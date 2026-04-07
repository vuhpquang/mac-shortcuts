#!/bin/bash
# Usage: bash scripts/ask_human.sh "question" <project_name>
# PROJECT_NAME can also be set as an env var.

QUESTION="$1"
PROJECT_NAME="${2:-$PROJECT_NAME}"

if [ -z "$PROJECT_NAME" ]; then
  echo "Error: project_name required as 2nd arg or PROJECT_NAME env var"
  exit 1
fi

STATE_FILE="blackboard/$PROJECT_NAME/state.json"

if [ ! -f "$STATE_FILE" ]; then
  echo "Error: state file not found at $STATE_FILE"
  exit 1
fi

echo ""
echo "╔══════════════════════════════════════╗"
echo "║  STAKEHOLDER INPUT REQUIRED          ║"
echo "╚══════════════════════════════════════╝"
echo "Project: $PROJECT_NAME"
echo "Question: $QUESTION"
echo ""
read -p "Your answer: " ANSWER
node -e "
const fs = require('fs');
const bb = JSON.parse(fs.readFileSync(process.argv[1]));
bb.decisions.push({ question: process.argv[2], answer: process.argv[3], timestamp: Date.now() });
bb.stakeholder_queue = [];
fs.writeFileSync(process.argv[1], JSON.stringify(bb, null, 2));
" "$STATE_FILE" "$QUESTION" "$ANSWER"
echo "$ANSWER"
