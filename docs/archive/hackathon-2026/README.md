# Hackathon 2026 Archive — Index

**Status:** Historical archive index (March 2026 EVE Frontier hackathon)
**Retention:** Archive

This is the landing page for the **March 2026 EVE Frontier hackathon** (Deepsurge / CCP Games)
planning, strategy, feasibility, and demo materials.

> ⚠️ **Historical — do not treat as current build plans.**
> These materials were created **before and during the March 2026 hackathon** and were genuinely
> useful: they drove feasibility validation, planning, and prize-winning hackathon work (two
> prizes). They are kept for **reference, reusable patterns, and prior reasoning**.
>
> They are **not** current operating instructions. Any contract signature, event shape, auth model,
> version pin, or "validated" claim in these docs reflects the world-contracts state of **early 2026
> (≤ v0.0.18)** and **must be revalidated** against the current `vendor/world-contracts` before you
> rely on it. See the [authority hierarchy](../../current/README.md#authority-hierarchy-source-of-truth)
> and the [latest refresh audit](../../current/operations/submodule-refresh-2026-06.md).

The files below were **not moved** — they remain in their original locations to preserve the dense
cross-link web and the carry-forward export index. This page indexes them by cluster.

---

## Why keep this

- **Prior reasoning:** the "why" behind decisions (adversarial reviews, kill criteria, risk sweeps).
- **Reusable patterns:** PTB shapes, extension-witness layout, demo evidence methodology.
- **Validated findings:** what was confirmed on localnet against early-2026 contracts (revalidate).
- **Negative results:** ideas that were explored and dropped, so future agents don't repeat them.

---

## Major historical clusters (in place)

### Flagship project — CivilizationControl (GateControl + TradePost + ZK GatePass)
- System spec & carry-forward: [`docs/core/spec.md`](../../core/spec.md),
  [`docs/core/CARRY_FORWARD_INDEX.md`](../../core/CARRY_FORWARD_INDEX.md),
  [`docs/core/march-11-reimplementation-checklist.md`](../../core/march-11-reimplementation-checklist.md)
- Strategy & narrative: [`docs/strategy/civilization-control/`](../../strategy/civilization-control/)
- UX: [`docs/ux/`](../../ux/)
- Demo: [`docs/demo/`](../../demo/), [`docs/core/civilizationcontrol-demo-beat-sheet.md`](../../core/civilizationcontrol-demo-beat-sheet.md)

### Other hackathon entries / sprints
- Flappy Frontier: [`docs/strategy/flappy-frontier/`](../../strategy/flappy-frontier/)
- Cargo Bond / Atomic Courier: [`docs/strategy/cargo-bond/`](../../strategy/cargo-bond/),
  [`experiments/atomic_courier_experiment/`](../../../experiments/atomic_courier_experiment/)
- Fortune Gauntlet: [`docs/strategy/fortune-gauntlet/`](../../strategy/fortune-gauntlet/),
  [`docs/analysis/fortune-gauntlet-feasibility.md`](../../analysis/fortune-gauntlet-feasibility.md)
- Shadow Broker Protocol: [`docs/strategy/shadow-broker-protocol/`](../../strategy/shadow-broker-protocol/)
- Portfolio strategy: [`docs/strategy/_shared/`](../../strategy/_shared/)

### Idea exploration
- [`docs/ideas/`](../../ideas/) (shortlist, wildcard sprint, v3-judged ideas)
- Superseded idea sets: [`docs/archive/ideas/`](../ideas/)

### Architecture & feasibility (early-2026 world-contracts)
- [`docs/architecture/`](../../architecture/) — gate lifecycle, auth model, turret surface,
  TradePost/SSU validation, read-path, ZK kill-switch, structural risk sweeps. **Version-pinned to
  ≤ v0.0.18 — revalidate.**

### Rules, compliance, and judging (event-specific, now closed)
- [`docs/research/hackathon-event-rules-source.md`](../../research/hackathon-event-rules-source.md),
  [`docs/research/hackathon-event-rules-digest.md`](../../research/hackathon-event-rules-digest.md)
- [`docs/operations/compliance-audit-2026-02-24.md`](../../operations/compliance-audit-2026-02-24.md),
  [`docs/operations/compliance-audit-2026-03-09.md`](../../operations/compliance-audit-2026-03-09.md)

### Validation evidence (localnet, early-2026 contracts)
- [`docs/validation/`](../../validation/), [`docs/sandbox/`](../../sandbox/),
  [`sandbox/`](../../../sandbox/) — confirmed against world-contracts ≤ v0.0.18. Re-run before reuse.

### Research & reference maps (prep-only)
- [`docs/research/`](../../research/) — event surface/inventory audits, builder/Sui docs reference
  maps, UX/visualization research, currency model.

### Decision history
- [`docs/decision-log.md`](../../decision-log.md) — newest-first. Entries dated Feb–Mar 2026 are the
  hackathon record; the June 2026 reframe entry sits at the top.

---

## What is **not** historical

Durable conventions and agent guardrails remain **active** and are not part of this archive:

- Repo conventions: [`docs/core/hackathon-repo-conventions.md`](../../core/hackathon-repo-conventions.md)
- Move conventions: [`.github/instructions/move.instructions.md`](../../../.github/instructions/move.instructions.md)
- TS/React conventions: [`.github/instructions/typescript-react.instructions.md`](../../../.github/instructions/typescript-react.instructions.md)
- Submodule refresh procedure: [`docs/operations/submodule-refresh-prompt.md`](../../operations/submodule-refresh-prompt.md)
- Current workspace guide: [`docs/current/README.md`](../../current/README.md)

(The filenames above keep their original "hackathon"/"march-11" names for link stability; their
*conventions* are durable even though their names are historical.)
