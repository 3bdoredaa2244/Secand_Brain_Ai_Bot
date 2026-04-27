"""
RAG engine — orchestrates indexing and retrieval.
Phase 1: wiring + interfaces. LLM synthesis added in Phase 2.
"""
from pathlib import Path
from app.core.config import get_settings
from app.core.logging import get_logger
from app.models.query import QueryRequest, QueryResponse, DocumentChunk
from app.services.rag.indexer import VaultIndexer
from app.services.rag.retriever import VaultRetriever, RetrievedChunk

logger = get_logger(__name__)
settings = get_settings()


class RAGEngine:
    def __init__(self, retriever: VaultRetriever) -> None:
        self._retriever = retriever
        self._indexer = VaultIndexer(settings.vault_path)

    async def index_vault(self) -> int:
        """Reindex all vault documents. Returns chunk count."""
        chunks = self._indexer.scan()
        if not chunks:
            logger.warning("RAGEngine: no chunks produced by indexer")
            return 0

        self._retriever.upsert(chunks)
        logger.info("RAGEngine: upserted %d chunks", len(chunks))
        return len(chunks)

    async def query(self, request: QueryRequest) -> QueryResponse:
        """Retrieve relevant chunks for a query (synthesis added in Phase 2)."""
        raw: list[RetrievedChunk] = self._retriever.search(request.text, request.top_k)
        chunks = [
            DocumentChunk(
                id=r.id,
                content=r.content,
                source=r.source,
                score=r.score,
                metadata=r.metadata,
            )
            for r in raw
        ]
        return QueryResponse(query=request.text, chunks=chunks, answer=None)
