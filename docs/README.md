# Documentation Index

Structured documentation for the SUI Playground workspace. Documents are organized by lifecycle and purpose.

**Taxonomy:**
- `core/` — Essential documents to carry into the hackathon repo
- `architecture/` — Technical capability and system design docs
- `ideas/` — Hackathon project ideas and concept exploration
- `research/` — External inspiration and UX research (prep only)
- `operations/` — Bootstrap checklists, process guides, workspace rules
- `ux/` — UX architecture specs and interaction design
- `sandbox/` — Temporary or experimental documents
- `archive/` — Deprecated but retained documents

> **New docs rule:** All markdown files must go inside a categorized subfolder. Do not create files directly under `docs/`. Update this index when adding a new document.

### Retention Classification (Mandatory)

All documents under `docs/` must begin with a header block declaring their retention classification:

```
# Document Title

**Retention:** [Carry-forward | Prep-only | Sandbox-only | Archive]
```

| Classification | Meaning |
|---|---|
| **Carry-forward** | Intended to be copied into the March 11 hackathon submission repo |
| **Prep-only** | Research or planning that should NOT be copied into the submission repo |
| **Sandbox-only** | Devnet validation artifacts, scripts, or temporary findings |
| **Archive** | Superseded documents kept for traceability |

**Rules:**
- New documents must explicitly declare retention before commit.
- Agents must classify retention before writing any new doc.
- If uncertain, default to **Prep-only** and flag for review.

---

## Decision Log

| File | Purpose |
|------|---------|
| [decision-log.md](decision-log.md) | Non-trivial technical and strategic decisions (newest first) |

## Core (Carry to Hackathon)

| File | Purpose |
|------|---------|
| [core/WORKSPACE_ABSTRACT.md](core/WORKSPACE_ABSTRACT.md) | What this workspace is and how to use it |
| [core/COPILOT_MEMORY_GUIDELINES.md](core/COPILOT_MEMORY_GUIDELINES.md) | What to store in Copilot persistent memory |
| [core/march-11-reimplementation-checklist.md](core/march-11-reimplementation-checklist.md) | **March 11 carry-forward** — validated patterns, day-1 checklist, pitfalls, DO NOT COPY notice |
| [core/civilizationcontrol-claim-proof-matrix.md](core/civilizationcontrol-claim-proof-matrix.md) | **Evidence ledger** — every demo claim mapped to tx digest, object ID, overlay format; utility metrics targets |
| [core/civilizationcontrol-demo-beat-sheet.md](core/civilizationcontrol-demo-beat-sheet.md) | **Demo beat sheet** — 3-min primary loop (Control→Consequence→Revenue), 2-min fallback variant, evidence capture checklist |

## Architecture

| File | Purpose |
|------|---------|
| [architecture/sui-playground.md](architecture/sui-playground.md) | Sui local devnet quickstart — start, build, publish, troubleshoot |
| [architecture/sui-playground-capabilities.md](architecture/sui-playground-capabilities.md) | Capabilities deep dive — smart structures, ZK proximity (Groth16 PoC), experiments |
| [architecture/gate-lifecycle-function-reference.md](architecture/gate-lifecycle-function-reference.md) | Gate lifecycle complete function call reference — all signatures, types, dependency chain, OwnerCap borrow/return pattern |
| [architecture/gatecontrol-feasibility-report.md](architecture/gatecontrol-feasibility-report.md) | GateControl feasibility validation — gate architecture, extension pattern, toll options, validation plan |
| [architecture/tradepost-cross-address-ptb-validation.md](architecture/tradepost-cross-address-ptb-validation.md) | TradePost cross-address PTB risk validation — SSU ownership model, extension pattern analysis, atomic trade design, test plan |
| [architecture/zk-killswitch-fallback-analysis.md](architecture/zk-killswitch-fallback-analysis.md) | ZK Gate Pass kill-switch & fallback analysis — GREEN/YELLOW/RED criteria, day-by-day checkpoints, partial ZK options, demo narratives |
| [architecture/world-contracts-auth-model.md](architecture/world-contracts-auth-model.md) | **Deep auth model analysis** — all structs, 40+ functions categorized by auth tier, extension pattern, hidden permission gates |
| [architecture/authenticated-user-surface-analysis.md](architecture/authenticated-user-surface-analysis.md) | **Authenticated user surface analysis** — structure discovery, location visibility, permission model, off-chain indexing requirements, dashboard feasibility |
| [architecture/read-path-architecture-validation.md](architecture/read-path-architecture-validation.md) | **Read-path architecture validation** — wallet→structures discovery, event inventory (31 events / 16 types), signal feed data sources, Option A/B/C comparison, scale model, demo data sourcing, gap list |
| [architecture/tradepost-buyer-journey-validation.md](architecture/tradepost-buyer-journey-validation.md) | **TradePost buyer journey validation** — PARTIAL PASS verdict, minimal architecture (object types, PTB shapes, events), March 11 test checklist, doc corrections |
| [architecture/structural-risk-sweep-2026-02-18.md](architecture/structural-risk-sweep-2026-02-18.md) | **Structural Risk Sweep** — adversarial pre-mortem synthesizing 6 audit tracks: Top 5 risks ranked (#1 sponsor access reclassified CRITICAL→HIGH with probability model), system dependency graph, Day-1 validation protocol, full assumptions ledger (13 on-chain + 11 environmental + 5 strategy) |
| [architecture/sweep-audit-artifacts-2026-02-18.md](architecture/sweep-audit-artifacts-2026-02-18.md) | **Sweep audit artifacts** — consolidated working notes from 6 parallel audit tracks (A–F): 58 findings, severity distribution, cross-reference to main report |
| [architecture/spatial-embed-requirements.md](architecture/spatial-embed-requirements.md) | **Spatial embed requirements** — EF-Map embed capability audit, 12 visual primitives gap analysis, hybrid architecture recommendation (CivControl SVG topology + EF-Map iframe context) |

## Ideas

| File | Purpose |
|------|---------|
| [ideas/hackathon-ideas-grounded-v3-judged.md](ideas/hackathon-ideas-grounded-v3-judged.md) | **V3: 28 ideas scored against 8 judging criteria + player vote** — ranked list, CivilizationControl suite, bonus prize alignment |
| [ideas/hackathon-shortlist-recommendations.md](ideas/hackathon-shortlist-recommendations.md) | Shortlist companion — top picks by category, recommended CivilizationControl module set, implementation order |

## Strategy

| File | Purpose |
|------|---------|
| [strategy/civilizationcontrol-strategy-memo.md](strategy/civilizationcontrol-strategy-memo.md) | Adversarial strategy review — thesis, critique, reconciled recommendation for CivilizationControl |
| [strategy/civilizationcontrol-product-vision.md](strategy/civilizationcontrol-product-vision.md) | Human-centered product vision pitch — problem, vision, demo narrative, judging alignment |
| [strategy/civilizationcontrol-voice-and-narrative.md](strategy/civilizationcontrol-voice-and-narrative.md) | **Canonical UI voice & narrative guide** — positioning, label mapping, microcopy, demo framing, Narrative Impact Check |
| [strategy/civilizationcontrol-hackathon-emotional-objective.md](strategy/civilizationcontrol-hackathon-emotional-objective.md) | **Hackathon emotional objective** — primary emotional target, Five-Pillar Narrative Lens, 3-Second Emotional Check, consequence layer, demo strategy |
| [strategy/hackathon-portfolio-roadmap.md](strategy/hackathon-portfolio-roadmap.md) | **Multi-entry portfolio strategy** — 4 tracks, prize mapping, development cadence, kill criteria |
| [strategy/strategic-next-move-audit-2026-02-18.md](strategy/strategic-next-move-audit-2026-02-18.md) | **Strategic next-move audit** — pre-hackathon bottleneck analysis, STOP/CONTINUE/START, top-3 actions, calendar sketch |

## Research (Prep Only — Not for Hackathon Repo)

| File | Purpose |
|------|---------|
| [research/hackathon-inspiration-research.md](research/hackathon-inspiration-research.md) | Web research: blockchain hackathon patterns, Sui ecosystem examples |
| [research/player-value-ux-analysis.md](research/player-value-ux-analysis.md) | Player pain points, UX interaction patterns, value analysis |
| [research/evefrontier-builder-docs-map.md](research/evefrontier-builder-docs-map.md) | Official GitBook docs reference map — structured index with gap analysis and freshness policy |
| [research/sui-documentation-reference-map.md](research/sui-documentation-reference-map.md) | SUI chain-level docs reference map — canonical source hierarchy, architectural constraints, consultation rules |
| [research/hackathon-event-rules-source.md](research/hackathon-event-rules-source.md) | Verbatim snapshot of official EVE Frontier Hackathon Event Rules (captured 2026-02-16) |
| [research/hackathon-event-rules-digest.md](research/hackathon-event-rules-digest.md) | **Practical digest** — dates, eligibility, judging criteria, agent compliance checklist |
| [research/currency-truth-table.md](research/currency-truth-table.md) | Currency/token model truth table — LUX, EVE Token, Coin types, sponsored tx, exchange rates |
| [research/civcontrol-independent-audit.md](research/civcontrol-independent-audit.md) | **Independent audit** — external scorecard review of CivilizationControl positioning, gap analysis, P0/P1 action items |

## Operations

| File | Purpose |
|------|---------|
| [operations/hackathon-bootstrap-checklist.md](operations/hackathon-bootstrap-checklist.md) | Day-1 checklist for initializing the hackathon submission repo |
| [operations/SCAFFOLD_NOTES.md](operations/SCAFFOLD_NOTES.md) | Step-by-step workspace customization guide |
| [operations/DECISIONS_TEMPLATE.md](operations/DECISIONS_TEMPLATE.md) | Decision log entry format template |
| [operations/shortlist-viability-validation-plan.md](operations/shortlist-viability-validation-plan.md) | Test matrix for validating GateControl + TradePost on local devnet |
| [operations/shortlist-viability-validation-report.md](operations/shortlist-viability-validation-report.md) | **Devnet test evidence** — 10/10 GREEN (GateControl, TradePost, and ZK GatePass all confirmed viable) |
| [operations/zk-gatepass-feasibility-report.md](operations/zk-gatepass-feasibility-report.md) | **ZK GatePass feasibility** — GREEN, fully validated on local devnet (addendum 2026-03-11); see [validation report](operations/shortlist-viability-validation-report.md) tests 8–10 |
| [operations/gate-lifecycle-runbook.md](operations/gate-lifecycle-runbook.md) | **Full gate lifecycle runbook** — 13-step procedure from publish to jump_with_permit, with evidence (object IDs, tx digests). Carry-forward. |

## UX

| File | Purpose |
|------|---------|
| [ux/civilizationcontrol-ux-architecture-spec.md](ux/civilizationcontrol-ux-architecture-spec.md) | **UX Architecture Specification** — screen hierarchy, gate list/detail, rule composer, linking flow, manual pinning, spatial layer, MVP vs stretch, design principles & upgrade path |

## Sandbox

_Empty — use for temporary or experimental documents._

## Archive

| File | Purpose |
|------|---------|
| [archive/ideas/hackathon-ideas-grounded.md](archive/ideas/hackathon-ideas-grounded.md) | _(Superseded by v3)_ Original 20 grounded hackathon ideas (v1) |
| [archive/ideas/hackathon-ideas-grounded-v2.md](archive/ideas/hackathon-ideas-grounded-v2.md) | _(Superseded by v3)_ 25 ideas validated against official docs (v2) |
| [archive/ideas/hackathon-ideas-v2-doc-enabled.md](archive/ideas/hackathon-ideas-v2-doc-enabled.md) | _(Superseded by v3)_ 8 doc-enabled ideas supplementing v2 |
| [archive/research/location-proof-leakage-investigation.md](archive/research/location-proof-leakage-investigation.md) | _Archived research — not active input to hackathon build._ Location proof leakage investigation — distance field observability, trilateration feasibility, risk classification (YELLOW) |
| [archive/research/location-proof-actionability-analysis.md](archive/research/location-proof-actionability-analysis.md) | _Archived research — not active input to hackathon build._ Location proof actionability analysis — ownership constraints, cross-player feasibility, graph reconstruction, CivilizationControl impact (revised to GREEN) |
| [archive/research/distance-constraint-system-mapping-analysis.md](archive/research/distance-constraint-system-mapping-analysis.md) | _Archived research — not active input to hackathon build._ Distance-constraint system mapping — star database matching feasibility, candidate enumeration, proximity oracle, solar system identification risk (ORANGE) |

---

## Non-Docs References

| File | Purpose |
|------|---------|
| [AGENTS.md](../AGENTS.md) | Root agent context — auto-loaded by VS Code 1.104+ |
| [.github/copilot-instructions.md](../.github/copilot-instructions.md) | Authoritative guardrails and patterns |
| [GITHUB-COPILOT.md](../GITHUB-COPILOT.md) | Copilot-specific playbook |
| [llms.txt](../llms.txt) | AI-readable documentation pointer |
| [templates/cloudflare/](../templates/cloudflare/) | Cloudflare Pages/Workers config templates |
