"""
IntentRouter — maps a user query to the first matching external tool.

Tools are checked in priority order. If none match, returns (None, None)
and the caller should fall back to vault RAG.

Adding a new tool:
  1. Create a class inheriting BaseTool in services/tools/
  2. Append an instance to _TOOLS below — order matters (first match wins)
"""
from app.core.logging import get_logger
from app.services.tools.base import BaseTool, ToolResult
from app.services.tools.crypto import CryptoTool
from app.services.tools.weather import WeatherTool

logger = get_logger(__name__)

# Priority order: more specific tools first
_TOOLS: list[BaseTool] = [
    CryptoTool(),
    WeatherTool(),
]


class IntentRouter:
    def route(self, query: str) -> BaseTool | None:
        """Return the first tool that claims this query, or None."""
        for tool in _TOOLS:
            try:
                if tool.matches(query):
                    logger.debug("IntentRouter: '%s' → tool '%s'", query[:60], tool.name)
                    return tool
            except Exception as exc:
                logger.warning("IntentRouter: tool '%s'.matches() raised — %s", tool.name, exc)
        return None

    async def run_tool(self, query: str) -> tuple[str | None, ToolResult | None]:
        """Route and execute. Returns (tool_name, result) or (None, None)."""
        tool = self.route(query)
        if tool is None:
            return None, None
        try:
            result = await tool.run(query)
            return tool.name, result
        except Exception as exc:
            logger.error("IntentRouter: tool '%s'.run() raised — %s", tool.name, exc)
            return tool.name, ToolResult(
                answer=f"The {tool.name} tool encountered an error. Falling back to vault search.",
                data={},
            )


router = IntentRouter()  # singleton
