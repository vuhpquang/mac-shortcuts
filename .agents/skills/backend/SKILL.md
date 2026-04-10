# Backend Skill — API, Database & Server-side Logic

## API Conventions
- RESTful endpoints: `GET /resource`, `POST /resource`, `PUT /resource/:id`, `DELETE /resource/:id`
- Response shape: `{ data, error, status }`
- HTTP status codes: 200 OK, 201 Created, 400 Bad Request, 401 Unauthorized, 404 Not Found, 500 Internal Server Error
- Validate all input at the boundary — never trust client data
- Never expose internal error details to the client

## Authentication
- Use JWT for stateless auth; store tokens in httpOnly cookies or Authorization header
- Hash passwords with bcrypt (min rounds: 12)
- Refresh token rotation on each use

## Database
- Always use migrations for schema changes — never alter live tables manually
- Index foreign keys and columns used in WHERE clauses
- Use transactions for multi-step writes
- Never store plain-text secrets or PII without encryption

## Error Handling
- Catch at the boundary; let internal errors propagate naturally
- Log with context: request ID, user ID, timestamp
- Distinguish operational errors (expected) from programmer errors (bugs)

## Code Structure
```
src/
  api/          ← route handlers
  services/     ← business logic
  db/           ← queries, migrations, models
  middleware/   ← auth, validation, logging
  utils/        ← shared helpers
```

## Before you write code
1. Read `.agents/memory.md` for project conventions
2. Read `.agents/blackboard.md` for your assigned task
3. Check existing `src/` structure and follow it
