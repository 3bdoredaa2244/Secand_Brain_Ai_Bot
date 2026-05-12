"""Pydantic models for Google Calendar API."""
from datetime import datetime

from pydantic import BaseModel, Field


class CalendarAttendee(BaseModel):
    email: str
    response_status: str = "needsAction"  # accepted | declined | tentative | needsAction


class CalendarEventModel(BaseModel):
    id: str
    summary: str                     # title
    description: str = ""
    location: str = ""
    start: datetime
    end: datetime
    all_day: bool = False
    attendees: list[CalendarAttendee] = Field(default_factory=list)
    organizer: str | None = None
    html_link: str | None = None     # link to event in Google Calendar
    timezone: str = "UTC"
    status: str = "confirmed"        # confirmed | tentative | cancelled


class CalendarEventList(BaseModel):
    events: list[CalendarEventModel]
    total: int
    mock: bool = False


class CreateEventRequest(BaseModel):
    summary: str = Field(..., min_length=1, max_length=200)
    description: str = Field(default="", max_length=5000)
    location: str = Field(default="", max_length=200)
    start: datetime
    end: datetime
    attendees: list[str] = Field(default_factory=list, description="Attendee email addresses")
    send_invites: bool = False


class UpdateEventRequest(BaseModel):
    summary: str | None = None
    description: str | None = None
    location: str | None = None
    start: datetime | None = None
    end: datetime | None = None
    attendees: list[str] | None = None


class FreeBusySlot(BaseModel):
    start: datetime
    end: datetime
    duration_minutes: int


class FreeBusyResponse(BaseModel):
    free_slots: list[FreeBusySlot]
    busy_periods: list[FreeBusySlot]
    timezone: str = "UTC"


class AgendaSummary(BaseModel):
    """Daily agenda — used by briefing endpoint + assistant."""
    date: datetime
    event_count: int
    events: list[CalendarEventModel]
    summary: str          # LLM-generated overview
    next_event: CalendarEventModel | None = None
    mock: bool = False
