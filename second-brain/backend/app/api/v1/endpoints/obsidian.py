"""
Obsidian vault API endpoints.

POST /api/v1/obsidian/sync          — full vault re-index (background)
POST /api/v1/obsidian/sync/file     — re-index a single file (blocking)
GET  /api/v1/obsidian/status        — vault stats without re-indexing
"""
from pathlib import Path

from fastapi import APIRouter, BackgroundTasks, HTTPException, Query
from pydantic import BaseModel

from app.core.config import get_settings
from app.core.logging import get_logger
from app.services.obsidian.sync import ObsidianSync, SyncResult, sync as default_sync

logger = get_logger(__name__)
settings = get_settings()
router = APIRouter(prefix="/obsidian", tags=["obsidian"])


# ── response models ───────────────────────────────────────────────────────────

class SyncResponse(BaseModel):
    files_scanned: int
    chunks_indexed: int
    errors: int
    message: str


class VaultStatus(BaseModel):
    vault_path: str
    exists: bool
    md_files: int
    watcher_active: bool


# ── dependency ────────────────────────────────────────────────────────────────

def get_sync() -> ObsidianSync:
    return default_sync


# ── endpoints ─────────────────────────────────────────────────────────────────

@router.post("/sync", response_model=SyncResponse, status_code=202)
async def sync_vault(background_tasks: BackgroundTasks) -> SyncResponse:
    """
    Trigger a full vault re-index in the background.

    Returns immediately (202 Accepted). Watch the server logs for progress.
    Safe to call multiple times — upsert is idempotent.
    """
    background_tasks.add_task(_run_full_sync)
    return SyncResponse(
        files_scanned=0,
        chunks_indexed=0,
        errors=0,
        message=(
            f"Full sync started in background for vault '{settings.vault_path}'. "
            "Check server logs for progress."
        ),
    )


@router.post("/sync/file", response_model=SyncResponse)
async def sync_file(
    path: str = Query(
        ...,
        description="Relative path from vault root — e.g. 01-daily/2024-01-15.md",
    ),
) -> SyncResponse:
    """
    Re-index a single file immediately (blocking).

    Use this after editing a specific note and wanting instant results
    without waiting for the file watcher debounce.
    """
    full_path = (settings.vault_path / path).resolve()

    if not full_path.exists():
        raise HTTPException(status_code=404, detail=f"File not found: {path}")
    if full_path.suffix != ".md":
        raise HTTPException(status_code=400, detail="Only .md files are supported")
    if not _is_inside_vault(full_path):
        raise HTTPException(status_code=400, detail="Path must be inside the configured vault")

    chunks = await default_sync.sync_file(full_path)
    return SyncResponse(
        files_scanned=1,
        chunks_indexed=chunks,
        errors=0 if chunks >= 0 else 1,
        message=f"Synced '{path}' → {chunks} chunk(s) indexed",
    )


@router.get("/status", response_model=VaultStatus)
async def vault_status() -> VaultStatus:
    """Return vault statistics without modifying the index."""
    vault = settings.vault_path.resolve()
    exists = vault.exists()
    md_count = len(list(vault.rglob("*.md"))) if exists else 0

    # Check if watcher is running by inspecting the module-level watcher
    from app.services.obsidian import watcher as _watcher_mod  # noqa: PLC0415
    watcher_active = (
        hasattr(_watcher_mod, "_watcher")
        and _watcher_mod._watcher is not None
        and getattr(_watcher_mod._watcher, "_observer", None) is not None
        and getattr(_watcher_mod._watcher._observer, "is_alive", lambda: False)()
    )

    return VaultStatus(
        vault_path=str(vault),
        exists=exists,
        md_files=md_count,
        watcher_active=watcher_active,
    )


# ── background task ───────────────────────────────────────────────────────────

async def _run_full_sync() -> None:
    try:
        result: SyncResult = await default_sync.sync_all()
        logger.info(
            "Background sync complete: %d files, %d chunks, %d errors",
            result.files_scanned, result.chunks_indexed, result.errors,
        )
    except Exception as exc:
        logger.error("Background sync failed: %s", exc)


# ── guard ─────────────────────────────────────────────────────────────────────

def _is_inside_vault(path: Path) -> bool:
    vault = settings.vault_path.resolve()
    try:
        path.relative_to(vault)
        return True
    except ValueError:
        return False
