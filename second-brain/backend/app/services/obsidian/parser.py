"""
Obsidian markdown parser.

Understands:
  - YAML frontmatter (title, tags, date, aliases, …)
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


@dataclass
class ObsidianNote:
    path: Path
    title: str
    body: str           # clean text for indexing (frontmatter stripped, wikilinks resolved)
    raw_content: str
    tags: list[str] = field(default_factory=list)
    frontmatter: dict = field(default_factory=dict)
    wikilinks: list[str] = field(default_factory=list)


# ── frontmatter ───────────────────────────────────────────────────────────────

def _parse_yaml(raw: str) -> dict:
    if _YAML_OK:
        try:
            result = _yaml.safe_load(raw)
            return result if isinstance(result, dict) else {}
        except Exception:
            pass
    # fallback: simple key: value (no nesting)
    out: dict = {}
    for line in raw.splitlines():
        if ":" in line:
            k, _, v = line.partition(":")
            out[k.strip()] = v.strip()
    return out


def _normalize_tags(raw) -> list[str]:
    """Accept tags in any YAML form and return a flat list of lowercase strings."""
    if not raw:
        return []
    if isinstance(raw, str):
        return [t.strip().lstrip("#") for t in re.split(r"[,\s]+", raw) if t.strip()]
    if isinstance(raw, list):
        out = []
        for item in raw:
            if isinstance(item, str):
                out.append(item.strip().lstrip("#"))
        return out
    return []


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

    # ── tags ──
    tags = _normalize_tags(frontmatter.get("tags") or frontmatter.get("tag"))
    for inline in _INLINE_TAG_RE.findall(body_text):
        t = inline.lstrip("#")
        if t not in tags:
            tags.append(t)

    # ── wikilinks ──
    wikilinks = [m.group(1).strip() for m in _WIKILINK_RE.finditer(body_text)]

    # ── clean body for indexing ──
    clean = _EMBED_RE.sub("", body_text)
    # resolve wikilinks: [[Note|Display]] → Display, [[Note]] → Note
    clean = _WIKILINK_RE.sub(
        lambda m: (m.group(2).lstrip("|") if m.group(2) else m.group(1)), clean
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
    )


def _first_h1(text: str) -> str:
    m = _H1_RE.search(text)
    return m.group(1).strip() if m else ""
