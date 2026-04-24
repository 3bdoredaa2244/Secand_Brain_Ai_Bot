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
