#!/bin/bash
# Usage: bash scripts/init_project.sh <project_name>
# Creates the git project submodule AND its isolated blackboard.

PROJECT_NAME=$1

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: bash scripts/init_project.sh <project_name>"
  exit 1
fi

# --- Git project ---
mkdir -p "./projects/$PROJECT_NAME"
cd "./projects/$PROJECT_NAME"
git init
git checkout -b develop
echo "# $PROJECT_NAME" > README.md
git add . && git commit -m "init: $PROJECT_NAME"
cd ../..
git submodule add "./projects/$PROJECT_NAME" "./projects/$PROJECT_NAME"
git commit -m "chore: add $PROJECT_NAME as submodule"

# --- Blackboard namespace ---
BLACKBOARD_DIR="blackboard/$PROJECT_NAME"
mkdir -p "$BLACKBOARD_DIR"

# state.json skeleton
cat > "$BLACKBOARD_DIR/state.json" <<EOF
{
  "project": {
    "id": "$PROJECT_NAME",
    "name": "$PROJECT_NAME",
    "goal": "",
    "status": "init"
  },
  "features": [],
  "tasks": [],
  "architecture": {},
  "design": [],
  "code": [],
  "test_results": [],
  "decisions": [],
  "stakeholder_queue": []
}
EOF

# context.md placeholder
cat > "$BLACKBOARD_DIR/context.md" <<EOF
# Project: $PROJECT_NAME

## Goal
<!-- Describe the project goal here -->

## Tech stack
<!-- List the tech stack -->

## References
<!-- Add relevant links -->
EOF

# Register in projects.json
PROJECTS_FILE="blackboard/projects.json"
if [ -f "$PROJECTS_FILE" ]; then
  node -e "
const fs = require('fs');
const list = JSON.parse(fs.readFileSync(process.argv[1]));
if (!list.includes(process.argv[2])) {
  list.push(process.argv[2]);
  fs.writeFileSync(process.argv[1], JSON.stringify(list, null, 2) + '\n');
}
" "$PROJECTS_FILE" "$PROJECT_NAME"
else
  echo "[\"$PROJECT_NAME\"]" > "$PROJECTS_FILE"
fi

echo "Project $PROJECT_NAME ready."
echo "  git submodule: ./projects/$PROJECT_NAME"
echo "  blackboard:    $BLACKBOARD_DIR/"
echo ""
echo "Next: fill in $BLACKBOARD_DIR/context.md, then run:"
echo "  bash scripts/run.sh $PROJECT_NAME team \"Your project goal\""
