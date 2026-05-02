#!/usr/bin/env python3

import base64
import subprocess
import sys
from pathlib import Path

import anthropic
import fitz

PROJECT_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_DIR / "notes" / "raw"
CLEAN_DIR = PROJECT_DIR / "notes" / "cleaned"

MODEL = "claude-sonnet-4-6"

_client = None


def _get_client():
    global _client
    if _client is None:
        _client = anthropic.Anthropic()
    return _client


def main():
    CLEAN_DIR.mkdir(parents=True, exist_ok=True)
    pdfs = sorted(RAW_DIR.rglob("*.pdf"))
    for pdf in pdfs:
        relative = pdf.relative_to(RAW_DIR)
        out_path = CLEAN_DIR / relative.with_suffix(".txt")
        out_path.parent.mkdir(parents=True, exist_ok=True)
        print(f"Vision-ingesting {relative} ...")
        text = summarize_pdf(pdf)
        out_path.write_text(text.strip() + "\n", encoding="utf-8")
        print(f"Wrote {out_path}")

    subprocess.run([sys.executable, "tools/build_notes_manifest.py"], cwd=PROJECT_DIR, check=True)


def summarize_pdf(pdf_path: Path) -> str:
    image_paths = render_pdf(pdf_path)

    system_prompt = "\n".join([
        "You are reading Signals and Systems lecture notes.",
        "Produce clean, concise study notes in plain text.",
        "Do not mention OCR.",
        "Do not invent facts that are not visible.",
        "If something is ambiguous, mark it as [unclear].",
        "Prefer a useful study-note structure: Title, Main topics, Key formulas, Important ideas, Worked examples.",
        "Keep formulas readable in plain text.",
    ])

    content = []
    for image_path in image_paths:
        with open(image_path, "rb") as f:
            image_data = base64.standard_b64encode(f.read()).decode("utf-8")
        content.append({
            "type": "image",
            "source": {"type": "base64", "media_type": "image/png", "data": image_data},
        })
    content.append({
        "type": "text",
        "text": f"Source file: {pdf_path.name}\n\nProduce clean study notes from these pages.",
    })

    response = _get_client().messages.create(
        model=MODEL,
        max_tokens=8192,
        system=system_prompt,
        messages=[{"role": "user", "content": content}],
    )
    text_blocks = [b.text for b in response.content if b.type == "text"]
    return "\n".join(text_blocks).strip()


def render_pdf(pdf_path: Path):
    render_dir = PROJECT_DIR / "notes" / "rendered" / pdf_path.relative_to(RAW_DIR).with_suffix("")
    render_dir.mkdir(parents=True, exist_ok=True)

    doc = fitz.open(str(pdf_path))
    image_paths = []
    for idx, page in enumerate(doc, start=1):
        out_path = render_dir / f"page_{idx:03d}.png"
        pix = page.get_pixmap(matrix=fitz.Matrix(2, 2), alpha=False)
        pix.save(out_path)
        image_paths.append(out_path)
    return image_paths


if __name__ == "__main__":
    main()
