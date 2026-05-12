"""
Voice subsystem — streaming STT + TTS for the immersive voice UI.

Modules:
  transcriber.py   — faster-whisper wrapper (STT)
  synthesizer.py   — Piper TTS wrapper
  session.py       — per-WebSocket VoiceSession (state machine)
  vad.py           — simple energy-based voice activity detection

All components lazy-load their models so importing this package is cheap.
"""
from app.services.voice.session import VoiceSession
from app.services.voice.synthesizer import synthesizer
from app.services.voice.transcriber import transcriber

__all__ = ["VoiceSession", "transcriber", "synthesizer"]
