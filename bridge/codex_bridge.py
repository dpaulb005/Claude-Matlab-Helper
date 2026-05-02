#!/usr/bin/env python3

import json
import os
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import anthropic

HOST = "127.0.0.1"
PORT = 8765
DEFAULT_MODEL = "claude-opus-4-7"
PROJECT_DIR = Path(__file__).resolve().parent.parent
NOTES_MANIFEST = PROJECT_DIR / "notes" / "manifest.json"
STOPWORDS = {
    "a", "an", "and", "are", "as", "at", "be", "by", "do", "for", "from", "how",
    "i", "if", "in", "is", "it", "of", "on", "or", "s", "show", "solve", "system",
    "systems", "that", "the", "this", "to", "use", "what", "with", "write", "you"
}

_client = None


def _get_client():
    global _client
    if _client is None:
        _client = anthropic.Anthropic()
    return _client


class ClaudeBridgeHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.write_json(200, {"ok": True, "service": "matlab-code-assist-bridge"})
            return

        self.write_json(404, {"error": "Not found."})

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_common_headers()
        self.end_headers()

    def do_POST(self):
        if self.path != "/generate":
            self.write_json(404, {"error": "Not found."})
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
            body = self.rfile.read(length)
            data = json.loads(body.decode("utf-8"))
            payload = data.get("payload", {})
            model = data.get("model") or DEFAULT_MODEL
            code = call_claude(payload, model)
            self.write_json(200, {"ok": True, "model": model, "code": code})
        except anthropic.APIStatusError as exc:
            self.write_json(500, {"error": f"Claude API error: {exc.message}"})
        except Exception as exc:
            self.write_json(500, {"error": str(exc)})

    def log_message(self, _format, *_args):
        return

    def send_common_headers(self):
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")

    def write_json(self, status_code, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status_code)
        self.send_common_headers()
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def call_claude(payload, model):
    target = (payload.get("target") or "command").lower()

    if target == "editor":
        behavior = "\n".join([
            "Return MATLAB code only.",
            "Do not use markdown fences.",
            "Do not explain the code.",
            "If editing a selection, return only the replacement code for that selection.",
        ])
    else:
        behavior = "\n".join([
            "Answer the user's question directly and very concisely.",
            "Be short and to the point.",
            "When useful, include a small MATLAB snippet or command to back up the answer.",
            "Prefer plain text with optional short MATLAB code.",
            "Do not use markdown fences.",
        ])

    system_prompt = "\n".join([
        "You are a MATLAB study assistant.",
        "You are especially strong at Signals and Systems.",
        behavior,
        "Use the provided course notes when they are relevant.",
        "Keep continuity with the current problem context when one is active.",
        "Only use base MATLAB and the Symbolic Math Toolbox (syms, laplace, ilaplace, fourier, ifourier, solve, simplify, etc.).",
        "Do NOT use the Control System Toolbox (tf, bode, step, zpkdata, etc.) or any other optional toolbox.",
        "If a task would normally use tf() or bode(), implement it using symbolic or numeric methods instead.",
    ])

    editor = payload.get("editor") or {}
    file_name = editor.get("fileName") or "untitled.m"
    file_code = editor.get("code") or ""
    selected_code = editor.get("selectedCode") or ""
    command_window = payload.get("commandWindow") or ""
    problem_label = payload.get("problemLabel")
    problem_context = payload.get("problemContext") or ""
    request = payload.get("request") or ""
    notes_context = build_notes_context(request)

    user_message = "\n".join([
        "Current active problem context:",
        format_problem_context(problem_label),
        "",
        "Relevant prior problem history:",
        problem_context or "(no saved problem history available)",
        "",
        "Relevant course notes:",
        notes_context,
        "",
        f"Active MATLAB file: {file_name}",
        "",
        "User request:",
        request,
        "",
        "Selected code:",
        selected_code or "(no selection)",
        "",
        "Current file contents:",
        file_code or "(empty file)",
        "",
        "Recent Command Window context:",
        command_window or "(unavailable)",
    ])

    response = _get_client().messages.create(
        model=model,
        max_tokens=8192,
        system=system_prompt,
        messages=[{"role": "user", "content": user_message}],
    )

    text_blocks = [b.text for b in response.content if b.type == "text"]
    output = "\n".join(text_blocks).strip()

    if not output:
        raise RuntimeError("Claude returned an empty response.")
    return output


def format_problem_context(problem_label):
    if problem_label in (None, "", []):
        return "(no active problem selected)"
    return (
        f"Problem {problem_label}. Keep the answer scoped to this problem and its "
        "follow-up parts unless the user switches to a different problem."
    )


def build_notes_context(request):
    manifest = load_notes_manifest()
    if not manifest:
        return "(no local course notes loaded)"

    query_terms = extract_terms(request)
    scored = []
    for document in manifest.get("documents", []):
        for chunk in document.get("chunks", []):
            score = score_chunk(chunk.get("text", ""), query_terms)
            if score > 0:
                scored.append((score, document.get("title", "notes"), chunk))

    scored.sort(key=lambda item: item[0], reverse=True)
    top_chunks = scored[:4]
    if not top_chunks:
        return "(local course notes available, but no strongly matching chunk was found)"

    parts = []
    for _score, title, chunk in top_chunks:
        parts.append(
            f"[{title}, page {chunk.get('page', '?')}]\n{chunk.get('text', '')[:1800].strip()}"
        )
    return "\n\n---\n\n".join(parts)


def load_notes_manifest():
    if not NOTES_MANIFEST.exists():
        return None
    with NOTES_MANIFEST.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def extract_terms(text):
    words = re.findall(r"[A-Za-z0-9_]+", (text or "").lower())
    return [word for word in words if word not in STOPWORDS and len(word) > 2]


def score_chunk(text, query_terms):
    if not text or not query_terms:
        return 0

    haystack = text.lower()
    score = 0
    for term in query_terms:
        score += haystack.count(term)

    signals_terms = {
        "fourier", "laplace", "convolution", "sampling", "transfer", "frequency",
        "response", "lti", "impulse", "step", "pole", "zero", "ztransform",
        "stability", "system", "signal"
    }
    if any(term in signals_terms for term in query_terms):
        for term in signals_terms:
            if term in haystack:
                score += 1

    return score


def main():
    ThreadingHTTPServer.allow_reuse_address = True
    server = ThreadingHTTPServer((HOST, PORT), ClaudeBridgeHandler)
    print(f"MATLAB Code Assist bridge listening on http://{HOST}:{PORT}")
    server.serve_forever()


if __name__ == "__main__":
    main()
