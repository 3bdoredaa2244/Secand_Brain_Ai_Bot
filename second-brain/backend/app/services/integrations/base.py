"""
Base interface for all external integrations.

Each integration must:
  - implement connect() / disconnect()
  - report health_check() → bool
  - expose a `mock: bool` flag (True when running against fake data)

Real credentials are injected via Settings. When they are absent the service
automatically operates in mock mode — callers never need to branch.
"""
from abc import ABC, abstractmethod

from app.core.logging import get_logger

logger = get_logger(__name__)


class BaseIntegration(ABC):
    name: str = "base"

    def __init__(self) -> None:
        self.mock: bool = True        # flipped to False once real creds are present
        self._connected: bool = False

    # ── lifecycle ─────────────────────────────────────────────────────────────

    @abstractmethod
    async def connect(self) -> bool:
        """Attempt to establish a connection. Returns True on success."""

    async def disconnect(self) -> None:
        self._connected = False

    # ── health ────────────────────────────────────────────────────────────────

    async def health_check(self) -> bool:
        """Return True when the integration is reachable."""
        return self._connected

    # ── helpers ───────────────────────────────────────────────────────────────

    def _log_mock(self, method: str) -> None:
        logger.debug("%s.%s called in mock mode", self.name, method)
