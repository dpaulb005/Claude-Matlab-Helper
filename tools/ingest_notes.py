#!/usr/bin/env python3

import json
import re
from pathlib import Path

from pypdf import PdfReader

PROJECT_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_DIR / "notes" / "raw"
TEXT_DIR = PROJECT_DIR / "notes" / "text"
MANIFEST_PATH = PROJECT_DIR / "notes" / "manifest.json"


def main():
    TEXT_DIR.mkdir(parents=True, exist_ok=True)

    manifest = {"documents": []}
    for pdf_path in sorted(RAW_DIR.rglob("*.pdf")):
        try:
            page_records = extract_pdf_text(pdf_path)
        except Exception as exc:
            print(f"Skipping {pdf_path}: {exc}")
            continue
        relative_pdf = pdf_path.relative_to(RAW_DIR)
        text_path = TEXT_DIR / relative_pdf.with_suffix(".txt")
        text_path.parent.mkdir(parents=True, exist_ok=True)
        full_text = "\n\n".join(record["text"] for record in page_records if record["text"].strip())
        text_path.write_text(full_text, encoding="utf-8")

        manifest["documents"].append({
            "pdf": str(pdf_path.relative_to(PROJECT_DIR)),
            "text": str(text_path.relative_to(PROJECT_DIR)),
            "pages": len(page_records),
            "title": pdf_path.stem,
            "chunks": build_chunks(pdf_path.stem, page_records),
        })

    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Wrote {MANIFEST_PATH}")


def extract_pdf_text(pdf_path: Path):
    reader = PdfReader(str(pdf_path))
    page_records = []
    for idx, page in enumerate(reader.pages, start=1):
        text = normalize_text(page.extract_text() or "")
        page_records.append({"page": idx, "text": text})
    return page_records


def build_chunks(title: str, page_records):
    chunks = []
    chunk_index = 0
    for record in page_records:
        paragraphs = split_paragraphs(record["text"])
        if not paragraphs:
            continue

        current = []
        current_len = 0
        for paragraph in paragraphs:
            if current_len + len(paragraph) > 1400 and current:
                chunks.append(make_chunk(title, record["page"], chunk_index, current))
                chunk_index += 1
                current = []
                current_len = 0

            current.append(paragraph)
            current_len += len(paragraph)

        if current:
            chunks.append(make_chunk(title, record["page"], chunk_index, current))
            chunk_index += 1

    return chunks


def make_chunk(title: str, page: int, index: int, paragraphs):
    return {
        "id": f"{title}-p{page}-c{index}",
        "page": page,
        "text": "\n\n".join(paragraphs).strip(),
    }


def split_paragraphs(text: str):
    parts = re.split(r"\n\s*\n", text)
    return [normalize_text(part) for part in parts if normalize_text(part)]


def normalize_text(text: str):
    text = text.replace("\x00", " ")
    text = text.replace("￿", "")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


if __name__ == "__main__":
    main()
