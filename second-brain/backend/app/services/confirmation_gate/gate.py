"""
Confirmation gate — every action must pass through here before execution.
No action is ever executed without explicit approval.

Phase 2: Redis-backed storage with TTL so pending actions survive restarts
and expire automatically. Falls back to in-memory if Redis is unavailable.
"""
from uuid import UUID

from app.core.config import get_settings
from app.core.logging import get_logger
from app.models.action import ActionConfirmation, ActionRequest, ActionResult, ActionStatus

logger = get_logger(__name__)
settings = get_settings()

_PENDING_PREFIX = "gate:pending:"
_RESULT_PREFIX  = "gate:result:"


class ConfirmationGate:
    def __init__(self) -> None:
        self._redis = None
        # In-memory fallback — used when Redis is unavailable
        self._mem_pending: dict[UUID, ActionRequest] = {}
        self._mem_results: dict[UUID, ActionResult] = {}

    # ── lifecycle ─────────────────────────────────────────────────────────────

    async def connect(self) -> None:
        """Attempt to connect to Redis. Silent on failure — uses in-memory fallback."""
        try:
            import redis.asyncio as aioredis  # noqa: PLC0415
            client = await aioredis.from_url(settings.redis_url, decode_responses=True)
            await client.ping()
            self._redis = client
            logger.info("ConfirmationGate: connected to Redis at %s", settings.redis_url)
        except Exception as exc:
            logger.warning(
                "ConfirmationGate: Redis unavailable (%s) — using in-memory fallback", exc
            )

    # ── public interface ──────────────────────────────────────────────────────

    async def submit(self, request: ActionRequest) -> ActionRequest:
        """Register an action and block it pending user confirmation."""
        request.status = ActionStatus.awaiting_confirmation
        await self._save_pending(request)
        logger.info("Gate: action %s submitted, awaiting confirmation", request.id)
        return request

    async def confirm(self, confirmation: ActionConfirmation) -> ActionResult:
        """Accept or reject a pending action."""
        request = await self._load_pending(confirmation.action_id)
        if request is None:
            raise KeyError(f"No pending action with id {confirmation.action_id}")

        if confirmation.approved:
            request.status = ActionStatus.confirmed
            logger.info("Gate: action %s APPROVED", confirmation.action_id)
            result = ActionResult(
                action_id=confirmation.action_id,
                status=ActionStatus.confirmed,
            )
        else:
            request.status = ActionStatus.rejected
            logger.info("Gate: action %s REJECTED — %s", confirmation.action_id, confirmation.note)
            result = ActionResult(
                action_id=confirmation.action_id,
                status=ActionStatus.rejected,
            )

        await self._save_result(result)
        await self._delete_pending(confirmation.action_id)
        return result

    async def list_pending(self) -> list[ActionRequest]:
        if self._redis:
            return await self._redis_list_pending()
        return list(self._mem_pending.values())

    async def get_result(self, action_id: UUID) -> ActionResult | None:
        if self._redis:
            return await self._redis_get_result(action_id)
        return self._mem_results.get(action_id)

    # ── Redis helpers ─────────────────────────────────────────────────────────

    async def _save_pending(self, request: ActionRequest) -> None:
        key = f"{_PENDING_PREFIX}{request.id}"
        payload = request.model_dump_json()
        if self._redis:
            await self._redis.setex(key, settings.gate_timeout_seconds, payload)
        else:
            self._mem_pending[request.id] = request

    async def _load_pending(self, action_id: UUID) -> ActionRequest | None:
        if self._redis:
            raw = await self._redis.get(f"{_PENDING_PREFIX}{action_id}")
            if raw is None:
                return None
            return ActionRequest.model_validate_json(raw)
        return self._mem_pending.get(action_id)

    async def _delete_pending(self, action_id: UUID) -> None:
        if self._redis:
            await self._redis.delete(f"{_PENDING_PREFIX}{action_id}")
        else:
            self._mem_pending.pop(action_id, None)

    async def _save_result(self, result: ActionResult) -> None:
        key = f"{_RESULT_PREFIX}{result.action_id}"
        payload = result.model_dump_json()
        if self._redis:
            # Keep results for 24 h
            await self._redis.setex(key, 86400, payload)
        else:
            self._mem_results[result.action_id] = result

    async def _redis_list_pending(self) -> list[ActionRequest]:
        keys = await self._redis.keys(f"{_PENDING_PREFIX}*")
        if not keys:
            return []
        raws = await self._redis.mget(*keys)
        out = []
        for raw in raws:
            if raw:
                try:
                    out.append(ActionRequest.model_validate_json(raw))
                except Exception as exc:
                    logger.warning("Gate: could not deserialise pending action — %s", exc)
        return out

    async def _redis_get_result(self, action_id: UUID) -> ActionResult | None:
        raw = await self._redis.get(f"{_RESULT_PREFIX}{action_id}")
        if raw is None:
            return None
        try:
            return ActionResult.model_validate_json(raw)
        except Exception as exc:
            logger.warning("Gate: could not deserialise result %s — %s", action_id, exc)
            return None


gate = ConfirmationGate()
