"""
ConversationMemory — short-term per-session recall.

Stores the last N user/assistant turns per session so the agent can answer
follow-ups ("yes, do that", "what about Tuesday?") with the surrounding
context. Redis-backed with TTL; falls back to in-process memory when Redis
is unavailable so unit tests and offline runs still work.

Distinct from the vault (long-term semantic memory). This is a sliding
window for the live conversation only.

Keys
────
    chat:hist:<session_id>   list[json]   capped at MAX_TURNS
    chat:meta:<session_id>   hash          last_activity, created_at
"""
from __future__ import annotations

import json
import time
from collections import deque
from typing import Deque, Iterable

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)
settings = get_settings()

_HIST_PREFIX = "chat:hist:"
_META_PREFIX = "chat:meta:"
_MAX_TURNS = 20
_TTL_SECONDS = 60 * 60 * 6  # 6 h — long enough for a session, short enough to expire


class ConversationMemory:
    def __init__(self) -> None:
        self._redis = None
        # In-memory fallback: session_id -> deque of turn dicts
        self._mem: dict[str, Deque[dict]] = {}

    # ── lifecycle ─────────────────────────────────────────────────────────────

    async def connect(self) -> None:
        try:
            import redis.asyncio as aioredis  # noqa: PLC0415
            client = await aioredis.from_url(settings.redis_url, decode_responses=True)
            await client.ping()
            self._redis = client
            logger.info("ConversationMemory: connected to Redis")
        except Exception as exc:
            logger.warning(
                "ConversationMemory: Redis unavailable (%s) — using in-memory store", exc,
            )

    # ── public api ────────────────────────────────────────────────────────────

    async def append(self, session_id: str, role: str, content: str) -> None:
        """Append a turn. Role is 'user' or 'assistant'."""
        if not session_id or not content:
            return
        turn = {"role": role, "content": content, "ts": time.time()}

        if self._redis is None:
            buf = self._mem.setdefault(session_id, deque(maxlen=_MAX_TURNS))
            buf.append(turn)
            return

        key = f"{_HIST_PREFIX}{session_id}"
        try:
            pipe = self._redis.pipeline()
            pipe.rpush(key, json.dumps(turn))
            pipe.ltrim(key, -_MAX_TURNS, -1)
            pipe.expire(key, _TTL_SECONDS)
            pipe.hset(f"{_META_PREFIX}{session_id}", mapping={
                "last_activity": str(turn["ts"]),
            })
            pipe.expire(f"{_META_PREFIX}{session_id}", _TTL_SECONDS)
            await pipe.execute()
        except Exception as exc:
            logger.warning("ConversationMemory.append: Redis failed (%s) — keeping in memory", exc)
            buf = self._mem.setdefault(session_id, deque(maxlen=_MAX_TURNS))
            buf.append(turn)

    async def history(self, session_id: str, limit: int = _MAX_TURNS) -> list[dict]:
        """Return the most recent `limit` turns (oldest first)."""
        if not session_id:
            return []
        if self._redis is None:
            return list(self._mem.get(session_id, deque()))[-limit:]
        try:
            raw = await self._redis.lrange(f"{_HIST_PREFIX}{session_id}", -limit, -1)
            return [json.loads(r) for r in raw]
        except Exception as exc:
            logger.warning("ConversationMemory.history: Redis failed — %s", exc)
            return list(self._mem.get(session_id, deque()))[-limit:]

    async def clear(self, session_id: str) -> None:
        if self._redis is None:
            self._mem.pop(session_id, None)
            return
        try:
            await self._redis.delete(f"{_HIST_PREFIX}{session_id}", f"{_META_PREFIX}{session_id}")
        except Exception as exc:
            logger.warning("ConversationMemory.clear: Redis failed — %s", exc)
            self._mem.pop(session_id, None)

    async def list_sessions(self) -> list[str]:
        """Return session_ids with at least one stored turn (for diagnostics)."""
        if self._redis is None:
            return list(self._mem.keys())
        try:
            keys = await self._redis.keys(f"{_HIST_PREFIX}*")
            return [k.removeprefix(_HIST_PREFIX) for k in keys]
        except Exception:
            return list(self._mem.keys())

    # ── prompt helpers ────────────────────────────────────────────────────────

    @staticmethod
    def format_for_prompt(turns: Iterable[dict], max_chars: int = 2000) -> str:
        """Render history as a chat transcript chunk for inclusion in a prompt."""
        lines = []
        total = 0
        for t in turns:
            line = f"{t['role'].title()}: {t['content']}"
            total += len(line) + 1
            if total > max_chars:
                break
            lines.append(line)
        return "\n".join(lines)


conversation_memory = ConversationMemory()
