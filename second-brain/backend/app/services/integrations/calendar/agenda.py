"""Agenda summarization — used by the daily briefing and CalendarTool."""
from datetime import datetime
from app.core.logging import get_logger
from app.models.calendar import CalendarEventModel
from app.services.rag.memory import memory_engine

logger = get_logger(__name__)

_AGENDA_PROMPT = """\
Summarize the user's calendar for {when} in 2-4 short sentences.
Highlight: key meetings, back-to-back blocks, deep work time, and any conflicts.
Be conversational and concise. Do not list every event verbatim.

Events:
{events}
"""


async def summarize_agenda(events: list[CalendarEventModel], when: str = "today") -> str:
    if not events:
        return f"Your calendar is clear for {when}."

    formatted = "\n".join(
        f"- {e.start:%H:%M}-{e.end:%H:%M}: {e.summary}"
        + (f" @ {e.location}" if e.location else "")
        + (f" with {', '.join(a.email for a in e.attendees[:3])}" if e.attendees else "")
        for e in events
    )
    prompt = _AGENDA_PROMPT.format(when=when, events=formatted)

    try:
        answer = await memory_engine.llm_fallback(prompt)
        if answer:
            return answer.strip()
    except Exception as exc:
        logger.warning("summarize_agenda: LLM call failed — %s", exc)

    # Deterministic fallback
    lines = [f"You have {len(events)} event(s) {when}:"]
    for e in events[:6]:
        lines.append(f"  • {e.start:%H:%M} — {e.summary}")
    if len(events) > 6:
        lines.append(f"  …and {len(events) - 6} more.")
    return "\n".join(lines)


def detect_conflicts(events: list[CalendarEventModel]) -> list[tuple[CalendarEventModel, CalendarEventModel]]:
    """Return pairs of events with overlapping time windows."""
    sorted_events = sorted(events, key=lambda e: e.start)
    conflicts: list[tuple[CalendarEventModel, CalendarEventModel]] = []
    for i, a in enumerate(sorted_events):
        for b in sorted_events[i + 1:]:
            if b.start >= a.end:
                break  # sorted: nothing else can overlap a
            conflicts.append((a, b))
    return conflicts
