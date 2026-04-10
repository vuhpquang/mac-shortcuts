You are creating a new task on the blackboard.

User's task: $ARGUMENTS

Steps:
1. Read `.agents/blackboard.md` to find the next available task ID (scan existing IDs, increment)
2. Create a new task entry in the Active Tasks table:
   - id: task-NNN (next sequential)
   - role: tbd (orchestrator will assign sub-roles)
   - title: short title derived from the user's task
   - description: full task details
   - status: pending
   - assigned_at: current timestamp
3. Update the Features table if this is a new feature
4. Write the updated `.agents/blackboard.md`
5. Output: "Task task-NNN added to blackboard. Orchestrator should now decompose and assign."

After writing, output the full task breakdown so the orchestrator can act immediately.
