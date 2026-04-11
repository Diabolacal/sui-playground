# Gate Distance & Location Leakage Investigation — Discovery Index

**Retention:** Prep-only

> Discovery pass: April 11 2026. Indexes all documentation related to the pre-hackathon investigation into whether hidden location could be inferred from on-chain data (gate link distances, events, star-database matching).

---

## Investigation Chain — Primary Documents

These four documents form a connected investigation chain. They were authored 2026-02-17 through 2026-02-18, with the first three archived on 2026-02-18 ("chapter closed pre-hackathon") and the fourth remaining active in `docs/research/`.

### 1. Location Proof Leakage Investigation (origin document)

| | |
|---|---|
| **Path** | [docs/archive/research/location-proof-leakage-investigation.md](../archive/research/location-proof-leakage-investigation.md) |
| **Retention** | Archive |
| **Created** | `7d9566a` 2026-02-17 — "docs: investigate proximity proof location leakage" |
| **Archived** | `f67b2fb` 2026-02-18 — "Archive location proof research docs (chapter closed pre-hackathon)" |
| **Risk verdict** | **YELLOW** (overall) |
| **Core question** | Does the EVE Frontier location proof system leak distance or coordinate information through on-chain data? |

**Key findings:**
- `LocationProofMessage.distance: u64` is exposed in **plaintext** in BCS-encoded transaction inputs for every `link_gates` and proximity proof transaction — rated RED
- `GateConfig.max_distance_by_type` is a shared object, publicly readable (threshold leakage)
- `verify_distance()` has no deadline check (`_clock` parameter is unused) — proofs never expire
- Coordinate recovery via trilateration is theoretically possible with ≥4 non-coplanar anchor points
- Production thresholds: type 88086 ≈ 55 ly, type 84955 ≈ 110 ly (exact 2:1 ratio)
- Mentions EVE solar system positions as potential anchor points but does NOT model star-DB matching

### 2. Location Proof Actionability Analysis (downgrade)

| | |
|---|---|
| **Path** | [docs/archive/research/location-proof-actionability-analysis.md](../archive/research/location-proof-actionability-analysis.md) |
| **Retention** | Archive |
| **Created** | `dbb0605` 2026-02-17 — "docs: add location proof actionability analysis (GREEN — not exploitable cross-player)" |
| **Archived** | `f67b2fb` 2026-02-18 |
| **Risk verdict** | **GREEN** (downgraded from YELLOW) |
| **Core question** | Is the leakage identified in Doc 1 practically actionable for network-wide intelligence? |

**Key findings:**
- **Critical constraint:** `link_gates` requires `OwnerCap` for BOTH gates from the SAME character — all distance edges are intra-player. Cross-player graph construction is structurally impossible
- No `solar_system_id` on any assembly-type struct (Gate, Assembly, StorageUnit, NetworkNode)
- No on-chain system → coordinates mapping
- `GatesLinkedEvent` does NOT exist — no event emitted by `link_gates()`
- Killmail.solar_system_id is the ONLY place solar system ID appears on-chain; does NOT link back to gates/assemblies
- **Strategic recommendation: IGNORE for hackathon**
- Does NOT model off-chain star database matching (gap filled by Doc 3)

### 3. Distance-Constraint Solar System Mapping Analysis (upgrade)

| | |
|---|---|
| **Path** | [docs/archive/research/distance-constraint-system-mapping-analysis.md](../archive/research/distance-constraint-system-mapping-analysis.md) |
| **Retention** | Archive |
| **Created** | `a62597e` 2026-02-17 — "docs: distance-constraint system mapping analysis (ORANGE classification)" |
| **Refined** | `0fe8108` 2026-02-17, `2deb8b1` 2026-02-17 |
| **Archived** | `f67b2fb` 2026-02-18 |
| **Risk verdict** | **ORANGE** (upgraded from GREEN) |
| **Core question** | Can observed `link_gates` distances be matched against a public star coordinate database to identify which solar systems a player has gates in? |

**Key findings — THIS IS THE MAIN STAR-DB MATCHING WRITEUP:**
- Distance unit confirmed as **meters** (max_distance values match 55 ly / 110 ly to ±0.00000003%)
- At integer-meter precision each distance value is effectively **unique** across ~288M system pairs
- Single cross-system gate link: ~400–4,000 candidate pairs at practical tolerances (>99% search-space reduction)
- **Multi-link intersection** converges to near-certain identification: 3 links ≈ 0.9 false matches, 5 links < 1, 7 links < 1
- Universe: ~24,000 solar systems, ~15,000 × 9,500 × 2,500 ly extent
- Historical retrieval fully supported — no need for real-time monitoring
- Distance is linear (not squared) — squared meters at inter-system scale would overflow u64
- **Practical impact:** An observer can determine which specific solar systems a player operates in — competitive intelligence

### 4. Location Proof Independent Audit (adversarial review)

| | |
|---|---|
| **Path** | [docs/research/location-proof-independent-audit.md](location-proof-independent-audit.md) |
| **Retention** | Prep-only |
| **Created** | `ca9c8a4` 2026-02-18 — "Finalize CivControl docs: evidence ledger, demo beats, audits" |
| **Updated** | `a013a3a` 2026-03-03 — "docs: v0.0.15 drift sweep" |
| **Risk verdict** | Mixed **YELLOW / ORANGE** |
| **Core question** | Are there additional leakage/inference surfaces beyond the known gate-distance plaintext issue? |

**Key findings (new surfaces beyond Docs 1–3):**
- Unchecked signed metadata fields (`source_structure_id`, `source_location_hash`, `data`) create cross-transaction fingerprinting channels
- No deadline enforcement in `verify_distance` confirmed — highest-priority hardening target
- ZK PoC `LocationAttestationData.timestamp` is caller-supplied, stored without cryptographic binding
- ZK PoC `distance_squared_meters` directly decodable from tx inputs
- ZK PoC distance storage key fragmentation (ordered but not canonicalized concatenation)
- Gate/SSU creation events emit `location_hash`; `JumpEvent` exposes source/dest gate IDs + character → route usage graph reconstruction
- `server_address` reusable across users/sessions for server-issuer correlation

---

## Threat Evolution Summary

| Threat | Doc 1 | Doc 2 | Doc 3 | Doc 4 |
|--------|-------|-------|-------|-------|
| Distance value leakage (per-link) | RED | RED | — | ORANGE |
| Cross-player distance enumeration | YELLOW | **GREEN** | GREEN | — |
| Network-wide graph reconstruction | YELLOW | **GREEN** | GREEN | — |
| **Solar system pair identification** | YELLOW | **GREEN** | **ORANGE** | — |
| CivilizationControl auto-placement | YELLOW | GREEN | — | — |
| ZK PoC distance attestation | — | — | — | YELLOW |
| Fingerprinting via unchecked metadata | — | — | — | YELLOW |

---

## Supporting Artifacts — Code & Scripts

These scripts demonstrate and reproduce the on-chain distance exposure documented in the primary investigation.

| # | Path | Role |
|---|------|------|
| 1 | [sandbox/validation/generate_distance_proof.mjs](../../sandbox/validation/generate_distance_proof.mjs) | **Proof factory** — BCS-serializes `LocationProofMessage` with plaintext `distance: u64` and signs with Ed25519. The output bytes are submitted on-chain as-is. |
| 2 | [sandbox/validation/generate_distance_proof.js](../../sandbox/validation/generate_distance_proof.js) | CommonJS variant of the same script. Identical BCS layout and signing logic. |
| 3 | [sandbox/validation/step9.sh](../../sandbox/validation/step9.sh) | **On-chain submitter** — generates distance proof with `--distance 0` and passes proof bytes as `vector<u8>` argument to `link_gates` PTB call. Most direct evidence of on-chain distance exposure. |
| 4 | [sandbox/validation/step4.sh](../../sandbox/validation/step4.sh) | **Config writer** — calls `gate::set_max_distance` to write `maxDist` to shared `GateConfig` (publicly readable). |
| 5 | [sandbox/validation/gate_lifecycle_rehearsal.sh](../../sandbox/validation/gate_lifecycle_rehearsal.sh) | **Full pipeline** — end-to-end gate lifecycle: server keypair → set_max_distance → anchor with location_hash → link_gates with distance proof. |
| 6 | [sandbox/validation/gate_lifecycle_steps.sh](../../sandbox/validation/gate_lifecycle_steps.sh) | **Stepwise pipeline** — same lifecycle, modular form. |

## Supporting Artifacts — Operational Documentation

| # | Path | Role |
|---|------|------|
| 7 | [docs/operations/gate-lifecycle-runbook.md](../operations/gate-lifecycle-runbook.md) | **Carry-forward runbook.** Includes BCS message layout documentation confirming the struct format needed to deserialize distance from tx data: `player_address(32) + target_location_hash(32) + distance(u64 LE) + deadline(u64 LE)`. |
| 8 | [notes/gate-lifecycle-evidence.md](../../notes/gate-lifecycle-evidence.md) | Incomplete evidence log from 2026-02-16 rehearsal. Truncated before distance-relevant steps (Steps 4, 8, 9). |

---

## Secondary References (passing mentions)

These files mention gate distance, location proof, or proximity in the context of broader analysis. Listed for completeness — none contain dedicated investigation of the leakage question.

### Architecture & Feasibility

| Path | Key mention |
|------|------------|
| [docs/architecture/sui-playground-capabilities.md](../architecture/sui-playground-capabilities.md) | ZK proximity PoC deep dive (§7): `verify_proximity()`, DistanceData/LocationData, server-signed proximity proofs, distance attestation circuit references |
| [docs/architecture/authenticated-user-surface-analysis.md](../architecture/authenticated-user-surface-analysis.md) | Proximity proof for SSU deposit/withdraw, `location.move` verify_distance/verify_proximity, ZK PoC as alternative |
| [docs/architecture/gatecontrol-feasibility-report.md](../architecture/gatecontrol-feasibility-report.md) | Proximity proof complexity for SSU; Coin transfer avoids proximity |
| [docs/architecture/world-contracts-auth-model.md](../architecture/world-contracts-auth-model.md) | verify_proximity() L106, verify_proximity_proof_from_bytes() L130, deposit/withdraw proximity requirements |
| [docs/architecture/gate-lifecycle-function-reference.md](../architecture/gate-lifecycle-function-reference.md) | Gate function reference: link_gates, set_max_distance signatures |
| [docs/architecture/structural-risk-sweep-2026-02-18.md](../architecture/structural-risk-sweep-2026-02-18.md) | Distance proof reusability (A13), proximity-free extension path |
| [docs/architecture/sweep-audit-artifacts-2026-02-18.md](../architecture/sweep-audit-artifacts-2026-02-18.md) | Proximity proof deadlines, deposit_item needs NO proximity proof |
| [docs/architecture/read-path-architecture-validation.md](../architecture/read-path-architecture-validation.md) | PriorityListUpdatedEvent ENTERED = proximity entry |
| [docs/architecture/tradepost-cross-address-ptb-validation.md](../architecture/tradepost-cross-address-ptb-validation.md) | Owner-direct proximity proof; TradePost avoids proximity proof |
| [docs/architecture/turret-contract-surface.md](../architecture/turret-contract-surface.md) | ENTERED = target entered proximity |

### Core / Implementation Planning

| Path | Key mention |
|------|------------|
| [docs/core/spec.md](../core/spec.md) | LocationRegistry now stores **plain-text coordinates** on-chain (was hashes). `reveal_location()` on all assemblies. Separate and more direct exposure vector than distance-proof leakage. |
| [docs/core/march-11-reimplementation-checklist.md](../core/march-11-reimplementation-checklist.md) | LocationRegistry + reveal_location detail: `Coordinates` struct with `solarsystem: u64`, `x/y/z: String`. LocationRevealedEvent. |
| [docs/core/civilizationcontrol-implementation-plan.md](../core/civilizationcontrol-implementation-plan.md) | Linked gates, extension authorization, LocationRegistry coordinates for SVG map |
| [docs/core/civilizationcontrol-demo-beat-sheet.md](../core/civilizationcontrol-demo-beat-sheet.md) | Gate link lines shift green → amber in demo |

### UX

| Path | Key mention |
|------|------------|
| [docs/ux/civilizationcontrol-ux-architecture-spec.md](../ux/civilizationcontrol-ux-architecture-spec.md) | Link gates (distance proof), LocationRegistry plain-text coordinates, "Distance revealed in proof transactions" |
| [docs/ux/svg-topology-layer-spec.md](../ux/svg-topology-layer-spec.md) | Cross-system link distance, jump distance not rendered to scale |

### Strategy & Ideas

| Path | Key mention |
|------|------------|
| [docs/strategy/_shared/hackathon-portfolio-roadmap.md](../strategy/_shared/hackathon-portfolio-roadmap.md) | ZK as GateControl rule type, proximity proof removed from SSU, LocationRegistry plain-text coordinates update |
| [docs/ideas/wildcard-sprint-analysis.md](../ideas/wildcard-sprint-analysis.md) | Gate linked_gate_id, GateConfig |
| [docs/ideas/hackathon-ideas-grounded-v3-judged.md](../ideas/hackathon-ideas-grounded-v3-judged.md) | Gate linking, linked gates pre-deployed |
| [docs/archive/ideas/hackathon-ideas-grounded.md](../archive/ideas/hackathon-ideas-grounded.md) | Badge rarity by distance |
| [docs/archive/ideas/hackathon-ideas-grounded-v2.md](../archive/ideas/hackathon-ideas-grounded-v2.md) | link_gates distance proof, mock locally |

### Analysis & Validation

| Path | Key mention |
|------|------------|
| [docs/analysis/assumption-registry-and-demo-fragility-audit.md](../analysis/assumption-registry-and-demo-fragility-audit.md) | A-56: link_gates requires server-signed distance proof (Ed25519 over BCS LocationProof). SR-2. Scenario 5: gate linking impossible without distance proof |
| [docs/analysis/must-work-claim-registry.md](../analysis/must-work-claim-registry.md) | INF-12: link_gates requires AdminACL + distance proof |
| [docs/analysis/fortune-gauntlet-feasibility.md](../analysis/fortune-gauntlet-feasibility.md) | GateLinkedEvent, smart_gate config references |
| [docs/analysis/fortune-gauntlet-scoring-report.md](../analysis/fortune-gauntlet-scoring-report.md) | Linked gates, cannot link 3+ gates in test |
| [docs/validation/localnet-validation-backlog.md](../validation/localnet-validation-backlog.md) | GC-14: Distance proof / link_gates — BLOCKED (requires server key) |
| [docs/research/evefrontier-builder-docs-map.md](../research/evefrontier-builder-docs-map.md) | LocationRegistry + reveal_location detail, plain-text coordinates |

### Other

| Path | Key mention |
|------|------------|
| [docs/decision-log.md](../decision-log.md) | Gate lifecycle evidence references, LocationRegistry plain-text coordinates |
| [docs/ptb/proof-extraction-moveabort.md](../ptb/proof-extraction-moveabort.md) | Proof extraction and MoveAbort investigation |
| [experiments/atomic_courier_experiment/FEASIBILITY-REPORT.md](../../experiments/atomic_courier_experiment/FEASIBILITY-REPORT.md) | Proximity proofs as delivery triggers |
| [docs/operations/zk-gatepass-feasibility-report.md](../operations/zk-gatepass-feasibility-report.md) | ZK gate pass feasibility |

---

## Related Vendor Submodule (read-only context)

| Path | Relevance |
|------|-----------|
| `vendor/eve-frontier-proximity-zk-poc/` | The ZK proximity proof-of-concept analyzed in Doc 4. Contains Groth16 circuits for distance/location attestation. |
| `vendor/world-contracts/` | Canonical Move source for `gate.move`, `location.move` functions analyzed across all 4 docs. |

---

## Git History Timeline

| Date | Commit | Action |
|------|--------|--------|
| 2026-02-17 15:04 | `7d9566a` | Created: location-proof-leakage-investigation.md (YELLOW) |
| 2026-02-17 15:33 | `dbb0605` | Created: location-proof-actionability-analysis.md (GREEN) |
| 2026-02-17 16:05 | `a62597e` | Created: distance-constraint-system-mapping-analysis.md (ORANGE) |
| 2026-02-17 16:45 | `0fe8108` | Refined: distance-constraint analysis (24k systems, link-pair mechanics) |
| 2026-02-17 18:02 | `2deb8b1` | Refined: universe geometry assumptions and max-range bounding |
| 2026-02-18 10:24 | `ca9c8a4` | Created: location-proof-independent-audit.md (YELLOW/ORANGE) |
| 2026-02-18 10:57 | `f67b2fb` | **Archived** Docs 1–3 from `docs/research/` → `docs/archive/research/` ("chapter closed pre-hackathon") |
| 2026-03-01 11:51 | `85e2841` | Updated archived docs during pre-hackathon structural hardening |
| 2026-03-03 14:44 | `a013a3a` | Updated independent audit during v0.0.15 drift sweep |

All three archived docs originated in `docs/research/` and were renamed (R100 = identical content) to `docs/archive/research/` in commit `f67b2fb`. No investigation files were deleted — the full chain is intact.

---

## Gaps & Uncertainty

1. **No decision log entry** explicitly documents the investigation findings, risk classifications, or the "IGNORE for hackathon" recommendation. The decision log references gate lifecycle evidence but not the leakage investigation itself.

2. **Evidence file incomplete.** [notes/gate-lifecycle-evidence.md](../../notes/gate-lifecycle-evidence.md) was truncated at Step 1 — no distance proof evidence was captured. Steps 4, 8, 9 evidence is missing from the notes.

3. **LocationRegistry plain-text coordinates.** The [spec.md](../core/spec.md) and [march-11-reimplementation-checklist.md](../core/march-11-reimplementation-checklist.md) document a **separate, more direct** exposure vector: `LocationRegistry` now stores plain-text `(solarsystem: u64, x: String, y: String, z: String)` coordinates on-chain with a `reveal_location()` function. This is post-investigation (the world-contracts API changed around March 10) and makes the distance-inference attack partially moot — coordinates may now be directly readable. **No dedicated investigation document exists for this new vector.**

4. **No empirical validation.** None of the four investigation docs include actual testnet/mainnet transaction analysis. The star-DB matching attack (Doc 3) is entirely theoretical with mathematical modeling but no observed production data.

5. **ZK PoC analysis is shallow.** Doc 4 identifies surfaces in the ZK proximity PoC but notes it was never deployed to production. Investigation scope was appropriate but limited.
