# init-project

Initialize a new project: creates the git submodule under `./projects/` and the isolated blackboard at `./blackboard/{name}/`.

## Usage

Run: `bash scripts/init_project.sh $ARGUMENTS`

After running, remind the user to:
1. Fill in `blackboard/{name}/context.md` with the project goal and tech stack
2. Run `/run-team {name} "project goal"` to start the agent team
