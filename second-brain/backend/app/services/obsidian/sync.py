"""
Obsidian sync orchestrator.

Ties together ObsidianLoader (parse + chunk), VaultRetriever (ChromaDB),
and VaultGraph (wikilink relationships).

Called by:
  - main.py lifespan (startup sync when obsidian_sync_on_startup=True)
  - POST /api/v1/obsidian/sync  (manual full sync)
  - VaultWatcher (incremental per-file sync on file-system events)
"""
import asyncio
from dataclasses import dataclass
from pathlib import Path

from app.core.config import get_settings
from app.core.logging import get_logger
from app.services.obsidian.graph import VaultGraph, graph as default_graph
from app.services.obsidian.loader import ObsidianLoader, loader as default_loader
from app.services.rag.retriever import VaultRetriever, retriever as default_retriever

logger = get_logger(__name__)
settings = get_settings()


@dataclass
class SyncResult:
    files_scanned: int
    chunks_indexed: int
    errors: int


class ObsidianSync:
    def __init__(
        self,
        ldr: ObsidianLoader | None = None,
        ret: VaultRetriever | None = None,
        grph: VaultGraph | None = None,
    ) -> None:
        self._loader = ldr or default_loader
        self._retriever = ret or default_retriever
        self._graph = grph or default_graph

    # ── full vault sync ───────────────────────────────────────────────────────

    async def sync_all(self) -> SyncResult:
        """Re-index every .md file and rebuild the relationship graph."""
        loop = asyncio.get_running_loop()

        notes = await loop.run_in_executor(None, self._loader.load_all)
        if not notes:
            logger.warning("ObsidianSync: no notes found in %s", self._loader.vault_path)
            return SyncResult(files_scanned=0, chunks_indexed=0, errors=0)

        # Rebuild graph from scratch
        self._graph.clear()
        for note in notes:
            source = self._loader.relative_source(note.path)
            self._graph.update(source, note.wikilinks)

        total_chunks = 0
        errors = 0
        for note in notes:
            try:
                chunks = self._loader.note_to_chunks(note)
                if chunks:
                    await loop.run_in_executor(None, self._retriever.upsert, chunks)
                    total_chunks += len(chunks)
            except Exception as exc:
                logger.error("ObsidianSync: error indexing %s — %s", note.path.name, exc)
                errors += 1

        logger.info(
            "ObsidianSync: complete — %d files, %d chunks, %d errors | graph: %d nodes, %d edges",
            len(notes), total_chunks, errors,
            self._graph.node_count, self._graph.edge_count,
        )
        return SyncResult(files_scanned=len(notes), chunks_indexed=total_chunks, errors=errors)

    # ── single-file sync ──────────────────────────────────────────────────────

    async def sync_file(self, path: Path) -> int:
        """Re-index one file and update its graph edges. Returns chunk count."""
        loop = asyncio.get_running_loop()

        note = await loop.run_in_executor(None, self._loader.load_file, path)
        if note is None:
            return 0

        source = self._loader.relative_source(path)
        chunks = self._loader.note_to_chunks(note)

        # Update graph
        self._graph.update(source, note.wikilinks)

        # Refresh ChromaDB
        await loop.run_in_executor(None, self._retriever.delete_by_source, source)
        if chunks:
            await loop.run_in_executor(None, self._retriever.upsert, chunks)

        logger.info("ObsidianSync: synced '%s' → %d chunks", path.name, len(chunks))
        return len(chunks)

    # ── file removal ──────────────────────────────────────────────────────────

    async def remove_file(self, path: Path) -> None:
        """Remove index + graph edges for a deleted/renamed file."""
        source = self._loader.relative_source(path)
        loop = asyncio.get_running_loop()
        self._graph.remove(source)
        await loop.run_in_executor(None, self._retriever.delete_by_source, source)
        logger.info("ObsidianSync: removed '%s' from index and graph", path.name)


sync = ObsidianSync()
