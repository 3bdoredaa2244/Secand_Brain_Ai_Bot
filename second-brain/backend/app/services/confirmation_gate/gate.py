"""
Confirmation gate — every action must pass through here before execution.
No action is ever executed without explicit approval.
"""
import asyncio
from datetime import datetime
from uuid import UUID
from app.core.logging import get_logger
from app.models.action import ActionRequest, ActionConfirmation, ActionResult, ActionStatus

logger = get_logger(__name__)

# In-memory store for pending confirmations (Phase 1 — replace with Redis in Phase 2)
_pending: dict[UUID, ActionRequest] = {}
_results: dict[UUID, ActionResult] = {}


class ConfirmationGate:
    async def submit(self, request: ActionRequest) -> ActionRequest:
        """Register an action and block it pending user confirmation."""
        request.status = ActionStatus.awaiting_confirmation
        _pending[request.id] = request
        logger.info("Gate: action %s submitted, awaiting confirmation", request.id)
        return request

    async def confirm(self, confirmation: ActionConfirmation) -> ActionResult:
        """Accept or reject a pending action."""
        request = _pending.get(confirmation.action_id)
        if request is None:
            raise KeyError(f"No pending action with id {confirmation.action_id}")

        if confirmation.approved:
            request.status = ActionStatus.confirmed
            logger.info("Gate: action %s APPROVED", confirmation.action_id)
            result = ActionResult(
                action_id=confirmation.action_id,
                status=ActionStatus.confirmed,
            )
        else:
            request.status = ActionStatus.rejected
            logger.info("Gate: action %s REJECTED — %s", confirmation.action_id, confirmation.note)
            result = ActionResult(
                action_id=confirmation.action_id,
                status=ActionStatus.rejected,
            )

        _results[confirmation.action_id] = result
        del _pending[confirmation.action_id]
        return result

    def list_pending(self) -> list[ActionRequest]:
        return list(_pending.values())

    def get_result(self, action_id: UUID) -> ActionResult | None:
        return _results.get(action_id)


gate = ConfirmationGate()
