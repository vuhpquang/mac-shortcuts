#!/bin/bash
# start.sh — one command to launch everything
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_PORT=8000
DASHBOARD_URL="http://localhost:${DASHBOARD_PORT}/dashboard/"

# ── 1. Start agents ─────────────────────────────────────────────────
echo "Starting agents..."
bash "$ROOT/scripts/start-agents.sh"

# ── 2. Start blackboard HTTP server ─────────────────────────────────
echo ""
echo "Starting blackboard server on port $DASHBOARD_PORT..."

# Kill any existing server on that port
lsof -ti ":$DASHBOARD_PORT" | xargs kill -9 2>/dev/null || true

cd "$ROOT/blackboard"
python3 -m http.server "$DASHBOARD_PORT" &
BB_PID=$!
cd "$ROOT"

# Wait until the server is ready
for i in $(seq 1 20); do
  curl -sf "http://localhost:$DASHBOARD_PORT/" -o /dev/null 2>/dev/null && break
  sleep 0.3
done

echo "Blackboard ready at $DASHBOARD_URL"

# ── 3. Open browser ──────────────────────────────────────────────────
echo "Opening browser..."
if command -v open &>/dev/null; then
  open "$DASHBOARD_URL"                   # macOS
elif command -v xdg-open &>/dev/null; then
  xdg-open "$DASHBOARD_URL"              # Linux
elif command -v start &>/dev/null; then
  start "$DASHBOARD_URL"                 # Windows (Git Bash)
fi

echo ""
echo "  Dashboard : $DASHBOARD_URL"
echo "  Agents    : po=7681  pm=7682  design=7683  techlead=7684  dev=7685  qc=7686"
echo "  Relay     : 7690"
echo "  Blackboard PID: $BB_PID (kill $BB_PID to stop server)"
echo ""
echo "Press Ctrl+C to stop the blackboard server (agents keep running in tmux)"

# Keep server in foreground so Ctrl+C kills it cleanly
wait $BB_PID
