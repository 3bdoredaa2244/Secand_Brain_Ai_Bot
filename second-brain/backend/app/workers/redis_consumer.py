"""
Redis stream consumer — reads events from action and trigger streams.
Phase 1 skeleton: connection handling + message dispatch loop.
"""
import asyncio
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
        # Phase 2: route to trigger evaluators and action handlers


consumer = RedisStreamConsumer()
