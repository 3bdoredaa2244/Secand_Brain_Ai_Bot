"""Verify the voice stack imports without OpenBLAS errors and reports state."""
import sys

def w(msg):
    print(msg, flush=True)
    with open("_verify_out.txt", "a", encoding="utf-8") as f:
        f.write(str(msg) + "\n")

# Truncate the output file
open("_verify_out.txt", "w", encoding="utf-8").close()

w("=== Step 1: runtime tuning ===")
from app.core import runtime_tuning
applied = runtime_tuning.apply()
for k, v in applied.items():
    w(f"  {k}={v}")

w("\n=== Step 2: import main.py (loads chromadb, gmail, everything) ===")
import main
w("  main imported OK")

w("\n=== Step 3: voice subsystem readiness ===")
from app.services.voice.transcriber import transcriber
from app.services.voice.synthesizer import synthesizer
w(f"  STT available: {transcriber.is_available()}")
w(f"  TTS available: {synthesizer.is_available()}")
w(f"  TTS voice info: {synthesizer.voice_info()}")

w("\n=== Step 4: route registration ===")
from main import app
for r in app.routes:
    path = getattr(r, "path", "")
    if "voice" in path:
        kind = type(r).__name__
        w(f"  [{kind}] {path}")

w("\n=== All checks passed — no OpenBLAS crash ===")
