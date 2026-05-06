"""
AgentEngine — top-level query orchestrator.

Decision flow
─────────────
1. IntentRouter  →  external tool match (crypto, weather, …)
      hit  →  return tool answer immediately
      miss →  continue

2. Vault RAG  →  ChromaDB similarity search
      hit  →  optional LLM synthesis over vault context
               return chunks + answer
      miss →  continue

3. LLM general fallback  →  answer from model knowledge (no vault context)
      configured  →  return LLM answer, source="llm_fallback"
      not configured →  return polite "nothing found" message

Guarantee: query() NEVER raises. Every code path returns a valid QueryResponse.
"""
from app.core.config import get_settings
from app.core.logging import get_logger
from app.models.query import DocumentChunk, QueryRequest, QueryResponse
from app.services.rag.memory import MemoryEngine, memory_engine as default_memory
from app.services.rag.retriever import RetrievedChunk, VaultRetriever, retriever as default_retriever
from app.services.tools.router import IntentRouter, router as default_router

logger = get_logger(__name__)
settings = get_settings()


class AgentEngine:
    def __init__(
        self,
        ret: VaultRetriever | None = None,
        mem: MemoryEngine | None = None,
        tool_router: IntentRouter | None = None,
    ) -> None:
        self._retriever = ret or default_retriever
        self._memory = mem or default_memory
        self._router = tool_router or default_router

    # ── public interface ──────────────────────────────────────────────────────

    async def query(self, request: QueryRequest) -> QueryResponse:
        """Handle a user query. Guaranteed to return a valid response — never raises."""
        try:
            return await self._route(request)
        except Exception as exc:
            logger.error(
                "AgentEngine: unhandled error for query '%s': %s",
                request.text[:80], exc, exc_info=True,
            )
            return QueryResponse(
                query=request.text,
                chunks=[],
                answer="Something went wrong while processing your query. Please try again.",
                tool_used=None,
                answer_source="error",
            )

    # ── routing logic ─────────────────────────────────────────────────────────

    async def _route(self, request: QueryRequest) -> QueryResponse:
        # ── Step 1: external tool ─────────────────────────────────────────────
        tool_name, tool_result = await self._router.run_tool(request.text)
        if tool_result is not None:
            logger.info("AgentEngine: answered via tool '%s'", tool_name)
            return QueryResponse(
                query=request.text,
                chunks=[],
                answer=tool_result.answer,
                tool_used=tool_name,
                answer_source="tool",
            )

        # ── Step 2: vault RAG ─────────────────────────────────────────────────
        where = request.filters if request.filters else None
        chunks_raw = await self._memory.retrieve(
            query=request.text,
            top_k=request.top_k,
            where=where,
        )

        if chunks_raw:
            answer = await self._memory.reason(request.text, chunks_raw)
            logger.info(
                "AgentEngine: vault RAG returned %d chunk(s), LLM=%s",
                len(chunks_raw), answer is not None,
            )
            return QueryResponse(
                query=request.text,
                chunks=[_to_doc(c) for c in chunks_raw],
                answer=answer,
                tool_used=None,
                answer_source="vault",
            )

        # ── Step 3: LLM general fallback ──────────────────────────────────────
        if settings.has_llm():
            answer = await self._memory.llm_fallback(request.text)
            if answer:
                logger.info("AgentEngine: answered via LLM general fallback")
                return QueryResponse(
                    query=request.text,
                    chunks=[],
                    answer=answer,
                    tool_used=None,
                    answer_source="llm_fallback",
                )

        # ── Step 4: nothing found ─────────────────────────────────────────────
        logger.info("AgentEngine: no answer found for query '%s'", request.text[:60])
        return QueryResponse(
            query=request.text,
            chunks=[],
            answer=(
                "I couldn't find anything relevant in your vault for this query. "
                "Try syncing your Obsidian vault or rephrasing the question."
                + ("" if settings.has_llm() else
                   " Set LLM_PROVIDER in .env for general-knowledge fallback answers.")
            ),
            tool_used=None,
            answer_source="no_results",
        )


# ── helpers ───────────────────────────────────────────────────────────────────

def _to_doc(c: RetrievedChunk) -> DocumentChunk:
    return DocumentChunk(
        id=c.id,
        content=c.content,
        source=c.source,
        score=c.score,
        metadata=c.metadata,
    )


agent_engine = AgentEngine()  # singleton
