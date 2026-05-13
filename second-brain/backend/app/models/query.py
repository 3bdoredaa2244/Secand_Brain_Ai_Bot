from typing import Literal
from pydantic import BaseModel, Field


class QueryRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=2000)
    top_k: int = Field(default=5, ge=1, le=20)
    filters: dict[str, str] = Field(default_factory=dict)
    # When set, the agent loads recent turns from this session and writes
    # the new exchange back so follow-ups stay coherent.
    session_id: str | None = None


class DocumentChunk(BaseModel):
    id: str
    content: str
    source: str
    score: float
    metadata: dict[str, str] = Field(default_factory=dict)


class QueryResponse(BaseModel):
    query: str
    chunks: list[DocumentChunk]
    answer: str | None = None
    # Which external tool produced the answer (None = vault RAG or LLM fallback)
    tool_used: str | None = None
    # Describes where the answer came from — useful for UI badges and debugging
    answer_source: Literal["vault", "tool", "llm_fallback", "no_results", "error"] = "vault"
