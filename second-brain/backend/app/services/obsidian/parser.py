"""
Obsidian markdown parser.

Understands:
  - YAML frontmatter (title, tags, date, aliases, …)
  - Structured fields: type, priority, due_date, status (promoted for indexing)
  - Inline #tags in the body
  - [[Wikilinks]] and [[Wikilink|display text]]
  - ![[Embeds]] (stripped from clean text)
  - First # Heading as fallback title
"""
import re
from dataclasses import dataclass, field
from pathlib import Path

try:
    import yaml as _yaml
    _YAML_OK = True
except ImportError:
    _YAML_OK = False

# ── regexes ──────────────────────────────────────────────────────────────────
_FRONTMATTER_RE = re.compile(r"^---[ \t]*\r?\n(.*?)\r?\n---[ \t]*\r?\n", re.DOTALL)
_EMBED_RE = re.compile(r"!\[\[[^\]]*\]\]")
_WIKILINK_RE = re.compile(r"\[\[([^\]|#]+)(?:#[^\]|]*)?((?:\|[^\]]+)?)\]\]")
_INLINE_TAG_RE = re.compile(r"(?<!\S)#([A-Za-z][A-Za-z0-9_/\-]*)")
_H1_RE = re.compile(r"^#\s+(.+)", re.MULTILINE)

# Known structured field names (case-insensitive lookup)
_NOTE_TYPES = {"task", "note", "reminder", "health", "finance", "meeting", "person", "project"}
_PRIORITIES = {"high", "medium", "low", "urgent"}
_STATUSES = {"open", "done", "cancelled", "in-progress", "archived"}


@dataclass
class ObsidianNote:
    path: Path
    title: str
    body: str           # clean text for indexing (frontmatter stripped, wikilinks resolved)
    raw_content: str

    # Flat collections
    tags: list[str] = field(default_factory=list)
    frontmatter: dict = field(default_factory=dict)
    wikilinks: list[str] = field(default_factory=list)

    # Promoted structured fields — usable as ChromaDB `where` filters
    note_type: str = ""     # task | note | reminder | health | finance | …
    priority: str = ""      # high | medium | low | urgent
    due_date: str = ""      # ISO date string, e.g. "2024-03-15"
    status: str = ""        # open | done | cancelled | in-progress | archived


# ── frontmatter ───────────────────────────────────────────────────────────────

def _parse_yaml(raw: str) -> dict:
    if _YAML_OK:
        try:
            result = _yaml.safe_load(raw)
            return result if isinstance(result, dict) else {}
        except Exception:
            pass
    out: dict = {}
    for line in raw.splitlines():
        if ":" in line:
            k, _, v = line.partition(":")
            out[k.strip()] = v.strip()
    return out


def _normalize_tags(raw) -> list[str]:
    if not raw:
        return []
    if isinstance(raw, str):
        return [t.strip().lstrip("#") for t in re.split(r"[,\s]+", raw) if t.strip()]
    if isinstance(raw, list):
        return [str(item).strip().lstrip("#") for item in raw if item]
    return []


def _extract_structured(fm: dict) -> tuple[str, str, str, str]:
    """Return (note_type, priority, due_date, status) from frontmatter."""
    note_type = str(fm.get("type", fm.get("note_type", ""))).strip().lower()
    if note_type not in _NOTE_TYPES:
        note_type = ""

    priority = str(fm.get("priority", "")).strip().lower()
    if priority not in _PRIORITIES:
        priority = ""

    due_date = str(fm.get("due_date", fm.get("due", fm.get("deadline", "")))).strip()
    # Basic sanity check: looks like a date
    if not re.match(r"^\d{4}-\d{2}-\d{2}", due_date):
        due_date = ""

    status = str(fm.get("status", fm.get("state", ""))).strip().lower()
    if status not in _STATUSES:
        status = ""

    return note_type, priority, due_date, status


# ── public ────────────────────────────────────────────────────────────────────

def parse_note(path: Path) -> ObsidianNote:
    """Parse an Obsidian markdown file into a structured ObsidianNote."""
    raw = path.read_text(encoding="utf-8", errors="replace")

    # ── frontmatter ──
    frontmatter: dict = {}
    body_text = raw
    m = _FRONTMATTER_RE.match(raw)
    if m:
        frontmatter = _parse_yaml(m.group(1))
        body_text = raw[m.end():]

    # ── structured fields ──
    note_type, priority, due_date, status = _extract_structured(frontmatter)

    # ── tags ──
    tags = _normalize_tags(frontmatter.get("tags") or frontmatter.get("tag"))
    for inline in _INLINE_TAG_RE.findall(body_text):
        t = inline.lstrip("#")
        if t not in tags:
            tags.append(t)

    # ── wikilinks ──
    wikilinks = [wm.group(1).strip() for wm in _WIKILINK_RE.finditer(body_text)]

    # ── clean body ──
    clean = _EMBED_RE.sub("", body_text)
    clean = _WIKILINK_RE.sub(
        lambda wm: (wm.group(2).lstrip("|") if wm.group(2) else wm.group(1)), clean
    )
    clean = clean.strip()

    # ── title ──
    title = (
        str(frontmatter.get("title", "")).strip()
        or _first_h1(clean)
        or path.stem
    )

    return ObsidianNote(
        path=path,
        title=title,
        body=clean,
        raw_content=raw,
        tags=tags,
        frontmatter=frontmatter,
        wikilinks=wikilinks,
        note_type=note_type,
        priority=priority,
        due_date=due_date,
        status=status,
    )


def _first_h1(text: str) -> str:
    m = _H1_RE.search(text)
    return m.group(1).strip() if m else ""
