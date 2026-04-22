# Second Brain — Living Build Context

Read this at the start of every session. Update the Build State section when done.

## Core Rules
- NEVER execute real-world actions without confirmation
- All actions must pass through the confirmation gate
- All data must be stored in structured + markdown form
- Prefer local-first architecture
- Code must be modular and production-ready

---

## System Modes
1. **Reactive** — user asks a question → RAG engine answers
2. **Proactive** — system detects a trigger → proposes an action
3. **Action** — user confirms → system executes

## Action Registry
| Action | Handler | Status |
|--------|---------|--------|
| `send_email` | `services/actions/send_email.py` | Stub |
| `book_flight` | `services/actions/book_flight.py` | Stub |
| `buy_product` | `services/actions/buy_product.py` | Stub |
| `schedule_meeting` | `services/actions/schedule_meeting.py` | Stub |

Every action lifecycle: **prepare → gate.submit → await_confirmation → execute**

## Confirmation Gate
File: `backend/app/services/confirmation_gate/gate.py`
- Phase 1: in-memory dict (`_pending`, `_results`)
- Phase 2: migrate to Redis with TTL

## Trigger Registry
| Trigger | Type | Domain | File |
|---------|------|--------|------|
| `price_alert` | realtime | shopping | `triggers/realtime.py` |
| `email_keyword` | realtime | communication | `triggers/realtime.py` |
| `daily_briefing` | scheduled | general | `triggers/scheduled.py` |
| `bill_due_reminder` | scheduled | finance | `triggers/scheduled.py` |
| `travel_intent` | semantic | travel | `triggers/semantic.py` |
| `purchase_intent` | semantic | shopping | `triggers/semantic.py` |

---

## Monorepo Structure
```
second-brain/
├── CLAUDE.md                          ← this file
├── docker-compose.yml
├── .env.example
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── main.py                        ← FastAPI entrypoint + lifespan
│   └── app/
│       ├── core/
│       │   ├── config.py              ← pydantic-settings (Settings)
│       │   └── logging.py
│       ├── api/v1/
│       │   ├── router.py              ← aggregates all endpoints
│       │   └── endpoints/
│       │       ├── health.py          ← GET /health, GET /ready
│       │       ├── query.py           ← POST /query, POST /index
│       │       ├── actions.py         ← prepare / pending / confirm / result
│       │       └── triggers.py        ← list / evaluate
│       ├── models/
│       │   ├── action.py              ← ActionType, ActionStatus, ActionPlan, ActionRequest
│       │   ├── query.py               ← QueryRequest, QueryResponse, DocumentChunk
│       │   └── trigger.py             ← TriggerType, TriggerDomain, TriggerEvent
│       ├── services/
│       │   ├── rag/
│       │   │   ├── engine.py          ← RAGEngine (index_vault, query)
│       │   │   ├── indexer.py         ← VaultIndexer (scan, chunk, parse frontmatter)
│       │   │   └── retriever.py       ← VaultRetriever (ChromaDB client, search)
│       │   ├── confirmation_gate/
│       │   │   └── gate.py            ← ConfirmationGate (submit, confirm, list_pending)
│       │   ├── triggers/
│       │   │   ├── base.py            ← BaseTrigger ABC
│       │   │   ├── realtime.py        ← PriceAlertTrigger, EmailKeywordTrigger
│       │   │   ├── scheduled.py       ← DailyBriefingTrigger, BillDueReminderTrigger
│       │   │   └── semantic.py        ← TravelIntentTrigger, PurchaseIntentTrigger
│       │   └── actions/
│       │       ├── base.py            ← BaseAction ABC (prepare, execute, run)
│       │       ├── send_email.py
│       │       ├── book_flight.py
│       │       ├── buy_product.py
│       │       └── schedule_meeting.py
│       └── workers/
│           ├── redis_consumer.py      ← RedisStreamConsumer (streams: actions, triggers)
│           └── proactive_worker.py    ← ProactiveWorker (60s scan cycle)
├── vault/
│   ├── 00-inbox/
│   ├── 01-daily/
│   ├── 02-people/
│   ├── 03-meetings/
│   ├── 04-projects/
│   ├── 05-knowledge/
│   ├── 06-actions/
│   ├── 07-archive/
│   └── templates/
│       ├── daily-note.md
│       ├── person.md
│       └── meeting.md
└── n8n/
    └── workflows/
```

---

## Docker Services
| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| `backend` | custom Python 3.12 | 8000 | FastAPI API |
| `redis` | redis:7-alpine | 6379 | Event streams |
| `chromadb` | chromadb/chroma | 8001 | Vector store |
| `n8n` | n8nio/n8n | 5678 | Workflow automation |

---

## Environment Variables
All vars in `.env.example`. Copy to `.env` before running.
Key Phase 1 vars: `REDIS_URL`, `CHROMA_HOST`, `CHROMA_PORT`, `VAULT_PATH`, `SECRET_KEY`

---

## API Endpoints (v1)
```
GET  /api/v1/health
GET  /api/v1/ready
POST /api/v1/query                          ← RAG query
POST /api/v1/index                          ← reindex vault (background)
POST /api/v1/actions/prepare/{action_type}  ← create pending action
GET  /api/v1/actions/pending                ← list awaiting confirmation
POST /api/v1/actions/confirm                ← approve or reject
GET  /api/v1/actions/result/{action_id}
GET  /api/v1/triggers                       ← list all trigger definitions
POST /api/v1/triggers/evaluate/{name}       ← test a trigger with payload
```

---

## Build State Tracker

### Phase 1 — Foundation ✅ COMPLETE (2026-04-22)
- [x] Monorepo directory structure
- [x] FastAPI backend skeleton (main.py, lifespan, CORS)
- [x] Core config (pydantic-settings), logging
- [x] Pydantic models: action, query, trigger
- [x] RAG skeleton: VaultIndexer (parse + chunk), VaultRetriever (ChromaDB stub), RAGEngine
- [x] Confirmation gate: ConfirmationGate (in-memory, Phase 2 → Redis)
- [x] Action stubs: send_email, book_flight, buy_product, schedule_meeting
- [x] Trigger stubs: 6 triggers across realtime/scheduled/semantic
- [x] Workers: RedisStreamConsumer, ProactiveWorker
- [x] API endpoints: health, query, actions, triggers
- [x] Docker: docker-compose (backend + redis + chromadb + n8n)
- [x] Obsidian vault: 8 folders + 3 templates
- [x] .env.example

### Phase 2 — Intelligence (next)
- [ ] Connect LLM for RAG synthesis (Claude / OpenAI)
- [ ] Real embeddings via sentence-transformers
- [ ] Migrate confirmation gate to Redis with TTL
- [ ] Wire Redis streams to trigger evaluators
- [ ] Connect email API (Gmail)
- [ ] Connect calendar API (Google Calendar)
- [ ] Connect travel API (Amadeus)
- [ ] n8n workflow definitions

### Phase 3 — Frontend
- [ ] React / Next.js UI
- [ ] Vault viewer
- [ ] Confirmation gate UI (approve/reject cards)
- [ ] Proactive alert feed

---

## Coding Standards
- Python 3.12, FastAPI, Pydantic v2
- All models in `app/models/`
- All business logic in `app/services/`
- Workers are long-running asyncio tasks started in lifespan
- No external API calls in Phase 1 — all stubs log a warning
- Confirmation gate is the single chokepoint before any execution
