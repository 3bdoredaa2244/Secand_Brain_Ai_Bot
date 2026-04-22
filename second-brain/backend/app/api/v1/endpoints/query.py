from fastapi import APIRouter, Depends, BackgroundTasks
from app.models.query import QueryRequest, QueryResponse
from app.services.rag.engine import RAGEngine
from app.services.rag.retriever import retriever

router = APIRouter()


def get_engine() -> RAGEngine:
    return RAGEngine(retriever)


@router.post("/query", response_model=QueryResponse)
async def query_vault(request: QueryRequest, engine: RAGEngine = Depends(get_engine)):
    return await engine.query(request)


@router.post("/index")
async def index_vault(background_tasks: BackgroundTasks, engine: RAGEngine = Depends(get_engine)):
    background_tasks.add_task(engine.index_vault)
    return {"message": "Indexing started in background"}
