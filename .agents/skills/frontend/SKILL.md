# Frontend Skill — Components, Styling & Client State

## Component Structure
- One component per file; filename matches component name
- Keep components small and focused — split when > ~150 lines
- Props should be typed; avoid `any`
- Colocate styles with the component they belong to

## Styling Rules
- Use design tokens / CSS variables for colors, spacing, typography
- Mobile-first responsive design
- No magic numbers — use named constants
- Accessibility: always include `alt`, `aria-label`, keyboard navigation

## State Management
- Local state for UI-only concerns (open/closed, hover, etc.)
- Shared/global state for server data and auth
- Avoid prop drilling > 2 levels — use context or state store
- Optimistic updates for better UX on mutations

## Data Fetching
- Always handle loading, error, and empty states
- Show skeleton screens or spinners while loading
- Cache server responses where appropriate
- Retry on network errors; don't retry on 4xx

## UI/UX Defaults
- Confirm before destructive actions
- Disable submit buttons while submitting
- Show inline validation errors, not alerts
- Use consistent spacing, font sizes, and color hierarchy

## Code Structure
```
src/
  components/   ← reusable UI components
  pages/        ← route-level views
  hooks/        ← custom hooks
  store/        ← global state
  styles/       ← global styles, tokens
  utils/        ← helpers
```

## Before you write code
1. Read `.agents/memory.md` for project conventions
2. Read `.agents/blackboard.md` for your assigned task
3. Check existing `src/` structure and follow it
