"""
ScheduleMeetingAction — confirmation-gated calendar mutations.

Handles three operations through one action type:
  create — propose a new event  → params: summary, start, end, attendees, …
  update — modify an event       → params: operation="update", event_id, fields…
  delete — remove an event       → params: operation="delete", event_id

The operation is inferred from the `operation` parameter (default: create).
"""
from datetime import datetime

from app.core.logging import get_logger
from app.models.action import ActionPlan, ActionRequest, ActionResult, ActionStatus, ActionType
from app.services.actions.base import BaseAction
from app.services.integrations.calendar.client import calendar_client

logger = get_logger(__name__)


class ScheduleMeetingAction(BaseAction):
    action_type = ActionType.schedule_meeting

    async def prepare(self, parameters: dict) -> ActionPlan:
        op = parameters.get("operation", "create")
        title = parameters.get("summary") or parameters.get("title", "Meeting")
        attendees = parameters.get("attendees", [])
        attendees_str = ", ".join(attendees) if attendees else "(no attendees)"
        when = parameters.get("start", "?")
        return ActionPlan(
            action_type=ActionType.schedule_meeting,
            description=f"[{op}] '{title}' with {attendees_str} on {when}",
            parameters=parameters,
            reversible=(op != "delete"),
            risks=(
                ["Sends calendar invites to attendees"] if attendees and parameters.get("send_invites")
                else []
            ),
        )

    async def execute(self, request: ActionRequest) -> ActionResult:
        params = request.plan.parameters
        op = params.get("operation", "create")

        if not calendar_client.is_ready():
            return self._fail(request, "Google Calendar not authorized. Visit /api/v1/auth/google/login first.")

        try:
            if op == "delete":
                return await self._do_delete(request, params)
            if op == "update":
                return await self._do_update(request, params)
            return await self._do_create(request, params)
        except Exception as exc:
            logger.error("ScheduleMeetingAction[%s]: %s", op, exc, exc_info=True)
            return self._fail(request, f"Calendar API error: {exc}")

    # ── operations ────────────────────────────────────────────────────────────

    async def _do_create(self, request: ActionRequest, params: dict) -> ActionResult:
        ev = await calendar_client.create_event(
            summary=params.get("summary", "Meeting"),
            start=_parse_dt(params["start"]),
            end=_parse_dt(params["end"]),
            description=params.get("description", ""),
            location=params.get("location", ""),
            attendees=params.get("attendees", []),
            send_invites=params.get("send_invites", False),
        )
        if ev is None:
            return self._fail(request, "Calendar API did not return the created event")
        logger.info("ScheduleMeetingAction.create: id=%s", ev.id)
        return ActionResult(
            action_id=request.id,
            status=ActionStatus.completed,
            output={"event_id": ev.id, "html_link": ev.html_link, "summary": ev.summary},
        )

    async def _do_update(self, request: ActionRequest, params: dict) -> ActionResult:
        event_id = params.get("event_id")
        if not event_id:
            return self._fail(request, "update operation requires event_id")
        updates = {k: v for k, v in params.items() if k not in {"operation", "event_id"}}
        # Parse datetime fields back
        for key in ("start", "end"):
            if key in updates and isinstance(updates[key], str):
                updates[key] = _parse_dt(updates[key])
        ev = await calendar_client.update_event(event_id, updates)
        if ev is None:
            return self._fail(request, "Calendar API did not return the updated event")
        return ActionResult(
            action_id=request.id, status=ActionStatus.completed,
            output={"event_id": ev.id, "summary": ev.summary, "html_link": ev.html_link},
        )

    async def _do_delete(self, request: ActionRequest, params: dict) -> ActionResult:
        event_id = params.get("event_id")
        if not event_id:
            return self._fail(request, "delete operation requires event_id")
        ok = await calendar_client.delete_event(event_id)
        if not ok:
            return self._fail(request, "Calendar API rejected the delete")
        return ActionResult(
            action_id=request.id, status=ActionStatus.completed,
            output={"deleted": True, "event_id": event_id},
        )

    # ── helpers ───────────────────────────────────────────────────────────────

    def _fail(self, request: ActionRequest, message: str) -> ActionResult:
        logger.warning("ScheduleMeetingAction: %s", message)
        return ActionResult(
            action_id=request.id, status=ActionStatus.failed,
            output={"error": message},
        )


def _parse_dt(val) -> datetime:
    """Accept ISO string or datetime; return tz-aware datetime."""
    if isinstance(val, datetime):
        return val if val.tzinfo else val.astimezone()
    return datetime.fromisoformat(val.replace("Z", "+00:00") if isinstance(val, str) and val.endswith("Z") else val)


schedule_meeting = ScheduleMeetingAction()
