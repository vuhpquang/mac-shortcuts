# fix-bugs

Trigger a targeted bug-fix cycle after QC has found failures.

## Steps

Arguments: `<project_name>`

1. Read `blackboard/<project_name>/state.json`
2. Find all bugs[] where `status = "open"`
3. For each open bug:
   - If `assigned_to = "worker"`: spawn a Task → worker agent to fix it
     - Provide: bug description, feature_id, task_id, architecture context
   - If `assigned_to = "techlead"`: notify the user — architectural fix needed
4. After workers finish, update bugs[].status = "fixed" for resolved items
5. Run TechLead Phase 2 (commit fixes):
   - `cd ./projects/<project_name>/ && git add . && git commit -m "fix: resolve QC bugs"`
6. Re-run QC agent on the project
7. Report: bugs fixed, bugs still open, re-test results
