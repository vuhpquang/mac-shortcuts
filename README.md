# Software Team

An agent-team framework for running autonomous AI software teams, with full support for running **multiple projects in parallel** — each with its own isolated blackboard.

## Agent Architecture

```
                        ┌─────────────────────────────────────────┐
                        │            BLACKBOARD                   │
                        │  blackboard/{project}/state.json        │
                        │  features[] tasks[] architecture        │
                        │  design[] code[] test_results[] bugs[]  │
                        └─────────────────┬───────────────────────┘
                                          │ read/write
     ┌────────────────────────────────────┼──────────────────────┐
     │                                    │                      │
     ▼                                    ▼                      ▼
┌──────────────────┐             ┌──────────────────┐   ┌──────────────┐
│ Researcher Agent │──features──▶│  TechLead Agent  │   │ Design Agent │
│ (researcher.md)  │             │  (techlead.md)   │   │ (design.md)  │
└──────────────────┘             └────────┬─────────┘   └──────────────┘
Market research:                 Phase 0: tasks[]         UI/UX design
- user pain points               Phase 1: architecture    per feature
- competitor gaps                Phase 2: git commit
- feature opportunities          Phase 3: release
                                 ◀── ONLY agent with git
                                          │
                    ┌────────────────────┐│
                    │                    ▼▼
           ┌──────────────┐    ┌──────────────────┐    ┌──────────────┐
           │  Dev Agent   │───▶│  Worker (×N)     │    │   QC Agent   │
           │  (dev.md)    │    │  (worker.md)     │    │   (qc.md)    │
           └──────────────┘    └──────────────────┘    └──────────────┘
           Programmer           Spawned via Task          Verifies features,
           Supervisor           tool per task             writes test_results[]
                                claude-haiku              and bugs[]
```

### Agent roles & blackboard access

| Agent      | Reads                          | Writes                                   |
|------------|--------------------------------|------------------------------------------|
| Researcher | context.md (goal + domain)     | features[] (with market rationale)       |
| Design     | features[], tasks[]            | design[]                                 |
| TechLead   | ALL                            | tasks[], architecture, decisions[], git  |
| Dev        | tasks[], architecture          | tasks[].status                           |
| Worker     | tasks[assigned], architecture  | code[], files in projects/               |
| QC         | features[], code[]             | test_results[], bugs[]                   |

### Pipeline flow

```
Researcher → Design → TechLead (tasks+arch) → Dev → Workers → TechLead (commit) → QC → TechLead (release)
```

Human escalation at any step via `bash scripts/ask_human.sh "question" {project}`.

---

## Project structure

```
.claude/
  agents/          ← agent role definitions (single source of truth)
  │  researcher.md   market research → features[]
  │  design.md       UI/UX design → design[]
  │  techlead.md     task planning + architecture + git (phases 0–3)
  │  dev.md          programmer supervisor → spawns workers
  │  worker.md       single-task implementer (haiku, spawned by dev)
  │  qc.md           verifies features → test_results[], bugs[]
  commands/        ← project slash commands
  │  /new-project      guided project setup
  │  /run-team         start the full agent pipeline
  │  /run-solo         single-agent mode
  │  /project-status   show blackboard overview + next action
  │  /fix-bugs         targeted bug-fix cycle after QC
  │  /request-merge    validate readiness then merge develop → main
scripts/           ← shell utilities called by agents and commands
  │  run.sh            launch a project in solo|team mode
  │  init_project.sh   create git submodule + blackboard namespace
  │  start-agents.sh   launch all agent tmux sessions + ttyd + relay
  │  ask_human.sh      human escalation — pause and capture answer to blackboard
  │  request_merge.sh  stakeholder approval UI for develop → main merge
projects/          ← git submodules, one per project
blackboard/
  projects.json    ← registry of all project names
  {project}/
    state.json     ← blackboard state (features, tasks, code, bugs, tests)
    context.md     ← project goal and tech stack
  dashboard/
    index.html     ← visual web dashboard (multi-project)
run.md             ← orchestrator pipeline (read by run.sh team mode)
index.html         ← standalone agent terminal grid
start.sh           ← one-command launcher
```

---

## Quick start

```bash
bash start.sh
```

Opens the browser to the dashboard with all 6 agents ready and waiting.

---

## Init a new project

```bash
bash scripts/init_project.sh <project_name>
```

This creates:
- `./projects/<project_name>/` git submodule
- `./blackboard/<project_name>/state.json`
- `./blackboard/<project_name>/context.md`

Then fill in `blackboard/<project_name>/context.md` with your goal and tech stack.

Also add the project name to `blackboard/projects.json` so the dashboard can find it.

## Run an agent team

```bash
bash scripts/run.sh <project_name> solo "Project goal"
```

or

```bash
bash scripts/run.sh <project_name> team "Project goal"
```

## Run multiple projects in parallel

Open **one terminal per project**, each scoped to its own blackboard:

```bash
# Terminal 1
bash scripts/run.sh gesturekit team "GestureKit macOS app"

# Terminal 2
bash scripts/run.sh myapp team "My other app"
```

Each team reads/writes only `blackboard/<project_name>/` — **no shared state, no conflicts.**

## Blackboard Dashboard

Visualize any project's state (features, tasks, bugs, test results, architecture).

```bash
cd blackboard && python3 -m http.server 8000
```

Then open: http://localhost:8000/dashboard/

- Use the **project switcher** in the sidebar to switch between projects
- Or link directly: `http://localhost:8000/dashboard/?project=gesturekit`
- Click **Agents** in the sidebar to see all 6 live terminal panes + chat bar
- The dashboard reads blackboard files dynamically — refresh to pick up changes

## Human escalation

If an agent needs input, it calls:

```bash
bash ./scripts/ask_human.sh "question" <project_name>
```

This pauses and waits for your answer, then writes it to the project's blackboard.
