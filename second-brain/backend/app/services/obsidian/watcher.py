"""
Vault file watcher.

Uses watchdog (OS-native inotify/FSEvents/ReadDirectoryChangesW) to detect
.md changes in the vault folder and call async sync/remove callbacks on the
running asyncio event loop.

Debouncing (500 ms) is applied per-path to coalesce rapid saves (e.g. editor
autosave writing temp files before the final save).
"""
import asyncio
import threading
from collections.abc import Awaitable, Callable
from pathlib import Path

from app.core.logging import get_logger

logger = get_logger(__name__)

try:
    from watchdog.events import FileSystemEvent, FileSystemEventHandler
    from watchdog.observers import Observer
    _WATCHDOG_OK = True
except ImportError:
    _WATCHDOG_OK = False
    logger.warning(
        "watchdog not installed — file watching disabled. "
        "Install with: pip install watchdog>=4.0"
    )

_DEBOUNCE_SECONDS = 0.5


# ── debouncer ─────────────────────────────────────────────────────────────────

class _Debouncer:
    """Thread-safe per-key debouncer using threading.Timer."""

    def __init__(self, delay: float = _DEBOUNCE_SECONDS) -> None:
        self._delay = delay
        self._timers: dict[str, threading.Timer] = {}
        self._lock = threading.Lock()

    def schedule(self, key: str, fn: Callable[[], None]) -> None:
        with self._lock:
            existing = self._timers.get(key)
            if existing:
                existing.cancel()
            t = threading.Timer(self._delay, fn)
            self._timers[key] = t
            t.start()

    def cancel_all(self) -> None:
        with self._lock:
            for t in self._timers.values():
                t.cancel()
            self._timers.clear()


# ── event handler ─────────────────────────────────────────────────────────────

if _WATCHDOG_OK:
    class _VaultEventHandler(FileSystemEventHandler):
        def __init__(
            self,
            loop: asyncio.AbstractEventLoop,
            sync_fn: Callable[[Path], Awaitable[int]],
            remove_fn: Callable[[Path], Awaitable[None]],
        ) -> None:
            super().__init__()
            self._loop = loop
            self._sync_fn = sync_fn
            self._remove_fn = remove_fn
            self._debouncer = _Debouncer()

        # ── helpers ──

        @staticmethod
        def _is_md(path: str) -> bool:
            p = Path(path)
            return p.suffix == ".md" and not p.name.startswith(".")

        def _fire_async(self, coro: Awaitable) -> None:
            asyncio.run_coroutine_threadsafe(coro, self._loop)

        def _schedule_sync(self, raw_path: str) -> None:
            path = raw_path  # capture now, not by reference to loop variable
            self._debouncer.schedule(
                path,
                lambda: self._fire_async(self._sync_fn(Path(path))),
            )

        # ── watchdog hooks ──

        def on_created(self, event: "FileSystemEvent") -> None:
            if not event.is_directory and self._is_md(event.src_path):
                logger.debug("Vault: created %s", event.src_path)
                self._schedule_sync(event.src_path)

        def on_modified(self, event: "FileSystemEvent") -> None:
            if not event.is_directory and self._is_md(event.src_path):
                logger.debug("Vault: modified %s", event.src_path)
                self._schedule_sync(event.src_path)

        def on_deleted(self, event: "FileSystemEvent") -> None:
            if not event.is_directory and self._is_md(event.src_path):
                logger.info("Vault: deleted %s — removing from index", event.src_path)
                self._fire_async(self._remove_fn(Path(event.src_path)))

        def on_moved(self, event: "FileSystemEvent") -> None:
            if event.is_directory:
                return
            if self._is_md(event.src_path):
                logger.info("Vault: moved %s → removing old index", event.src_path)
                self._fire_async(self._remove_fn(Path(event.src_path)))
            if self._is_md(event.dest_path):
                logger.debug("Vault: moved → %s", event.dest_path)
                self._schedule_sync(event.dest_path)


# ── public watcher ────────────────────────────────────────────────────────────

class VaultWatcher:
    """Wraps a watchdog Observer. Call start() inside the FastAPI lifespan."""

    def __init__(
        self,
        vault_path: Path,
        sync_fn: Callable[[Path], Awaitable[int]],
        remove_fn: Callable[[Path], Awaitable[None]],
    ) -> None:
        self._vault_path = vault_path
        self._sync_fn = sync_fn
        self._remove_fn = remove_fn
        self._observer = None
        self._handler = None

    def start(self, loop: asyncio.AbstractEventLoop) -> None:
        if not _WATCHDOG_OK:
            logger.warning("VaultWatcher: watchdog unavailable — auto-sync disabled")
            return

        if not self._vault_path.exists():
            logger.warning(
                "VaultWatcher: vault path %s does not exist — watcher not started",
                self._vault_path,
            )
            return

        self._handler = _VaultEventHandler(loop, self._sync_fn, self._remove_fn)
        self._observer = Observer()
        self._observer.schedule(self._handler, str(self._vault_path), recursive=True)
        self._observer.start()
        logger.info("VaultWatcher: watching %s", self._vault_path)

    def stop(self) -> None:
        if self._handler:
            self._handler._debouncer.cancel_all()
        if self._observer and self._observer.is_alive():
            self._observer.stop()
            self._observer.join(timeout=5)
            logger.info("VaultWatcher: stopped")
