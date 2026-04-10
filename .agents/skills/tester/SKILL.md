# Tester Skill — Test Strategy & Coverage

## Test Pyramid
- **Unit tests**: pure functions, utils, business logic — fast, isolated
- **Integration tests**: API endpoints, DB queries, service interactions
- **E2E tests**: critical user flows only (login, checkout, core action)

## Coverage Requirements
- Minimum 80% line coverage for new code
- 100% coverage for auth, payments, and data-write paths
- Every bug fix must include a regression test

## Test Structure
```
src/
  __tests__/
    unit/         ← pure function tests
    integration/  ← API + DB tests
    e2e/          ← full user flow tests
```

## Naming Convention
```
describe('ComponentName / functionName', () => {
  it('should [expected behavior] when [condition]', () => { ... })
})
```

## What to test
- Happy path
- Edge cases (empty input, null, zero, max length)
- Error cases (invalid input, network failure, auth failure)
- Boundary conditions

## What NOT to test
- Implementation details (test behavior, not internals)
- Third-party library internals
- Generated code

## Test Quality Rules
- Each test has one assertion focus
- No logic in tests (no if/else, loops)
- Tests are independent — no shared mutable state
- Tests must pass in any order

## Workflow
1. Read `.agents/blackboard.md` for your assigned test tasks
2. Read the feature's implementation in `src/`
3. Write tests, run them, ensure they pass
4. Update blackboard: status=done, output=test files + coverage %
