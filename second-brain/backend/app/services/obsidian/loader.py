"""
Obsidian vault loader.

Scans the vault, parses every .md file with the Obsidian parser,
and converts notes into RawChunk objects ready for ChromaDB upsert.

Chunk IDs are derived from the note's relative path so they are stable
across re-indexes: upserting the same note twice is idempotent.
"""
from pathlib import Path

from app.core.config import get_settings
from app.core.logging import get_logger
from app.services.obsidian.parser import ObsidianNote, parse_note
from app.services.rag.indexer import RawChunk, _chunk_text, CHUNK_SIZE, CHUNK_OVERLAP

logger = get_logger(__name__)
settings = get_settings()

# Metadata values must be strings for ChromaDB; truncate long fields.
_META_MAX = 500


def _safe_str(v) -> str:
    return str(v)[:_META_MAX] if v is not None else ""


class ObsidianLoader:
    def __init__(self, vault_path: Path | None = None) -> None:
        self.vault_path = (vault_path or settings.vault_path).resolve()

    # ── bulk load ─────────────────────────────────────────────────────────────

    def load_all(self) -> list[ObsidianNote]:
        """Return parsed notes for every .md file in the vault."""
        if not self.vault_path.exists():
            logger.warning(
                "ObsidianLoader: vault not found at %s — "
                "set VAULT_PATH in backend/.env",
                self.vault_path,
            )
            return []

        md_files = list(self.vault_path.rglob("*.md"))
        logger.info("ObsidianLoader: found %d .md files in %s", len(md_files), self.vault_path)

        notes: list[ObsidianNote] = []
        for path in md_files:
            note = self.load_file(path)
            if note is not None:
                notes.append(note)
        return notes

    # ── single file ───────────────────────────────────────────────────────────

    def load_file(self, path: Path) -> ObsidianNote | None:
        """Parse a single file. Returns None on I/O or parse error."""
        try:
            return parse_note(path)
        except Exception as exc:
            logger.error("ObsidianLoader: cannot load %s — %s", path, exc)
            return None

    # ── chunking ──────────────────────────────────────────────────────────────

    def note_to_chunks(self, note: ObsidianNote) -> list[RawChunk]:
        """Convert a parsed note into indexable chunks with full metadata."""
        if not note.body.strip():
            return []

        # Forward-slash normalised relative path (works on Windows too)
        try:
            relative = note.path.relative_to(self.vault_path).as_posix()
        except ValueError:
            relative = note.path.name

        # Stable chunk ID: based on relative path, no collisions across subdirs
        safe_key = relative.replace("/", "__").replace(".", "_").replace(" ", "_")

        metadata: dict[str, str] = {
            "source": relative,
            "filename": note.path.name,
            "title": _safe_str(note.title),
            "tags": ",".join(note.tags),
        }
        # Include any extra frontmatter fields (skip tags already captured)
        for k, v in note.frontmatter.items():
            if k not in ("tags", "tag") and v is not None:
                metadata[k] = _safe_str(v)

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
        """Return the forward-slash relative path used as the 'source' metadata key."""
        try:
            return path.resolve().relative_to(self.vault_path).as_posix()
        except ValueError:
            return path.name


loader = ObsidianLoader()  # singleton; vault_path resolved from settings at import time
