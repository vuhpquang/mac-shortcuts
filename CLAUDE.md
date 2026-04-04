# Software Team — Agent Rules

## Blackboard

- Shared state: ./blackboard/state.json
- Always read before starting, write outputs when done
- Only write to your designated sections

## Human escalation

- If blocked or ambiguous, run:
  bash ./scripts/ask_human.sh "your question"
- This pauses and waits for input

## Git rules

- ALL git commands run by Tech Lead only
- Workers write files, never run git
- One branch only: develop
- Software repo is a git submodule at ./projects/{name}/

## Commit format

feat({feature_id}): {feature_title}

## Blackboard read rules (read ONLY your section)

- PO: read project only
- PM: read project, features
- Design: read features, tasks
- Tech Lead: read ALL
- Worker: read tasks[assigned], architecture, design[feature]
- QC: read features, code
