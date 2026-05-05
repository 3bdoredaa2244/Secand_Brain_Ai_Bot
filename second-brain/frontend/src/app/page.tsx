"use client";
import { useEffect, useRef, useState } from "react";

interface Chunk {
  id: string;
  content: string;
  source: string;
  score: number;
  metadata: Record<string, string>;
}

interface Message {
  role: "user" | "assistant";
  content: string;
  sources?: Chunk[];
  ts: number;
}

function fmt(ts: number) {
  return new Date(ts).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
}

function SourceList({ chunks }: { chunks: Chunk[] }) {
  const [open, setOpen] = useState(false);
  return (
    <div>
      <button className="sources-toggle" onClick={() => setOpen(!open)}>
        {open ? "▾" : "▸"} {chunks.length} source{chunks.length !== 1 ? "s" : ""}
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

export default function AskPage() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [draft, setDraft] = useState("");
  const [loading, setLoading] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, loading]);

  async function send() {
    const text = draft.trim();
    if (!text || loading) return;
    setDraft("");

    const userMsg: Message = { role: "user", content: text, ts: Date.now() };
    setMessages((prev) => [...prev, userMsg]);
    setLoading(true);

    try {
      const res = await fetch("/api/v1/query", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text, top_k: 5 }),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      const assistantMsg: Message = {
        role: "assistant",
        content: data.answer ?? (data.chunks?.length ? "Here are the relevant notes I found:" : "No results found."),
        sources: data.chunks ?? [],
        ts: Date.now(),
      };
      setMessages((prev) => [...prev, assistantMsg]);
    } catch (err) {
      setMessages((prev) => [
        ...prev,
        { role: "assistant", content: `Error: ${String(err)}`, ts: Date.now() },
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
              Ask anything — your Obsidian notes, daily logs, projects, and ideas are all searchable.
            </div>
          </div>
        )}

        {messages.map((m, i) => (
          <div key={i} className={m.role === "user" ? "msg-user" : "msg-assistant"}>
            <div className="msg-meta">{m.role === "user" ? "You" : "Second Brain"} · {fmt(m.ts)}</div>
            <div className="msg-bubble">{m.content}</div>
            {m.role === "assistant" && m.sources && m.sources.length > 0 && (
              <SourceList chunks={m.sources} />
            )}
          </div>
        ))}

        {loading && (
          <div className="msg-assistant">
            <div className="msg-meta">Second Brain · now</div>
            <div className="msg-bubble">
              <span className="spinner" />
            </div>
          </div>
        )}

        <div ref={bottomRef} />
      </div>

      <div className="chat-input-area">
        <div className="chat-input-row">
          <textarea
            ref={textareaRef}
            rows={1}
            placeholder="Ask anything… (Enter to send, Shift+Enter for newline)"
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={onKey}
          />
          <button className="btn-primary" onClick={send} disabled={loading || !draft.trim()}>
            {loading ? <span className="spinner" /> : "Send"}
          </button>
        </div>
      </div>
    </div>
  );
}
