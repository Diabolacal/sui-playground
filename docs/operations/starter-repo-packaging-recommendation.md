# Starter-Repo Packaging Recommendation

**Retention:** Prep-only

**Date:** 2026-03-09
**Status:** Proposal — audit/recommendation only. No export created.
**Source conversation:** VS Code Agent Mode, packaging audit session (2026-03-09)

---

## Purpose

This document records the full-repo packaging recommendation for extracting a clean CivilizationControl (CC) starter repo from `sui-playground` on or after March 11, 2026.

**Key constraint:** `sui-playground` remains the source/evidence repository and should NOT itself be transformed into the starter repo. A new, clean repo is created; artifacts are selectively carried forward per this recommendation.

---

## Packaging Categories

| Category | Meaning |
|----------|---------|
| **Shared-starter** | Reusable across multiple hackathon project repos |
| **CC-starter** | Specific to the CivilizationControl hackathon submission repo |
| **Evidence-only** | Remains in `sui-playground` only — not exported |
| **Local-only** | Machine/user/environment-specific — never exported |
| **Archive-only** | Historical/superseded — remains in source repo for traceability |

---

## A. Recommended Shared-Starter Set

Files/patterns reusable across any EVE Frontier hackathon project repo.

| Item | Action | Notes |
|------|--------|-------|
| `.gitignore` | Carry verbatim (minor trim) | Remove ZK-specific patterns if unused by target project |
| `.github/copilot-instructions.md` | Carry **structure**, rewrite **content** | ~60% verbatim (guardrails, CLI policy, quality gates, vendor policy); ~40% project-specific rewrite (Architecture Overview, sandbox rules, project facts) |
| `.github/security-guidelines.md` | Carry verbatim | OWASP baseline, project-agnostic |
| `.github/prompts/rehydrate.prompt.md` | Carry verbatim | Context-amnesia recovery, project-agnostic |
| `.github/prompts/vibe-bootstrap.prompt.md` | Carry verbatim | Onboarding wizard, project-agnostic |
| `.github/skills/deploy/SKILL.md` | Carry verbatim | Generic Cloudflare deploy skill |
| `.github/skills/docker-ops/SKILL.md` | Carry verbatim | Generic Docker operations skill |
| `.vscode/settings.json` | Carry verbatim (minor trim) | No machine-specific content; all workspace-portable |
| `.vscode/extensions.json` | Carry verbatim | Copilot Chat, REST Client, GitHub PR |
| `.vscode/prompts/plan.prompt.md` | Carry verbatim | Change-planning prompt, project-agnostic |
| `AGENTS.md` | Carry **structure**, rewrite **content** | Shared scaffold with project-specific facts swapped |
| `GITHUB-COPILOT.md` | Carry **structure**, rewrite | Thin pointer file; update references |
| `llms.txt` | Carry **structure**, rewrite | LLM index; update docs map (currently incomplete) |
| `templates/cloudflare/` | Carry verbatim (3 files) | CF deployment templates |
| `docs/operations/DECISIONS_TEMPLATE.md` | Carry verbatim | Decision log format |

**Total:** ~15 items forming a reusable starter scaffold.

---

## B. Recommended CC-Starter Set

Files specific to the CivilizationControl hackathon submission.

### Config & Meta

| Item | Action |
|------|--------|
| `.gitmodules` | **Create fresh** via `git submodule add` (world-contracts, builder-scaffold; optionally evevault) |
| `.github/instructions/move.instructions.md` | Carry verbatim — CC-specific Move conventions |
| `.vscode/tasks.json` | Carry with **path update** (default movePkgPath → CC contract dir) |
| `LICENSE` | Carry verbatim (MIT) |

### Assets (entire tree — 20 SVGs + 5 READMEs)

| Item | Action |
|------|--------|
| `assets/icons/README.md` | Carry verbatim — asset governance |
| `assets/icons/glyphs/*.svg` (5) | Carry verbatim — gate, network_node, solar_system_aggregate, trade_post, turret |
| `assets/icons/glyphs/mini/*.svg` (4) + README | Carry verbatim — compact 10×10 variants |
| `assets/icons/overlays/` (all subdirs) | Carry verbatim — badges (5 SVGs + README), halos (2), pips (2), pulse (1), overlay README |

### Docs — Carry-Forward (40 files across 10 categories)

| Category | Count | Key Files |
|----------|-------|-----------|
| **core/** | 9 | spec.md, march-11-reimplementation-checklist.md, day1-checklist.md, validation.md, implementation-plan.md, demo-beat-sheet.md, claim-proof-matrix.md, memory.md, CARRY_FORWARD_INDEX.md |
| **architecture/** | 10 | authenticated-user-surface-analysis, gate-lifecycle-function-reference, gatecontrol-feasibility-report, in-game-dapp-surface, policy-authoring-model-validation, read-path-architecture-validation, read-provider-abstraction, spatial-embed-requirements, sui-playground-capabilities, world-contracts-auth-model |
| **strategy/civilization-control/** | 4 | hackathon-emotional-objective, product-vision, strategy-memo, voice-and-narrative |
| **analysis/** | 2 | assumption-registry-and-demo-fragility-audit, must-work-claim-registry |
| **validation/** | 5 | admin-acl-enrollment, compound-df-key, extension-integration-e2e, localnet-validation-backlog, ssu-extension-e2e |
| **ux/** | 3 | civilizationcontrol-ux-architecture-spec, svg-asset-audit, svg-topology-layer-spec |
| **ptb/** | 5 | README, atomic-settlement-skeleton, governance-admin-skeletons, proof-extraction-moveabort, ptb-patterns |
| **operations/** | 5 | DECISIONS_TEMPLATE, demo-evidence-appendix, gate-lifecycle-runbook, hackathon-bootstrap-checklist, submodule-refresh-prompt |
| **demo/** | 1 | narration-direction-spec |
| **index + log** | 2 | docs/README.md (rewrite), docs/decision-log.md (fresh/empty) |

### Vendor Submodules (fresh adds, not copies)

| Submodule | Required? |
|-----------|-----------|
| `vendor/world-contracts` | Yes — core dependency |
| `vendor/builder-scaffold` | Yes — devnet environment |
| `vendor/evevault` | TBD — needed if wallet signing integration |
| `vendor/builder-documentation` | Optional — reference only |
| `vendor/eve-frontier-proximity-zk-poc` | TBD — needed if ZK features in scope |

---

## C. Evidence-Only Set (remain in sui-playground)

| Category | Count | Examples |
|----------|-------|---------|
| `experiments/` | Entire tree | atomic_courier_experiment (pre-start validation code) |
| `sandbox/` | Entire tree | extension_auth_test, posture-switch-validation, zk validations |
| `docs/research/` | 14 md + 1 JSON | Reference maps, hackathon rules source/digest, idea rankings, event inventories |
| `docs/ideas/` | 3 files | Idea rankings and analysis |
| `docs/audits/` | 1 file | DApp surface full-resolution audit |
| `docs/sandbox/` | 1 file | Posture-switch localnet report |
| `docs/architecture/` (non-carry-forward) | 8 files | Structural sweeps, turret surface, TradePost cross-address, event audits, strategic review, turret-closed-world |
| `docs/operations/` (non-carry-forward) | 7 files | Compliance audits, scaffold notes, viability reports, turret checklist, ZK feasibility, this document |
| `docs/core/` (non-carry-forward) | 2 files | COPILOT_MEMORY_GUIDELINES, WORKSPACE_ABSTRACT |
| `docs/strategy/.../strategic-next-move-audit` | 1 file | Prep-only |
| `docs/archive/` | 7 files | Superseded ideas, demo beat sheet v1, archived research |

---

## D. Local-Only Set (never export)

| Item | Rationale |
|------|-----------|
| `notes/` (entire directory) | Gitignored. Machine-specific tx outputs, package IDs, localnet addresses. |
| `docs/working_memory/` | Gitignored. Ephemeral agent task files. |
| `.vscode/mcp.json` (if created) | Machine-specific MCP server config. |
| Any `.env` or `.env.*` files | Secrets. |
| `vendor/*/docker/workspace-data/` | Ephemeral Docker state. |

---

## E. Root Starter Repo Shape

Proposed top-level structure for a clean CC starter repo:

```
CivilizationControl/
├── .github/
│   ├── copilot-instructions.md        ← REWRITE (shared scaffold + CC content)
│   ├── security-guidelines.md         ← verbatim
│   ├── instructions/
│   │   └── move.instructions.md       ← verbatim
│   ├── prompts/
│   │   ├── rehydrate.prompt.md        ← verbatim
│   │   └── vibe-bootstrap.prompt.md   ← verbatim
│   └── skills/
│       ├── deploy/SKILL.md            ← verbatim
│       └── docker-ops/SKILL.md        ← verbatim
├── .vscode/
│   ├── settings.json                  ← verbatim (minor trim)
│   ├── extensions.json                ← verbatim
│   ├── tasks.json                     ← path update
│   └── prompts/
│       └── plan.prompt.md             ← verbatim
├── assets/
│   └── icons/                         ← entire tree verbatim (20 SVGs + 5 MDs)
├── contracts/                         ← NEW: CC Move contract code (post-March 11)
│   └── civilization_control/
│       ├── Move.toml
│       └── sources/
├── docs/
│   ├── README.md                      ← REWRITE (CC-only index)
│   ├── decision-log.md                ← FRESH (empty template)
│   ├── core/                          ← 9 carry-forward authority docs
│   ├── architecture/                  ← 10 carry-forward design docs
│   ├── strategy/civilization-control/ ← 4 carry-forward strategy docs
│   ├── analysis/                      ← 2 carry-forward analysis docs
│   ├── validation/                    ← 5 carry-forward validation reports
│   ├── ux/                            ← 3 carry-forward UX docs
│   ├── ptb/                           ← 5 carry-forward PTB patterns
│   ├── operations/                    ← 5 carry-forward runbooks/templates
│   ├── demo/                          ← 1 narration spec
│   └── working_memory/                ← gitignored, created on use
├── vendor/                            ← fresh submodule adds
│   ├── world-contracts/
│   └── builder-scaffold/
├── templates/
│   └── cloudflare/                    ← 3 files verbatim
├── .gitignore                         ← verbatim (minor trim)
├── .gitmodules                        ← FRESH (from submodule adds)
├── AGENTS.md                          ← REWRITE
├── GITHUB-COPILOT.md                  ← REWRITE
├── LICENSE                            ← verbatim
├── llms.txt                           ← REWRITE
└── README.md                          ← FULL REWRITE
```

---

## F. Files Requiring Rewrite or Replacement in Starter

These files should NOT be copied verbatim — they need contextual rewriting.

| File | Scope | What Changes |
|------|-------|-------------|
| `README.md` | Full rewrite | Remove "this is NOT the submission repo" framing. Write CC project description, quickstart, architecture overview, folder structure, hackathon compliance. |
| `AGENTS.md` | Major rewrite (~60%) | Remove sandbox-specific rules. Update project quick facts to CC. Remove "private training sandbox" framing. Keep: workflow primer, three-tier boundaries, guardrails, vendor policy, hackathon narrative, doc rules. |
| `.github/copilot-instructions.md` | Surgical rewrite (~40%) | Update: Architecture Overview (add frontend/backend/data), remove Sandbox-Workspace Rules or replace with deploy rules, update Quick Command Reference. Keep: guardrails, CLI policy, risk classes, interaction protocol. |
| `GITHUB-COPILOT.md` | Light rewrite | Update project description, verification commands, do/don't entries. |
| `llms.txt` | Full rewrite | Currently incomplete. Write CC-specific docs map. |
| `docs/README.md` | Major rewrite | Strip evidence-only/prep-only/sandbox-only rows. Retain carry-forward entries. Update category descriptions. |
| `docs/decision-log.md` | Replace with empty | Start fresh. Planning-era decisions are evidence-only. |
| `.vscode/tasks.json` | Minor update | Change default `movePkgPath` from `experiments/atomic_courier_experiment` to `contracts/civilization_control`. |
| `.gitmodules` | Create fresh | Generated by `git submodule add` commands. |
| `docs/core/CARRY_FORWARD_INDEX.md` | Light update | Verify file list matches actual exported set. |

---

## G. Packaging Model Recommendation

**Recommended: Single CC repo (Option A) — shared + CC content baked together.**

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **A: Single CC repo** | Simplest. One repo. No layer coordination. | Shared improvements don't propagate to other projects. | **Recommended for March 11** |
| **B: Template repo + CC fork** | Shared layer updates propagate. Clean separation. | Extra repo overhead. Template updates require merge. | Good long-term, premature now |
| **C: Monorepo with project dirs** | Everything in one place. | Doesn't match "fresh repo per project" hackathon requirement. | Non-compliant |

**Rationale:** For the March 11 deadline, a single baked CC repo is the cleanest path. The shared-starter layer (~15 files) is small enough to duplicate into multiple project repos if needed. If a second hackathon project emerges, extract the shared layer at that point.

---

## H. Export-Risk Notes

Things easy to miss if exporting only markdown docs:

| Risk | Impact | Mitigation |
|------|--------|------------|
| SVG assets missing | No topology glyphs/overlays for CC UI. UX spec references nonexistent files. | Export entire `assets/icons/` tree. |
| `.github/` agent infrastructure missing | Agent operates without guardrails, Move conventions, security policy, recovery/planning prompts. | Export full `.github/` with required rewrites. |
| `.vscode/` config missing | No Sui Move tasks, no agent memory, no search subagent, no extension recs. | Export `.vscode/` with minor updates. |
| Prompt files missing | `/rehydrate` and `/plan` chat commands don't work. Context recovery broken. | Export `.github/prompts/` and `.vscode/prompts/`. |
| Skills missing | Deploy and Docker ops playbooks unavailable to agent. | Export `.github/skills/`. |
| Cloudflare templates missing | Frontend deploy setup has no scaffold. | Export `templates/cloudflare/`. |
| PTB pattern library missing | Agent has no PTB assembly reference when composing transactions. | Export `docs/ptb/` (5 files). |
| Move.instructions.md missing | Agent generates Move code without CC-specific conventions. | Export `.github/instructions/move.instructions.md`. |
| tasks.json missing | No VS Code task buttons for Sui Move build/test/publish. | Export `.vscode/tasks.json` with updated path. |
| Vendor submodules copied instead of freshly added | Stale localnet state, Docker volumes, build artifacts leak into starter. | Fresh `git submodule add` in CC repo. Never copy `vendor/` directly. |
| `notes/` directory leaking | Contains localnet package IDs, transaction outputs with addresses. | Verify `notes/` excluded. `.gitignore` covers it. |
| `CARRY_FORWARD_INDEX.md` drift | If actual export differs from index, agent/operator trusts stale list. | Update CARRY_FORWARD_INDEX.md during export to match actual set. |

---

## I. Recommended Next Steps

1. **Decide** on packaging model (recommend Option A: single CC repo).
2. **On or after March 11:** Create fresh private GitHub repo (`CivilizationControl` or chosen name).
3. **Execute export** using this document + `docs/core/CARRY_FORWARD_INDEX.md` + `docs/operations/hackathon-bootstrap-checklist.md` as the combined source of truth.
4. **Rewrite** the ~10 files identified in Section F during or immediately after export.
5. **Fresh-add vendor submodules** via `git submodule add` (never copy `vendor/` directories).
6. **Verify** starter repo completeness by checking all items in Sections A + B are present.
7. **Preserve** `sui-playground` as the intact source/evidence repository.

---

## Explicit Preservation Statement

> **`sui-playground` remains the source and evidence repository.** It must not be transformed, merged, or repurposed into the starter repo. The starter repo is a new, clean repository that receives selectively carried-forward artifacts per this recommendation. `sui-playground` retains all experiments, sandbox validations, research, compliance audits, archived documents, and local notes as the durable audit trail of pre-hackathon planning work.

---

## Summary Statistics

| Category | File Count | Notes |
|----------|-----------|-------|
| Shared-starter | ~15 | Project-agnostic scaffold |
| CC-starter (non-doc) | ~30 | Assets (25) + config/meta (5) |
| CC-starter (docs) | ~40 | Carry-forward markdown |
| CC-starter total | ~85 | Shared + CC-specific combined |
| Evidence-only | ~45 | Docs + experiments + sandbox |
| Local-only | ~15+ | Notes, working memory, env files |
| Archive-only | 7 | Superseded docs |
| Files needing rewrite | ~10 | See Section F |
