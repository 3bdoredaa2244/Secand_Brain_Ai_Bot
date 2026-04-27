import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.logging import setup_logging, get_logger
from app.api.v1.router import router
from app.services.rag.retriever import retriever
from app.services.obsidian import watcher as _watcher_mod
from app.services.obsidian.sync import sync as obsidian_sync
from app.services.obsidian.watcher import VaultWatcher
from app.workers.redis_consumer import consumer
from app.workers.proactive_worker import worker

setup_logging()
logger = get_logger(__name__)
settings = get_settings()

# Exposed on the module so the /obsidian/status endpoint can inspect it
_watcher_mod._watcher = None


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

    # ── vault file watcher (runs in an OS background thread) ──
    loop = asyncio.get_running_loop()
    vault_watcher = VaultWatcher(
        vault_path=settings.vault_path.resolve(),
        sync_fn=obsidian_sync.sync_file,
        remove_fn=obsidian_sync.remove_file,
    )
    vault_watcher.start(loop)
    _watcher_mod._watcher = vault_watcher

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
