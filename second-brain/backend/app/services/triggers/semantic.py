"""
Semantic triggers — fire when RAG detects a contextual pattern in vault content.
Phase 1 stubs for: travel intent, purchase intent, meeting follow-up gap.
"""
from app.models.trigger import TriggerDefinition, TriggerDomain, TriggerEvent, TriggerType
from app.services.triggers.base import BaseTrigger
from app.core.logging import get_logger

logger = get_logger(__name__)

TRAVEL_INTENT_KEYWORDS = ["fly", "flight", "hotel", "trip", "travel", "visit", "conference"]
PURCHASE_INTENT_KEYWORDS = ["buy", "purchase", "order", "get", "need", "want"]


class TravelIntentTrigger(BaseTrigger):
    definition = TriggerDefinition(
        name="travel_intent",
        trigger_type=TriggerType.semantic,
        domain=TriggerDomain.travel,
        description="Fires when vault content suggests an upcoming trip",
        condition="semantic similarity to travel intent > threshold",
        action_suggestion="book_flight",
    )

    async def evaluate(self, payload: dict) -> TriggerEvent | None:
        text = payload.get("text", "").lower()
        if any(kw in text for kw in TRAVEL_INTENT_KEYWORDS):
            logger.info("TravelIntentTrigger fired")
            return TriggerEvent(
                trigger_type=self.definition.trigger_type,
                domain=self.definition.domain,
                name=self.definition.name,
                payload=payload,
            )
        return None


class PurchaseIntentTrigger(BaseTrigger):
    definition = TriggerDefinition(
        name="purchase_intent",
        trigger_type=TriggerType.semantic,
        domain=TriggerDomain.shopping,
        description="Fires when vault content suggests a purchase need",
        condition="semantic similarity to purchase intent > threshold",
        action_suggestion="buy_product",
    )

    async def evaluate(self, payload: dict) -> TriggerEvent | None:
        text = payload.get("text", "").lower()
        if any(kw in text for kw in PURCHASE_INTENT_KEYWORDS):
            logger.info("PurchaseIntentTrigger fired")
            return TriggerEvent(
                trigger_type=self.definition.trigger_type,
                domain=self.definition.domain,
                name=self.definition.name,
                payload=payload,
            )
        return None


SEMANTIC_TRIGGERS: list[BaseTrigger] = [
    TravelIntentTrigger(),
    PurchaseIntentTrigger(),
]
