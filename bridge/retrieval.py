from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

PROJECT_DIR = Path(__file__).resolve().parent.parent
NOTES_MANIFEST = PROJECT_DIR / "notes" / "manifest.json"
STOPWORDS = {
    "a", "an", "and", "are", "as", "at", "be", "by", "do", "for", "from", "how",
    "i", "if", "in", "is", "it", "of", "on", "or", "s", "show", "solve", "system",
    "systems", "that", "the", "this", "to", "use", "what", "with", "write", "you"
}
SIGNALS_TERMS = {
    "fourier", "laplace", "convolution", "sampling", "transfer", "frequency",
    "response", "lti", "impulse", "step", "pole", "zero", "ztransform",
    "stability", "system", "signal", "aliasing", "nyquist", "harmonic"
}


def load_notes_manifest(path: Path = NOTES_MANIFEST) -> dict[str, Any] | None:
    if not path.exists():
        return None
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def extract_terms(text: str) -> list[str]:
    words = re.findall(r"[A-Za-z0-9_]+", (text or "").lower())
    return [word for word in words if word not in STOPWORDS and len(word) > 2]


def score_chunk(text: str, query_terms: list[str]) -> int:
    if not text or not query_terms:
        return 0

    haystack = text.lower()
    score = 0
    for term in query_terms:
        score += haystack.count(term)
        if term in SIGNALS_TERMS and term in haystack:
            score += 1
    return score


def build_notes_context(request: str, manifest: dict[str, Any] | None = None, max_chunks: int = 4) -> str:
    manifest = manifest if manifest is not None else load_notes_manifest()
    if not manifest:
        return "(no local course notes loaded)"

    query_terms = extract_terms(request)
    scored: list[tuple[int, str, dict[str, Any]]] = []
    for document in manifest.get("documents", []):
        title = document.get("title", "notes")
        for chunk in document.get("chunks", []):
            text = chunk.get("text", "")
            score = score_chunk(text, query_terms)
            if score > 0:
                scored.append((score, title, chunk))

    scored.sort(key=lambda item: item[0], reverse=True)
    top_chunks = scored[:max_chunks]
    if not top_chunks:
        return "(local course notes available, but no strongly matching chunk was found)"

    parts = []
    for _score, title, chunk in top_chunks:
        snippet = chunk.get("text", "")[:1800].strip()
        parts.append(f"[{title}, page {chunk.get('page', '?')}]\n{snippet}")
    return "\n\n---\n\n".join(parts)
