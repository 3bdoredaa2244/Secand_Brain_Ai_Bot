"""
Proactive worker — periodically scans vault and fires scheduled/semantic triggers.
Phase 1 skeleton: scheduling loop + trigger registry wiring.
"""
import asyncio
from app.core.config import get_settings
from app.core.logging import get_logger
from app.services.triggers.scheduled import SCHEDULED_TRIGGERS
from app.services.triggers.semantic import SEMANTIC_TRIGGERS

logger = get_logger(__name__)
settings = get_settings()

ALL_PROACTIVE_TRIGGERS = SCHEDULED_TRIGGERS + SEMANTIC_TRIGGERS
SCAN_INTERVAL_SECONDS = 60


class ProactiveWorker:
    def __init__(self) -> None:
        self._running = False

    async def start(self) -> None:
        self._running = True
        logger.info(
            "ProactiveWorker: starting with %d triggers, interval=%ds",
            len(ALL_PROACTIVE_TRIGGERS),
            SCAN_INTERVAL_SECONDS,
        )
        while self._running:
            await self._scan_cycle()
            await asyncio.sleep(SCAN_INTERVAL_SECONDS)

    async def stop(self) -> None:
        self._running = False

    async def _scan_cycle(self) -> None:
        for trigger in ALL_PROACTIVE_TRIGGERS:
            try:
                event = await trigger.evaluate({})
                if event:
                    logger.info("ProactiveWorker: trigger fired — %s", event.name)
                    # Phase 2: push event to Redis stream or notification queue
            except Exception as exc:
                logger.error("ProactiveWorker: error in trigger %s — %s", trigger, exc)


worker = ProactiveWorker()
