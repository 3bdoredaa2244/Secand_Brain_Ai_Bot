"""
Retriever — similarity search and write operations against the vector store.
"""
from dataclasses import dataclass

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)
settings = get_settings()


@dataclass
class RetrievedChunk:
    id: str
    content: str
    source: str
    score: float
    metadata: dict[str, str]


class VaultRetriever:
    def __init__(self) -> None:
        self._client = None
        self._collection = None
        self._unavailable_logged = False

    # ── lifecycle ─────────────────────────────────────────────────────────────

    def connect(self) -> None:
        """Initialize ChromaDB connection. Called once at app startup."""
        try:
            import chromadb  # noqa: PLC0415
            self._client = chromadb.HttpClient(
                host=settings.chroma_host,
                port=settings.chroma_port,
            )
            self._collection = self._client.get_or_create_collection(
                name=settings.chroma_collection
            )
            logger.info(
                "Retriever: connected to ChromaDB at %s:%s — collection '%s'",
                settings.chroma_host, settings.chroma_port, settings.chroma_collection,
            )
        except Exception as exc:
            logger.warning(
                "Retriever: ChromaDB unavailable at %s:%s — %s. "
                "Start with: docker-compose up chromadb",
                settings.chroma_host, settings.chroma_port, exc,
            )

    # ── write ─────────────────────────────────────────────────────────────────

    def upsert(self, chunks: list) -> None:
        """Insert or update a list of RawChunk objects in the collection."""
        if self._collection is None or not chunks:
            return
        self._collection.upsert(
            ids=[c.id for c in chunks],
            documents=[c.content for c in chunks],
            metadatas=[c.metadata for c in chunks],
        )

    def delete_by_source(self, source: str) -> None:
        """Remove every chunk whose metadata['source'] equals *source*.

        Safe to call even when no matching documents exist.
        """
        if self._collection is None:
            return
        try:
            self._collection.delete(where={"source": source})
        except Exception as exc:
            # ChromaDB raises when collection is empty or no match found
            logger.debug("Retriever.delete_by_source('%s'): %s", source, exc)

    # ── read ──────────────────────────────────────────────────────────────────

    def search(self, query: str, top_k: int | None = None) -> list[RetrievedChunk]:
        """Return top-k semantically similar chunks for a query."""
        k = top_k or settings.rag_top_k

        if self._collection is None:
            if not self._unavailable_logged:
                logger.warning("Retriever: ChromaDB not connected — returning empty results")
                self._unavailable_logged = True
            return []

        results = self._collection.query(query_texts=[query], n_results=k)
        return [
            RetrievedChunk(
                id=results["ids"][0][i],
                content=doc,
                source=results["metadatas"][0][i].get("source", "unknown"),
                score=1 - results["distances"][0][i],
                metadata=results["metadatas"][0][i],
            )
            for i, doc in enumerate(results["documents"][0])
        ]


retriever = VaultRetriever()  # singleton
