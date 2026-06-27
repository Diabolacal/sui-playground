# Future Research Brief — Weekend EVE Frontier Project Ideation

**Status:** Actioned 2026-06-27 (a broader ideation pass was run) — kept as the standing template
**Audience:** A future agent asked for weekend-project ideation

> **A broad ideation pass has been run** and supersedes this weekend-only brief for now:
> [`../research/project-ideation-2026-06-27/README.md`](../research/project-ideation-2026-06-27/README.md).
> This file is retained as the reusable template for the *next* time the operator wants a fresh pass
> (re-run it against the then-current vendor submodules and community state).

This is a **standing brief**. When the operator asks for a "fun weekend EVE Frontier build idea,"
follow this brief (and review the latest ideation pass linked above first).

---

## Goal

Propose **one (or a small ranked set of) fun, achievable weekend EVE Frontier build idea(s)** that
fit the current cycle, are genuinely buildable on top of the current `world-contracts`, and do not
duplicate work that already exists.

This is a *creative-but-grounded* exercise: the idea must be fun and demo-able, but every on-chain
assumption must be checkable against current upstream source.

---

## Inputs to inspect (in priority order)

1. **Latest `vendor/world-contracts`.** Refresh it first (see
   [`../../operations/submodule-refresh-prompt.md`](../../operations/submodule-refresh-prompt.md)),
   then read the actual Move modules for SSU, gate, turret, inventory, and metadata surfaces.
   Confirm function signatures, structs, events, and auth requirements directly from code.
2. **Latest `vendor/builder-documentation`.** Read current SSU / gate / turret / dapp-surface /
   wallet / deployment / in-game-browser / world-API pages for what builders are *meant* to do.
3. **Current operator context:** [`../eve-frontier-context-2026-06.md`](../eve-frontier-context-2026-06.md)
   and the [latest refresh note](../operations/submodule-refresh-2026-06.md). Re-confirm these are
   still current; if stale, refresh the assumptions first.
4. **Historical hackathon archive:** [`../../archive/hackathon-2026/README.md`](../../archive/hackathon-2026/README.md).
   Mine it for prior reasoning, validated patterns, feasibility verdicts, and dead-ends — but treat
   every contract claim as needing revalidation against current source.
5. **EF-Map integration possibilities** *if relevant* to the idea (spatial/topology context). Note:
   operator says EF-Map is maintained elsewhere — integrate, don't rebuild.

## Hard constraints

- **Do not duplicate** the existing **shared tribe storage for SSUs** (already built by someone else).
- **Do not duplicate** the existing **marketplace** (already built) unless the idea has a clearly
  **materially different** angle.
- Favor the **SSU surface** as the most interesting area this cycle; deprioritize industry-management.
- Respect the [authority hierarchy](../README.md#authority-hierarchy-source-of-truth): current
  vendor source wins over any historical doc.
- Stay within the repo guardrails (read-only `vendor/*`, no secrets, no production deploys).

## Expected output

For each proposed idea, produce:

- **One-line pitch** and why it is fun.
- **Why it fits the current cycle** (tie back to the June 2026 context + the latest audit).
- **On-chain feasibility check** with concrete evidence: the exact `world-contracts` modules /
  functions / events it would use, quoted from current source, with the commit SHA.
- **Non-duplication argument:** how it avoids the existing shared-storage and marketplace work.
- **Weekend-scope MVP boundary:** what ships in a weekend vs. what is stretch.
- **Top risks** and the fastest way to kill the idea if it is infeasible.
- **Relevant prior art** from the hackathon archive (with revalidation caveats).

Keep it grounded: a fun idea that cannot be built on current contracts is not a good answer.
