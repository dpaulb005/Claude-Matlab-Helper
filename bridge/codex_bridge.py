#!/usr/bin/env python3

import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
if str(PROJECT_DIR) not in sys.path:
    sys.path.insert(0, str(PROJECT_DIR))

import anthropic

from bridge.prompt_templates import build_system_prompt, build_user_message
from bridge.retrieval import build_notes_context

HOST = "127.0.0.1"
PORT = 8765
DEFAULT_MODEL = "claude-opus-4-7"

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
    system_prompt, _settings = build_system_prompt(payload)
    notes_context = build_notes_context(payload.get("request") or "")
    user_message = build_user_message(payload, notes_context)

    response = _get_client().messages.create(
        model=model,
        max_tokens=8192,
        system=system_prompt,
        messages=[{"role": "user", "content": user_message}],
    )

    text_blocks = [block.text for block in response.content if block.type == "text"]
    output = "\n".join(text_blocks).strip()

    if not output:
        raise RuntimeError("Claude returned an empty response.")
    return output


def main():
    ThreadingHTTPServer.allow_reuse_address = True
    server = ThreadingHTTPServer((HOST, PORT), ClaudeBridgeHandler)
    print(f"MATLAB Code Assist bridge listening on http://{HOST}:{PORT}")
    server.serve_forever()


if __name__ == "__main__":
    main()
