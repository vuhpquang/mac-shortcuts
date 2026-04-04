# in scripts/run.sh
MODE=$1  # "team" or "solo"
PROJECT_GOAL=$2

if [ "$MODE" = "solo" ]; then
  claude --dangerously-skip-permissions \
    "Read blackboard/context.md. Implement the full project solo, phase by phase. 
     Project: $PROJECT_GOAL"
else
  claude --dangerously-skip-permissions \
    "Read run.md and blackboard/context.md. 
     Start the software team. Project: $PROJECT_GOAL"
fi