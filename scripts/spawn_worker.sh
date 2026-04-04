# scripts/spawn_worker.sh
TASK_ID=$1
claude --model claude-haiku-4-5-20251001 \
  --dangerously-skip-permissions \
  "Read prompts/worker.md. Your task_id: $TASK_ID. 
   Read blackboard/state.json for your task only."