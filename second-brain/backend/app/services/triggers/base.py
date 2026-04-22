"""
Base trigger class. All trigger types extend this.
"""
from abc import ABC, abstractmethod
from app.models.trigger import TriggerEvent, TriggerDefinition
from app.core.logging import get_logger

logger = get_logger(__name__)


class BaseTrigger(ABC):
    definition: TriggerDefinition

    @abstractmethod
    async def evaluate(self, payload: dict) -> TriggerEvent | None:
        """Evaluate payload and return a TriggerEvent if the trigger fires, else None."""
        ...

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__} name={self.definition.name}>"
