"""
Base action class. All action handlers extend this.
No action executes without passing through the ConfirmationGate.
"""
from abc import ABC, abstractmethod
from app.models.action import ActionPlan, ActionResult, ActionRequest
from app.services.confirmation_gate.gate import gate
from app.core.logging import get_logger

logger = get_logger(__name__)


class BaseAction(ABC):
    action_type: str

    @abstractmethod
    async def prepare(self, parameters: dict) -> ActionPlan:
        """Build the action plan from raw parameters. No side effects."""
        ...

    @abstractmethod
    async def execute(self, request: ActionRequest) -> ActionResult:
        """Execute an already-confirmed action. Never call directly — use run()."""
        ...

    async def run(self, parameters: dict) -> ActionRequest:
        """Full lifecycle: prepare → gate → (execute only after confirmation)."""
        plan = await self.prepare(parameters)
        request = ActionRequest(plan=plan)
        submitted = await gate.submit(request)
        logger.info("Action '%s' submitted to gate (id=%s)", self.action_type, submitted.id)
        return submitted
