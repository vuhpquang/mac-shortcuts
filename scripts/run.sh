#!/bin/bash
# Usage:
#   bash scripts/run.sh <project_name> solo "Project goal"
#   bash scripts/run.sh <project_name> team "Project goal"
#
# Each project has its own isolated blackboard at blackboard/<project_name>/

PROJECT_NAME=$1
MODE=$2
PROJECT_GOAL=$3

if [ -z "$PROJECT_NAME" ] || [ -z "$MODE" ] || [ -z "$PROJECT_GOAL" ]; then
  echo "Usage: bash scripts/run.sh <project_name> <solo|team> \"Project goal\""
  exit 1
fi

BLACKBOARD_DIR="blackboard/$PROJECT_NAME"
CONTEXT_FILE="$BLACKBOARD_DIR/context.md"
STATE_FILE="$BLACKBOARD_DIR/state.json"

if [ ! -d "$BLACKBOARD_DIR" ]; then
  echo "Error: Blackboard not found at $BLACKBOARD_DIR"
  echo "Run: bash scripts/init_project.sh $PROJECT_NAME first"
  exit 1
fi

export PROJECT_NAME
export BLACKBOARD_DIR

if [ "$MODE" = "solo" ]; then
  claude --dangerously-skip-permissions \
    "PROJECT_NAME=$PROJECT_NAME. Read $CONTEXT_FILE. Implement the full project solo, phase by phase.
     Use $STATE_FILE for shared state (not blackboard/state.json).
     Project: $PROJECT_GOAL"
else
  claude --dangerously-skip-permissions \
    "PROJECT_NAME=$PROJECT_NAME. Read run.md and $CONTEXT_FILE.
     Use $STATE_FILE for shared state (not blackboard/state.json).
     Start the software team. Project: $PROJECT_GOAL"
fi
