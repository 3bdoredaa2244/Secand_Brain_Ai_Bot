"""
Transcriber — faster-whisper wrapper.

Lazy-loads the model on first use (download + load takes ~5s for tiny on CPU).
Falls back to a stub transcript when faster-whisper is not installed so the
rest of the voice pipeline can be exercised without ML deps.

Audio input
───────────
We accept either:
  • raw bytes of any format ffmpeg can decode (WebM/Opus, MP3, WAV, …)
  • a numpy float32 mono array at 16 kHz
"""
from __future__ import annotations

import asyncio
import io
import threading
from pathlib import Path

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)
settings = get_settings()


class Transcriber:
    """Singleton STT engine. Thread-safe model load."""

    def __init__(self) -> None:
        self._model = None
        self._load_lock = threading.Lock()
        self._available: bool | None = None

    # ── readiness ─────────────────────────────────────────────────────────────

    def is_available(self) -> bool:
        """True when faster-whisper is importable (does not load the model)."""
        if self._available is not None:
            return self._available
        try:
            import faster_whisper  # noqa: F401, PLC0415
            self._available = True
        except ImportError:
            self._available = False
            logger.warning(
                "Transcriber: 'faster-whisper' not installed — voice will use stub transcript. "
                "Install with: pip install faster-whisper"
            )
        return self._available

    # ── public api ────────────────────────────────────────────────────────────

    async def transcribe_bytes(self, data: bytes, language: str | None = None) -> str:
        """Transcribe arbitrary audio bytes. Returns '' on error or empty audio."""
        if not data:
            return ""
        if not self.is_available():
            return _stub_transcript(len(data))
        try:
            return await asyncio.to_thread(self._transcribe_sync, data, language)
        except Exception as exc:
            logger.error("Transcriber: failed — %s", exc, exc_info=True)
            return ""

    # ── sync impl ─────────────────────────────────────────────────────────────

    def _ensure_loaded(self):
        if self._model is not None:
            return
        with self._load_lock:
            if self._model is not None:
                return
            from faster_whisper import WhisperModel  # noqa: PLC0415
            model_size = settings.whisper_model or "tiny"
            logger.info("Transcriber: loading faster-whisper '%s' (this may take ~5s)...", model_size)
            # int8 quantisation gives best CPU speed at minimal quality loss
            self._model = WhisperModel(model_size, device="cpu", compute_type="int8")
            logger.info("Transcriber: model loaded")

    def _transcribe_sync(self, data: bytes, language: str | None) -> str:
        self._ensure_loaded()
        # faster-whisper accepts a file-like object — saves us a tempfile dance
        buf = io.BytesIO(data)
        segments, info = self._model.transcribe(
            buf,
            language=language,
            beam_size=1,           # greedy decode = faster
            vad_filter=True,       # built-in Silero VAD removes silences
            vad_parameters={"min_silence_duration_ms": 400},
        )
        text_parts = [seg.text for seg in segments]
        text = "".join(text_parts).strip()
        logger.info("Transcriber: %d chars (lang=%s, prob=%.2f)", len(text), info.language, info.language_probability)
        return text


def _stub_transcript(n_bytes: int) -> str:
    return f"[stub transcript — install faster-whisper to enable real STT] received {n_bytes} bytes"


transcriber = Transcriber()
