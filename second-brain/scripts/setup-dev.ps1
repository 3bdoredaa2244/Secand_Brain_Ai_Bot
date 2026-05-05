# setup-dev.ps1 — one-shot dev environment setup for Second Brain
# Run from the repo root:  .\scripts\setup-dev.ps1
# Requires: Python 3.10-3.12, Docker Desktop running
#
# What it does:
#   1. Creates a .venv inside backend/
#   2. Installs all Python dependencies
#   3. Starts Redis + ChromaDB via Docker (detached)
#   4. Copies .env.example to backend/.env if missing
#   5. Runs a quick smoke test

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path $PSScriptRoot -Parent
$BackendDir = Join-Path $RepoRoot "backend"

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    OK: $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "    WARN: $msg" -ForegroundColor Yellow }
function Abort($msg)      { Write-Host "`nFATAL: $msg" -ForegroundColor Red; exit 1 }

# ── 1. Python version check ──────────────────────────────────────────────────
Write-Step "Checking Python version"
$pyver = & python --version 2>&1
if ($pyver -match "Python 3\.(\d+)") {
    $minor = [int]$Matches[1]
    if ($minor -lt 10) { Abort "Python 3.10+ required, got $pyver" }
    if ($minor -ge 14) {
        Write-Warn "Python 3.14 is a preview release. 3.12 is recommended for production."
        Write-Warn "Install 3.12: winget install Python.Python.3.12"
        Write-Warn "Continuing anyway — wheels exist for 3.14 as of mid-2026."
    } else {
        Write-Ok $pyver
    }
} else {
    Abort "Could not determine Python version. Is python in PATH?"
}

# ── 2. Virtual environment ────────────────────────────────────────────────────
Write-Step "Setting up virtual environment"
$VenvDir = Join-Path $BackendDir ".venv"
if (-not (Test-Path $VenvDir)) {
    & python -m venv $VenvDir
    Write-Ok "Created .venv at $VenvDir"
} else {
    Write-Ok ".venv already exists"
}

$PipExe  = Join-Path $VenvDir "Scripts\pip.exe"
$PythonExe = Join-Path $VenvDir "Scripts\python.exe"

# ── 3. Install dependencies ───────────────────────────────────────────────────
Write-Step "Installing Python dependencies"
& $PipExe install --upgrade pip --quiet
& $PipExe install -r (Join-Path $BackendDir "requirements.txt") --quiet
if ($LASTEXITCODE -ne 0) { Abort "pip install failed" }
Write-Ok "All packages installed"

# ── 4. .env file ─────────────────────────────────────────────────────────────
Write-Step "Checking .env file"
$EnvFile    = Join-Path $BackendDir ".env"
$EnvExample = Join-Path $RepoRoot ".env.example"
if (-not (Test-Path $EnvFile)) {
    if (Test-Path $EnvExample) {
        Copy-Item $EnvExample $EnvFile
        Write-Ok "Copied .env.example → backend/.env  (edit it to add API keys)"
    } else {
        Write-Warn ".env.example not found. Create backend/.env manually."
    }
} else {
    Write-Ok "backend/.env already exists"
}

# ── 5. Docker services ────────────────────────────────────────────────────────
Write-Step "Starting Docker services (Redis + ChromaDB)"
$dockerInfo = & docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Warn "Docker is not running. Start Docker Desktop, then re-run this script."
    Write-Warn "Skipping service startup — backend will run in degraded mode without Redis/ChromaDB."
} else {
    Set-Location $RepoRoot
    & docker compose up redis chromadb -d --remove-orphans
    if ($LASTEXITCODE -ne 0) { Abort "docker compose up failed" }
    Write-Ok "Redis and ChromaDB started (use 'docker compose logs -f' to watch)"

    # Wait for healthy status
    Write-Host "    Waiting for services to become healthy..." -ForegroundColor Gray
    $timeout = 60
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        Start-Sleep 3
        $elapsed += 3
        $redisHealth  = & docker inspect --format="{{.State.Health.Status}}" second-brain-redis  2>$null
        $chromaHealth = & docker inspect --format="{{.State.Health.Status}}" second-brain-chromadb 2>$null
        if ($redisHealth -eq "healthy" -and $chromaHealth -eq "healthy") {
            Write-Ok "Redis: healthy | ChromaDB: healthy"
            break
        }
        Write-Host "    ...${elapsed}s (redis=${redisHealth}, chromadb=${chromaHealth})" -ForegroundColor Gray
    }
    if ($elapsed -ge $timeout) {
        Write-Warn "Services did not become healthy within ${timeout}s. Check: docker compose logs"
    }
}

# ── 6. Smoke test ─────────────────────────────────────────────────────────────
Write-Step "Running import smoke test"
$smokeResult = & $PythonExe -c "
import sys, importlib
mods = ['fastapi','pydantic','pydantic_settings','redis','chromadb','httpx','yaml','dotenv','watchdog','multipart','uvicorn']
failed = []
for m in mods:
    try: importlib.import_module(m)
    except ImportError as e: failed.append(f'{m}: {e}')
if failed:
    print('FAIL')
    for f in failed: print(f)
    sys.exit(1)
print('OK')
" 2>&1
if ($smokeResult -match "^OK") {
    Write-Ok "All imports pass"
} else {
    Write-Warn "Some imports failed:`n$smokeResult"
}

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Setup complete." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " To run the backend (dev):" -ForegroundColor White
Write-Host "   cd backend" -ForegroundColor Gray
Write-Host "   ..\.venv\Scripts\uvicorn main:app --reload --port 8000" -ForegroundColor Gray
Write-Host ""
Write-Host " To run via Docker (full stack):" -ForegroundColor White
Write-Host "   docker compose up --build" -ForegroundColor Gray
Write-Host ""
Write-Host " Health check:" -ForegroundColor White
Write-Host "   curl http://localhost:8000/api/v1/health" -ForegroundColor Gray
Write-Host ""
