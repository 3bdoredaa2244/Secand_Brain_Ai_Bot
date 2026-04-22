from enum import Enum
from datetime import datetime
from uuid import UUID, uuid4
from pydantic import BaseModel, Field


class TriggerType(str, Enum):
    realtime = "realtime"
    scheduled = "scheduled"
    semantic = "semantic"


class TriggerDomain(str, Enum):
    finance = "finance"
    travel = "travel"
    health = "health"
    work = "work"
    shopping = "shopping"
    communication = "communication"
    calendar = "calendar"
    general = "general"


class TriggerEvent(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    trigger_type: TriggerType
    domain: TriggerDomain
    name: str
    payload: dict
    fired_at: datetime = Field(default_factory=datetime.utcnow)
    processed: bool = False


class TriggerDefinition(BaseModel):
    name: str
    trigger_type: TriggerType
    domain: TriggerDomain
    description: str
    condition: str
    action_suggestion: str | None = None
    enabled: bool = True
