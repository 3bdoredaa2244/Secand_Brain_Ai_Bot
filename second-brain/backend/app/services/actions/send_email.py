from app.models.action import ActionPlan, ActionRequest, ActionResult, ActionStatus, ActionType
from app.services.actions.base import BaseAction
from app.core.logging import get_logger

logger = get_logger(__name__)


class SendEmailAction(BaseAction):
    action_type = ActionType.send_email

    async def prepare(self, parameters: dict) -> ActionPlan:
        to = parameters.get("to", "")
        subject = parameters.get("subject", "(no subject)")
        return ActionPlan(
            action_type=ActionType.send_email,
            description=f"Send email to {to} — Subject: {subject}",
            parameters=parameters,
            reversible=False,
            risks=["Email cannot be unsent once delivered"],
        )

    async def execute(self, request: ActionRequest) -> ActionResult:
        # Phase 2: integrate email provider (SMTP / Gmail API)
        logger.info("SendEmailAction.execute — stub, not yet connected")
        return ActionResult(
            action_id=request.id,
            status=ActionStatus.completed,
            output={"message": "stub — email not yet sent"},
        )


send_email = SendEmailAction()
