"""
Obsidian vault loader.

Scans the vault, parses every .md file with the Obsidian parser,
and converts notes into RawChunk objects ready for ChromaDB upsert.

Chunk IDs are path-derived (stable + collision-free across subdirectories).
All structured fields (type, priority, due_date, status, wikilinks) are stored
as ChromaDB metadata so they can be used in `where` filter queries.
"""
from pathlib import Path

from app.core.config import get_settings
from app.core.logging import get_logger
from app.core.runtime_config import runtime_config
from app.services.obsidian.parser import ObsidianNote, parse_note
from app.services.rag.indexer import RawChunk, _chunk_text, CHUNK_SIZE, CHUNK_OVERLAP

logger = get_logger(__name__)
settings = get_settings()

_META_MAX = 500  # ChromaDB metadata values must be strings; truncate long ones


def _s(v) -> str:
    return str(v)[:_META_MAX] if v is not None else ""


class ObsidianLoader:
    def __init__(self, vault_path: Path | None = None) -> None:
        # Stored as None so reads always pick up the latest runtime override.
        self._explicit_path: Path | None = Path(vault_path) if vault_path else None

    @property
    def vault_path(self) -> Path:
        if self._explicit_path is not None:
            return self._explicit_path.resolve()
        return runtime_config.get_vault_path().resolve()

    def set_vault_path(self, path: Path) -> None:
        """Switch the active vault root (used by /obsidian/config)."""
        self._explicit_path = Path(path)

    # ── bulk load ─────────────────────────────────────────────────────────────

    def load_all(self) -> list[ObsidianNote]:
        if not self.vault_path.exists():
            logger.warning(
                "ObsidianLoader: vault not found at %s — set VAULT_PATH in backend/.env",
                self.vault_path,
            )
            return []

        md_files = list(self.vault_path.rglob("*.md"))
        logger.info("ObsidianLoader: found %d .md files in %s", len(md_files), self.vault_path)

        return [n for path in md_files if (n := self.load_file(path)) is not None]

    # ── single file ───────────────────────────────────────────────────────────

    def load_file(self, path: Path) -> ObsidianNote | None:
        try:
            return parse_note(path)
        except Exception as exc:
            logger.error("ObsidianLoader: cannot load %s — %s", path, exc)
            return None

    # ── chunking ──────────────────────────────────────────────────────────────

    def note_to_chunks(self, note: ObsidianNote) -> list[RawChunk]:
        if not note.body.strip():
            return []

        try:
            relative = note.path.relative_to(self.vault_path).as_posix()
        except ValueError:
            relative = note.path.name

        safe_key = relative.replace("/", "__").replace(".", "_").replace(" ", "_")

        metadata: dict[str, str] = {
            "source": relative,
            "filename": note.path.name,
            "title": _s(note.title),
            "tags": ",".join(note.tags),
            "wikilinks": ",".join(note.wikilinks),
            # Promoted structured fields — filterable via ChromaDB where={}
            "note_type": note.note_type,
            "priority": note.priority,
            "due_date": note.due_date,
            "status": note.status,
        }

        # Include any extra frontmatter fields not already covered
        _skip = {"tags", "tag", "type", "note_type", "priority", "due_date",
                 "due", "deadline", "status", "state", "title"}
        for k, v in note.frontmatter.items():
            if k not in _skip and v is not None:
                metadata[k] = _s(v)

        text_chunks = _chunk_text(note.body, CHUNK_SIZE, CHUNK_OVERLAP)
        return [
            RawChunk(
                id=f"{safe_key}__{i}",
                content=chunk,
                source=relative,
                metadata=metadata,
            )
            for i, chunk in enumerate(text_chunks)
        ]

    # ── helpers ───────────────────────────────────────────────────────────────

    def relative_source(self, path: Path) -> str:
        try:
            return path.resolve().relative_to(self.vault_path).as_posix()
        except ValueError:
            return path.name


loader = ObsidianLoader()
