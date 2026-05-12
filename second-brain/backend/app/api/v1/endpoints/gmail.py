"""
Gmail HTTP endpoints.

  GET  /gmail/recent         — most recent N emails (default 10)
  GET  /gmail/unread         — unread inbox (default 20)
  GET  /gmail/search?q=…     — Gmail search syntax
  GET  /gmail/{message_id}   — full message with body
  GET  /gmail/briefing       — daily digest + LLM summary + urgent flagging
  POST /gmail/draft          — propose an email; returns an ActionRequest in the gate
  POST /gmail/{message_id}/archive
"""
from fastapi import APIRouter, HTTPException, Query
from uuid import UUID

from app.core.logging import get_logger
from app.models.action import ActionPlan, ActionRequest, ActionStatus, ActionType
from app.models.email import (
    DraftRequest, DraftResponse, EmailBriefing, EmailListResponse, EmailModel,
)
from app.services.confirmation_gate.gate import gate
from app.services.integrations.gmail.client import gmail_client
from app.services.integrations.gmail.summarizer import detect_important, summarize_emails

logger = get_logger(__name__)
router = APIRouter(prefix="/gmail", tags=["gmail"])


# ── read endpoints ──────────────────────────────────────────────────────────

@router.get("/recent", response_model=EmailListResponse)
async def recent(max_results: int = Query(default=10, ge=1, le=50)) -> EmailListResponse:
    """Return the N most recent inbox emails. Empty list when not authorized."""
    if not gmail_client.is_ready():
        return EmailListResponse(emails=[], total=0, mock=True)
    emails = await gmail_client.list_messages(query="in:inbox", max_results=max_results)
    return EmailListResponse(emails=emails, total=len(emails))


@router.get("/unread", response_model=EmailListResponse)
async def unread(max_results: int = Query(default=20, ge=1, le=100)) -> EmailListResponse:
    """Return only unread inbox emails."""
    if not gmail_client.is_ready():
        return EmailListResponse(emails=[], total=0, mock=True)
    emails = await gmail_client.list_messages(query="in:inbox is:unread", max_results=max_results)
    return EmailListResponse(emails=emails, total=len(emails))


@router.get("/search", response_model=EmailListResponse)
async def search(
    q: str = Query(..., description="Gmail search string, e.g. 'from:omar@example.com'"),
    max_results: int = Query(default=20, ge=1, le=100),
) -> EmailListResponse:
    if not gmail_client.is_ready():
        return EmailListResponse(emails=[], total=0, mock=True)
    emails = await gmail_client.list_messages(query=q, max_results=max_results)
    return EmailListResponse(emails=emails, total=len(emails))


@router.get("/briefing", response_model=EmailBriefing)
async def briefing() -> EmailBriefing:
    """Daily email digest: unread count, important emails, LLM summary."""
    if not gmail_client.is_ready():
        return EmailBriefing(
            total_unread=0, important_count=0,
            summary="Gmail not connected. Authorize via /api/v1/auth/google/login.",
            top_emails=[], mock=True,
        )

    emails = await gmail_client.list_messages(query="in:inbox is:unread", max_results=25)
    important = detect_important(emails)
    summary = await summarize_emails(emails[:10])

    return EmailBriefing(
        total_unread=len(emails),
        important_count=len(important),
        summary=summary,
        top_emails=important[:5] if important else emails[:5],
    )


@router.get("/{message_id}", response_model=EmailModel)
async def detail(message_id: str) -> EmailModel:
    """Fetch one message with full body."""
    if not gmail_client.is_ready():
        raise HTTPException(status_code=503, detail="Gmail not authorized")
    msg = await gmail_client.get_message(message_id)
    if msg is None:
        raise HTTPException(status_code=404, detail=f"Message {message_id} not found")
    return msg


# ── write endpoints (gated) ─────────────────────────────────────────────────

@router.post("/draft", response_model=DraftResponse)
async def draft(req: DraftRequest) -> DraftResponse:
    """
    Propose an outgoing email. This does NOT send — it creates a pending
    ActionRequest in the confirmation gate. The user must approve it via
    POST /actions/confirm before the email is dispatched.
    """
    plan = ActionPlan(
        action_type=ActionType.send_email,
        description=f"Send email to {req.to} — Subject: {req.subject}",
        parameters={"to": req.to, "subject": req.subject, "body": req.body, "cc": req.cc},
        risks=["Email cannot be unsent once delivered"],
        reversible=False,
    )
    action_request = ActionRequest(plan=plan, status=ActionStatus.awaiting_confirmation)
    await gate.submit(action_request)
    return DraftResponse(
        draft_id=str(action_request.id),
        to=req.to,
        subject=req.subject,
        body=req.body,
        requires_confirmation=True,
    )


@router.post("/{message_id}/archive")
async def archive(message_id: str) -> dict:
    """Archive an email (remove INBOX label). Read-only mutation, no gate needed."""
    if not gmail_client.is_ready():
        raise HTTPException(status_code=503, detail="Gmail not authorized")
    ok = await gmail_client.archive(message_id)
    if not ok:
        raise HTTPException(status_code=500, detail="Archive failed")
    return {"archived": True, "message_id": message_id}
