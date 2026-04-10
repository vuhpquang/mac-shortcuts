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

## Escalation

If scope is unclear or a blocking decision is needed:
```bash
bash ./scripts/ask_human.sh "your question" {PROJECT_NAME}
```
