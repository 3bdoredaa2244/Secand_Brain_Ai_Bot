"""
Synthesizer — Piper TTS wrapper (Piper 1.4.x API).

Streams PCM-encoded WAV chunks for low-latency playback. Each yielded chunk
is a complete WAV file the browser can decode independently — one chunk per
sentence (Piper synthesizes sentence-by-sentence).

Model files
───────────
Piper voices are pairs of (.onnx, .onnx.json) downloaded from:
  https://huggingface.co/rhasspy/piper-voices

Defaults
  voice name:  en_US-lessac-medium  (good US English, ~63 MB)
  voice path:  backend/data/piper/en_US-lessac-medium.onnx
  configurable via PIPER_VOICE_PATH in .env

Auto-download
  On first use, if the model file is missing we fetch both the .onnx and
  .onnx.json from HuggingFace using huggingface_hub. Subsequent loads use
  the cached files.
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

_DEFAULT_VOICE = "en_US-lessac-medium"
# HuggingFace path layout: voices/<lang_code>/<lang_country>/<voice>/<quality>/<voice>.onnx
_HF_REPO = "rhasspy/piper-voices"
_HF_VOICE_PATH = "en/en_US/lessac/medium"

_DATA_DIR = Path(__file__).resolve().parents[3] / "data" / "piper"


class Synthesizer:
    """Singleton TTS engine. Streams 16-bit PCM WAV chunks."""

    def __init__(self) -> None:
        self._voice = None
        self._sample_rate: int = 22050
        self._load_lock = threading.Lock()
        self._available_cached: bool | None = None  # None = not checked yet

    # ── readiness ─────────────────────────────────────────────────────────────

    def is_available(self) -> bool:
        """Return True when piper is importable AND voice file is present."""
        if self._available_cached is not None:
            return self._available_cached
        self._available_cached = self._compute_available()
        return self._available_cached

    def _compute_available(self) -> bool:
        try:
            import piper  # noqa: F401, PLC0415
        except ImportError:
            logger.warning(
                "Synthesizer: 'piper-tts' not installed — TTS disabled. "
                "Install with: pip install piper-tts"
            )
            return False
        if not self._voice_path().exists():
            logger.info(
                "Synthesizer: voice file missing at %s. Will auto-download on first use.",
                self._voice_path(),
            )
            # Still "available" — we'll download lazily
            return True
        return True

    @property
    def sample_rate(self) -> int:
        return self._sample_rate

    def voice_info(self) -> dict:
        """Return diagnostic info for /voice/status."""
        return {
            "voice_name": _DEFAULT_VOICE,
            "voice_path": str(self._voice_path()),
            "voice_exists": self._voice_path().exists(),
            "loaded": self._voice is not None,
            "sample_rate": self._sample_rate,
        }

    async def ensure_model(self) -> bool:
        """Download the voice model if it is missing. Returns True on success."""
        if self._voice_path().exists():
            return True
        try:
            await asyncio.to_thread(self._download_voice_sync)
            return self._voice_path().exists()
        except Exception as exc:
            logger.error("Synthesizer: model download failed — %s", exc)
            return False

    # ── public api ────────────────────────────────────────────────────────────

    async def synthesize_chunks(self, text: str) -> AsyncIterator[bytes]:
        """
        Yield WAV-encoded PCM chunks. Each chunk = one sentence from Piper.
        Auto-downloads the voice model on first call if missing.
        """
        if not text.strip():
            return
        if not self.is_available():
            return

        if not self._voice_path().exists():
            if not await self.ensure_model():
                logger.warning("Synthesizer: cannot synthesize — model unavailable")
                return

        try:
            # Producer thread fills a queue with WAV chunks
            queue: asyncio.Queue[bytes | None] = asyncio.Queue()
            loop = asyncio.get_running_loop()

            def _produce():
                try:
                    self._ensure_loaded()
                    for chunk in self._voice.synthesize(text):
                        wav_bytes = _audio_chunk_to_wav(chunk)
                        asyncio.run_coroutine_threadsafe(queue.put(wav_bytes), loop)
                except Exception as exc:
                    logger.error("Synthesizer._produce: %s", exc, exc_info=True)
                finally:
                    asyncio.run_coroutine_threadsafe(queue.put(None), loop)

            threading.Thread(target=_produce, daemon=True, name="piper-synth").start()

            while True:
                item = await queue.get()
                if item is None:
                    break
                yield item
        except Exception as exc:
            logger.error("Synthesizer: synthesis failed — %s", exc, exc_info=True)

    # ── internal ──────────────────────────────────────────────────────────────

    def _voice_path(self) -> Path:
        custom = (settings.piper_voice_path or "").strip()
        if custom:
            return Path(custom)
        return _DATA_DIR / f"{_DEFAULT_VOICE}.onnx"

    def _config_path(self) -> Path:
        # Piper convention: <model>.onnx.json
        return self._voice_path().with_suffix(self._voice_path().suffix + ".json")

    def _ensure_loaded(self):
        if self._voice is not None:
            return
        with self._load_lock:
            if self._voice is not None:
                return
            from piper import PiperVoice  # noqa: PLC0415
            voice_path = self._voice_path()
            config_path = self._config_path()
            logger.info("Synthesizer: loading Piper voice %s (single-threaded)", voice_path.name)
            # Load the voice via Piper's helper, then tighten the underlying
            # onnxruntime session so it uses only one thread — this matches
            # OPENBLAS_NUM_THREADS=1 set in runtime_tuning and keeps memory low.
            self._voice = PiperVoice.load(
                model_path=str(voice_path),
                config_path=str(config_path) if config_path.exists() else None,
                use_cuda=False,
            )
            try:
                # Piper exposes the onnxruntime InferenceSession at voice.session.
                # We can't change SessionOptions after construction, but we can
                # configure thread pools via the global ONNX runtime env vars,
                # which we already set in runtime_tuning.py.
                sess = getattr(self._voice, "session", None)
                if sess is not None and hasattr(sess, "get_session_options"):
                    opts = sess.get_session_options()
                    logger.debug(
                        "Synthesizer: onnxruntime threads — intra=%d inter=%d",
                        opts.intra_op_num_threads, opts.inter_op_num_threads,
                    )
            except Exception as exc:
                logger.debug("Synthesizer: couldn't inspect onnxruntime threads — %s", exc)
            self._sample_rate = self._voice.config.sample_rate
            logger.info("Synthesizer: voice loaded (sample_rate=%d)", self._sample_rate)

    def _download_voice_sync(self) -> None:
        """Fetch the default voice from HuggingFace into the data dir."""
        from huggingface_hub import hf_hub_download  # noqa: PLC0415

        _DATA_DIR.mkdir(parents=True, exist_ok=True)
        for ext in (".onnx", ".onnx.json"):
            filename = f"{_HF_VOICE_PATH}/{_DEFAULT_VOICE}{ext}"
            target = _DATA_DIR / f"{_DEFAULT_VOICE}{ext}"
            if target.exists():
                continue
            logger.info("Synthesizer: downloading %s ...", filename)
            local = hf_hub_download(
                repo_id=_HF_REPO,
                filename=filename,
                local_dir=str(_DATA_DIR),
                local_dir_use_symlinks=False,
            )
            # hf_hub_download may place file at nested path; move/copy to flat location
            local_path = Path(local)
            if local_path != target:
                target.write_bytes(local_path.read_bytes())
            logger.info("Synthesizer: saved %s (%d bytes)", target.name, target.stat().st_size)


def _audio_chunk_to_wav(chunk) -> bytes:
    """Convert a Piper AudioChunk to a self-contained WAV file."""
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(chunk.sample_channels)
        wf.setsampwidth(chunk.sample_width)
        wf.setframerate(chunk.sample_rate)
        wf.writeframes(chunk.audio_int16_bytes)
    return buf.getvalue()


synthesizer = Synthesizer()
