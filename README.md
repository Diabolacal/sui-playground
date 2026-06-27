# Sui Playground — EVE Frontier Staging & Research Workspace

A context-rich staging, research, and agent-context workspace for **EVE Frontier on Sui**:
inspect upstream contracts and docs, validate feasibility on local devnet, and reuse durable
conventions when starting new projects.

> **History:** This was formerly the **March 2026 EVE Frontier hackathon** planning/research
> workspace (Deepsurge / CCP Games). That hackathon is over — the work here helped win two prizes.
> The planning and strategy material is retained as a **historical archive**, not as current plans
> or current rules.

## What this repo is

- **EVE Frontier / Sui staging & research workspace** — a place to inspect upstream EVE Frontier
  code and docs, run local-devnet feasibility spikes against `world-contracts`, and capture findings.
- **Vendor submodule collection** — read-only references to upstream EVE Frontier contracts, builder
  scaffold, official docs, ZK proof-of-concept, and the EveVault wallet.
- **Durable convention + guardrail set** — Move conventions, TypeScript/React conventions, repo
  discipline, submodule policy, and agent workflow rules that carry into new project repos.
- **Historical hackathon archive** — preserved planning, strategy, feasibility, and demo docs from
  the March 2026 cycle, indexed at
  [docs/archive/hackathon-2026/](docs/archive/hackathon-2026/README.md).
- **Agent-aware** — ships with [llms.txt](llms.txt), [AGENTS.md](AGENTS.md), and
  [.github/copilot-instructions.md](.github/copilot-instructions.md) for AI agent orientation.

## What this repo is NOT

- **Not a live hackathon repo.** There is no pending submission, deadline, or vote. The March 2026
  hackathon has concluded.
- **Not the source of truth for current contract behavior.** Historical docs reflect early-2026
  contract state (≤ v0.0.18). Always verify against the current `vendor/world-contracts` before building.
- **Not a fork/PR target for vendor repos.** Vendor submodules are read-only upstream references.

---

## Quickstart

Vendor submodules are **required** — many docs reference `vendor/` paths, and devnet spikes depend on
`vendor/builder-scaffold/docker`.

```bash
# Clone with submodules (recommended)
git clone --recurse-submodules <repo-url>

# If already cloned without submodules
git submodule update --init --recursive
```

Then:

1. **Read the agent rules** — [AGENTS.md](AGENTS.md), [.github/copilot-instructions.md](.github/copilot-instructions.md).
2. **Read the current workspace guide** — [docs/current/README.md](docs/current/README.md).
3. **Inspect vendor submodules** — read upstream code/docs directly (read-only).
4. **Run local validation where feasible** — `sui move build --path <non-vendor-package>`.

**Verify submodules loaded:**

```bash
ls vendor/builder-scaffold vendor/world-contracts vendor/builder-documentation \
   vendor/evevault vendor/eve-frontier-proximity-zk-poc
```

> **Note:** There is no frontend/backend/npm at the repo root — this is a Move + research workspace.
> Devnet spikes under `experiments/` and `sandbox/` rely on `vendor/builder-scaffold/docker`.

---

## Start here

| Doc | Purpose |
|-----|---------|
| [docs/current/README.md](docs/current/README.md) | **Current workspace guide** — what the repo is now, authority hierarchy, how to use it |
| [docs/current/eve-frontier-context-2026-06.md](docs/current/eve-frontier-context-2026-06.md) | **Current EVE Frontier context** — operator assumptions (June 2026), revalidate before relying |
| [docs/current/operations/submodule-refresh-2026-06.md](docs/current/operations/submodule-refresh-2026-06.md) | **Latest submodule refresh + upstream-delta audit** |
| [docs/operations/submodule-refresh-prompt.md](docs/operations/submodule-refresh-prompt.md) | **Reusable submodule refresh + audit procedure** |
| [docs/README.md](docs/README.md) | **Documentation index** — full map of all docs, with classification legend |
| [docs/archive/hackathon-2026/README.md](docs/archive/hackathon-2026/README.md) | **Historical hackathon archive index** (March 2026) |
| [docs/core/hackathon-repo-conventions.md](docs/core/hackathon-repo-conventions.md) | **Durable repo conventions** — git workflow, file discipline, naming, TS/React/Move standards |

---

## Vendor submodules

Submodules under `vendor/` are **read-only upstream references**. Never commit, modify, or create
tracked files inside them.

| Submodule | What it is |
|-----------|------------|
| `vendor/world-contracts` | EVE Frontier on-chain world contracts — the **canonical** Sui Move code |
| `vendor/builder-documentation` | EVE Frontier official builder documentation (GitBook source) |
| `vendor/builder-scaffold` | Builder scaffold — Docker local devnet, Move templates, TS/Rust scripts, zkLogin CLI |
| `vendor/evevault` | EveVault wallet — Sui Wallet Standard + zkLogin browser extension |
| `vendor/eve-frontier-proximity-zk-poc` | ZK proximity proof-of-concept — Groth16 circuits (reference only) |

Do not `git add/commit/push` from inside any `vendor/` directory. To refresh a submodule, follow
[docs/operations/submodule-refresh-prompt.md](docs/operations/submodule-refresh-prompt.md) and commit
the updated gitlink in the parent repo. Full policy in
[AGENTS.md](AGENTS.md#submodule--vendor-policy).

---

## License / attribution

This repository is MIT-licensed (see [LICENSE](LICENSE)). Vendor submodules retain their own upstream
licenses — check each `vendor/<name>/LICENSE` for details. No upstream code is modified or
redistributed from this repo.
