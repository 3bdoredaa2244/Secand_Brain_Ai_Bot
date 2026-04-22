"""
Scheduled triggers — fire on a time-based schedule.
Phase 1 stubs for: daily briefing, bill due reminder, flight check-in.
"""
from app.models.trigger import TriggerDefinition, TriggerDomain, TriggerEvent, TriggerType
from app.services.triggers.base import BaseTrigger
from app.core.logging import get_logger

logger = get_logger(__name__)


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


SCHEDULED_TRIGGERS: list[BaseTrigger] = [
    DailyBriefingTrigger(),
    BillDueReminderTrigger(),
]
