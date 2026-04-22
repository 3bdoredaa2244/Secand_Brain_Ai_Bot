from functools import lru_cache
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # App
    app_name: str = "Second Brain"
    app_version: str = "0.1.0"
    debug: bool = False
    log_level: str = "INFO"

    # Server
    host: str = "0.0.0.0"
    port: int = 8000

    # Redis
    redis_url: str = "redis://redis:6379"
    redis_stream_actions: str = "stream:actions"
    redis_stream_triggers: str = "stream:triggers"

    # Vault
    vault_path: Path = Path("/vault")

    # RAG / Vector store
    chroma_host: str = "chromadb"
    chroma_port: int = 8001
    chroma_collection: str = "second_brain"
    embedding_model: str = "sentence-transformers/all-MiniLM-L6-v2"
    rag_top_k: int = 5

    # Confirmation gate
    gate_timeout_seconds: int = 300
    gate_require_confirmation: bool = True

    # Security
    secret_key: str = "change-me-in-production"
    allowed_origins: list[str] = ["http://localhost:3000"]


@lru_cache
def get_settings() -> Settings:
    return Settings()
