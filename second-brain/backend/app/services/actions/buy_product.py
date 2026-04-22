from app.models.action import ActionPlan, ActionRequest, ActionResult, ActionStatus, ActionType
from app.services.actions.base import BaseAction
from app.core.logging import get_logger

logger = get_logger(__name__)


class BuyProductAction(BaseAction):
    action_type = ActionType.buy_product

    async def prepare(self, parameters: dict) -> ActionPlan:
        product = parameters.get("product_name", "unknown product")
        price = parameters.get("price", "?")
        return ActionPlan(
            action_type=ActionType.buy_product,
            description=f"Purchase: {product} for {price}",
            parameters=parameters,
            estimated_cost=str(price),
            reversible=False,
            risks=["Charges payment method", "Return policy may be limited"],
        )

    async def execute(self, request: ActionRequest) -> ActionResult:
        # Phase 2: integrate e-commerce API (Amazon / Shopify)
        logger.info("BuyProductAction.execute — stub, not yet connected")
        return ActionResult(
            action_id=request.id,
            status=ActionStatus.completed,
            output={"message": "stub — product not yet purchased"},
        )


buy_product = BuyProductAction()
