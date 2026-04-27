from fastapi import APIRouter
from app.api.v1.endpoints import health, query, actions, triggers, obsidian

router = APIRouter(prefix="/api/v1")
router.include_router(health.router, tags=["health"])
router.include_router(query.router, tags=["rag"])
router.include_router(actions.router, tags=["actions"])
router.include_router(triggers.router, tags=["triggers"])
router.include_router(obsidian.router, tags=["obsidian"])
