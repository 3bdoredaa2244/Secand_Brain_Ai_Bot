"""
Retriever — similarity search against the vector store.
Phase 1 skeleton: interface defined, ChromaDB client stubbed out.
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

    def connect(self) -> None:
        """Initialize ChromaDB connection. Called at app startup."""
        try:
            import chromadb  # noqa: PLC0415
            self._client = chromadb.HttpClient(
                host=settings.chroma_host,
                port=settings.chroma_port,
            )
            self._collection = self._client.get_or_create_collection(
                name=settings.chroma_collection
            )
            logger.info("Retriever: connected to ChromaDB collection '%s'", settings.chroma_collection)
        except Exception as exc:
            logger.warning("Retriever: ChromaDB unavailable — %s (running in stub mode)", exc)

    def search(self, query: str, top_k: int | None = None) -> list[RetrievedChunk]:
        """Return top-k semantically similar chunks for a query."""
        k = top_k or settings.rag_top_k

        if self._collection is None:
            logger.warning("Retriever: no collection — returning empty results")
            return []

        results = self._collection.query(query_texts=[query], n_results=k)
        chunks: list[RetrievedChunk] = []
        for i, doc in enumerate(results["documents"][0]):
            chunks.append(
                RetrievedChunk(
                    id=results["ids"][0][i],
                    content=doc,
                    source=results["metadatas"][0][i].get("source", "unknown"),
                    score=1 - results["distances"][0][i],
                    metadata=results["metadatas"][0][i],
                )
            )
        return chunks


retriever = VaultRetriever()
