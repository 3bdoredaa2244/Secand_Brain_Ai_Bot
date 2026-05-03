"""
RAG engine — orchestrates indexing and retrieval.

Phase 2: wired to MemoryEngine so that when LLM_PROVIDER is configured the
`answer` field in QueryResponse is populated; otherwise degrades to Phase 1
behaviour (raw chunks, answer=None).
"""
from app.core.config import get_settings
from app.core.logging import get_logger
from app.models.query import QueryRequest, QueryResponse, DocumentChunk
from app.services.rag.indexer import VaultIndexer
from app.services.rag.memory import MemoryEngine, memory_engine as default_memory
from app.services.rag.retriever import VaultRetriever, retriever as default_retriever

logger = get_logger(__name__)
settings = get_settings()


class RAGEngine:
    def __init__(
        self,
        ret: VaultRetriever | None = None,
        mem: MemoryEngine | None = None,
    ) -> None:
        self._retriever = ret or default_retriever
        self._memory = mem or default_memory
        self._indexer = VaultIndexer(settings.vault_path)

    async def index_vault(self) -> int:
        """Reindex all vault documents via the legacy VaultIndexer. Returns chunk count."""
        chunks = self._indexer.scan()
        if not chunks:
            logger.warning("RAGEngine: no chunks produced by indexer")
            return 0
        self._retriever.upsert(chunks)
        logger.info("RAGEngine: upserted %d chunks", len(chunks))
        return len(chunks)

    async def query(self, request: QueryRequest) -> QueryResponse:
        """Retrieve relevant chunks and optionally synthesise an LLM answer.

        If LLM_PROVIDER is set and the API key is present, `answer` is populated.
        Otherwise only `chunks` are returned (safe degradation).
        """
        where = request.filters if request.filters else None

        chunks_raw = await self._memory.retrieve(
            query=request.text,
            top_k=request.top_k,
            where=where,
        )

        answer = await self._memory.reason(request.text, chunks_raw)

        chunks = [
            DocumentChunk(
                id=r.id,
                content=r.content,
                source=r.source,
                score=r.score,
                metadata=r.metadata,
            )
            for r in chunks_raw
        ]

        return QueryResponse(query=request.text, chunks=chunks, answer=answer)
