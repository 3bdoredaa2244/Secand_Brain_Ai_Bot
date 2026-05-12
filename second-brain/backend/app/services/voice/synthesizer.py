"""
Synthesizer — Piper TTS wrapper.

Streams PCM audio chunks for low-latency playback. The client receives WAV
data over the WebSocket and pipes it directly into the browser's audio
context.

Model files
───────────
Piper voices are pairs of (.onnx, .onnx.json) downloaded separately from:
  https://huggingface.co/rhasspy/piper-voices

Default model search path: `backend/data/piper/<voice-name>.onnx`
Configurable via `PIPER_VOICE_PATH` in .env.

When Piper isn't installed or the voice file is missing, synthesize_chunks()
yields a single empty chunk and the frontend simply skips audio playback.
"""
from __future__ import annotations

import asyncio
import io
import threading
import wave
from pathlib import Path
from typing import AsyncIterator

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)
settings = get_settings()


class Synthesizer:
    """Singleton TTS engine. Streams 16-bit PCM WAV chunks."""

    def __init__(self) -> None:
        self._voice = None
        self._load_lock = threading.Lock()
        self._available: bool | None = None
        self._sample_rate: int = 22050  # set after model load

    # ── readiness ─────────────────────────────────────────────────────────────

    def is_available(self) -> bool:
        """True when Piper is installed and the voice file exists."""
        if self._available is not None:
            return self._available
        try:
            import piper  # noqa: F401, PLC0415
        except ImportError:
            logger.warning(
                "Synthesizer: 'piper-tts' not installed — TTS disabled. "
                "Install with: pip install piper-tts"
            )
            self._available = False
            return False

        voice_path = self._voice_path()
        if not voice_path.exists():
            logger.warning(
                "Synthesizer: voice file not found at %s. Download a voice from "
                "https://huggingface.co/rhasspy/piper-voices and set PIPER_VOICE_PATH.",
                voice_path,
            )
            self._available = False
            return False

        self._available = True
        return True

    @property
    def sample_rate(self) -> int:
        """Sample rate of generated audio (Hz). Default 22050 — overridden after load."""
        return self._sample_rate

    # ── public api ────────────────────────────────────────────────────────────

    async def synthesize_chunks(self, text: str, chunk_ms: int = 250) -> AsyncIterator[bytes]:
        """
        Yield WAV-encoded PCM chunks for `text`. Each chunk is a complete WAV
        file the browser can decode independently.

        The first call also yields a tiny WAV header chunk so the client knows
        the sample rate. Subsequent chunks are raw PCM with their own headers
        — simple but ~1KB overhead per chunk, fine at 250ms.
        """
        if not text.strip():
            return
        if not self.is_available():
            return

        try:
            async for chunk in self._stream(text, chunk_ms):
                yield chunk
        except Exception as exc:
            logger.error("Synthesizer: synthesis failed — %s", exc, exc_info=True)

    # ── internal ──────────────────────────────────────────────────────────────

    def _voice_path(self) -> Path:
        return Path(getattr(settings, "piper_voice_path", "") or
                    Path(__file__).resolve().parents[3] / "data" / "piper" / "en_US-lessac-medium.onnx")

    def _ensure_loaded(self):
        if self._voice is not None:
            return
        with self._load_lock:
            if self._voice is not None:
                return
            from piper import PiperVoice  # noqa: PLC0415
            voice_path = self._voice_path()
            logger.info("Synthesizer: loading Piper voice %s", voice_path)
            self._voice = PiperVoice.load(str(voice_path))
            self._sample_rate = self._voice.config.sample_rate
            logger.info("Synthesizer: loaded (sample_rate=%d)", self._sample_rate)

    async def _stream(self, text: str, chunk_ms: int) -> AsyncIterator[bytes]:
        """Generate audio in a thread and yield PCM chunks of ~chunk_ms duration."""
        # Run blocking synthesis in a thread, collect to a queue, yield from main loop.
        queue: asyncio.Queue[bytes | None] = asyncio.Queue()
        loop = asyncio.get_running_loop()

        def _produce():
            try:
                self._ensure_loaded()
                samples_per_chunk = int(self._sample_rate * (chunk_ms / 1000.0))
                # Piper synthesize() yields raw PCM int16 bytes — wrap as WAV chunks
                # so the browser can play each chunk independently.
                pcm_buffer = io.BytesIO()
                for audio_bytes in self._voice.synthesize_stream_raw(text):
                    pcm_buffer.write(audio_bytes)
                    while pcm_buffer.tell() >= samples_per_chunk * 2:  # 2 bytes/sample int16
                        pcm_buffer.seek(0)
                        head = pcm_buffer.read(samples_per_chunk * 2)
                        rest = pcm_buffer.read()
                        pcm_buffer = io.BytesIO()
                        pcm_buffer.write(rest)
                        wav_chunk = _pcm_to_wav(head, self._sample_rate)
                        asyncio.run_coroutine_threadsafe(queue.put(wav_chunk), loop)
                # Flush trailing PCM
                pcm_buffer.seek(0)
                tail = pcm_buffer.read()
                if tail:
                    asyncio.run_coroutine_threadsafe(queue.put(_pcm_to_wav(tail, self._sample_rate)), loop)
            except Exception as exc:
                logger.error("Synthesizer._produce: %s", exc, exc_info=True)
            finally:
                asyncio.run_coroutine_threadsafe(queue.put(None), loop)

        # kick off producer thread
        threading.Thread(target=_produce, daemon=True, name="piper-synth").start()

        while True:
            item = await queue.get()
            if item is None:
                break
            yield item


def _pcm_to_wav(pcm_data: bytes, sample_rate: int) -> bytes:
    """Wrap raw 16-bit mono PCM in a minimal WAV header."""
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)         # 16-bit
        wf.setframerate(sample_rate)
        wf.writeframes(pcm_data)
    return buf.getvalue()


synthesizer = Synthesizer()
