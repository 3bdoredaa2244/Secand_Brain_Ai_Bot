from app.models.action import ActionPlan, ActionRequest, ActionResult, ActionStatus, ActionType
from app.services.actions.base import BaseAction
from app.core.logging import get_logger

logger = get_logger(__name__)


class BookFlightAction(BaseAction):
    action_type = ActionType.book_flight

    async def prepare(self, parameters: dict) -> ActionPlan:
        origin = parameters.get("origin", "?")
        destination = parameters.get("destination", "?")
        date = parameters.get("date", "?")
        return ActionPlan(
            action_type=ActionType.book_flight,
            description=f"Book flight {origin} → {destination} on {date}",
            parameters=parameters,
            estimated_cost=parameters.get("estimated_cost"),
            reversible=False,
            risks=["Booking may be non-refundable", "Requires payment authorization"],
        )

    async def execute(self, request: ActionRequest) -> ActionResult:
        # Phase 2: integrate travel API (Amadeus / Skyscanner)
        logger.info("BookFlightAction.execute — stub, not yet connected")
        return ActionResult(
            action_id=request.id,
            status=ActionStatus.completed,
            output={"message": "stub — flight not yet booked"},
        )


book_flight = BookFlightAction()
