"""Pydantic models for Gmail API responses."""
from datetime import datetime

from pydantic import BaseModel, Field


class EmailAddress(BaseModel):
    name: str | None = None
    email: str


class EmailModel(BaseModel):
    id: str
    thread_id: str | None = None
    subject: str
    sender: str          # raw "Name <email>" string
    sender_email: str    # parsed email only
    snippet: str
    received_at: datetime
    labels: list[str] = Field(default_factory=list)
    is_unread: bool = False
    is_important: bool = False
    has_attachments: bool = False
    body: str = ""       # plain-text body, populated by /detail endpoint only


class EmailListResponse(BaseModel):
    emails: list[EmailModel]
    total: int
    mock: bool = False   # True when no Gmail OAuth — frontend can show a banner


class GmailAuthStatus(BaseModel):
    authorized: bool
    email: str | None = None
    expires_at: datetime | None = None
    scopes: list[str] = Field(default_factory=list)


class DraftRequest(BaseModel):
    to: str = Field(..., description="Recipient email address")
    subject: str = Field(..., max_length=200)
    body: str = Field(..., min_length=1, max_length=10_000)
    cc: list[str] = Field(default_factory=list)


class DraftResponse(BaseModel):
    draft_id: str
    to: str
    subject: str
    body: str
    requires_confirmation: bool = True


class EmailBriefing(BaseModel):
    """A daily summary of inbox state."""
    total_unread: int
    important_count: int
    summary: str        # LLM-generated digest
    top_emails: list[EmailModel]
    mock: bool = False
