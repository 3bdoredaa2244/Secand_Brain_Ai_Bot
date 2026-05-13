"""
Runtime configuration store — overrides for settings that should be editable
without restarting the backend (vault path, primarily).

Backed by a JSON file under backend/data/runtime_config.json. Settings loaded
here win over values from .env / pydantic-settings at lookup time.

Why this exists
───────────────
The vault location is user-specific (e.g. D:\\SecondBrainVault on Windows).
Editing .env and restarting works, but the UI should be able to switch
vaults on the fly and persist the choice across restarts. This module
keeps that persistence concern out of pydantic-settings.

Usage
─────
    from app.core.runtime_config import runtime_config
    path = runtime_config.get_vault_path()   # Path with override applied
    runtime_config.set_vault_path("D:/SecondBrainVault")  # persists
"""
from __future__ import annotations

import json
import threading
from pathlib import Path
from typing import Any

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)

_DATA_DIR = Path(__file__).resolve().parents[2] / "data"
_CONFIG_FILE = _DATA_DIR / "runtime_config.json"


class RuntimeConfig:
    """Thread-safe JSON-backed override store."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._data: dict[str, Any] = {}
        self._load()

    # ── persistence ───────────────────────────────────────────────────────────

    def _load(self) -> None:
        if not _CONFIG_FILE.exists():
            return
        try:
            with _CONFIG_FILE.open("r", encoding="utf-8") as fp:
                self._data = json.load(fp) or {}
        except Exception as exc:
            logger.warning("RuntimeConfig: could not read %s — %s", _CONFIG_FILE, exc)
            self._data = {}

    def _save(self) -> None:
        _DATA_DIR.mkdir(parents=True, exist_ok=True)
        tmp = _CONFIG_FILE.with_suffix(".json.tmp")
        with tmp.open("w", encoding="utf-8") as fp:
            json.dump(self._data, fp, indent=2, sort_keys=True)
        tmp.replace(_CONFIG_FILE)

    # ── generic ───────────────────────────────────────────────────────────────

    def get(self, key: str, default: Any = None) -> Any:
        with self._lock:
            return self._data.get(key, default)

    def set(self, key: str, value: Any) -> None:
        with self._lock:
            self._data[key] = value
            self._save()

    # ── vault helpers (most common override) ──────────────────────────────────

    def get_vault_path(self) -> Path:
        """Effective vault path: runtime override > settings.vault_path."""
        override = self.get("vault_path")
        if override:
            return Path(override).expanduser()
        return Path(get_settings().vault_path).expanduser()

    def set_vault_path(self, path: str | Path) -> Path:
        """Persist a new vault path and return the resolved value."""
        p = Path(path).expanduser()
        self.set("vault_path", str(p))
        return p


runtime_config = RuntimeConfig()
