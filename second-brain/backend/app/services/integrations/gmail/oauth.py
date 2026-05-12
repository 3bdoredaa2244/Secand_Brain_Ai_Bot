"""
Google OAuth 2.0 flow for Gmail + Calendar.

Both integrations share a single OAuth client (one consent screen, one refresh
token). The user clicks "Connect Google" once and both Gmail + Calendar work.

Flow
────
1. Frontend opens /api/v1/auth/google/login in a popup
2. We build an authorisation URL and 302-redirect to Google
3. Google redirects back to /api/v1/auth/google/callback?code=...
4. We exchange the code for an access + refresh token, encrypt + store
5. Backend serves a self-closing HTML page; frontend polls /status

The same credentials are used for Calendar (Phase 3 Part 2).
"""
from __future__ import annotations

from app.core.config import get_settings
from app.core.logging import get_logger
from app.services.integrations.gmail.token_store import token_store

logger = get_logger(__name__)
settings = get_settings()

# Scopes — gmail.modify covers archive/label; gmail.send covers sending.
# Calendar scopes added here too so a single consent grants both integrations.
SCOPES: list[str] = [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/gmail.modify",
    "https://www.googleapis.com/auth/calendar",
    "openid", "email", "profile",
]


class GoogleOAuth:
    """Handles authorisation URL construction + code exchange."""

    def is_configured(self) -> bool:
        return bool(settings.gmail_client_id and settings.gmail_client_secret)

    def build_auth_url(self, state: str = "") -> str:
        """Return the consent-screen URL for the frontend popup."""
        if not self.is_configured():
            raise RuntimeError(
                "Google OAuth not configured — set GMAIL_CLIENT_ID and "
                "GMAIL_CLIENT_SECRET in .env"
            )
        flow = self._build_flow()
        url, _ = flow.authorization_url(
            access_type="offline",       # required to receive a refresh token
            prompt="consent",            # forces refresh-token issuance even on re-auth
            include_granted_scopes="true",
            state=state,
        )
        return url

    def exchange_code(self, code: str) -> dict:
        """Exchange an auth code for tokens and persist them. Returns token dict."""
        flow = self._build_flow()
        flow.fetch_token(code=code)
        creds = flow.credentials
        token_dict = _credentials_to_dict(creds)
        token_store.save(token_dict)
        logger.info("GoogleOAuth: exchanged code, tokens saved (scopes=%d)", len(creds.scopes or []))
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
