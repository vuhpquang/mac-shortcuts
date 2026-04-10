# Reviewer Skill — Code Review & Quality Gates

## Review Checklist

### Correctness
- [ ] Does the code do what the task requires?
- [ ] Are edge cases handled?
- [ ] No obvious logic errors or off-by-one mistakes?

### Security
- [ ] No SQL injection, XSS, CSRF, or command injection vectors
- [ ] No hardcoded secrets, tokens, or credentials
- [ ] Auth checks on all protected routes
- [ ] Input validated at boundaries

### Design
- [ ] Does it follow the existing patterns in the codebase?
- [ ] Is it the simplest solution that works?
- [ ] No premature abstractions or over-engineering?
- [ ] No dead code?

### Maintainability
- [ ] Is the logic self-evident, or does it need a comment?
- [ ] Are variable/function names clear?
- [ ] Is test coverage adequate?

## Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| blocker | Must fix before merging | Block + assign back to agent |
| major | Should fix; significant risk | Request fix |
| minor | Nice to fix; low risk | Suggest fix |
| nit | Style/preference | Leave as comment |

## Review Output Format

Append to `.logs/decisions.md`:
```
## [task-NNN] Review — YYYY-MM-DD
**Verdict**: approved | changes_requested
**Issues**:
- [severity] description
**Decision**: (if architectural choice made)
```

Update blackboard task status:
- approved → done
- changes_requested → blocked (with reviewer notes)

## Git — Reviewer is the only agent that runs git
- `git add`, `git commit`, `git push` only after review passes
- Commit message: `feat({task-id}): {task-title}`
- One commit per feature (squash task commits)
