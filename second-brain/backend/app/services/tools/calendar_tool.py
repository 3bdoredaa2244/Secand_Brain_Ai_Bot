"""
CalendarTool — routes natural-language calendar queries.

Read-only operations execute directly (list, summarize, find slots).
Mutating operations (create/edit/delete) propose an ActionRequest through the
confirmation gate — the user must approve before anything actually happens.

Sample queries:
  "what meetings do I have today / tomorrow"
  "my agenda this week"
  "what free slots do I have this week"
  "schedule a meeting with omar friday at 3pm"   (gated)
  "cancel my AI meeting"                          (gated, user must confirm)
"""
import re
from datetime import datetime, timedelta

from app.core.logging import get_logger
from app.models.action import ActionPlan, ActionRequest, ActionStatus, ActionType
from app.services.confirmation_gate.gate import gate
from app.services.integrations.calendar.agenda import detect_conflicts, summarize_agenda
from app.services.integrations.calendar.client import calendar_client
from app.services.integrations.calendar.nlp import parse_when
from app.services.tools.base import BaseTool, ToolResult

logger = get_logger(__name__)

_CALENDAR_WORDS = {
    "calendar", "meeting", "meetings", "agenda", "schedule", "scheduled",
    "appointment", "appointments", "event", "events", "free slot", "free slots",
    "availability", "available",
}
_LIST_VERBS = {"have", "show", "list", "what", "any", "next"}
_CREATE_VERBS = {"schedule", "book", "set up", "create", "add"}
_RANGE_TODAY = {"today", "this morning", "this afternoon", "this evening"}
_RANGE_TOMORROW = {"tomorrow"}
_RANGE_WEEK = {"this week", "next week", "upcoming"}

# "with Omar", "with Sarah Smith"
_WITH_RE = re.compile(r"\bwith\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)?|[\w.+-]+@[\w.-]+)")


class CalendarTool(BaseTool):
    name = "calendar"
    description = "Read calendar, propose new events, find free slots"

    def matches(self, query: str) -> bool:
        lower = query.lower()
        return any(w in lower for w in _CALENDAR_WORDS)

    async def run(self, query: str) -> ToolResult:
        if not calendar_client.is_ready():
            return ToolResult(
                answer=(
                    "Google Calendar isn't connected yet. Visit "
                    "/api/v1/auth/google/login to authorize."
                ),
                data={"authorized": False},
            )

        lower = query.lower()

        # ── mutation: schedule / book / create ────────────────────────────────
        if any(v in lower for v in _CREATE_VERBS):
            return await self._propose_event(query)

        # ── free slots ────────────────────────────────────────────────────────
        if "free" in lower or "available" in lower or "availability" in lower:
            return await self._find_free_slots(query)

        # ── read ──────────────────────────────────────────────────────────────
        if any(p in lower for p in _RANGE_TOMORROW):
            return await self._list_tomorrow()
        if any(p in lower for p in _RANGE_WEEK):
            return await self._list_week()
        return await self._list_today()

    # ── read handlers ─────────────────────────────────────────────────────────

    async def _list_today(self) -> ToolResult:
        events = await calendar_client.list_today()
        if not events:
            return ToolResult(answer="No events on your calendar today.", data={"count": 0})
        summary = await summarize_agenda(events, when="today")
        conflicts = detect_conflicts(events)
        extra = f"\n\n⚠ {len(conflicts)} conflict(s) detected." if conflicts else ""
        return ToolResult(
            answer=f"You have **{len(events)}** event(s) today.\n\n{summary}{extra}",
            data={"count": len(events), "conflicts": len(conflicts)},
        )

    async def _list_tomorrow(self) -> ToolResult:
        start = datetime.now().astimezone().replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(days=1)
        end = start + timedelta(days=1)
        events = await calendar_client.list_events(time_min=start, time_max=end, max_results=50)
        if not events:
            return ToolResult(answer="No events on your calendar tomorrow.", data={"count": 0})
        summary = await summarize_agenda(events, when="tomorrow")
        return ToolResult(
            answer=f"Tomorrow you have **{len(events)}** event(s).\n\n{summary}",
            data={"count": len(events)},
        )

    async def _list_week(self) -> ToolResult:
        events = await calendar_client.list_upcoming(days=7)
        if not events:
            return ToolResult(answer="Your week is clear — no events in the next 7 days.", data={"count": 0})
        summary = await summarize_agenda(events, when="this week")
        return ToolResult(
            answer=f"**{len(events)}** event(s) in the next 7 days.\n\n{summary}",
            data={"count": len(events)},
        )

    async def _find_free_slots(self, query: str) -> ToolResult:
        # Default window: today through end of week
        now = datetime.now().astimezone()
        end = now + timedelta(days=7)
        free, busy = await calendar_client.free_busy(
            time_min=now.replace(hour=0, minute=0, second=0, microsecond=0),
            time_max=end,
            min_slot_minutes=30,
        )
        if not free:
            return ToolResult(answer="No free slots found in the next 7 days within work hours.", data={"count": 0})
        lines = [f"You have **{len(free)}** free slot(s) this week (≥30 min):"]
        for s in free[:8]:
            lines.append(f"  • {s.start:%a %d %b %H:%M} — {s.end:%H:%M}  ({s.duration_minutes}m)")
        if len(free) > 8:
            lines.append(f"  …and {len(free) - 8} more.")
        return ToolResult(answer="\n".join(lines), data={"slots": len(free)})

    # ── mutation handler (gated) ──────────────────────────────────────────────

    async def _propose_event(self, query: str) -> ToolResult:
        parsed = parse_when(query)
        if parsed is None:
            return ToolResult(
                answer=(
                    "I understood that you want to schedule something, but I couldn't "
                    "parse the time. Try: 'schedule meeting with Omar tomorrow at 3pm'."
                ),
                data={"parsed": False},
            )
        start, end = parsed

        # Extract attendees
        attendees: list[str] = []
        for m in _WITH_RE.finditer(query):
            attendees.append(m.group(1))

        # Title heuristic: strip scheduling verbs and time clause
        summary = re.sub(r"\b(schedule|book|set up|create|add)\b", "", query, flags=re.IGNORECASE).strip()
        summary = re.sub(r"\bwith\s+\S+(\s+\S+)?\b", "", summary, flags=re.IGNORECASE).strip()
        summary = re.sub(r"\b(tomorrow|today|tonight|this week|next week)\b", "", summary, flags=re.IGNORECASE).strip()
        summary = re.sub(r"\b(at\s+\d{1,2}(:\d{2})?\s*(am|pm)?)\b", "", summary, flags=re.IGNORECASE).strip()
        summary = summary.strip("., ") or "Meeting"

        # Submit through the confirmation gate
        plan = ActionPlan(
            action_type=ActionType.schedule_meeting,
            description=f"Schedule '{summary}' on {start:%Y-%m-%d %H:%M}",
            parameters={
                "summary": summary,
                "start": start.isoformat(),
                "end": end.isoformat(),
                "attendees": attendees,
            },
            risks=[] if not attendees else [f"Calendar invite will be sent to {len(attendees)} attendee(s)"],
            reversible=True,
        )
        req = ActionRequest(plan=plan, status=ActionStatus.awaiting_confirmation)
        await gate.submit(req)

        attendee_str = f" with {', '.join(attendees)}" if attendees else ""
        return ToolResult(
            answer=(
                f"📅 I drafted an event **'{summary}'** for **{start:%a %d %b at %H:%M}**{attendee_str}.\n\n"
                f"Approve it on the **Actions** page — id `{req.id}`."
            ),
            data={
                "action_id": str(req.id),
                "summary": summary,
                "start": start.isoformat(),
                "end": end.isoformat(),
                "attendees": attendees,
                "requires_confirmation": True,
            },
        )
