"""Base contract for all external tools."""
from abc import ABC, abstractmethod
from dataclasses import dataclass, field


@dataclass
class ToolResult:
    answer: str
    data: dict = field(default_factory=dict)  # raw structured data (optional, for UI)


class BaseTool(ABC):
    name: str = ""
    description: str = ""

    @abstractmethod
    def matches(self, query: str) -> bool:
        """Return True if this tool should handle the query."""

    @abstractmethod
    async def run(self, query: str) -> ToolResult:
        """Execute the tool and return a structured result. Must never raise."""
