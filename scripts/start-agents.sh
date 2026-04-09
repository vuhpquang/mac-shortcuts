#!/bin/bash
# start-agents.sh — launch all 6 agent sessions with their roles pre-loaded

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

# name:port
AGENTS=(
  "researcher:7681"
  "design:7682"
  "techlead:7683"
  "dev:7684"
  "qc:7685"
)
RELAY_PORT=7690

# ── Kill stale ttyd/relay on all ports ─────────────────────────────
for entry in "${AGENTS[@]}"; do
  PORT="${entry#*:}"; PORT="${PORT%%:*}"
  lsof -ti ":$PORT" | xargs kill -9 2>/dev/null || true
done
lsof -ti ":$RELAY_PORT" | xargs kill -9 2>/dev/null || true

# ── Launch each agent ───────────────────────────────────────────────
for entry in "${AGENTS[@]}"; do
  IFS=: read -r NAME PORT <<< "$entry"
  LAUNCHER="/tmp/agent-${NAME}.sh"

  # Write launcher: start idle, no --agent flag so Claude waits for user input
  {
    echo '#!/bin/bash'
    echo "cd $(printf '%q' "$ROOT")"
    echo "exec claude --dangerously-skip-permissions"
  } > "$LAUNCHER"
  chmod +x "$LAUNCHER"

  # Create session if missing; start claude if not already running in the session
  if ! tmux has-session -t "$NAME" 2>/dev/null; then
    tmux new-session -s "$NAME" -d -c "$ROOT"
    tmux send-keys -t "$NAME" "$LAUNCHER" Enter
    echo "Started $NAME (port $PORT)"
  else
    # Session exists — check if claude is the active process; restart if not
    ACTIVE=$(tmux list-panes -t "$NAME" -F '#{pane_current_command}' 2>/dev/null | head -1)
    if [[ "$ACTIVE" != "node" ]]; then
      tmux send-keys -t "$NAME" "" ""   # clear any half-typed input
      tmux send-keys -t "$NAME" "$LAUNCHER" Enter
      echo "Restarted claude in $NAME (port $PORT, was: $ACTIVE)"
    else
      echo "Reused $NAME (port $PORT, claude already running)"
    fi
  fi

  # Expose via ttyd
  ttyd -p "$PORT" --writable tmux attach -t "$NAME" &
done

# ── Tiled overview session (local: tmux attach -t agents) ───────────
if ! tmux has-session -t agents 2>/dev/null; then
  tmux new-session -s agents -d -x 240 -y 60
  for _ in $(seq 1 5); do
    tmux split-window -t agents
  done
  tmux select-layout -t agents tiled
  echo "Created agents tiled overview (tmux attach -t agents)"
fi

# ── Chat relay server — POST /send → tmux send-keys ────────────────
RELAY_SCRIPT=/tmp/agent_relay.py
cat > "$RELAY_SCRIPT" <<'PYEOF'
from http.server import HTTPServer, BaseHTTPRequestHandler
import json, subprocess, sys

VALID = {'researcher', 'design', 'techlead', 'dev', 'qc'}

class H(BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')

    def do_OPTIONS(self):
        self.send_response(200); self._cors(); self.end_headers()

    def do_POST(self):
        if self.path == '/send':
            n = int(self.headers.get('Content-Length', 0))
            try: body = json.loads(self.rfile.read(n))
            except Exception: body = {}
            agent   = body.get('agent', '')
            message = body.get('message', '')
            targets = list(VALID) if agent == 'all' else ([agent] if agent in VALID else [])
            for t in targets:
                subprocess.run(['tmux', 'send-keys', '-t', t, message, 'Enter'])
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self._cors(); self.end_headers()
        self.wfile.write(b'{"ok":true}')

    def log_message(self, *_): pass

port = int(sys.argv[1]) if len(sys.argv) > 1 else 7690
HTTPServer(('localhost', port), H).serve_forever()
PYEOF

python3 "$RELAY_SCRIPT" "$RELAY_PORT" &
echo "Chat relay on port $RELAY_PORT"
echo ""
echo "  Ports: researcher=7681  design=7682  techlead=7683  dev=7684  qc=7685"
echo "  Relay: $RELAY_PORT"
echo "  Local view: tmux attach -t agents"
