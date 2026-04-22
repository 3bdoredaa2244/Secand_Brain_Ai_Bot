from fastapi import APIRouter
from app.models.trigger import TriggerEvent, TriggerDefinition
from app.services.triggers.realtime import REALTIME_TRIGGERS
from app.services.triggers.scheduled import SCHEDULED_TRIGGERS
from app.services.triggers.semantic import SEMANTIC_TRIGGERS

router = APIRouter()

ALL_TRIGGERS = REALTIME_TRIGGERS + SCHEDULED_TRIGGERS + SEMANTIC_TRIGGERS


@router.get("/triggers", response_model=list[TriggerDefinition])
async def list_triggers():
    return [t.definition for t in ALL_TRIGGERS]


@router.post("/triggers/evaluate/{trigger_name}", response_model=TriggerEvent | None)
async def evaluate_trigger(trigger_name: str, payload: dict):
    trigger = next((t for t in ALL_TRIGGERS if t.definition.name == trigger_name), None)
    if trigger is None:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail=f"Trigger '{trigger_name}' not found")
    return await trigger.evaluate(payload)
