# project-status

Show a concise status overview for a project from its blackboard.

## Steps

Arguments: `<project_name>` (if omitted, list projects from `blackboard/projects.json`)

1. Read `blackboard/<project_name>/state.json`
2. Print a summary:
   - Project name, goal, current status
   - Features: total / committed / pending
   - Tasks: total / done / in-progress / pending
   - Bugs: open / fixed
   - Test results: passed / failed
   - Last decisions from decisions[]
3. Suggest the next action based on project.status:
   - `research_done` → run TechLead Phase 0+1
   - `techlead_done` → run Dev agent
   - `coding_done` → run QC agent
   - `qc_done` → run TechLead Phase 3 (release)
   - `released` → done
