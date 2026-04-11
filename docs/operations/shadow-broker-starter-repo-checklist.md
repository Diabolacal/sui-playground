# Shadow Broker Protocol — Starter Repo Checklist

**Retention:** Prep-only

**Purpose:** Step-by-step checklist for assembling the Shadow Broker Protocol starter repo from `sui-playground`. Use alongside `docs/operations/shadow-broker-starter-repo-packaging.md` (the full packaging recommendation).

---

## Pre-Flight

- [ ] Fresh private GitHub repo created (suggested name: `ShadowBrokerProtocol`)
- [ ] Local clone ready
- [ ] `sui-playground` is intact and on `main` branch (do NOT modify source repo)

---

## Phase 1: Shared-Starter Files (Verbatim)

Copy these files directly — no content changes needed.

- [ ] `.gitignore` (trim ZK patterns: `*.ptau`, `*.zkey`, `*.wasm`, `*.r1cs`)
- [ ] `.github/security-guidelines.md`
- [ ] `.github/prompts/rehydrate.prompt.md`
- [ ] `.github/prompts/vibe-bootstrap.prompt.md`
- [ ] `.github/skills/deploy/SKILL.md`
- [ ] `.github/skills/docker-ops/SKILL.md`
- [ ] `.github/instructions/move.instructions.md`
- [ ] `.github/instructions/typescript-react.instructions.md`
- [ ] `.vscode/settings.json`
- [ ] `.vscode/extensions.json`
- [ ] `.vscode/prompts/plan.prompt.md`
- [ ] `templates/cloudflare/env.example`
- [ ] `templates/cloudflare/README.md`
- [ ] `templates/cloudflare/wrangler.example.jsonc`
- [ ] `LICENSE`

---

## Phase 2: SBP-Specific Config (Copy + Update)

- [ ] `.vscode/tasks.json` — copy, change default `movePkgPath` to `contracts/shadow_broker`
- [ ] `docs/core/hackathon-repo-conventions.md` — copy verbatim

---

## Phase 3: Strategy Docs (Copy + Light Edit)

Copy these 4 files, then for each:
- Change `Retention: Prep-only` → `Retention: Carry-forward`
- Remove any `PRE-HACKATHON PROVISIONAL PLAN` banners
- Verify SDK package names and versions are current

- [ ] `docs/strategy/shadow-broker-product-vision.md`
- [ ] `docs/strategy/shadow-broker-technical-architecture.md`
- [ ] `docs/strategy/shadow-broker-demo-beat-sheet.md`
- [ ] `docs/strategy/shadow-broker-validation-evidence.md`

---

## Phase 4: Rewrite Files

These files must be rewritten for SBP context. Use `sui-playground` originals as scaffolds.

- [ ] `README.md` — Full rewrite: SBP project description, quickstart, architecture (Sui+Walrus+Seal), Fair Exchange Problem
- [ ] `AGENTS.md` — Major rewrite: remove CC content, add SBP facts (standalone dApp, no vendor deps, Seal/Walrus SDK notes)
- [ ] `.github/copilot-instructions.md` — Surgical rewrite: update Architecture Overview, remove vendor/submodule policy, remove CC narrative rules, add SBP commands
- [ ] `GITHUB-COPILOT.md` — Light rewrite: update project description and verification commands
- [ ] `llms.txt` — Full rewrite: SBP docs map
- [ ] `docs/README.md` — Major rewrite: SBP-only doc index (~8 entries)
- [ ] `docs/decision-log.md` — Create fresh (empty template only)
- [ ] `docs/core/memory.md` — Light rewrite: replace "CivilizationControl" with "Shadow Broker Protocol"

---

## Phase 5: Create Fresh Directories

Scaffold directories for sprint work. Populate with minimal placeholder files.

- [ ] `contracts/shadow_broker/Move.toml` — package manifest (named address `shadow_broker = "0x0"`, Sui framework dep)
- [ ] `contracts/shadow_broker/sources/` — empty (production Move code written during sprint)
- [ ] `contracts/shadow_broker/tests/` — empty (production tests written during sprint)
- [ ] `apps/web/` — React project scaffold (package.json with Mysten SDK deps, Vite config, tsconfig)
- [ ] `assets/audio/README.md` — Spec for demo audio recording (reference demo beat sheet)
- [ ] `docs/working_memory/` — create directory (gitignored)

---

## Phase 6: Verify Completeness

- [ ] All files listed in packaging recommendation Sections A + B are present
- [ ] No files from `sandbox/shadow-broker-validation/` were copied
- [ ] No files from `notes/` were copied
- [ ] No `Pub.local.toml` or `Pub.testnet.toml` in starter repo
- [ ] No `.env` files in starter repo
- [ ] No `vendor/` directory in starter repo
- [ ] No `node_modules/` or `build/` artifacts in starter repo
- [ ] `.gitignore` covers: `notes/`, `docs/working_memory/`, `node_modules/`, `build/`, `.env*`
- [ ] `sui move build --path contracts/shadow_broker` passes (after Move.toml is configured)
- [ ] No CC-specific language remains in rewritten files (search for "CivilizationControl", "civilization", "gate", "turret", "SSU", "topology")
- [ ] Strategy docs all say `Retention: Carry-forward`
- [ ] `docs/README.md` index matches actual file set
- [ ] `llms.txt` references are valid

---

## Phase 7: Initial Commit

- [ ] Stage all files
- [ ] Commit: `chore: Initialize Shadow Broker Protocol starter repo`
- [ ] Push to origin

---

## Post-Setup

- [ ] Verify Copilot loads `.github/copilot-instructions.md` correctly in new repo
- [ ] Run `/rehydrate` prompt to confirm context recovery works
- [ ] Begin sprint: Move contracts → frontend → Walrus/Seal integration → demo
