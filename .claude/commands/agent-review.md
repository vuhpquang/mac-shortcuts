Trigger the reviewer agent on completed tasks.

Steps:
1. Read `.agents/blackboard.md` — find tasks with status=done not yet reviewed (no entry in `.logs/decisions.md`)
2. Read `.agents/personas/reviewer.md` — load reviewer identity
3. Read `.agents/skills/reviewer/SKILL.md` — review checklist and git rules
4. Read `.agents/memory.md` — load project conventions
5. For each task to review:
   a. Read the changed files in `src/`
   b. Apply the review checklist
   c. Write result to `.logs/decisions.md`
   d. If approved: commit and push with `feat({task-id}): {title}`
   e. If changes requested: mark task blocked in blackboard with reviewer notes
6. Report: approved tasks committed, tasks needing changes, any blockers
