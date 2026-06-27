# Documentation Index

**Retention:** Carry-forward

Structured documentation for the Sui Playground workspace. Documents are organized by lifecycle and purpose.

> **Reframed June 2026.** This repo is now an EVE Frontier / Sui staging & research workspace. Most of
> the docs below were produced for the **March 2026 hackathon** (concluded) and are **historical**.
> Start with [`current/README.md`](current/README.md). See the classification legend before relying on
> any doc.

## Classification legend

| Class | Meaning | Where |
|-------|---------|-------|
| **Current** | Active workspace docs — accurate as of now | `current/` |
| **Durable reference** | Conventions/patterns that outlive any one project (revalidate contract specifics) | `core/hackathon-repo-conventions.md`, `.github/instructions/`, `ptb/`, `operations/submodule-refresh-prompt.md` |
| **Historical** | March 2026 hackathon planning/strategy/feasibility/demo — reference only, revalidate every contract claim | `core/`, `architecture/`, `strategy/`, `ideas/`, `analysis/`, `demo/`, `ux/`, `audits/`, `research/`, `archive/` |
| **Sandbox / evidence** | Devnet validation against ≤ v0.0.18 contracts — re-run before reuse | `validation/`, `sandbox/` |

Historical-cluster landing page: [`archive/hackathon-2026/README.md`](archive/hackathon-2026/README.md).

**Taxonomy (folders):**
- `current/` — **Current workspace docs** (workspace guide, EVE Frontier context, refresh notes, future briefs)
- `core/` — Essential hackathon docs + durable conventions (historical except conventions)
- `architecture/` — Technical capability and system design docs (historical; ≤ v0.0.18)
- `ideas/` — Hackathon project ideas and concept exploration (historical)
- `research/` — External inspiration, reference maps, and UX research (prep only / historical)
- `operations/` — Process guides, checklists, workspace rules (mixed: refresh procedure is durable)
- `ux/` — UX architecture specs and interaction design (historical)
- `analysis/` — Cross-cutting analytical artifacts (historical)
- `audits/` — Reconciliation and consistency audit reports (historical)
- `demo/` — Demo production assets (historical)
- `sandbox/` — Temporary or experimental documents (sandbox evidence)
- `validation/` — Localnet validation evidence (sandbox evidence; ≤ v0.0.18)
- `archive/` — Deprecated/superseded documents + the hackathon archive index

> **New docs rule:** All markdown files must go inside a categorized subfolder. Do not create files directly under `docs/`. Update this index when adding a new document.

---

## Current (start here)

| File | Purpose |
|------|---------|
| [current/README.md](current/README.md) | **Current workspace guide** — what the repo is now, authority hierarchy, how to use it |
| [current/eve-frontier-context-2026-06.md](current/eve-frontier-context-2026-06.md) | **Current EVE Frontier context** — operator assumptions (June 2026); revalidate before relying |
| [current/operations/submodule-refresh-2026-06.md](current/operations/submodule-refresh-2026-06.md) | **Latest submodule refresh + upstream-delta audit** |
| [current/future-research-briefs/weekend-project-ideation.md](current/future-research-briefs/weekend-project-ideation.md) | **Future brief** — weekend-project ideation (not yet performed) |
| [archive/hackathon-2026/README.md](archive/hackathon-2026/README.md) | **Historical hackathon archive index** (March 2026) |

### Retention Classification (Mandatory)

All documents under `docs/` must begin with a header block declaring their retention classification:

```
# Document Title

**Retention:** [Carry-forward | Prep-only | Sandbox-only | Archive]
```

| Classification | Meaning |
|---|---|
| **Carry-forward** | Reusable in downstream EVE Frontier project repos (originally: copy into the hackathon submission repo) — revalidate contract specifics first |
| **Prep-only** | Research or planning not intended for downstream project repos |
| **Sandbox-only** | Devnet validation artifacts, scripts, or temporary findings |
| **Archive** | Superseded documents kept for traceability |

**Rules:**
- New documents must explicitly declare retention before commit.
- Agents must classify retention before writing any new doc.
- If uncertain, default to **Prep-only** and flag for review.

---

## Canonical Terminology

Consistent naming conventions used across all active documents.

### Product & Module Names

| Term | Context | Notes |
|------|---------|-------|
| **CivilizationControl** | Full product/submission name | Abbreviation: **CC** |
| **GateControl** | UI label for the gate governance module | Player-facing display name |
| **TradePost** | UI label for the SSU commerce module | Player-facing display name |
| **ZK GatePass** | ZK-gated access rule (no space in "GatePass") | Integrated into GateControl as a rule type |

### On-Chain Types & Functions

| Term | Layer | Notes |
|------|-------|-------|
| `GateAuth` | CivControl gate extension witness type | Concrete type implementing `Auth: drop` |
| `TradeAuth` | CivControl trade extension witness type | Concrete type implementing `Auth: drop` |
| `XAuth` | Builder-scaffold example witness | Only use when discussing scaffold examples |
| `authorize_extension<T>` | World-contracts function | Registers extension on a gate/SSU |
| `gate::issue_jump_permit<Auth>()` | World-contracts issuance function | Extension-callable, no AdminACL required |
| `civcontrol::request_jump_permit()` | CivControl wrapper function | Internally calls `gate::issue_jump_permit<GateAuth>()` |
| `gate::jump_with_permit()` | World-contracts consumption function | Requires AdminACL; deletes the permit object |
| `JumpPermit` | World-contracts struct (`key, store`) | Single-use, consumed (object deleted) by `jump_with_permit`. NOT hot-potato. |

### Rule Struct Naming

| Key Struct | Value Struct | Purpose |
|------------|-------------|---------|
| `TribeRuleKey` | `TribeRule { tribe_id }` | Tribe-based access filtering |
| `CoinTollKey` | `CoinTollRule { price_mist, treasury }` | SUI toll per jump |
| `SubPassKey` | `SubPassLedger { Table<ID, u64> }` | Subscription pass ledger (character_id → expiry_ms) |
| `SubTierKey` | `SubTierConfig { price_mist, duration_ms }` | Subscription pricing & duration config |

### Currency & Units

| Term | Context | Notes |
|------|---------|-------|
| **SUI** | Day-1 display denomination | User-facing amounts (e.g., "Toll: 5 SUI") |
| **MIST** | On-chain smallest unit | 1 SUI = 10⁹ MIST. Move struct fields use `u64` in MIST |
| `Coin<SUI>` | On-chain token type | Day-1 settlement token |
| **Lux** | In-game display currency (stretch goal) | No on-chain representation; confirmed rate: 10,000 Lux = 1 EVE token. Lux-to-SUI depends on EVE/SUI exchange (undefined for MVP) |
| `price_mist` | Canonical field name for toll/price amounts | Not `price_in_mist` |

### Access Control

| Term | Meaning |
|------|---------|
| **AdminACL** | On-chain sponsor whitelist (canonical capitalization) |
| **`verify_sponsor`** | World-contracts function; falls back to `ctx.sender()` when no sponsor |
| **Extension witness** | The typed witness pattern (`Auth: drop`) used by gate/SSU extensions |

### Feature Names

| Term | Canonical Form | Notes |
|------|---------------|-------|
| Gate topology reconfiguration | **Gate Preset Switching** | Predefined link-topology presets (S46) |

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
| [core/hackathon-repo-conventions.md](core/hackathon-repo-conventions.md) | **Repo conventions** — git workflow, file discipline, naming, TS/React/Move standards, judge legibility, agent rules |
| [core/march-11-reimplementation-checklist.md](core/march-11-reimplementation-checklist.md) | **March 11 carry-forward** — validated patterns, day-1 checklist, pitfalls, DO NOT COPY notice |
| [core/civilizationcontrol-claim-proof-matrix.md](core/civilizationcontrol-claim-proof-matrix.md) | **Evidence ledger** — every demo claim mapped to tx digest, object ID, overlay format; utility metrics targets |
| [core/civilizationcontrol-demo-beat-sheet.md](core/civilizationcontrol-demo-beat-sheet.md) | **Demo beat sheet (v2)** — ~2:56 primary loop (Pain→Power→Policy→Denial→Revenue→Defense Mode→Commerce→Command), 2-min fallback variant, proof registry, pre-flight checklist |
| [core/civilizationcontrol-implementation-plan.md](core/civilizationcontrol-implementation-plan.md) | **Atomic implementation plan** — 45 steps across 7 phases (~68h), Day-1 validation first, ZK kill criteria, demo capture |
| [core/spec.md](core/spec.md) | **System specification** — boundaries, on-chain model, module architecture, UX hierarchy, demo architecture, risk model, embargo assumptions |
| [core/memory.md](core/memory.md) | **Working memory template** — structured hackathon sprint tracking, recovery procedure, proof moment evidence slots |
| [core/day1-checklist.md](core/day1-checklist.md) | **Day-1 chain validation checklist** — 10 structured checks with commands, expected output, fallbacks, GO/NO-GO gate |
| [core/validation.md](core/validation.md) | **Validation procedures** — step-level verification, build/lint gates, deterministic proof moment validation, runtime expectations |
| [core/CARRY_FORWARD_INDEX.md](core/CARRY_FORWARD_INDEX.md) | **Carry-forward export index** — definitive list of files to copy into hackathon submission repo |

## Architecture

| File | Purpose |
|------|---------|
| [architecture/sui-playground.md](architecture/sui-playground.md) | Sui local devnet quickstart — start, build, publish, troubleshoot |
| [architecture/sui-playground-capabilities.md](architecture/sui-playground-capabilities.md) | Capabilities deep dive — smart structures, ZK proximity (Groth16 PoC), experiments |
| [architecture/gate-lifecycle-function-reference.md](architecture/gate-lifecycle-function-reference.md) | Gate lifecycle complete function call reference — all signatures, types, dependency chain, OwnerCap borrow/return pattern |
| [architecture/gatecontrol-feasibility-report.md](architecture/gatecontrol-feasibility-report.md) | GateControl feasibility validation — gate architecture, extension pattern, toll options, validation plan |
| [architecture/tradepost-cross-address-ptb-validation.md](architecture/tradepost-cross-address-ptb-validation.md) | TradePost cross-address PTB risk validation — SSU ownership model, extension pattern analysis, atomic trade design, test plan |
| [architecture/zk-killswitch-fallback-analysis.md](architecture/zk-killswitch-fallback-analysis.md) | ZK GatePass kill-switch & fallback analysis — GREEN/YELLOW/RED criteria, day-by-day checkpoints, partial ZK options, demo narratives |
| [architecture/world-contracts-auth-model.md](architecture/world-contracts-auth-model.md) | **Deep auth model analysis** — all structs, 40+ functions categorized by auth tier, extension pattern, hidden permission gates |
| [architecture/authenticated-user-surface-analysis.md](architecture/authenticated-user-surface-analysis.md) | **Authenticated user surface analysis** — structure discovery, location visibility, permission model, off-chain indexing requirements, dashboard feasibility |
| [architecture/read-path-architecture-validation.md](architecture/read-path-architecture-validation.md) | **Read-path architecture validation** — wallet→structures discovery, event inventory (31 events / 16 types), signal feed data sources, Option A/B/C comparison (mapped to provider types), scale model, demo data sourcing, gap list |
| [architecture/read-provider-abstraction.md](architecture/read-provider-abstraction.md) | **Read Provider Abstraction Layer** — unified event/state feed interface: 4 provider types (RPC, GraphQL, Indexer, Demo), hackathon strategy (RPC-only Day-1), Demo Provider design (synthetic replay for recording + showcase), interface boundary at React hooks layer |
| [architecture/tradepost-buyer-journey-validation.md](architecture/tradepost-buyer-journey-validation.md) | **TradePost buyer journey validation** — PARTIAL PASS verdict, minimal architecture (object types, PTB shapes, events), March 11 test checklist, doc corrections |
| [architecture/structural-risk-sweep-2026-02-18.md](architecture/structural-risk-sweep-2026-02-18.md) | **Structural Risk Sweep** — adversarial pre-mortem synthesizing 6 audit tracks: Top 5 risks ranked (#1 sponsor access reclassified CRITICAL→HIGH with probability model), system dependency graph, Day-1 validation protocol, full assumptions ledger (13 on-chain + 11 environmental + 5 strategy) |
| [architecture/gate-turret-courier-access-feasibility.md](architecture/gate-turret-courier-access-feasibility.md) | **Gate & Turret Access Control + Cargo Bond feasibility** — permit issuance auth, time-bounding via job deadline, turret extension pattern (v0.0.14, now v0.0.15), single-extension-slot constraint, accept-job PTB shape, natural expiry fail-safe, cross-extension risks, recommended hackathon approach |
| [architecture/sweep-audit-artifacts-2026-02-18.md](architecture/sweep-audit-artifacts-2026-02-18.md) | **Sweep audit artifacts** — consolidated working notes from 6 parallel audit tracks (A–F): 58 findings, severity distribution, cross-reference to main report |
| [architecture/spatial-embed-requirements.md](architecture/spatial-embed-requirements.md) | **Spatial embed requirements** — EF-Map embed capability audit, 12 visual primitives gap analysis, hybrid architecture recommendation (CivControl SVG topology + EF-Map iframe context) |
| [architecture/in-game-dapp-surface.md](architecture/in-game-dapp-surface.md) | **In-game DApp browser surface** — confirmed runtime constraints (viewport, wallet, storage, security), DApp URL strategy, gate/SSU UI responsibilities, wallet states, deployment implications |
| [architecture/policy-authoring-model-validation.md](architecture/policy-authoring-model-validation.md) | **Policy authoring model validation** — VERIFIED: data-driven policies via dynamic fields, users never write Move, publish-once/configure-forever model, policy lifecycle, Day-1 validation steps |
| [architecture/turret-contract-surface.md](architecture/turret-contract-surface.md) | **Turret contract surface** — full API reference (v0.0.14, now v0.0.15): types, entry functions, events, error codes, extension pattern, default targeting rules, project applicability |
| [architecture/turret-closed-world-clarified.md](architecture/turret-closed-world-clarified.md) | **Turret closed-world constraint (canonical)** — code-proven evidence: fixed 4-arg PTB, no uid() accessor, default targeting matrix, CC alignment verdict, per-project feasibility, toll payer mismatch |
| [architecture/world-contracts-event-layer-audit.md](architecture/world-contracts-event-layer-audit.md) | **Event layer & observability audit** — complete inventory of 30 event types / 37 emit sites across world-contracts v0.0.15 *(v0.0.17: at least 31 types; see audit for update note)*, gap analysis for CC proof moments, indexer vs. pollable classification, demo observability recommendations |

> **v0.0.18 update:** `ExtensionConfigFrozenEvent` added (~32 event types). New emit site in `extension_freeze.move`.
| [architecture/world-contracts-strategic-review.md](architecture/world-contracts-strategic-review.md) | **Strategic review** — full API surface, governance model, event layer, builder experience audit of world-contracts v0.0.15. 4 SIMPLE + 3 EASY + 5 HARD recommendations. Demo impact analysis for CC proof moments. |

## Ideas

| File | Purpose |
|------|---------|
| [ideas/hackathon-ideas-grounded-v3-judged.md](ideas/hackathon-ideas-grounded-v3-judged.md) | **V3: 28 ideas scored against 8 judging criteria + player vote** — ranked list, CivilizationControl suite, bonus prize alignment |
| [ideas/hackathon-shortlist-recommendations.md](ideas/hackathon-shortlist-recommendations.md) | Shortlist companion — top picks by category, recommended CivilizationControl module set, implementation order |
| [ideas/wildcard-sprint-analysis.md](ideas/wildcard-sprint-analysis.md) | **Wildcard sprint:** 6 high-variance concepts, ranked top 3, selected winner (Atomic Courier) with 3-day sprint plan |

## Strategy

Strategy documents are organized by project scope:

- `_shared/` — Portfolio-level strategy and cross-project planning
- `civilization-control/` — CivilizationControl flagship documentation
- `flappy-frontier/` — Flappy Frontier sprint entry documentation
- `cargo-bond/` — Cargo Bond / Atomic Courier sprint entry documentation
- `fortune-gauntlet/` — Fortune Gauntlet sprint entry documentation

### Shared (Portfolio-Level)

| File | Purpose |
|------|---------|
| [strategy/_shared/hackathon-portfolio-roadmap.md](strategy/_shared/hackathon-portfolio-roadmap.md) | **Multi-entry portfolio strategy** — 6 tracks (CC + Fortune Gate + Salvage + Corpse Toll + Flappy Frontier + Atomic Courier), prize mapping, development cadence, kill criteria |
| [strategy/_shared/marketing-plan.md](strategy/_shared/marketing-plan.md) | **Marketing & player vote campaign plan** — 4-phase campaign (tease → launch → vote window → Stillness flex), channel playbooks, content cadence, asset checklists |

### CivilizationControl (Flagship)

| File | Purpose |
|------|---------|
| [strategy/civilization-control/civilizationcontrol-strategy-memo.md](strategy/civilization-control/civilizationcontrol-strategy-memo.md) | Adversarial strategy review — thesis, critique, reconciled recommendation for CivilizationControl |
| [strategy/civilization-control/civilizationcontrol-product-vision.md](strategy/civilization-control/civilizationcontrol-product-vision.md) | Human-centered product vision pitch — problem, vision, demo narrative, judging alignment |
| [strategy/civilization-control/civilizationcontrol-voice-and-narrative.md](strategy/civilization-control/civilizationcontrol-voice-and-narrative.md) | **Canonical UI voice & narrative guide** — positioning, label mapping, microcopy, demo framing, Narrative Impact Check |
| [strategy/civilization-control/civilizationcontrol-hackathon-emotional-objective.md](strategy/civilization-control/civilizationcontrol-hackathon-emotional-objective.md) | **Hackathon emotional objective** — primary emotional target, Five-Pillar Narrative Lens, 3-Second Emotional Check, consequence layer, demo strategy |
| [strategy/civilization-control/strategic-next-move-audit-2026-02-18.md](strategy/civilization-control/strategic-next-move-audit-2026-02-18.md) | **Strategic next-move audit** — pre-hackathon bottleneck analysis, STOP/CONTINUE/START, top-3 actions, calendar sketch |

### Flappy Frontier (Sprint)

| File | Purpose |
|------|---------|
| [strategy/flappy-frontier/flappy-frontier-product-vision.md](strategy/flappy-frontier/flappy-frontier-product-vision.md) | **Product vision** — gameplay, Sui primitives, economic model, MVP scope, risks |

### Fortune Gauntlet (Sprint)

Combined concept: Fortune Gate (VRF probabilistic permit) + The Gauntlet (sequential gate race).

| File | Purpose |
|------|---------|
| [strategy/fortune-gauntlet/fortune-gauntlet-project-vision.md](strategy/fortune-gauntlet/fortune-gauntlet-project-vision.md) | **Project vision** — sequential gate race with VRF randomness, consequence model, demo plan, MVP boundaries, risks, graceful degradation path |
| [strategy/fortune-gauntlet/fortune-gauntlet-scoring-memo.md](strategy/fortune-gauntlet/fortune-gauntlet-scoring-memo.md) | **Scoring memo** — 8-criterion + 4-area scoring (weighted 6.72), prize target (Weirdest Idea), denial rate/checkpoint tuning, kill criteria, portfolio impact |

### Cargo Bond / Atomic Courier (Sprint)

On-chain package name: **Atomic Courier** (`atomic_courier`). Player-facing name: **Cargo Bond**.

| File | Purpose |
|------|---------|
| [strategy/cargo-bond/cargo-bond-product-vision.md](strategy/cargo-bond/cargo-bond-product-vision.md) | **Product vision** — escrow lifecycle, collateral model, gate access integration, Sui primitives, economic model, demo scope, MVP boundaries, risks |

### Shadow Broker Protocol (Sprint)

Encrypted intelligence marketplace using Seal threshold encryption + Walrus blob storage.

| File | Purpose |
|------|---------|
| [strategy/shadow-broker-protocol/shadow-broker-product-vision.md](strategy/shadow-broker-protocol/shadow-broker-product-vision.md) | **Product vision** — encrypted intel marketplace, Seal + Walrus architecture, pricing model, demo scope |
| [strategy/shadow-broker-protocol/shadow-broker-demo-beat-sheet.md](strategy/shadow-broker-protocol/shadow-broker-demo-beat-sheet.md) | **Demo beat sheet** — narrative arc, proof moments, recording plan |
| [strategy/shadow-broker-protocol/shadow-broker-technical-architecture.md](strategy/shadow-broker-protocol/shadow-broker-technical-architecture.md) | **Technical architecture** — Move contracts, Seal integration, Walrus storage, PTB composition |
| [strategy/shadow-broker-protocol/shadow-broker-validation-evidence.md](strategy/shadow-broker-protocol/shadow-broker-validation-evidence.md) | **Validation evidence** — SDK patterns, tx digests, E2E pipeline results (13/13 PASS). Prep-only. |

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
| [research/capabilities.json](research/capabilities.json) | **In-game browser capabilities** — raw probe data from EVE Frontier embedded WebView (Chromium 122 CEF), captured 2026-02-28. Prep-only (JSON; no header). |
| [research/civcontrol-independent-audit.md](research/civcontrol-independent-audit.md) | **Independent audit** — external scorecard review of CivilizationControl positioning, gap analysis, P0/P1 action items |
| [research/location-proof-independent-audit.md](research/location-proof-independent-audit.md) | **Location proof independent audit** — distance proof observability, trilateration analysis, risk classification |
| [research/world-contracts-event-surface.md](research/world-contracts-event-surface.md) | **World-contracts event surface audit** — 28 event types, field index, spatial linkage, consumption paths (RPC/GraphQL/gRPC), Ethereum assumption mismatches, polling architecture |
| [research/world-contracts-event-inventory.md](research/world-contracts-event-inventory.md) | **Complete event inventory** — 30 event struct types / 37 emit sites across world-contracts v0.0.15 *(v0.0.17: at least 31 types; see inventory for update note)*, with full field definitions, line numbers, gap analysis, spatial identifier audit, and cross-reference against prior audit |

> **v0.0.18 update:** `ExtensionConfigFrozenEvent` added (~32 event types). New emit site in `extension_freeze.move`.
| [research/visualization-conventions-reference-report.md](research/visualization-conventions-reference-report.md) | **Visualization conventions research** — ISA-101, NUREG-0700, HP-HMI, IEC 60073, ISA-18.2, EEMUA 191, MIL-STD-2525, Gestalt principles; cross-reference matrix and universal design principles |
| [research/sui-read-path-options-analysis.md](research/sui-read-path-options-analysis.md) | **Sui read-path options analysis** — suix_queryEvents, GraphQL API, WebSocket subscriptions, indexer options, EVE Frontier specifics; setup complexity, hackathon suitability, recommendation for MVP |

## Operations

| File | Purpose |
|------|---------|

| [operations/SCAFFOLD_NOTES.md](operations/SCAFFOLD_NOTES.md) | Step-by-step workspace customization guide |
| [operations/DECISIONS_TEMPLATE.md](operations/DECISIONS_TEMPLATE.md) | Decision log entry format template |
| [operations/shortlist-viability-validation-plan.md](operations/shortlist-viability-validation-plan.md) | Test matrix for validating GateControl + TradePost on local devnet |
| [operations/shortlist-viability-validation-report.md](operations/shortlist-viability-validation-report.md) | **Devnet test evidence** — 10/10 GREEN (GateControl, TradePost, and ZK GatePass all confirmed viable) |
| [operations/zk-gatepass-feasibility-report.md](operations/zk-gatepass-feasibility-report.md) | **ZK GatePass feasibility** — GREEN, validated on local devnet; see [validation report](operations/shortlist-viability-validation-report.md) tests 8–10 |
| [operations/gate-lifecycle-runbook.md](operations/gate-lifecycle-runbook.md) | **Full gate lifecycle runbook** — 13-step procedure from publish to jump_with_permit, with evidence (object IDs, tx digests). Carry-forward. |
| [operations/demo-evidence-appendix.md](operations/demo-evidence-appendix.md) | **Demo evidence mapping** — maps every beat sheet artifact to its executable script, expected output, and capture method. Gap analysis included. Carry-forward. |
| [operations/submodule-refresh-prompt.md](operations/submodule-refresh-prompt.md) | **Reusable submodule refresh procedure** — step-by-step commands, audit focus areas, doc update checklist, agent prompt template |
| [operations/turret-localnet-validation-checklist.md](operations/turret-localnet-validation-checklist.md) | **Turret localnet validation checklist** — 45 test cases (8 executable, 36 environment-blocked, 1 structurally impossible), BCS encoding reference, object dependency matrix |
| [operations/compliance-audit-2026-02-24.md](operations/compliance-audit-2026-02-24.md) | **Compliance audit (2026-02-24)** — First structured hackathon compliance check. Prep-only. |
| [operations/compliance-audit-2026-03-09.md](operations/compliance-audit-2026-03-09.md) | **Compliance audit (2026-03-09)** — Pre-template compliance audit. 2 HIGH, 6 MEDIUM findings. Prep-only. |
| [operations/starter-repo-packaging-recommendation.md](operations/starter-repo-packaging-recommendation.md) | **Starter-repo packaging recommendation** — Full artifact-set classification (shared-starter / CC-starter / evidence-only / local-only), root repo shape, rewrite list, export-risk notes. Prep-only. |
| [operations/shadow-broker-validation-plan.md](operations/shadow-broker-validation-plan.md) | **Shadow Broker validation plan** — 5-phase agent-executable plan: Move compile+test, Walrus SDK, Seal SDK, E2E envelope encryption, evidence collection. Prep-only. |
| [operations/shadow-broker-starter-repo-packaging.md](operations/shadow-broker-starter-repo-packaging.md) | **Shadow Broker starter-repo packaging recommendation** — Full artifact-set classification (shared-starter / SBP-starter / evidence-only / local-only), root repo shape, rewrite list, export-risk notes, carry-forward checklist. Prep-only. |
| [operations/shadow-broker-starter-repo-checklist.md](operations/shadow-broker-starter-repo-checklist.md) | **Shadow Broker starter-repo assembly checklist** — 7-phase step-by-step checklist for assembling the SBP starter repo from sui-playground. Prep-only. |

## UX

| File | Purpose |
|------|---------|
| [ux/civilizationcontrol-ux-architecture-spec.md](ux/civilizationcontrol-ux-architecture-spec.md) | **UX Architecture Specification** — screen hierarchy, gate list/detail, rule composer, linking flow, manual pinning, spatial layer, MVP vs stretch, design principles & upgrade path |
| [ux/svg-topology-layer-spec.md](ux/svg-topology-layer-spec.md) | **SVG Topology Layer Spec** — symbol grammar (4 structure glyphs), state system (6 overlay channels), color semantics doctrine, motion doctrine & demo timing, layout/stacking rules, export conventions, standards grounding (ISA-101, MIL-STD-2525D, IEC 60073) |
| [ux/svg-asset-audit.md](ux/svg-asset-audit.md) | **SVG Asset Audit** — strict audit of 19 SVG primitives against spec (viewBox, stroke doctrine, caps/joins, color policy, XML validity, clipping/margins). Design decision registry. Coverage check. |

## PTB Pattern Library

| File | Purpose |
|------|---------|
| [ptb/README.md](ptb/README.md) | **PTB Pattern Library entry point** — transaction assembly templates, skeleton PTBs, proof-extraction guidance (non-canonical, revalidation required) |

## Audits

| File | Purpose |
|------|---------|
| [audits/dapp-surface-full-resolution-2026-02-28.md](audits/dapp-surface-full-resolution-2026-02-28.md) | **Full reconciliation report** — 30 findings (C/H/M/L) from adversarial consistency audit across 8 planning docs, 20 fixed, 6 false positives, 4 already correct |

## Analysis

| File | Purpose |
|------|---------|
| [analysis/assumption-registry-and-demo-fragility-audit.md](analysis/assumption-registry-and-demo-fragility-audit.md) | **Assumption registry + demo fragility audit** — 87 material assumptions across 16 categories, beat-by-beat determinism scoring, top 5 structural risks, pre-recording checklist, failure scenario responses |
| [analysis/fortune-gauntlet-feasibility.md](analysis/fortune-gauntlet-feasibility.md) | **Fortune Gauntlet feasibility** — sequential multi-gate checkpoint race with probabilistic permit issuance via `sui::random`; 5-area validation against world-contracts surfaces, proxy consequence architecture, multi-gate DF config pattern |
| [analysis/fortune-gauntlet-scoring-report.md](analysis/fortune-gauntlet-scoring-report.md) | **Fortune Gauntlet scoring report** — 8-criterion + 4-area FAQ scoring, comparative analysis vs Fortune Gate (5.38) and standalone Gauntlet (7.8), prize category fit (Weirdest Idea primary), denial rate/checkpoint tuning, kill criteria |
| [analysis/turret-project-semantics-and-mismatches.md](analysis/turret-project-semantics-and-mismatches.md) | **Turret project semantics and mismatches** — per-project (CC/CB/FG) translation of turret capabilities, 8 classified mismatches, closed-world constraint analysis, workaround assessment |
| [analysis/must-work-claim-registry.md](analysis/must-work-claim-registry.md) | **Must-work claim registry** — 148 testable claims extracted from 10 source docs + atomic courier experiment, grouped by project (CC GateControl/TradePost/Posture/UI/Demo, ZK GatePass, Fortune Gauntlet, Atomic Courier, Infrastructure), with demo-critical flags and validation status |

## Demo

| File | Purpose |
|------|---------|
| [demo/narration-direction-spec.md](demo/narration-direction-spec.md) | **Narration direction spec (ElevenLabs v3)** — annotated script, delivery control table, Defense Mode moment spec, TTS settings, voice selection procedure, recording checklist |

## Sandbox

| File | Purpose |
|------|---------|
| [sandbox/posture-switch-localnet-validation.md](sandbox/posture-switch-localnet-validation.md) | **Posture-switch localnet validation** — Strategy A (single PTB) confirmed for both BUSINESS→DEFENSE and DEFENSE→BUSINESS directions; PTB composition, prerequisites, constraints, and reproducibility notes. Referenced by: [product vision](strategy/civilization-control/civilizationcontrol-product-vision.md), [demo beat sheet](core/civilizationcontrol-demo-beat-sheet.md), [spec.md](core/spec.md). |

## Validation

| File | Purpose |
|------|---------|
| [validation/localnet-validation-backlog.md](validation/localnet-validation-backlog.md) | **Localnet Validation Backlog** — Prioritized inventory of all must-work claims, classified by localnet-now vs March 11 vs blocked. Top 10 validations with exact commands/scripts. |
| [validation/compound-df-key-validation.md](validation/compound-df-key-validation.md) | **Compound DF Key Validation** — 6/6 PASS. Confirms per-gate compound keys produce independent DFs on shared config. Validates GC-09. |
| [validation/version-pinning-verification.md](validation/version-pinning-verification.md) | **Version Pinning Verification** — A1-A4 function signatures confirmed at commit 78854fed (v0.0.14; sigs changed in v0.0.15). |
| [validation/extension-integration-e2e-validation.md](validation/extension-integration-e2e-validation.md) | **Extension Integration E2E** — Full cross-package Auth witness validation. authorize_extension + issue_jump_permit + DF config all PASS on localnet. |
| [validation/admin-acl-enrollment-validation.md](validation/admin-acl-enrollment-validation.md) | **AdminACL Self-Enrollment** — verify_sponsor sender-fallback confirmed. Self-enrollment enables all admin operations without dual-sign. |
| [validation/ssu-extension-e2e-validation.md](validation/ssu-extension-e2e-validation.md) | **SSU Extension E2E (TP-05)** — 7/7 PASS. Cross-package withdraw_item, deposit_to_owned, partial quantity, wrong-extension abort all validated against real world-contracts v0.0.15. |

## Archive

| File | Purpose |
|------|---------|
| [archive/ideas/hackathon-ideas-grounded.md](archive/ideas/hackathon-ideas-grounded.md) | _(Superseded by v3)_ Original 20 grounded hackathon ideas (v1) |
| [archive/ideas/hackathon-ideas-grounded-v2.md](archive/ideas/hackathon-ideas-grounded-v2.md) | _(Superseded by v3)_ 25 ideas validated against official docs (v2) |
| [archive/ideas/hackathon-ideas-v2-doc-enabled.md](archive/ideas/hackathon-ideas-v2-doc-enabled.md) | _(Superseded by v3)_ 8 doc-enabled ideas supplementing v2 |
| [archive/research/location-proof-leakage-investigation.md](archive/research/location-proof-leakage-investigation.md) | _Archived research — not active input to hackathon build._ Location proof leakage investigation — distance field observability, trilateration feasibility, risk classification (YELLOW) |
| [archive/research/location-proof-actionability-analysis.md](archive/research/location-proof-actionability-analysis.md) | _Archived research — not active input to hackathon build._ Location proof actionability analysis — ownership constraints, cross-player feasibility, graph reconstruction, CivilizationControl impact (revised to GREEN) |
| [archive/research/distance-constraint-system-mapping-analysis.md](archive/research/distance-constraint-system-mapping-analysis.md) | _Archived research — not active input to hackathon build._ Distance-constraint system mapping — star database matching feasibility, candidate enumeration, proximity oracle, solar system identification risk (ORANGE) |
| [archive/operations/hackathon-bootstrap-checklist.md](archive/operations/hackathon-bootstrap-checklist.md) | _(Superseded by starter-repo-packaging-recommendation)_ Manual Day-1 repo bootstrap checklist |

---

## Non-Docs References

| File | Purpose |
|------|---------|
| [AGENTS.md](../AGENTS.md) | Root agent context — auto-loaded by VS Code 1.104+ |
| [.github/copilot-instructions.md](../.github/copilot-instructions.md) | Authoritative guardrails and patterns |
| [GITHUB-COPILOT.md](../GITHUB-COPILOT.md) | Copilot-specific playbook |
| [llms.txt](../llms.txt) | AI-readable documentation pointer |
| [templates/cloudflare/](../templates/cloudflare/) | Cloudflare Pages/Workers config templates |
