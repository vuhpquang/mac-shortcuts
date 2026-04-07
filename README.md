# Software Team

An agent-team framework for running autonomous AI software teams, with full support for running **multiple projects in parallel** — each with its own isolated blackboard.

## Project structure

```
projects/          ← git submodules, one per project
blackboard/
  projects.json    ← registry of all project names
  {project}/
    state.json     ← blackboard state for that project
    context.md     ← project goals, tech stack, delivery plan
  dashboard/
    index.html     ← visual dashboard (supports multi-project)
prompts/           ← agent role prompts
scripts/           ← run, init, spawn, ask scripts
```

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
- The dashboard reads blackboard files dynamically — refresh to pick up changes

## Human escalation

If an agent needs input, it calls:

```bash
bash ./scripts/ask_human.sh "question" <project_name>
```

This pauses and waits for your answer, then writes it to the project's blackboard.
