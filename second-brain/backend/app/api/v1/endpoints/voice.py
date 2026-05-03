"""
Voice input endpoint.

POST /api/v1/voice/input
  - Accept an audio file (multipart/form-data, field name: "file")
  - Transcribe with Whisper if installed, otherwise return a stub transcript
  - Forward the transcript to the RAG query pipeline
  - Return transcript + full QueryResponse

Install Whisper for real transcription:
    pip install openai-whisper

Without it the endpoint still works — it returns a stub transcript so the
rest of the pipeline can be tested end-to-end.
"""
import tempfile
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from pydantic import BaseModel

from app.core.config import get_settings
from app.core.logging import get_logger
from app.models.query import DocumentChunk, QueryResponse
from app.services.rag.engine import RAGEngine
from app.services.rag.memory import memory_engine
from app.services.rag.retriever import retriever
from app.models.query import QueryRequest

logger = get_logger(__name__)
settings = get_settings()
router = APIRouter(prefix="/voice", tags=["voice"])

_SUPPORTED_MIME = {
    "audio/mpeg", "audio/mp4", "audio/wav", "audio/x-wav",
    "audio/webm", "audio/ogg", "audio/flac",
}
_MAX_BYTES = 25 * 1024 * 1024  # 25 MB


class VoiceResponse(BaseModel):
    transcript: str
    source: str           # "whisper" | "stub"
    query_result: QueryResponse


def get_engine() -> RAGEngine:
    return RAGEngine(ret=retriever, mem=memory_engine)


@router.post("/input", response_model=VoiceResponse)
async def voice_input(
    file: UploadFile = File(..., description="Audio file to transcribe"),
    engine: RAGEngine = Depends(get_engine),
) -> VoiceResponse:
    """Transcribe an audio file and query the knowledge base with the result."""
    raw = await file.read()
    if len(raw) > _MAX_BYTES:
        raise HTTPException(status_code=413, detail="Audio file exceeds 25 MB limit")

    transcript, source = await _transcribe(raw, file.filename or "audio")

    if not transcript.strip():
        raise HTTPException(status_code=422, detail="Transcription produced empty text")

    request = QueryRequest(text=transcript, top_k=settings.rag_top_k)
    result = await engine.query(request)

    return VoiceResponse(transcript=transcript, source=source, query_result=result)


async def _transcribe(audio_bytes: bytes, filename: str) -> tuple[str, str]:
    """Try Whisper; fall back to stub if not installed."""
    try:
        import whisper  # noqa: PLC0415
    except ImportError:
        logger.info(
            "VoiceEndpoint: 'openai-whisper' not installed — using stub transcript. "
            "Install with: pip install openai-whisper"
        )
        return _stub_transcript(filename), "stub"

    suffix = Path(filename).suffix or ".wav"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(audio_bytes)
        tmp_path = tmp.name

    try:
        model = whisper.load_model(settings.whisper_model)
        result = model.transcribe(tmp_path)
        text: str = result.get("text", "").strip()
        logger.info("VoiceEndpoint: Whisper transcribed %d chars", len(text))
        return text, "whisper"
    except Exception as exc:
        logger.error("VoiceEndpoint: Whisper failed — %s", exc)
        return _stub_transcript(filename), "stub"
    finally:
        Path(tmp_path).unlink(missing_ok=True)


def _stub_transcript(filename: str) -> str:
    return f"[stub transcript — install openai-whisper to enable real transcription] file={filename}"
