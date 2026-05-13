"use client";
import { usePathname } from "next/navigation";

const LINKS = [
  { href: "/",            icon: "✦", label: "Ask"         },
  { href: "/actions",     icon: "⚡", label: "Actions"     },
  { href: "/obsidian",    icon: "◈",  label: "Obsidian"    },
  { href: "/voice",       icon: "◎",  label: "Voice"       },
  { href: "/diagnostics", icon: "❖",  label: "Diagnostics" },
];

export function Sidebar() {
  const pathname = usePathname();
  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <div className="brand-logo">SB</div>
        <div>
          <div className="brand-name">second-brain</div>
          <div className="brand-sub">personal AI</div>
        </div>
      </div>

      <nav className="sidebar-nav">
        {LINKS.map((l) => {
          const active = pathname === l.href;
          return (
            <a
              key={l.href}
              href={l.href}
              className={`nav-item${active ? " nav-active" : ""}`}
            >
              <span className="nav-icon">{l.icon}</span>
              <span className="nav-label">{l.label}</span>
              {active && <span className="nav-pip" />}
            </a>
          );
        })}
      </nav>

      <div className="sidebar-footer">
        <div className="status-dot" title="Backend connected" />
        <span className="sidebar-footer-text">Phase 2</span>
      </div>
    </aside>
  );
}
