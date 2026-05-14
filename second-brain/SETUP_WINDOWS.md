# Second Brain — Windows Setup

End-to-end installation for a fresh Windows 10/11 machine. Tested with
Python 3.12+, Docker Desktop, and Node.js 20. All commands assume
PowerShell.

> The backend runs natively on Windows. Redis + ChromaDB run in Docker
> because their native Windows builds are flaky.

---

## 0. Prerequisites

| Tool             | Version  | Source                                              |
|------------------|----------|-----------------------------------------------------|
| Python           | 3.12+    | https://www.python.org/downloads/windows/           |
| Node.js          | 20 LTS   | https://nodejs.org/                                 |
| Docker Desktop   | latest   | https://www.docker.com/products/docker-desktop      |
| Git              | latest   | https://git-scm.com/download/win                    |
| ffmpeg (optional) | latest  | `winget install Gyan.FFmpeg` — needed by Whisper    |

Reboot once after installing Docker Desktop. Make sure the engine is
running before continuing.

---

## 1. Clone & enter the repo

```powershell
git clone https://github.com/3bdoredaa2244/Secand_Brain_Ai_Bot E:\work\cloude
cd E:\work\cloude\second-brain
```

---

## 2. Start the infrastructure containers

Redis and ChromaDB are required. n8n is optional (only used for
automation workflows).

```powershell
docker-compose up redis chromadb -d
docker ps   # confirm both are healthy
```

Exposed ports:

| Service  | Host port | Container port |
|----------|-----------|----------------|
| Redis    | 6379      | 6379           |
| ChromaDB | 8001      | 8000           |

---

## 3. Set up the Python backend

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

### 3a. Configure `.env`

Copy the example and fill in any credentials you have:

```powershell
copy ..\.env.example .env
notepad .env
```

Bare minimum: `REDIS_URL`, `CHROMA_HOST`, `CHROMA_PORT`, `VAULT_PATH`.
The rest can be added later through the UI.

### 3b. Install voice dependencies (optional but recommended)

These are CPU-only and ~300 MB total once models are cached.

```powershell
pip install faster-whisper piper-tts huggingface_hub psutil
```

The first run will download:
- the Whisper model (`tiny.en` by default, ~75 MB)
- the Piper voice (`en_US-lessac-medium`, ~63 MB) to `backend/data/piper/`

You can trigger the Piper download manually:

```powershell
curl -X POST http://localhost:8000/api/v1/voice/setup
```

---

## 4. Set up the Obsidian vault

The default vault path is `..\vault` (relative to `backend/`). To use
`D:\SecondBrainVault` instead, either:

**Option A — via the API (recommended, persists across restarts):**

```powershell
curl -X POST http://localhost:8000/api/v1/obsidian/config `
     -H "Content-Type: application/json" `
     -d '{"vault_path": "D:\\SecondBrainVault", "create_structure": true}'
```

`create_structure: true` scaffolds `notes/`, `projects/`, `meetings/`,
`tasks/` if the directory is empty.

**Option B — edit `.env` and restart the backend:**

```env
VAULT_PATH=D:\SecondBrainVault
```

Either way, a full re-sync runs in the background; watch the logs for
`Background sync complete: N files, N chunks`.

---

## 5. Set up the frontend

```powershell
cd ..\frontend
npm install
npm run dev    # serves on http://localhost:3000
```

The Next.js dev server proxies `/api/*` → `http://localhost:8000`, so
opening `http://localhost:3000` is enough — no CORS dance.

---

## 6. Start the backend

In a separate PowerShell window:

```powershell
cd E:\work\cloude\second-brain\backend
.\.venv\Scripts\Activate.ps1
python -m uvicorn main:app --reload --port 8000
```

Expected first-run log lines:

```
Runtime tuning: {'OPENBLAS_NUM_THREADS': '1', ...}
ConfirmationGate: connected to Redis at redis://localhost:6379
ConversationMemory: connected to Redis
Retriever: connected to ChromaDB at localhost:8001 ...
Voice: STT (faster-whisper) and TTS (Piper) both available
VaultWatcher: watching ...
```

---

## 7. Verify everything

From the repo root:

```powershell
cd E:\work\cloude\second-brain
python verify_system.py
```

The script exits 0 on success. It checks:

- Python 3.12+
- Redis on `localhost:6379`
- ChromaDB on `localhost:8001`
- Backend on `localhost:8000`
- Frontend on `localhost:3000`
- Vault path resolves and exists
- Piper voice model present
- Google OAuth credentials in `.env`
- Required Python modules importable
- Thread-limit env vars (set lazily by the backend at import time)

You can also open the **Diagnostics** page in the UI
(`http://localhost:3000/diagnostics`) for a live view.

---

## 8. Connect Google (Gmail + Calendar)

Both integrations share a single OAuth client. One consent screen unlocks
both APIs.

### 8.1 Google Cloud Console setup

1. Open https://console.cloud.google.com/ and **create a project**
   (top-left project picker → New Project). Any name is fine.
2. Navigate to **APIs & Services → Library** and enable:
   - **Gmail API**
   - **Google Calendar API**
3. Go to **APIs & Services → OAuth consent screen**:
   - User type: **External** (unless you have a Workspace org)
   - App name: anything (e.g. "Second Brain")
   - User support email + developer email: your Gmail address
   - **Scopes**: you don't need to pre-declare them here for the
     development consent screen — Google asks for them dynamically
     based on what the backend requests. The backend asks for:
     ```
     gmail.readonly
     gmail.send
     gmail.modify
     gmail.compose
     calendar
     calendar.events
     openid email profile
     ```
   - **Test users**: add your own Gmail address. While the app is in
     **Testing** mode (the default), only listed test users can
     complete the consent flow.
4. Go to **APIs & Services → Credentials → Create credentials → OAuth
   client ID**:
   - Application type: **Web application**
   - Authorized redirect URIs — add exactly:
     `http://localhost:8000/api/v1/auth/google/callback`
5. Copy the generated **Client ID** and **Client secret**.

### 8.2 Wire into the backend

Add these to `backend/.env`:

```env
GMAIL_CLIENT_ID=<paste here>
GMAIL_CLIENT_SECRET=<paste here>
GOOGLE_REDIRECT_URI=http://localhost:8000/api/v1/auth/google/callback
```

> The historical name `GOOGLE_OAUTH_REDIRECT_URI` is also accepted.

Restart the backend. You should see in the logs:

```
Google OAuth: credentials configured, no tokens yet.
Visit http://localhost:8000/api/v1/auth/google/login to authorize.
```

### 8.3 Run the consent flow

1. Open `http://localhost:8000/api/v1/auth/google/login` in a browser.
2. Pick the Gmail account you added as a test user.
3. Approve each scope (Gmail + Calendar). Because the backend sends
   `prompt=consent` + `access_type=offline`, Google will issue a
   long-lived refresh token even on re-auth.
4. The callback page says "Connected" and closes itself after ~1.5s.

### 8.4 Verify

```powershell
curl http://localhost:8000/api/v1/auth/google/status
```

Expected JSON shape:

```json
{
  "authorized": true,
  "email": "you@gmail.com",
  "expires_at": "2026-05-14T18:47:00+00:00",
  "scopes": [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/gmail.modify",
    "https://www.googleapis.com/auth/gmail.compose",
    "https://www.googleapis.com/auth/calendar",
    "https://www.googleapis.com/auth/calendar.events",
    "openid", "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/userinfo.profile"
  ]
}
```

Tokens are saved encrypted at `backend/data/tokens/google.bin`
(Fernet, keyed off `SECRET_KEY`).

### 8.5 Functional smoke tests

```powershell
# Gmail reads
curl http://localhost:8000/api/v1/gmail/recent
curl http://localhost:8000/api/v1/gmail/unread
curl "http://localhost:8000/api/v1/gmail/search?q=test"
curl http://localhost:8000/api/v1/gmail/briefing

# Gmail write (gated — returns action_id, must be confirmed)
curl -X POST http://localhost:8000/api/v1/gmail/draft `
     -H "Content-Type: application/json" `
     -d '{"to":"you@gmail.com","subject":"Test from Second Brain","body":"Hello"}'

# Calendar reads
curl http://localhost:8000/api/v1/calendar/today
curl "http://localhost:8000/api/v1/calendar/upcoming?days=7"
curl http://localhost:8000/api/v1/calendar/agenda
curl "http://localhost:8000/api/v1/calendar/free-busy?days=3"

# Calendar write (gated)
curl -X POST http://localhost:8000/api/v1/calendar/events `
     -H "Content-Type: application/json" `
     -d '{"summary":"Test","start":"2026-05-14T15:00:00","end":"2026-05-14T15:30:00","attendees":[]}'

# Approve a pending write (run after a gated request)
curl http://localhost:8000/api/v1/actions/pending
curl -X POST http://localhost:8000/api/v1/actions/confirm `
     -H "Content-Type: application/json" `
     -d '{"action_id":"<paste id>","approved":true}'
```

### 8.6 Common OAuth errors

| Symptom                                                  | Fix                                                                                                                             |
|----------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| `redirect_uri_mismatch` after consent                    | Redirect URI in Google Console must match `GOOGLE_REDIRECT_URI` **exactly** (scheme, host, port, path, trailing slash).         |
| `access_blocked: This app's request is invalid`          | Add your Gmail address as a **test user** in the OAuth consent screen, or move the app to Production.                           |
| `invalid_scope` on next refresh                           | Scope list changed since tokens were issued — re-auth: `POST /api/v1/auth/google/disconnect` then visit `/auth/google/login`.   |
| `/auth/google/status` returns `authorized: false`        | Tokens may be revoked, expired without refresh, or decryption failed after a SECRET_KEY change. Reconnect via /login.           |
| `TokenStore: cannot decrypt — SECRET_KEY changed`        | Either restore the old SECRET_KEY or run `POST /api/v1/auth/google/disconnect` and re-authorize.                                |
| 503 `Gmail not authorized` from `/gmail/{id}` endpoints  | No tokens. Run the consent flow.                                                                                                |
| `quota exceeded` from Google API                         | Per-user Gmail API limit is generous but bursty reads will throttle. Reduce `max_results` or back off.                          |

### 8.7 Resetting tokens

```powershell
curl -X POST http://localhost:8000/api/v1/auth/google/disconnect
```

This deletes `backend/data/tokens/google.bin`. The next `/auth/google/login`
will require a fresh consent.

### 8.8 Natural-language scheduling

The Calendar service accepts free-text dates in chat-style requests.
The parser at `services/integrations/calendar/nlp.py` understands:

- `tomorrow`, `today`, `tonight`
- `Friday`, `next Monday`, `Mon`/`Tue`/...
- `in 30 minutes`, `in 2 hours`, `in 3 days`
- `at 3pm`, `at 14:30`, `Friday at 3pm`

These resolve to a (start, end) pair in local tz. The actual event
creation still passes through the confirmation gate — saying "schedule
a meeting tomorrow at 3pm" produces a pending action that must be
approved before the event is written to your calendar.

---

## 9. Configure an LLM (optional)

Without an LLM the system still works — it returns raw vault chunks. To
get synthesised answers, set in `.env`:

```env
LLM_PROVIDER=anthropic
ANTHROPIC_API_KEY=sk-ant-...
```

or

```env
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-...
```

Install the corresponding SDK:

```powershell
pip install anthropic    # or: pip install openai
```

---

## Troubleshooting

### `OpenBLAS : Program is Terminating Due to lack of memory`

The backend pins every BLAS/OMP backend to 1 thread via
`app/core/runtime_tuning.py`, imported as the very first line of
`main.py`. If the crash still happens:

- Confirm `main.py` line 1 reads `from app.core import runtime_tuning`.
- Confirm `os.environ["OPENBLAS_NUM_THREADS"] == "1"` via the
  Diagnostics page or `GET /api/v1/voice/status`.
- Avoid running `python -c "import numpy"` before the backend — that
  loads BLAS without the limits.

### Whisper takes 20s on first transcription

That's the model download + load. Subsequent transcriptions are ~200 ms
on `tiny.en` for a short utterance. Switch to `base.en` in `.env` for
quality, `small.en` if you have spare RAM.

### Piper says "voice file missing"

Either run `POST /api/v1/voice/setup` once, or download manually:

```powershell
$dst = "backend\data\piper"
mkdir $dst -ErrorAction SilentlyContinue
curl -L `
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx" `
  -o "$dst\en_US-lessac-medium.onnx"
curl -L `
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json" `
  -o "$dst\en_US-lessac-medium.onnx.json"
```

### ChromaDB connection refused

`docker-compose ps` — confirm the container is `Up`. The host port is
**8001** (not 8000) because 8000 is reserved for the backend.

### Vault file changes not picked up

Watchdog needs the vault to exist when the backend starts. If you
re-point the vault via `/obsidian/config`, restart the backend so the
watcher binds to the new directory.

### Frontend can't reach the backend

`next.config.js` proxies `/api/*` to `localhost:8000`. If the backend is
on a different host, edit the proxy target there. Don't open the API
host directly — Next.js relative paths assume it lives behind the same
origin as the frontend.

### "Cannot import 'piper'" but it's installed

Piper renamed its package between 1.2 and 1.4. The code is written
against the 1.4.x API (`PiperVoice.load(...)`). If you have an older
version, upgrade:

```powershell
pip install --upgrade "piper-tts>=1.4"
```

---

## Stopping cleanly

```powershell
# In the backend window
Ctrl+C

# In the frontend window
Ctrl+C

# Containers (optional — leave running for next session)
docker-compose down
```

Conversation memory expires automatically after 6 hours. Confirmation
gate entries expire after `GATE_TIMEOUT_SECONDS` (default 300s).
