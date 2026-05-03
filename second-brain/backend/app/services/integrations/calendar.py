"""
Calendar integration — interface + mock implementation.

Mock returns realistic-looking fake events so reminder triggers and
the daily briefing can be tested without real Google Calendar credentials.

To wire real Google Calendar:
  1. Set GOOGLE_CALENDAR_CREDENTIALS_JSON in .env (path to credentials file)
  2. pip install google-auth google-auth-oauthlib google-api-python-client
  3. Replace _fetch_real() stub below with actual Calendar API calls
"""
from dataclasses import dataclass, field
from datetime import datetime, timedelta

from app.core.config import get_settings
from app.core.logging import get_logger
from app.services.integrations.base import BaseIntegration

logger = get_logger(__name__)
settings = get_settings()


@dataclass
class CalendarEvent:
    id: str
    title: str
    start: datetime
    end: datetime
    description: str = ""
    location: str = ""
    attendees: list[str] = field(default_factory=list)
    all_day: bool = False


class CalendarService(BaseIntegration):
    name = "calendar"

    async def connect(self) -> bool:
        has_creds = bool(settings.google_calendar_credentials_json)
        if has_creds:
            logger.info("CalendarService: credentials found — stub connect (Phase 3 wires this)")
            self.mock = False
        else:
            logger.info("CalendarService: no credentials — running in mock mode")
            self.mock = True

        self._connected = True
        return True

    # ── public interface ──────────────────────────────────────────────────────

    async def list_today(self) -> list[CalendarEvent]:
        """Return all events scheduled for today."""
        if self.mock:
            self._log_mock("list_today")
            return _mock_today_events()
        return await self._fetch_real(days=1)

    async def list_upcoming(self, days: int = 7) -> list[CalendarEvent]:
        """Return events in the next *days* days."""
        if self.mock:
            self._log_mock("list_upcoming")
            return _mock_upcoming_events(days)
        return await self._fetch_real(days=days)

    async def events_within_minutes(self, minutes: int = 30) -> list[CalendarEvent]:
        """Return events starting within *minutes* minutes."""
        now = datetime.now()
        cutoff = now + timedelta(minutes=minutes)
        events = await self.list_today()
        return [e for e in events if now <= e.start <= cutoff]

    # ── real implementation (Phase 3) ─────────────────────────────────────────

    async def _fetch_real(self, days: int = 1) -> list[CalendarEvent]:
        logger.warning("CalendarService._fetch_real: not yet implemented — returning empty list")
        return []


# ── mock data ─────────────────────────────────────────────────────────────────

def _mock_today_events() -> list[CalendarEvent]:
    now = datetime.now().replace(second=0, microsecond=0)
    return [
        CalendarEvent(
            id="mock-cal-001",
            title="Morning standup",
            start=now.replace(hour=9, minute=0),
            end=now.replace(hour=9, minute=30),
            attendees=["alice@company.com", "bob@company.com"],
        ),
        CalendarEvent(
            id="mock-cal-002",
            title="Deep work block — Second Brain dev",
            start=now.replace(hour=10, minute=0),
            end=now.replace(hour=12, minute=0),
        ),
        CalendarEvent(
            id="mock-cal-003",
            title="Lunch",
            start=now.replace(hour=13, minute=0),
            end=now.replace(hour=14, minute=0),
            all_day=False,
        ),
    ]


def _mock_upcoming_events(days: int) -> list[CalendarEvent]:
    base = _mock_today_events()
    now = datetime.now()
    extras = []
    for d in range(1, min(days, 7)):
        extras.append(
            CalendarEvent(
                id=f"mock-cal-future-{d}",
                title=f"Placeholder event day+{d}",
                start=now + timedelta(days=d, hours=10),
                end=now + timedelta(days=d, hours=11),
            )
        )
    return base + extras


calendar_service = CalendarService()
