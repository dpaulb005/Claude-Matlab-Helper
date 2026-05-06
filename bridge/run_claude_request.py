#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

BRIDGE_DIR = Path(__file__).resolve().parent
PROJECT_DIR = BRIDGE_DIR.parent
if str(PROJECT_DIR) not in sys.path:
    sys.path.insert(0, str(PROJECT_DIR))

from bridge.claude_client import DEFAULT_MODEL, call_claude, ensure_api_key
from bridge.env_utils import load_dotenv


def _write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload), encoding="utf-8")


def _run_healthcheck(output_path: Path) -> int:
    load_dotenv()
    try:
        ensure_api_key()
        import anthropic  # noqa: F401
    except Exception as exc:
        _write_json(output_path, {"ok": False, "error": str(exc)})
        return 1

    _write_json(
        output_path,
        {
            "ok": True,
            "service": "matlab-code-assist-direct",
            "projectDir": str(PROJECT_DIR),
        },
    )
    return 0


def _run_generate(input_path: Path, output_path: Path) -> int:
    load_dotenv()
    try:
        ensure_api_key()
        data = json.loads(input_path.read_text(encoding="utf-8"))
        payload = data.get("payload", {})
        model = data.get("model") or DEFAULT_MODEL
        code = call_claude(payload, model)
    except Exception as exc:
        _write_json(output_path, {"ok": False, "error": str(exc)})
        return 1

    _write_json(output_path, {"ok": True, "model": model, "code": code})
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", dest="input_path")
    parser.add_argument("--output", dest="output_path", required=True)
    parser.add_argument("--healthcheck", action="store_true")
    args = parser.parse_args()

    output_path = Path(args.output_path).resolve()

    if args.healthcheck:
        return _run_healthcheck(output_path)
    if not args.input_path:
        _write_json(output_path, {"ok": False, "error": "--input is required unless --healthcheck is used."})
        return 1
    return _run_generate(Path(args.input_path).resolve(), output_path)


if __name__ == "__main__":
    raise SystemExit(main())
