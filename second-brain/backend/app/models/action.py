from enum import Enum
from datetime import datetime
from uuid import UUID, uuid4
from pydantic import BaseModel, Field


class ActionType(str, Enum):
    send_email = "send_email"
    book_flight = "book_flight"
    buy_product = "buy_product"
    schedule_meeting = "schedule_meeting"


class ActionStatus(str, Enum):
    pending = "pending"
    awaiting_confirmation = "awaiting_confirmation"
    confirmed = "confirmed"
    rejected = "rejected"
    executing = "executing"
    completed = "completed"
    failed = "failed"


class ActionPlan(BaseModel):
    action_type: ActionType
    description: str
    parameters: dict
    estimated_cost: str | None = None
    estimated_time: str | None = None
    risks: list[str] = Field(default_factory=list)
    reversible: bool = True


class ActionRequest(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    plan: ActionPlan
    created_at: datetime = Field(default_factory=datetime.utcnow)
    status: ActionStatus = ActionStatus.pending
    triggered_by: str = "user"


class ActionConfirmation(BaseModel):
    action_id: UUID
    approved: bool
    note: str | None = None


class ActionResult(BaseModel):
    action_id: UUID
    status: ActionStatus
    output: dict | None = None
    error: str | None = None
    completed_at: datetime | None = None
