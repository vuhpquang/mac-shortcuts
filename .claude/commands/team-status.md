Show the current state of the agent team and blackboard.

Steps:
1. Read `.agents/blackboard.md`
2. Read `.agents/memory.md`
3. Read `.logs/decisions.md` (last 5 entries)
4. Output a formatted status report:

---
## Team Status

### Active Tasks
(list each in_progress task: ID, role, title)

### Pending Tasks
(list each pending task: ID, role, title)

### Blocked Tasks
(list each blocked task: ID, role, title, blocker)

### Completed This Session
(list done tasks: ID, role, title, output summary)

### Recent Decisions
(last 3 entries from decisions.md)

### Next Actions
(what each role should do next based on current state)
---
