"""
Google Calendar API client — async wrapper around google-api-python-client.

Shares OAuth credentials with Gmail (single Google account, single consent).
All operations are idempotent and never raise — failures log and return safe
defaults so the agent degrades gracefully.

Operations
──────────
  list_events    — events in a time window
  get_event      — fetch one event
  create_event   — create a new event (called from confirmation-gated action)
  update_event   — modify an existing event
  delete_event   — remove an event
  free_busy      — find open slots in a window
"""
from __future__ import annotations

import asyncio
from datetime import datetime, time, timedelta, timezone
from typing import Any

from app.core.logging import get_logger
from app.models.calendar import (
    CalendarAttendee, CalendarEventModel, FreeBusySlot,
)
from app.services.integrations.gmail.oauth import oauth_handler

logger = get_logger(__name__)


class CalendarClient:
    """Async wrapper around the Google Calendar v3 API."""

    # ── readiness ─────────────────────────────────────────────────────────────

    def is_ready(self) -> bool:
        try:
            return oauth_handler.load_credentials() is not None
        except Exception:
            return False

    # ── operations ────────────────────────────────────────────────────────────

    async def list_events(
        self,
        time_min: datetime | None = None,
        time_max: datetime | None = None,
        max_results: int = 25,
        calendar_id: str = "primary",
    ) -> list[CalendarEventModel]:
        try:
            return await asyncio.to_thread(
                self._list_events_sync, time_min, time_max, max_results, calendar_id,
            )
        except Exception as exc:
            logger.error("CalendarClient.list_events: %s", exc)
            return []

    async def list_today(self) -> list[CalendarEventModel]:
        """Events scheduled for the local 'today' (midnight to midnight)."""
        today = datetime.now().astimezone()
        start = today.replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=1)
        return await self.list_events(time_min=start, time_max=end, max_results=50)

    async def list_upcoming(self, days: int = 7) -> list[CalendarEventModel]:
        now = datetime.now().astimezone()
        return await self.list_events(time_min=now, time_max=now + timedelta(days=days), max_results=100)

    async def get_event(self, event_id: str, calendar_id: str = "primary") -> CalendarEventModel | None:
        try:
            return await asyncio.to_thread(self._get_event_sync, event_id, calendar_id)
        except Exception as exc:
            logger.error("CalendarClient.get_event(%s): %s", event_id, exc)
            return None

    async def create_event(
        self,
        summary: str,
        start: datetime,
        end: datetime,
        description: str = "",
        location: str = "",
        attendees: list[str] | None = None,
        send_invites: bool = False,
        calendar_id: str = "primary",
    ) -> CalendarEventModel | None:
        try:
            return await asyncio.to_thread(
                self._create_event_sync,
                summary, start, end, description, location,
                attendees or [], send_invites, calendar_id,
            )
        except Exception as exc:
            logger.error("CalendarClient.create_event: %s", exc)
            return None

    async def update_event(
        self,
        event_id: str,
        updates: dict[str, Any],
        calendar_id: str = "primary",
    ) -> CalendarEventModel | None:
        try:
            return await asyncio.to_thread(self._update_event_sync, event_id, updates, calendar_id)
        except Exception as exc:
            logger.error("CalendarClient.update_event(%s): %s", event_id, exc)
            return None

    async def delete_event(self, event_id: str, calendar_id: str = "primary") -> bool:
        try:
            return await asyncio.to_thread(self._delete_event_sync, event_id, calendar_id)
        except Exception as exc:
            logger.error("CalendarClient.delete_event(%s): %s", event_id, exc)
            return False

    async def free_busy(
        self,
        time_min: datetime,
        time_max: datetime,
        min_slot_minutes: int = 30,
        work_hours: tuple[int, int] = (9, 18),
        calendar_id: str = "primary",
    ) -> tuple[list[FreeBusySlot], list[FreeBusySlot]]:
        """Return (free_slots, busy_periods). Free slots respect work_hours."""
        try:
            return await asyncio.to_thread(
                self._free_busy_sync, time_min, time_max, min_slot_minutes, work_hours, calendar_id,
            )
        except Exception as exc:
            logger.error("CalendarClient.free_busy: %s", exc)
            return [], []

    # ── sync impls (run in threadpool) ────────────────────────────────────────

    def _service(self):
        from googleapiclient.discovery import build  # noqa: PLC0415
        creds = oauth_handler.load_credentials()
        if creds is None:
            raise RuntimeError("Calendar not authorized — run /api/v1/auth/google/login")
        return build("calendar", "v3", credentials=creds, cache_discovery=False)

    def _list_events_sync(
        self, time_min: datetime | None, time_max: datetime | None,
        max_results: int, calendar_id: str,
    ) -> list[CalendarEventModel]:
        svc = self._service()
        params: dict[str, Any] = {
            "calendarId": calendar_id,
            "singleEvents": True,
            "orderBy": "startTime",
            "maxResults": max_results,
        }
        if time_min is not None:
            params["timeMin"] = _iso(time_min)
        if time_max is not None:
            params["timeMax"] = _iso(time_max)

        resp = svc.events().list(**params).execute()
        return [_parse_event(e) for e in resp.get("items", [])]

    def _get_event_sync(self, event_id: str, calendar_id: str) -> CalendarEventModel | None:
        svc = self._service()
        ev = svc.events().get(calendarId=calendar_id, eventId=event_id).execute()
        return _parse_event(ev)

    def _create_event_sync(
        self, summary: str, start: datetime, end: datetime, description: str,
        location: str, attendees: list[str], send_invites: bool, calendar_id: str,
    ) -> CalendarEventModel:
        svc = self._service()
        body: dict[str, Any] = {
            "summary": summary,
            "description": description,
            "location": location,
            "start": {"dateTime": _iso(start)},
            "end": {"dateTime": _iso(end)},
        }
        if attendees:
            body["attendees"] = [{"email": a} for a in attendees]
        result = svc.events().insert(
            calendarId=calendar_id, body=body,
            sendUpdates="all" if send_invites else "none",
        ).execute()
        return _parse_event(result)

    def _update_event_sync(
        self, event_id: str, updates: dict[str, Any], calendar_id: str,
    ) -> CalendarEventModel:
        svc = self._service()
        # Fetch then patch so we don't blow away unset fields
        existing = svc.events().get(calendarId=calendar_id, eventId=event_id).execute()
        if "summary" in updates:     existing["summary"] = updates["summary"]
        if "description" in updates: existing["description"] = updates["description"]
        if "location" in updates:    existing["location"] = updates["location"]
        if "start" in updates:       existing["start"] = {"dateTime": _iso(updates["start"])}
        if "end" in updates:         existing["end"] = {"dateTime": _iso(updates["end"])}
        if "attendees" in updates:
            existing["attendees"] = [{"email": a} for a in (updates["attendees"] or [])]
        result = svc.events().update(
            calendarId=calendar_id, eventId=event_id, body=existing,
        ).execute()
        return _parse_event(result)

    def _delete_event_sync(self, event_id: str, calendar_id: str) -> bool:
        svc = self._service()
        svc.events().delete(calendarId=calendar_id, eventId=event_id).execute()
        return True

    def _free_busy_sync(
        self, time_min: datetime, time_max: datetime, min_slot_minutes: int,
        work_hours: tuple[int, int], calendar_id: str,
    ) -> tuple[list[FreeBusySlot], list[FreeBusySlot]]:
        svc = self._service()
        resp = svc.freebusy().query(body={
            "timeMin": _iso(time_min),
            "timeMax": _iso(time_max),
            "items": [{"id": calendar_id}],
        }).execute()
        busy_raw = resp.get("calendars", {}).get(calendar_id, {}).get("busy", [])
        busy_periods: list[FreeBusySlot] = []
        for b in busy_raw:
            s = datetime.fromisoformat(b["start"].replace("Z", "+00:00"))
            e = datetime.fromisoformat(b["end"].replace("Z", "+00:00"))
            busy_periods.append(_slot(s, e))

        # Compute free slots respecting work hours
        free_slots = _compute_free_slots(time_min, time_max, busy_periods, min_slot_minutes, work_hours)
        return free_slots, busy_periods


# ── helpers ──────────────────────────────────────────────────────────────────

def _iso(dt: datetime) -> str:
    """RFC3339 timestamp with offset (Google requires UTC offset or 'Z')."""
    if dt.tzinfo is None:
        dt = dt.astimezone()  # attach local tz
    return dt.isoformat()


def _parse_event(ev: dict) -> CalendarEventModel:
    start_raw = ev.get("start", {})
    end_raw = ev.get("end", {})

    all_day = "date" in start_raw and "dateTime" not in start_raw
    if all_day:
        start = datetime.fromisoformat(start_raw["date"])
        end = datetime.fromisoformat(end_raw["date"])
    else:
        start = datetime.fromisoformat(start_raw["dateTime"].replace("Z", "+00:00"))
        end = datetime.fromisoformat(end_raw["dateTime"].replace("Z", "+00:00"))

    return CalendarEventModel(
        id=ev["id"],
        summary=ev.get("summary", "(no title)"),
        description=ev.get("description", ""),
        location=ev.get("location", ""),
        start=start,
        end=end,
        all_day=all_day,
        attendees=[
            CalendarAttendee(email=a["email"], response_status=a.get("responseStatus", "needsAction"))
            for a in ev.get("attendees", [])
        ],
        organizer=ev.get("organizer", {}).get("email"),
        html_link=ev.get("htmlLink"),
        timezone=start_raw.get("timeZone", "UTC"),
        status=ev.get("status", "confirmed"),
    )


def _slot(start: datetime, end: datetime) -> FreeBusySlot:
    return FreeBusySlot(
        start=start, end=end,
        duration_minutes=max(0, int((end - start).total_seconds() // 60)),
    )


def _compute_free_slots(
    time_min: datetime, time_max: datetime, busy: list[FreeBusySlot],
    min_minutes: int, work_hours: tuple[int, int],
) -> list[FreeBusySlot]:
    """Walk day-by-day; subtract busy periods; respect work hours."""
    out: list[FreeBusySlot] = []
    start_h, end_h = work_hours
    day = time_min.replace(hour=start_h, minute=0, second=0, microsecond=0)

    while day < time_max:
        work_start = day
        work_end = day.replace(hour=end_h)
        # busy periods overlapping today, sorted
        today_busy = sorted(
            [b for b in busy if b.start < work_end and b.end > work_start],
            key=lambda b: b.start,
        )
        cursor = work_start
        for b in today_busy:
            if b.start > cursor:
                slot = _slot(cursor, min(b.start, work_end))
                if slot.duration_minutes >= min_minutes:
                    out.append(slot)
            cursor = max(cursor, b.end)
        if cursor < work_end:
            slot = _slot(cursor, work_end)
            if slot.duration_minutes >= min_minutes:
                out.append(slot)
        day = day + timedelta(days=1)
    return out


calendar_client = CalendarClient()
