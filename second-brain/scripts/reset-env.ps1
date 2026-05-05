# reset-env.ps1 — nuclear option: wipe and rebuild the entire Python env
# Run from the repo root:  .\scripts\reset-env.ps1
# Use this when: pip install fails, venv is corrupted, wrong Python version

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot  = Split-Path $PSScriptRoot -Parent
$BackendDir = Join-Path $RepoRoot "backend"
$VenvDir    = Join-Path $BackendDir ".venv"

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    OK: $msg" -ForegroundColor Green }
function Abort($msg)      { Write-Host "`nFATAL: $msg" -ForegroundColor Red; exit 1 }

Write-Step "Removing old virtual environment"
if (Test-Path $VenvDir) {
    Remove-Item $VenvDir -Recurse -Force
    Write-Ok "Deleted $VenvDir"
} else {
    Write-Ok "No existing .venv found"
}

Write-Step "Clearing pip cache (avoids stale .whl files)"
& python -m pip cache purge 2>$null
Write-Ok "pip cache cleared"

Write-Step "Creating fresh virtual environment"
& python -m venv $VenvDir
if ($LASTEXITCODE -ne 0) { Abort "python -m venv failed — is Python in PATH?" }
Write-Ok "Created $VenvDir"

$PipExe    = Join-Path $VenvDir "Scripts\pip.exe"
$PythonExe = Join-Path $VenvDir "Scripts\python.exe"

Write-Step "Upgrading pip inside venv"
& $PythonExe -m pip install --upgrade pip --quiet
Write-Ok "pip upgraded"

Write-Step "Installing dependencies"
& $PipExe install -r (Join-Path $BackendDir "requirements.txt")
if ($LASTEXITCODE -ne 0) { Abort "pip install failed — see errors above" }
Write-Ok "All packages installed"

Write-Step "Verifying imports"
& $PythonExe -c "
import fastapi, pydantic, pydantic_settings, redis, chromadb, httpx, yaml, dotenv, watchdog, uvicorn
print('All imports OK')
print('fastapi:', fastapi.__version__)
print('pydantic:', pydantic.__version__)
print('chromadb:', chromadb.__version__)
print('redis:', redis.__version__)
"
if ($LASTEXITCODE -ne 0) { Abort "Import check failed" }

Write-Host "`nEnvironment reset complete." -ForegroundColor Cyan
Write-Host "Activate with:  $VenvDir\Scripts\Activate.ps1" -ForegroundColor Gray
