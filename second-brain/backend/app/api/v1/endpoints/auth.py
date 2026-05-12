"""
Google OAuth endpoints — shared by Gmail + Calendar.

  GET  /auth/google/login       — 302 to Google consent (use in popup)
  GET  /auth/google/callback    — Google redirects here with ?code=…
  GET  /auth/google/status      — frontend polls this to detect completion
  POST /auth/google/disconnect  — wipe local tokens
"""
from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import HTMLResponse, RedirectResponse

from app.core.logging import get_logger
from app.models.email import GmailAuthStatus
from app.services.integrations.gmail.client import gmail_client
from app.services.integrations.gmail.oauth import oauth_handler
from app.services.integrations.gmail.token_store import token_store

logger = get_logger(__name__)
router = APIRouter(prefix="/auth/google", tags=["auth"])


_CLOSE_POPUP_HTML = """\
<!doctype html>
<html><head><title>Connected</title>
<style>
  body { font-family: -apple-system, system-ui, sans-serif; background: #0b0b10;
         color: #d0d0e8; display: flex; align-items: center; justify-content: center;
         height: 100vh; margin: 0; }
  .card { background: #111118; border: 1px solid #25253a; border-radius: 10px;
          padding: 32px 40px; text-align: center; }
  h1 { margin: 0 0 8px; font-size: 18px; color: #6ee7b7; }
  p  { margin: 0; color: #9090b0; font-size: 13px; }
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
  body { font-family: system-ui; background: #0b0b10; color: #f87171;
         display: flex; align-items: center; justify-content: center; height: 100vh; }
  pre { background: #17171f; padding: 12px 16px; border-radius: 6px;
        color: #d0d0e8; font-size: 13px; max-width: 480px; overflow: auto; }
</style></head><body>
<div><h1>Authorization failed</h1><pre>{detail}</pre></div>
</body></html>
"""


@router.get("/login")
async def login(state: str = ""):
    """Begin the OAuth dance. Frontend should open this in a popup window."""
    if not oauth_handler.is_configured():
        raise HTTPException(
            status_code=503,
            detail="Google OAuth is not configured. Set GMAIL_CLIENT_ID and "
                   "GMAIL_CLIENT_SECRET in backend/.env, then restart.",
        )
    try:
        url = oauth_handler.build_auth_url(state=state)
    except Exception as exc:
        logger.error("auth/google/login: %s", exc)
        raise HTTPException(status_code=500, detail=str(exc))
    return RedirectResponse(url=url, status_code=302)


@router.get("/callback", response_class=HTMLResponse)
async def callback(code: str | None = Query(default=None), error: str | None = Query(default=None)):
    """Google redirects here. Exchange the code, save tokens, close the popup."""
    if error:
        logger.warning("auth/google/callback: Google returned error '%s'", error)
        return HTMLResponse(content=_ERROR_HTML.format(detail=error), status_code=400)
    if not code:
        return HTMLResponse(content=_ERROR_HTML.format(detail="No authorization code"), status_code=400)
    try:
        oauth_handler.exchange_code(code)
    except Exception as exc:
        logger.error("auth/google/callback: token exchange failed — %s", exc)
        return HTMLResponse(content=_ERROR_HTML.format(detail=str(exc)), status_code=500)
    return HTMLResponse(content=_CLOSE_POPUP_HTML)


@router.get("/status", response_model=GmailAuthStatus)
async def status() -> GmailAuthStatus:
    """Tell the frontend whether OAuth is complete."""
    if not token_store.has_tokens():
        return GmailAuthStatus(authorized=False)

    profile = await gmail_client.get_profile()
    email = profile.get("emailAddress") if profile else None
    return GmailAuthStatus(
        authorized=profile is not None,
        email=email,
        scopes=[],  # populated once we parse from creds
    )


@router.post("/disconnect")
async def disconnect() -> dict:
    """Wipe stored Google tokens. User must re-authorize to use Gmail/Calendar."""
    oauth_handler.disconnect()
    return {"disconnected": True}
