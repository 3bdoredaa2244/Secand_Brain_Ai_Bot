from fastapi import APIRouter, BackgroundTasks

from app.models.query import QueryRequest, QueryResponse
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

    Guaranteed to return HTTP 200 with a valid JSON body — never 500.
    """
    return await agent_engine.query(request)


@router.post("/index")
async def index_vault(background_tasks: BackgroundTasks) -> dict:
    """Reindex the full Obsidian vault in the background."""
    engine = RAGEngine(retriever)
    background_tasks.add_task(engine.index_vault)
    return {"message": "Vault indexing started in background"}
