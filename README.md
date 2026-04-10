# Software Team

An agent-team framework for running autonomous AI software teams with a file-based blackboard and role-based agents.

## Agent Architecture

```
                    ┌──────────────────────────────────────┐
                    │            BLACKBOARD                │
                    │  .agents/blackboard.md               │
                    │  tasks[] · features[] · status       │
                    │  .agents/memory.md (persistent facts)│
                    └──────────────┬───────────────────────┘
                                   │ read/write
     ┌─────────────────────────────┼─────────────────────────┐
     │                             │                         │
     ▼                             ▼                         ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Orchestrator  │     │ Backend / Frontend│     │    Reviewer     │
│ (orchestrator)  │────▶│ (backend/frontend)│────▶│  (reviewer)     │
└─────────────────┘     └────────┬─────────┘     └─────────────────┘
Decomposes tasks,        Implements code,          Reviews code,
assigns roles,           writes to src/,           runs git,
tracks progress          updates blackboard         writes decisions.md
                                 │
                                 ▼
                    ┌──────────────────┐
                    │     Tester       │
                    │   (tester)       │
                    └──────────────────┘
                    Writes + runs tests,
                    reports coverage
```

### Agent roles

| Agent        | Responsibility                                | Writes to                        | Git?                 |
| ------------ | --------------------------------------------- | -------------------------------- | -------------------- |
| Orchestrator | Decompose tasks, assign roles, track progress | blackboard.md (tasks)            | No                   |
| Backend      | APIs, DB, server logic                        | src/ + blackboard (status)       | No                   |
| Frontend     | UI components, styling, client state          | src/ + blackboard (status)       | No                   |
| Tester       | Unit, integration, E2E tests                  | test files + blackboard (status) | No                   |
| Reviewer     | Code review, quality gates, commits           | decisions.md + git               | **YES — only agent** |

### Execution flow

```
/agent-assign "build login API"
  → Orchestrator decomposes → writes tasks to blackboard

/agent-run backend    → Backend implements API tasks
/agent-run frontend   → Frontend implements UI tasks
/agent-run tester     → Tester writes + runs tests
/agent-review         → Reviewer reviews → commits → pushes

/team-status          → Show full blackboard summary
```

Human escalation at any step:

```bash
bash ./scripts/ask_human.sh "question" {project_name}
```

---

## Project structure

```
.agents/
  blackboard.md          ← shared task state (single source of truth)
  memory.md              ← persistent facts and conventions across sessions
  personas/              ← agent identity and boundaries per role
  │  orchestrator.md
  │  backend.md
  │  frontend.md
  │  tester.md
  │  reviewer.md
  skills/                ← domain knowledge per role
  │  orchestrator/SKILL.md   task decomposition, role assignment rules
  │  backend/SKILL.md        API patterns, DB conventions, error handling
  │  frontend/SKILL.md       component structure, styling rules
  │  tester/SKILL.md         test strategy, coverage requirements
  │  reviewer/SKILL.md       review checklist, quality gates, git rules

.claude/
  agents/                ← Claude Code sub-agent definitions
  │  orchestrator.md
  │  backend.md
  │  frontend.md
  │  tester.md
  │  reviewer.md
  commands/              ← slash commands
  │  /agent-assign       post a task to the blackboard
  │  /agent-run          run an agent role on their tasks
  │  /agent-review       trigger reviewer on completed tasks
  │  /team-status        show blackboard summary + next actions
  │  /project-status     show blackboard overview
  │  /fix-bugs           targeted bug-fix cycle
  │  /request-merge      validate readiness then merge develop → main

.logs/
  decisions.md           ← architecture decision records (written by reviewer)

scripts/
  start-agents.sh        ← launch all 5 agent tmux sessions + ttyd + relay
  run.sh                 ← launch a project in solo|team mode
  init_project.sh        ← create git submodule + blackboard namespace
  ask_human.sh           ← human escalation — pause and capture answer
  request_merge.sh       ← stakeholder approval UI for develop → main merge

blackboard/
  projects.json          ← registry of all project names
  {project}/
    state.json           ← legacy project state (existing projects)
    context.md           ← project goal and tech stack
  dashboard/
    index.html           ← visual web dashboard (multi-project)

projects/                ← git submodules, one per project
index.html               ← standalone agent terminal grid
start.sh                 ← one-command launcher
CLAUDE.md                ← root context injected into every agent session
```

---

## Running the dashboard & agent team

### Normal daily use

```bash
bash start.sh
```

This is the only command you need day-to-day. It:

- Kills stale ports (8000, 7681–7685, 7690)
- Reuses agent tmux sessions if Claude is already running in them
- Restarts any agent session where Claude exited
- Starts the blackboard HTTP server on port 8000
- Opens the dashboard in your browser

### Agent frozen or stuck

```bash
bash scripts/start-agents.sh
```

Restarts only the agent sessions (orchestrator, backend, frontend, tester, reviewer). Does not touch the HTTP server or browser.

### Full reset (agents broken, sessions corrupted)

```bash
for s in orchestrator backend frontend tester reviewer; do tmux kill-session -t $s 2>/dev/null; done
bash start.sh
```

Kills only the agent sessions — not your entire tmux server. Use this when agents are in an unrecoverable state.

> **Do not use `tmux kill-server`** — it destroys all tmux sessions on your machine, including unrelated work.

---

## Init a new project

```bash
bash scripts/init_project.sh <project_name>
```

Creates:

- `./projects/<project_name>/` git submodule
- `./blackboard/<project_name>/state.json`
- `./blackboard/<project_name>/context.md`

Then fill in `blackboard/<project_name>/context.md` with your goal and tech stack.

## Assign a task

Type directly in the Orchestrator terminal, or use the chat bar:

```
/agent-assign build a login API with JWT auth
```

The orchestrator decomposes it and writes tasks to `.agents/blackboard.md`.

## Run agents

```
/agent-run backend
/agent-run frontend
/agent-run tester
/agent-review
```

Or send messages directly to any agent via the chat bar in the dashboard.

## Check status

```
/team-status
```

---

## Agent startup sequence

Every agent follows the same boot sequence:

1. Read `.agents/blackboard.md` — find assigned tasks
2. Read `.agents/personas/{role}.md` — load identity and boundaries
3. Read `.agents/skills/{role}/SKILL.md` — load domain knowledge
4. Read `.agents/memory.md` — load project conventions
5. Execute tasks; update blackboard status as work progresses

---

## Dashboard

Visualize any project's state (features, tasks, bugs, test results, architecture).

```bash
bash start.sh
```

Then open: `http://localhost:8000/dashboard/`

- Use the **project switcher** in the sidebar to switch between projects
- Click **Agents** in the sidebar to see all 5 live terminal panes + chat bar
- The chat bar broadcasts to all agents or targets a specific one

## Human escalation

If an agent needs input, it calls:

```bash
bash ./scripts/ask_human.sh "question" <project_name>
```

This pauses and waits for your answer, then writes it to the project's blackboard.

# Projects

## Mac Shortcuts: gesturekit

Run:

```bash
open projects/gesturekit/build/Mac\ Shortcuts.app
```
