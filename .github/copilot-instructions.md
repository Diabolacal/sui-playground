# Copilot Project Instructions ({{PROJECT_NAME}})

Purpose: Authoritative source of truth for AI agent guardrails, interaction patterns, and workflow conventions in this VS Code project. GitHub Copilot loads this file automatically. Follow the patterns below when adding or modifying code. Optimized for a "vibe coding" workflow: the human provides intent (non‑coder friendly) and the AI agent converts intent into safe, minimal, verifiable changes.

## Beginner Defaulting
If the user doesn't know an answer yet, propose a sensible default and proceed. Do not block progress.

## Operator Quick Start (Non‑Coder)
1. Describe goal in plain language (what you want changed / added / fixed).
2. Assistant replies with: checklist, assumptions (≤2), risk class, plan.
3. You approve or adjust scope (optionally grant token if High risk).
4. Assistant patches code, runs typecheck/build, reports gates & follow-ups.
5. Non-trivial decisions appended to `docs/decision-log.md` (≤10 lines each).

If stuck: ask for "safer alternative" or "explain tradeoffs". Avoid giving line-by-line code; just describe desired outcome.

## Instruction Strategy & Scope
- Repo-wide mandates live here. `AGENTS.md` summarizes them; path- or persona-specific instructions belong in `.github/instructions/*.instructions.md`.
- Commands belong near the top of each relevant section. Provide exact flags so agents can run them verbatim.
- Use bullet lists over prose and include concrete "good vs bad" examples when reinforcing style or architecture conventions.
- When a rule applies only to a subset of the project, isolate it with a clear heading so other workflows scan past it quickly.

## Model Workflow Expectations
- Start every reply with a brief acknowledgement plus a high-level plan.
- Manage work through a todo list with exactly one item `in-progress`; update statuses as tasks start or finish.
- Report status as deltas — highlight what changed since the last message instead of repeating full plans.
- Run fast verification steps yourself when feasible and note any gates you couldn't execute.

## Operational Guardrails (Authoritative)
These rules have the highest precedence. `AGENTS.md` mirrors them in shortened form; if wording differs, this section wins.

1. **Execute commands yourself.** Run CLI/git/HTTP commands directly unless a secret prompt is needed, then launch the command and let the operator paste the secret locally. Summarize results instead of listing commands for the user to run.
2. **Deploy protocol.** Feature branches must deploy as previews and report the preview URL (never deploy to production from a feature branch). Production deploys only come from `main` after merge. **Deploy commands MUST be run from `{{FRONTEND_DIR}}/`** to pick up project bindings.
3. **Working memory discipline.** Consider a Working Memory file when: (a) a task spans multiple real-world sessions, (b) VS Code shows "summarizing conversation" or ≥70% context, or (c) operator explicitly asks. For most single-session work, proceed directly — Working Memory is optional, not blocking.
4. **Decision logging.** Any non-trivial behavior change, data migration, or platform action must be reflected in `docs/decision-log.md`.
5. **No regressions.** All persistence changes must target the project's current platform abstraction — do not reintroduce deprecated providers.

## Architecture Overview
<!-- Customize per project. Keep this section updated with high-level data flow. -->
- Frontend: `{{FRONTEND_DIR}}/` — {{FRONTEND_STACK}}
- Backend / API: {{BACKEND_DESCRIPTION}}
- Data flow: {{DATA_FLOW_DESCRIPTION}}
- Key entry points: {{KEY_ENTRY_POINTS}}

## Quick Command Reference

```bash
# Frontend
cd {{FRONTEND_DIR}}
npm install              # First-time setup
npm run dev              # Development server
npm run build            # Production build
npm run typecheck        # TypeScript validation

# Deploy (preview — feature branches)
{{DEPLOY_COMMAND}} --branch <branch-name>

# Deploy (production — main branch only, after merge)
{{DEPLOY_COMMAND}} --branch main

# Platform CLI inspection
{{PLATFORM_CLI_INSPECT}}

# Verification gates (run after ANY code change)
npm run typecheck        # Must pass
npm run build            # Must succeed
# Manual smoke: {{SMOKE_CHECKLIST}}
```

## Key Folders / Files
<!-- Customize per project -->
- `{{FRONTEND_DIR}}/src/`: Application source
- `{{API_DIR}}/`: API / serverless functions
- `docs/`: Structured documentation (see `docs/README.md` for index)
- `docs/core/`: Essential docs to carry into hackathon repo
- `docs/architecture/`: Technical capability and system design
- `docs/ideas/`: Hackathon project ideas
- `docs/operations/`: Process guides, checklists, templates
- `docs/working_memory/`: Ephemeral agent task tracking (gitignored)

## Assistant Interaction Protocol (Strict Sequence)
1. **Intent Echo:** Restate user goal as bullet checklist (features, constraints, data touched).
2. **Assumptions:** Call out at most 2 inferred assumptions (or ask if blocking).
3. **Risk Class:** Label change Low / Medium / High (see below) + required tokens if any.
4. **Plan:** List files to read/edit, expected diff size, verification steps.
5. **Patch:** Apply minimal diff; avoid unrelated formatting.
6. **Verify:** Typecheck + build + (describe smoke steps). If unable to run, output exact commands.
7. **Summarize:** What changed, gates status, follow-ups.

## Risk Classes & Escalation Triggers
- **Low:** Pure docs, styling (CSS), isolated panel UI, copy tweaks.
- **Medium:** New worker file, new API endpoint, minor algorithm tweak, new utility function.
- **High:** Core rendering / state management, schema / data shape changes, performance-critical loops, global state patterns, storage migration.

Escalate / request token if: touching protected anchors, >3 core files, >150 LoC delta, adds dependency, alters persisted data format, or introduces new storage layer.

## Vibe Coding (Non‑Coder Operator) Guidance
When the user (non‑coder) asks for a change:
1. Restate goal as a concise checklist (what will change, files likely touched).
2. Identify risk level: core rendering / schema / worker performance / simple UI.
3. If risky token required (e.g., `CORE CHANGE OK`, `SCHEMA CHANGE OK`) and not provided: propose safer alternative or request token.
4. Propose minimal patch; avoid refactors unless solving an explicit pain point.
5. After patch: ensure typecheck + build succeed and note any manual smoke steps.
6. Update or create docs only if behavior, metrics, or public API changed — otherwise skip doc churn.
7. Offer a brief rationale when choosing between multiple implementations so the operator can approve.

Language: prefer plain language over jargon when explaining tradeoffs; surface 1–2 alternative approaches only if materially different in complexity or performance.

## Prompt Patterns (Examples)
**Good feature prompt:** "Add a toggle in the Settings panel to switch between algorithm A and algorithm B. Persist choice to localStorage. Success: user change reflected after reload; no regression in existing behavior."

**Good performance prompt:** "Reduce lookup overhead in the data processing worker (current O(n) scan). Goal: same outputs, fewer explored items (>10% improvement on medium inputs)."

**Weak prompt → Rewrite:** "Make it faster" → "Optimize priority queue: avoid sorting whole array each insert (use binary heap). Maintain identical output results."

## Minimal Patch Contract
Each change must include: reason, scope (files), diff size estimate, success criteria, rollback (revert commit). Avoid speculative refactors.

## Task Decomposition & Subagent Execution
Subagents are the **primary mechanism** for complex work. Use them by default for:
- Multi-file changes (≥3 files) or cross-surface edits (frontend + API + data)
- Research-heavy tasks (audits, schema analysis, migration planning)
- Any step that might consume >20% of context budget

**Subagent output requirements:** (1) short summary, (2) concrete deliverables (files, diffs, commands), (3) risks/follow-ups.

**Failure handling:** Retry failing subagent once with tighter prompt/context. On second failure, fall back to manual decomposition and report failure cause.

## Safer Alternative Rule
If user asks for broad refactor, first propose smallest path to accomplish user-visible benefit; proceed only after confirmation or token granting scope.

## Quality Gates (Always)
- Typecheck passes (no new TS errors).
- Build succeeds.
- Smoke: {{SMOKE_CHECKLIST}}
- Additional (if metrics): event appears in server-side whitelist and is displayed or intentionally documented as hidden.
- Run the relevant checks yourself whenever tooling is available. If a gate cannot be executed (e.g., missing dependency, platform constraint), call it out explicitly with the command you would have run and any fallback validation performed.

## Decision Log Template
```
## YYYY-MM-DD – <Title>
- Goal:
- Files:
- Diff: (added/removed LoC)
- Risk: low/med/high
- Gates: typecheck ✅|❌ build ✅|❌ smoke ✅|❌
- Follow-ups: (optional)
```

## Conventions & Patterns
- State bridging to globals: When a feature needs instrumentation, expose a single global setter rather than sprinkling tracking calls. Extend this pattern for new mode-level timers.
- Usage metrics categories (optional — only if this project uses analytics):
  - **Counters:** increment-only events.
  - **First-in-session counters:** fire a `*_first` event to also increment a separate `*_sessions` counter.
  - **Time sums:** send `{ type:'xyz_time', ms }` at end-of-session. Client accumulates, server declares `sum/count` keys.
  - **Buckets:** client chooses bucket id, server just counts.
- Adding a new metric: (1) emit in centralized tracking utility (2) add mapping server-side with counters or sum schema (3) extend stats display logic.
- Web worker performance (optional — only if this project uses Web Workers): Reuse spatial grid & neighbor caches keyed by integer parameters. When parameters change invalidating cache keys, clear caches. Preserve this to avoid memory bloat or stale data reuse.
- Large UI text generation: build condensed representation first (segments), then paginate to max length. Follow existing pagination patterns to avoid off-by-one bugs.
- Do NOT store PII; events are aggregate only. Keep new event payload fields whitelisted and non-identifying.

## Code Style Examples

### TypeScript/React Patterns
```typescript
// ✅ GOOD – Typed props, error handling, descriptive names
interface SearchQueryProps {
  query: string;
  category: string;
  maxResults: number;
}

async function runSearch({ query, category, maxResults }: SearchQueryProps): Promise<SearchResult> {
  if (!query || !category) {
    throw new Error('Query and category are required');
  }
  // ... implementation
}

// ❌ BAD – Any types, vague names, no validation
async function search(q: any, c: any, n: any) {
  return await doSearch(q, c, n);
}
```

### State Management
```typescript
// ✅ GOOD – Extract to custom hook
function useProcessingState() {
  const [result, setResult] = useState<Result | null>(null);
  const [processing, setProcessing] = useState(false);

  const process = useCallback(async (params: ProcessParams) => {
    setProcessing(true);
    try {
      const data = await runProcess(params);
      setResult(data);
    } finally {
      setProcessing(false);
    }
  }, []);

  return { result, processing, process };
}

// ❌ BAD – Inline in component body, scattered state
function DataPanel() {
  const [r, setR] = useState(null);
  const [c, setC] = useState(false);
  // ... 200 more lines of logic mixed with JSX
}
```

### Worker Communication
> _Optional — only applicable if this project uses Web Workers._

```typescript
// ✅ GOOD – Typed messages, throttled progress, error boundary
interface WorkerProgress {
  type: 'progress';
  current: number;
  total: number;
}

let lastUpdate = 0;
worker.onmessage = (e: MessageEvent<WorkerProgress>) => {
  if (e.data.type === 'progress') {
    // Throttle to ~5Hz (200ms minimum interval)
    if (Date.now() - lastUpdate > 200) {
      updateProgress(e.data.current, e.data.total);
      lastUpdate = Date.now();
    }
  }
};

// ❌ BAD – Untyped, unthrottled, no error handling
worker.onmessage = (e) => {
  updateProgress(e.data.c, e.data.t); // Floods main thread
};
```

### Usage Metrics
> _Optional — only applicable if this project uses usage tracking / analytics._

```typescript
// ✅ GOOD – Centralized in a single tracking module
import { track } from './utils/tracking';

function handleModeToggle(enabled: boolean) {
  track({ type: enabled ? 'mode_enter' : 'mode_exit' });
}

// ❌ BAD – Direct fetch calls scattered throughout components
fetch('/api/usage-event', {
  method: 'POST',
  body: JSON.stringify({ type: 'some_event' })
}); // Double counting risk + bypasses debouncing
```

## CLI Execution Policy (Generic)

### Core Mandate
The assistant MUST directly run every CLI command that does not require pasting or revealing a secret value. The operator will manually paste any secret when prompted. Do NOT ask the operator to run a command the assistant can execute. Do NOT instruct use of web UI when an equivalent CLI command exists unless:
- The CLI genuinely lacks required functionality, AND
- The limitation is stated clearly with a short justification.

### Quick Checklist
- Can I execute the command myself? → Run it and summarize the result.
- Does it require a secret? → Start the command and prompt the operator to paste the value locally.
- After 3–5 related commands, provide a concise outcome summary (IDs, URLs, counts) before moving on.
- If a failure occurs, retry once when transient and document the stderr plus next options if it persists.

### Operational Rules
1. Default to executing (not just printing) non-secret commands: deployments, listings, key reads/writes, migrations, inspections.
2. **Secret Entry Boundary:** For commands that prompt for a secret, the assistant initiates the command; the operator pastes the secret at the prompt locally.
3. **No UI Deferral:** Avoid telling user to click in a dashboard unless CLI route is missing. Provide citation if so.
4. **Batch & Verify:** After running 3–5 related CLI actions, summarize outcomes before proceeding.
5. **Idempotence First:** For potentially destructive commands, first run a dry-run/listing variant and show planned impact.
6. **Error Handling:** On command failure, attempt one focused retry if transient. If still failing, surface exact stderr + next options.
7. **Logging Hygiene:** Never log or store secret tokens; redact if accidentally echoed.

### Prohibited Patterns (require immediate self-correction)
- "Please run …" followed by a command the assistant could execute.
- Providing only a list of commands without executing them when execution is possible.
- Asking the operator to copy/paste output that can be fetched programmatically.

### Required Patterns
- Execute commands, then summarize concise results (status, IDs, counts, URLs) — not raw verbose dumps unless troubleshooting.
- For HTTP endpoint verification: use `Invoke-WebRequest` or `curl` capturing status + first bytes.
- When a secret is required: start the command, note "Operator: paste secret now (input hidden)", then continue.

## Context & Memory Protocols

### Working Memory Documents
When working on multi-step tasks (>30 minutes or >50 messages), maintain a working memory document:

**Location:** `docs/working_memory/<YYYY-MM-DD>_<task_name>.md`

**Required structure:**
```markdown
# Task: [Brief title]
Started: YYYY-MM-DD HH:MM
Status: [In Progress / Paused / Completed]

## Objective
[1–2 sentence goal]

## Progress
- [x] Step completed – key result
- [ ] Step in progress – blockers/notes

## Key Decisions
- Decision: [What was chosen]
  Rationale: [Why]
  Files: [Affected files]

## Current State
- Last file touched: …
- Next action: …
- Open questions: …
```

### When to Create / Update
- **Create:** At task start if expected duration >30 min.
- **Update:** Every 10–15 messages OR when approaching context budget limit.
- **Critical update:** IMMEDIATELY before context compaction (if VS Code warns "summarizing conversation").

### Post-Compaction Recovery
1. Read `docs/working_memory/<current_task>.md`.
2. Verify current state (git status, running processes).
3. Resume from "Next action" in working memory.
4. Continue updating working memory as work progresses.

### Cleanup
Upon task completion, move Working Memory files to `docs/archive/working_memory/` (or delete if trivial) and note the move in the decision log when relevant.

## Response Framing
- Start with a purposeful plan; reserve redundant labels only when they aid scanning.
- Keep follow-up updates focused on what changed since the prior message (delta reporting).
- Reference filenames and symbols with backticks for clarity.
- Keep answers concise — don't over-explain completed file operations.

## Common Failure Modes & Preventers
- **Double metric counting** → centralize tracking in a single module; never call `track()` from multiple places for the same semantic event.
- **Cache stale after parameter change** → ensure cache invalidation when keys/parameters change (e.g., spatial grid sizes, lookup indices).
- **Pagination regressions** → keep segment-first pagination; follow existing patterns to avoid off-by-one bugs.
- **Worker progress spam** → throttle ≥200 ms (mirror existing pattern); exceeding batch limits triggers immediate flush.
- **Speculative refactors** → apply safer alternative rule; smallest safe change first.
- **Silent metric accumulation** → document intentionally hidden counters; prefer visible display or explicit internal note.

## Adding Features (Pattern)
> _These patterns are optional — applicable when the project uses a web frontend with workers and/or analytics._

- **New engagement mode with timing:**
  1. Manage `[mode, setMode]` + `useRef` pattern in the relevant component.
  2. Expose a global setter (e.g., `window.__setNewMode`) for instrumentation bridging.
  3. In tracking util, add internal state (active flag, accumulation start/stop) & track `mode_first`, `mode_enter`, and final `mode_time` at finalize.
  4. Update server-side event whitelist with counters & sum definition.
- **New worker algorithm:**
  - Place under `src/utils/` or `workers/`. Maintain message API: input request object, progress emits, final response. Throttle progress to ≤5 Hz.
  - Keep pure, no DOM. Use caches keyed off request parameters to avoid recomputation.

## Submodule & Vendor Policy

`vendor/*` directories contain **third-party upstream repos** added as git submodules. The following rules have the same precedence as Operational Guardrails:

1. **Never commit inside submodules.** Do not run `git add`, `git commit`, or `git push` from within any `vendor/` directory. The agent must verify its `cwd` is the parent repo root before any git write operation.
2. **Submodule updates via parent only.** To update a submodule's pinned commit, run `git submodule update --remote vendor/<name>` from the parent repo root, then commit the updated gitlink in the parent.
3. **No tracked modifications.** Never modify, delete, or create tracked files inside `vendor/*`. Reading for context is always allowed.
4. **Local-only ignores.** Transient/generated files (Docker volumes, build artifacts, `.env.*`, `workspace-data/`) must be excluded via `vendor/<name>/.git/info/exclude` — a local-only mechanism that is never committed to the submodule.
5. **No secrets in vendor.** Never commit `.env` files, private keys, mnemonics, or wallet configs inside submodules or anywhere in the repo.

### Sandbox-Workspace Rules
- This repo (`sui-playground`) is a **private training sandbox** — not the hackathon submission repo.
- **Do not push** without explicit operator approval.
- **Docs-only changes:** Pushing to origin is allowed when the operator explicitly includes "commit + push" in the prompt.
- **Sui keys & wallet config:** Treat `~/.sui/`, `sui.keystore`, and any env var containing mnemonics as secrets — never log, commit, or echo.
- **Docker state:** `vendor/builder-scaffold/docker/workspace-data/` is ephemeral — always ignored, never committed.
- **Environment switching:** Always verify `sui client active-env` before running transactions to avoid accidental mainnet/testnet operations.
- **Prefer notes over commits:** Use `notes/` directory for logs, outputs, and incidental observations rather than committing generated content.

## High-Risk Surfaces

- **Submodule boundaries** — never commit inside `vendor/*`; see Submodule & Vendor Policy above
- **Sui key material** — private keys, mnemonics, wallet configs
- **Docker compose state** — workspace-data volumes, network configs
- **Core application logic** — main entry points, global state
- **API contracts** — persistence, auth, protocol definitions
- **Data pipelines** — run with DRY_RUN first; changes can corrupt production data

## Hackathon Narrative & Emotional Signal Priority (UI + Demo Only)

CivilizationControl must communicate **calm authority, sovereignty, and governance** — not generic SaaS vocabulary. This guardrail applies exclusively to UI-facing elements and demo framing materials.

**Canonical references:**
- `docs/strategy/civilizationcontrol-voice-and-narrative.md` — voice, labels, microcopy, Narrative Impact Check
- `docs/strategy/civilizationcontrol-hackathon-emotional-objective.md` — emotional target, Five-Pillar Lens, 3-Second Check, consequence layer

**Agent rules:**
1. **Evaluate UI labels** against the label mapping table (§3 of the canonical doc). Do not default to generic SaaS terms (e.g., Dashboard, Admin, Objects, Settings, Notifications) unless explicitly justified with documented rationale.
2. **Run the Narrative Impact Check** (§8 of the canonical doc) when generating or reviewing:
   - Navigation labels
   - Page titles
   - Headings and subheadings
   - Empty states and system messages
   - Demo scripts and demo framing documents
3. **Prioritize clarity + authority** over feature density in demo surfaces. Demo narration should describe governance decisions, not button clicks.
4. **Emotional signal:** Calm power, governance, authority — in that priority order. No celebration ("Congratulations!"), no hedging ("Something may have gone wrong"), no theatrics.
5. **Excluded from this rule:** README files (internal/technical), marketing copy (handled externally), vendor code, non-UI technical documentation (architecture docs, runbooks, feasibility reports, decision logs), and code comments.

## Hackathon Rules Compliance Policy

Official hackathon event rules are captured in `docs/research/hackathon-event-rules-source.md` with a practical digest at `docs/research/hackathon-event-rules-digest.md`.

**Agent rules:**
1. **Before generating Entry code**, verify the hackathon has started — entries must be developed on or after the start date (Section 5).
2. **Before creating token/financial mechanics**, verify no security/equity characteristics — entries must not be securities, commodities, or confer ownership/revenue-share rights (Section 5).
3. **Before submission**, cross-check repo hygiene: original work, GitHub-hosted, Deepsurge-registered, within deadline (31 March 2026 23:59 UTC).
4. **Consult the digest** when evaluating idea feasibility, judging criteria alignment, or bonus prize strategy.
5. An eligible Entry may win **max 1 prize**. Player vote = 25% of Best Entry score. Stillness deployment bonus window = 14 days post-close.
6. **No vote manipulation** — do not automate vote solicitation, trading, or purchasing.

## Official Documentation Reference Policy

EVE Frontier maintains official builder documentation at https://docs.evefrontier.com/ (GitBook). These docs are actively being rewritten for the Sui blockchain transition — many pages contain `//TODO` placeholders.

**Reading hierarchy:** (1) `vendor/builder-documentation` for local content reads (submodule added 2026-02-18), (2) GitBook URLs (`docs.evefrontier.com`) for public citation, (3) `llms.txt` for structural change detection.

**Agent rules:**
1. When generating chain interaction flows, sponsorship patterns, or deployment steps, consult `docs/research/evefrontier-builder-docs-map.md` and the linked official docs pages.
2. Code in `vendor/world-contracts` is canonical; GitBook is explanatory. If behavior described in docs contradicts Move code, the code wins — flag the discrepancy.
3. If official docs show a "Last updated" date newer than the reference map's last internal review date, re-check before finalizing logic.
4. Do not copy GitBook content into internal docs — summarize insights and link to the official page.
5. Key pages to always consult: "Interfacing with the EVE Frontier World" (sponsored transactions, read/write paths), "EVE Frontier World Explainer" (three-layer architecture), "Introduction to Smart Contracts" (capability, witness, hot-potato patterns), "Object Model" (Sui object types), "Ownership Model" (cap-based access hierarchy), "@evefrontier/dapp-kit" (SDK for builder dApps).
6. Freshness: Review `docs/research/evefrontier-builder-docs-map.md` weekly during active development; always re-check before hackathon submission freeze.

## SUI Documentation Policy

Sui chain-level documentation at https://docs.sui.io is canonical for all blockchain-level mechanics (object model, gas, PTBs, abilities, events, storage, coins, cryptographic primitives).

**Agent rules:**
1. When reasoning about object model, gas mechanics, PTB composition, coin/token standards, dynamic field behavior, events, on-chain randomness, package upgrades, or storage — consult SUI docs via `docs/research/sui-documentation-reference-map.md`.
2. Use `https://docs.sui.io/llms.txt` as the machine-readable entry point for locating canonical pages.
3. **Canonical hierarchy:** `vendor/world-contracts` code > SUI docs (docs.sui.io) > EVE Frontier GitBook (docs.evefrontier.com) > internal docs. If ambiguity exists between GitBook and SUI docs, SUI docs override.
4. Do not copy SUI documentation content into this repository — summarize insights and link to the canonical page.
5. Key constraints to always verify against SUI docs: 250 KB object size limit, 1000 PTB command limit, 1024 dynamic fields per tx, 32 struct field limit, 8 Groth16 public inputs, shared object consensus latency, hot-potato consumption requirements.
6. Freshness: Check SUI `llms.txt` once per week during active development; always re-check before hackathon submission freeze.

## Documentation Rules

1. All new markdown documents must be placed inside a categorized subfolder under `docs/`.
2. Do NOT create markdown files directly under `docs/` root (only `docs/README.md` lives at root).
3. Every new document must be categorized as one of: `core`, `architecture`, `ideas`, `research`, `operations`, `sandbox`, `archive`.
4. When creating a new doc, update `docs/README.md` index.
5. `research/` and `sandbox/` documents are not intended for the hackathon submission repo.
6. **Retention classification is mandatory.** All docs must begin with a header block:
   ```
   # Document Title

   **Retention:** [Carry-forward | Prep-only | Sandbox-only | Archive]
   ```
   Classifications: **Carry-forward** (copy to hackathon repo), **Prep-only** (research/planning, do not copy), **Sandbox-only** (devnet artifacts, temporary), **Archive** (superseded, kept for traceability).
7. Agents must classify retention before committing any new document. If uncertain, default to **Prep-only** and flag for review.

## Sui Local Devnet

For local Sui devnet operations (start, build, publish, troubleshoot), read `docs/architecture/sui-playground.md` first. Log outputs to `notes/sui-local-smoketest.md` (untracked, local-only).

## External Spec Intake Policy (ChatGPT / Gemini Prompts)

The operator may paste a "spec" produced by an external LLM. Treat it as **INTENT**, not strict instructions.

**Required behavior:**
1. Extract the intended outcome.
2. Validate against repository guardrails (hackathon compliance, vendor/submodule policy, no secrets, push rules).
3. Check workspace reality and prefer existing patterns over assumptions in the spec.
4. If the spec is inefficient, outdated, or architecturally unsound, propose a safer or cleaner approach and proceed.
5. If the spec implies unsafe actions (e.g., copying sandbox code into hackathon submission, editing `vendor/`, pushing without authorization), **STOP** and propose a compliant alternative.

## When Unsure
- Search existing patterns first (grep for similar feature names).
- Mirror existing instrumented modes for any UI mode needing session vs enter counts + time.
- Keep serverless functions < ~150 lines, no external state besides managed storage, return 4xx on validation errors early.

<!-- End – Provide feedback if additional sections should be documented. -->
