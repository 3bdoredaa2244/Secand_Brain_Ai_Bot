"""
VaultGraph — in-memory directed graph of Obsidian [[wikilink]] relationships.

Rebuilt on every full sync; incrementally updated on single-file sync/remove.
No persistence required — ChromaDB holds the content; this holds the edges.

Nodes are forward-slash relative paths (same key as metadata["source"]).
"""
from collections import defaultdict

from app.core.logging import get_logger

logger = get_logger(__name__)


class VaultGraph:
    def __init__(self) -> None:
        # out-edges: source → {targets}  (links this note makes)
        self._out: dict[str, set[str]] = defaultdict(set)
        # in-edges:  target → {sources}  (notes that link TO this note = backlinks)
        self._in: dict[str, set[str]] = defaultdict(set)

    # ── write ─────────────────────────────────────────────────────────────────

    def update(self, source: str, links: list[str]) -> None:
        """Set the outgoing links for *source*, removing any stale edges first."""
        # Remove stale out-edges from this source
        for old_target in self._out.get(source, set()):
            self._in[old_target].discard(source)

        self._out[source] = set(links)
        for target in links:
            self._in[target].add(source)

    def remove(self, source: str) -> None:
        """Remove a note and all its edges when the file is deleted."""
        for target in self._out.pop(source, set()):
            self._in[target].discard(source)
        # Also remove this note as a target (dangling backlinks cleanup)
        self._in.pop(source, None)

    def clear(self) -> None:
        self._out.clear()
        self._in.clear()

    # ── read ──────────────────────────────────────────────────────────────────

    def get_links(self, source: str) -> list[str]:
        """Notes that *source* links to."""
        return sorted(self._out.get(source, set()))

    def get_backlinks(self, target: str) -> list[str]:
        """Notes that link TO *target*."""
        return sorted(self._in.get(target, set()))

    def get_related(self, source: str, depth: int = 1) -> list[str]:
        """BFS up to *depth* hops away from *source* (following out-edges)."""
        visited: set[str] = set()
        frontier: set[str] = {source}
        for _ in range(depth):
            next_frontier: set[str] = set()
            for node in frontier:
                for link in self._out.get(node, set()):
                    if link not in visited:
                        next_frontier.add(link)
            visited |= frontier
            frontier = next_frontier - visited
        visited.discard(source)
        return sorted(visited)

    # ── stats ─────────────────────────────────────────────────────────────────

    @property
    def node_count(self) -> int:
        return len(self._out)

    @property
    def edge_count(self) -> int:
        return sum(len(v) for v in self._out.values())

    def summary(self) -> dict:
        return {
            "nodes": self.node_count,
            "edges": self.edge_count,
            "most_linked": self._most_linked(5),
        }

    def _most_linked(self, n: int) -> list[dict]:
        ranked = sorted(self._in.items(), key=lambda kv: len(kv[1]), reverse=True)
        return [{"note": k, "backlinks": len(v)} for k, v in ranked[:n]]


graph = VaultGraph()  # singleton — rebuilt by ObsidianSync
