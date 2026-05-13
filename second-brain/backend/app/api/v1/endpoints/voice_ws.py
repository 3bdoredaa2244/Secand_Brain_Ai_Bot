"""
WebSocket endpoint for the immersive voice UI.

Protocol
────────

Client → Server
  Text (JSON):
    {"type": "start"}             — begin a new turn (optional, on_audio auto-starts)
    {"type": "end"}               — finalize current audio, transcribe, respond, speak
    {"type": "interrupt"}         — cancel current turn (mid-TTS, etc.)
    {"type": "text", "text": "…"} — text-only turn (typed input while in voice mode)
    {"type": "ping"}              — keepalive

  Binary:
    Raw audio bytes appended to the current utterance buffer.
    Format: any container ffmpeg can decode (WebM/Opus default from browser MediaRecorder).

Server → Client
  Text (JSON):
    {"type": "state", "state": "idle|listening|thinking|speaking"}
    {"type": "transcript", "text": "…", "is_final": true}
    {"type": "response", "text": "…", "tool_used": "…|null", "answer_source": "…", "latency_ms": …}
    {"type": "tts_start", "sample_rate": 22050}
    {"type": "tts_end"}
    {"type": "tts_skip", "reason": "…"}    — when synth not available
    {"type": "tts_interrupted"}
    {"type": "error", "message": "…"}
    {"type": "pong"}                       — keepalive ack
    {"type": "ready", "session_id": "…", "stt_available": bool, "tts_available": bool}

  Binary:
    WAV chunks of TTS audio. Each chunk is a self-contained WAV file the
    browser can decode independently (~250 ms each).
"""
from __future__ import annotations

import asyncio
import json

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.core.logging import get_logger
from app.services.voice.session import VoiceSession
from app.services.voice.synthesizer import synthesizer
from app.services.voice.transcriber import transcriber

logger = get_logger(__name__)
router = APIRouter(prefix="/voice", tags=["voice"])


@router.get("/status")
async def voice_status() -> dict:
    """Diagnostic info about local voice capabilities.

    Used by the frontend to show a setup banner when STT/TTS are not ready,
    and by ops to verify that thread-tuning env vars took effect.
    Never raises — always returns the current state.
    """
    import os  # noqa: PLC0415
    from app.core.config import get_settings  # noqa: PLC0415
    s = get_settings()

    thread_env = {
        k: os.environ.get(k, "")
        for k in ("OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "MKL_NUM_THREADS",
                  "NUMEXPR_NUM_THREADS", "BLIS_NUM_THREADS")
    }
    memory_safe = all(thread_env[k] == "1" for k in thread_env if thread_env[k])

    return {
        "stt_available": transcriber.is_available(),
        "tts_available": synthesizer.is_available(),
        "models_loaded": {
            "stt": transcriber._model is not None,
            "tts": synthesizer._voice is not None,
        },
        "memory_safe": memory_safe,
        "stt": {
            "available": transcriber.is_available(),
            "model": s.whisper_model,
            "cpu_threads": getattr(s, "whisper_cpu_threads", 1),
            "compute_type": "int8",
            "loaded": transcriber._model is not None,
        },
        "tts": {
            "available": synthesizer.is_available(),
            **synthesizer.voice_info(),
        },
        "runtime_threads": thread_env,
    }


@router.post("/setup")
async def voice_setup() -> dict:
    """Trigger model downloads for any missing local assets.

    Currently downloads the Piper voice; faster-whisper downloads its model
    automatically on first transcription call. Safe to call repeatedly.
    """
    tts_ok = await synthesizer.ensure_model()
    return {
        "tts_model_ready": tts_ok,
        "tts_path": synthesizer.voice_info()["voice_path"],
        "note": "Whisper model downloads automatically on first transcription.",
    }


@router.websocket("/stream")
async def voice_stream(ws: WebSocket) -> None:
    await ws.accept()
    session = VoiceSession()
    logger.info("voice_stream: session %s opened", session.id)

    # Greet the client with capabilities so the frontend can adapt
    await ws.send_json({
        "type": "ready",
        "session_id": session.id,
        "stt_available": transcriber.is_available(),
        "tts_available": synthesizer.is_available(),
    })

    # Run send/receive loops concurrently
    sender_task = asyncio.create_task(_sender(ws, session), name=f"voice-send-{session.id}")
    try:
        await _receiver(ws, session)
    except WebSocketDisconnect:
        logger.info("voice_stream: session %s disconnected", session.id)
    except Exception as exc:
        logger.error("voice_stream[%s]: receive error — %s", session.id, exc, exc_info=True)
    finally:
        await session.on_interrupt()
        await session.close()
        sender_task.cancel()
        try:
            await sender_task
        except (asyncio.CancelledError, Exception):
            pass


# ── loops ───────────────────────────────────────────────────────────────────

async def _receiver(ws: WebSocket, session: VoiceSession) -> None:
    """Read messages from the client and dispatch into the session."""
    while True:
        msg = await ws.receive()
        if msg["type"] == "websocket.disconnect":
            raise WebSocketDisconnect()

        if "bytes" in msg and msg["bytes"] is not None:
            await session.on_audio(msg["bytes"])
            continue

        text = msg.get("text")
        if not text:
            continue

        try:
            payload = json.loads(text)
        except json.JSONDecodeError:
            logger.warning("voice_stream[%s]: bad JSON ignored", session.id)
            continue

        kind = payload.get("type")
        if kind == "end":
            await session.on_end_audio()
        elif kind == "interrupt":
            await session.on_interrupt()
        elif kind == "text":
            await session.on_text(payload.get("text", ""))
        elif kind == "ping":
            await ws.send_json({"type": "pong"})
        elif kind == "start":
            # No-op; on_audio auto-starts. Kept for symmetric UX semantics.
            pass
        else:
            logger.debug("voice_stream[%s]: unknown command %r", session.id, kind)


async def _sender(ws: WebSocket, session: VoiceSession) -> None:
    """Drain session events to the client. JSON dicts → text frames, bytes → binary frames."""
    try:
        async for item in session.events():
            if isinstance(item, dict):
                await ws.send_json(item)
            elif isinstance(item, (bytes, bytearray)):
                await ws.send_bytes(bytes(item))
    except WebSocketDisconnect:
        return
    except Exception as exc:
        # Connection closed mid-send is normal — debug-log it
        logger.debug("voice_stream[%s]: sender exit — %s", session.id, exc)
