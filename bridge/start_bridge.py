#!/usr/bin/env python3

import os
import sys
import tempfile
from pathlib import Path

BRIDGE_DIR = Path(__file__).resolve().parent
PROJECT_DIR = BRIDGE_DIR.parent


def _load_dotenv():
    env_path = PROJECT_DIR / ".env"
    if not env_path.exists():
        return
    with env_path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = value


def main():
    _load_dotenv()

    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("ERROR: ANTHROPIC_API_KEY is not set.", file=sys.stderr)
        print("Set it in the environment or create a .env file in the project root.", file=sys.stderr)
        sys.exit(1)

    os.environ.setdefault("PYTHONDONTWRITEBYTECODE", "1")
    pycache_root = Path(tempfile.gettempdir()) / "matlab-code-assist-pycache"
    pycache_root.mkdir(parents=True, exist_ok=True)
    os.environ.setdefault("PYTHONPYCACHEPREFIX", str(pycache_root))

    os.chdir(PROJECT_DIR)
    os.execv(
        sys.executable,
        [
            sys.executable,
            "-B",
            str(BRIDGE_DIR / "codex_bridge.py"),
        ],
    )


if __name__ == "__main__":
    main()
