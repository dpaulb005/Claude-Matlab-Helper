#!/usr/bin/env python3

import json
import re
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
NOTES_DIR = PROJECT_DIR / "notes"


def main():
    cleaned_dir = NOTES_DIR / "cleaned"
    text_dir = NOTES_DIR / "text"
    source_dir = cleaned_dir if cleaned_dir.exists() else text_dir
    manifest_path = NOTES_DIR / "manifest.json"

    manifest = {"documents": []}
    for text_path in sorted(source_dir.rglob("*.txt")):
        relative = text_path.relative_to(source_dir)
        title = text_path.stem
        text = normalize_text(text_path.read_text(encoding="utf-8", errors="ignore"))
        chunks = build_chunks(title, text)
        manifest["documents"].append({
            "text": str(text_path.relative_to(PROJECT_DIR)),
            "title": title,
            "pages": estimate_pages(text),
            "chunks": chunks,
        })

    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Wrote {manifest_path} from {source_dir}")


def build_chunks(title: str, text: str):
    paragraphs = split_paragraphs(text)
    chunks = []
    current = []
    current_len = 0
    chunk_index = 0

    for paragraph in paragraphs:
        if current_len + len(paragraph) > 1600 and current:
            chunks.append(make_chunk(title, chunk_index, current))
            chunk_index += 1
            current = []
            current_len = 0

        current.append(paragraph)
        current_len += len(paragraph)

    if current:
        chunks.append(make_chunk(title, chunk_index, current))

    return chunks


def make_chunk(title: str, index: int, paragraphs):
    text = "\n\n".join(paragraphs).strip()
    page_matches = re.findall(r"Page\s+(\d+(?:\.\d+)?)", text, flags=re.IGNORECASE)
    page = page_matches[0] if page_matches else "?"
    return {
        "id": f"{title}-c{index}",
        "page": page,
        "text": text,
    }


def split_paragraphs(text: str):
    parts = re.split(r"\n\s*\n", text)
    return [normalize_text(part) for part in parts if normalize_text(part)]


def estimate_pages(text: str):
    return len(re.findall(r"Page\s+\d+(?:\.\d+)?", text, flags=re.IGNORECASE)) or 1


def normalize_text(text: str):
    text = text.replace("\x00", " ")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


if __name__ == "__main__":
    main()
