Run the agent for the given role on their assigned tasks.

Arguments: role name (e.g. `backend`, `frontend`, `tester`, `reviewer`, `orchestrator`)

Role from arguments: $ARGUMENTS

Steps:
1. Read `.agents/blackboard.md` — find pending/in_progress tasks for role: $ARGUMENTS
2. Read `.agents/personas/$ARGUMENTS.md` — load role identity and boundaries
3. Read `.agents/skills/$ARGUMENTS/SKILL.md` — load domain knowledge
4. Read `.agents/memory.md` — load project conventions
5. Execute all pending tasks for this role, updating blackboard status as you go:
   - Mark in_progress when starting
   - Mark done when complete, with output (files changed, summary)
   - Mark blocked with reason if stuck
6. After all tasks: report what was completed and what (if anything) is blocked
