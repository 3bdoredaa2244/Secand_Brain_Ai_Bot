from uuid import UUID
from fastapi import APIRouter, HTTPException
from app.models.action import ActionConfirmation, ActionResult, ActionRequest, ActionType
from app.services.confirmation_gate.gate import gate
from app.services.actions.send_email import send_email
from app.services.actions.book_flight import book_flight
from app.services.actions.buy_product import buy_product
from app.services.actions.schedule_meeting import schedule_meeting

router = APIRouter()

ACTION_REGISTRY = {
    ActionType.send_email: send_email,
    ActionType.book_flight: book_flight,
    ActionType.buy_product: buy_product,
    ActionType.schedule_meeting: schedule_meeting,
}


@router.post("/actions/prepare/{action_type}", response_model=ActionRequest)
async def prepare_action(action_type: ActionType, parameters: dict):
    handler = ACTION_REGISTRY.get(action_type)
    if not handler:
        raise HTTPException(status_code=404, detail=f"Unknown action type: {action_type}")
    return await handler.run(parameters)


@router.get("/actions/pending", response_model=list[ActionRequest])
async def list_pending():
    return gate.list_pending()


@router.post("/actions/confirm", response_model=ActionResult)
async def confirm_action(confirmation: ActionConfirmation):
    try:
        return await gate.confirm(confirmation)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc))


@router.get("/actions/result/{action_id}", response_model=ActionResult)
async def get_result(action_id: UUID):
    result = gate.get_result(action_id)
    if result is None:
        raise HTTPException(status_code=404, detail="No result found for this action id")
    return result
