"""
Obsidian vault API endpoints.

GET  /api/v1/obsidian/config        — current vault configuration
POST /api/v1/obsidian/config        — change vault path (persists across restarts)
POST /api/v1/obsidian/sync          — full vault re-index (background)
POST /api/v1/obsidian/sync/file     — re-index a single file (blocking)
GET  /api/v1/obsidian/status        — vault stats without re-indexing
GET  /api/v1/obsidian/graph         — wikilink graph summary
GET  /api/v1/obsidian/graph/node    — links + backlinks for a specific note
"""
from pathlib import Path

from fastapi import APIRouter, BackgroundTasks, HTTPException, Query
from pydantic import BaseModel

from app.core.config import get_settings
from app.core.logging import get_logger
from app.core.runtime_config import runtime_config
from app.services.obsidian.graph import graph as vault_graph
from app.services.obsidian.sync import ObsidianSync, SyncResult, sync as default_sync
from app.services.rag.retriever import retriever as default_retriever

logger = get_logger(__name__)
settings = get_settings()
router = APIRouter(prefix="/obsidian", tags=["obsidian"])


def _vault_root() -> Path:
    """Active vault root — runtime override wins over .env."""
    return runtime_config.get_vault_path().resolve()


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


class GraphSummary(BaseModel):
    nodes: int
    edges: int
    most_linked: list[dict]


class NodeLinks(BaseModel):
    source: str
    links: list[str]       # notes this file links to
    backlinks: list[str]   # notes that link to this file
    related: list[str]     # 2-hop neighbourhood


class TagSearchResult(BaseModel):
    source: str
    title: str
    tags: list[str]
    note_type: str
    score: float
    snippet: str           # first 200 chars of the matching chunk


class VaultConfig(BaseModel):
    vault_path: str
    exists: bool
    is_override: bool      # true when /obsidian/config has been used
    settings_path: str     # what .env / settings.py says
    subfolders: list[str]  # immediate-child directory names
    md_files: int          # count of .md files (recursive)


class VaultConfigUpdate(BaseModel):
    vault_path: str
    create_structure: bool = False  # if True, scaffold notes/projects/meetings/tasks


_DEFAULT_SUBFOLDERS = ("notes", "projects", "meetings", "tasks")


# ── dependency ────────────────────────────────────────────────────────────────

def get_sync() -> ObsidianSync:
    return default_sync


# ── endpoints ─────────────────────────────────────────────────────────────────

@router.get("/config", response_model=VaultConfig)
async def get_vault_config() -> VaultConfig:
    """Return the currently active vault configuration.

    `is_override` is true when a value has been set via POST /obsidian/config —
    in that case `vault_path` differs from what's in .env.
    """
    active = _vault_root()
    settings_path = Path(settings.vault_path).expanduser().resolve()
    override = runtime_config.get("vault_path") is not None

    subfolders: list[str] = []
    md_count = 0
    if active.exists():
        try:
            subfolders = sorted(p.name for p in active.iterdir() if p.is_dir())
        except (PermissionError, OSError) as exc:
            logger.warning("get_vault_config: cannot list %s — %s", active, exc)
        md_count = _count_md_files(active)

    return VaultConfig(
        vault_path=str(active),
        exists=active.exists(),
        is_override=override,
        settings_path=str(settings_path),
        subfolders=subfolders,
        md_files=md_count,
    )


@router.post("/config", response_model=VaultConfig)
async def set_vault_config(req: VaultConfigUpdate, background_tasks: BackgroundTasks) -> VaultConfig:
    """Change the active vault path and optionally scaffold the default folders.

    The new path persists across restarts (stored in backend/data/runtime_config.json).
    Triggers a background re-sync so ChromaDB picks up the new vault. The file
    watcher will pick up the new root on the next backend restart.
    """
    candidate = Path(req.vault_path).expanduser()

    # Optional scaffold — useful when pointing at a fresh directory like D:\\SecondBrainVault
    if req.create_structure:
        try:
            candidate.mkdir(parents=True, exist_ok=True)
            for name in _DEFAULT_SUBFOLDERS:
                (candidate / name).mkdir(exist_ok=True)
            logger.info("set_vault_config: scaffolded %s with %s", candidate, _DEFAULT_SUBFOLDERS)
        except OSError as exc:
            raise HTTPException(status_code=400, detail=f"Cannot create {candidate}: {exc}")

    if not candidate.exists():
        raise HTTPException(
            status_code=400,
            detail=(
                f"Vault path '{candidate}' does not exist. "
                "Re-send with create_structure=true to scaffold it."
            ),
        )
    if not candidate.is_dir():
        raise HTTPException(status_code=400, detail=f"'{candidate}' is not a directory")

    runtime_config.set_vault_path(candidate)
    logger.info("set_vault_config: vault path → %s", candidate)

    # Point the in-process loader at the new vault and re-sync in the background.
    try:
        from app.services.obsidian.loader import loader as _loader  # noqa: PLC0415
        _loader.set_vault_path(candidate)
    except Exception as exc:
        logger.warning("set_vault_config: could not update loader — %s", exc)

    background_tasks.add_task(_run_full_sync)
    return await get_vault_config()


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
            f"Full sync started in background for vault '{_vault_root()}'. "
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
    full_path = (_vault_root() / path).resolve()

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
    try:
        vault = _vault_root()
        exists = vault.exists()
        md_count = _count_md_files(vault) if exists else 0

        watcher_active = _check_watcher()

        return VaultStatus(
            vault_path=str(vault),
            exists=exists,
            md_files=md_count,
            watcher_active=watcher_active,
        )
    except Exception as exc:
        logger.error("vault_status error: %s", exc, exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to read vault status: {exc}")


@router.get("/graph", response_model=GraphSummary)
async def graph_summary() -> GraphSummary:
    """Return high-level wikilink graph statistics."""
    try:
        s = vault_graph.summary()
        return GraphSummary(
            nodes=s["nodes"],
            edges=s["edges"],
            most_linked=s["most_linked"],
        )
    except Exception as exc:
        logger.error("graph_summary error: %s", exc, exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to read graph: {exc}")


@router.get("/graph/node", response_model=NodeLinks)
async def graph_node(
    source: str = Query(
        ...,
        description="Relative vault path — e.g. 05-knowledge/Python.md",
    ),
) -> NodeLinks:
    """Return forward links, backlinks, and 2-hop neighbours for a single note."""
    try:
        return NodeLinks(
            source=source,
            links=vault_graph.get_links(source),
            backlinks=vault_graph.get_backlinks(source),
            related=vault_graph.get_related(source, depth=2),
        )
    except Exception as exc:
        logger.error("graph_node error: %s", exc, exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to read graph node: {exc}")


@router.get("/search", response_model=list[TagSearchResult])
async def search_by_tag(
    tag: str = Query(..., description="Tag name to filter notes by, e.g. 'health'"),
    limit: int = Query(default=20, ge=1, le=100),
) -> list[TagSearchResult]:
    """Return notes that contain *tag* in their frontmatter tags.

    Uses a semantic search on the tag name then post-filters by metadata,
    so results are ranked by relevance as well as tag match.
    """
    try:
        # Over-fetch semantically, then narrow to exact tag matches in Python
        raw = default_retriever.search(query=tag, top_k=min(limit * 5, 100))
        tag_lower = tag.lower()

        # Deduplicate by source — keep highest-scoring chunk per note
        seen: dict[str, TagSearchResult] = {}
        for chunk in raw:
            raw_tags = chunk.metadata.get("tags", "")
            note_tags = [t.strip().lower() for t in raw_tags.split(",") if t.strip()]
            if tag_lower not in note_tags:
                continue
            if chunk.source in seen:
                continue  # already have a higher-scored chunk for this note
            seen[chunk.source] = TagSearchResult(
                source=chunk.source,
                title=chunk.metadata.get("title", chunk.source),
                tags=[t.strip() for t in raw_tags.split(",") if t.strip()],
                note_type=chunk.metadata.get("note_type", ""),
                score=round(chunk.score, 4),
                snippet=chunk.content[:200],
            )

        return list(seen.values())[:limit]
    except Exception as exc:
        logger.error("search_by_tag error: %s", exc, exc_info=True)
        raise HTTPException(status_code=500, detail=f"Tag search failed: {exc}")


# ── helpers ───────────────────────────────────────────────────────────────────

def _count_md_files(vault: Path) -> int:
    """Count .md files in the vault, skipping directories we cannot read."""
    count = 0
    try:
        for item in vault.rglob("*.md"):
            count += 1
    except PermissionError:
        pass  # skip inaccessible subdirectories on Windows
    except OSError as exc:
        logger.warning("_count_md_files: OS error during rglob — %s", exc)
    return count


def _check_watcher() -> bool:
    """Return True if the vault file watcher is currently running."""
    try:
        from app.services.obsidian import watcher as _watcher_mod  # noqa: PLC0415
        w = getattr(_watcher_mod, "_watcher", None)
        if w is None:
            return False
        obs = getattr(w, "_observer", None)
        if obs is None:
            return False
        is_alive = getattr(obs, "is_alive", None)
        return bool(is_alive()) if callable(is_alive) else False
    except Exception as exc:
        logger.warning("_check_watcher: unexpected error — %s", exc)
        return False


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
    vault = _vault_root()
    try:
        path.relative_to(vault)
        return True
    except ValueError:
        return False
