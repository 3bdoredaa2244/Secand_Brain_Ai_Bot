"""
Minimal natural-language datetime parser for calendar queries.

This is intentionally lightweight — it handles the most common phrases the
user will use in chat. For complex parsing, callers should pass ISO datetimes
directly through the REST API.

Supported patterns:
  "tomorrow", "today", "tonight"
  "Friday", "next Monday"
  "in 30 minutes", "in 2 hours"
  "at 3pm", "at 14:30"
  "Friday at 3pm"
"""
import re
from datetime import datetime, timedelta

_WEEKDAYS = {
    "monday": 0, "tuesday": 1, "wednesday": 2, "thursday": 3,
    "friday": 4, "saturday": 5, "sunday": 6,
    "mon": 0, "tue": 1, "wed": 2, "thu": 3, "fri": 4, "sat": 5, "sun": 6,
}

# matches "3pm", "3 pm", "15:00", "3:30pm"
_TIME_RE = re.compile(
    r"(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?",
    re.IGNORECASE,
)
# matches "in 30 minutes / 2 hours / 1 day"
_RELATIVE_RE = re.compile(
    r"in\s+(\d+)\s+(minutes?|hours?|days?)",
    re.IGNORECASE,
)


def parse_when(text: str, *, default_hour: int = 9, duration_minutes: int = 30) -> tuple[datetime, datetime] | None:
    """Parse a free-text "when" expression. Returns (start, end) in local time, or None.

    `default_hour` is used when only a date is mentioned (e.g. "tomorrow").
    `duration_minutes` is the default event length.
    """
    now = datetime.now().astimezone().replace(second=0, microsecond=0)
    lower = text.lower()

    # ── "in X minutes/hours/days" ─────────────────────────────────────────────
    m = _RELATIVE_RE.search(lower)
    if m:
        n, unit = int(m.group(1)), m.group(2).lower()
        delta = (
            timedelta(minutes=n) if unit.startswith("minute") else
            timedelta(hours=n)   if unit.startswith("hour")   else
            timedelta(days=n)
        )
        start = now + delta
        return start, start + timedelta(minutes=duration_minutes)

    # ── pick a base date ──────────────────────────────────────────────────────
    base = now.replace(hour=default_hour, minute=0)
    if "tomorrow" in lower:
        base = base + timedelta(days=1)
    elif "tonight" in lower:
        base = now.replace(hour=20, minute=0)
    elif "today" in lower:
        pass  # keep base = now
    else:
        # weekday?
        for word, idx in _WEEKDAYS.items():
            if re.search(rf"\b{word}\b", lower):
                ahead = (idx - now.weekday()) % 7
                if ahead == 0:
                    ahead = 7  # always next week if same weekday
                if "next" in lower:
                    ahead += 7 if ahead < 7 else 0
                base = now.replace(hour=default_hour, minute=0) + timedelta(days=ahead)
                break
        else:
            # No date keyword found → don't assume — let caller decide.
            base = None  # type: ignore[assignment]

    # ── time clause ───────────────────────────────────────────────────────────
    time_match = _TIME_RE.search(lower)
    if time_match:
        h = int(time_match.group(1))
        minute = int(time_match.group(2) or 0)
        ampm = (time_match.group(3) or "").lower()
        if ampm == "pm" and h < 12: h += 12
        if ampm == "am" and h == 12: h = 0
        # If we don't have a base date yet, anchor to today / tomorrow
        if base is None:
            base = now.replace(hour=h, minute=minute)
            if base < now:
                base = base + timedelta(days=1)
        else:
            base = base.replace(hour=h, minute=minute)

    if base is None:
        return None

    return base, base + timedelta(minutes=duration_minutes)
