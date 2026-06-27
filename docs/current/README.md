# Current Workspace Guide

**Status:** Active — current workspace doc (maintained as of June 2026)
**Audience:** Agents and humans using this repo for new EVE Frontier / Sui work

This is the front door for **using this repository today**. If you only read one doc to
get oriented, read this one.

---

## What this repo is now

`sui-playground` is an **EVE Frontier / Sui staging, research, and agent-context workspace**.

It was originally the planning and feasibility sandbox for the **March 2026 EVE Frontier
hackathon** (Deepsurge / CCP Games). That hackathon is over — the work here helped win two
prizes. The planning, strategy, and feasibility material is preserved as a **historical
archive** (see [`../archive/hackathon-2026/`](../archive/hackathon-2026/README.md)), not as
current operating instructions.

Today the repo serves as a **context-rich starting point** for new EVE Frontier projects,
spikes, and feasibility research. Concretely, it lets an agent:

- Inspect upstream EVE Frontier code and docs directly via the read-only `vendor/*` submodules.
- Answer questions like *"look at `world-contracts` and tell me whether X is possible"* or
  *"spin up `builder-scaffold` and check whether Y works."*
- Refresh vendor submodules to latest upstream HEAD and audit the drift (see the
  [refresh procedure](../operations/submodule-refresh-prompt.md)).
- Reuse durable conventions (Move, TypeScript/React, repo discipline) and agent guardrails.
- Mine the historical hackathon archive for prior reasoning, patterns, and validated findings —
  **after** revalidating against current upstream source.

> **Not a live hackathon repo.** Nothing here is a pending submission, deadline, or vote.
> Treat dated planning docs as evidence of prior reasoning, not as current plans.

---

## Authority hierarchy (source of truth)

When sources disagree, trust them in this order:

1. **Current vendor submodules / official upstream docs** — `vendor/world-contracts` Move code,
   `vendor/builder-documentation`, `docs.sui.io`, `docs.evefrontier.com`. This is canonical.
2. **Current workspace docs** — this `docs/current/` tree (workspace guide, EVE Frontier context,
   refresh notes).
3. **Validated experiments** — `docs/validation/`, `sandbox/`, `experiments/` evidence, with the
   caveat that they were validated against an *older* world-contracts version (≤ v0.0.18 / Mar 2026)
   and may need re-running.
4. **Historical hackathon archive** — planning, strategy, feasibility, and demo docs from the
   March 2026 cycle. Useful for patterns and prior reasoning; never authoritative on current
   contract behavior.
5. **Older plans / speculative docs** — superseded ideas and early drafts under `docs/archive/`.

> **Golden rule:** before writing new project code, **verify function signatures, structs, events,
> and auth requirements against the current `vendor/world-contracts` commit.** Do not trust
> historical docs (or LLM training data) for on-chain shapes — they drift between releases.

---

## How to use this repo

### 1. Clone / update submodules

```bash
git clone --recurse-submodules <repo-url>
# or, if already cloned:
git submodule update --init --recursive
```

### 2. Read the agent rules

- [`AGENTS.md`](../../AGENTS.md) — agent operating context (auto-loaded by VS Code 1.104+).
- [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md) — authoritative guardrails.
- Durable conventions: [`docs/core/hackathon-repo-conventions.md`](../core/hackathon-repo-conventions.md),
  [`.github/instructions/move.instructions.md`](../../.github/instructions/move.instructions.md),
  [`.github/instructions/typescript-react.instructions.md`](../../.github/instructions/typescript-react.instructions.md).

### 3. Read the current context

- [`eve-frontier-context-2026-06.md`](eve-frontier-context-2026-06.md) — operator-provided
  June 2026 assumptions about the current EVE Frontier cycle. **Revalidate before relying.**

### 4. Inspect vendor submodules

`vendor/*` are **read-only upstream references**. Read them freely; never commit inside them.

| Submodule | What it is |
|-----------|------------|
| `vendor/world-contracts` | EVE Frontier on-chain world contracts — the **canonical** Sui Move code |
| `vendor/builder-documentation` | EVE Frontier official builder docs (GitBook source) |
| `vendor/builder-scaffold` | Docker local devnet, Move templates, TS/Rust scripts, zkLogin CLI |
| `vendor/evevault` | EveVault wallet — Sui Wallet Standard + zkLogin browser extension |
| `vendor/eve-frontier-proximity-zk-poc` | ZK proximity proof-of-concept (Groth16) — reference only |

Full policy: [`AGENTS.md` § Submodule & Vendor Policy](../../AGENTS.md).

### 5. Refresh + audit when needed

To bring vendor submodules to latest upstream and audit drift, follow
[`docs/operations/submodule-refresh-prompt.md`](../operations/submodule-refresh-prompt.md).
The most recent run is recorded in
[`operations/submodule-refresh-2026-06.md`](operations/submodule-refresh-2026-06.md).

### 6. Run local validation where feasible

There is **no frontend/backend/npm at the repo root** — this is a Move + research workspace.
Build any non-vendor Move packages under `experiments/` / `sandbox/`:

```bash
sui --version
sui client active-env          # verify network BEFORE any tx
sui move build --path <dir>    # build a non-vendor Move package
```

---

## Map of the docs tree

| Area | What lives there | Treat as |
|------|------------------|----------|
| `docs/current/` | This guide, current EVE Frontier context, dated refresh notes, future-research briefs | **Current** |
| `docs/core/`, `.github/instructions/`, `docs/core/hackathon-repo-conventions.md` | Move/TS conventions, repo discipline, decision-log practice, PTB authority | **Durable reference** (revalidate contract specifics) |
| `docs/ptb/` | PTB assembly patterns | **Durable reference — revalidate every signature** |
| `docs/archive/hackathon-2026/` | Index into the March 2026 hackathon planning/strategy/demo material | **Historical** |
| `docs/validation/`, `sandbox/`, `experiments/` | Devnet validation evidence, one-off findings | **Sandbox / evidence (older world-contracts)** |
| `docs/strategy/`, `docs/ideas/`, `docs/analysis/`, `docs/demo/`, `docs/audits/` | Per-project hackathon planning + analysis | **Historical** |

See [`../README.md`](../README.md) for the full per-file index and the classification legend.

---

## Research: project ideation (2026-06-27)

A broad EVE Frontier project-ideation pass has been run (superseding and expanding the original
weekend-only brief). Start at
[`research/project-ideation-2026-06-27/README.md`](research/project-ideation-2026-06-27/README.md) for
the executive summary, ranked shortlist, and recommended next build. The original standing brief is
at [`future-research-briefs/weekend-project-ideation.md`](future-research-briefs/weekend-project-ideation.md).

## Research: fitting tool & overlay feasibility (2026-06-27)

A follow-up deep dive into a **ship-fitting tool** for Cycle 6 (the operator's chosen direction) plus
an **EF-Map overlay/helper** technical + visual audit. Verdict: **build the fitting tool** as a
standalone web app that reuses EF-Map's public data/share/industry assets; overlay work is a parallel
moat, not a blocker. Start at
[`research/frontier-fitting-overlay-feasibility-2026-06-27/README.md`](research/frontier-fitting-overlay-feasibility-2026-06-27/README.md)
for the verdict, ranked candidates, data audit, fitting model, UX spec, and the recommended next build.
Operator corrections in that pass (Rift Watch out; Patch Witness/SSU-dashboard/Frontier-Facts/Discord-bot
deprioritized) supersede the earlier ideation shortlist.
