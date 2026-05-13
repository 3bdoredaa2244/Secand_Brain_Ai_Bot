import logging
import sys
from app.core.config import get_settings


def setup_logging() -> None:
    settings = get_settings()
    level = getattr(logging, settings.log_level.upper(), logging.INFO)
    fmt = "%(asctime)s | %(levelname)-8s | %(name)s | %(message)s"
    logging.basicConfig(stream=sys.stdout, level=level, format=fmt, datefmt="%Y-%m-%dT%H:%M:%S")
    # Quiet down libraries that otherwise flood the console on Windows.
    # uvicorn.access prints every poll; faster_whisper / chromadb chatter at INFO.
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    for noisy in (
        "watchdog", "httpx", "httpcore", "urllib3",
        "chromadb", "chromadb.telemetry", "chromadb.config",
        "faster_whisper", "ctranslate2",
        "onnxruntime", "huggingface_hub",
        "googleapiclient.discovery", "googleapiclient.http",
    ):
        logging.getLogger(noisy).setLevel(logging.WARNING)


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)
