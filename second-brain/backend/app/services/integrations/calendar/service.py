"""
Legacy CalendarService — preserved for backwards compatibility with code
that does `from app.services.integrations.calendar import calendar_service`.

The original Phase 2 implementation lived in
`services/integrations/calendar.py` as a flat module with mock data.
This file restores that surface unchanged, but now bridges to the real
CalendarClient when Google OAuth is connected.

Triggers in `triggers/scheduled.py` and `main.py` import `calendar_service`
from here — do not remove this file.
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
    """Legacy dataclass — kept for backwards compatibility with triggers."""
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
        try:
            from app.services.integrations.calendar.client import calendar_client  # noqa: PLC0415
            if calendar_client.is_ready():
                logger.info("CalendarService: Google OAuth tokens present — using real client")
                self.mock = False
            else:
                logger.info("CalendarService: no Google tokens — running in mock mode")
                self.mock = True
        except Exception as exc:
            logger.warning("CalendarService: client import failed (%s) — mock mode", exc)
            self.mock = True

        self._connected = True
        return True

    # ── public interface (preserved from Phase 2) ─────────────────────────────

    async def list_today(self) -> list[CalendarEvent]:
        if self.mock:
            self._log_mock("list_today")
            return _mock_today_events()
        return await self._fetch_real()

    async def list_upcoming(self, days: int = 7) -> list[CalendarEvent]:
        if self.mock:
            self._log_mock("list_upcoming")
            return _mock_upcoming_events(days)
        return await self._fetch_real(days=days)

    async def events_within_minutes(self, minutes: int = 30) -> list[CalendarEvent]:
        now = datetime.now()
        cutoff = now + timedelta(minutes=minutes)
        events = await self.list_today()
        return [e for e in events if now <= e.start <= cutoff]

    # ── real bridge ───────────────────────────────────────────────────────────

    async def _fetch_real(self, days: int = 1) -> list[CalendarEvent]:
        from app.services.integrations.calendar.client import calendar_client  # noqa: PLC0415
        if days <= 1:
            models = await calendar_client.list_today()
        else:
            models = await calendar_client.list_upcoming(days=days)
        return [
            CalendarEvent(
                id=m.id,
                title=m.summary,
                start=m.start,
                end=m.end,
                description=m.description,
                location=m.location,
                attendees=[a.email for a in m.attendees],
                all_day=m.all_day,
            )
            for m in models
        ]


# ── mock data (preserved from Phase 2) ───────────────────────────────────────

def _mock_today_events() -> list[CalendarEvent]:
    now = datetime.now().replace(second=0, microsecond=0)
    return [
        CalendarEvent(
            id="mock-cal-001", title="Morning standup",
            start=now.replace(hour=9, minute=0), end=now.replace(hour=9, minute=30),
            attendees=["alice@company.com", "bob@company.com"],
        ),
        CalendarEvent(
            id="mock-cal-002", title="Deep work block — Second Brain dev",
            start=now.replace(hour=10, minute=0), end=now.replace(hour=12, minute=0),
        ),
        CalendarEvent(
            id="mock-cal-003", title="Lunch",
            start=now.replace(hour=13, minute=0), end=now.replace(hour=14, minute=0),
        ),
    ]


def _mock_upcoming_events(days: int) -> list[CalendarEvent]:
    base = _mock_today_events()
    now = datetime.now()
    extras = []
    for d in range(1, min(days, 7)):
        extras.append(CalendarEvent(
            id=f"mock-cal-future-{d}",
            title=f"Placeholder event day+{d}",
            start=now + timedelta(days=d, hours=10),
            end=now + timedelta(days=d, hours=11),
        ))
    return base + extras


calendar_service = CalendarService()
