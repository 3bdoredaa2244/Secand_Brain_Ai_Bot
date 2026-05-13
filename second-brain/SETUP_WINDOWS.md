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

Both integrations share a single OAuth client.

1. Create a project at https://console.cloud.google.com/
2. Enable **Gmail API** and **Google Calendar API**
3. Create OAuth Client ID → **Web application**
4. Add redirect URI: `http://localhost:8000/api/v1/auth/google/callback`
5. Paste the client id and secret into `backend/.env`:
   ```env
   GMAIL_CLIENT_ID=...
   GMAIL_CLIENT_SECRET=...
   ```
6. Restart the backend.
7. In the browser, visit
   `http://localhost:8000/api/v1/auth/google/login`. Consent on Google's
   screen — the popup closes itself when done.
8. Confirm: `GET /api/v1/auth/google/status` should return
   `{"authorized": true, "email": "you@gmail.com"}`.

Tokens are stored encrypted under `backend/data/tokens/`. To revoke:

```powershell
curl -X POST http://localhost:8000/api/v1/auth/google/disconnect
```

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
