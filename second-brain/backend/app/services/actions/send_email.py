"""
SendEmailAction — confirmation-gated email dispatch via Gmail API.

Flow:
  1. POST /gmail/draft (or /actions/prepare/send_email) creates this action and
     submits it to the confirmation gate
  2. User reviews via /actions/pending and approves via /actions/confirm
  3. Worker reads gate result and calls execute() — only THEN does the email send

If Gmail OAuth is not connected the action fails fast with a clear error;
the gate's approval mechanism is unchanged.
"""
from app.core.logging import get_logger
from app.models.action import ActionPlan, ActionRequest, ActionResult, ActionStatus, ActionType
from app.services.actions.base import BaseAction
from app.services.integrations.gmail.client import gmail_client

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
        params = request.plan.parameters
        to = params.get("to", "")
        subject = params.get("subject", "")
        body = params.get("body", "")
        cc = params.get("cc", []) or []

        if not gmail_client.is_ready():
            logger.warning("SendEmailAction: Gmail not authorized — cannot send")
            return ActionResult(
                action_id=request.id,
                status=ActionStatus.failed,
                output={"error": "Gmail not authorized. Visit /api/v1/auth/google/login first."},
            )

        message_id = await gmail_client.send_message(to=to, subject=subject, body=body, cc=cc)
        if not message_id:
            return ActionResult(
                action_id=request.id,
                status=ActionStatus.failed,
                output={"error": "Gmail API rejected the message — check server logs"},
            )

        logger.info("SendEmailAction: sent email %s to %s", message_id, to)
        return ActionResult(
            action_id=request.id,
            status=ActionStatus.completed,
            output={"message_id": message_id, "to": to, "subject": subject},
        )


send_email = SendEmailAction()
