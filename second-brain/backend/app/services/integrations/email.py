"""
Email integration — interface + mock implementation.

Mock returns realistic-looking fake data so the rest of the pipeline
(keyword triggers, RAG indexing of email subjects) can be tested
without real Gmail credentials.

To wire real Gmail:
  1. Set GMAIL_CLIENT_ID, GMAIL_CLIENT_SECRET, GMAIL_REFRESH_TOKEN in .env
  2. pip install google-auth google-auth-oauthlib google-api-python-client
  3. Replace _fetch_real() stub below with actual Gmail API calls
"""
from dataclasses import dataclass, field
from datetime import datetime

from app.core.config import get_settings
from app.core.logging import get_logger
from app.services.integrations.base import BaseIntegration

logger = get_logger(__name__)
settings = get_settings()


@dataclass
class EmailMessage:
    id: str
    subject: str
    sender: str
    snippet: str
    received_at: datetime
    labels: list[str] = field(default_factory=list)
    body: str = ""


class EmailService(BaseIntegration):
    name = "email"

    async def connect(self) -> bool:
        has_creds = bool(
            settings.gmail_client_id
            and settings.gmail_client_secret
            and settings.gmail_refresh_token
        )
        if has_creds:
            # Phase 3: initialise google-auth client here
            logger.info("EmailService: real credentials found — stub connect (Phase 3 wires this)")
            self.mock = False
        else:
            logger.info("EmailService: no Gmail credentials — running in mock mode")
            self.mock = True

        self._connected = True
        return True

    # ── public interface ──────────────────────────────────────────────────────

    async def list_recent(self, max_results: int = 10) -> list[EmailMessage]:
        """Return the most recent emails."""
        if self.mock:
            self._log_mock("list_recent")
            return _mock_emails()[:max_results]
        return await self._fetch_real(max_results)

    async def search(self, query: str, max_results: int = 10) -> list[EmailMessage]:
        """Search emails by Gmail query string (e.g. 'subject:invoice')."""
        if self.mock:
            self._log_mock("search")
            return [e for e in _mock_emails() if query.lower() in e.subject.lower()][:max_results]
        return await self._fetch_real(max_results, query=query)

    async def has_keyword(self, keyword: str) -> bool:
        """True if any recent email contains *keyword* in subject or snippet."""
        emails = await self.list_recent(max_results=20)
        kw = keyword.lower()
        return any(kw in e.subject.lower() or kw in e.snippet.lower() for e in emails)

    # ── real implementation (Phase 3) ─────────────────────────────────────────

    async def _fetch_real(
        self, max_results: int, query: str = ""
    ) -> list[EmailMessage]:
        logger.warning("EmailService._fetch_real: not yet implemented — returning empty list")
        return []


# ── mock data ─────────────────────────────────────────────────────────────────

def _mock_emails() -> list[EmailMessage]:
    now = datetime.now()
    return [
        EmailMessage(
            id="mock-001",
            subject="Invoice #1042 from AWS",
            sender="billing@aws.amazon.com",
            snippet="Your AWS bill for April is ready.",
            received_at=now,
            labels=["INBOX", "UNREAD"],
        ),
        EmailMessage(
            id="mock-002",
            subject="Flight confirmation — Cairo → Dubai",
            sender="noreply@flydubai.com",
            snippet="Your booking is confirmed. Departure: 2026-06-01 08:30.",
            received_at=now,
            labels=["INBOX"],
        ),
        EmailMessage(
            id="mock-003",
            subject="Weekly team standup notes",
            sender="team@company.com",
            snippet="Hi all, here are the notes from this week's standup...",
            received_at=now,
            labels=["INBOX"],
        ),
    ]


email_service = EmailService()
