# Second Brain

FastAPI backend with RAG (ChromaDB), event streaming (Redis), and a proactive trigger/action engine.

## Prerequisites

- Docker Desktop (running)
- Python 3.12
- pip

---

## Quickstart — local dev (recommended)

### 1. Start infrastructure

```bash
# From the project root (second-brain/)
docker-compose up redis chromadb
```

Wait until both containers are healthy (≈10–30 seconds):

```
second-brain-redis     | Ready to accept connections
second-brain-chromadb  | Application startup complete
```

### 2. Install Python dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 3. Start the API

```bash
# Still inside backend/
python -m uvicorn main:app --reload
```

The API is now live at **http://localhost:8000**

---

## Verify everything is working

```bash
# Health check
curl http://localhost:8000/api/v1/health

# Readiness check
curl http://localhost:8000/api/v1/ready

# List triggers
curl http://localhost:8000/api/v1/triggers
```

Expected output from `/health`:
```json
{"status": "ok", "app": "Second Brain", "version": "0.1.0"}
```

Startup logs to look for:

```
INFO | app.workers.redis_consumer | RedisStreamConsumer: connected to redis://localhost:6379
INFO | app.services.rag.retriever | Retriever: connected to ChromaDB at localhost:8001 — collection 'second_brain'
INFO | app.workers.proactive_worker | ProactiveWorker: starting with 4 triggers, interval=60s
```

### Index the vault

```bash
curl -X POST http://localhost:8000/api/v1/index
```

### Query the vault

```bash
curl -X POST http://localhost:8000/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{"text": "meetings this week", "top_k": 5}'
```

---

## Interactive API docs

- Swagger UI: http://localhost:8000/docs
- ReDoc:       http://localhost:8000/redoc

---

## Full Docker deployment (all services in containers)

```bash
# From the project root
docker-compose up --build
```

All four services start: `backend`, `redis`, `chromadb`, `n8n` (workflow automation at :5678).

---

## Environment configuration

| File | Purpose |
|------|---------|
| `backend/.env` | Local development (localhost URLs) |
| `.env.example` | Template — copy to `backend/.env` to start |
| `docker-compose.yml` | Docker overrides (`redis`, `chromadb` service names) |

The key difference between local and Docker:

| Variable | Local dev | Inside Docker |
|----------|-----------|---------------|
| `REDIS_URL` | `redis://localhost:6379` | `redis://redis:6379` |
| `CHROMA_HOST` | `localhost` | `chromadb` |
| `CHROMA_PORT` | `8001` | `8000` |
| `VAULT_PATH` | `../vault` | `/vault` |

`docker-compose.yml` overrides these automatically when running in Docker.

---

## Project structure

```
second-brain/
├── backend/
│   ├── .env                # Local dev config (gitignored)
│   ├── main.py             # FastAPI entrypoint
│   ├── requirements.txt
│   └── app/
│       ├── api/v1/         # Endpoints: health, query, actions, triggers
│       ├── core/           # config.py, logging.py
│       ├── models/         # Pydantic models
│       ├── services/       # RAG, confirmation gate, actions, triggers
│       └── workers/        # Redis consumer, proactive worker
├── vault/                  # Obsidian-style markdown knowledge base
├── docker-compose.yml
└── .env.example
```

---

## Troubleshooting

**Redis connection fails**
- Confirm Docker is running: `docker ps | grep redis`
- Check it's healthy: `docker-compose ps`

**ChromaDB unavailable**
- ChromaDB takes ~20–30 seconds to start. Wait and retry.
- Check logs: `docker-compose logs chromadb`

**`app` module not found**
- Run uvicorn from inside `backend/`: `cd backend && python -m uvicorn main:app --reload`

**Port conflicts**
- Redis 6379 or ChromaDB 8001 already in use — stop the conflicting process or change the host port in `docker-compose.yml`.




NEW

# Second Brain AI

A modular AI-powered personal assistant platform built with FastAPI, React, Redis, and ChromaDB.

Second Brain AI combines:

* Personal knowledge management (Obsidian vault integration)
* Retrieval-Augmented Generation (RAG)
* External tools and APIs
* Redis workers and background automation
* Voice and action workflows
* Extensible AI agent architecture

---

# Features

## Current Features

### Backend (FastAPI)

* REST API architecture
* Async background workers
* Redis stream consumers
* ChromaDB vector database integration
* Obsidian vault indexing
* Modular AI service layer
* Graceful degradation and fallback handling
* Structured logging

### Frontend (Next.js + React)

* Ask interface
* Actions dashboard
* Obsidian vault viewer
* Voice module UI
* Live response source badges
* Modern responsive UI

### AI / Agent Features

* Vault-based RAG search
* Hybrid agent routing
* External tool support
* LLM fallback architecture
* Intent routing system

### Integrated Tools

* Crypto prices via CoinGecko API
* Weather lookup via wttr.in API

---

# Architecture

```text
                ┌────────────────────┐
                │    Frontend UI     │
                │  Next.js + React   │
                └─────────┬──────────┘
                          │
                          ▼
                ┌────────────────────┐
                │   FastAPI Backend  │
                └─────────┬──────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
         ▼                ▼                ▼
 ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
 │ IntentRouter │ │ Vault RAG    │ │ Tool Services│
 │              │ │ ChromaDB     │ │ Crypto/Weather
 └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
        │                │                │
        └────────────────┼────────────────┘
                         ▼
                ┌────────────────────┐
                │ Memory / LLM Layer │
                └────────────────────┘
```

---

# Tech Stack

## Backend

* Python 3.12+
* FastAPI
* Redis
* ChromaDB
* Uvicorn
* Pydantic
* HTTPX

## Frontend

* Next.js 14
* React
* TypeScript
* TailwindCSS

## Infrastructure

* Docker
* Docker Compose

---

# Project Structure

```text
second-brain/
│
├── backend/
│   ├── api/
│   ├── app/
│   │   ├── services/
│   │   │   ├── agent/
│   │   │   ├── rag/
│   │   │   ├── tools/
│   │   │   ├── integrations/
│   │   │   └── obsidian/
│   │   ├── workers/
│   │   └── models/
│   ├── main.py
│   └── requirements.txt
│
├── frontend/
│   ├── src/
│   ├── public/
│   ├── package.json
│   └── next.config.js
│
├── vault/
├── docker-compose.yml
└── README.md
```

---

# Installation

## Prerequisites

Install:

* Python 3.12+
* Node.js 20+
* Docker Desktop
* Git

---

# Clone Repository

```bash
git clone https://github.com/3bdoredaa2244/Secand_Brain_Ai_Bot.git
cd Secand_Brain_Ai_Bot
```

---

# Backend Setup

## Navigate to backend

```bash
cd backend
```

## Create virtual environment

### Windows

```bash
py -3.12 -m venv .venv
.venv\Scripts\activate
```

### Linux / macOS

```bash
python3 -m venv .venv
source .venv/bin/activate
```

## Install dependencies

```bash
pip install -r requirements.txt
```

---

# Start Infrastructure Services

From backend directory:

```bash
docker compose up redis chromadb -d
```

Verify running containers:

```bash
docker ps
```

Expected containers:

* second-brain-redis
* second-brain-chromadb

---

# Run Backend

```bash
python -m uvicorn main:app --reload --port 8000
```

Backend URL:

```text
http://localhost:8000
```

Health endpoint:

```text
http://localhost:8000/api/v1/health
```

Expected response:

```json
{
  "status": "ok",
  "app": "Second Brain",
  "version": "0.1.0"
}
```

---

# Frontend Setup

## Navigate to frontend

```bash
cd frontend
```

## Install dependencies

```bash
npm install
```

## Windows memory fix

Before starting frontend on Windows:

```bash
set NODE_OPTIONS=--max-old-space-size=4096
```

## Start frontend

```bash
npm run dev
```

Frontend URL:

```text
http://localhost:3000
```

---

# ChromaDB Health Check

Open:

```text
http://localhost:8001/api/v2/heartbeat
```

Expected:

```json
{
  "nanosecond heartbeat": 123456789
}
```

---

# Redis Test

```bash
docker exec -it second-brain-redis redis-cli
```

Then:

```text
PING
```

Expected:

```text
PONG
```

---

# Current Modules

## Ask

AI assistant interface.

Supports:

* Vault retrieval
* Crypto queries
* Weather queries
* LLM fallback

---

## Actions

Pending AI actions requiring approval.

Future capabilities:

* Email actions
* Calendar automation
* Task execution
* Workflow approvals

---

## Obsidian

Displays:

* Indexed notes
* Graph statistics
* Wikilinks
* Vault synchronization

---

## Voice

Voice recording and transcription interface.

Future:

* Whisper integration
* Voice command workflows
* Audio embeddings

---

# Agent Flow

```text
User Query
   ↓
Intent Router
   ↓
├── Crypto Tool
├── Weather Tool
├── Vault RAG
└── LLM Fallback
   ↓
Final Response
```

---

# API Endpoints

## Health

```http
GET /api/v1/health
```

---

## Query

```http
POST /api/v1/query
```

Example request:

```json
{
  "query": "what is btc price?"
}
```

---

# Test Cases

## Crypto Tool

Query:

```text
what is btc price?
```

Expected:

* Live BTC price
* Tool source badge
* No HTTP 500

---

## Weather Tool

Query:

```text
what is the weather in Cairo?
```

Expected:

* Weather response
* Tool source badge

---

## Vault RAG

Query:

```text
tell me about project-name
```

Expected:

* ChromaDB retrieval
* Vault source badge

---

# Graceful Degradation

The system is designed to continue operating even if services are unavailable.

| Service  | Fallback Behaviour           |
| -------- | ---------------------------- |
| ChromaDB | Returns empty results safely |
| Redis    | Uses in-memory fallback      |
| LLM      | Returns safe stub response   |
| APIs     | Returns graceful tool error  |

---

# Environment Variables

Example `.env`:

```env
LLM_PROVIDER=none
OPENAI_API_KEY=
CHROMA_HOST=localhost
CHROMA_PORT=8001
REDIS_URL=redis://localhost:6379
```

---

# Future Roadmap

## Phase 3

* OpenAI integration
* Tavily web search
* Real agent workflows
* Tool calling via LLM
* Streaming responses
* Persistent memory
* Multi-user support

## Phase 4

* Autonomous task execution
* Email/calendar integration
* Semantic scheduling
* Mobile app
* Cloud deployment

---

# Troubleshooting

## Frontend crashes with heap out of memory

Run:

```bash
set NODE_OPTIONS=--max-old-space-size=4096
npm run dev
```

---

## ChromaDB unhealthy

Ensure Docker containers are running:

```bash
docker compose up redis chromadb -d
```

---

## Backend returns connection errors

Verify:

```text
http://localhost:8001/api/v2/heartbeat
```

---

## Redis issues

Restart Redis:

```bash
docker restart second-brain-redis
```

---

# Development Notes

* Built using modular service architecture
* Tool system is extensible
* Backend designed for graceful degradation
* Optimized for local-first AI workflows
* Supports hybrid retrieval + tools + LLM design

---

# Contributors

* Abdulrahman Fahmy

---

# License

MIT License
