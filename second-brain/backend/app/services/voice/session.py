"""
VoiceSession — per-connection conversation state machine.

State diagram
─────────────
                 ┌─────────► IDLE ◄────────┐
                 │            │            │
       interrupt │       start_turn        │ done
                 │            │            │
                 │            ▼            │
                 │        LISTENING        │
                 │            │            │
                 │       end_audio         │
                 │            │            │
                 │            ▼            │
                 └─── THINKING ──► SPEAKING

Public API
──────────
  on_audio(bytes)        — append a chunk to the current utterance buffer
  on_end_audio()         — finalize buffer; transcribe; query agent; synthesise reply
  on_interrupt()         — abort whatever turn is in progress, return to IDLE
  on_text(text)          — text-only turn (lets users type while in voice mode)

Each public method is async-generator-friendly: callers consume events via
the `events()` async iterator. This decouples session logic from the
transport (WebSocket vs SSE vs in-process tests).
"""
from __future__ import annotations

import asyncio
import time
import uuid
from typing import AsyncIterator, Literal

from app.core.logging import get_logger
from app.models.query import QueryRequest
from app.services.agent.conversation_memory import conversation_memory
from app.services.agent.engine import agent_engine
from app.services.voice.synthesizer import synthesizer
from app.services.voice.transcriber import transcriber

logger = get_logger(__name__)

State = Literal["idle", "listening", "thinking", "speaking"]


class VoiceSession:
    def __init__(self) -> None:
        self.id: str = uuid.uuid4().hex[:8]
        self.state: State = "idle"
        self._audio_buf: bytearray = bytearray()
        self._events: asyncio.Queue[dict | bytes] = asyncio.Queue()
        self._turn_task: asyncio.Task | None = None
        self._history: list[dict] = []  # [{role, content, ts}]

    # ── event stream consumed by WebSocket handler ───────────────────────────

    async def events(self) -> AsyncIterator[dict | bytes]:
        """Yield all server-to-client messages for this session."""
        while True:
            item = await self._events.get()
            if item is None:
                return
            yield item

    async def close(self) -> None:
        await self._events.put(None)

    # ── public commands from the client ──────────────────────────────────────

    async def on_audio(self, chunk: bytes) -> None:
        """Append a binary audio chunk to the current utterance buffer."""
        if self.state == "idle":
            await self._set_state("listening")
        self._audio_buf.extend(chunk)

    async def on_end_audio(self) -> None:
        """Finalize the audio buffer and start the agent turn."""
        if self.state not in ("idle", "listening"):
            logger.debug("VoiceSession[%s]: end_audio ignored — state=%s", self.id, self.state)
            return
        audio = bytes(self._audio_buf)
        self._audio_buf.clear()
        # Run the agent turn in a task so on_interrupt can cancel it
        self._turn_task = asyncio.create_task(self._run_turn(audio))

    async def on_interrupt(self) -> None:
        """Cancel any in-flight TTS / agent turn and return to idle."""
        if self._turn_task and not self._turn_task.done():
            self._turn_task.cancel()
            try:
                await self._turn_task
            except (asyncio.CancelledError, Exception):
                pass
        self._audio_buf.clear()
        await self._set_state("idle")

    async def on_text(self, text: str) -> None:
        """Text-only turn (skip transcription, jump straight to agent)."""
        if self._turn_task and not self._turn_task.done():
            await self.on_interrupt()
        self._turn_task = asyncio.create_task(self._run_turn_from_text(text))

    # ── turn implementation ──────────────────────────────────────────────────

    async def _run_turn(self, audio: bytes) -> None:
        t0 = time.monotonic()
        try:
            await self._set_state("thinking")

            # ── 1. Transcribe ─────────────────────────────────────────────────
            transcript = await transcriber.transcribe_bytes(audio)
            if not transcript.strip():
                await self._emit({"type": "error", "message": "I didn't catch that — try again."})
                await self._set_state("idle")
                return
            await self._emit({"type": "transcript", "text": transcript, "is_final": True})

            # ── 2. Agent ─────────────────────────────────────────────────────
            await self._run_turn_from_text(transcript, _skip_state_set=True, t0=t0)
        except asyncio.CancelledError:
            logger.info("VoiceSession[%s]: turn cancelled", self.id)
            raise
        except Exception as exc:
            logger.error("VoiceSession[%s]: turn failed — %s", self.id, exc, exc_info=True)
            await self._emit({"type": "error", "message": "Something went wrong on the server."})
            await self._set_state("idle")

    async def _run_turn_from_text(
        self, text: str, *, _skip_state_set: bool = False, t0: float | None = None,
    ) -> None:
        if t0 is None:
            t0 = time.monotonic()
        try:
            if not _skip_state_set:
                await self._set_state("thinking")

            # Record the user side of the turn before invoking the agent so it
            # can see the message in its own context window if needed.
            self._history.append({"role": "user", "content": text, "ts": time.time()})
            await conversation_memory.append(self.id, "user", text)

            # Agent query — the agent never raises, always returns a response.
            # Pass the session id so the engine can fetch recent turns for context.
            resp = await agent_engine.query(
                QueryRequest(text=text, top_k=5),
                session_id=self.id,
            )
            answer = resp.answer or "I don't have an answer for that."
            self._history.append({"role": "assistant", "content": answer, "ts": time.time()})
            await conversation_memory.append(self.id, "assistant", answer)
            await self._emit({
                "type": "response",
                "text": answer,
                "tool_used": resp.tool_used,
                "answer_source": resp.answer_source,
                "latency_ms": int((time.monotonic() - t0) * 1000),
            })

            # ── 3. Speak ─────────────────────────────────────────────────────
            await self._speak(answer)
            await self._set_state("idle")
        except asyncio.CancelledError:
            raise
        except Exception as exc:
            logger.error("VoiceSession[%s]: text-turn failed — %s", self.id, exc, exc_info=True)
            await self._emit({"type": "error", "message": "Something went wrong on the server."})
            await self._set_state("idle")

    async def _speak(self, text: str) -> None:
        """Stream TTS audio chunks to the client."""
        if not synthesizer.is_available():
            # No TTS — emit a no-op so the client knows to skip playback
            await self._emit({"type": "tts_skip", "reason": "synth_unavailable"})
            return
        await self._set_state("speaking")
        await self._emit({"type": "tts_start", "sample_rate": synthesizer.sample_rate})
        try:
            async for wav_chunk in synthesizer.synthesize_chunks(text):
                await self._events.put(wav_chunk)
        except asyncio.CancelledError:
            await self._emit({"type": "tts_interrupted"})
            raise
        await self._emit({"type": "tts_end"})

    # ── helpers ──────────────────────────────────────────────────────────────

    async def _set_state(self, state: State) -> None:
        if state == self.state:
            return
        self.state = state
        logger.debug("VoiceSession[%s]: state -> %s", self.id, state)
        await self._emit({"type": "state", "state": state})

    async def _emit(self, payload: dict) -> None:
        await self._events.put(payload)
