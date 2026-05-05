"use client";
import { useEffect, useState } from "react";

interface ActionPlan {
  type: string;
  description: string;
  parameters: Record<string, unknown>;
  estimated_cost?: string;
  estimated_time?: string;
  risks: string[];
  reversible: boolean;
}

interface ActionRequest {
  id: string;
  plan: ActionPlan;
  status: string;
  triggered_by: string | null;
  created_at: string;
}

function RiskBadge({ risk }: { risk: string }) {
  return <span className="badge badge-red">{risk}</span>;
}

export default function ActionsPage() {
  const [pending, setPending] = useState<ActionRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [confirming, setConfirming] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/v1/actions/pending");
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      setPending(await res.json());
    } catch (err) {
      setError(String(err));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  async function decide(id: string, approved: boolean) {
    setConfirming(id);
    try {
      const res = await fetch("/api/v1/actions/confirm", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action_id: id, approved, note: approved ? "" : "rejected from UI" }),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      await load();
    } catch (err) {
      setError(String(err));
    } finally {
      setConfirming(null);
    }
  }

  return (
    <div className="page">
      <div className="page-header">
        <div className="row">
          <div>
            <div className="page-title">Pending Actions</div>
            <div className="page-sub">Review and approve actions before they execute</div>
          </div>
          <div className="grow" />
          <button onClick={load} disabled={loading}>
            {loading ? <span className="spinner" /> : "↻"} Refresh
          </button>
        </div>
      </div>

      {error && (
        <div className="alert alert-error">
          <span>⚠</span> {error}
        </div>
      )}

      {loading && !pending.length && (
        <div className="empty-state">
          <span className="spinner" style={{ width: 24, height: 24 }} />
        </div>
      )}

      {!loading && pending.length === 0 && !error && (
        <div className="empty-state">
          <div className="empty-icon">⚡</div>
          <div className="empty-title">No pending actions</div>
          <div className="empty-desc">
            Actions appear here when a trigger proposes something that needs your approval.
          </div>
        </div>
      )}

      {pending.map((a) => (
        <div key={a.id} className="card">
          <div className="row mb-8">
            <span className="badge badge-yellow">{a.status}</span>
            <span className="badge badge-blue">{a.plan.type}</span>
            {!a.plan.reversible && <span className="badge badge-red">irreversible</span>}
            <div className="grow" />
            <span className="dim">{new Date(a.created_at).toLocaleString()}</span>
          </div>

          <div style={{ fontSize: 15, color: "var(--text)", marginBottom: 12 }}>
            {a.plan.description}
          </div>

          {(a.plan.estimated_cost || a.plan.estimated_time || a.triggered_by) && (
            <div className="row mb-8" style={{ gap: 16 }}>
              {a.plan.estimated_cost && (
                <span className="dim">cost: <strong>{a.plan.estimated_cost}</strong></span>
              )}
              {a.plan.estimated_time && (
                <span className="dim">time: <strong>{a.plan.estimated_time}</strong></span>
              )}
              {a.triggered_by && (
                <span className="dim">trigger: <strong>{a.triggered_by}</strong></span>
              )}
            </div>
          )}

          {a.plan.risks.length > 0 && (
            <div className="row mb-8" style={{ flexWrap: "wrap" }}>
              {a.plan.risks.map((r) => <RiskBadge key={r} risk={r} />)}
            </div>
          )}

          {Object.keys(a.plan.parameters).length > 0 && (
            <pre style={{ marginBottom: 16, fontSize: 12 }}>
              {JSON.stringify(a.plan.parameters, null, 2)}
            </pre>
          )}

          <div className="row">
            <button
              className="btn-success btn-sm"
              disabled={confirming === a.id}
              onClick={() => decide(a.id, true)}
            >
              {confirming === a.id ? <span className="spinner" /> : "✓"} Approve
            </button>
            <button
              className="btn-danger btn-sm"
              disabled={confirming === a.id}
              onClick={() => decide(a.id, false)}
            >
              ✕ Reject
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}
