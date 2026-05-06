#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
info() { echo -e "${YELLOW}[INFO]${NC} $1"; }

HEALTHCHECK_OUT="$(mktemp /tmp/matlab-code-assist-health.XXXXXX.json)"
trap 'rm -f "$HEALTHCHECK_OUT"' EXIT

echo
echo -e "${BOLD}======================================${NC}"
echo -e "${BOLD}   Claude MATLAB Helper — Setup${NC}"
echo -e "${BOLD}======================================${NC}"
echo

PY=""
for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
        version=$("$candidate" --version 2>&1 || true)
        if echo "$version" | grep -q "Python 3"; then
            PY="$candidate"
            break
        fi
    fi
done

if [ -z "$PY" ]; then
    fail "Python 3 not found. Install it from https://www.python.org/downloads/."
    exit 1
fi
ok "Python found: $($PY --version 2>&1)"

if [ ! -d ".venv" ]; then
    info "Creating local virtual environment..."
    "$PY" -m venv .venv
fi

VENV_PY=".venv/bin/python"
if [ ! -x "$VENV_PY" ]; then
    fail "Expected virtualenv Python at $VENV_PY"
    exit 1
fi
ok "Using local virtual environment: .venv"

info "Installing Python dependencies..."
"$VENV_PY" -m pip install --upgrade pip --disable-pip-version-check >/dev/null
"$VENV_PY" -m pip install -r requirements.txt --disable-pip-version-check
ok "Python dependencies installed."

if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    ok "Using ANTHROPIC_API_KEY from the current environment."
elif [ -f ".env" ] && grep -q '^ANTHROPIC_API_KEY=' .env 2>/dev/null; then
    ok "Found ANTHROPIC_API_KEY in .env"
else
    echo
    echo "Get your Claude API key from: https://console.anthropic.com/"
    read -r -s -p "Enter ANTHROPIC_API_KEY: " ENTERED_KEY
    echo
    if [ -z "$ENTERED_KEY" ]; then
        fail "No API key entered."
        exit 1
    fi
    printf 'ANTHROPIC_API_KEY=%s\n' "$ENTERED_KEY" > .env
    ok "Saved ANTHROPIC_API_KEY to .env"
fi

info "Running direct-mode healthcheck..."
if "$VENV_PY" bridge/run_claude_request.py --healthcheck --output "$HEALTHCHECK_OUT"; then
    ok "Direct local Claude helper is ready."
else
    fail "Direct-mode healthcheck failed."
    if [ -f "$HEALTHCHECK_OUT" ]; then
        cat "$HEALTHCHECK_OUT"
    fi
    exit 1
fi

echo
echo -e "${BOLD}======================================${NC}"
echo -e "${GREEN}${BOLD}   Setup complete!${NC}"
echo -e "${BOLD}======================================${NC}"
echo
echo "Next steps in MATLAB:"
echo "  1. Run: matlab_code_assist_setup"
echo "  2. Try: lrn(\"What is the Laplace transform of a unit step?\")"
echo