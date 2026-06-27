# GITHUB-COPILOT.md — How We Work in This Repo

> **Authoritative source:** `.github/copilot-instructions.md`
> **Agent quick-load:** `AGENTS.md`
> **Documentation index:** `docs/README.md`

This file is a short orientation for Copilot agents. It does **not** override the files above — if anything here conflicts, `copilot-instructions.md` wins.

## What this repo is

An **EVE Frontier / Sui staging & research workspace**: read-only upstream `vendor/*` submodules,
durable Move/TS conventions, local devnet feasibility spikes, and a historical archive of the
March 2026 hackathon work (now concluded — it helped win two prizes). Contains documentation,
architecture specs, PTB pattern templates, and devnet experiments. No frontend, no backend, no npm.
See [docs/current/README.md](docs/current/README.md) for the current workspace guide.

## Verification commands

```bash
sui move build --path <package-dir>   # Must compile
sui move test --path <package-dir>    # Must pass
sui client active-env                 # Verify network before any tx
```

There are no `npm`, `tsc`, or web-build commands in this workspace.

## Do

- Follow the authority hierarchy: **current `vendor/world-contracts` + official upstream docs** >
  current workspace docs (`docs/current/`) > validated experiments > historical hackathon archive
  (`docs/archive/`, `docs/core/`, `docs/strategy/`) > older/speculative docs.
- Verify function signatures, structs, events, and auth against current `vendor/world-contracts`
  before generating call sites — historical docs reflect early-2026 (≤ v0.0.18) contracts.
- Use `docs/ptb/` patterns as templates — they require revalidation, not blind trust.
- Append non-trivial decisions to `docs/decision-log.md`.
- Make the smallest safe change. Prefer guard clauses and helpers over refactors.
- Use approval tokens for high-risk changes: `CORE CHANGE OK`, `SCHEMA CHANGE OK`.

## Don't

- Edit anything inside `vendor/`. Read-only always.
- Push without explicit operator approval.
- Commit secrets, keys, mnemonics, or `.env` files.
- Assume PTB skeletons are correct — revalidate against latest world-contracts.
- Rely on events as proof-of-execution for flows that may MoveAbort (events are not emitted on abort).

## Safe edit checklist

- [ ] Plan: summary, files to touch, risk class (Low/Medium/High).
- [ ] Build: `sui move build` passes.
- [ ] Test: `sui move test` passes.
- [ ] Smoke: `sui client active-env` confirms expected network.
- [ ] Decision log: entry appended if non-trivial.
