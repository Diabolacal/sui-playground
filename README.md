# Sui Playground — Hackathon Planning Workspace (EVE Frontier)

A pre-hackathon sandbox: validate Sui tooling, world-contracts interactions, and concept feasibility before and during the EVE Frontier hackathon build window.

## What this repo is

- **Private sandbox** for Sui blockchain development — local devnet experiments with Move smart contracts against EVE Frontier's world-contracts stack. All experiments are local-devnet-only.
- **Hackathon planning workspace** — research, idea ranking, strategy, judging-criteria analysis, and documentation reference maps for the EVE Frontier hackathon (Deepsurge / CCP Games, closes 31 March 2026).
- **Vendor submodule collection** — read-only references to upstream EVE Frontier contracts, builder scaffold, official docs, ZK proof-of-concept, and the EveVault wallet.
- **Agent-aware** — ships with [llms.txt](llms.txt), [AGENTS.md](AGENTS.md), and [.github/copilot-instructions.md](.github/copilot-instructions.md) for AI coding agent orientation and guardrails.

## What this repo is NOT

- **Not the hackathon submission repo.** The submission repo will be created on or after the hackathon start date (expected ~March 11, 2026) with a clean commit history. No Entry code lives here.
- **Not pre-start code.** Per hackathon rules (Section 5), Entries must be developed on or after the start date. This repo contains only research, documentation, and sandbox experiments — all permitted pre-start activities.
- **Not a fork/PR target for vendor repos.** Vendor submodules are upstream references. Do not commit inside them.

---

## Quickstart (Reproducible Setup)

Vendor submodules are **required** — many docs reference `vendor/` paths, and sandbox experiments depend on `vendor/builder-scaffold/docker` for local Sui devnet.

```bash
# Clone with submodules (recommended)
git clone --recurse-submodules <repo-url>

# If already cloned without submodules
git submodule update --init --recursive
```

**Verify submodules loaded:**

```bash
# All of these directories should exist and be non-empty
ls vendor/builder-scaffold
ls vendor/world-contracts
ls vendor/builder-documentation
ls vendor/evevault
ls vendor/eve-frontier-proximity-zk-poc
```

> **Note:** Sandbox experiments (under `experiments/` and `sandbox/`) rely on `vendor/builder-scaffold/docker` for local Sui devnet and will not run without submodules initialized.

---

## Start here

| Doc | Purpose |
|-----|---------|
| [docs/README.md](docs/README.md) | **Documentation index** — full map of all docs by category |
| [docs/core/spec.md](docs/core/spec.md) | **CivilizationControl system spec** — boundaries, on-chain model, risk model |
| [docs/research/hackathon-event-rules-digest.md](docs/research/hackathon-event-rules-digest.md) | **Hackathon rules digest** — dates, eligibility, judging, compliance checklist |
| [docs/strategy/hackathon-portfolio-roadmap.md](docs/strategy/hackathon-portfolio-roadmap.md) | Portfolio strategy — multi-entry plan, prize targeting, dev cadence |
| [docs/core/march-11-reimplementation-checklist.md](docs/core/march-11-reimplementation-checklist.md) | March 11 carry-forward — validated patterns, day-1 bootstrap |
| [docs/architecture/sui-playground.md](docs/architecture/sui-playground.md) | Local devnet quickstart — start, build, publish, troubleshoot |
| [docs/operations/gate-lifecycle-runbook.md](docs/operations/gate-lifecycle-runbook.md) | Gate lifecycle runbook — 13-step procedure with evidence |
| [docs/research/evefrontier-builder-docs-map.md](docs/research/evefrontier-builder-docs-map.md) | EVE Frontier official docs reference map |
| [docs/research/sui-documentation-reference-map.md](docs/research/sui-documentation-reference-map.md) | Sui chain-level docs reference map — object model, PTBs, gas, events |

---

## Vendor submodules

Submodules under `vendor/` are **read-only upstream references**. Never commit, modify, or create tracked files inside them.

| Submodule | What it is |
|-----------|------------|
| `vendor/builder-documentation` | EVE Frontier official builder documentation (GitBook source) |
| `vendor/builder-scaffold` | Builder scaffold — Docker local devnet, Move contract templates, TS/Rust scripts, zkLogin CLI |
| `vendor/world-contracts` | EVE Frontier on-chain world contracts — the **canonical** Sui Move code |
| `vendor/evevault` | EveVault wallet — Chrome MV3 extension implementing Sui Wallet Standard with zkLogin |
| `vendor/eve-frontier-proximity-zk-poc` | ZK proximity proof-of-concept — Groth16 circuits for obfuscated location and distance verification |

Do not `git add/commit/push` from inside any `vendor/` directory. To update a submodule pin, run `git submodule update --remote vendor/<name>` from the repo root, then commit the updated gitlink in the parent. Full policy in [AGENTS.md](AGENTS.md#submodule--vendor-policy).

---

## Hackathon compliance

This repository is a **planning and training sandbox**. No code from this repo will be submitted as a hackathon Entry. The actual Entry will be developed in a separate, clean GitHub repository with its first commit on or after the hackathon start date, ensuring compliance with Section 5 of the rules.

| Event | Date |
|-------|------|
| Hackathon start | Expected ~March 11, 2026 (TBD — Entry development begins only after official announcement) |
| Submission deadline | **March 31, 2026, 23:59 UTC** |
| Player voting deadline | April 15, 2026 |
| Stillness deployment bonus | Within 14 days after hackathon close |

Full rules and compliance checklist: [hackathon-event-rules-digest.md](docs/research/hackathon-event-rules-digest.md) | [source snapshot](docs/research/hackathon-event-rules-source.md)

---

## License / attribution

This repository is MIT-licensed (see [LICENSE](LICENSE)). Vendor submodules retain their own upstream licenses — check each `vendor/<name>/LICENSE` for details. No upstream code is modified or redistributed from this repo.
