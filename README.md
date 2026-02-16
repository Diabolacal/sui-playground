# Sui Playground — Hackathon Planning Workspace (EVE Frontier)

A de-risking and acceleration lab: validate Sui tooling, world-contract interactions, and concept feasibility before the official hackathon build window opens.

> **Note:** If you see "SWE" in voice notes or transcripts, it refers to **Sui** (the blockchain). Transcription tools frequently mishear it.

## What this repo is

- **Private sandbox** for learning Sui blockchain development, running a local devnet, and experimenting with Move smart contracts against EVE Frontier's world-contract stack. All experiments are local-devnet-only and are not hackathon submission code.
- **Hackathon planning workspace** — research, idea ranking, strategy memos, judging-criteria analysis, and documentation reference maps for the EVE Frontier hackathon (Deepsurge / CCP Games, closes 31 March 2026).
- **Vendor submodule collection** — read-only references to upstream EVE Frontier contracts, builder scaffold, ZK proof-of-concept, and the EveVault wallet.
- **AI-agent-aware** — ships with [llms.txt](llms.txt), [AGENTS.md](AGENTS.md), and [.github/copilot-instructions.md](.github/copilot-instructions.md) so coding agents can orient quickly and stay within guardrails.

## What this repo is NOT

- **Not the hackathon submission repo.** The submission repo will be created fresh on **March 11, 2026** (hackathon start date) with a clean commit history. No Entry code lives here.
- **Not pre-start code.** Per hackathon rules (Section 5), Entries must be developed on or after the start date. This repo contains only research, documentation, and sandbox experiments — all permitted pre-start activities.
- **Not a fork/PR target for vendor repos.** Vendor submodules are upstream references. Do not commit inside them or submit PRs from this repo.

---

## Quickstart (Read first)

| Doc | Purpose |
|-----|---------|
| [docs/README.md](docs/README.md) | **Documentation index** — full map of all docs by category |
| [docs/research/hackathon-event-rules-digest.md](docs/research/hackathon-event-rules-digest.md) | **Hackathon rules digest** — dates, eligibility, judging criteria, agent compliance checklist |
| [docs/architecture/sui-playground.md](docs/architecture/sui-playground.md) | Local devnet quickstart — start, build, publish, troubleshoot |
| [docs/architecture/sui-playground-capabilities.md](docs/architecture/sui-playground-capabilities.md) | Capabilities deep dive — smart structures, ZK proximity (Groth16 PoC) |
| [docs/research/sui-documentation-reference-map.md](docs/research/sui-documentation-reference-map.md) | Sui chain-level docs reference map — object model, PTBs, gas, events |
| [docs/research/evefrontier-builder-docs-map.md](docs/research/evefrontier-builder-docs-map.md) | EVE Frontier GitBook docs reference map — sponsored tx, world architecture |
| [docs/ideas/hackathon-ideas-grounded-v3-judged.md](docs/ideas/hackathon-ideas-grounded-v3-judged.md) | **V3: 28 ideas scored against 8 judging criteria** — ranked, with bonus prize alignment |
| [docs/ideas/hackathon-shortlist-recommendations.md](docs/ideas/hackathon-shortlist-recommendations.md) | Shortlist — top picks by category, recommended module set, implementation order |
| [docs/strategy/civilizationcontrol-strategy-memo.md](docs/strategy/civilizationcontrol-strategy-memo.md) | Adversarial strategy review for the lead concept (CivilizationControl) |

---

## Vendor submodules

Submodules under `vendor/` are **read-only upstream references**. Never commit, modify, or create tracked files inside them.

| Submodule | What it is |
|-----------|------------|
| `vendor/builder-scaffold` | CCP / EVE Frontier builder scaffold — Docker local devnet, Move contract templates, TS/Rust scripts, zkLogin CLI |
| `vendor/world-contracts` | EVE Frontier on-chain world contracts — the **canonical** Sui Move code (actively developed, not yet production) |
| `vendor/evevault` | EveVault wallet — Chrome MV3 extension implementing Sui Wallet Standard with zkLogin |
| `vendor/eve-frontier-proximity-zk-poc` | ZK proximity proof-of-concept — Groth16 circuits for obfuscated location & distance verification |

**Rules:** Do not `git add/commit/push` from inside any `vendor/` directory. To update a submodule pin, run `git submodule update --remote vendor/<name>` from the repo root, then commit the updated gitlink in the parent. Full policy in [AGENTS.md](AGENTS.md#submodule--vendor-policy).

---

## Local devnet usage

See [docs/architecture/sui-playground.md](docs/architecture/sui-playground.md) for the complete workflow:

- Starting the Sui local devnet via Docker Compose (`docker compose run --rm sui-local`)
- Building and publishing Move packages
- Common troubleshooting (port conflicts, Docker state, faucet issues)

Smoke-test outputs go in `notes/sui-local-smoketest.md` (untracked, local-only).

---

## Hackathon compliance + March 11 bootstrap

> This repository is a **planning and training sandbox**. It contains research, architecture notes, design documents, and tooling experiments — all permitted before the hackathon start date. **No code from this repo will be submitted as a hackathon Entry.** The actual Entry will be developed in a separate, clean GitHub repository with its first commit on or after the hackathon start date, ensuring compliance with Section 5 of the rules.

**Key dates:**

| Event | Date |
|-------|------|
| Hackathon start | **When announced** (expected ~March 11, 2026) — Entry development may begin only after the official announcement |
| Submission deadline | **March 31, 2026, 23:59 UTC** — late entries auto-disqualified |
| Player voting deadline | April 15, 2026 |
| Stillness deployment bonus window | 14 days after hackathon close |

**Bootstrap plan:**
1. On March 11, create a **fresh public GitHub repo** with a clean first commit.
2. Register the team on **Deepsurge** (max 5 members, no multi-team).
3. Carry over only `docs/core/` templates (workspace abstract, Copilot memory guidelines) and agent instruction scaffolds — **no code** from this sandbox.
4. Re-add vendor submodules as needed in the new repo.
5. All Entry code developed from scratch, on or after start date.

**Key compliance constraints:**
- Entries must be **original work** developed on or after the start date.
- Entry must **not** be a security, commodity, or confer ownership/equity/revenue-share rights.
- Submission via **GitHub repo link + Deepsurge** — no other method accepted.
- Max **1 prize** per eligible Entry. Player vote = 25% of Best Entry score.
- Max **5 team members**; no individual on multiple teams.
- Full rules: [hackathon-event-rules-digest.md](docs/research/hackathon-event-rules-digest.md) · [source snapshot](docs/research/hackathon-event-rules-source.md)

---

## License / attribution

This repository is MIT-licensed (see [LICENSE](LICENSE)). Vendor submodules retain their own upstream licenses — check each `vendor/<name>/LICENSE` for details. No upstream code is modified or redistributed from this repo.
