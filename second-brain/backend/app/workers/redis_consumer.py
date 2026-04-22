"""
Redis stream consumer — reads events from action and trigger streams.
Phase 1 skeleton: connection handling + message dispatch loop.
"""
import asyncio
import json
from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)
settings = get_settings()


class RedisStreamConsumer:
    def __init__(self) -> None:
        self._redis = None
        self._running = False

    async def connect(self) -> None:
        try:
            import redis.asyncio as aioredis  # noqa: PLC0415
            self._redis = await aioredis.from_url(settings.redis_url, decode_responses=True)
            await self._redis.ping()
            logger.info("RedisStreamConsumer: connected to %s", settings.redis_url)
        except Exception as exc:
            logger.warning("RedisStreamConsumer: Redis unavailable — %s (running offline)", exc)

    async def start(self) -> None:
        self._running = True
        streams = {
            settings.redis_stream_actions: "$",
            settings.redis_stream_triggers: "$",
        }
        logger.info("RedisStreamConsumer: starting, watching %s", list(streams.keys()))

        while self._running:
            if self._redis is None:
                await asyncio.sleep(5)
                continue
            try:
                results = await self._redis.xread(streams, block=1000, count=10)
                for stream_name, messages in results:
                    for msg_id, data in messages:
                        await self._dispatch(stream_name, msg_id, data)
                        streams[stream_name] = msg_id
            except Exception as exc:
                logger.error("RedisStreamConsumer error: %s", exc)
                await asyncio.sleep(1)

    async def stop(self) -> None:
        self._running = False
        if self._redis:
            await self._redis.aclose()

    async def _dispatch(self, stream: str, msg_id: str, data: dict) -> None:
        logger.debug("Stream %s | msg %s | data %s", stream, msg_id, data)
        # Phase 2: route to trigger evaluators and action handlers


consumer = RedisStreamConsumer()
