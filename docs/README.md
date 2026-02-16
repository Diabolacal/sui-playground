# Documentation Index

Structured documentation for the SUI Playground workspace. Documents are organized by lifecycle and purpose.

**Taxonomy:**
- `core/` — Essential documents to carry into the hackathon repo
- `architecture/` — Technical capability and system design docs
- `ideas/` — Hackathon project ideas and concept exploration
- `research/` — External inspiration and UX research (prep only)
- `operations/` — Bootstrap checklists, process guides, workspace rules
- `sandbox/` — Temporary or experimental documents
- `archive/` — Deprecated but retained documents

> **New docs rule:** All markdown files must go inside a categorized subfolder. Do not create files directly under `docs/`. Update this index when adding a new document.

---

## Core (Carry to Hackathon)

| File | Purpose |
|------|---------|
| [core/WORKSPACE_ABSTRACT.md](core/WORKSPACE_ABSTRACT.md) | What this workspace is and how to use it |
| [core/COPILOT_MEMORY_GUIDELINES.md](core/COPILOT_MEMORY_GUIDELINES.md) | What to store in Copilot persistent memory |
| [core/march-11-reimplementation-checklist.md](core/march-11-reimplementation-checklist.md) | **March 11 carry-forward** — validated patterns, day-1 checklist, pitfalls, DO NOT COPY notice |

## Architecture

| File | Purpose |
|------|---------|
| [architecture/sui-playground.md](architecture/sui-playground.md) | Sui local devnet quickstart — start, build, publish, troubleshoot |
| [architecture/sui-playground-capabilities.md](architecture/sui-playground-capabilities.md) | Capabilities deep dive — smart structures, ZK proximity (Groth16 PoC), experiments |
| [architecture/gatecontrol-feasibility-report.md](architecture/gatecontrol-feasibility-report.md) | GateControl feasibility validation — gate architecture, extension pattern, toll options, validation plan |
| [architecture/tradepost-cross-address-ptb-validation.md](architecture/tradepost-cross-address-ptb-validation.md) | TradePost cross-address PTB risk validation — SSU ownership model, extension pattern analysis, atomic trade design, test plan |

## Ideas

| File | Purpose |
|------|---------|
| [ideas/hackathon-ideas-grounded.md](ideas/hackathon-ideas-grounded.md) | 20 grounded hackathon project ideas with top-5 shortlist (v1 — superseded) |
| [ideas/hackathon-ideas-grounded-v2.md](ideas/hackathon-ideas-grounded-v2.md) | **25 ideas validated against official docs** — Green/Yellow/Red verdicts, top-5 shortlist, 5 new ideas |
| [ideas/hackathon-ideas-v2-doc-enabled.md](ideas/hackathon-ideas-v2-doc-enabled.md) | 8 new ideas enabled by Sui/GitBook documentation knowledge (top-5 filtered) |
| [ideas/hackathon-ideas-grounded-v3-judged.md](ideas/hackathon-ideas-grounded-v3-judged.md) | **V3: 28 ideas scored against 8 judging criteria + player vote** — ranked list, CivilizationControl suite, bonus prize alignment |
| [ideas/hackathon-shortlist-recommendations.md](ideas/hackathon-shortlist-recommendations.md) | Shortlist companion — top picks by category, recommended CivilizationControl module set, implementation order |

## Strategy

| File | Purpose |
|------|---------|
| [strategy/civilizationcontrol-strategy-memo.md](strategy/civilizationcontrol-strategy-memo.md) | Adversarial strategy review — thesis, critique, reconciled recommendation for CivilizationControl |

## Research (Prep Only — Not for Hackathon Repo)

| File | Purpose |
|------|---------|
| [research/hackathon-inspiration-research.md](research/hackathon-inspiration-research.md) | Web research: blockchain hackathon patterns, Sui ecosystem examples |
| [research/player-value-ux-analysis.md](research/player-value-ux-analysis.md) | Player pain points, UX interaction patterns, value analysis |
| [research/evefrontier-builder-docs-map.md](research/evefrontier-builder-docs-map.md) | Official GitBook docs reference map — structured index with gap analysis and freshness policy |
| [research/sui-documentation-reference-map.md](research/sui-documentation-reference-map.md) | SUI chain-level docs reference map — canonical source hierarchy, architectural constraints, consultation rules |
| [research/hackathon-event-rules-source.md](research/hackathon-event-rules-source.md) | Verbatim snapshot of official EVE Frontier Hackathon Event Rules (captured 2026-02-16) |
| [research/hackathon-event-rules-digest.md](research/hackathon-event-rules-digest.md) | **Practical digest** — dates, eligibility, judging criteria, agent compliance checklist |

## Operations

| File | Purpose |
|------|---------|
| [operations/hackathon-bootstrap-checklist.md](operations/hackathon-bootstrap-checklist.md) | Day-1 checklist for initializing the hackathon submission repo |
| [operations/SCAFFOLD_NOTES.md](operations/SCAFFOLD_NOTES.md) | Step-by-step workspace customization guide |
| [operations/DECISIONS_TEMPLATE.md](operations/DECISIONS_TEMPLATE.md) | Decision log entry format template |
| [operations/shortlist-viability-validation-plan.md](operations/shortlist-viability-validation-plan.md) | Test matrix for validating GateControl + TradePost on local devnet |
| [operations/shortlist-viability-validation-report.md](operations/shortlist-viability-validation-report.md) | **Devnet test evidence** — 6/6 GREEN, both modules confirmed viable |

## Sandbox

_Empty — use for temporary or experimental documents._

## Archive

_Empty — move deprecated documents here instead of deleting._

---

## Non-Docs References

| File | Purpose |
|------|---------|
| [AGENTS.md](../AGENTS.md) | Root agent context — auto-loaded by VS Code 1.104+ |
| [.github/copilot-instructions.md](../.github/copilot-instructions.md) | Authoritative guardrails and patterns |
| [GITHUB-COPILOT.md](../GITHUB-COPILOT.md) | Copilot-specific playbook |
| [llms.txt](../llms.txt) | AI-readable documentation pointer |
| [templates/cloudflare/](../templates/cloudflare/) | Cloudflare Pages/Workers config templates |
