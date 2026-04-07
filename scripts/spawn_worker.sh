#!/bin/bash
# Usage: bash scripts/spawn_worker.sh <task_id> <project_name>
# PROJECT_NAME can also be set as an env var.

TASK_ID=$1
PROJECT_NAME="${2:-$PROJECT_NAME}"

if [ -z "$TASK_ID" ] || [ -z "$PROJECT_NAME" ]; then
  echo "Usage: bash scripts/spawn_worker.sh <task_id> <project_name>"
  exit 1
fi

STATE_FILE="blackboard/$PROJECT_NAME/state.json"

claude --model claude-haiku-4-5-20251001 \
  --dangerously-skip-permissions \
  "Read prompts/worker.md. Your task_id: $TASK_ID. Project: $PROJECT_NAME.
   Read $STATE_FILE for your task only (not blackboard/state.json)."
