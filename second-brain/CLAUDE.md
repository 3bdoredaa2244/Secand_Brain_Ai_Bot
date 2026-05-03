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
- Phase 2: Redis-backed with TTL (`gate:pending:<id>`, `gate:result:<id>`)
- Falls back to in-memory if Redis is unavailable
- `gate.connect()` called at startup in `main.py`

## Trigger Registry
| Trigger | Type | Domain | File |
|---------|------|--------|------|
| `price_alert` | realtime | shopping | `triggers/realtime.py` |
| `email_keyword` | realtime | communication | `triggers/realtime.py` |
| `daily_briefing` | scheduled | general | `triggers/scheduled.py` |
| `bill_due_reminder` | scheduled | finance | `triggers/scheduled.py` |
| `daily_health_check` | scheduled | health | `triggers/scheduled.py` |
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
│       │       ├── triggers.py        ← list / evaluate
│       │       ├── obsidian.py        ← sync / status / graph ✨ Phase 2
│       │       └── voice.py           ← POST /voice/input ✨ Phase 2
│       ├── models/
│       │   ├── action.py              ← ActionType, ActionStatus, ActionPlan, ActionRequest
│       │   ├── query.py               ← QueryRequest, QueryResponse, DocumentChunk
│       │   ├── trigger.py             ← TriggerType, TriggerDomain, TriggerEvent
│       │   └── health.py              ← VitaminLog, DailyRoutine, DailyHealthSummary
│       ├── services/
│       │   ├── rag/
│       │   │   ├── engine.py          ← RAGEngine → MemoryEngine (LLM synthesis) ✨ Phase 2
│       │   │   ├── memory.py          ← MemoryEngine (retrieve→reason→respond) ✨ Phase 2
│       │   │   ├── indexer.py         ← VaultIndexer (scan, chunk, parse frontmatter)
│       │   │   └── retriever.py       ← VaultRetriever (ChromaDB, where filter) ✨ Phase 2
│       │   ├── obsidian/
│       │   │   ├── parser.py          ← ObsidianNote parser (wikilinks, frontmatter)
│       │   │   ├── loader.py          ← ObsidianLoader → RawChunk
│       │   │   ├── sync.py            ← ObsidianSync (full + incremental)
│       │   │   ├── watcher.py         ← VaultWatcher (filesystem events)
│       │   │   └── graph.py           ← VaultGraph (wikilink relationships)
│       │   ├── confirmation_gate/
│       │   │   └── gate.py            ← ConfirmationGate Redis-backed + in-memory fallback ✨ Phase 2
│       │   ├── integrations/                                              ✨ Phase 2
│       │   │   ├── base.py            ← BaseIntegration ABC
│       │   │   ├── email.py           ← EmailService (mock + Gmail stub)
│       │   │   └── calendar.py        ← CalendarService (mock + GCal stub)
│       │   ├── triggers/
│       │   │   ├── base.py            ← BaseTrigger ABC
│       │   │   ├── realtime.py        ← PriceAlertTrigger, EmailKeywordTrigger
│       │   │   ├── scheduled.py       ← DailyBriefing, BillDue, DailyHealthCheck ✨ Phase 2
│       │   │   └── semantic.py        ← TravelIntentTrigger, PurchaseIntentTrigger
│       │   └── actions/
│       │       ├── base.py            ← BaseAction ABC (prepare, execute, run)
│       │       ├── send_email.py
│       │       ├── book_flight.py
│       │       ├── buy_product.py
│       │       └── schedule_meeting.py
│       └── workers/
│           ├── redis_consumer.py      ← RedisStreamConsumer (dispatch wired) ✨ Phase 2
│           └── proactive_worker.py    ← ProactiveWorker (60s scan cycle)
├── frontend/                                                              ✨ Phase 2
│   ├── package.json                   ← Next.js 14 app
│   ├── next.config.js                 ← proxy /api/* → localhost:8000
│   └── src/app/
│       ├── layout.tsx                 ← shared nav + inline styles
│       ├── page.tsx                   ← Chat / Ask page
│       ├── actions/page.tsx           ← Pending actions (approve/reject)
│       └── obsidian/page.tsx          ← Vault status + graph stats + sync button
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
POST /api/v1/query                          ← RAG query (+ LLM answer if configured)
POST /api/v1/index                          ← reindex vault (background)
POST /api/v1/actions/prepare/{action_type}  ← create pending action
GET  /api/v1/actions/pending                ← list awaiting confirmation
POST /api/v1/actions/confirm                ← approve or reject
GET  /api/v1/actions/result/{action_id}
GET  /api/v1/triggers                       ← list all trigger definitions
POST /api/v1/triggers/evaluate/{name}       ← test a trigger with payload
POST /api/v1/obsidian/sync                  ← full vault re-index (background)
POST /api/v1/obsidian/sync/file?path=…     ← re-index one file (blocking)
GET  /api/v1/obsidian/status               ← vault stats
GET  /api/v1/obsidian/graph                ← wikilink graph summary ✨ Phase 2
GET  /api/v1/obsidian/graph/node?source=…  ← links + backlinks for a note ✨ Phase 2
POST /api/v1/voice/input                   ← transcribe audio → query ✨ Phase 2
```

---

## Build State Tracker

### Phase 1 — Foundation ✅ COMPLETE (2026-04-22)
- [x] Monorepo directory structure
- [x] FastAPI backend skeleton (main.py, lifespan, CORS)
- [x] Core config (pydantic-settings), logging
- [x] Pydantic models: action, query, trigger
- [x] RAG skeleton: VaultIndexer (parse + chunk), VaultRetriever (ChromaDB stub), RAGEngine
- [x] Confirmation gate: ConfirmationGate (in-memory)
- [x] Action stubs: send_email, book_flight, buy_product, schedule_meeting
- [x] Trigger stubs: 6 triggers across realtime/scheduled/semantic
- [x] Workers: RedisStreamConsumer, ProactiveWorker
- [x] API endpoints: health, query, actions, triggers
- [x] Docker: docker-compose (backend + redis + chromadb + n8n)
- [x] Obsidian vault: 8 folders + 3 templates
- [x] .env.example

### Phase 2 — Intelligence ✅ COMPLETE (2026-05-03)
- [x] VaultRetriever.search() — metadata `where` filter support
- [x] RAGEngine wired to MemoryEngine (retrieve → reason → respond)
- [x] LLM synthesis: Anthropic + OpenAI (set LLM_PROVIDER in .env)
- [x] Confirmation gate: Redis-backed with TTL + in-memory fallback
- [x] Redis consumer dispatch: routes trigger + action stream events
- [x] Obsidian graph API: GET /obsidian/graph, GET /obsidian/graph/node
- [x] Voice endpoint: POST /voice/input (Whisper + stub fallback)
- [x] Health trigger: DailyHealthCheckTrigger (fires at health_check_hour)
- [x] Integration stubs: EmailService + CalendarService (mock mode, ready for real creds)
- [x] python-multipart added to requirements.txt
- [x] Frontend (Next.js 14): Ask / Actions / Obsidian pages

### Phase 3 — Productionisation (next)
- [ ] Wire real Gmail API in EmailService
- [ ] Wire real Google Calendar API in CalendarService
- [ ] n8n workflow definitions for trigger → action automation
- [ ] Migrate ProactiveWorker trigger events → Redis stream (pub/sub)
- [ ] Add authentication (JWT or API key) to FastAPI
- [ ] Docker Compose: add frontend service (Node 20)
- [ ] Vault health note auto-creation from DailyHealthCheckTrigger
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
