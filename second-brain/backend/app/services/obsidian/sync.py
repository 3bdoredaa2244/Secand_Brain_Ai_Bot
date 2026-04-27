"""
Obsidian sync orchestrator.

Ties together ObsidianLoader (parse + chunk) and VaultRetriever (ChromaDB).
Called both by the API endpoint (manual full sync) and by VaultWatcher
(incremental per-file sync triggered by file-system events).
"""
import asyncio
from dataclasses import dataclass
from pathlib import Path

from app.core.config import get_settings
from app.core.logging import get_logger
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
    ) -> None:
        self._loader = ldr or default_loader
        self._retriever = ret or default_retriever

    # ── full vault sync ───────────────────────────────────────────────────────

    async def sync_all(self) -> SyncResult:
        """Re-index every .md file in the vault. Safe to call multiple times."""
        loop = asyncio.get_running_loop()

        notes = await loop.run_in_executor(None, self._loader.load_all)
        if not notes:
            logger.warning("ObsidianSync: no notes found in vault %s", self._loader.vault_path)
            return SyncResult(files_scanned=0, chunks_indexed=0, errors=0)

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
            "ObsidianSync: sync_all complete — %d files, %d chunks, %d errors",
            len(notes), total_chunks, errors,
        )
        return SyncResult(files_scanned=len(notes), chunks_indexed=total_chunks, errors=errors)

    # ── single-file sync (called by watcher) ─────────────────────────────────

    async def sync_file(self, path: Path) -> int:
        """Re-index one file. Called automatically when the file changes.
        Returns the number of chunks indexed (0 if file could not be parsed).
        """
        loop = asyncio.get_running_loop()

        note = await loop.run_in_executor(None, self._loader.load_file, path)
        if note is None:
            return 0

        source = self._loader.relative_source(path)
        chunks = self._loader.note_to_chunks(note)

        # delete → upsert so stale chunks are removed when a file shrinks
        await loop.run_in_executor(None, self._retriever.delete_by_source, source)
        if chunks:
            await loop.run_in_executor(None, self._retriever.upsert, chunks)

        logger.info("ObsidianSync: synced '%s' → %d chunks", path.name, len(chunks))
        return len(chunks)

    # ── deletion (called by watcher on file remove/rename) ───────────────────

    async def remove_file(self, path: Path) -> None:
        """Remove all ChromaDB chunks for a deleted or renamed file."""
        source = self._loader.relative_source(path)
        loop = asyncio.get_running_loop()
        await loop.run_in_executor(None, self._retriever.delete_by_source, source)
        logger.info("ObsidianSync: removed index for '%s'", path.name)


sync = ObsidianSync()  # singleton — wired to default loader and retriever
