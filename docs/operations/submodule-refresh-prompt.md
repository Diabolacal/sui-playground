# Submodule Refresh — Reusable Agent Prompt

**Retention:** Carry-forward

> **Created:** 2026-02-20  
> **Purpose:** Repeatable prompt + procedure for refreshing all git submodules, auditing changes, and updating local documentation.

---

## When to Run

- Weekly during active development
- Before hackathon submission freeze
- After notification of upstream changes to any submodule

## Prerequisites

- Clean working tree (no uncommitted changes outside `vendor/`)
- Network access to GitHub (submodule remotes)

## Procedure

### Step 1: Preflight

```bash
git status
git submodule status
# Record current pinned SHAs for each submodule
git diff -- vendor/  # Shows pinned vs checked-out SHA per submodule
```

### Step 2: Create Working Branch

```bash
git checkout -b chore/submodule-refresh-YYYYMMDD
```

### Step 3: Fetch + Update Each Submodule

```bash
# Fetch all remotes
git submodule foreach 'git fetch --all --prune'

# Checkout + pull default branch for each
cd vendor/builder-documentation && git checkout main && git pull origin main && cd ../..
cd vendor/builder-scaffold && git checkout main && git pull origin main && cd ../..
cd vendor/eve-frontier-proximity-zk-poc && git checkout main && git pull origin main && cd ../..
cd vendor/evevault && git checkout main && git pull origin main && cd ../..
cd vendor/world-contracts && git checkout main && git pull origin main && cd ../..

# Verify
git submodule status
git diff -- vendor/  # Confirms old→new SHA changes
```

### Step 4: Audit Changes Per Submodule

For each submodule with changes:

```bash
cd vendor/<name>
git log --oneline --decorate <oldSHA>..<newSHA>
git diff <oldSHA>..<newSHA> --stat
# Read key changed files (especially Move modules, TS scripts, documentation)
cd ../..
```

**Focus areas by submodule:**

| Submodule | Key areas to audit |
|---|---|
| **world-contracts** | `contracts/world/sources/` (Move modules), `extension_examples/`, function signature changes, new events, `verify_sponsor` call sites |
| **builder-documentation** | New/changed pages, AdminCap/AdminACL naming, extension patterns, SSU/gate/turret, deployment guides |
| **evevault** | Wallet adapter (`SuiWallet.ts`), chain support, sponsored tx (`walletHandlers.ts`), auth modules, SDK changes |
| **builder-scaffold** | Move contracts (`smart_gate/`), TS scripts, Docker config, deployment scripts, .env changes |
| **proximity-zk-poc** | Circuit changes, proof generation, verification patterns |

### Step 5: Update Local Documentation

Documents to update (if impacts found):

1. **`docs/research/evefrontier-builder-docs-map.md`** — Update review date, submodule commit, section summaries, gaps
2. **`docs/core/march-11-reimplementation-checklist.md`** — Add findings that affect validated patterns
3. **`docs/strategy/hackathon-portfolio-roadmap.md`** — Update track status if upstream changes affect feasibility
4. **`docs/decision-log.md`** — Add entry for the refresh

### Step 6: Commit + Push

```bash
git add vendor/
git add docs/
git commit -m "chore: refresh submodules + docs (YYYY-MM-DD)"
git push -u origin chore/submodule-refresh-YYYYMMDD
```

## Expected Output Format

### Summary Table

| Submodule | Old SHA | New SHA | Commits | Impact |
|---|---|---|---|---|
| builder-documentation | `abc1234` | `def5678` | N | Low/Med/High |
| builder-scaffold | ... | ... | ... | ... |
| evevault | ... | ... | ... | ... |
| world-contracts | ... | ... | ... | ... |
| proximity-zk-poc | ... | ... | ... | ... |

### Per-Submodule Report

For each changed submodule:
- **Notable changes** (3-8 bullets)
- **Impact on CivilizationControl** (3-6 bullets)
- **Action items** (if any)

## Guardrails

- Never commit inside `vendor/*` directories
- Never modify files inside submodules
- If local changes exist in a submodule, stop and surface them
- If breaking changes are found, capture evidence and create a TODO note — don't speculatively fix
- Minimal doc edits: prefer addenda and callouts over rewrites
- Update stored memory facts if previously stored facts are now outdated

## Agent Prompt (Copy-Paste)

When asking an AI agent to perform this refresh, use:

> Update all git submodules to their latest upstream commits. For each submodule that changed: (1) record old→new SHA, (2) audit what changed in Move modules/docs/scripts/APIs, (3) assess impact on CivilizationControl architecture. Then update docs/research/evefrontier-builder-docs-map.md, docs/core/march-11-reimplementation-checklist.md, and docs/strategy/hackathon-portfolio-roadmap.md with any findings. Add a decision-log entry. Commit on a `chore/submodule-refresh-YYYYMMDD` branch and push.
