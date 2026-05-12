"""
Encrypted token persistence for OAuth credentials.

Tokens are stored at <backend>/data/tokens/google.json after encryption with
Fernet, keyed off a SHA-256 derivation of SECRET_KEY. This is good enough for
a single-user developer setup. For multi-user production, swap this out for
Vault / AWS Secrets Manager / a real KMS.

The file format is opaque ciphertext; the plaintext is a Google OAuth2 token
dict as produced by google-auth's Credentials.to_json().
"""
import base64
import hashlib
import json
import threading
from pathlib import Path

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)
settings = get_settings()

_TOKEN_DIR = Path(__file__).resolve().parents[4] / "data" / "tokens"
_TOKEN_FILE = _TOKEN_DIR / "google.bin"


def _derive_key(secret: str) -> bytes:
    """Derive a 32-byte url-safe base64 Fernet key from SECRET_KEY."""
    digest = hashlib.sha256(secret.encode("utf-8")).digest()
    return base64.urlsafe_b64encode(digest)


class TokenStore:
    """Single-instance encrypted store for one provider (Google).

    Thread-safe: all methods take a lock so the file is never half-written.
    """

    def __init__(self) -> None:
        self._lock = threading.Lock()
        _TOKEN_DIR.mkdir(parents=True, exist_ok=True)

    # ── public ────────────────────────────────────────────────────────────────

    def has_tokens(self) -> bool:
        return _TOKEN_FILE.exists() and _TOKEN_FILE.stat().st_size > 0

    def save(self, token_dict: dict) -> None:
        """Encrypt and persist a token dict atomically."""
        ciphertext = self._encrypt(json.dumps(token_dict).encode("utf-8"))
        with self._lock:
            tmp = _TOKEN_FILE.with_suffix(".tmp")
            tmp.write_bytes(ciphertext)
            tmp.replace(_TOKEN_FILE)
        logger.info("TokenStore: saved tokens (%d bytes ciphertext)", len(ciphertext))

    def load(self) -> dict | None:
        if not self.has_tokens():
            return None
        with self._lock:
            try:
                ciphertext = _TOKEN_FILE.read_bytes()
                plaintext = self._decrypt(ciphertext)
                return json.loads(plaintext)
            except Exception as exc:
                logger.error("TokenStore: failed to load tokens — %s", exc)
                return None

    def clear(self) -> None:
        with self._lock:
            if _TOKEN_FILE.exists():
                _TOKEN_FILE.unlink()
                logger.info("TokenStore: tokens cleared")

    # ── crypto ────────────────────────────────────────────────────────────────

    def _encrypt(self, plaintext: bytes) -> bytes:
        from cryptography.fernet import Fernet  # noqa: PLC0415
        return Fernet(_derive_key(settings.secret_key)).encrypt(plaintext)

    def _decrypt(self, ciphertext: bytes) -> bytes:
        from cryptography.fernet import Fernet, InvalidToken  # noqa: PLC0415
        try:
            return Fernet(_derive_key(settings.secret_key)).decrypt(ciphertext)
        except InvalidToken as exc:
            raise ValueError(
                "TokenStore: cannot decrypt — SECRET_KEY changed since tokens were saved. "
                "Run /api/v1/auth/google/disconnect and re-authorize."
            ) from exc


token_store = TokenStore()
