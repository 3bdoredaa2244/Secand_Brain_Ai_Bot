"""
Scheduled triggers — fire on a time-based schedule.
"""
from datetime import datetime

from app.core.config import get_settings
from app.core.logging import get_logger
from app.models.health import DailyHealthSummary
from app.models.trigger import TriggerDefinition, TriggerDomain, TriggerEvent, TriggerType
from app.services.triggers.base import BaseTrigger

logger = get_logger(__name__)
settings = get_settings()


class DailyBriefingTrigger(BaseTrigger):
    definition = TriggerDefinition(
        name="daily_briefing",
        trigger_type=TriggerType.scheduled,
        domain=TriggerDomain.general,
        description="Fires every morning to generate a daily brief from the vault",
        condition="cron: 0 7 * * *",
    )

    async def evaluate(self, payload: dict) -> TriggerEvent | None:
        logger.info("DailyBriefingTrigger fired")
        return TriggerEvent(
            trigger_type=self.definition.trigger_type,
            domain=self.definition.domain,
            name=self.definition.name,
            payload=payload,
        )


class BillDueReminderTrigger(BaseTrigger):
    definition = TriggerDefinition(
        name="bill_due_reminder",
        trigger_type=TriggerType.scheduled,
        domain=TriggerDomain.finance,
        description="Fires 3 days before a bill due date",
        condition="days_until_due <= 3",
        action_suggestion="send_email",
    )

    async def evaluate(self, payload: dict) -> TriggerEvent | None:
        days = payload.get("days_until_due")
        if days is not None and int(days) <= 3:
            logger.info("BillDueReminderTrigger fired: %d days until due", days)
            return TriggerEvent(
                trigger_type=self.definition.trigger_type,
                domain=self.definition.domain,
                name=self.definition.name,
                payload=payload,
            )
        return None


class DailyHealthCheckTrigger(BaseTrigger):
    definition = TriggerDefinition(
        name="daily_health_check",
        trigger_type=TriggerType.scheduled,
        domain=TriggerDomain.health,
        description=(
            f"Fires at {settings.health_check_hour:02d}:00 each day with a summary "
            "of vitamins and routines due"
        ),
        condition=f"cron: 0 {settings.health_check_hour} * * *",
    )

    async def evaluate(self, payload: dict) -> TriggerEvent | None:
        now = datetime.now()
        if now.hour != settings.health_check_hour and not payload.get("force"):
            return None

        summary = DailyHealthSummary(
            date=now.strftime("%Y-%m-%d"),
            check_time=now.strftime("%H:%M"),
            vitamins_due=settings.vitamins_list(),
            routines_due=payload.get("routines_due", []),
        )
        logger.info(
            "DailyHealthCheckTrigger fired: %d vitamins, %d routines due",
            len(summary.vitamins_due), len(summary.routines_due),
        )
        return TriggerEvent(
            trigger_type=self.definition.trigger_type,
            domain=self.definition.domain,
            name=self.definition.name,
            payload=summary.model_dump(),
        )


SCHEDULED_TRIGGERS: list[BaseTrigger] = [
    DailyBriefingTrigger(),
    BillDueReminderTrigger(),
    DailyHealthCheckTrigger(),
]
