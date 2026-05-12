"""Google Calendar integration package.

Re-exports the legacy `calendar_service` singleton so that existing imports
(`from app.services.integrations.calendar import calendar_service`) keep
working unchanged after we split the module into a package.
"""
from app.services.integrations.calendar.client import CalendarClient, calendar_client
from app.services.integrations.calendar.service import CalendarEvent, CalendarService, calendar_service

__all__ = [
    "CalendarClient", "calendar_client",
    "CalendarService", "calendar_service", "CalendarEvent",
]
