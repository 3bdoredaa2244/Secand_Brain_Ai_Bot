"use client";
/**
 * Diagnostics dashboard.
 *
 * Polls /api/v1/diagnostics/system every 5s and renders a status grid
 * covering: backend, redis, chromadb, voice models, vault, gmail,
 * calendar, conversation memory, and runtime tuning.
 *
 * Read-only — for write operations (sync vault, change config, run OAuth)
 * use the relevant page from the sidebar.
 */
import { useEffect, useState } from "react";

type Status = "ok" | "warn" | "err" | "muted";

interface SystemDiag {
  backend: {
    status: string; app: string; version: string; python: string;
    platform: string; pid: number;
  };
  redis: {
    url: string; connected: boolean; latency_ms: number | null;
    note?: string; error?: string;
  };
  chromadb: {
    host: string; port: number; collection: string;
    connected: boolean; doc_count: number | null;
  };
  voice: {
    stt: { available: boolean; model: string; loaded: boolean; cpu_threads: number; compute_type: string };
    tts: {
      available: boolean; loaded: boolean; voice_name: string;
      voice_path: string; voice_exists: boolean; sample_rate: number;
    };
  };
  vault: {
    path: string; exists: boolean; md_files: number;
    graph: { nodes: number; edges: number; most_linked: { source: string; count: number }[] };
    watcher_active: boolean;
  };
  gmail:    { oauth_configured: boolean; authorized: boolean; email: string | null };
  calendar: { authorized: boolean; today_event_count: number | null };
  memory:   { sessions_active: number; sessions: string[]; redis_backed: boolean };
  runtime:  {
    thread_limits: Record<string, string>; memory_safe: boolean;
    rss_mb: number | null; uptime_seconds: number;
  };
}

const POLL_MS = 5000;

export default function DiagnosticsPage() {
  const [data, setData] = useState<SystemDiag | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [lastFetch, setLastFetch] = useState<number>(0);

  useEffect(() => {
    let cancelled = false;

    async function fetchOnce() {
      try {
        const r = await fetch("/api/v1/diagnostics/system");
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        const json = await r.json();
        if (!cancelled) {
          setData(json);
          setError(null);
          setLastFetch(Date.now());
        }
      } catch (e: any) {
        if (!cancelled) setError(String(e?.message || e));
      }
    }

    fetchOnce();
    const t = setInterval(fetchOnce, POLL_MS);
    return () => { cancelled = true; clearInterval(t); };
  }, []);

  if (error && !data) {
    return (
      <main className="page">
        <div className="page-header">
          <div className="page-title">Diagnostics</div>
          <div className="page-sub">Cannot reach backend.</div>
        </div>
        <div className="alert alert-error">{error}</div>
      </main>
    );
  }

  if (!data) {
    return (
      <main className="page">
        <div className="page-header">
          <div className="page-title">Diagnostics</div>
        </div>
        <div className="card"><span className="spinner" /> Loading…</div>
      </main>
    );
  }

  return (
    <main className="page">
      <div className="page-header">
        <div className="page-title">Diagnostics</div>
        <div className="page-sub">
          Live system snapshot · refresh every {POLL_MS / 1000}s
          {lastFetch ? ` · last at ${new Date(lastFetch).toLocaleTimeString()}` : ""}
        </div>
      </div>

      {error && <div className="alert alert-error">Recent fetch error: {error}</div>}

      <div className="diag-grid">
        <StatusCard
          title="Backend"
          status="ok"
          rows={[
            ["app",     `${data.backend.app} v${data.backend.version}`],
            ["python",  data.backend.python],
            ["platform", data.backend.platform],
            ["pid",     String(data.backend.pid)],
          ]}
        />

        <StatusCard
          title="Redis"
          status={data.redis.connected ? "ok" : "warn"}
          rows={[
            ["url",       data.redis.url],
            ["connected", data.redis.connected ? "yes" : "no — in-memory fallback"],
            ["latency",   data.redis.latency_ms != null ? `${data.redis.latency_ms} ms` : "—"],
            ...(data.redis.error ? [["error" as string, data.redis.error]] : []),
          ]}
        />

        <StatusCard
          title="ChromaDB"
          status={data.chromadb.connected ? "ok" : "err"}
          rows={[
            ["host",       `${data.chromadb.host}:${data.chromadb.port}`],
            ["collection", data.chromadb.collection],
            ["connected",  data.chromadb.connected ? "yes" : "no"],
            ["documents",  data.chromadb.doc_count != null ? String(data.chromadb.doc_count) : "—"],
          ]}
        />

        <StatusCard
          title="Voice — STT"
          status={data.voice.stt.available ? "ok" : "warn"}
          rows={[
            ["model",      data.voice.stt.model],
            ["available",  data.voice.stt.available ? "yes" : "no — install faster-whisper"],
            ["loaded",     data.voice.stt.loaded ? "yes (cached)" : "lazy"],
            ["threads",    `${data.voice.stt.cpu_threads} (${data.voice.stt.compute_type})`],
          ]}
        />

        <StatusCard
          title="Voice — TTS"
          status={data.voice.tts.available && data.voice.tts.voice_exists ? "ok" : "warn"}
          rows={[
            ["voice",      data.voice.tts.voice_name],
            ["available",  data.voice.tts.available ? "yes" : "no — install piper-tts"],
            ["model file", data.voice.tts.voice_exists ? "present" : "missing — POST /voice/setup"],
            ["loaded",     data.voice.tts.loaded ? "yes (cached)" : "lazy"],
            ["sample rate", `${data.voice.tts.sample_rate} Hz`],
          ]}
        />

        <StatusCard
          title="Vault"
          status={data.vault.exists ? "ok" : "err"}
          rows={[
            ["path",       data.vault.path],
            ["exists",     data.vault.exists ? "yes" : "no — configure /obsidian/config"],
            ["md files",   String(data.vault.md_files)],
            ["graph",      `${data.vault.graph.nodes} nodes · ${data.vault.graph.edges} edges`],
            ["watcher",    data.vault.watcher_active ? "live" : "off"],
          ]}
        />

        <StatusCard
          title="Gmail"
          status={data.gmail.authorized ? "ok" : data.gmail.oauth_configured ? "warn" : "muted"}
          rows={[
            ["oauth",      data.gmail.oauth_configured ? "configured" : "set GMAIL_CLIENT_ID/SECRET"],
            ["authorized", data.gmail.authorized ? "yes" : "no — visit /api/v1/auth/google/login"],
            ["account",    data.gmail.email || "—"],
          ]}
        />

        <StatusCard
          title="Calendar"
          status={data.calendar.authorized ? "ok" : "muted"}
          rows={[
            ["authorized",  data.calendar.authorized ? "yes" : "no — shares Gmail OAuth"],
            ["today count", data.calendar.today_event_count != null ? String(data.calendar.today_event_count) : "—"],
          ]}
        />

        <StatusCard
          title="Conversation memory"
          status="ok"
          rows={[
            ["backend",         data.memory.redis_backed ? "redis" : "in-memory"],
            ["active sessions", String(data.memory.sessions_active)],
            ...(data.memory.sessions.slice(0, 3).map(s => ["session" as string, s])),
          ]}
        />

        <StatusCard
          title="Runtime"
          status={data.runtime.memory_safe ? "ok" : "warn"}
          rows={[
            ["memory_safe", data.runtime.memory_safe ? "yes (1-thread per backend)" : "no — risk of OpenBLAS crash"],
            ["RSS",         data.runtime.rss_mb != null ? `${data.runtime.rss_mb} MB` : "psutil not installed"],
            ["uptime",      formatUptime(data.runtime.uptime_seconds)],
            ...Object.entries(data.runtime.thread_limits)
              .filter(([, v]) => v)
              .map(([k, v]) => [k.toLowerCase(), v] as [string, string]),
          ]}
        />
      </div>

      <style>{CSS}</style>
    </main>
  );
}

function StatusCard({ title, status, rows }: {
  title: string;
  status: Status;
  rows: [string, string][];
}) {
  return (
    <div className={`diag-card diag-${status}`}>
      <div className="diag-card-head">
        <span className={`diag-dot diag-dot-${status}`} />
        <span className="diag-title">{title}</span>
      </div>
      <table className="diag-rows">
        <tbody>
          {rows.map(([k, v], i) => (
            <tr key={i}>
              <td className="diag-key">{k}</td>
              <td className="diag-val mono">{v}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function formatUptime(seconds: number): string {
  const d = Math.floor(seconds / 86400);
  const h = Math.floor((seconds % 86400) / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  if (d > 0) return `${d}d ${h}h`;
  if (h > 0) return `${h}h ${m}m`;
  return `${m}m ${seconds % 60}s`;
}

const CSS = `
.diag-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 12px;
}
.diag-card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 14px 16px;
}
.diag-card.diag-ok    { border-left: 3px solid var(--green); }
.diag-card.diag-warn  { border-left: 3px solid var(--yellow); }
.diag-card.diag-err   { border-left: 3px solid var(--red); }
.diag-card.diag-muted { border-left: 3px solid var(--dim); }

.diag-card-head { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; }
.diag-title { font-size: 13px; font-weight: 600; color: var(--text); }
.diag-dot { width: 7px; height: 7px; border-radius: 50%; }
.diag-dot-ok    { background: var(--green);  box-shadow: 0 0 6px var(--green); }
.diag-dot-warn  { background: var(--yellow); box-shadow: 0 0 6px var(--yellow); }
.diag-dot-err   { background: var(--red);    box-shadow: 0 0 6px var(--red); }
.diag-dot-muted { background: var(--dim); }

.diag-rows { width: 100%; border-collapse: collapse; }
.diag-rows td {
  padding: 4px 0;
  font-size: 12px;
  vertical-align: top;
  word-break: break-all;
}
.diag-key { color: var(--text2); width: 110px; }
.diag-val { color: var(--text); }
`;
