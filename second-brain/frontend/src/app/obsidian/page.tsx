"use client";
import { useEffect, useState } from "react";

interface VaultStatus {
  vault_path: string;
  exists: boolean;
  md_files: number;
  watcher_active: boolean;
}

interface GraphSummary {
  nodes: number;
  edges: number;
  most_linked: { note: string; backlinks: number }[];
}

export default function ObsidianPage() {
  const [status, setStatus] = useState<VaultStatus | null>(null);
  const [graph, setGraph] = useState<GraphSummary | null>(null);
  const [syncing, setSyncing] = useState(false);
  const [syncMsg, setSyncMsg] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  async function loadAll() {
    setLoading(true);
    setError(null);
    try {
      const [s, g] = await Promise.all([
        fetch("/api/v1/obsidian/status").then((r) => { if (!r.ok) throw new Error(`status ${r.status}`); return r.json(); }),
        fetch("/api/v1/obsidian/graph").then((r) => { if (!r.ok) throw new Error(`graph ${r.status}`); return r.json(); }),
      ]);
      setStatus(s);
      setGraph(g);
    } catch (err) {
      setError(String(err));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadAll(); }, []);

  async function triggerSync() {
    setSyncing(true);
    setSyncMsg(null);
    setError(null);
    try {
      const res = await fetch("/api/v1/obsidian/sync", { method: "POST" });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      setSyncMsg(data.message ?? "Sync started in background.");
      setTimeout(loadAll, 4000);
    } catch (err) {
      setError(String(err));
    } finally {
      setSyncing(false);
    }
  }

  return (
    <div className="page">
      <div className="page-header">
        <div className="row">
          <div>
            <div className="page-title">Obsidian Vault</div>
            <div className="page-sub">Index status, graph analysis, and sync controls</div>
          </div>
          <div className="grow" />
          <button onClick={loadAll} disabled={loading}>↻ Refresh</button>
          <button className="btn-primary" onClick={triggerSync} disabled={syncing || loading}>
            {syncing ? <><span className="spinner" /> Syncing…</> : "⟳ Sync Now"}
          </button>
        </div>
      </div>

      {error && (
        <div className="alert alert-error"><span>⚠</span> {error}</div>
      )}
      {syncMsg && (
        <div className="alert alert-info"><span>ℹ</span> {syncMsg}</div>
      )}

      {loading && !status && (
        <div className="empty-state"><span className="spinner" style={{ width: 24, height: 24 }} /></div>
      )}

      {status && (
        <>
          <div className="stat-grid">
            <div className="stat-card">
              <div className="stat-value">{status.md_files}</div>
              <div className="stat-label">Notes</div>
            </div>
            <div className="stat-card">
              <div className="stat-value">{graph?.nodes ?? "—"}</div>
              <div className="stat-label">Graph nodes</div>
            </div>
            <div className="stat-card">
              <div className="stat-value">{graph?.edges ?? "—"}</div>
              <div className="stat-label">Wikilinks</div>
            </div>
            <div className="stat-card">
              <div className="stat-value" style={{ fontSize: 18, color: status.watcher_active ? "var(--green)" : "var(--red)" }}>
                {status.watcher_active ? "On" : "Off"}
              </div>
              <div className="stat-label">File watcher</div>
            </div>
          </div>

          <div className="card mb-16">
            <div className="card-title">Vault Details</div>
            <div className="row" style={{ flexDirection: "column", gap: 8, alignItems: "stretch" }}>
              <div className="row">
                <span className="dim" style={{ width: 120, flexShrink: 0 }}>Path</span>
                <span className="mono truncate" style={{ fontSize: 12 }}>{status.vault_path}</span>
              </div>
              <div className="row">
                <span className="dim" style={{ width: 120, flexShrink: 0 }}>Vault exists</span>
                <span className={status.exists ? "ok" : "err"}>{status.exists ? "Yes" : "No"}</span>
              </div>
              <div className="row">
                <span className="dim" style={{ width: 120, flexShrink: 0 }}>File watcher</span>
                <span className={status.watcher_active ? "ok" : "warn"}>
                  {status.watcher_active ? "Active" : "Inactive"}
                </span>
              </div>
            </div>
          </div>
        </>
      )}

      {graph && graph.most_linked.length > 0 && (
        <div className="card">
          <div className="card-title">Most Linked Notes</div>
          {graph.most_linked.map((n, i) => (
            <div key={n.note} className="row" style={{ padding: "8px 0", borderBottom: i < graph.most_linked.length - 1 ? "1px solid var(--border)" : "none" }}>
              <span style={{ width: 24, color: "var(--dim)", fontSize: 12, flexShrink: 0 }}>{i + 1}.</span>
              <span className="mono grow truncate" style={{ fontSize: 12 }}>{n.note}</span>
              <span className="badge badge-blue">{n.backlinks} ←</span>
            </div>
          ))}
        </div>
      )}

      {graph && graph.most_linked.length === 0 && status && (
        <div className="empty-state" style={{ padding: "40px 20px" }}>
          <div className="empty-icon">◈</div>
          <div className="empty-title">Graph is empty</div>
          <div className="empty-desc">Sync the vault to build the wikilink graph.</div>
        </div>
      )}
    </div>
  );
}
