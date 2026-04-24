import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.logging import setup_logging, get_logger
from app.api.v1.router import router
from app.services.rag.retriever import retriever
from app.workers.redis_consumer import consumer
from app.workers.proactive_worker import worker

setup_logging()
logger = get_logger(__name__)
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting %s v%s", settings.app_name, settings.app_version)

    # ---- Startup ----
    try:
        retriever.connect()
    except Exception as e:
        logger.warning("Retriever failed: %s", e)

    try:
        await consumer.connect()
    except Exception as e:
        logger.warning("Redis consumer failed to connect: %s", e)

    consumer_task = asyncio.create_task(consumer.start())
    worker_task = asyncio.create_task(worker.start())

    yield

    # ---- Shutdown ----
    logger.info("Shutting down")

    try:
        await consumer.stop()
    except Exception:
        pass

    try:
        await worker.stop()
    except Exception:
        pass

    consumer_task.cancel()
    worker_task.cancel()


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)