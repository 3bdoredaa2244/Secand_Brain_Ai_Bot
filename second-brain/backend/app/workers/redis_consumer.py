"""
Redis stream consumer — reads events from action and trigger streams.

Dispatch logic (Phase 2):
  stream:triggers  → evaluate the named trigger; if it fires, submit an action
                     plan to the confirmation gate
  stream:actions   → log the incoming action event (execution happens after
                     the user approves via the confirmation gate)
"""
import asyncio
import json

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)
settings = get_settings()

_BACKOFF_MIN = 2
_BACKOFF_MAX = 30


class RedisStreamConsumer:
    def __init__(self) -> None:
        self._redis = None
        self._running = False

    async def connect(self) -> bool:
        """Attempt a single connection. Returns True on success."""
        try:
            import redis.asyncio as aioredis  # noqa: PLC0415
            client = await aioredis.from_url(settings.redis_url, decode_responses=True)
            await client.ping()
            self._redis = client
            logger.info("RedisStreamConsumer: connected to %s", settings.redis_url)
            return True
        except Exception as exc:
            logger.warning("RedisStreamConsumer: cannot connect to Redis — %s", exc)
            return False

    async def start(self) -> None:
        self._running = True
        backoff = _BACKOFF_MIN
        streams = {
            settings.redis_stream_actions: "$",
            settings.redis_stream_triggers: "$",
        }
        logger.info("RedisStreamConsumer: starting, watching %s", list(streams.keys()))

        while self._running:
            # Reconnect if we have no client
            if self._redis is None:
                connected = await self.connect()
                if not connected:
                    logger.info(
                        "RedisStreamConsumer: retrying in %ds (Redis at %s not yet available)",
                        backoff, settings.redis_url,
                    )
                    await asyncio.sleep(backoff)
                    backoff = min(backoff * 2, _BACKOFF_MAX)
                    continue
                backoff = _BACKOFF_MIN

            try:
                results = await self._redis.xread(streams, block=1000, count=10)
                for stream_name, messages in results:
                    for msg_id, data in messages:
                        await self._dispatch(stream_name, msg_id, data)
                        streams[stream_name] = msg_id
            except Exception as exc:
                logger.warning(
                    "RedisStreamConsumer: connection lost — %s. Reconnecting in %ds", exc, backoff
                )
                try:
                    await self._redis.aclose()
                except Exception:
                    pass
                self._redis = None
                await asyncio.sleep(backoff)
                backoff = min(backoff * 2, _BACKOFF_MAX)

    async def stop(self) -> None:
        self._running = False
        if self._redis:
            await self._redis.aclose()

    async def _dispatch(self, stream: str, msg_id: str, data: dict) -> None:
        logger.debug("Stream %s | msg %s | data %s", stream, msg_id, data)

        if stream == settings.redis_stream_triggers:
            await self._handle_trigger(data)
        elif stream == settings.redis_stream_actions:
            await self._handle_action(data)

    async def _handle_trigger(self, data: dict) -> None:
        """Evaluate the named trigger and log the fired event."""
        name = data.get("name", "unknown")
        try:
            payload = json.loads(data.get("payload", "{}"))
        except json.JSONDecodeError:
            payload = dict(data)

        # Import here to avoid circular imports at module load time
        from app.services.triggers.scheduled import SCHEDULED_TRIGGERS  # noqa: PLC0415
        from app.services.triggers.realtime import REALTIME_TRIGGERS     # noqa: PLC0415
        from app.services.triggers.semantic import SEMANTIC_TRIGGERS     # noqa: PLC0415

        all_triggers = SCHEDULED_TRIGGERS + REALTIME_TRIGGERS + SEMANTIC_TRIGGERS
        trigger = next((t for t in all_triggers if t.definition.name == name), None)

        if trigger is None:
            logger.warning("RedisStreamConsumer: unknown trigger '%s' — ignoring", name)
            return

        try:
            event = await trigger.evaluate(payload)
            if event:
                logger.info(
                    "RedisStreamConsumer: trigger '%s' fired → domain=%s",
                    event.name, event.domain,
                )
        except Exception as exc:
            logger.error("RedisStreamConsumer: trigger '%s' raised — %s", name, exc)

    async def _handle_action(self, data: dict) -> None:
        """Log an inbound action event (execution only after gate approval)."""
        action_type = data.get("type", "unknown")
        action_id = data.get("id", "?")
        logger.info(
            "RedisStreamConsumer: action event received — type=%s id=%s",
            action_type, action_id,
        )


consumer = RedisStreamConsumer()
