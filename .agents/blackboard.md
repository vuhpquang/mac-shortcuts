# Blackboard

_Single source of truth for task state across all agents._

## Schema

Each task entry:
| Field | Type | Values |
|-------|------|--------|
| id | string | task-001, task-002, … |
| role | string | orchestrator \| backend \| frontend \| tester \| reviewer |
| title | string | short description |
| description | string | full details |
| status | string | pending \| in_progress \| done \| blocked |
| output | string | files changed or summary of work done |
| assigned_at | string | ISO 8601 timestamp |
| completed_at | string | ISO 8601 timestamp or — |

---

## Active Tasks

| ID | Role | Title | Status | Output |
|----|------|-------|--------|--------|
| — | — | — | — | — |

---

## Completed Tasks

| ID | Role | Title | Output | Completed |
|----|------|-------|--------|-----------|

---

## Blocked Tasks

| ID | Role | Title | Blocker |
|----|------|-------|---------|

---

## Features

| ID | Title | Status | Roles Involved |
|----|-------|--------|----------------|

---

## Notes

- Agents write only to their designated rows.
- Orchestrator manages feature status and overall progress.
- Reviewer updates decisions in `.logs/decisions.md`.
