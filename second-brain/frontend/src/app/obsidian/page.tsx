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

  async function loadStatus() {
    try {
      const [s, g] = await Promise.all([
        fetch("/api/v1/obsidian/status").then((r) => r.json()),
        fetch("/api/v1/obsidian/graph").then((r) => r.json()),
      ]);
      setStatus(s);
      setGraph(g);
    } catch (err) {
      setError(String(err));
    }
  }

  useEffect(() => { loadStatus(); }, []);

  async function triggerSync() {
    setSyncing(true);
    setSyncMsg(null);
    setError(null);
    try {
      const res = await fetch("/api/v1/obsidian/sync", { method: "POST" });
      const data = await res.json();
      setSyncMsg(data.message ?? "Sync started.");
      // Reload stats after a short delay so the background task has time to run
      setTimeout(loadStatus, 3000);
    } catch (err) {
      setError(String(err));
    } finally {
      setSyncing(false);
    }
  }

  return (
    <>
      <div className="row" style={{ marginBottom: 20 }}>
        <h1 style={{ marginBottom: 0 }}>Obsidian vault</h1>
        <div className="grow" />
        <button onClick={loadStatus}>refresh</button>
        <button onClick={triggerSync} disabled={syncing} style={{ marginLeft: 8 }}>
          {syncing ? "syncing…" : "sync now"}
        </button>
      </div>

      {error && <p className="err" style={{ marginBottom: 12 }}>{error}</p>}
      {syncMsg && <p className="ok" style={{ marginBottom: 12 }}>{syncMsg}</p>}

      {status && (
        <div className="card" style={{ marginBottom: 20 }}>
          <h2>Vault status</h2>
          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 14 }}>
            <tbody>
              {[
                ["Path", status.vault_path],
                ["Exists", status.exists ? "yes" : "no"],
                ["Markdown files", String(status.md_files)],
                ["File watcher", status.watcher_active ? "active" : "inactive"],
              ].map(([label, value]) => (
                <tr key={label}>
                  <td className="dim" style={{ padding: "4px 0", width: 160 }}>{label}</td>
                  <td
                    className={
                      value === "no" || value === "inactive" ? "err"
                      : value === "yes" || value === "active" ? "ok"
                      : ""
                    }
                  >
                    {value}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {graph && (
        <div className="card">
          <h2>Knowledge graph</h2>
          <div className="row" style={{ marginBottom: 16, gap: 32 }}>
            <div>
              <div style={{ fontSize: 28, color: "#7eb8f7" }}>{graph.nodes}</div>
              <div className="dim">nodes</div>
            </div>
            <div>
              <div style={{ fontSize: 28, color: "#7eb8f7" }}>{graph.edges}</div>
              <div className="dim">edges</div>
            </div>
          </div>

          {graph.most_linked.length > 0 && (
            <>
              <h2 style={{ marginBottom: 8 }}>Most linked notes</h2>
              {graph.most_linked.map((n) => (
                <div key={n.note} className="row" style={{ marginBottom: 4 }}>
                  <span style={{ fontSize: 13 }}>{n.note}</span>
                  <div className="grow" />
                  <span className="dim">{n.backlinks} backlinks</span>
                </div>
              ))}
            </>
          )}
        </div>
      )}
    </>
  );
}
