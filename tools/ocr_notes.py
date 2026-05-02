#!/usr/bin/env python3

from pathlib import Path
import tempfile

import fitz
from Foundation import NSURL
from Quartz import CIImage
from Vision import VNImageRequestHandler, VNRecognizeTextRequest


def render_page(pdf_path: Path, page_index: int, dpi: int = 220) -> Path:
    doc = fitz.open(pdf_path)
    page = doc.load_page(page_index)
    zoom = dpi / 72.0
    pix = page.get_pixmap(matrix=fitz.Matrix(zoom, zoom), alpha=False)
    out_path = Path(tempfile.gettempdir()) / f"{pdf_path.stem}_page_{page_index+1}.png"
    pix.save(out_path)
    return out_path


def recognize_text(image_path: Path) -> str:
    url = NSURL.fileURLWithPath_(str(image_path))
    ci_image = CIImage.imageWithContentsOfURL_(url)
    request = VNRecognizeTextRequest.alloc().init()
    request.setRecognitionLevel_(1)
    request.setUsesLanguageCorrection_(True)
    handler = VNImageRequestHandler.alloc().initWithCIImage_options_(ci_image, None)
    success, error = handler.performRequests_error_([request], None)
    if not success:
        raise RuntimeError(str(error))

    observations = request.results() or []
    lines = []
    for observation in observations:
        candidates = observation.topCandidates_(1)
        if candidates:
            lines.append(str(candidates[0].string()))
    return "\n".join(lines)


if __name__ == "__main__":
    pdf = Path("notes/raw/EE350 Lectures/EE 350 S26 Lecture 23.pdf")
    image = render_page(pdf, 0)
    text = recognize_text(image)
    print(text[:4000])
