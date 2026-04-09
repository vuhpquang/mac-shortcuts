# request-merge

Run the merge approval flow for a project — merges `develop` → `main` after stakeholder approval.

## Steps

Arguments: `<project_name>`

1. Read `blackboard/<project_name>/state.json` and verify:
   - `project.status` is `qc_done` or all bugs are fixed
   - All features have status `committed`
2. If not ready, report what's blocking and stop
3. If ready, run: `bash scripts/request_merge.sh <project_name>`
4. After merge succeeds, update `blackboard/<project_name>/state.json`:
   - `project.status = "released"`
5. Print release summary: project name, features shipped, commit count
