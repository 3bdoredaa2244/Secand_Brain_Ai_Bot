"""
GmailTool — routes natural-language email queries to Gmail API + LLM summarizer.

Matches on email-related keywords and routes to the appropriate Gmail operation.
If Gmail is not authorized (mock mode), it tells the user how to connect.

Sample queries it handles:
  "summarize my unread emails"
  "did Omar reply to me?"
  "show me recent emails from Sarah"
  "what urgent emails do I have"
  "my inbox briefing"
"""
import re

from app.core.logging import get_logger
from app.services.integrations.gmail.client import gmail_client
from app.services.integrations.gmail.summarizer import detect_important, summarize_emails
from app.services.tools.base import BaseTool, ToolResult

logger = get_logger(__name__)

_INBOX_WORDS = {
    "email", "emails", "inbox", "gmail", "mailbox", "unread", "messages",
}
_URGENT_WORDS = {"urgent", "important", "priority"}
_REPLY_WORDS  = {"reply", "replied", "respond", "responded", "answered"}

# "did Omar reply", "did Sarah respond"
_DID_REPLY_RE = re.compile(
    r"did\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\s+(?:reply|respond|answer)",
    re.IGNORECASE,
)
# "emails from Omar", "from Sarah"
_FROM_RE = re.compile(
    r"\bfrom\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?|[\w.+-]+@[\w.-]+)",
    re.IGNORECASE,
)


class GmailTool(BaseTool):
    name = "gmail"
    description = "Read, search, and summarize Gmail inbox"

    def matches(self, query: str) -> bool:
        lower = query.lower()
        return any(w in lower for w in _INBOX_WORDS) or bool(_DID_REPLY_RE.search(query))

    async def run(self, query: str) -> ToolResult:
        if not gmail_client.is_ready():
            return ToolResult(
                answer=(
                    "Gmail isn't connected yet. Open the Settings page and click "
                    "'Connect Google' — or visit /api/v1/auth/google/login directly."
                ),
                data={"authorized": False},
            )

        lower = query.lower()

        # ── "did X reply to me" ───────────────────────────────────────────────
        m = _DID_REPLY_RE.search(query)
        if m:
            person = m.group(1)
            return await self._did_person_reply(person)

        # ── "emails from X" ───────────────────────────────────────────────────
        m = _FROM_RE.search(query)
        if m and any(w in lower for w in _INBOX_WORDS):
            return await self._emails_from(m.group(1))

        # ── "urgent" / "important" emails ─────────────────────────────────────
        if any(w in lower for w in _URGENT_WORDS):
            return await self._urgent_emails()

        # ── default: summarize unread ─────────────────────────────────────────
        return await self._summarize_unread()

    # ── handlers ──────────────────────────────────────────────────────────────

    async def _summarize_unread(self) -> ToolResult:
        emails = await gmail_client.list_messages(query="in:inbox is:unread", max_results=15)
        if not emails:
            return ToolResult(answer="No unread emails — your inbox is clear.", data={"count": 0})
        summary = await summarize_emails(emails[:10])
        return ToolResult(
            answer=f"You have **{len(emails)}** unread email(s).\n\n{summary}",
            data={"count": len(emails), "ids": [e.id for e in emails]},
        )

    async def _urgent_emails(self) -> ToolResult:
        emails = await gmail_client.list_messages(query="in:inbox is:unread", max_results=30)
        important = detect_important(emails)
        if not important:
            return ToolResult(answer="No urgent emails right now.", data={"count": 0})
        lines = [f"You have **{len(important)}** urgent email(s):"]
        for e in important[:5]:
            lines.append(f"  • **{e.sender_email}** — {e.subject}")
        return ToolResult(answer="\n".join(lines), data={"count": len(important)})

    async def _did_person_reply(self, person: str) -> ToolResult:
        # Search both "from Person" and threads they're on
        emails = await gmail_client.list_messages(query=f'from:"{person}"', max_results=5)
        if not emails:
            return ToolResult(
                answer=f"No recent emails from **{person}**.",
                data={"person": person, "found": False},
            )
        latest = emails[0]
        return ToolResult(
            answer=(
                f"Yes — latest email from **{person}**:\n"
                f"  Subject: {latest.subject}\n"
                f"  Received: {latest.received_at:%Y-%m-%d %H:%M}"
            ),
            data={"person": person, "found": True, "latest_id": latest.id},
        )

    async def _emails_from(self, sender: str) -> ToolResult:
        emails = await gmail_client.list_messages(query=f'from:"{sender}"', max_results=10)
        if not emails:
            return ToolResult(answer=f"No emails from **{sender}**.", data={"count": 0})
        lines = [f"Found **{len(emails)}** email(s) from {sender}:"]
        for e in emails[:5]:
            lines.append(f"  • {e.subject}  ·  {e.received_at:%Y-%m-%d}")
        return ToolResult(answer="\n".join(lines), data={"count": len(emails)})
