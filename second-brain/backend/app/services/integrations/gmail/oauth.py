"""
Google OAuth 2.0 flow for Gmail + Calendar (PKCE-aware).

Both integrations share a single OAuth client (one consent screen, one refresh
token). The user clicks "Connect Google" once and both Gmail + Calendar work.

Flow
────
1. Frontend opens /api/v1/auth/google/login in a popup
2. build_auth_url() builds an authorisation URL WITH a PKCE code_challenge
   and stores the matching code_verifier server-side, keyed by `state`.
3. Google redirects back to /api/v1/auth/google/callback?code=...&state=...
4. exchange_code() retrieves the verifier by `state`, attaches it to a fresh
   Flow, and exchanges the code for tokens. Verifier is deleted on use.
5. Tokens are encrypted and persisted via TokenStore; the popup self-closes.

Why this exists
───────────────
google-auth-oauthlib 1.4+ enables PKCE automatically
(`autogenerate_code_verifier=True`), so the authorization request always
sends a `code_challenge`. The token exchange therefore MUST present the
matching `code_verifier`. Because /login and /callback are different
request lifecycles (and possibly different processes after reload), the
verifier has to be persisted across them.

Storage
───────
Redis when available (key `oauth:pkce:<state>`, TTL 600s). In-memory
fallback keyed by state, evicted lazily by expiry. The verifier is a
short-lived secret — it has no value once consumed.
"""
from __future__ import annotations

import asyncio
import secrets
import time

from app.core.config import get_settings
from app.core.logging import get_logger
from app.services.integrations.gmail.token_store import token_store

logger = get_logger(__name__)
settings = get_settings()

# Scopes — gmail.modify covers archive/label; gmail.send + gmail.compose cover drafts/sending.
# Calendar.events is technically a subset of `calendar`, listed explicitly so the consent
# screen makes the event-write permission visible.
SCOPES: list[str] = [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/gmail.modify",
    "https://www.googleapis.com/auth/gmail.compose",
    "https://www.googleapis.com/auth/calendar",
    "https://www.googleapis.com/auth/calendar.events",
    "openid", "email", "profile",
]


_PKCE_PREFIX = "oauth:pkce:"
_PKCE_TTL_SECONDS = 600  # 10 minutes — generous window for the consent screen


class GoogleOAuth:
    """Handles authorisation URL construction + PKCE-aware code exchange."""

    def __init__(self) -> None:
        self._redis = None
        # In-memory fallback: state -> (verifier, expires_at_epoch_seconds).
        # Only used when Redis is unreachable.
        self._mem_store: dict[str, tuple[str, float]] = {}
        self._mem_lock = asyncio.Lock()

    # ── lifecycle ─────────────────────────────────────────────────────────────

    async def connect(self) -> None:
        """Best-effort Redis connection for PKCE verifier storage.

        Called from main.py lifespan. Failures degrade silently to the
        in-memory store, which is fine for a single-process dev setup
        but loses state across `--reload` restarts.
        """
        try:
            import redis.asyncio as aioredis  # noqa: PLC0415
            client = await aioredis.from_url(settings.redis_url, decode_responses=True)
            await client.ping()
            self._redis = client
            logger.info("GoogleOAuth: PKCE store connected to Redis")
        except Exception as exc:
            logger.warning(
                "GoogleOAuth: Redis unavailable (%s) — PKCE store using in-memory fallback "
                "(verifiers will not survive backend restarts)",
                exc,
            )

    def is_configured(self) -> bool:
        return bool(settings.gmail_client_id and settings.gmail_client_secret)

    # ── login / callback ─────────────────────────────────────────────────────

    async def build_auth_url(self, state: str = "") -> str:
        """Build the consent-screen URL and persist the PKCE verifier.

        `state` is auto-generated if empty. Google echoes it back to the
        callback so we can look up the verifier.
        """
        if not self.is_configured():
            raise RuntimeError(
                "Google OAuth not configured — set GMAIL_CLIENT_ID and "
                "GMAIL_CLIENT_SECRET in .env"
            )
        if not state:
            state = secrets.token_urlsafe(24)

        flow = self._build_flow()
        # google-auth-oauthlib 1.4+ defaults this to True; we set it explicitly
        # so the behaviour is robust if upstream changes the default again.
        flow.autogenerate_code_verifier = True

        url, returned_state = flow.authorization_url(
            access_type="offline",       # required to receive a refresh token
            prompt="consent",            # forces refresh-token issuance even on re-auth
            include_granted_scopes="true",
            state=state,
        )
        verifier = flow.code_verifier
        if not verifier:
            # PKCE was disabled somehow — log loudly. The flow will still work
            # if Google doesn't enforce PKCE, but if it does, the callback fails.
            logger.warning("GoogleOAuth: no code_verifier on flow after authorization_url")
        else:
            await self._store_verifier(returned_state, verifier)
            logger.info(
                "GoogleOAuth: auth started (state=%s, verifier stored in %s)",
                _short(returned_state),
                "redis" if self._redis is not None else "memory",
            )
        return url

    async def exchange_code(self, code: str, state: str | None) -> dict:
        """Exchange the authorization code for tokens, using the stored PKCE verifier.

        Raises:
            ValueError: state is missing or its verifier has expired / been consumed.
            Exception: token exchange itself failed (network, invalid grant, ...).
        """
        if not state:
            raise ValueError(
                "Missing state parameter in callback — restart at /api/v1/auth/google/login"
            )
        verifier = await self._pop_verifier(state)
        if verifier is None:
            raise ValueError(
                "OAuth verifier missing or expired (state=%s) — "
                "restart at /api/v1/auth/google/login" % _short(state)
            )
        logger.info(
            "GoogleOAuth: callback received (state=%s, verifier restored)",
            _short(state),
        )

        flow = self._build_flow()
        # CRITICAL: re-attach the original verifier so fetch_token sends it.
        # Without this, oauthlib auto-generates a NEW verifier that does not
        # match the code_challenge Google saw at the authorization step,
        # which produces "invalid_grant: Missing code verifier".
        flow.code_verifier = verifier
        try:
            flow.fetch_token(code=code)
        except Exception as exc:
            logger.error("GoogleOAuth: token exchange failed — %s", exc)
            raise

        creds = flow.credentials
        token_dict = _credentials_to_dict(creds)
        token_store.save(token_dict)
        logger.info(
            "GoogleOAuth: token exchange succeeded (scopes=%d, refresh_token=%s)",
            len(creds.scopes or []),
            "yes" if creds.refresh_token else "no",
        )
        return token_dict

    def load_credentials(self):
        """Return a refreshed google.oauth2.credentials.Credentials, or None."""
        from google.oauth2.credentials import Credentials  # noqa: PLC0415
        from google.auth.transport.requests import Request  # noqa: PLC0415

        token_dict = token_store.load()
        if not token_dict:
            return None
        try:
            creds = Credentials(**{
                k: token_dict.get(k)
                for k in ("token", "refresh_token", "token_uri", "client_id",
                          "client_secret", "scopes", "expiry")
                if token_dict.get(k) is not None
            })
        except Exception as exc:
            logger.error("GoogleOAuth: cannot reconstruct credentials — %s", exc)
            return None

        # Auto-refresh if expired and a refresh_token is present
        if creds.expired and creds.refresh_token:
            try:
                creds.refresh(Request())
                token_store.save(_credentials_to_dict(creds))
                logger.info("GoogleOAuth: refresh token rotated")
            except Exception as exc:
                logger.error("GoogleOAuth: refresh failed — %s", exc)
                return None
        return creds

    def disconnect(self) -> None:
        token_store.clear()

    # ── diagnostics ───────────────────────────────────────────────────────────

    def token_info(self) -> dict:
        """Return token metadata for /auth/google/status and diagnostics.

        Never raises; returns ``authorized=False`` on any failure. The access
        token itself is intentionally NOT returned.
        """
        token_dict = token_store.load()
        if not token_dict:
            return {"authorized": False}

        scopes = list(token_dict.get("scopes") or [])
        expiry_raw = token_dict.get("expiry")
        expires_at = None
        expires_in = None
        if expiry_raw:
            try:
                from datetime import datetime, timezone  # noqa: PLC0415
                # google-auth stores expiry as a naive UTC iso string.
                dt = datetime.fromisoformat(expiry_raw.replace("Z", "+00:00"))
                if dt.tzinfo is None:
                    dt = dt.replace(tzinfo=timezone.utc)
                expires_at = dt
                expires_in = int((dt - datetime.now(tz=timezone.utc)).total_seconds())
            except Exception as exc:
                logger.debug("GoogleOAuth.token_info: cannot parse expiry — %s", exc)

        return {
            "authorized": True,
            "has_refresh_token": bool(token_dict.get("refresh_token")),
            "scopes": scopes,
            "scope_count": len(scopes),
            "expires_at": expires_at,
            "expires_in_seconds": expires_in,
            "needs_refresh": expires_in is not None and expires_in <= 60,
        }

    # ── internal ──────────────────────────────────────────────────────────────

    def _build_flow(self):
        from google_auth_oauthlib.flow import Flow  # noqa: PLC0415
        client_config = {
            "web": {
                "client_id": settings.gmail_client_id,
                "client_secret": settings.gmail_client_secret,
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
                "redirect_uris": [settings.google_oauth_redirect_uri],
            }
        }
        flow = Flow.from_client_config(
            client_config,
            scopes=SCOPES,
            redirect_uri=settings.google_oauth_redirect_uri,
        )
        return flow

    # ── PKCE verifier store ───────────────────────────────────────────────────

    async def _store_verifier(self, state: str, verifier: str) -> None:
        """Persist verifier under `state` with TTL. Redis first, memory fallback."""
        if self._redis is not None:
            try:
                await self._redis.setex(
                    _PKCE_PREFIX + state, _PKCE_TTL_SECONDS, verifier,
                )
                return
            except Exception as exc:
                logger.warning(
                    "GoogleOAuth: Redis setex failed (%s) — storing verifier in memory", exc,
                )
        async with self._mem_lock:
            self._evict_expired()
            self._mem_store[state] = (verifier, time.time() + _PKCE_TTL_SECONDS)

    async def _pop_verifier(self, state: str) -> str | None:
        """Retrieve and delete the verifier for a given state. Returns None if absent."""
        if self._redis is not None:
            try:
                key = _PKCE_PREFIX + state
                verifier = await self._redis.get(key)
                if verifier:
                    # Single-use: remove immediately to prevent replay.
                    await self._redis.delete(key)
                    return verifier
                # Not in Redis — fall through to memory in case Redis came online
                # between login and callback.
            except Exception as exc:
                logger.warning(
                    "GoogleOAuth: Redis get failed (%s) — checking memory fallback", exc,
                )
        async with self._mem_lock:
            self._evict_expired()
            entry = self._mem_store.pop(state, None)
            return entry[0] if entry is not None else None

    def _evict_expired(self) -> None:
        """Drop expired entries from the in-memory store. Called under _mem_lock."""
        now = time.time()
        expired = [s for s, (_, exp) in self._mem_store.items() if exp < now]
        for s in expired:
            self._mem_store.pop(s, None)


def _short(state: str) -> str:
    """Truncate a state value for logging — never log the full secret."""
    if not state:
        return "<empty>"
    return state[:8] + "…" if len(state) > 8 else state


def _credentials_to_dict(creds) -> dict:
    """Serialize Credentials to a JSON-safe dict for the token store."""
    return {
        "token": creds.token,
        "refresh_token": creds.refresh_token,
        "token_uri": creds.token_uri,
        "client_id": creds.client_id,
        "client_secret": creds.client_secret,
        "scopes": list(creds.scopes or []),
        "expiry": creds.expiry.isoformat() if creds.expiry else None,
    }


oauth_handler = GoogleOAuth()
