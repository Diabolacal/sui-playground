# Carry-Forward Export Index

**Retention:** Carry-forward

## Carry-Forward Policy

This document is the **definitive list** of files intended to be copied into the hackathon submission repository on March 11. Only files listed here should be carried forward.

> **Only copy files listed here into hackathon submission repository. This prevents accidental inclusion of sandbox or scaffold artifacts.**

When copying, update project name, scope, and any sandbox-specific references to match the specific hackathon build.

---

## Core Documents (always copy)

| File | Purpose |
|------|---------|
| `docs/core/spec.md` | System specification — boundaries, on-chain model, risk model |
| `docs/core/march-11-reimplementation-checklist.md` | Execution checklist — validated patterns, day-1 bootstrap |
| `docs/core/validation.md` | Validation procedures — build gates, runtime expectations, proof moments |
| `docs/core/civilizationcontrol-implementation-plan.md` | Expanded implementation plan — all phases |
| `docs/core/day1-checklist.md` | Day-1 validation checklist |
| `docs/core/civilizationcontrol-demo-beat-sheet.md` | Demo beat sheet — narrative flow for submission video |
| `docs/core/civilizationcontrol-claim-proof-matrix.md` | Claim-proof matrix — maps claims to evidence |
| `docs/core/memory.md` | Working memory template (CivilizationControl extended) |
| `docs/core/CARRY_FORWARD_INDEX.md` | This index |

## Strategy Documents (copy for voice/narrative consistency)

| File | Purpose |
|------|---------|
| `docs/strategy/civilizationcontrol-voice-and-narrative.md` | Voice, labels, microcopy guidelines |
| `docs/strategy/civilizationcontrol-hackathon-emotional-objective.md` | Emotional design target |
| `docs/strategy/civilizationcontrol-strategy-memo.md` | Strategic positioning |
| `docs/strategy/civilizationcontrol-product-vision.md` | Product vision |
| `docs/strategy/hackathon-portfolio-roadmap.md` | Portfolio strategy and prize targeting |
| `docs/strategy/marketing-plan.md` | Marketing and submission narrative |

## UX Documents (copy for design guidance)

| File | Purpose |
|------|---------|
| `docs/ux/civilizationcontrol-ux-architecture-spec.md` | UX architecture specification |

## Architecture Documents (copy selectively — validated patterns)

| File | Purpose |
|------|---------|
| `docs/architecture/gate-lifecycle-function-reference.md` | Gate function signatures and auth requirements |
| `docs/architecture/gatecontrol-feasibility-report.md` | GateControl feasibility analysis |
| `docs/architecture/world-contracts-auth-model.md` | Auth model reference |
| `docs/architecture/read-path-architecture-validation.md` | Read-path validation |
| `docs/architecture/policy-authoring-model-validation.md` | Policy model validation |

## Operations Documents (copy for bootstrap procedures)

| File | Purpose |
|------|---------|
| `docs/operations/gate-lifecycle-runbook.md` | 13-step gate lifecycle procedure |
| `docs/operations/hackathon-bootstrap-checklist.md` | Repo bootstrap checklist |
| `docs/operations/demo-evidence-appendix.md` | Evidence collection appendix |

## Documentation Infrastructure (copy for repo hygiene)

| File | Purpose |
|------|---------|
| `docs/README.md` | Documentation index (update for new repo) |
| `docs/decision-log.md` | Decision log (start fresh in new repo) |

---

## Explicit Exclusions

The following are **NOT** carried forward into the hackathon submission repo:

- `vendor/` — upstream submodules (re-add as needed in new repo)
- `sandbox/` — isolated validation tests (sandbox-only)
- `experiments/` — sandbox Move experiments (sandbox-only)
- `templates/` — scaffold templates (consumed, not copied)
- `notes/` — local smoketest logs (untracked)
- `docs/research/` — prep-only research and reference maps
- `docs/archive/` — superseded documents
- `docs/audits/` — point-in-time audit snapshots
- `docs/analysis/` — transient analysis artifacts
- `docs/core/WORKSPACE_ABSTRACT.md` — scaffold template documentation
- `docs/core/COPILOT_MEMORY_GUIDELINES.md` — agent memory guidelines (scaffold)
- `docs/operations/SCAFFOLD_NOTES.md` — scaffold setup notes
- `docs/operations/compliance-audit-2026-02-24.md` — point-in-time compliance check
- `docs/ideas/` — idea exploration (decisions already captured in core docs)
- Historical validation artifacts unless explicitly listed above
