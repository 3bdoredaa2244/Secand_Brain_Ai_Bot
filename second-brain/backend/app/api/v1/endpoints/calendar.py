"""
Google Calendar HTTP endpoints.

  GET    /calendar/today                 — today's events
  GET    /calendar/upcoming?days=7       — next N days
  GET    /calendar/events                — events in a time range (ISO query params)
  GET    /calendar/agenda                — daily summary (events + LLM digest)
  GET    /calendar/free-busy?days=7      — free / busy windows
  GET    /calendar/{event_id}            — fetch one event
  POST   /calendar/events                — propose a new event (gated)
  PATCH  /calendar/events/{event_id}     — propose an edit (gated)
  DELETE /calendar/events/{event_id}     — propose deletion (gated)
"""
from datetime import datetime, timedelta

from fastapi import APIRouter, HTTPException, Query

from app.core.logging import get_logger
from app.models.action import ActionPlan, ActionRequest, ActionStatus, ActionType
from app.models.calendar import (
    AgendaSummary, CalendarEventList, CalendarEventModel,
    CreateEventRequest, FreeBusyResponse, UpdateEventRequest,
)
from app.services.confirmation_gate.gate import gate
from app.services.integrations.calendar.agenda import summarize_agenda
from app.services.integrations.calendar.client import calendar_client

logger = get_logger(__name__)
router = APIRouter(prefix="/calendar", tags=["calendar"])


# ── read endpoints ──────────────────────────────────────────────────────────

@router.get("/today", response_model=CalendarEventList)
async def today() -> CalendarEventList:
    if not calendar_client.is_ready():
        return CalendarEventList(events=[], total=0, mock=True)
    events = await calendar_client.list_today()
    return CalendarEventList(events=events, total=len(events))


@router.get("/upcoming", response_model=CalendarEventList)
async def upcoming(days: int = Query(default=7, ge=1, le=60)) -> CalendarEventList:
    if not calendar_client.is_ready():
        return CalendarEventList(events=[], total=0, mock=True)
    events = await calendar_client.list_upcoming(days=days)
    return CalendarEventList(events=events, total=len(events))


@router.get("/events", response_model=CalendarEventList)
async def events_in_range(
    time_min: datetime = Query(..., description="ISO datetime, inclusive"),
    time_max: datetime = Query(..., description="ISO datetime, exclusive"),
    max_results: int = Query(default=50, ge=1, le=250),
) -> CalendarEventList:
    if not calendar_client.is_ready():
        return CalendarEventList(events=[], total=0, mock=True)
    events = await calendar_client.list_events(time_min=time_min, time_max=time_max, max_results=max_results)
    return CalendarEventList(events=events, total=len(events))


@router.get("/agenda", response_model=AgendaSummary)
async def agenda() -> AgendaSummary:
    """Today's events plus an LLM-generated narrative summary."""
    today_ = datetime.now().astimezone().replace(hour=0, minute=0, second=0, microsecond=0)

    if not calendar_client.is_ready():
        return AgendaSummary(
            date=today_, event_count=0, events=[],
            summary="Calendar not connected. Authorize via /api/v1/auth/google/login.",
            mock=True,
        )

    events = await calendar_client.list_today()
    summary_text = await summarize_agenda(events, when="today")
    next_ev = next((e for e in events if e.start > datetime.now().astimezone()), None)
    return AgendaSummary(
        date=today_,
        event_count=len(events),
        events=events,
        summary=summary_text,
        next_event=next_ev,
    )


@router.get("/free-busy", response_model=FreeBusyResponse)
async def free_busy(
    days: int = Query(default=7, ge=1, le=30),
    min_slot_minutes: int = Query(default=30, ge=15, le=480),
) -> FreeBusyResponse:
    if not calendar_client.is_ready():
        return FreeBusyResponse(free_slots=[], busy_periods=[])
    now = datetime.now().astimezone().replace(hour=0, minute=0, second=0, microsecond=0)
    free, busy = await calendar_client.free_busy(
        time_min=now, time_max=now + timedelta(days=days),
        min_slot_minutes=min_slot_minutes,
    )
    return FreeBusyResponse(free_slots=free, busy_periods=busy)


@router.get("/{event_id}", response_model=CalendarEventModel)
async def get_event(event_id: str) -> CalendarEventModel:
    if not calendar_client.is_ready():
        raise HTTPException(status_code=503, detail="Calendar not authorized")
    ev = await calendar_client.get_event(event_id)
    if ev is None:
        raise HTTPException(status_code=404, detail=f"Event {event_id} not found")
    return ev


# ── mutation endpoints (gated) ──────────────────────────────────────────────

@router.post("/events")
async def propose_create_event(req: CreateEventRequest) -> dict:
    """
    Propose a new event. Does NOT actually create the event — it creates an
    ActionRequest in the confirmation gate. The user must approve via
    /api/v1/actions/confirm.
    """
    plan = ActionPlan(
        action_type=ActionType.schedule_meeting,
        description=f"Create event '{req.summary}' on {req.start:%Y-%m-%d %H:%M}",
        parameters={
            "summary": req.summary,
            "description": req.description,
            "location": req.location,
            "start": req.start.isoformat(),
            "end": req.end.isoformat(),
            "attendees": req.attendees,
            "send_invites": req.send_invites,
        },
        risks=[f"Will email {len(req.attendees)} attendee(s)"] if req.send_invites and req.attendees else [],
        reversible=True,
    )
    action_request = ActionRequest(plan=plan, status=ActionStatus.awaiting_confirmation)
    await gate.submit(action_request)
    return {
        "action_id": str(action_request.id),
        "summary": req.summary,
        "start": req.start.isoformat(),
        "requires_confirmation": True,
    }


@router.patch("/events/{event_id}")
async def propose_update_event(event_id: str, req: UpdateEventRequest) -> dict:
    if not calendar_client.is_ready():
        raise HTTPException(status_code=503, detail="Calendar not authorized")
    existing = await calendar_client.get_event(event_id)
    if existing is None:
        raise HTTPException(status_code=404, detail=f"Event {event_id} not found")

    plan = ActionPlan(
        action_type=ActionType.schedule_meeting,
        description=f"Update event '{existing.summary}' ({event_id})",
        parameters={
            "operation": "update", "event_id": event_id,
            **{k: v.isoformat() if isinstance(v, datetime) else v
               for k, v in req.model_dump(exclude_none=True).items()},
        },
        risks=["Existing event attendees may receive a notification"],
        reversible=True,
    )
    action_request = ActionRequest(plan=plan, status=ActionStatus.awaiting_confirmation)
    await gate.submit(action_request)
    return {"action_id": str(action_request.id), "requires_confirmation": True}


@router.delete("/events/{event_id}")
async def propose_delete_event(event_id: str) -> dict:
    if not calendar_client.is_ready():
        raise HTTPException(status_code=503, detail="Calendar not authorized")
    existing = await calendar_client.get_event(event_id)
    if existing is None:
        raise HTTPException(status_code=404, detail=f"Event {event_id} not found")

    plan = ActionPlan(
        action_type=ActionType.schedule_meeting,
        description=f"Delete event '{existing.summary}' on {existing.start:%Y-%m-%d %H:%M}",
        parameters={"operation": "delete", "event_id": event_id},
        risks=["Event cannot be restored once deleted"],
        reversible=False,
    )
    action_request = ActionRequest(plan=plan, status=ActionStatus.awaiting_confirmation)
    await gate.submit(action_request)
    return {"action_id": str(action_request.id), "requires_confirmation": True}
