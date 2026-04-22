"""
Document indexer — scans the vault and indexes markdown files.
Phase 1 skeleton: parsing + chunking logic, no vector store writes yet.
"""
from pathlib import Path
from dataclasses import dataclass
from app.core.logging import get_logger

logger = get_logger(__name__)

CHUNK_SIZE = 512
CHUNK_OVERLAP = 64


@dataclass
class RawChunk:
    id: str
    content: str
    source: str
    metadata: dict[str, str]


def _chunk_text(text: str, size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> list[str]:
    words = text.split()
    chunks: list[str] = []
    start = 0
    while start < len(words):
        end = min(start + size, len(words))
        chunks.append(" ".join(words[start:end]))
        start += size - overlap
    return chunks


def _parse_frontmatter(content: str) -> tuple[dict[str, str], str]:
    """Extract YAML frontmatter and return (metadata, body)."""
    if not content.startswith("---"):
        return {}, content
    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}, content
    meta: dict[str, str] = {}
    for line in parts[1].splitlines():
        if ":" in line:
            k, _, v = line.partition(":")
            meta[k.strip()] = v.strip()
    return meta, parts[2].strip()


class VaultIndexer:
    def __init__(self, vault_path: Path):
        self.vault_path = vault_path

    def scan(self) -> list[RawChunk]:
        """Walk vault and return all chunks ready for embedding."""
        chunks: list[RawChunk] = []
        md_files = list(self.vault_path.rglob("*.md"))
        logger.info("Indexer: found %d markdown files", len(md_files))

        for path in md_files:
            try:
                text = path.read_text(encoding="utf-8")
            except Exception as exc:
                logger.warning("Indexer: could not read %s — %s", path, exc)
                continue

            metadata, body = _parse_frontmatter(text)
            metadata["source"] = str(path.relative_to(self.vault_path))
            metadata["filename"] = path.name

            for i, chunk in enumerate(_chunk_text(body)):
                chunks.append(
                    RawChunk(
                        id=f"{path.stem}_{i}",
                        content=chunk,
                        source=str(path.relative_to(self.vault_path)),
                        metadata=metadata,
                    )
                )

        logger.info("Indexer: produced %d chunks", len(chunks))
        return chunks
