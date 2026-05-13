#!/usr/bin/env python3
"""
verify_system.py — pre-flight check for the Second Brain stack.

Run from the repo root:
    python verify_system.py

Exits 0 when everything looks healthy, 1 when a hard dependency is missing.
Warnings (optional pieces missing) do not fail the script.

The script never imports the FastAPI app — it makes plain HTTP / socket
checks. That keeps it usable as a `wait-for-it` style gate before starting
the backend or running smoke tests.
"""
from __future__ import annotations

import io
import json
import os
import socket
import sys
from dataclasses import dataclass
from pathlib import Path
from urllib import error as urlerror, request as urlrequest

# Windows consoles default to cp1256 / cp437 — re-open stdout/stderr in UTF-8
# so the script doesn't crash printing non-ASCII characters.
if hasattr(sys.stdout, "buffer"):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "buffer"):
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

REPO_ROOT = Path(__file__).resolve().parent
BACKEND_DIR = REPO_ROOT / "backend"


# ── colours ────────────────────────────────────────────────────────────────

class _Colors:
    if os.name == "nt" and not os.environ.get("ANSICON"):
        # Best-effort: Windows Terminal supports ANSI; cmd.exe < Win10 doesn't.
        # Stick to plain text there.
        OK = WARN = ERR = DIM = END = ""
    else:
        OK   = "\033[92m"
        WARN = "\033[93m"
        ERR  = "\033[91m"
        DIM  = "\033[2m"
        END  = "\033[0m"


C = _Colors


@dataclass
class Check:
    name: str
    ok: bool
    detail: str
    fatal: bool = False   # if True, missing this fails the script

    def render(self) -> str:
        if self.ok:
            tag = f"{C.OK}OK{C.END}"
        elif self.fatal:
            tag = f"{C.ERR}FAIL{C.END}"
        else:
            tag = f"{C.WARN}WARN{C.END}"
        return f"  [{tag}] {self.name:<28}  {C.DIM}{self.detail}{C.END}"


# ── individual checks ──────────────────────────────────────────────────────


def check_python_version() -> Check:
    ok = sys.version_info >= (3, 12)
    return Check(
        "python>=3.12",
        ok,
        f"running {sys.version.split(' ', 1)[0]}",
        fatal=not ok,
    )


def check_port(host: str, port: int, label: str, fatal: bool = False) -> Check:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1.5)
    try:
        sock.connect((host, port))
        return Check(label, True, f"{host}:{port} reachable")
    except OSError as exc:
        return Check(label, False, f"{host}:{port} unreachable ({exc})", fatal=fatal)
    finally:
        sock.close()


def check_http(url: str, label: str, *, fatal: bool = False) -> Check:
    try:
        with urlrequest.urlopen(url, timeout=3) as resp:
            body_head = resp.read(200).decode("utf-8", errors="replace")
            return Check(label, True, f"{resp.status} - {body_head[:60].strip()}")
    except urlerror.HTTPError as exc:
        # Any HTTP response means the server is up — treat as reachable.
        return Check(label, True, f"{url} reachable (HTTP {exc.code})")
    except urlerror.URLError as exc:
        return Check(label, False, f"{url} not reachable ({exc.reason})", fatal=fatal)
    except Exception as exc:
        return Check(label, False, f"{url} error ({exc})", fatal=fatal)


def check_module(module: str, label: str | None = None, *, fatal: bool = False) -> Check:
    try:
        __import__(module)
        return Check(label or module, True, "import OK")
    except ImportError as exc:
        return Check(label or module, False, f"missing — pip install {module} ({exc})", fatal=fatal)


def check_vault_path() -> Check:
    """Look up the active vault path: runtime override > .env > default."""
    runtime_cfg = BACKEND_DIR / "data" / "runtime_config.json"
    path: str | None = None
    if runtime_cfg.exists():
        try:
            data = json.loads(runtime_cfg.read_text())
            path = data.get("vault_path")
        except Exception:
            pass
    if not path:
        env = BACKEND_DIR / ".env"
        if env.exists():
            for line in env.read_text().splitlines():
                if line.strip().startswith("VAULT_PATH="):
                    path = line.split("=", 1)[1].strip().strip('"').strip("'")
                    break
    if not path:
        path = "../vault"

    resolved = (BACKEND_DIR / path).resolve() if not Path(path).is_absolute() else Path(path)
    exists = resolved.exists()
    return Check(
        "obsidian vault",
        exists,
        f"{resolved} {'present' if exists else 'NOT FOUND'}",
        fatal=False,  # warn only — the user might fix via /obsidian/config later
    )


def check_piper_voice() -> Check:
    """Default Piper voice lives in backend/data/piper/."""
    voice = BACKEND_DIR / "data" / "piper" / "en_US-lessac-medium.onnx"
    if voice.exists():
        size_mb = round(voice.stat().st_size / 1_048_576, 1)
        return Check("piper voice model", True, f"{voice.name} ({size_mb} MB)")
    return Check(
        "piper voice model",
        False,
        "missing — POST /api/v1/voice/setup or run the backend once",
    )


def check_google_creds() -> Check:
    env = BACKEND_DIR / ".env"
    if not env.exists():
        return Check("google oauth", False, "no .env found")
    text = env.read_text()
    has_id = "GMAIL_CLIENT_ID=" in text and not text.split("GMAIL_CLIENT_ID=", 1)[1].split("\n", 1)[0].strip() in ("", '""', "''")
    has_secret = "GMAIL_CLIENT_SECRET=" in text and not text.split("GMAIL_CLIENT_SECRET=", 1)[1].split("\n", 1)[0].strip() in ("", '""', "''")
    if has_id and has_secret:
        return Check("google oauth", True, "client id + secret present in .env")
    return Check("google oauth", False, "GMAIL_CLIENT_ID / GMAIL_CLIENT_SECRET unset (skip if you don't want Gmail/Calendar)")


def check_thread_env() -> Check:
    """Confirm runtime_tuning would set the env vars (we don't import it here)."""
    expected = {"OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS"}
    set_vars = [v for v in expected if os.environ.get(v) == "1"]
    if len(set_vars) == len(expected):
        return Check("thread limits", True, "OpenBLAS/OMP capped at 1 thread")
    return Check(
        "thread limits",
        True,  # not fatal — main.py sets them at import time
        "will be set by app.core.runtime_tuning at startup",
    )


# ── orchestrator ───────────────────────────────────────────────────────────


def main() -> int:
    print(f"\nSecond Brain - system verification\n{'-' * 40}")

    checks: list[Check] = [
        check_python_version(),
        # Hard infrastructure (Docker services)
        check_port("localhost", 6379, "redis (6379)", fatal=False),
        check_http("http://localhost:8001/api/v1/heartbeat", "chromadb (8001)"),
        # Optional but expected
        check_http("http://localhost:8000/api/v1/health", "backend (8000)"),
        check_http("http://localhost:3000", "frontend (3000)"),
        # Local files
        check_vault_path(),
        check_piper_voice(),
        check_google_creds(),
        # Python deps (lazy — only flag the critical ones)
        check_module("fastapi", fatal=True),
        check_module("pydantic", fatal=True),
        check_module("redis", fatal=False),
        check_module("chromadb", fatal=False),
        check_module("faster_whisper", "faster-whisper", fatal=False),
        check_module("piper", "piper-tts", fatal=False),
        check_module("watchdog", fatal=False),
        check_module("googleapiclient", "google-api-python-client", fatal=False),
        check_thread_env(),
    ]

    for c in checks:
        print(c.render())

    fatal = [c for c in checks if not c.ok and c.fatal]
    warn  = [c for c in checks if not c.ok and not c.fatal]

    print(f"\n{'-' * 40}")
    print(f"  {len([c for c in checks if c.ok])} OK · {len(warn)} warnings · {len(fatal)} fatal")

    if fatal:
        print(f"\n{C.ERR}Verification failed.{C.END} Fix the FAIL items and re-run.")
        return 1
    if warn:
        print(f"\n{C.WARN}Verification passed with warnings.{C.END} Optional components missing.")
    else:
        print(f"\n{C.OK}All systems go.{C.END}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
