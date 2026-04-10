# Orchestrator Skill — Task Decomposition & Role Assignment

## When to decompose
- Any task > ~2h of work → break it down
- Any task crossing multiple domains (backend + frontend) → split by domain
- Ambiguous scope → ask human before assigning

## Role assignment rules

| Work type | Assign to |
|-----------|-----------|
| REST APIs, DB schema, server logic, auth | backend |
| UI components, styling, client state, routing | frontend |
| Unit tests, integration tests, E2E, coverage | tester |
| Code review, security audit, architecture check | reviewer |
| Multi-role decomposition, dependency ordering | orchestrator (self) |

## Decomposition pattern

Given: "build login feature"
```
task-001 | backend   | POST /auth/login endpoint (JWT)
task-002 | backend   | User session storage
task-003 | frontend  | Login form component
task-004 | frontend  | Auth state management
task-005 | tester    | Integration tests for login flow
task-006 | reviewer  | Review login impl + security audit
```

## Blackboard update format

Append to `.agents/blackboard.md` Active Tasks table:
```
| task-NNN | ROLE | TITLE | pending | — |
```

Move to Completed when status=done. Move to Blocked with blocker description when stuck.

## Progress tracking

After all tasks for a feature are done → update Features table: status=complete.

## Parallel sub-agent research (multi-project bootstrap)

When asked to research or populate multiple projects at once, spawn one sub-agent per project using the **Task tool**, all in a single response so they run in parallel.

Each sub-agent instruction:
```
You are a researcher sub-agent. 
1. Read blackboard/{project}/context.md — understand the goal, platform, tech stack
2. Research the domain: target users, pain points, competitor gaps, technical breakdown
3. Define features[]: { id, title, description, priority, status: "pending" }
4. Define tasks[] from features: { id, feature_id, title, description, status: "pending" }
5. Write both arrays to blackboard/{project}/state.json (merge, do not overwrite project field)
6. Report: "Done — {N} features, {M} tasks written for {project}"
```

Spawn pattern (one Task call per project, all in same response = parallel execution):
- Task 1 → research boardcast
- Task 2 → research sleepwave  
- Task 3 → research dayflow
- Task 4 → research frameshot

After all tasks complete → update `.agents/blackboard.md` Features table with results.

## Escalation

If scope is unclear or a blocking decision is needed:
```bash
bash ./scripts/ask_human.sh "your question" {PROJECT_NAME}
```
