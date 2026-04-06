# How to use this agent-team?

```
bash scripts/run.sh solo "GestureKit macOS app"
```

or

```
bash scripts/run.sh team "GestureKit macOS app"
```

## Blackboard Dashboard

Visualize the current project state (features, tasks, bugs, test results, architecture) from `blackboard/state.json` and `blackboard/context.md`.

```bash
cd blackboard && python3 -m http.server 8000
```

Then open: http://localhost:8000/dashboard/

The dashboard reads the blackboard files dynamically — refresh the page to pick up any changes.
