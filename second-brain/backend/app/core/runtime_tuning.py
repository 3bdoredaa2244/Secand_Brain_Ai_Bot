"""
Runtime tuning — sets thread-limiting environment variables BEFORE any
ML library imports happen anywhere in the process.

Why this exists
───────────────
On Windows, loading numpy + ctranslate2 (faster-whisper) + onnxruntime (Piper)
+ chromadb all in one process triggers OpenBLAS to try to allocate per-thread
workspace memory across many threads. Some Windows builds of OpenBLAS exhaust
their allocator and crash with "Memory allocation still failed after 10 retries".

Setting these env vars to 1 caps each numerical backend at a single thread,
which is fine for our voice workload (latency-bound, not CPU-bound) and
eliminates the contention.

Usage
─────
This file MUST be imported before any other module that pulls in numpy or
ML libraries. In main.py it is the first import:

    import app.core.runtime_tuning  # noqa: F401  -- side-effect import

The values are only set when not already present in the environment, so users
who explicitly tune threads via shell vars are respected.
"""
import os

_DEFAULTS: dict[str, str] = {
    "OPENBLAS_NUM_THREADS": "1",
    "OMP_NUM_THREADS": "1",
    "MKL_NUM_THREADS": "1",
    "NUMEXPR_NUM_THREADS": "1",
    "BLIS_NUM_THREADS": "1",
    # ONNX runtime — disable per-session thread pool so SessionOptions wins
    "OMP_WAIT_POLICY": "PASSIVE",
}

for key, value in _DEFAULTS.items():
    os.environ.setdefault(key, value)


def apply() -> dict[str, str]:
    """Idempotent no-op — the env vars are set at module import time.

    Call this from main.py to make the intent visible and keep linters happy
    about an otherwise "unused" import. Returns the active tuning values so
    callers can log them.
    """
    return {key: os.environ.get(key, "") for key in _DEFAULTS}
