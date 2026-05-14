# MUST be the first import — sets OPENBLAS_NUM_THREADS / OMP_NUM_THREADS / etc.
# before numpy, ctranslate2, or onnxruntime are loaded anywhere. Prevents an
# OpenBLAS memory-allocation crash on Windows when faster-whisper, Piper, and
# chromadb (numpy) all load in the same process.
from app.core import runtime_tuning
_voice_tuning = runtime_tuning.apply()

import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import get_settings
from app.core.logging import setup_logging, get_logger
from app.core.runtime_config import runtime_config
from app.api.v1.router import router
from app.services.agent.conversation_memory import conversation_memory
from app.services.confirmation_gate.gate import gate
from app.services.integrations.calendar import calendar_service
from app.services.integrations.email import email_service
from app.services.rag.retriever import retriever
from app.services.obsidian import watcher as _watcher_mod
from app.services.obsidian.sync import sync as obsidian_sync
from app.services.obsidian.watcher import VaultWatcher
from app.workers.redis_consumer import consumer
from app.workers.proactive_worker import worker

setup_logging()
logger = get_logger(__name__)
settings = get_settings()
logger.info("Runtime tuning: %s", _voice_tuning)

# Exposed on the module so the /obsidian/status endpoint can inspect it
_watcher_mod._watcher = None


async def _startup_sync() -> None:
    """Run a full vault sync once in the background after startup."""
    try:
        result = await obsidian_sync.sync_all()
        logger.info(
            "Startup sync complete: %d files, %d chunks, %d errors",
            result.files_scanned, result.chunks_indexed, result.errors,
        )
    except Exception as exc:
        logger.error("Startup sync failed: %s", exc)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting %s v%s", settings.app_name, settings.app_version)

    # ── infrastructure ──
    try:
        retriever.connect()
    except Exception as exc:
        logger.warning("Retriever failed to connect: %s", exc)

    try:
        await consumer.connect()
    except Exception as exc:
        logger.warning("Redis consumer failed to connect: %s", exc)

    # Gate gets its own Redis connection (separate from the stream consumer)
    await gate.connect()

    # Conversation memory — separate Redis connection; falls back to in-memory.
    await conversation_memory.connect()

    # Integrations: attempt real connect; both degrade to mock silently
    await email_service.connect()
    await calendar_service.connect()

    # Google OAuth: log readiness so missing setup is obvious in logs.
    try:
        from app.services.integrations.gmail.oauth import oauth_handler  # noqa: PLC0415
        if not oauth_handler.is_configured():
            logger.warning(
                "Google OAuth: GMAIL_CLIENT_ID / GMAIL_CLIENT_SECRET not set in .env — "
                "Gmail + Calendar will run in mock mode. See SETUP_WINDOWS.md."
            )
        else:
            info = oauth_handler.token_info()
            if not info.get("authorized"):
                logger.info(
                    "Google OAuth: credentials configured, no tokens yet. "
                    "Visit %s to authorize.",
                    "http://localhost:8000/api/v1/auth/google/login",
                )
            else:
                logger.info(
                    "Google OAuth: tokens loaded (scopes=%d, refresh_token=%s, expires_in=%ss)",
                    info.get("scope_count", 0),
                    "yes" if info.get("has_refresh_token") else "no",
                    info.get("expires_in_seconds"),
                )
    except Exception as exc:
        logger.warning("Google OAuth: readiness probe failed — %s", exc)

    # Voice subsystem readiness check — non-blocking, never crashes
    try:
        from app.services.voice.transcriber import transcriber  # noqa: PLC0415
        from app.services.voice.synthesizer import synthesizer  # noqa: PLC0415
        stt_ok = transcriber.is_available()
        tts_ok = synthesizer.is_available()
        if stt_ok and tts_ok:
            logger.info("Voice: STT (faster-whisper) and TTS (Piper) both available")
        elif stt_ok:
            logger.warning("Voice: STT ready, TTS NOT ready — POST /api/v1/voice/setup to download voice model")
        elif tts_ok:
            logger.warning("Voice: TTS ready, STT NOT ready — pip install faster-whisper")
        else:
            logger.warning(
                "Voice: STT and TTS both unavailable. Install: pip install faster-whisper piper-tts. "
                "Then POST /api/v1/voice/setup to download the default voice."
            )
    except Exception as exc:
        logger.warning("Voice: readiness probe failed (%s) — voice disabled", exc)

    # ── vault file watcher (runs in an OS background thread) ──
    vault_root = runtime_config.get_vault_path().resolve()
    if not vault_root.exists():
        logger.warning(
            "Vault path %s does not exist — create it or change via "
            "POST /api/v1/obsidian/config",
            vault_root,
        )

    loop = asyncio.get_running_loop()
    vault_watcher = VaultWatcher(
        vault_path=vault_root,
        sync_fn=obsidian_sync.sync_file,
        remove_fn=obsidian_sync.remove_file,
    )
    vault_watcher.start(loop)
    _watcher_mod._watcher = vault_watcher

    # ── startup vault sync (fires once in background, does not block startup) ──
    if settings.obsidian_sync_on_startup:
        asyncio.create_task(_startup_sync())

    # ── async background workers ──
    consumer_task = asyncio.create_task(consumer.start())
    worker_task = asyncio.create_task(worker.start())

    yield

    # ── shutdown ──
    logger.info("Shutting down")

    vault_watcher.stop()

    try:
        await consumer.stop()
    except Exception:
        pass

    try:
        await worker.stop()
    except Exception:
        pass

    consumer_task.cancel()
    worker_task.cancel()


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)


@app.exception_handler(Exception)
async def _unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Catch any exception that escapes endpoint handlers and return JSON.

    Starlette's default ServerErrorMiddleware returns plain-text
    'Internal Server Error', which the frontend cannot parse as JSON.
    This handler ensures every 500 is a well-formed JSON response.
    """
    logger.error(
        "Unhandled exception on %s %s: %s",
        request.method, request.url.path, exc,
        exc_info=True,
    )
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "detail": str(exc)},
    )
