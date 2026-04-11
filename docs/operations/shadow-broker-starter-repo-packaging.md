# Shadow Broker Protocol — Starter-Repo Packaging Recommendation

**Retention:** Prep-only

**Date:** 2026-03-30
**Status:** Proposal — audit/recommendation only. No export created.
**Source conversation:** VS Code Agent Mode, packaging audit session (2026-03-30)
**Template reference:** `docs/operations/starter-repo-packaging-recommendation.md` (CC packaging model)

---

## Purpose

This document records the full-repo packaging recommendation for extracting a clean **Shadow Broker Protocol (SBP)** starter repo from `sui-playground`. It follows the same structure and reasoning model as the CivilizationControl packaging recommendation, adapted to Shadow Broker's distinct architecture.

**Key constraint:** `sui-playground` remains the source/evidence repository and should NOT itself be transformed into the starter repo. A new, clean repo is created; artifacts are selectively carried forward per this recommendation.

**Key architectural difference from CC:** Shadow Broker is a **standalone dApp** — no world-contracts dependency, no EVE Frontier extension system, no vendor submodules required. The project integrates three Mysten Labs technologies (Sui Move + Walrus + Seal) as npm packages, not as on-chain dependencies from the EVE Frontier world.

---

## Packaging Categories

| Category | Meaning |
|----------|---------|
| **Shared-starter** | Reusable across multiple hackathon project repos |
| **SBP-starter** | Specific to the Shadow Broker Protocol submission repo |
| **Evidence-only** | Remains in `sui-playground` only — not exported |
| **Local-only** | Machine/user/environment-specific — never exported |
| **Archive-only** | Historical/superseded — remains in source repo for traceability |

---

## A. Recommended Shared-Starter Set

Files/patterns reusable across any EVE Frontier hackathon project repo. Identical to CC packaging recommendation Section A.

| Item | Action | Notes |
|------|--------|-------|
| `.gitignore` | Carry verbatim (minor trim) | Remove ZK-specific patterns (`*.ptau`, `*.zkey`, `*.wasm`, `*.r1cs`) — SBP has no ZK features |
| `.github/copilot-instructions.md` | Carry **structure**, rewrite **content** | ~60% verbatim (guardrails, CLI policy, quality gates); ~40% project-specific rewrite (Architecture Overview, project facts, remove CC narrative/voice rules, remove vendor/submodule policy section, add Walrus/Seal/audio context) |
| `.github/security-guidelines.md` | Carry verbatim | OWASP baseline, project-agnostic |
| `.github/prompts/rehydrate.prompt.md` | Carry verbatim | Context-amnesia recovery, project-agnostic |
| `.github/prompts/vibe-bootstrap.prompt.md` | Carry verbatim | Onboarding wizard, project-agnostic |
| `.github/skills/deploy/SKILL.md` | Carry verbatim | Generic Cloudflare deploy skill |
| `.github/skills/docker-ops/SKILL.md` | Carry verbatim | Generic Docker operations skill |
| `.vscode/settings.json` | Carry verbatim | No machine-specific content |
| `.vscode/extensions.json` | Carry verbatim | Copilot Chat, REST Client, GitHub PR |
| `.vscode/prompts/plan.prompt.md` | Carry verbatim | Change-planning prompt, project-agnostic |
| `AGENTS.md` | Carry **structure**, rewrite **content** | Shared scaffold with SBP-specific facts |
| `GITHUB-COPILOT.md` | Carry **structure**, rewrite | Thin pointer file; update references |
| `llms.txt` | Carry **structure**, rewrite | LLM index; update to SBP docs map |
| `templates/cloudflare/` | Carry verbatim (3 files) | CF deployment templates for React frontend |

**Total:** ~16 items forming a reusable starter scaffold.

---

## B. Recommended SBP-Starter Set

Files specific to the Shadow Broker Protocol hackathon submission.

### Config & Meta

| Item | Action | Notes |
|------|--------|-------|
| `.github/instructions/move.instructions.md` | Carry verbatim | Move conventions — project-agnostic |
| `.github/instructions/typescript-react.instructions.md` | Carry verbatim | TS/React/Tailwind conventions |
| `.vscode/tasks.json` | Carry with **path update** | Default `movePkgPath` → `contracts/shadow_broker` |
| `LICENSE` | Carry verbatim (MIT) | |

### Assets

| Item | Action | Notes |
|------|--------|-------|
| `assets/audio/` | **Create fresh** during sprint | Demo audio recording (scripted "intercepted comms") + 2-second teaser extraction. See demo beat sheet for audio spec. No existing assets to carry. |

**Note:** Unlike CC, Shadow Broker has **no SVG/icon assets** to carry. The CC topology icon tree (20 SVGs + 5 READMEs) is entirely CC-specific and excluded.

### Docs — Carry-Forward (8 files across 3 categories)

| Category | Count | Files | Action |
|----------|-------|-------|--------|
| **core/** | 2 | `hackathon-repo-conventions.md`, `memory.md` | Verbatim for conventions; **rewrite** memory.md (replace "CivilizationControl" references with "Shadow Broker Protocol") |
| **strategy/** | 4 | `shadow-broker-product-vision.md`, `shadow-broker-technical-architecture.md`, `shadow-broker-demo-beat-sheet.md`, `shadow-broker-validation-evidence.md` | Carry with **light edits**: update `Retention: Carry-forward`, remove "Prep-only" / sandbox disclaimers, update any stale SDK coordinates |
| **index + log** | 2 | `docs/README.md` (rewrite), `docs/decision-log.md` (fresh/empty) | |

**Total carry-forward docs: 8** (vs CC's ~41). Shadow Broker is architecturally simpler — one product vision, one tech architecture, one demo script, one validation evidence doc. No separate PTB library, no UX specs, no architecture audits, no validation reports.

### Vendor Submodules

| Submodule | Required? | Rationale |
|-----------|-----------|-----------|
| `vendor/world-contracts` | **No** | SBP is standalone — no EVE Frontier world-contracts dependency |
| `vendor/builder-scaffold` | **No** | No devnet tooling dependency |
| `vendor/evevault` | **No** | No wallet signing integration needed |
| `vendor/builder-documentation` | **No** | Reference only — not needed in SBP repo |

**Shadow Broker has zero vendor submodule requirements.** All external dependencies are npm packages (`@mysten/sui`, `@mysten/seal`, `@mysten/walrus`). This dramatically simplifies the starter repo — no `.gitmodules`, no submodule initialization, no vendor policy enforcement.

---

## C. Evidence-Only Set (remain in sui-playground)

| Category | Count | Items |
|----------|-------|-------|
| `sandbox/shadow-broker-validation/` | 11 files + build artifacts | Move contracts (intel_object.move, marketplace.move, tests), TS validation scripts (on-chain-smoke, walrus-smoke, seal-smoke, e2e-smoke), package.json, tsconfig, Move.toml/Lock, Pub.testnet.toml |
| `docs/operations/shadow-broker-validation-plan.md` | 1 file | 5-phase validation plan — prep-only, execution reference |
| `docs/strategy/_shared/hackathon-portfolio-roadmap.md` | 1 file (tangential) | Multi-project scoring; contains SBP score but is shared/portfolio-level |
| `notes/shadow-broker-publish-local.md` | 1 file | Local devnet publish log (package IDs, tx digests) |
| `notes/sbp-mint-output.json` | 1 file | CLI mint attempt error output |
| `Pub.local.toml` | 1 file | Local publication metadata referencing sandbox validation |
| `docs/decision-log.md` entry | 1 entry | "Shadow Broker Protocol E2E Validation Complete" (2026-03-11) |

**Total evidence-only: ~16 items.** These represent the pre-hackathon validation work and must remain in `sui-playground` as the audit trail.

---

## D. Local-Only Set (never export)

| Item | Rationale |
|------|-----------|
| `notes/` (entire directory) | Gitignored. Contains localnet package IDs, testnet addresses, transaction outputs. |
| `docs/working_memory/` | Gitignored. Ephemeral agent task files. |
| `.vscode/mcp.json` (if created) | Machine-specific MCP server config. |
| Any `.env` or `.env.*` files | Secrets. |
| `sandbox/shadow-broker-validation/build/` | Compiled Move bytecode artifacts. |
| `sandbox/shadow-broker-validation/ts-scripts/node_modules/` | npm install artifacts. |

---

## E. Root Starter Repo Shape

Proposed top-level structure for a clean Shadow Broker Protocol starter repo:

```
ShadowBrokerProtocol/
├── .github/
│   ├── copilot-instructions.md        ← REWRITE (shared scaffold + SBP content)
│   ├── security-guidelines.md         ← verbatim
│   ├── instructions/
│   │   ├── move.instructions.md       ← verbatim
│   │   └── typescript-react.instructions.md ← verbatim
│   ├── prompts/
│   │   ├── rehydrate.prompt.md        ← verbatim
│   │   └── vibe-bootstrap.prompt.md   ← verbatim
│   └── skills/
│       ├── deploy/SKILL.md            ← verbatim
│       └── docker-ops/SKILL.md        ← verbatim
├── .vscode/
│   ├── settings.json                  ← verbatim
│   ├── extensions.json                ← verbatim
│   ├── tasks.json                     ← path update (→ contracts/shadow_broker)
│   └── prompts/
│       └── plan.prompt.md             ← verbatim
├── contracts/
│   └── shadow_broker/                 ← NEW: production Move code (written during sprint)
│       ├── Move.toml
│       ├── sources/
│       │   ├── intel_object.move
│       │   └── marketplace.move
│       └── tests/
│           └── shadow_broker_tests.move
├── apps/
│   └── web/                           ← NEW: React frontend (written during sprint)
│       ├── package.json               ← deps: @mysten/sui, @mysten/seal, @mysten/walrus,
│       │                                 @mysten/dapp-kit-react, react, tailwindcss
│       ├── tsconfig.json
│       ├── vite.config.ts             ← Vite + React
│       ├── index.html
│       └── src/
│           ├── App.tsx
│           ├── main.tsx
│           ├── hooks/
│           │   ├── useWalrusUpload.ts
│           │   ├── useSealEncrypt.ts
│           │   ├── useSealDecrypt.ts
│           │   └── useTeaserPlayback.ts
│           ├── components/
│           │   ├── UploadIntel.tsx
│           │   ├── MarketplaceBrowser.tsx
│           │   ├── IntelCard.tsx
│           │   ├── TeaserPlayer.tsx
│           │   ├── PurchaseButton.tsx
│           │   └── DecryptPlayer.tsx
│           ├── pages/
│           │   ├── UploadPage.tsx
│           │   ├── MarketplacePage.tsx
│           │   └── MyIntelPage.tsx
│           └── utils/
│               ├── aes.ts             ← AES-256-GCM encrypt/decrypt
│               ├── teaserExtract.ts   ← Web Audio API 2-second clip extraction
│               └── config.ts          ← Network URLs, package IDs, key server IDs
├── assets/
│   └── audio/                         ← NEW: demo audio assets (created during sprint)
│       └── README.md                  ← Spec for demo audio recording
├── docs/
│   ├── README.md                      ← REWRITE (SBP-only doc index)
│   ├── decision-log.md                ← FRESH (empty template)
│   ├── core/
│   │   ├── hackathon-repo-conventions.md  ← verbatim
│   │   └── memory.md                     ← REWRITE (SBP working memory template)
│   ├── strategy/
│   │   ├── shadow-broker-product-vision.md         ← carry, update retention
│   │   ├── shadow-broker-technical-architecture.md ← carry, update retention
│   │   ├── shadow-broker-demo-beat-sheet.md        ← carry, update retention
│   │   └── shadow-broker-validation-evidence.md    ← carry, update retention
│   └── working_memory/                ← gitignored, created on use
├── templates/
│   └── cloudflare/                    ← verbatim (3 files)
├── .gitignore                         ← verbatim (minor trim: remove ZK patterns)
├── AGENTS.md                          ← REWRITE
├── GITHUB-COPILOT.md                  ← REWRITE
├── LICENSE                            ← verbatim
├── llms.txt                           ← REWRITE
└── README.md                          ← FULL REWRITE
```

### Key Structural Differences from CC Starter Repo

| Aspect | CC Repo | SBP Repo | Reason |
|--------|---------|----------|--------|
| `vendor/` | 2+ submodules (world-contracts, builder-scaffold) | **None** | SBP is standalone — no world-contracts dependency |
| `assets/icons/` | 20 SVGs + 5 READMEs | **None** | CC topology glyphs are CC-specific |
| `assets/audio/` | None | **New** | Demo requires recorded audio + teaser |
| `docs/` tree | ~41 carry-forward docs across 10 categories | **8 docs** across 3 categories | SBP is architecturally simpler |
| `docs/ptb/` | 5 PTB pattern files | **None** | SBP has 3 simple PTBs documented in tech arch |
| `docs/architecture/` | 10 files | **None** | Architecture is in `shadow-broker-technical-architecture.md` |
| `docs/ux/` | 3 files | **None** | No SVG spec, no topology layer |
| `docs/validation/` | 5 files | **None** | Validation evidence is one file |
| `docs/analysis/` | 2 files | **None** | No fragility audit needed for simpler scope |
| `.gitmodules` | Required | **Not created** | No submodules |
| Hackathon narrative rules | Extensive (voice, labels, 5-pillar lens) | **None** | SBP has no CivilizationControl thematic voice rules |
| Frontend | `apps/web/` or `web/` | `apps/web/` | Both need React frontend |

---

## F. Files Requiring Rewrite or Replacement in Starter

These files should NOT be copied verbatim — they need contextual rewriting.

| File | Scope | What Changes |
|------|-------|-------------|
| `README.md` | Full rewrite | Shadow Broker Protocol project description, quickstart (install, build Move, run frontend), architecture overview (Mysten Trinity: Sui+Walrus+Seal), Fair Exchange Problem framing, demo instructions, hackathon compliance statement. |
| `AGENTS.md` | Major rewrite (~65%) | Remove all CC/world-contracts language. Update project quick facts to SBP (standalone dApp, React+Move+Walrus+Seal). Remove vendor/submodule policy (none needed). Remove CC narrative/emotional signal sections. Add SBP-specific context: Seal decrypt requires `onlyTransactionKind: true`, WAL tokens needed for Walrus uploads, 2-TX seller flow. Keep: workflow primer, three-tier boundaries, guardrails, doc rules. |
| `.github/copilot-instructions.md` | Surgical rewrite (~45%) | Update Architecture Overview (React frontend + standalone Move contracts + Walrus + Seal). Remove Submodule & Vendor Policy section entirely. Remove Hackathon Narrative & Emotional Signal section. Remove EVE Documentation Reference Policy / SUI Documentation Policy sections (simplify — SBP doesn't need the full reference hierarchy). Update Quick Command Reference (add `npm run dev`, `npm run build` for frontend). Update Key Folders. |
| `GITHUB-COPILOT.md` | Light rewrite | Update project description, verification commands, do/don't entries to SBP context. |
| `llms.txt` | Full rewrite | SBP-specific docs map: product vision, tech architecture, demo beat sheet, validation evidence, repo conventions. |
| `docs/README.md` | Major rewrite | Strip all CC-specific entries. Create SBP-only index with ~8 docs + decision log. |
| `docs/decision-log.md` | Replace with empty | Start fresh. Planning-era decisions are evidence-only. |
| `.vscode/tasks.json` | Minor update | Change default `movePkgPath` from `experiments/atomic_courier_experiment` to `contracts/shadow_broker`. |
| `docs/core/memory.md` | Light rewrite | Replace "CivilizationControl" with "Shadow Broker Protocol" throughout. Remove CC-specific sections (Environment State references to world-contracts package IDs). Keep: general template structure, checkpoint log format. |
| Strategy docs (4 files) | Light edit | Change `Retention: Prep-only` to `Retention: Carry-forward`. Remove "PRE-HACKATHON PROVISIONAL PLAN" banners if present. Verify SDK coordinates are current. |

**Total files needing rewrite: ~12** (10 structural + 4 strategy doc light edits, but 2 strategy docs overlap with structural).

---

## G. Packaging Model Recommendation

**Recommended: Single SBP repo (Option A) — shared + SBP content baked together.**

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **A: Single SBP repo** | Simplest. One repo. No coordination overhead. Fastest to set up. | Shared improvements don't propagate to other projects. | **Recommended** |
| **B: Template repo + SBP fork** | Shared layer updates propagate. Clean separation. | Extra repo overhead. Only 16 shared files — not worth the abstraction. | Premature |
| **C: Monorepo with CC** | Everything in one place. | Doesn't match "fresh repo per project" hackathon requirement. Different prize targets. | Non-compliant |

**Rationale:** Shadow Broker is a smaller, simpler project than CC. The shared-starter layer (~16 files) is small enough to duplicate. SBP has no vendor submodules, fewer docs, and a standalone architecture — creating a single baked repo is the fastest path.

---

## H. Export-Risk Notes

Things easy to miss when exporting:

| Risk | Impact | Mitigation |
|------|--------|------------|
| `.github/` agent infrastructure missing | Agent operates without guardrails, Move conventions, security policy, recovery/planning prompts. | Export full `.github/` with required rewrites. |
| `.vscode/` config missing | No Sui Move tasks, no extension recs. | Export `.vscode/` with path update. |
| Prompt files missing | `/rehydrate` and `/plan` chat commands don't work. | Export `.github/prompts/` and `.vscode/prompts/`. |
| Skills missing | Deploy and Docker ops playbooks unavailable to agent. | Export `.github/skills/`. |
| Cloudflare templates missing | Frontend deploy setup has no scaffold. | Export `templates/cloudflare/`. |
| Move.instructions.md missing | Agent generates Move code without conventions. | Export `.github/instructions/move.instructions.md`. |
| typescript-react.instructions.md missing | Agent generates TS/React code without conventions. | Export `.github/instructions/typescript-react.instructions.md`. |
| hackathon-repo-conventions.md missing | Agent has no file discipline or git workflow reference. | Export `docs/core/hackathon-repo-conventions.md`. |
| tasks.json has wrong path | Sui Move tasks point to `experiments/` instead of `contracts/shadow_broker`. | Update default `movePkgPath` during export. |
| `notes/` directory leaking | Contains localnet package IDs, testnet addresses. | Verify `notes/` excluded. `.gitignore` covers it. |
| **Sandbox validation code copied** | `sandbox/shadow-broker-validation/` contains pre-hackathon code that must NOT appear in submission repo. | Do NOT copy `sandbox/` directory. Fresh contracts must be written in `contracts/shadow_broker/`. |
| **Strategy docs still say "Prep-only"** | Agents or judges confused about doc status in submission repo. | Update retention to "Carry-forward" during export. |
| **CC-specific copilot instructions copied** | Agent follows CivilizationControl narrative rules, vendor policy for world-contracts, wrong architecture overview. | Rewrite copilot-instructions.md — remove CC sections entirely. |
| **CC-specific AGENTS.md copied** | Agent applies wrong project facts, wrong vendor rules, wrong high-risk surfaces. | Rewrite AGENTS.md for SBP context. |
| **Missing audio demo assets** | Demo beat sheet references audio recording but no files exist yet. | Create `assets/audio/README.md` spec. Record during sprint. |
| **Seal SDK `onlyTransactionKind` not documented** | Agent generates broken decrypt PTB. Key error: "Invalid PTB: Invalid BCS". | Ensure validation evidence doc (carried forward) captures this critical finding prominently. |
| **WAL token exchange not documented** | Agent fails Walrus uploads because no WAL balance. | Ensure validation evidence doc captures `wal_exchange::exchange_all_for_wal` pattern. |
| **Stale Seal key server IDs** | Testnet key server object IDs may change. | Make key server IDs configurable in `apps/web/src/utils/config.ts`, not hardcoded. |
| **Missing working memory template** | Agent has no structured template for sprint tracking. | Carry `docs/core/memory.md` (rewritten for SBP). |

---

## I. Recommended Next Steps

1. **Decide** on repo name (suggested: `ShadowBrokerProtocol` or `shadow-broker-protocol`).
2. **Create** fresh private GitHub repo.
3. **Export** using this document as the combined source of truth (Sections A + B define the complete file set).
4. **Copy verbatim** files (~16 shared + 6 SBP-specific = ~22 verbatim files).
5. **Rewrite** the ~12 files identified in Section F.
6. **Create fresh** the `contracts/shadow_broker/` and `apps/web/` directories during sprint (production code, not sandbox copies).
7. **Record/create** demo audio assets during sprint per demo beat sheet spec.
8. **Verify** starter repo completeness by checking all items in Sections A + B are present.
9. **Preserve** `sui-playground` as the intact source/evidence repository.

---

## Explicit Preservation Statement

> **`sui-playground` remains the source and evidence repository.** It must not be transformed, merged, or repurposed into the starter repo. The SBP starter repo is a new, clean repository that receives selectively carried-forward artifacts per this recommendation. `sui-playground` retains all sandbox validation code (`sandbox/shadow-broker-validation/`), validation plans, local devnet logs, testnet package IDs, and ephemeral notes as the durable audit trail of pre-hackathon planning and validation work.

> **Sandbox code is NOT production code.** The Move contracts in `sandbox/shadow-broker-validation/sources/` were written for feasibility validation and may differ from the production contracts written during the sprint. Do NOT copy sandbox Move code into the submission repo.

---

## Summary Statistics

| Category | File Count | Notes |
|----------|-----------|-------|
| Shared-starter | ~16 | Project-agnostic scaffold |
| SBP-starter (non-doc) | ~6 | Config/meta (4) + license (1) + audio README (1) |
| SBP-starter (docs) | ~8 | Carry-forward markdown |
| SBP-starter total | ~30 | Shared + SBP-specific combined |
| Evidence-only | ~16 | Sandbox validation + notes + validation plan |
| Local-only | ~10+ | Notes, working memory, env files, build artifacts |
| Files needing rewrite | ~12 | See Section F |
| Files carry verbatim | ~22 | No changes needed |
| New files (sprint) | ~20+ | contracts/, apps/web/, audio assets |

---

## Appendix: Shadow Broker Source Material Index

All Shadow Broker-related files in `sui-playground`, for reference during export.

| Path | Category | Relevance |
|------|----------|-----------|
| `docs/strategy/shadow-broker-protocol/shadow-broker-product-vision.md` | SBP-starter | Authoritative product vision — carry forward |
| `docs/strategy/shadow-broker-protocol/shadow-broker-technical-architecture.md` | SBP-starter | Technical architecture reference — carry forward |
| `docs/strategy/shadow-broker-protocol/shadow-broker-demo-beat-sheet.md` | SBP-starter | Demo screencast script — carry forward |
| `docs/strategy/shadow-broker-protocol/shadow-broker-validation-evidence.md` | SBP-starter | SDK patterns + E2E proof — carry forward |
| `docs/operations/shadow-broker-validation-plan.md` | Evidence-only | 5-phase validation plan — remains in source repo |
| `sandbox/shadow-broker-validation/sources/intel_object.move` | Evidence-only | Validation Move contract — do NOT copy |
| `sandbox/shadow-broker-validation/sources/marketplace.move` | Evidence-only | Validation Move contract — do NOT copy |
| `sandbox/shadow-broker-validation/tests/shadow_broker_tests.move` | Evidence-only | Validation tests — do NOT copy |
| `sandbox/shadow-broker-validation/ts-scripts/on-chain-smoke.ts` | Evidence-only | Phase 1.7 validation script |
| `sandbox/shadow-broker-validation/ts-scripts/walrus-smoke.ts` | Evidence-only | Phase 2 validation script |
| `sandbox/shadow-broker-validation/ts-scripts/seal-smoke.ts` | Evidence-only | Phase 3 validation script |
| `sandbox/shadow-broker-validation/ts-scripts/e2e-smoke.ts` | Evidence-only | Phase 4 E2E validation script |
| `sandbox/shadow-broker-validation/Move.toml` | Evidence-only | Package manifest |
| `sandbox/shadow-broker-validation/Move.lock` | Evidence-only | Lock file |
| `sandbox/shadow-broker-validation/ts-scripts/package.json` | Evidence-only | TS script dependencies |
| `sandbox/shadow-broker-validation/ts-scripts/tsconfig.json` | Evidence-only | TS config |
| `sandbox/shadow-broker-validation/ts-scripts/Pub.testnet.toml` | Evidence-only | Testnet publication metadata |
| `notes/shadow-broker-publish-local.md` | Local-only | Devnet publish log |
| `notes/sbp-mint-output.json` | Local-only | CLI mint error output |
| `Pub.local.toml` | Local-only | Local publication metadata |
| `docs/decision-log.md` (SBP entry) | Evidence-only | E2E validation complete entry |
| `docs/strategy/_shared/hackathon-portfolio-roadmap.md` | Evidence-only | Multi-project scoring (tangential) |
