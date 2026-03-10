# Hackathon Repository Conventions

**Retention:** Carry-forward

Compact, enforceable standards for hackathon submission repos. Agents must follow these rules. Human operators can override with explicit intent.

> **Authority:** This document is the single source of truth for repo-working conventions. `AGENTS.md` and `copilot-instructions.md` reference it. If wording conflicts, this document wins for convention topics.

---

## 1. Git Workflow

### Branching

- **Always branch for features and fixes.** Never commit incomplete or untested work directly to `main`.
- **Direct-to-main is OK for:** typo fixes, comment edits, `.gitignore` tweaks, trivial doc corrections.
- **Branch naming:** `<type>/<short-description>` — lowercase, hyphen-separated, max ~4 words after prefix.

| Prefix | Use |
|--------|-----|
| `feat/` | New feature or contract module |
| `fix/` | Bug fix |
| `docs/` | Documentation changes |
| `chore/` | Config, build, housekeeping |
| `spike/` | Throwaway experiment (never merges to main) |

**Examples:** `feat/toll-gate`, `fix/ptb-quoting`, `docs/readme-polish`, `spike/zk-perf-test`

### Merge Strategy

- **Squash merge all feature branches into `main`.** This produces one clean commit per feature.
- In GitHub repo settings, enable **only** "Allow squash merging" to prevent accidents.
- The PR title becomes the squash commit message — write PR titles in commit message format.
- **Never force-push to `main`.** Linear, append-only history.

### Commit Messages

Simplified Conventional Commits — type + imperative description.

```
<type>: <imperative description>

[optional body — what and why]
```

**Types:** `feat`, `fix`, `docs`, `chore`, `refactor`, `test`

**Rules:**
- Subject line ≤72 characters
- Imperative mood ("Add toll collection" not "Added toll collection")
- No period at end of subject
- Capitalize first word after colon

**Examples:**
```
feat: Add toll collection for gate control
fix: Handle fuel burn rate minimum constraint
docs: Add architecture overview for judges
chore: Configure Move.toml environments for localnet
```

### Commit Hygiene on Feature Branches

- On feature branches, commit freely — small WIP commits are fine.
- All branch commits are squashed on merge, so only the PR title matters for `main` history.
- Before merging: ensure the branch builds and tests pass.

### Spike Branches

- Prefix with `spike/` — these are explicitly throwaway.
- **Never merge spike branches into `main`.** Extract learnings, then implement properly on `feat/` branches.
- Push to remote for backup but don't create PRs.
- Document findings in docs rather than preserving spike code.

### PRs (Even Solo)

Judges can browse merged PRs. Use them even when working solo.

**Minimal PR body:**
```markdown
## What
One sentence describing the feature.

## Why
One sentence on motivation.

## Verified
How this was tested (e.g., "sui move test passes", "localnet smoke OK").
```

Trivial PRs (single-file doc fix): title-only is fine.

### Main Branch Policy

- **`main` must always be demo-ready.** Never merge broken code.
- `git log --oneline` on `main` should read like a feature changelog.
- Front-load scaffolding commits, then features — judges skim the first 10-15 entries.

---

## 2. Repository Structure (Submission Repos)

```
/
├── README.md                  # Hero doc — judges start here
├── LICENSE
├── .gitignore
├── .env.example               # Placeholder env vars only
├── contracts/                 # Sui Move smart contracts
│   ├── <package>/
│   │   ├── Move.toml
│   │   ├── Move.lock          # Always committed
│   │   └── sources/
│   └── README.md
├── frontend/                  # React/TS frontend app
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
├── scripts/                   # Deploy, setup, seed scripts
│   └── README.md
├── docs/                      # Architecture, demo guide, screenshots
│   ├── architecture.md
│   ├── demo-guide.md
│   └── screenshots/
└── assets/                    # Branding (logo, banner)
```

**Rules:**
- **Max 10 items at repo root.** More signals disorganization.
- **Separate concerns clearly:** `contracts/`, `frontend/`, `scripts/`, `docs/` are immediately legible.
- **README.md at root AND in each major directory.** Root is the entry point; subdirectory READMEs explain local context.
- **No monorepo tooling** (turborepo, nx, lerna) for a 10-day project — it obscures structure.

### What to Exclude from Submission Repos

Do NOT copy from the planning repo:
- `docs/working_memory/`, `docs/strategy/`, `docs/operations/`, `docs/research/`
- `docs/analysis/`, `docs/archive/`, `docs/ideas/`, `docs/sandbox/`
- `AGENTS.md`, `.github/copilot-instructions.md`, `.github/instructions/`
- `notes/`, `sandbox/`, `experiments/`, `vendor/`, `templates/`
- `llms.txt`, `GITHUB-COPILOT.md`
- Decision logs, internal planning docs, audit reports

**Rule:** If a document doesn't help a judge understand what the project does, how it works, or how to run it — leave it out.

---

## 3. File Size & Component Discipline

These thresholds are guardrails, not bureaucracy. Exceed them only with a comment explaining why.

### TypeScript / React

| Metric | Limit | Action when exceeded |
|--------|-------|---------------------|
| Component file | **~150 lines** | Split into sub-components |
| Page/route component | **~100 lines** | Extract sections into feature components |
| JSX return block | **~80 lines** | Extract child components |
| `App.tsx` | **~30 lines** | Only providers + router |
| Custom hook | **~100 lines** | Split or extract helpers |
| Utility file | **~150 lines** | Split by domain |
| Props per component | **~5** | Consider splitting the component |
| `useState` per component | **3** | Extract to `useReducer` or custom hook |
| `useEffect` per component | **2** | Extract to custom hook |
| Global state stores | **≤3 total** | Consolidate or question scope |

### Move

| Metric | Limit | Action when exceeded |
|--------|-------|---------------------|
| Module file | **~500 lines** | Extract helper primitives |
| Function body | **~50 lines** | Extract helper functions |
| Struct fields | **32** (Sui hard limit) | Refactor design |

### General

- **No "god files."** Any file doing 3+ unrelated things must be split.
- **No nested render functions** inside React components — extract to separate files.
- **No commented-out code blocks** in the submission repo. Remove or delete.

---

## 4. Naming Conventions

### Cross-Language Summary

| Element | Convention | Examples |
|---------|-----------|---------|
| **Directories** | `kebab-case` | `gate-control/`, `trade-post/` |
| **React components** | `PascalCase.tsx` | `PolicyEditor.tsx`, `GatePanel.tsx` |
| **Hooks** | `camelCase`, `use` prefix | `useWalletStatus.ts` |
| **Utilities / libs** | `camelCase.ts` | `formatAddress.ts` |
| **Types files** | `camelCase.ts` | `types.ts`, `policyTypes.ts` |
| **Constants** | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT` |
| **Scripts** | `kebab-case`, verb prefix | `deploy-contracts.ts`, `seed-data.ts` |
| **Docs** | `kebab-case`, topic-first | `architecture.md`, `demo-guide.md` |
| **Screenshots** | Number prefix + description | `01-connect-wallet.png` |
| **Move modules** | `snake_case` | `gate_extension.move` |
| **Move structs** | `PascalCase` | `GateAuth`, `TollConfigKey` |
| **Move functions** | `snake_case` | `issue_jump_permit` |
| **Move errors** | `EPascalCase` | `ENotAuthorized` |
| **Move events** | `PascalCase` + `Event` suffix | `TollCollectedEvent` |
| **Move caps** | `PascalCase` + `Cap` suffix | `AdminCap`, `OwnerCap` |

### TypeScript Specifics

| Element | Convention |
|---------|-----------|
| Boolean vars/props | `is/has/should/can` prefix: `isLoading`, `hasPermission` |
| Event handler props | `on` prefix: `onSubmit`, `onPolicyChange` |
| Event handler funcs | `handle` prefix: `handleSubmit`, `handlePolicyChange` |
| Type/interface | `PascalCase`, no `I` prefix: `PolicyConfig` |
| Props interface | `ComponentNameProps`: `PolicyCardProps` |
| Enum members | `PascalCase`: `PostureState.Active` |

---

## 5. Code Organization — TypeScript / React

### Folder Structure

```
src/
├── app/                  # App shell: router, providers, layout
├── components/           # Shared UI (Button, Card, Modal)
│   ├── ui/               # Primitives
│   └── layouts/          # Layout shells
├── features/             # Feature modules (self-contained)
│   └── governance/
│       ├── components/
│       ├── hooks/
│       ├── api/
│       ├── types.ts
│       └── utils.ts
├── hooks/                # Shared custom hooks
├── lib/                  # Third-party library wrappers
├── types/                # Shared types
├── utils/                # Shared pure utilities
└── constants.ts
```

**Rules:**
- **Group by feature, not by type.** Feature logic lives together.
- **Shared vs. feature-specific:** if used by only one feature → feature folder. If used by 2+ → shared folder.
- **One component per file** for non-trivial components.
- **Use `@/` path aliases** to avoid `../../../` chains.
- **No cross-feature imports.** Features import only from shared folders. Compose at app level.
- **No circular imports.** Features → shared. App → features. Never the reverse.
- **Import order:** (1) React/framework, (2) third-party, (3) shared internal (`@/`), (4) feature-relative (`./`). Blank line between groups.
- **Use `import type`** for type-only imports.

### State Management

| Category | Tool |
|----------|------|
| Component state | `useState`, `useReducer` |
| Server/async state | TanStack Query (React Query) |
| Global app state | Zustand or React Context (≤3 stores) |
| URL state | Router search params |
| Form state | React Hook Form + Zod (if complex) |

- **Do NOT put server data in global state.** Use React Query.
- **State lives as close as possible to where it's used.**
- **Derive, don't duplicate.** Compute from existing state via `useMemo`.

### Tailwind CSS

- Utility classes inline in JSX. No separate CSS files unless forced.
- Use `cn()` / `clsx` for conditional classes — never string concatenation with ternaries.
- Extract repeated class sets into components, not `@apply` rules.
- Keep `className` strings under ~120 chars; use multi-line `cn()` for longer.
- Install `prettier-plugin-tailwindcss` to auto-sort classes.

### TypeScript Hygiene

- **`strict: true`** in tsconfig.json. Non-negotiable.
- **No `any`**. Use `unknown` + type narrowing.
- **No `as` assertions** unless narrowing from `unknown` after a runtime check.
- **No unused imports.** Enforce via ESLint.

---

## 6. Code Organization — Sui Move

> These supplement the rules in `.github/instructions/move.instructions.md`.

### Package Layout

```
contracts/<package>/
├── Move.toml
├── Move.lock              # Always committed
├── README.md              # Package purpose, object model, deploy instructions
├── sources/
│   ├── <core_module>.move
│   ├── primitives/        # Shared helper types
│   └── extension/         # Extension-specific logic
└── tests/
    └── <module>_tests.move
```

- Package name: `PascalCase` in `Move.toml` (`name = "CivilizationControl"`)
- Named address: `snake_case` (`civilization_control = "0x0"`)
- One core object per module. Shared primitives in `primitives/` subdirectory.
- Commit `Move.lock` — ensures reproducible builds.

### Composability Rules

- **Return objects, don't self-transfer.** Let the PTB handle `transfer::transfer`. This enables composability.
- **No `public entry`** — use `public` (composable, can return values) or `entry` (intentionally non-composable) separately.
- **Exact Coin arguments** — prefer `fun f(payment: Coin<SUI>)` over `fun f(payment: &mut Coin<SUI>, amount: u64)`.

### Collection Sizing

- `vector` for ≤1000 items. Beyond that, use `Table`, `Bag`, or `ObjectTable`.
- Never allow unbounded `vector` growth from user input.

---

## 7. Dependency Discipline

- **Do not add dependencies without justification.** Each dep should earn its place.
- **Document non-obvious dependencies** in a comment in `package.json` or a `deps` section in the directory README.
- **Prefer standard library / framework built-ins** over third-party when equivalent functionality exists.
- **Lock files must be committed** (`package-lock.json`, `pnpm-lock.yaml`, `Move.lock`).
- **`.env.example`** with placeholder values must exist whenever `.env` is used. Never commit `.env`.
- **Script names in `package.json`:** use clear verbs — `dev`, `build`, `test`, `deploy`, `lint`.

---

## 8. Documentation Lifecycle

### Submission Repo Docs

| Document | Purpose | Required? |
|----------|---------|-----------|
| `README.md` (root) | Hero doc, project overview, quickstart | **Must** |
| `contracts/README.md` | Contract overview, object model, deployed addresses | **Must** |
| `docs/architecture.md` | System design, data flow | **Should** |
| `docs/demo-guide.md` | Step-by-step demo walkthrough | **Should** |
| `docs/screenshots/` | Visual evidence, hero screenshot/GIF | **Should** |
| `.env.example` | Environment variable template | **Must** if app uses env vars |

### README Template (Judge-Optimized)

```markdown
# Project Name

> One-line description.

![Hero Screenshot](docs/screenshots/hero.png)

## What It Does
2-3 sentences on core functionality.

## Demo
- **Live**: [link] | **Video**: [link]

## Architecture
Brief overview + diagram.

## Getting Started
\```bash
cd frontend && npm install && npm run dev
cd contracts/<pkg> && sui move build && sui move test
\```

## Project Structure
\```
contracts/  — Sui Move smart contracts
frontend/   — React/TypeScript UI
scripts/    — Deployment and setup
docs/       — Architecture and screenshots
\```

## Team
- [Name] — [Role]
```

### Keeping Docs Current

- Remove `TODO` and `fix later` comments before submission.
- Remove dead links. Test every link.
- Internal planning docs (decision logs, research, working memory) stay in the planning repo — never ship them.

---

## 9. Generated Artifacts & .gitignore

### Must .gitignore

```gitignore
node_modules/
dist/
build/
.next/
.env
.env.*
!.env.example
*.keystore
*.pem
contracts/*/build/
coverage/
*.log
notes/
docs/working_memory/
.DS_Store
Thumbs.db
```

### Must Commit

- `package-lock.json` / `pnpm-lock.yaml` (reproducible builds)
- `Move.lock` (reproducible Move builds)
- `.env.example` (onboarding)
- `.vscode/tasks.json` (if helpful)

---

## 10. Judge-Facing Legibility

**Judges spend 5-15 minutes per repo.** Optimize for that window.

### High-Signal Actions

1. **Hero image/GIF at top of README** — judges decide interest in 3 seconds.
2. **Working demo link** — strongest single signal.
3. **3-command quickstart** — if setup takes more than `install → build → run`, fix the scripts.
4. **Published package ID + network** in README — judges can verify on-chain.
5. **Consistent file structure** — even simple, applied consistently, signals competence.
6. **No 500+ line files** — immediate red flag.
7. **Meaningful names** — `PolicyExecutionPanel.tsx` >> `Component3.tsx`.
8. **Clean git history** — one commit per feature via squash merge.

### Common Mistakes

- Empty or sparse README
- `node_modules` committed
- Secrets in repo (check git history too)
- Dead links or missing images
- 30+ files at repo root
- Lots of commented-out code
- "TODO" / "fix later" scattered in code
- No license file
- Impressive docs but nothing runs

---

## 11. Hackathon Speed Rules

### When Shortcuts Are Acceptable

- **Skip tests for UI components** if time is critical — tests on contracts matter more.
- **Use simple state management** (useState + Context) if React Query or Zustand is unfamiliar.
- **Skip responsive design** if you only demo on desktop — but note it in README.
- **Hardcode config values** if environment switching isn't needed — use named constants, not magic numbers.
- **Skip CI/CD** — judges don't care about pipeline config for a 10-day project.
- **Skip i18n, accessibility polish, and SEO** — nice-to-have, not judged.

### Shortcuts That Are NEVER Acceptable

- Committing secrets or private keys
- Shipping broken `main` (doesn't build or run)
- No README
- No license
- Plagiarized code without attribution
- Giant monolithic files (>500 lines) — always take the 5 minutes to split

### How to Document Shortcuts Cleanly

If you skip something, add a single line in README under a "Known Limitations" section:

```markdown
## Known Limitations
- Mobile-responsive design not implemented (desktop-only demo)
- Test coverage limited to smart contract layer
- Error handling is basic on frontend — happy path optimized for demo
```

This signals awareness and intentionality — far better than leaving gaps unexplained.

---

## 12. Agent-Specific Rules

These rules apply when AI agents produce code or documentation.

### File Creation

- **Check for existing files before creating new ones.** Duplicate utilities/helpers are a common agent failure mode.
- **Place files in the correct directory** per the conventions above. Never create random one-off files at project root.
- **Name files according to the naming conventions.** No generic names like `utils2.ts`, `helper.ts`, `stuff.ts`.

### Code Production

- **Respect file size limits.** If generating a component that exceeds ~150 lines, split it proactively.
- **Do not produce commented-out code.** Write the code you mean or don't write it.
- **Do not add speculative utilities** "for future use." Only write what's needed now.
- **Check for existing hooks/utils before creating new ones.** Grep the workspace first.
- **Use consistent naming.** Match existing patterns in the codebase.

### Commit Behavior

- **Create feature branches** for any non-trivial change (unless the operator says otherwise).
- **Write PR titles in Conventional Commit format** (`feat: Add toll collection`).
- **Individual branch commits don't need perfect messages** — they'll be squashed.

### Documentation

- **Do not create docs that won't be read.** Only create documentation that serves judges, operators, or future agents.
- **Do not create a summary document after every change.** Update existing docs or confirm completion verbally.
- **Keep generated docs concise.** Match the conventions in this document.
