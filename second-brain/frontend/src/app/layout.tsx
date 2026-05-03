import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Second Brain",
  description: "Personal AI assistant",
};

const NAV: { href: string; label: string }[] = [
  { href: "/", label: "Ask" },
  { href: "/actions", label: "Actions" },
  { href: "/obsidian", label: "Obsidian" },
];

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <style>{`
          *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
          body { font-family: monospace; background: #0d0d0d; color: #e0e0e0; min-height: 100vh; }
          a { color: #7eb8f7; text-decoration: none; }
          a:hover { text-decoration: underline; }
          nav { display: flex; gap: 24px; padding: 16px 24px; border-bottom: 1px solid #222; }
          nav a { font-size: 14px; letter-spacing: 0.05em; }
          main { padding: 32px 24px; max-width: 860px; }
          button {
            background: #1a1a1a; color: #e0e0e0; border: 1px solid #333;
            padding: 8px 16px; cursor: pointer; font-family: monospace; font-size: 14px;
          }
          button:hover { border-color: #7eb8f7; }
          input, textarea {
            background: #111; color: #e0e0e0; border: 1px solid #333;
            padding: 10px 14px; font-family: monospace; font-size: 14px; width: 100%;
          }
          input:focus, textarea:focus { outline: none; border-color: #7eb8f7; }
          pre { background: #111; padding: 16px; overflow-x: auto; font-size: 13px; line-height: 1.6; }
          .card { border: 1px solid #222; padding: 16px; margin-bottom: 12px; }
          .tag { display: inline-block; background: #1a1a1a; border: 1px solid #333;
                 padding: 2px 8px; font-size: 12px; margin: 2px; }
          .dim { color: #666; font-size: 12px; }
          .row { display: flex; gap: 8px; align-items: flex-start; }
          .grow { flex: 1; }
          h1 { font-size: 18px; margin-bottom: 20px; color: #fff; }
          h2 { font-size: 14px; margin-bottom: 8px; color: #aaa; text-transform: uppercase; letter-spacing: 0.08em; }
          .ok { color: #4ec94e; } .err { color: #e06c75; } .warn { color: #e5c07b; }
        `}</style>
      </head>
      <body>
        <nav>
          <span style={{ color: "#7eb8f7", fontWeight: "bold" }}>second-brain</span>
          {NAV.map((n) => (
            <a key={n.href} href={n.href}>{n.label}</a>
          ))}
        </nav>
        <main>{children}</main>
      </body>
    </html>
  );
}
