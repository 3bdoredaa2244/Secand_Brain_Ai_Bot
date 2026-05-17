"""
Google OAuth endpoints — shared by Gmail + Calendar.

  GET  /auth/google/login       — 302 to Google consent (use in popup)
  GET  /auth/google/callback    — Google redirects here with ?code=… &state=…
  GET  /auth/google/status      — frontend polls this to detect completion
  POST /auth/google/disconnect  — wipe local tokens

The callback handler runs `oauth_handler.exchange_code(code, state)`, which
looks up the PKCE verifier stored at /login time, then exchanges the code
for tokens. State must be passed through — without it we cannot recover
the verifier.
"""
import html as _html

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import HTMLResponse, RedirectResponse

from app.core.logging import get_logger
from app.models.email import GmailAuthStatus
from app.services.integrations.gmail.client import gmail_client
from app.services.integrations.gmail.oauth import oauth_handler
from app.services.integrations.gmail.token_store import token_store

logger = get_logger(__name__)
router = APIRouter(prefix="/auth/google", tags=["auth"])


# Both templates are rendered via str.format(), so every literal `{` and `}`
# in CSS must be doubled (`{{`, `}}`). A single `{` would otherwise be parsed
# as a format placeholder and raise KeyError(' font-family').
_CLOSE_POPUP_HTML = """\
<!doctype html>
<html><head><title>Connected</title>
<style>
  body {{ font-family: -apple-system, system-ui, sans-serif; background: #0b0b10;
         color: #d0d0e8; display: flex; align-items: center; justify-content: center;
         height: 100vh; margin: 0; }}
  .card {{ background: #111118; border: 1px solid #25253a; border-radius: 10px;
          padding: 32px 40px; text-align: center; }}
  h1 {{ margin: 0 0 8px; font-size: 18px; color: #6ee7b7; }}
  p  {{ margin: 0; color: #9090b0; font-size: 13px; }}
</style></head><body>
<div class="card">
  <h1>✓ Connected</h1>
  <p>You can close this window.</p>
</div>
<script>setTimeout(() => window.close(), 1500);</script>
</body></html>
"""

_ERROR_HTML = """\
<!doctype html>
<html><head><title>Auth failed</title>
<style>
  body {{ font-family: system-ui; background: #0b0b10; color: #f87171;
         display: flex; align-items: center; justify-content: center; height: 100vh; }}
  .wrap {{ max-width: 520px; padding: 24px; }}
  h1 {{ font-size: 18px; margin: 0 0 12px; }}
  pre {{ background: #17171f; padding: 12px 16px; border-radius: 6px;
        color: #d0d0e8; font-size: 13px; overflow: auto;
        white-space: pre-wrap; word-break: break-word; }}
  .hint {{ margin-top: 12px; color: #9090b0; font-size: 12px; }}
</style></head><body>
<div class="wrap">
  <h1>Authorization failed</h1>
  <pre>{detail}</pre>
  <div class="hint">Close this window and retry from the app.</div>
</div>
</body></html>
"""


def _error_page(detail: str, *, status: int) -> HTMLResponse:
    """Render the error template, HTML-escaping the detail. Never raises."""
    safe_detail = _html.escape(str(detail) or "Unknown error")
    try:
        body = _ERROR_HTML.format(detail=safe_detail)
    except Exception as exc:
        # Defence-in-depth: if the template breaks for any reason, still
        # return something the popup can render rather than 500-crashing.
        logger.error("auth/google: error template failed to render — %s", exc, exc_info=True)
        body = (
            "<!doctype html><html><body>"
            f"<h1>Authorization failed</h1><pre>{safe_detail}</pre>"
            "</body></html>"
        )
    return HTMLResponse(content=body, status_code=status)


@router.get("/login")
async def login(state: str = ""):
    """Begin the OAuth dance. Frontend should open this in a popup window.

    `build_auth_url` generates and persists a PKCE code_verifier keyed by the
    OAuth state. The browser will be 302'd to Google with the matching
    code_challenge in the query string.
    """
    if not oauth_handler.is_configured():
        raise HTTPException(
            status_code=503,
            detail="Google OAuth is not configured. Set GMAIL_CLIENT_ID and "
                   "GMAIL_CLIENT_SECRET in backend/.env, then restart.",
        )
    try:
        url = await oauth_handler.build_auth_url(state=state)
    except Exception as exc:
        logger.error("auth/google/login: %s", exc, exc_info=True)
        raise HTTPException(status_code=500, detail=str(exc))
    return RedirectResponse(url=url, status_code=302)


@router.get("/callback", response_class=HTMLResponse)
async def callback(
    code: str | None = Query(default=None),
    state: str | None = Query(default=None),
    error: str | None = Query(default=None),
):
    """Google redirects here. Exchange the code (with stored PKCE verifier),
    save tokens, render the self-closing popup HTML.

    This handler MUST NOT raise — every failure mode renders an HTML error
    page so the popup can show something meaningful and the user can retry.
    """
    if error:
        logger.warning("auth/google/callback: Google returned error '%s'", error)
        return _error_page(error, status=400)
    if not code:
        return _error_page(
            "No authorization code in callback URL. Restart the flow.",
            status=400,
        )
    if not state:
        return _error_page(
            "Missing state parameter in callback. Restart at /api/v1/auth/google/login.",
            status=400,
        )

    try:
        await oauth_handler.exchange_code(code, state)
    except ValueError as exc:
        # Missing / expired verifier or other user-actionable issue.
        logger.warning("auth/google/callback: %s", exc)
        return _error_page(str(exc), status=400)
    except Exception as exc:
        logger.error("auth/google/callback: token exchange failed", exc_info=True)
        return _error_page(str(exc), status=500)

    return HTMLResponse(content=_CLOSE_POPUP_HTML)


@router.get("/status", response_model=GmailAuthStatus)
async def status() -> GmailAuthStatus:
    """Tell the frontend whether OAuth is complete.

    Returns the connected account email, the granted scopes, and the access
    token's expiry. `authorized=true` requires that we can both load tokens
    AND make at least one successful Gmail profile call — that guards against
    the case where tokens are present but have been revoked at Google.
    """
    info = oauth_handler.token_info()
    if not info.get("authorized"):
        return GmailAuthStatus(authorized=False)

    profile = await gmail_client.get_profile()
    email = profile.get("emailAddress") if profile else None
    return GmailAuthStatus(
        authorized=profile is not None,
        email=email,
        expires_at=info.get("expires_at"),
        scopes=info.get("scopes", []),
    )


@router.post("/disconnect")
async def disconnect() -> dict:
    """Wipe stored Google tokens. User must re-authorize to use Gmail/Calendar."""
    oauth_handler.disconnect()
    return {"disconnected": True}
