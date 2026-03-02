# Agents Context — Sui Playground (Hackathon Planning Workspace)

> **NOTE:** This repository is a multi-project planning workspace. On March 11, documentation copied into submission repos must update project name and scope to the specific hackathon build.

Purpose: Provide persistent, high-signal context and guardrails for agent mode in this repository. VS Code will automatically ingest this file (1.104+). Keep it short and link out for depth.

## Workflow primer

- Start every reply with a brief acknowledgement plus a high-level plan.
- Manage work through the todo list tool with exactly one item `in-progress`; update statuses as soon as tasks start or finish.
- Report status as deltas—highlight what changed since the last message instead of repeating full plans.
- Run fast verification steps yourself when feasible and note any gates you couldn't execute.

## Project quick facts

- What: Pre-hackathon sandbox for Sui tooling validation and EVE Frontier governance experimentation
- Frontend: N/A (sandbox workspace — no deployed frontend)
- Backend: N/A (sandbox workspace — experiments run against local Sui devnet)
- Data: Local Sui devnet state + vendor submodule references (read-only)

> **Glossary note:** If you see "SWE" in voice notes or transcripts, it refers to **Sui** (the blockchain). Transcription tools frequently mishear it.

Useful entry points:
- **Documentation Index**: `docs/README.md` — central map for all project documentation
- **Guardrails**: `.github/copilot-instructions.md` (source of truth for patterns)
- **Decisions**: `docs/decision-log.md` (newest first)
- **System Spec**: `docs/core/spec.md` — CivilizationControl boundaries, on-chain model, risk model

## Three-tier boundaries

✅ **Always do (no permission needed):**
- Read any file for context gathering
- Run build, test, lint commands
- Update working memory documents (`docs/working_memory/`)
- Write to `docs/` (decision logs, working memory, guides)
- Use documentation lookup tools (MCP servers, etc.)
- Execute automated test and verification steps

⚠️ **Ask first (coordinate before action):**
- Modifying core API contracts or protocol definitions
- Changes to high-risk runtime surfaces (vendor submodule boundaries, Sui key material, Docker compose state)
- Signing, certificate, or credential handling
- Creating distribution packages
- Breaking changes to cross-system payload schemas
- Adding external dependencies
- Changes spanning >3 core files or >150 LoC delta

🚫 **Never do (hard boundaries):**
- Commit secrets, certificates, private keys
- Deploy unsigned or unverified artifacts to users
- Remove failing tests to make CI pass
- Make changes outside your designated repository scope
- Skip mandatory verification scripts before distribution
- Store PII in analytics or telemetry

## Operational guardrails (summary)

Authoritative language for every mandate lives in `.github/copilot-instructions.md`. This section is a quick primer so agents see the rules even if only `AGENTS.md` is loaded.

- **Run the commands yourself.** Execute CLI / git / HTTP checks directly unless a secret prompt is required. Launch the command, ask the operator to paste secrets locally, and summarize results.
- **Preview vs production deploys.** Feature branches deploy to preview environments. Production deploys only come from `main` after merge.
- **Working memory discipline.** Consider a Working Memory file when: (a) a task spans multiple real-world sessions, (b) VS Code shows "summarizing conversation" or ≥70% context, or (c) operator explicitly asks.
- **Decision logging.** Any non-trivial behavior change, data migration, or platform action must be reflected in `docs/decision-log.md`.

Treat this list as a pointer; if wording differs, the `.github/copilot-instructions.md` version wins.

### External Spec Handling

When the operator pastes an externally generated plan or spec (e.g., from ChatGPT or Gemini), treat it as **intent**. Reconcile it with `.github/copilot-instructions.md` guardrails before execution. Full policy lives in `.github/copilot-instructions.md` § "External Spec Intake Policy".

## Agent operating rules (must follow)

1. Prefer smallest safe change; don't refactor broadly without explicit approval.
2. Follow the workflow primer: purposeful preamble + plan, synchronized todo list, and delta-style progress updates.
3. CLI mandate: When possible, run CLI commands yourself and summarize results. Prompt user only for secret inputs. Never commit secrets.
4. Sensitive edits: Treat worker entry points, production config, and build pipeline files as sensitive; ask before structural changes.
5. **Manual deployment may be required**: Check whether your deployment platform auto-deploys on push. If not, YOU must execute the deploy command after pushing.
6. **Feature branch deploys**: Always use feature-branch-scoped preview deploys. Never deploy feature branches to production.

## Working Memory & Context Management

Agent Mode enforces a per-conversation context limit. When the buffer fills, VS Code silently summarizes prior turns, which is lossy. A Working Memory file helps preserve task context.

### When to use Working Memory (optional)

Recommended—not required—for:
- Tasks spanning **multiple real-world sessions** (overnight, multi-day)
- After seeing a **"summarizing conversation"** toast or ≥70% context warning
- When the **operator explicitly requests** added rigor or handoff prep

For typical single-session work, proceed directly.

### Required metadata block

```markdown
# Working Memory — <Project / initiative>
**Date:** YYYY-MM-DD HH:MMZ
**Task Name:** <What you are doing>
**Version:** <increment when meaningfully edited>
**Maintainer:** <Agent / human pairing>
```

### Template

```markdown
## Objective  ⬅ keep current
[1–2 sentence mission]

## Progress
- [x] Major milestone – note
- [ ] Upcoming step – blocker/notes

## Key Decisions
- Decision: <What>
  Rationale: <Why>
  Files: <Touched files>

## Current State  ⬅ keep these bullets current
- Last file touched: …
- Next action: …
- Open questions: …

## Checkpoint Log (self-audit)
- Agent self-check (Turn ~X / HH:MM): confirmed Objective + Next action before editing <file>.

## Context Preservation
- Active branch / services verified
- Last checkpoint: [Time / description]
- External references consulted
```

### Recovery anti-patterns
- Do **not** continue after a summarization event without re-reading context.
- Do **not** rely solely on chat history for architecture decisions.
- Do **not** invent missing details—ask the operator when information is unclear.

### Maintenance rhythm
- Update after every major milestone or multi-file edit.
- Before stepping away, ensure "Next action" reflects the very next command.
- When you see the summarization toast: (1) stop, (2) re-read the file, (3) append recap.

### Rehydration (`/rehydrate`)
When resuming after context loss: (1) read Working Memory file, (2) restate Objective/Status/Next Step, (3) ask confirmation before resuming. See `.github/prompts/rehydrate.prompt.md`.

### Cleanup
- Move completed Working Memory files to `docs/archive/working_memory/` or delete.
- Keep at most one active file per task.
- If exceeding ~200 lines, summarize into decision log and trim.
> **CivilizationControl sprints:** Use the extended template in `docs/core/memory.md`, which adds Environment State, Evidence Captured, Commands Run, and Next Step Pointer sections.
## Context Discipline & Subagent Policy

Subagents are the **primary mechanism** for complex work. Use them by default for:
- Multi-file changes (≥3 files) or cross-surface edits
- Research-heavy tasks (audits, schema analysis, migration planning)
- Any step that might consume >20% of context budget

**Subagent output requirements:** (1) short summary, (2) concrete deliverables, (3) risks/follow-ups.

**Fallback:** Break into smallest safe chunks; ask permission before proceeding with reduced scope.

## Submodule & Vendor Policy

`vendor/*` directories contain **third-party upstream repos** added as git submodules. These rules are non-negotiable:

🚫 **Never do:**
- Create commits inside any `vendor/` submodule (`git -C vendor/* commit` — forbidden)
- Modify, delete, or add tracked files within `vendor/*`
- Stage submodule-internal changes from the parent repo
- Commit local Docker state, caches, or generated files from submodules (e.g., `docker/workspace-data/`, `.env.testnet`)

✅ **Correct patterns:**
- **Update submodule pin:** Change the pinned commit in the *parent* repo only — `git submodule update --remote vendor/<name>`, then commit the new gitlink from the parent
- **Local-only ignores:** Use `vendor/<name>/.git/info/exclude` for transient files (Docker volumes, build artifacts, local env files). This is local-only and never committed to the submodule
- **Read freely:** Reading submodule source for context/reference is always allowed
- **Document, don't commit:** Prefer `notes/` markdown logs over committing incidental changes

### Workspace-Specific Rules (sui-playground sandbox)
- This is a **private training sandbox**, NOT the hackathon submission repo
- **Never push** from this repo without explicit operator approval
- **Sui keys & wallet config:** Treat `~/.sui/` and any `.env` containing mnemonics/private keys as secrets — never log, commit, or echo them
- **Docker state:** `vendor/builder-scaffold/docker/workspace-data/` is ephemeral local state — always excluded, never committed
- **Environment switching:** When switching between local/testnet/mainnet, always verify `sui client active-env` before running transactions

## High-risk surfaces (coordinate before changing)

- **Submodule boundaries** — never commit inside `vendor/*`; see Submodule & Vendor Policy above
- **Sui key material** — private keys, mnemonics, wallet configs
- **Docker compose state** — workspace-data volumes, network configs
- **Core application logic** — main entry points, rendering loops, global state
- **API / Worker entrypoints** — persistence, auth, API contracts
- **Data pipelines** — run with DRY_RUN first; changes can corrupt production data
- **Shared schemas** — coordinate with consumers before format changes

## Safety & boundaries

- Never commit secrets; use env vars or `.env.example` for placeholders
- Avoid large diffs (>150 LoC) or dependency adds without explicit approval
- For data migrations or bulk ops, create scripts under `tools/` with `DRY_RUN` flag
- Working memory docs in `docs/working_memory/` are gitignored — ephemeral, not permanent

Append material decisions to `docs/decision-log.md` using the template in `.github/copilot-instructions.md`.

## Hackathon Narrative & Emotional Signal Priority (UI + Demo Only)

CivilizationControl must communicate **calm authority, sovereignty, and governance** — not generic SaaS vocabulary. This guardrail applies to all player-facing surfaces and demo materials.

**Canonical references:**
- `docs/strategy/civilization-control/civilizationcontrol-voice-and-narrative.md` — voice, labels, microcopy, Narrative Impact Check
- `docs/strategy/civilization-control/civilizationcontrol-hackathon-emotional-objective.md` — emotional target, Five-Pillar Lens, 3-Second Check, consequence layer

**Agent rules:**
1. **Evaluate UI labels** against the label mapping table in the canonical narrative doc. Do not default to generic terms (Dashboard, Admin, Objects, Settings, Notifications) unless explicitly justified with a documented rationale.
2. **Run the Narrative Impact Check** (§8 of the narrative doc) when generating or reviewing: navigation labels, page titles, headings, empty states, confirmations, fault messages, or demo scripts.
3. **Prioritize clarity + authority** over feature density in demo surfaces. Show governance, not feature tourism.
4. **Excluded from this rule:** README files, internal technical documentation, code comments, architecture docs, decision logs, vendor code, and marketing copy.

## Hackathon Rules Compliance Policy

Official hackathon event rules are captured in `docs/research/hackathon-event-rules-source.md` with a practical digest at `docs/research/hackathon-event-rules-digest.md`.

- **Before generating Entry code**, verify the hackathon has started (entries must be developed on or after the start date).
- **Before creating token/financial mechanics**, verify no security/equity characteristics (Section 5 of rules).
- **Before submission**, cross-check repo hygiene: original work, GitHub-hosted, Deepsurge-registered, within deadline (31 March 2026 23:59 UTC).
- **Consult the digest** whenever evaluating idea feasibility, judging criteria alignment, or bonus prize strategy.
- An eligible Entry may win **max 1 prize**. Player vote = 25% of Best Entry score.

## Official Documentation Reference Policy

EVE Frontier maintains official builder docs at https://docs.evefrontier.com/. These docs are actively being rewritten for the Sui transition and contain significant `//TODO` sections.

**Reading hierarchy:** (1) `vendor/builder-documentation` for local content reads (submodule added 2026-02-18), (2) GitBook URLs for public citation, (3) `llms.txt` for structural change detection.

- **Before assuming contract interaction behavior** (sponsored transactions, access control flows, deployment steps), consult `docs/research/evefrontier-builder-docs-map.md` for the relevant official page and read it.
- **Code is canonical; docs are explanatory.** `vendor/world-contracts` Move code takes precedence over GitBook descriptions. Flag discrepancies.
- **Key pages to consult:** "Interfacing with the EVE Frontier World" (write/read paths, sponsored tx pattern), "World Explainer" (three-layer architecture), "Introduction to Smart Contracts" (capability/witness/hot-potato patterns), "Object Model", "Ownership Model", "@evefrontier/dapp-kit".
- **Freshness:** If official docs show a "Last updated" date newer than the reference map's review date, re-check before finalizing logic. Review weekly during active development.

## SUI Documentation Policy

Sui chain-level documentation at https://docs.sui.io is canonical for all blockchain mechanics. Use `https://docs.sui.io/llms.txt` as the machine-readable index for locating pages.

- **Before assuming chain behavior** (object model, gas, PTBs, coins, events, limits, abilities), consult `docs/research/sui-documentation-reference-map.md` for the relevant SUI docs page.
- **Canonical hierarchy:** `vendor/world-contracts` code > SUI docs > EVE Frontier GitBook > internal docs. Flag discrepancies.
- **Key areas requiring SUI docs:** object ownership types, dynamic field behavior, PTB composition rules, gas budget estimation, Coin<T> standard, Groth16 proof format, sponsored transaction protocol, on-chain randomness calling conventions.
- **Freshness:** Check SUI `llms.txt` once per week during active development. Always re-check before hackathon submission freeze. Do not mirror content locally.

## Documentation Rules

1. All new markdown documents must be placed inside a categorized subfolder under `docs/`.
2. Do NOT create markdown files directly under `docs/` root (only `docs/README.md` lives at root).
3. Categories: `core`, `architecture`, `ideas`, `research`, `operations`, `sandbox`, `archive`.
4. When creating a new doc, update `docs/README.md` index.
5. `research/` and `sandbox/` documents are not intended for the hackathon submission repo.
6. **Retention classification is mandatory.** All docs must begin with: `**Retention:** [Carry-forward | Prep-only | Sandbox-only | Archive]`. Agents must classify before commit. Default to **Prep-only** if uncertain.

## Fast context to load on start

- Read `.github/copilot-instructions.md` (source of truth)
- Read `AGENTS.md` (this file)
- Skim last ~40 lines of `docs/decision-log.md` for recent initiatives
- Review `docs/README.md` for documentation map and taxonomy
- **For Sui local devnet operations**, read `docs/architecture/sui-playground.md` first
- **For CivilizationControl implementation**, read `docs/core/spec.md` (system spec) and `docs/core/day1-checklist.md` (Day-1 validation)

— Keep this file concise. Update when operating rules or architecture materially change.
