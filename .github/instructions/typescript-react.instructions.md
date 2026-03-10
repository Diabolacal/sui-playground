---
description: "TypeScript, React, and Tailwind CSS conventions for hackathon repos"
applyTo: "**/*.{ts,tsx}"
---

# TypeScript / React / Tailwind — Workspace Conventions

> Apply these rules when writing or modifying TypeScript and React code.
> Full rationale and thresholds in `docs/core/hackathon-repo-conventions.md`.

## File Size Guardrails

- **Component file: ~150 lines max.** Split into sub-components at this threshold.
- **Page/route component: ~100 lines max.** Pages are orchestrators — fetch data, compose components, handle layout.
- **App.tsx: ~30 lines max.** Only providers + router. Zero business logic.
- **JSX return block: ~80 lines max.** Extract child components.
- **Custom hook: ~100 lines max.** Split or extract pure helpers.
- **No nested render functions.** Never define `function renderFoo()` inside a component — extract to a file.

## Pre-Planning / File Decomposition (Mandatory)

Before generating any new component, hook, or utility file, the agent **must** outline the file decomposition in its plan:

1. **Estimate scope first.** Before writing code, mentally estimate the line count of the feature. If a single component or hook is likely to exceed its size limit (~150 lines for components, ~100 for hooks/pages), design it as multiple files in the plan.
2. **Declare file boundaries upfront.** The plan must list every file to be created or modified, with a one-line purpose for each. Do not start writing code until the decomposition is explicit.
3. **Split proactively, not reactively.** Never write a file past its size limit and then split afterward. If mid-generation you realize a file will exceed its limit, stop, revise the plan to add sub-components/hooks, and restart from the revised plan.
4. **Common split points:** Extract `useFoo` hooks for state+effect combos, extract `FooItem` for `.map()` children, extract `FooForm`/`FooList`/`FooDetail` for multi-section UIs, extract utility functions to `utils/`.

## Component Rules

- One non-trivial component per file.
- **Split when:** >3 `useState` calls, >2 `useEffect` calls, JSX return >80 lines, `.map()` plus other significant markup.
- **Always name components.** No `export default () => ...`.
- **Destructure props** in the function signature.
- Props interface named `ComponentNameProps`, defined above or inline.

## Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Component files | `PascalCase.tsx` | `PolicyEditor.tsx` |
| Hook files | `use` prefix, camelCase | `useWalletStatus.ts` |
| Utility files | `camelCase.ts` | `formatAddress.ts` |
| Directories | `kebab-case` | `gate-control/` |
| Types/interfaces | `PascalCase`, no `I` prefix | `PolicyConfig` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT` |
| Boolean vars | `is/has/should/can` prefix | `isLoading` |
| Handler props | `on` prefix | `onSubmit` |
| Handler functions | `handle` prefix | `handleSubmit` |

## Imports

Order: (1) React/framework → (2) third-party → (3) shared internal (`@/`) → (4) feature-relative (`./`).
Blank line between groups. Use `import type` for type-only imports. No circular imports.

## State Management

- **Component state:** `useState`, `useReducer` (max 3 `useState` before extracting a hook).
- **Server state:** TanStack Query. Never put server data in global state.
- **Global state:** Zustand or Context. Max 3 stores.
- **Derive, don't duplicate.** If computable from existing state, use `useMemo`.

## TypeScript

- **`strict: true`** always.
- **No `any`.** Use `unknown` + narrowing.
- **No `as` assertions** unless narrowing from `unknown` after a runtime check.
- **No unused imports.**

## Tailwind CSS

- Utility classes inline in JSX. No separate CSS files unless forced.
- Use `cn()` / `clsx` for conditional classes — never string concatenation with ternaries.
- Extract repeated class combos into React components, not `@apply`.
- Install `prettier-plugin-tailwindcss` for auto-sorted classes.

## Hooks

- Extract to a hook when: `useState` + `useEffect` together, same pattern in 2+ components, or >20 lines of logic before the JSX return.
- Hooks must start with `use`. Hooks don't return JSX (that's a component).
- Pure functions (no React state/effects) go in `utils/`, not in hooks.

## Folder Structure

```
src/
├── app/              # Router, providers, layout
├── components/       # Shared UI
│   ├── ui/           # Primitives (Button, Input)
│   └── layouts/      # Layout shells
├── features/         # Self-contained feature modules
│   └── <feature>/
│       ├── components/
│       ├── hooks/
│       ├── api/
│       ├── types.ts
│       └── utils.ts
├── hooks/            # Shared hooks
├── lib/              # Third-party wrappers
├── types/            # Shared types
├── utils/            # Shared pure functions
└── constants.ts
```

Group by feature, not by type. Feature-specific code stays in the feature folder. Promote to shared when used by 2+ features. No cross-feature imports.
