"""
Gmail API client — thin async wrapper around google-api-python-client.

The Google SDK is synchronous; every call is offloaded to a thread pool so it
never blocks the FastAPI event loop. All methods are idempotent and never
raise — they log and return safe defaults so the agent can degrade gracefully.

Operations
──────────
  list_messages   — list inbox by query (Gmail search syntax)
  get_message     — fetch one message with parsed body
  send_message    — send an email (called from confirmation-gated action)
  modify_labels   — add/remove labels (archive = remove INBOX)
  get_profile     — fetch authenticated user's address
"""
from __future__ import annotations

import asyncio
import base64
import re
from datetime import datetime, timezone
from email.mime.text import MIMEText
from typing import Any

from app.core.logging import get_logger
from app.models.email import EmailModel
from app.services.integrations.gmail.oauth import oauth_handler

logger = get_logger(__name__)


class GmailClient:
    """Async wrapper. Each instance lazily builds a service per call to avoid
    holding open HTTP pools across credential refreshes."""

    # ── readiness ─────────────────────────────────────────────────────────────

    def is_ready(self) -> bool:
        """True when OAuth has been completed and tokens are loadable."""
        try:
            return oauth_handler.load_credentials() is not None
        except Exception:
            return False

    # ── operations ────────────────────────────────────────────────────────────

    async def list_messages(
        self,
        query: str = "in:inbox",
        max_results: int = 10,
    ) -> list[EmailModel]:
        """Search messages. Returns [] on error or when not authorized."""
        try:
            return await asyncio.to_thread(self._list_messages_sync, query, max_results)
        except Exception as exc:
            logger.error("GmailClient.list_messages: %s", exc)
            return []

    async def get_message(self, message_id: str) -> EmailModel | None:
        try:
            return await asyncio.to_thread(self._get_message_sync, message_id)
        except Exception as exc:
            logger.error("GmailClient.get_message(%s): %s", message_id, exc)
            return None

    async def send_message(self, to: str, subject: str, body: str, cc: list[str] | None = None) -> str | None:
        """Send an email. Returns the new message ID, or None on failure."""
        try:
            return await asyncio.to_thread(self._send_message_sync, to, subject, body, cc or [])
        except Exception as exc:
            logger.error("GmailClient.send_message: %s", exc)
            return None

    async def modify_labels(
        self, message_id: str, add: list[str] | None = None, remove: list[str] | None = None,
    ) -> bool:
        try:
            return await asyncio.to_thread(self._modify_labels_sync, message_id, add or [], remove or [])
        except Exception as exc:
            logger.error("GmailClient.modify_labels(%s): %s", message_id, exc)
            return False

    async def archive(self, message_id: str) -> bool:
        """Convenience: archive == remove INBOX label."""
        return await self.modify_labels(message_id, remove=["INBOX"])

    async def get_profile(self) -> dict | None:
        try:
            return await asyncio.to_thread(self._get_profile_sync)
        except Exception as exc:
            logger.error("GmailClient.get_profile: %s", exc)
            return None

    # ── sync implementations (run in threadpool) ──────────────────────────────

    def _service(self):
        from googleapiclient.discovery import build  # noqa: PLC0415
        creds = oauth_handler.load_credentials()
        if creds is None:
            raise RuntimeError("Gmail not authorized — run /api/v1/auth/google/login")
        return build("gmail", "v1", credentials=creds, cache_discovery=False)

    def _list_messages_sync(self, query: str, max_results: int) -> list[EmailModel]:
        svc = self._service()
        resp = svc.users().messages().list(userId="me", q=query, maxResults=max_results).execute()
        ids = [m["id"] for m in resp.get("messages", [])]
        # Batch metadata fetches — light format only, no body
        emails: list[EmailModel] = []
        for mid in ids:
            try:
                msg = svc.users().messages().get(
                    userId="me", id=mid, format="metadata",
                    metadataHeaders=["From", "Subject", "Date"],
                ).execute()
                emails.append(_parse_message(msg, include_body=False))
            except Exception as exc:
                logger.warning("GmailClient: skipping message %s — %s", mid, exc)
        return emails

    def _get_message_sync(self, message_id: str) -> EmailModel | None:
        svc = self._service()
        msg = svc.users().messages().get(userId="me", id=message_id, format="full").execute()
        return _parse_message(msg, include_body=True)

    def _send_message_sync(self, to: str, subject: str, body: str, cc: list[str]) -> str:
        svc = self._service()
        mime = MIMEText(body, "plain", "utf-8")
        mime["To"] = to
        mime["Subject"] = subject
        if cc:
            mime["Cc"] = ", ".join(cc)
        raw = base64.urlsafe_b64encode(mime.as_bytes()).decode("ascii")
        result = svc.users().messages().send(userId="me", body={"raw": raw}).execute()
        return result.get("id", "")

    def _modify_labels_sync(self, message_id: str, add: list[str], remove: list[str]) -> bool:
        svc = self._service()
        svc.users().messages().modify(
            userId="me", id=message_id,
            body={"addLabelIds": add, "removeLabelIds": remove},
        ).execute()
        return True

    def _get_profile_sync(self) -> dict:
        svc = self._service()
        return svc.users().getProfile(userId="me").execute()


# ── parsing helpers ──────────────────────────────────────────────────────────

_ADDR_RE = re.compile(r"<([^>]+)>")


def _parse_message(msg: dict[str, Any], include_body: bool) -> EmailModel:
    """Convert a Gmail API message dict into our EmailModel."""
    headers = {h["name"].lower(): h["value"] for h in msg.get("payload", {}).get("headers", [])}
    sender_raw = headers.get("from", "")
    addr_match = _ADDR_RE.search(sender_raw)
    sender_email = addr_match.group(1) if addr_match else sender_raw

    # Internal date is ms since epoch
    received_at = datetime.fromtimestamp(
        int(msg.get("internalDate", 0)) / 1000, tz=timezone.utc,
    )

    labels = msg.get("labelIds", [])
    body = ""
    if include_body:
        body = _extract_plain_body(msg.get("payload", {}))

    return EmailModel(
        id=msg["id"],
        thread_id=msg.get("threadId"),
        subject=headers.get("subject", "(no subject)"),
        sender=sender_raw,
        sender_email=sender_email,
        snippet=msg.get("snippet", ""),
        received_at=received_at,
        labels=labels,
        is_unread="UNREAD" in labels,
        is_important="IMPORTANT" in labels,
        has_attachments=_has_attachments(msg.get("payload", {})),
        body=body,
    )


def _extract_plain_body(payload: dict) -> str:
    """Walk MIME parts to find a text/plain body. Returns '' if none."""
    if payload.get("mimeType") == "text/plain":
        data = payload.get("body", {}).get("data", "")
        if data:
            return base64.urlsafe_b64decode(data.encode()).decode("utf-8", errors="replace")
    for part in payload.get("parts", []) or []:
        result = _extract_plain_body(part)
        if result:
            return result
    return ""


def _has_attachments(payload: dict) -> bool:
    for part in payload.get("parts", []) or []:
        if part.get("filename"):
            return True
        if _has_attachments(part):
            return True
    return False


gmail_client = GmailClient()
