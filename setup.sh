#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "${GREEN}  [OK]${NC} $1"; }
fail() { echo -e "${RED}  [FAIL]${NC} $1"; }
info() { echo -e "  ${YELLOW}--${NC} $1"; }

echo ""
echo -e "${BOLD}======================================${NC}"
echo -e "${BOLD}   MATLAB Code Assist  —  Setup${NC}"
echo -e "${BOLD}======================================${NC}"
echo ""

# ── 1. Python ────────────────────────────────────────────────
PY=""
for candidate in python3 python; do
    if command -v "$candidate" &>/dev/null; then
        version=$("$candidate" --version 2>&1)
        if echo "$version" | grep -q "Python 3"; then
            PY="$candidate"
            break
        fi
    fi
done

if [ -z "$PY" ]; then
    fail "Python 3 not found. Install from https://www.python.org/downloads/"
    exit 1
fi
ok "Python found: $($PY --version)"

# ── 2. Dependencies ───────────────────────────────────────────
echo ""
info "Installing Python dependencies..."
if "$PY" -m pip install -r requirements.txt -q --disable-pip-version-check; then
    ok "Dependencies installed (anthropic, pymupdf, pypdf)"
else
    fail "pip install failed. Try: $PY -m pip install -r requirements.txt"
    exit 1
fi

# ── 3. API Key ────────────────────────────────────────────────
echo ""
KEY_ALREADY_SET=0
if [ -f ".env" ] && grep -q "ANTHROPIC_API_KEY=sk-ant-" ".env" 2>/dev/null; then
    ok "API key already set in .env"
    KEY_ALREADY_SET=1
elif [ -n "$ANTHROPIC_API_KEY" ]; then
    ok "API key found in environment"
    KEY_ALREADY_SET=1
fi

if [ "$KEY_ALREADY_SET" -eq 0 ]; then
    echo ""
    echo -e "  Get your key from: ${BOLD}https://console.anthropic.com/${NC}"
    echo -n "  Enter ANTHROPIC_API_KEY: "
    read -s ENTERED_KEY
    echo ""
    if [ -z "$ENTERED_KEY" ]; then
        fail "No API key entered."
        exit 1
    fi
    if ! echo "$ENTERED_KEY" | grep -q "^sk-"; then
        fail "Key doesn't look right — Anthropic keys start with 'sk-'"
        exit 1
    fi
    echo "ANTHROPIC_API_KEY=$ENTERED_KEY" > .env
    ok "API key saved to .env"
fi

# ── 4. Stop any existing bridge ───────────────────────────────
echo ""
EXISTING_PIDS=$(lsof -ti:8765 2>/dev/null)
if [ -n "$EXISTING_PIDS" ]; then
    info "Stopping existing process on port 8765..."
    echo "$EXISTING_PIDS" | xargs kill -9 2>/dev/null
    # Wait until the port is actually free (up to 5s)
    for i in $(seq 1 10); do
        sleep 0.5
        lsof -ti:8765 &>/dev/null || break
    done
fi

# ── 5. Start bridge ───────────────────────────────────────────
LOG_FILE="/tmp/matlab-code-assist-bridge.log"
info "Starting bridge..."
"$PY" bridge/start_bridge.py > "$LOG_FILE" 2>&1 &
BRIDGE_PID=$!
sleep 3

# ── 6. Health check ───────────────────────────────────────────
info "Testing connection..."
RESPONSE=$(curl -s --max-time 4 http://127.0.0.1:8765/health 2>/dev/null)
if echo "$RESPONSE" | grep -q '"ok"'; then
    ok "Bridge is running  (PID $BRIDGE_PID  |  log: $LOG_FILE)"
else
    fail "Bridge did not respond."
    echo ""
    echo "  Log output:"
    cat "$LOG_FILE" | sed 's/^/    /'
    kill "$BRIDGE_PID" 2>/dev/null
    exit 1
fi

# ── 7. Done ───────────────────────────────────────────────────
echo ""
echo -e "${BOLD}======================================${NC}"
echo -e "${GREEN}${BOLD}   Setup complete!${NC}"
echo -e "${BOLD}======================================${NC}"
echo ""
echo -e "  Next steps in MATLAB:"
echo -e "    1. Run: ${BOLD}matlab_code_assist_setup${NC}"
echo -e "    2. Try: ${BOLD}lrn(\"What is the Laplace transform of a unit step?\")${NC}"
echo ""
echo -e "  To restart the bridge later:"
echo -e "    ${BOLD}python3 bridge/start_bridge.py${NC}"
echo ""
