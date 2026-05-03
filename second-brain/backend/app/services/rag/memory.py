"""
MemoryEngine — retrieve → reason → respond.

Wraps VaultRetriever with optional LLM synthesis.
The system degrades gracefully: if no LLM provider is configured,
`answer` stays None and only raw chunks are returned (Phase 1 behaviour).

Supported providers (set LLM_PROVIDER in .env):
  anthropic → requires ANTHROPIC_API_KEY + pip install anthropic
  openai    → requires OPENAI_API_KEY + pip install openai
  none      → retrieval-only, no synthesis
"""
from app.core.config import get_settings
from app.core.logging import get_logger
from app.services.rag.retriever import RetrievedChunk, VaultRetriever, retriever as default_retriever

logger = get_logger(__name__)
settings = get_settings()

_SYSTEM_PROMPT = (
    "You are a personal AI assistant. Answer the user's question using ONLY "
    "the context excerpts provided from their private knowledge base. "
    "Cite the source note when relevant. "
    "If the answer is not in the context, say so clearly — do not invent information."
)


class MemoryEngine:
    def __init__(self, ret: VaultRetriever | None = None) -> None:
        self._retriever = ret or default_retriever

    # ── public interface ──────────────────────────────────────────────────────

    async def retrieve(
        self,
        query: str,
        top_k: int = 5,
        where: dict | None = None,
    ) -> list[RetrievedChunk]:
        return self._retriever.search(query, top_k, where=where)

    async def reason(self, query: str, chunks: list[RetrievedChunk]) -> str | None:
        """Call the configured LLM to synthesise an answer from chunks."""
        if not chunks or not settings.has_llm():
            return None
        if settings.llm_provider == "anthropic":
            return await self._reason_anthropic(query, chunks)
        if settings.llm_provider == "openai":
            return await self._reason_openai(query, chunks)
        return None

    # ── Anthropic ─────────────────────────────────────────────────────────────

    async def _reason_anthropic(self, query: str, chunks: list[RetrievedChunk]) -> str | None:
        try:
            import anthropic  # noqa: PLC0415
        except ImportError:
            logger.warning("MemoryEngine: 'anthropic' package not installed — pip install anthropic")
            return None

        context = _build_context(chunks)
        try:
            client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
            msg = await client.messages.create(
                model="claude-sonnet-4-6",
                max_tokens=1024,
                system=_SYSTEM_PROMPT,
                messages=[
                    {
                        "role": "user",
                        "content": (
                            f"Context from my knowledge base:\n\n{context}"
                            f"\n\n---\nQuestion: {query}"
                        ),
                    }
                ],
            )
            return msg.content[0].text
        except Exception as exc:
            logger.error("MemoryEngine: Anthropic call failed — %s", exc)
            return None

    # ── OpenAI ────────────────────────────────────────────────────────────────

    async def _reason_openai(self, query: str, chunks: list[RetrievedChunk]) -> str | None:
        try:
            import openai as _openai  # noqa: PLC0415
        except ImportError:
            logger.warning("MemoryEngine: 'openai' package not installed — pip install openai")
            return None

        context = _build_context(chunks)
        try:
            client = _openai.AsyncOpenAI(api_key=settings.openai_api_key)
            resp = await client.chat.completions.create(
                model="gpt-4o-mini",
                max_tokens=1024,
                messages=[
                    {"role": "system", "content": _SYSTEM_PROMPT},
                    {
                        "role": "user",
                        "content": (
                            f"Context from my knowledge base:\n\n{context}"
                            f"\n\n---\nQuestion: {query}"
                        ),
                    },
                ],
            )
            return resp.choices[0].message.content
        except Exception as exc:
            logger.error("MemoryEngine: OpenAI call failed — %s", exc)
            return None


def _build_context(chunks: list[RetrievedChunk]) -> str:
    parts = []
    for i, c in enumerate(chunks, 1):
        parts.append(f"[{i}] Source: {c.source}\n{c.content}")
    return "\n\n".join(parts)


memory_engine = MemoryEngine()  # singleton
