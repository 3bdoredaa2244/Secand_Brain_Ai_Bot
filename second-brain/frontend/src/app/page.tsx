"use client";
import { useEffect, useRef, useState } from "react";

interface Chunk {
  id: string;
  content: string;
  source: string;
  score: number;
  metadata: Record<string, string>;
}

type AnswerSource = "vault" | "tool" | "llm_fallback" | "no_results" | "error";

interface Message {
  role: "user" | "assistant";
  content: string;
  sources?: Chunk[];
  tool_used?: string | null;
  answer_source?: AnswerSource;
  ts: number;
}

function fmt(ts: number) {
  return new Date(ts).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
}

const SOURCE_BADGE: Record<AnswerSource, { label: string; cls: string }> = {
  vault:        { label: "Vault",       cls: "badge-blue"    },
  tool:         { label: "Live data",   cls: "badge-green"   },
  llm_fallback: { label: "AI",          cls: "badge-purple"  },
  no_results:   { label: "No results",  cls: "badge-default" },
  error:        { label: "Error",       cls: "badge-red"     },
};

function AnswerBadges({ source, tool }: { source?: AnswerSource; tool?: string | null }) {
  if (!source) return null;
  const { label, cls } = SOURCE_BADGE[source] ?? SOURCE_BADGE.vault;
  return (
    <div className="row mt-4" style={{ gap: 6 }}>
      <span className={`badge ${cls}`}>{label}</span>
      {tool && <span className="badge badge-default">{tool}</span>}
    </div>
  );
}

function SourceList({ chunks }: { chunks: Chunk[] }) {
  const [open, setOpen] = useState(false);
  return (
    <div className="mt-4">
      <button className="sources-toggle" onClick={() => setOpen(!open)}>
        {open ? "▾" : "▸"} {chunks.length} vault source{chunks.length !== 1 ? "s" : ""}
      </button>
      {open && chunks.map((c) => (
        <div key={c.id} className="source-item">
          <div className="row">
            <span className="source-path">{c.source}</span>
            <span className="source-score">score {c.score.toFixed(3)}</span>
          </div>
          <div className="source-snippet">{c.content.slice(0, 200)}</div>
        </div>
      ))}
    </div>
  );
}

const SUGGESTIONS = [
  "What is the BTC price?",
  "Weather in Cairo",
  "My health notes this week",
  "Show me my recent meetings",
];

export default function AskPage() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [draft, setDraft] = useState("");
  const [loading, setLoading] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, loading]);

  async function send(text?: string) {
    const query = (text ?? draft).trim();
    if (!query || loading) return;
    setDraft("");

    const userMsg: Message = { role: "user", content: query, ts: Date.now() };
    setMessages((prev) => [...prev, userMsg]);
    setLoading(true);

    try {
      const res = await fetch("/api/v1/query", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text: query, top_k: 5 }),
      });
      // AgentEngine always returns 200 — but guard anyway
      const data = await res.json();
      const content = data.answer
        ?? (data.chunks?.length ? "Here are the relevant notes I found:" : "No results found.");
      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content,
          sources: data.chunks ?? [],
          tool_used: data.tool_used ?? null,
          answer_source: (data.answer_source ?? "vault") as AnswerSource,
          ts: Date.now(),
        },
      ]);
    } catch (err) {
      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content: `Network error: ${String(err)}`,
          answer_source: "error",
          ts: Date.now(),
        },
      ]);
    } finally {
      setLoading(false);
      setTimeout(() => textareaRef.current?.focus(), 50);
    }
  }

  function onKey(e: React.KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      send();
    }
  }

  return (
    <div className="chat-wrap">
      <div className="chat-messages">
        {messages.length === 0 && !loading && (
          <div className="empty-state">
            <div className="empty-icon">✦</div>
            <div className="empty-title">Ask your second brain</div>
            <div className="empty-desc">
              Search your vault, get live crypto prices, check weather, and more.
            </div>
            <div className="row mt-16" style={{ flexWrap: "wrap", justifyContent: "center", gap: 8 }}>
              {SUGGESTIONS.map((s) => (
                <button key={s} className="btn-sm" onClick={() => send(s)}>{s}</button>
              ))}
            </div>
          </div>
        )}

        {messages.map((m, i) => (
          <div key={i} className={m.role === "user" ? "msg-user" : "msg-assistant"}>
            <div className="msg-meta">{m.role === "user" ? "You" : "Second Brain"} · {fmt(m.ts)}</div>
            <div className="msg-bubble" style={{ whiteSpace: "pre-wrap" }}>{m.content}</div>
            {m.role === "assistant" && (
              <>
                <AnswerBadges source={m.answer_source} tool={m.tool_used} />
                {m.sources && m.sources.length > 0 && <SourceList chunks={m.sources} />}
              </>
            )}
          </div>
        ))}

        {loading && (
          <div className="msg-assistant">
            <div className="msg-meta">Second Brain · now</div>
            <div className="msg-bubble"><span className="spinner" /></div>
          </div>
        )}

        <div ref={bottomRef} />
      </div>

      <div className="chat-input-area">
        <div className="chat-input-row">
          <textarea
            ref={textareaRef}
            rows={1}
            placeholder="Ask anything — vault, crypto prices, weather… (Enter to send)"
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={onKey}
          />
          <button className="btn-primary" onClick={() => send()} disabled={loading || !draft.trim()}>
            {loading ? <span className="spinner" /> : "Send"}
          </button>
        </div>
      </div>
    </div>
  );
}
