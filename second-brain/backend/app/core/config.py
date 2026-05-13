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
    redis_url: str = "redis://localhost:6379"
    redis_stream_actions: str = "stream:actions"
    redis_stream_triggers: str = "stream:triggers"

    # Vault
    vault_path: Path = Path("../vault")

    # RAG / Vector store
    chroma_host: str = "localhost"
    chroma_port: int = 8001
    chroma_collection: str = "second_brain"
    embedding_model: str = "sentence-transformers/all-MiniLM-L6-v2"
    rag_top_k: int = 5

    # Obsidian auto-sync
    obsidian_sync_on_startup: bool = True

    # Confirmation gate
    gate_timeout_seconds: int = 300
    gate_require_confirmation: bool = True

    # Security
    secret_key: str = "change-me-in-production"
    allowed_origins: list[str] = ["http://localhost:3000"]

    # ── Phase 2: LLM ─────────────────────────────────────────────────────────
    # Provider: "anthropic" | "openai" | "none"
    llm_provider: str = "none"
    anthropic_api_key: str = ""
    openai_api_key: str = ""
    # faster-whisper model name. English-only variants (.en suffix) are ~30%
    # smaller and faster than their multilingual counterparts.
    # Recommended for low-memory CPU use: tiny.en | base.en
    # Multilingual: tiny | base | small | medium
    whisper_model: str = "tiny.en"
    # CPU threads for faster-whisper inference. Keep at 1 on Windows to avoid
    # OpenBLAS allocator contention when chromadb/Piper are also loaded.
    whisper_cpu_threads: int = 1

    # Piper TTS voice file (.onnx). Empty = default path under backend/data/piper/
    piper_voice_path: str = ""

    # ── Phase 2/3: Google integrations (Gmail + Calendar share OAuth) ────────
    gmail_client_id: str = ""
    gmail_client_secret: str = ""
    gmail_refresh_token: str = ""  # legacy — Phase 3 uses encrypted token store
    google_oauth_redirect_uri: str = "http://localhost:8000/api/v1/auth/google/callback"
    google_calendar_credentials_json: str = ""

    # ── Phase 2: Health ───────────────────────────────────────────────────────
    # Comma-separated list of daily vitamins to track
    health_vitamins: str = "Vitamin D,Omega-3,Magnesium"
    # Hour (0–23) at which the daily health check trigger fires
    health_check_hour: int = 8

    def has_llm(self) -> bool:
        """True when at least one LLM provider is fully configured."""
        if self.llm_provider == "anthropic":
            return bool(self.anthropic_api_key)
        if self.llm_provider == "openai":
            return bool(self.openai_api_key)
        return False

    def vitamins_list(self) -> list[str]:
        return [v.strip() for v in self.health_vitamins.split(",") if v.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
