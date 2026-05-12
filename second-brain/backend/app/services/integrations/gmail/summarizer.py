"""
Email summarization pipeline — wraps MemoryEngine's LLM for inbox digests.

If no LLM is configured, returns a deterministic fallback summary.
This way the briefing endpoint always returns *something*.
"""
from app.core.logging import get_logger
from app.models.email import EmailModel
from app.services.rag.memory import memory_engine

logger = get_logger(__name__)

_PROMPT_TEMPLATE = """\
Summarize the user's recent inbox in 3-5 short bullet points.
For each bullet: who sent it, what they want, and any urgency cues.
Skip newsletters and promotional emails unless they look time-sensitive.

Emails:
{emails}
"""


async def summarize_emails(emails: list[EmailModel]) -> str:
    """LLM-backed inbox digest. Falls back to a plain list if no LLM."""
    if not emails:
        return "Your inbox is empty."

    # Try LLM synthesis via the shared MemoryEngine
    formatted = "\n".join(
        f"- From: {e.sender}\n  Subject: {e.subject}\n  Preview: {e.snippet[:200]}"
        for e in emails
    )
    prompt = _PROMPT_TEMPLATE.format(emails=formatted)

    try:
        answer = await memory_engine.llm_fallback(prompt)
        if answer:
            return answer.strip()
    except Exception as exc:
        logger.warning("summarize_emails: LLM call failed — %s", exc)

    # Deterministic fallback: just list senders and subjects
    lines = [f"You have {len(emails)} recent email(s):"]
    for e in emails[:5]:
        lines.append(f"  • {e.sender_email} — {e.subject}")
    if len(emails) > 5:
        lines.append(f"  …and {len(emails) - 5} more.")
    return "\n".join(lines)


def detect_important(emails: list[EmailModel]) -> list[EmailModel]:
    """Heuristic: 'urgent', 'asap', 'important' in subject OR IMPORTANT label."""
    urgent_words = ("urgent", "asap", "important", "deadline", "action required", "overdue")
    return [
        e for e in emails
        if e.is_important or any(w in e.subject.lower() for w in urgent_words)
    ]
