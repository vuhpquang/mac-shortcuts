# run-team

Start the full software agent team on a project.

## Usage

Arguments: `<project_name> "<project goal>"`

Run: `bash scripts/run.sh $ARGUMENTS`

This launches the full team pipeline:
  PO → PM → Design → TechLead → Dev (workers) → QC → TechLead (commit/release)

Each agent reads/writes only `blackboard/{project_name}/` — no shared state conflicts.
