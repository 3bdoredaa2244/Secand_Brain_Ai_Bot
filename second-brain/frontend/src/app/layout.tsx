import type { Metadata } from "next";
import { Sidebar } from "@/components/Sidebar";

export const metadata: Metadata = {
  title: "Second Brain",
  description: "Personal AI assistant",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <style>{CSS}</style>
      </head>
      <body>
        <Sidebar />
        <div className="main-wrap">
          {children}
        </div>
      </body>
    </html>
  );
}

const CSS = `
/* ── reset ────────────────────────────────────────────────────────── */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html, body { height: 100%; }

/* ── design tokens ───────────────────────────────────────────────── */
:root {
  --bg:        #0b0b10;
  --surface:   #111118;
  --surface2:  #17171f;
  --surface3:  #1e1e28;
  --border:    #25253a;
  --border2:   #2e2e45;
  --text:      #d0d0e8;
  --text2:     #9090b0;
  --dim:       #55556a;
  --accent:    #7b97ff;
  --accent2:   #a78bfa;
  --green:     #6ee7b7;
  --red:       #f87171;
  --yellow:    #fbbf24;
  --radius:    8px;
  --radius-sm: 5px;
  --sidebar-w: 220px;
  --font:      -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
  --mono:      "JetBrains Mono", "Fira Code", ui-monospace, "Cascadia Code", monospace;
}

/* ── base ─────────────────────────────────────────────────────────── */
body {
  font-family: var(--font);
  background: var(--bg);
  color: var(--text);
  display: flex;
  min-height: 100vh;
  font-size: 14px;
  line-height: 1.5;
  -webkit-font-smoothing: antialiased;
}
a { color: var(--accent); text-decoration: none; }
a:hover { color: #9fb8ff; }

/* ── sidebar ──────────────────────────────────────────────────────── */
.sidebar {
  width: var(--sidebar-w);
  min-height: 100vh;
  background: var(--surface);
  border-right: 1px solid var(--border);
  display: flex;
  flex-direction: column;
  position: fixed;
  top: 0; left: 0;
  z-index: 10;
}

.sidebar-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 20px 18px 18px;
  border-bottom: 1px solid var(--border);
}
.brand-logo {
  width: 32px; height: 32px;
  background: linear-gradient(135deg, var(--accent), var(--accent2));
  border-radius: 7px;
  display: flex; align-items: center; justify-content: center;
  font-size: 11px; font-weight: 700; color: #fff;
  letter-spacing: -0.03em; flex-shrink: 0;
}
.brand-name { font-size: 13px; font-weight: 600; color: var(--text); }
.brand-sub  { font-size: 10px; color: var(--dim); }

.sidebar-nav { flex: 1; padding: 10px 0; }
.nav-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 9px 18px;
  color: var(--text2);
  font-size: 13px;
  text-decoration: none;
  border-radius: 0;
  transition: background 0.1s, color 0.1s;
  position: relative;
  cursor: pointer;
}
.nav-item:hover { background: var(--surface2); color: var(--text); }
.nav-active { color: var(--accent) !important; background: rgba(123,151,255,0.08) !important; }
.nav-icon { font-size: 14px; width: 18px; text-align: center; flex-shrink: 0; }
.nav-label { flex: 1; }
.nav-pip {
  width: 3px; height: 16px;
  background: var(--accent);
  border-radius: 2px;
  position: absolute;
  right: 0; top: 50%; transform: translateY(-50%);
}

.sidebar-footer {
  padding: 14px 18px;
  border-top: 1px solid var(--border);
  display: flex;
  align-items: center;
  gap: 8px;
}
.status-dot {
  width: 7px; height: 7px;
  border-radius: 50%;
  background: var(--green);
  box-shadow: 0 0 6px var(--green);
  flex-shrink: 0;
}
.sidebar-footer-text { font-size: 11px; color: var(--dim); }

/* ── main layout ──────────────────────────────────────────────────── */
.main-wrap {
  margin-left: var(--sidebar-w);
  flex: 1;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}
.page { padding: 32px 36px; max-width: 880px; width: 100%; }

/* ── page headers ─────────────────────────────────────────────────── */
.page-header { margin-bottom: 28px; }
.page-title  { font-size: 20px; font-weight: 600; color: #fff; }
.page-sub    { font-size: 13px; color: var(--text2); margin-top: 4px; }

/* ── cards ────────────────────────────────────────────────────────── */
.card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 20px;
  margin-bottom: 12px;
}
.card:last-child { margin-bottom: 0; }
.card-sm { padding: 14px 16px; }
.card-title {
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--text2);
  margin-bottom: 12px;
}

/* ── buttons ──────────────────────────────────────────────────────── */
button {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: var(--surface2);
  color: var(--text);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 7px 14px;
  font-size: 13px;
  font-family: var(--font);
  cursor: pointer;
  transition: border-color 0.1s, color 0.1s, background 0.1s;
  white-space: nowrap;
}
button:hover:not(:disabled) { border-color: var(--border2); background: var(--surface3); }
button:disabled { opacity: 0.4; cursor: not-allowed; }
.btn-primary {
  background: var(--accent);
  color: #080810;
  border-color: var(--accent);
  font-weight: 600;
}
.btn-primary:hover:not(:disabled) { background: #8fa8ff; border-color: #8fa8ff; color: #080810; }
.btn-danger  { border-color: var(--red);   color: var(--red); }
.btn-danger:hover:not(:disabled) { background: rgba(248,113,113,0.08); }
.btn-success { border-color: var(--green); color: var(--green); }
.btn-success:hover:not(:disabled) { background: rgba(110,231,183,0.08); }
.btn-sm { padding: 5px 10px; font-size: 12px; }

/* ── inputs ───────────────────────────────────────────────────────── */
input, textarea, select {
  background: var(--surface2);
  color: var(--text);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 9px 12px;
  font-size: 14px;
  font-family: var(--font);
  width: 100%;
  outline: none;
  transition: border-color 0.15s;
}
input:focus, textarea:focus, select:focus { border-color: var(--accent); }
textarea { resize: vertical; line-height: 1.6; }

/* ── badges ───────────────────────────────────────────────────────── */
.badge {
  display: inline-flex; align-items: center;
  padding: 2px 8px; border-radius: 999px;
  font-size: 11px; font-weight: 500; white-space: nowrap;
}
.badge-default { background: var(--surface3); color: var(--text2); border: 1px solid var(--border); }
.badge-blue   { background: rgba(123,151,255,.12); color: var(--accent);  border: 1px solid rgba(123,151,255,.25); }
.badge-green  { background: rgba(110,231,183,.12); color: var(--green);   border: 1px solid rgba(110,231,183,.25); }
.badge-red    { background: rgba(248,113,113,.12); color: var(--red);     border: 1px solid rgba(248,113,113,.25); }
.badge-yellow { background: rgba(251,191,36,.12);  color: var(--yellow);  border: 1px solid rgba(251,191,36,.25); }
.badge-purple { background: rgba(167,139,250,.12); color: var(--accent2); border: 1px solid rgba(167,139,250,.25); }

/* ── code / pre ───────────────────────────────────────────────────── */
pre, code { font-family: var(--mono); font-size: 12.5px; }
pre {
  background: var(--surface2);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 14px 16px;
  overflow-x: auto;
  line-height: 1.65;
  white-space: pre-wrap;
  word-break: break-word;
}

/* ── stat grid ────────────────────────────────────────────────────── */
.stat-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(130px, 1fr)); gap: 12px; margin-bottom: 20px; }
.stat-card {
  background: var(--surface2);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 16px;
}
.stat-value { font-size: 26px; font-weight: 700; color: var(--accent); line-height: 1; }
.stat-label { font-size: 11px; color: var(--dim); margin-top: 6px; text-transform: uppercase; letter-spacing: 0.05em; }

/* ── alerts ───────────────────────────────────────────────────────── */
.alert {
  border-radius: var(--radius-sm);
  padding: 11px 14px;
  font-size: 13px;
  margin-bottom: 16px;
  display: flex;
  align-items: flex-start;
  gap: 8px;
}
.alert-error   { background: rgba(248,113,113,.08); border: 1px solid rgba(248,113,113,.2); color: var(--red); }
.alert-success { background: rgba(110,231,183,.08); border: 1px solid rgba(110,231,183,.2); color: var(--green); }
.alert-info    { background: rgba(123,151,255,.08); border: 1px solid rgba(123,151,255,.2); color: var(--accent); }

/* ── spinner ──────────────────────────────────────────────────────── */
.spinner {
  display: inline-block;
  width: 14px; height: 14px;
  border: 2px solid var(--border2);
  border-top-color: var(--accent);
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
  flex-shrink: 0;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* ── utility ──────────────────────────────────────────────────────── */
.row   { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.row-start { display: flex; gap: 8px; align-items: flex-start; }
.grow  { flex: 1; min-width: 0; }
.dim   { color: var(--dim); font-size: 12px; }
.ok    { color: var(--green); }
.err   { color: var(--red); }
.warn  { color: var(--yellow); }
.mono  { font-family: var(--mono); }
.truncate { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.mt-4  { margin-top:  4px; }
.mt-8  { margin-top:  8px; }
.mt-16 { margin-top: 16px; }
.mb-8  { margin-bottom:  8px; }
.mb-16 { margin-bottom: 16px; }
.mb-24 { margin-bottom: 24px; }

/* ── chat ─────────────────────────────────────────────────────────── */
.chat-wrap { display: flex; flex-direction: column; height: calc(100vh - 0px); }
.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: 24px 36px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}
.chat-input-area {
  border-top: 1px solid var(--border);
  padding: 16px 36px;
  background: var(--surface);
}

.msg-user, .msg-assistant { max-width: 760px; width: 100%; }
.msg-user { align-self: flex-end; }
.msg-assistant { align-self: flex-start; }

.msg-bubble {
  border-radius: var(--radius);
  padding: 12px 16px;
  font-size: 14px;
  line-height: 1.65;
  white-space: pre-wrap;
  word-break: break-word;
}
.msg-user .msg-bubble {
  background: var(--accent);
  color: #08080f;
}
.msg-assistant .msg-bubble {
  background: var(--surface);
  border: 1px solid var(--border);
  color: var(--text);
}

.msg-meta {
  font-size: 11px;
  color: var(--dim);
  margin-bottom: 5px;
  padding: 0 2px;
}
.msg-user .msg-meta { text-align: right; }

.sources-toggle {
  margin-top: 8px;
  font-size: 12px;
  color: var(--text2);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  border: none;
  background: none;
  padding: 2px 0;
}
.sources-toggle:hover { color: var(--accent); }
.source-item {
  background: var(--surface2);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 10px 12px;
  margin-top: 6px;
  font-size: 12px;
}
.source-path { color: var(--dim); font-family: var(--mono); }
.source-score { float: right; color: var(--dim); }
.source-snippet { margin-top: 4px; color: var(--text2); line-height: 1.5; }

.chat-input-row { display: flex; gap: 8px; align-items: flex-end; }
.chat-input-row textarea { flex: 1; max-height: 120px; }

/* ── empty state ──────────────────────────────────────────────────── */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  flex: 1;
  padding: 60px 20px;
  text-align: center;
  gap: 12px;
  color: var(--dim);
}
.empty-icon { font-size: 40px; opacity: 0.5; }
.empty-title { font-size: 16px; color: var(--text2); font-weight: 500; }
.empty-desc { font-size: 13px; max-width: 360px; line-height: 1.6; }
`;
