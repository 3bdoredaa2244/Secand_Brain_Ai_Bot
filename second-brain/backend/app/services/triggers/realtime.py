"""
Real-time triggers — fire immediately when a condition is detected.
Phase 1 stubs for: price alert, email keyword, flight delay.
"""
from app.models.trigger import TriggerDefinition, TriggerDomain, TriggerEvent, TriggerType
from app.services.triggers.base import BaseTrigger
from app.core.logging import get_logger

logger = get_logger(__name__)


class PriceAlertTrigger(BaseTrigger):
    definition = TriggerDefinition(
        name="price_alert",
        trigger_type=TriggerType.realtime,
        domain=TriggerDomain.shopping,
        description="Fires when a tracked product drops below target price",
        condition="current_price <= target_price",
        action_suggestion="buy_product",
    )

    async def evaluate(self, payload: dict) -> TriggerEvent | None:
        current = payload.get("current_price")
        target = payload.get("target_price")
        if current is not None and target is not None and float(current) <= float(target):
            logger.info("PriceAlertTrigger fired: %s <= %s", current, target)
            return TriggerEvent(
                trigger_type=self.definition.trigger_type,
                domain=self.definition.domain,
                name=self.definition.name,
                payload=payload,
            )
        return None


class EmailKeywordTrigger(BaseTrigger):
    definition = TriggerDefinition(
        name="email_keyword",
        trigger_type=TriggerType.realtime,
        domain=TriggerDomain.communication,
        description="Fires when an email contains a high-priority keyword",
        condition="keyword in email.subject or email.body",
        action_suggestion="send_email",
    )

    async def evaluate(self, payload: dict) -> TriggerEvent | None:
        keywords = payload.get("keywords", [])
        text = f"{payload.get('subject', '')} {payload.get('body', '')}".lower()
        if any(kw.lower() in text for kw in keywords):
            logger.info("EmailKeywordTrigger fired on keywords: %s", keywords)
            return TriggerEvent(
                trigger_type=self.definition.trigger_type,
                domain=self.definition.domain,
                name=self.definition.name,
                payload=payload,
            )
        return None


REALTIME_TRIGGERS: list[BaseTrigger] = [
    PriceAlertTrigger(),
    EmailKeywordTrigger(),
]
