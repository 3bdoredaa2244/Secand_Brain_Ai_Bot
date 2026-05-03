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

  async function decide(id: string, approved: boolean, note?: string) {
    setConfirming(id);
    try {
      const res = await fetch("/api/v1/actions/confirm", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action_id: id, approved, note: note ?? "" }),
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
    <>
      <div className="row" style={{ marginBottom: 20 }}>
        <h1 style={{ marginBottom: 0 }}>Pending actions</h1>
        <div className="grow" />
        <button onClick={load}>refresh</button>
      </div>

      {error && <p className="err">{error}</p>}
      {loading && <p className="dim">loading…</p>}

      {!loading && pending.length === 0 && (
        <p className="dim">No actions awaiting confirmation.</p>
      )}

      {pending.map((a) => (
        <div key={a.id} className="card">
          <div className="row" style={{ marginBottom: 8 }}>
            <span style={{ fontWeight: "bold" }}>{a.plan.type}</span>
            <span className="tag warn">{a.status}</span>
            <div className="grow" />
            <span className="dim">{new Date(a.created_at).toLocaleString()}</span>
          </div>

          <p style={{ marginBottom: 8 }}>{a.plan.description}</p>

          {a.plan.risks.length > 0 && (
            <p className="dim err" style={{ marginBottom: 8 }}>
              Risks: {a.plan.risks.join(", ")}
            </p>
          )}

          <div className="row" style={{ marginBottom: 8 }}>
            {a.plan.estimated_cost && (
              <span className="dim">cost: {a.plan.estimated_cost}</span>
            )}
            {a.plan.estimated_time && (
              <span className="dim">time: {a.plan.estimated_time}</span>
            )}
            <span className="dim">reversible: {a.plan.reversible ? "yes" : "no"}</span>
          </div>

          <pre style={{ marginBottom: 12, fontSize: 12 }}>
            {JSON.stringify(a.plan.parameters, null, 2)}
          </pre>

          <div className="row">
            <button
              className="ok"
              disabled={confirming === a.id}
              onClick={() => decide(a.id, true)}
              style={{ borderColor: "#4ec94e" }}
            >
              approve
            </button>
            <button
              className="err"
              disabled={confirming === a.id}
              onClick={() => decide(a.id, false, "rejected from UI")}
              style={{ borderColor: "#e06c75" }}
            >
              reject
            </button>
          </div>
        </div>
      ))}
    </>
  );
}
