"use client";
import { useState } from "react";

interface Chunk {
  id: string;
  content: string;
  source: string;
  score: number;
  metadata: Record<string, string>;
}

interface QueryResult {
  query: string;
  chunks: Chunk[];
  answer: string | null;
}

export default function AskPage() {
  const [text, setText] = useState("");
  const [topK, setTopK] = useState(5);
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<QueryResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!text.trim()) return;
    setLoading(true);
    setError(null);
    setResult(null);

    try {
      const res = await fetch("/api/v1/query", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text: text.trim(), top_k: topK }),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      setResult(await res.json());
    } catch (err) {
      setError(String(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <>
      <h1>Ask your second brain</h1>

      <form onSubmit={submit}>
        <div className="row" style={{ marginBottom: 8 }}>
          <textarea
            className="grow"
            rows={3}
            placeholder="What do you want to know?"
            value={text}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => { if (e.key === "Enter" && !e.shiftKey) submit(e as any); }}
          />
        </div>
        <div className="row">
          <label className="dim" style={{ whiteSpace: "nowrap", paddingTop: 10 }}>
            top_k&nbsp;
            <input
              type="number" min={1} max={20} value={topK}
              onChange={(e) => setTopK(Number(e.target.value))}
              style={{ width: 60 }}
            />
          </label>
          <div className="grow" />
          <button type="submit" disabled={loading}>
            {loading ? "searching…" : "search"}
          </button>
        </div>
      </form>

      {error && <p className="err" style={{ marginTop: 16 }}>{error}</p>}

      {result && (
        <div style={{ marginTop: 24 }}>
          {result.answer && (
            <div className="card" style={{ marginBottom: 20, borderColor: "#7eb8f7" }}>
              <h2>Answer</h2>
              <p style={{ lineHeight: 1.7, whiteSpace: "pre-wrap" }}>{result.answer}</p>
            </div>
          )}

          <h2>{result.chunks.length} chunk(s) retrieved</h2>

          {result.chunks.map((c) => (
            <div key={c.id} className="card">
              <div className="row" style={{ marginBottom: 6 }}>
                <span className="dim">{c.source}</span>
                <div className="grow" />
                <span className="dim">score {c.score.toFixed(3)}</span>
              </div>
              <pre style={{ marginBottom: 8 }}>{c.content}</pre>
              <div>
                {c.metadata.note_type && <span className="tag">{c.metadata.note_type}</span>}
                {c.metadata.priority && <span className="tag warn">{c.metadata.priority}</span>}
                {c.metadata.tags && c.metadata.tags.split(",").filter(Boolean).map((t) => (
                  <span key={t} className="tag dim">{t}</span>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
