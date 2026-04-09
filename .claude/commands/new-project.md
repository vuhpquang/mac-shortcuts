# new-project

Guided setup for a new project: initializes the git submodule, blackboard, and context — then optionally kicks off the team.

## Steps

1. Ask the user: "Project name?" (must be lowercase, no spaces)
2. Ask the user: "Describe the project goal in one sentence."
3. Ask the user: "What's the tech stack? (e.g. Swift/SwiftUI, React/Node, Python/FastAPI)"
4. Run: `bash scripts/init_project.sh <name>`
5. Write the goal and tech stack into `blackboard/<name>/context.md`
6. Add `<name>` to `blackboard/projects.json` if not already present
7. Ask: "Start the agent team now? (y/n)"
   - If yes: run `bash scripts/run.sh <name> team "<goal>"`
   - If no: remind the user to run `/run-team <name> "<goal>"` when ready
