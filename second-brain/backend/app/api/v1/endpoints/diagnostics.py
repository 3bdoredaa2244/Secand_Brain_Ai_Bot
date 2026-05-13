"""
Diagnostics endpoint — single-call snapshot used by the dashboard.

GET /api/v1/diagnostics/system

Aggregates the health of every subsystem so the frontend can render a
status grid without making a dozen requests. Every check is fail-safe:
a broken integration must NEVER fail the dashboard.
"""
from __future__ import annotations

import os
import platform
import sys
import time
from pathlib import Path

from fastapi import APIRouter

from app.core.config import get_settings
from app.core.logging import get_logger
from app.core.runtime_config import runtime_config
from app.services.agent.conversation_memory import conversation_memory
from app.services.confirmation_gate.gate import gate
from app.services.integrations.gmail.client import gmail_client
from app.services.integrations.gmail.oauth import oauth_handler
from app.services.integrations.gmail.token_store import token_store
from app.services.integrations.calendar.client import calendar_client
from app.services.obsidian.graph import graph as vault_graph
from app.services.rag.retriever import retriever
from app.services.voice.synthesizer import synthesizer
from app.services.voice.transcriber import transcriber

logger = get_logger(__name__)
router = APIRouter(prefix="/diagnostics", tags=["diagnostics"])
settings = get_settings()


@router.get("/system")
async def system_diagnostics() -> dict:
    """Return a complete subsystem status snapshot.

    Shape (top-level keys):
      backend, redis, chromadb, voice, vault, gmail, calendar, memory, runtime
    """
    return {
        "backend":  _backend_section(),
        "redis":    await _redis_section(),
        "chromadb": _chromadb_section(),
        "voice":    _voice_section(),
        "vault":    _vault_section(),
        "gmail":    await _gmail_section(),
        "calendar": await _calendar_section(),
        "memory":   await _memory_section(),
        "runtime":  _runtime_section(),
    }


# ── sections ────────────────────────────────────────────────────────────────


def _backend_section() -> dict:
    return {
        "status": "ok",
        "app": settings.app_name,
        "version": settings.app_version,
        "python": sys.version.split(" ", 1)[0],
        "platform": platform.platform(terse=True),
        "pid": os.getpid(),
    }


async def _redis_section() -> dict:
    """Check Redis by piggybacking on the gate's connection."""
    info: dict = {"url": settings.redis_url, "connected": False, "latency_ms": None}
    client = getattr(gate, "_redis", None)
    if client is None:
        info["note"] = "in-memory fallback active"
        return info
    try:
        t0 = time.perf_counter()
        await client.ping()
        info["connected"] = True
        info["latency_ms"] = round((time.perf_counter() - t0) * 1000, 1)
    except Exception as exc:
        info["error"] = str(exc)
    return info


def _chromadb_section() -> dict:
    """Inspect the retriever singleton — it's already connected at startup."""
    info: dict = {
        "host": settings.chroma_host,
        "port": settings.chroma_port,
        "collection": settings.chroma_collection,
        "connected": retriever._collection is not None,
        "doc_count": None,
    }
    if retriever._collection is not None:
        try:
            info["doc_count"] = retriever._collection.count()
        except Exception as exc:
            info["doc_count_error"] = str(exc)
    return info


def _voice_section() -> dict:
    """Pulled directly from /voice/status logic — duplicated here for the one-shot dashboard."""
    stt_available = transcriber.is_available()
    tts_available = synthesizer.is_available()
    voice_info = synthesizer.voice_info()
    return {
        "stt": {
            "available": stt_available,
            "model": settings.whisper_model,
            "loaded": transcriber._model is not None,
            "cpu_threads": getattr(settings, "whisper_cpu_threads", 1),
            "compute_type": "int8",
        },
        "tts": {
            "available": tts_available,
            "loaded": synthesizer._voice is not None,
            **voice_info,
        },
    }


def _vault_section() -> dict:
    vault = runtime_config.get_vault_path().resolve()
    exists = vault.exists()
    md_files = 0
    if exists:
        try:
            md_files = sum(1 for _ in vault.rglob("*.md"))
        except (PermissionError, OSError):
            pass
    return {
        "path": str(vault),
        "exists": exists,
        "md_files": md_files,
        "graph": vault_graph.summary(),
        "watcher_active": _watcher_alive(),
    }


def _watcher_alive() -> bool:
    try:
        from app.services.obsidian import watcher as _watcher_mod  # noqa: PLC0415
        w = getattr(_watcher_mod, "_watcher", None)
        if w is None:
            return False
        obs = getattr(w, "_observer", None)
        return bool(obs and obs.is_alive())
    except Exception:
        return False


async def _gmail_section() -> dict:
    authorized = token_store.has_tokens()
    email = None
    if authorized:
        try:
            profile = await gmail_client.get_profile()
            email = (profile or {}).get("emailAddress")
        except Exception as exc:
            logger.debug("diagnostics.gmail: profile fetch failed — %s", exc)
    return {
        "oauth_configured": oauth_handler.is_configured(),
        "authorized": authorized,
        "email": email,
    }


async def _calendar_section() -> dict:
    ready = calendar_client.is_ready()
    today_count: int | None = None
    if ready:
        try:
            events = await calendar_client.list_today()
            today_count = len(events)
        except Exception as exc:
            logger.debug("diagnostics.calendar: today count failed — %s", exc)
    return {
        "authorized": ready,
        "today_event_count": today_count,
    }


async def _memory_section() -> dict:
    sessions = await conversation_memory.list_sessions()
    return {
        "sessions_active": len(sessions),
        "sessions": sessions[:25],
        "redis_backed": conversation_memory._redis is not None,
    }


def _runtime_section() -> dict:
    thread_env = {
        k: os.environ.get(k, "")
        for k in (
            "OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "MKL_NUM_THREADS",
            "NUMEXPR_NUM_THREADS", "BLIS_NUM_THREADS",
        )
    }
    return {
        "thread_limits": thread_env,
        "memory_safe": all(v == "1" for v in thread_env.values() if v),
        "rss_mb": _process_rss_mb(),
        "uptime_seconds": int(time.time() - _PROCESS_START),
    }


def _process_rss_mb() -> float | None:
    """Best-effort RSS lookup; psutil is optional."""
    try:
        import psutil  # noqa: PLC0415
        return round(psutil.Process(os.getpid()).memory_info().rss / 1_048_576, 1)
    except Exception:
        return None


_PROCESS_START = time.time()
