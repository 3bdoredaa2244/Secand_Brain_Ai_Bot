from fastapi import APIRouter, BackgroundTasks

from app.models.query import QueryRequest, QueryResponse
from app.services.agent.conversation_memory import conversation_memory
from app.services.agent.engine import agent_engine
from app.services.rag.engine import RAGEngine
from app.services.rag.retriever import retriever

router = APIRouter()


@router.post("/query", response_model=QueryResponse)
async def query_vault(request: QueryRequest) -> QueryResponse:
    """
    Hybrid agent query endpoint.

    Routes to the first matching handler in priority order:
      1. External tool (crypto prices, weather, …)
      2. Vault RAG (ChromaDB similarity search + optional LLM synthesis)
      3. LLM general fallback (when vault has no relevant notes)
      4. Graceful "no results" message

    When `session_id` is set, recent turns from that session are folded into
    the LLM prompt and the new exchange is recorded — enables follow-ups.

    Guaranteed to return HTTP 200 with a valid JSON body — never 500.
    """
    response = await agent_engine.query(request, session_id=request.session_id)
    if request.session_id and response.answer:
        await conversation_memory.append(request.session_id, "user", request.text)
        await conversation_memory.append(request.session_id, "assistant", response.answer)
    return response


@router.get("/chat/history")
async def chat_history(session_id: str, limit: int = 20) -> dict:
    """Return the stored turns for a chat session. Useful for restoring UI state."""
    turns = await conversation_memory.history(session_id, limit=limit)
    return {"session_id": session_id, "turns": turns}


@router.post("/chat/clear")
async def chat_clear(session_id: str) -> dict:
    """Erase the conversation history for a session."""
    await conversation_memory.clear(session_id)
    return {"session_id": session_id, "cleared": True}


@router.post("/index")
async def index_vault(background_tasks: BackgroundTasks) -> dict:
    """Reindex the full Obsidian vault in the background."""
    engine = RAGEngine(retriever)
    background_tasks.add_task(engine.index_vault)
    return {"message": "Vault indexing started in background"}
