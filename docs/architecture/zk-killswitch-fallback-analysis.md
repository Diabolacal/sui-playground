# ZK GatePass — Kill-Switch & Fallback Analysis

**Retention:** Prep-only

> **Date:** 2026-02-16  
> **Type:** Decision framework — quantitative kill criteria, fallback plans, demo narratives  
> **Inputs:** ZK PoC codebase analysis, GateControl feasibility report, CC strategy memo, hackathon roadmap, Groth16 constraint analysis  
> **Status:** ZK GatePass GREEN — composition and on-chain verification gates passed on local devnet (sandbox validation; to re-validate on hackathon test server March 11). This document remains relevant for the membership circuit kill gate and fallback planning. See [validation report](../operations/shortlist-viability-validation-report.md) tests 8–10 and [ZK feasibility report](../operations/zk-gatepass-feasibility-report.md) §2.1.

---

## 1. GREEN / YELLOW / RED Classification Criteria

### GREEN — Proceed with ZK in Demo (Full Integration)

All of the following must be true:

| # | Criterion | Measurement | Evidence Required |
|---|-----------|-------------|-------------------|
| G1 | Membership circuit compiles | `circom --wasm --r1cs` exits 0 | `.wasm` + `.r1cs` artifacts exist |
| G2 | Trusted setup completes | `snarkjs groth16 setup` exits 0 | `.zkey` file under 10 MB |
| G3 | Browser-side proof generation ≤ 2 seconds | `Date.now()` timing around `snarkjs.groth16.fullProve()` | Console log showing ms ≤ 2000 |
| G4 | Move `groth16::verify_groth16_proof()` accepts proof on devnet | Transaction succeeds (no abort) | Transaction digest with success status |
| G5 | `entry` function calls Groth16 verify AND `gate::issue_jump_permit<ZkAuth>()` in same tx | Transaction succeeds; JumpPermit created | JumpPermit object visible in `sui client objects`; JumpEvent emitted after `jump_with_permit` |
| G6 | End-to-end demo flow completable in ≤ 5 user actions | UI button → proof → verify → permit → jump | Screen recording of complete flow |
| G7 | Total ZK development time ≤ 28 hours (including circuit, Move, integration, UI) | Time tracking | Hours logged against ZK line items |

**If all G1–G7 are met:** ZK is the demo's "wow moment." Include the 30-second ZK segment in the 3-minute CC video. Target "Best Technical Implementation" explicitly.

---

### YELLOW — Proceed with Caution (Partial ZK)

At least G1–G4 are met, but G5 or G6 fails:

| # | Criterion | What It Means | Partial Inclusion Strategy |
|---|-----------|---------------|---------------------------|
| Y1 | Groth16 verifies on-chain BUT gate extension integration fails | The depth-0 `entry` constraint prevents calling `issue_jump_permit` in the same transaction as `groth16::verify_groth16_proof` | Use a two-step flow: (1) `entry` fun verifies proof and emits `ZkVerified` event + stores approval in dynamic field, (2) separate tx reads approval and issues permit. Clunkier but demonstrable. |
| Y2 | Proof generation works but takes > 2 seconds | Proof is valid but UX is poor | Pre-generate proof before demo recording. Show "proof generated" as a pre-loaded state. Mention generation time honestly in README. |
| Y3 | Circuit works for a simplified membership proof (e.g., depth-4 Merkle tree) but not production-scale (depth-20+) | Provably correct but toy-scale | Demo with depth-4 tree (16 members). Note in README: "Production deployment would use deeper trees." Judges evaluate concept, not scale. |
| Y4 | Move verification works but package naming conflict unresolved cleanly | `world` name collision between ZK PoC and world-contracts requires ugly wrapper | Ship wrapper. Acknowledge technical debt in code comments. Judges won't penalize scaffolding choices. |

**If YELLOW:** Include ZK in demo with appropriate caveats. Show proof verification on-chain. If gate integration is two-step, demo shows both steps with narration: "The blockchain verified the proof — now the gate opens." Score impact: -0.3 to -0.5 vs full GREEN.

---

### RED — Kill ZK, Fall Back to Non-ZK Rules

Any one of the following triggers an immediate kill:

| # | Kill Trigger | Why It's Fatal | When Detected |
|---|-------------|---------------|---------------|
| R1 | Membership circuit fails to compile after 6 hours of debugging | Circom constraint errors in a custom circuit indicate a design flaw, not a typo. Redesigning a circuit from scratch is a 2–3 day task. | Day 1 |
| R2 | Trusted setup fails or produces artifacts > 50 MB | Oversized proving keys indicate circuit complexity exceeds browser-viable threshold. Optimization requires circuit redesign. | Day 1 |
| R3 | Groth16 verification fails on devnet after 4 hours of debugging (bytes format, endianness, public input count mismatch) | The ZK PoC revealed that endianness conversion between snarkjs (little-endian) and Move Merkle verification (big-endian) is a multi-day debugging surface. If the membership circuit hits new format issues, the debugging cost is unbounded. | Day 2 |
| R4 | Total ZK time exceeds 8 hours with no working on-chain verification | Opportunity cost exceeds value. Every ZK hour past 8 is an hour stolen from UI polish, demo recording, or side entries. | Day 2 midpoint |
| R5 | ZK integration requires modifying GateControl's core extension pattern | ZK must be additive (a new rule type), not invasive (changing how rules dispatch). If integration requires restructuring `PolicyConfig` or the witness pattern, the regression risk to validated tribe/toll rules is unacceptable. | Day 3 |
| R6 | Demo rehearsal with ZK segment exceeds 3:30 total video length | The ZK segment is eating demo time from proven modules. GateControl and TradePost demos are more impactful per second than a buggy ZK flow. | Day 5 |

**If any R1–R6 triggers:** ZK is killed. No partial credit. All ZK code is moved to a `stretch/zk-experimental/` directory (not deleted — preserves option to revisit for Stillness deployment post-submission). Development immediately redirects to: (a) UI polish for GateControl + TradePost, (b) side entry sprints, or (c) TribeMint stretch if core is solid.

---

## 2. Kill Checkpoints (Day-by-Day)

14-day sprint: March 11 (Day 1) through March 24 (Day 14).

| Day | Date | Checkpoint | Must Have By EOD | Kill Action If Not Met |
|-----|------|-----------|------------------|----------------------|
| **1** | Mar 11 | **Circuit Design & Compile** | Membership Merkle circuit (Circom) compiles. Trusted setup completes. Test proof generated off-chain. | **Kill ZK entirely.** Redirect 100% to GateControl + TradePost Move modules. (Triggers R1 or R2) |
| **2** | Mar 12 | **On-Chain Verification** | Move `groth16::verify_groth16_proof()` accepts the membership proof on local devnet. Wrapper module resolves `world` naming conflict. | **Kill ZK entirely** if >4 hours spent debugging verification failures with no progress. (Triggers R3 or R4) |
| **3** | Mar 13 | **Gate Integration (AM)** | `entry` function: verify Groth16 proof → issue `JumpPermit<ZkAuth>`. OR: two-step flow with `ZkVerified` event + separate permit issuance. Full pass/fail scenario working on devnet. | **If neither approach works by noon Day 3:** Kill ZK. Fall back to tribe + toll only. (Triggers R5) |
| **3** | Mar 13 | **Gate Integration (PM)** | If AM produced YELLOW (two-step), decide: accept two-step for demo or kill. | **If two-step UX is too confusing for a 30-second demo segment:** Kill. |
| **5** | Mar 15 | **Demo Rehearsal** | Complete CC demo rehearsal including ZK segment. Total ≤ 3:00. ZK segment ≤ 30 seconds, visually clear, narratively coherent. | **If ZK segment is confusing, buggy, or pushes total past 3:30:** Cut ZK from demo. Code stays but isn't shown. (Triggers R6) |
| **7** | Mar 17 | **Final ZK Freeze** | All ZK code frozen. No further ZK development regardless of status. Remaining days are polish, side entries, and demo recording. | **Hard freeze. No exceptions.** Any ZK work after Day 7 is stealing from portfolio EV. |

### Time Budget Summary

| Phase | Hours | Cumulative | % of Total Sprint (~112 hrs) |
|-------|-------|-----------|------------------------------|
| Circuit design + compile + setup | 4–6 | 6 | 5% |
| Move wrapper + on-chain verify | 4–6 | 12 | 11% |
| Gate extension integration | 4–6 | 18 | 16% |
| UI integration (proof gen button, status) | 4–6 | 24 | 21% |
| Testing + debugging buffer | 4 | 28 | 25% |
| **Maximum total ZK budget** | **28** | — | **25%** |

**Hard cap: 28 hours.** If ZK is not demo-ready after 28 hours of effort, it is killed regardless of progress. This prevents the sunk-cost fallacy from cannibalizing core module quality.

---

## 3. Fallback Plan — GateControl Without ZK

### What Remains

| Rule Type | Status | Demo-Ready? |
|-----------|--------|-------------|
| **Tribe Filter** | Devnet validated (GREEN) | Yes — tribe-1 pass, tribe-2 blocked |
| **Coin Toll** | Devnet validated (GREEN) | Yes — 1 SUI payment, atomic transfer |
| **Time Window** | Designed, not implemented | Implementable in 4–6 hours. Low risk. |
| **Allowlist** | Not designed | Simple dynamic field lookup. 2–4 hours. Conceptually weak — just an address set. |

### Without-ZK Module Shape

```
GateControl (No ZK)
├── PolicyConfig (shared object)
│   ├── TribeRule (dynamic field) — tribe_id matching
│   ├── CoinTollRule (dynamic field) — Coin<SUI> payment
│   └── TimeWindowRule (dynamic field) — clock-based access windows [stretch]
├── GateAuth (witness) — issues JumpPermit when all rules pass
└── AdminCap — owner configures rules
```

Three composable rule types (two validated, one stretch) within a single extension. Still demonstrates dynamic field composition, typed witness pattern, and composable policy engine. Still unique in the hackathon field — no other entry will have a multi-rule gate extension.

### Demo Narrative Change

| Aspect | With ZK | Without ZK |
|--------|---------|-----------|
| **"Wow moment"** | "The blockchain never learned who you were" — proof verified, gate opens | "Three rules, one extension, one click" — composable policy engine configured from browser |
| **Demo climax** | ZK proof generation → on-chain verification → gate opens (30 sec) | Wrong-tribe pilot blocked → right-tribe pilot pays toll → time-window closes → all enforced atomically (25 sec) |
| **Technical depth** | Groth16 + dynamic fields + PTB composition (3 primitive families) | Dynamic fields + typed witness + PTB composition (2 primitive families) |
| **Judge impression** | "They built ZK-verified game infrastructure — nobody else did that" | "They built a composable policy engine — cleanest extension architecture in the field" |
| **Best Technical argument** | Strong — ZK is objectively the widest technical footprint | Medium — still strong but missing the cryptographic layer |

### Estimated Score Impact

| Criterion (12.5% each) | With ZK | Without ZK | Delta |
|------------------------|---------|-----------|-------|
| Concept & Feasibility | 9.0 | 9.0 | 0 |
| Mod Design | 9.5 | 9.0 | -0.5 |
| Concept Implementation | 8.5 | 8.0 | -0.5 |
| Player Utility | 9.0 | 9.0 | 0 |
| Frontier Vibe | 9.0 | 9.0 | 0 |
| Creativity | 8.5 | 7.0 | **-1.5** |
| UX & Usability | 8.5 | 9.0 | +0.5 (more polish time) |
| Demo | 9.0 | 8.5 | -0.5 |
| **Judge Average** | **8.81** | **8.31** | **-0.50** |
| Player Vote | 7.5 | 7.0 | -0.5 |
| **Weighted Total** | **8.48** | **7.98** | **-0.50** |

**Net impact: approximately -0.50 weighted points.** The largest single-criterion loss is Creativity (-1.5), where ZK is the primary differentiator. Without ZK, CivilizationControl's creativity story becomes "composable rule engine" — solid but not novel.

### What Replaces ZK in "Best Technical Implementation"

Without ZK, the Best Technical Implementation argument rests on:

1. **Dynamic field rule composition** — multiple rule types stored as typed dynamic fields, dispatched by key, within a single extension slot. This is a novel pattern not shown in builder docs or scaffold templates.
2. **Cross-address PTB composition** — buyer splits coin, pays, receives item, all in one transaction across two addresses. Demonstrates PTB mastery.
3. **Typed witness composability** — GateAuth and TradeAuth witnesses sharing a capability hierarchy.
4. **Two smart assembly types** — gate + SSU extensions in a single cohesive system.

This is competitive but not dominant. ZK would have made it unassailable. Without ZK, the argument shifts from "widest primitive footprint" to "deepest extension pattern mastery."

---

## 4. Demo Narrative Options

### Option A: "ZK Enabled" — Full Integration Demo

**Duration:** 30 seconds within the 3-minute CC demo video (segment at 1:50–2:20)

**Setup:** A gate with ZK Privacy Rule active. An allowlist Merkle tree containing 8 addresses. The demo pilot's address is in the tree.

**What the viewer sees:**

1. **(1:50)** Dashboard shows Gate Alpha with "ZK Privacy Rule" badge active alongside Tribe Filter and Toll.
2. **(1:52)** Pilot clicks "Request Access." A loading spinner appears: "Generating zero-knowledge proof..."
3. **(1:56)** Spinner resolves: "Proof generated (320ms)." A stylized proof visualization appears (hex bytes, partially revealed).
4. **(1:58)** Status changes to "Submitting proof to blockchain..."
5. **(2:02)** On-chain response: "✓ Proof Verified. Access Granted." Green checkmark animation.
6. **(2:05)** JumpPermit appears in pilot's inventory. Jump event fires in activity feed.
7. **(2:08)** Voiceover: *"The blockchain verified the proof. The gate opened. And the chain never learned who was on the list — only that the pilot belonged."*
8. **(2:15)** Quick cut: a pilot NOT on the list attempts the same gate. "✗ Proof Invalid. Access Denied." Red X.
9. **(2:20)** Return to full dashboard.

**The "wow moment":** The 4-second transition from "Generating proof..." to "Proof Verified. Access Granted." The judge sees: (a) real cryptographic computation happening in their browser, (b) on-chain verification they can inspect, and (c) a privacy guarantee they can reason about. No other hackathon entry will have this.

**How ZK is explained to a non-technical judge:**

> *"ZK Privacy Rule lets a gate owner define a private allowlist. Pilots can prove they're on the list without revealing which address they are. The proof is verified on the blockchain — trustless, private, and composable with the other gate rules."*

One sentence. No math. The demo visualization does the heavy lifting.

---

### Option B: "ZK Roadmap" — Honest Framing Without ZK

**Duration:** 10 seconds within the 3-minute CC demo video (closing segment at 2:45–2:55)

**What the viewer sees:**

1. **(2:45)** Full dashboard view after GateControl + TradePost demo.
2. **(2:48)** Voiceover: *"CivilizationControl's rule engine is designed for extensibility. Today: tribe filters, tolls, and time windows. Next: zero-knowledge privacy rules — private allowlists verified on-chain without revealing membership."*
3. **(2:52)** A roadmap slide appears showing "ZK Privacy Rule" as "In Development" with a lock icon.
4. **(2:55)** Final title card.

**Key rules for honest framing:**

- **DO say:** "Designed for extensibility," "Next: ZK privacy rules," "In development"
- **DO NOT say:** "We built ZK," "ZK is working," or show any ZK UI that doesn't function
- **DO NOT show** a ZK toggle in the policy builder unless it's clearly marked as "Coming Soon" with a disabled state
- **Frame as architecture, not failure:** The dynamic field rule composition pattern IS designed to accept new rule types without redeployment. ZK as a future rule type is architecturally true, not a lie.

**What replaces the "wow moment":**

The wow shifts to the **composable policy engine demo.** Three rules activating on the same gate, configured from a browser, enforced atomically:

1. Tribe filter: wrong tribe blocked → "Access Denied"
2. Right tribe, no toll: blocked → "Toll Required"
3. Right tribe, toll paid, within time window: → "Access Granted"

**Duration saved:** The 30 seconds freed by cutting ZK goes to:
- Extended TradePost demo (showing buyer and seller perspectives) — +15 sec
- Dashboard system reveal (more polished, wider shot, event feed scrolling) — +10 sec
- Closing narrative with roadmap — +5 sec

This produces a tighter, more polished video that may actually score higher on Demo (8.5 → 9.0) and UX (8.5 → 9.0), partially offsetting the Creativity loss.

---

## 5. Risk-Adjusted Development Sequencing

### March 11 (Day 1) — Optimal Hour-by-Hour Plan

| Hour | Activity | Track | Notes |
|------|----------|-------|-------|
| 0:00–0:30 | Environment verification (Docker, devnet, build pipeline) | Shared | Non-negotiable. Catches infra issues before coding starts. |
| 0:30–2:30 | Publish world-contracts to local devnet. Full setup chain: GovernorCap → AdminCap → Characters → NWN → Gates → Link → Online. | GateControl | **This is the single highest-risk task.** Location proofs, energy config, fuel deposits — 6+ sequential admin operations. Script it or fail. |
| 2:30–4:30 | GateControl Move module: `GateAuth` witness + `PolicyConfig` + `TribeRule` dynamic field. Deploy. Test tribe pass/fail. | GateControl | Validate against devnet. Capture tx digests. |
| 4:30–6:30 | GateControl: `CoinTollRule` dynamic field. Test toll payment. Capture tx digests. | GateControl | At this point, GateControl MVP is done — two validated rule types. |
| **6:30–8:30** | **ZK: Design membership circuit (Circom). Compile. Trusted setup.** | **ZK (parallel)** | **This is the first ZK kill checkpoint.** If circuit doesn't compile by hour 8, ZK is RED. |
| 8:30–10:00 | TradePost Move module: `TradeAuth` witness + `Listing` CRUD + `buy()`. Deploy. Test. | TradePost | Can start in parallel with ZK if second workstream available. |
| 10:00–12:00 | TradePost: Cross-address atomic buy. Full lifecycle test. | TradePost | TradePost MVP done. |

**End of Day 1 gate:**
- GateControl: 2 rule types working on devnet (GREEN) **or** kill TradePost, focus here
- TradePost: atomic buy working on devnet (GREEN) **or** pivot to Strategy A
- ZK: circuit compiled + trusted setup complete (GREEN) **or** ZK is RED, killed

### ZK Time Allocation Rules

| Rule | Rationale |
|------|-----------|
| **ZK work does not start before GateControl tribe+toll are devnet-validated** | Core must be safe before stretch begins. No exceptions. |
| **ZK gets at most 2 hours on Day 1** | Just the circuit. No Move code on Day 1. If the circuit doesn't compile in 2 hours, the design is wrong. |
| **ZK gets at most 6 hours on Day 2** | Move wrapper + on-chain verification. This is the highest-risk phase (endianness, public input format, BN254 field encoding). |
| **ZK gets at most 6 hours on Day 3** | Gate integration. If not working by noon, kill. |
| **ZK gets zero hours after Day 5** | UI integration on Day 4. Demo rehearsal on Day 5. After that, freeze. |
| **Maximum cumulative ZK hours: 28** | 2 + 6 + 6 + 6 + 4 (UI) + 4 (buffer) = 28. This is 25% of the total sprint. |

### Cannibalisation Thresholds

| Scenario | ZK Status | Action |
|----------|-----------|--------|
| Day 2 EOD: GateControl + TradePost both GREEN, ZK circuit compiled | Safe to continue ZK | Proceed to Move verification |
| Day 2 EOD: GateControl GREEN, TradePost YELLOW, ZK not compiling | ZK cannibalizing TradePost | **Kill ZK. Redirect to TradePost de-risking.** |
| Day 3 noon: GateControl + TradePost GREEN, ZK Move verify working | Safe to continue | Proceed to gate integration |
| Day 3 noon: GateControl + TradePost GREEN, ZK Move verify failing | ZK consuming critical path | **Kill ZK. Redirect to UI + dashboard.** |
| Day 5: All GREEN but demo is 4:00 with ZK segment | ZK eating demo quality | **Cut ZK from demo.** Code stays, video doesn't show it. |
| Any day: ZK debugging requires modifying GateControl core | ZK threatening validated code | **Immediate kill. Non-negotiable.** |

---

## 6. Partial ZK Options

If full on-chain Groth16 gate integration (GREEN) is too complex, four fallback positions exist with diminishing technical impressiveness:

### Option P1: Two-Step On-Chain Verification (YELLOW quality)

**Architecture:**
1. `entry fun verify_membership_proof(proof, vkey, public_inputs, config)` — verifies Groth16, stores `ZkApproval { character_id, expires_at }` as dynamic field on a shared `ZkVerifierConfig` object.
2. Separate tx: `entry fun issue_zk_permit(config, source_gate, dest_gate, character, clock, ctx)` — reads `ZkApproval`, verifies not expired, calls `gate::issue_jump_permit<ZkAuth>()`, deletes approval.

**Why it might be necessary:** Sui's `groth16::verify_groth16_proof` may not compose cleanly within a function that also calls `gate::issue_jump_permit`. The depth-0 constraint means the `entry` function calling Groth16 cannot be called by another `public fun`. If the gate extension's permit issuance adds call depth, the verification may fail.

**Judging impact:** Still qualifies as "ZK-verified gate access." The two-step nature is an implementation detail, not a conceptual weakness. Demo shows both steps in sequence. Judges familiar with Sui will understand the `entry` constraint.

**Score impact:** -0.3 from full GREEN (loses some UX elegance, gains honesty about constraints).

**Probability of being necessary:** ~40%. The PoC README explicitly documents this depth constraint. The integration seam is the key unknown.

---

### Option P2: Off-Chain Proof + On-Chain Signature Verification

**Architecture:**
1. Client generates Groth16 proof off-chain (snarkjs in browser).
2. A trusted verifier service (or the gate operator's backend) verifies the proof off-chain and signs an attestation: `Ed25519.sign({ character_id, gate_id, expiry })`.
3. On-chain: `entry fun claim_zk_permit(attestation_signature, attestation_data, source_gate, dest_gate, character, clock, ctx)` — verifies Ed25519 signature against registered verifier public key, then calls `gate::issue_jump_permit<ZkAuth>()`.

**Trade-offs:**
- (+) Avoids all Groth16 on-chain complexity. Ed25519 verification is trivial in Move.
- (+) Proof generation still happens — the ZK math is real, just verified off-chain.
- (-) **Introduces a trusted verifier.** This is fundamentally not trustless. The verifier service can lie.
- (-) Judges who understand ZK will correctly identify this as "ZK-inspired," not "ZK-verified."

**Judging impact:** Significantly weaker. Does NOT qualify as "ZK-verified" in a meaningful sense. The verifier is a centralized trust point. Would score at best 7/10 on Technical Implementation (vs 9/10 for full on-chain).

**When to use:** Only if both P1 and full integration fail, AND you still want to mention ZK in the demo. The off-chain proof generation is still real — show it, but be honest: "Proof verified by our attestation service. On-chain Groth16 verification is in our roadmap."

**Score impact:** -1.0 from full GREEN on Creativity, -0.5 on Technical Implementation.

---

### Option P3: Server-Generated Proof Attestation

**Architecture:** Similar to P2, but the server also generates the proof (not the client). The client submits their address; the server checks the Merkle tree, generates the proof, verifies it, and signs an attestation.

**Trade-offs:**
- (+) Simplest implementation. No client-side Circom/snarkjs dependency.
- (-) **The user never sees or generates a proof.** The entire ZK computation is hidden server-side.
- (-) **This is just a signed allowlist with extra steps.** A judge who asks "why not just sign the allowlist directly?" will not receive a satisfying answer.
- (-) Does NOT qualify as ZK-verified by any reasonable standard.

**Judging impact:** Do not present this as ZK. If asked, say: "We explored ZK verification but the integration timeline didn't allow full on-chain verification. The server currently uses a simulated allowlist."

**When to use:** Never for judging purposes. This is architecturally equivalent to a signed allowlist, which can be built in 2 hours without any ZK infrastructure.

**Score impact:** No ZK credit. Same score as Option B (no ZK).

---

### Option P4: ZK as Read-Only Dashboard Feature

**Architecture:**
1. Client generates a Merkle membership proof in the browser using snarkjs.
2. The proof is verified client-side (JavaScript, not on-chain).
3. The dashboard displays: "✓ You are a verified member of this gate's allowlist" with proof details.
4. Gate access still uses a standard allowlist rule on-chain (address lookup in dynamic field).

**Trade-offs:**
- (+) ZK proof generation and verification are genuinely happening — in the browser.
- (+) Demonstrates understanding of ZK primitives (circuit, proof, verification).
- (-) **Not on-chain.** The blockchain never sees the proof. The on-chain rule is just an address check.
- (-) Judges will see through this: "The ZK is cosmetic."

**Judging impact:** Minimal ZK credit. Might earn a "nice touch" comment but won't influence Technical Implementation scoring. Better than lying, worse than actual integration.

**When to use:** As a "ZK preview" feature in the dashboard, honestly labeled. "Client-side proof verification — on-chain integration in development." Shows technical understanding without overclaiming.

**Score impact:** +0.2 on Creativity (vs no ZK at all). No Technical Implementation impact.

---

### Partial Option Summary

| Option | On-Chain ZK? | Trustless? | "ZK-Verified" Claim? | Score vs Full GREEN | Recommended? |
|--------|-------------|------------|----------------------|--------------------|----|
| **P1: Two-Step On-Chain** | Yes | Yes | Yes | -0.3 | **Yes — primary fallback** |
| **P2: Off-Chain + Signature** | No (Ed25519 only) | No (trusted verifier) | Weakly | -1.5 | Only if P1 fails |
| **P3: Server Attestation** | No | No | No | Same as no ZK | No |
| **P4: Browser-Only** | No | N/A | No | +0.2 vs no ZK | As dashboard feature only |

**Recommendation:** If full GREEN integration fails, pursue P1 (two-step on-chain) as the primary YELLOW fallback. P1 preserves the core claims: on-chain Groth16 verification, trustless access, and privacy-preserving membership proof. The two-step UX is a minor demerit. P2–P4 are not worth the engineering time relative to their judging impact — better to kill ZK entirely and reallocate time to core polish.

---

## 7. Critical Technical Constraints (Reference)

### Groth16 Depth-0 Constraint

The ZK PoC README states:

> "Groth16 verification in Move unit tests is skipped (commented out) because it requires depth 0 (entry point), but unit tests add an extra level of call depth."

This means `groth16::verify_groth16_proof()` **must be called from an `entry` function**, not from a `public fun` that is itself called by an `entry` function. The gate extension pattern calls `gate::issue_jump_permit<Auth>()` which is a `public fun` — this creates potential depth issues if the ZK verification and permit issuance need to occur in the same call chain.

**Potential solutions:**
1. Single `entry fun`: verify proof AND issue permit in one function. If `issue_jump_permit` is also depth-0 safe, this works.
2. Two-step pattern (Option P1): separate `entry` functions for verification and permit issuance.
3. `gate::issue_jump_permit` may not have the same depth constraint — it uses `sui::transfer`, not `sui::groth16`. Needs devnet testing.

### Package Naming Conflict

The ZK PoC's Move package is named `world`, same as `vendor/world-contracts/contracts/world/`. Both cannot be dependencies of the same package. A wrapper module is required:

```
zkgate/
├── Move.toml          # depends on world-contracts AND zkgate_verifier
├── sources/
│   └── zk_gate.move   # entry functions + gate integration
└── zkgate_verifier/
    ├── Move.toml       # renamed from "world" → "zkgate_verifier"  
    └── sources/        # copied Groth16/Merkle verification code (subset)
```

Estimated time: 4–6 hours (extraction, rename, dependency resolution, testing).

### Membership Circuit Design

The existing ZK PoC has circuits for **location attestation** and **distance attestation**. A gate membership circuit needs to be designed from scratch:

**Input design (sketch):**
- Public inputs: `merkle_root` (Poseidon hash of allowlist tree), `nullifier_hash` (prevents double-use)
- Private inputs: `address` (the pilot's address), `merkle_path` (sibling hashes), `path_indices` (left/right flags), `nullifier_secret`

The existing PoC's `MerkleVerifierLevel` template and Poseidon hashing are directly reusable. The circuit itself is ~50–80 lines of Circom — simpler than the location attestation circuit (185 lines).

**Key unknown: nullifier pattern.** Without a nullifier, the same proof can be replayed. For a hackathon demo, replay protection may be unnecessary (mention as future work). With a nullifier, add ~20 lines of Circom and a nullifier set on-chain (dynamic field on config).

**Estimated circuit design + compile time: 4–6 hours.**

---

## 8. Decision Matrix — Summary

| Decision Point | GREEN Action | YELLOW Action | RED Action |
|---------------|-------------|---------------|------------|
| Day 1 EOD | Continue to Day 2 (Move verify) | Re-examine circuit design (1 retry) | Kill ZK, redirect to core polish |
| Day 2 EOD | Continue to Day 3 (gate integration) | Adopt P1 two-step pattern | Kill ZK, redirect to UI/demo |
| Day 3 noon | Freeze ZK code, begin UI integration | Accept P1, freeze, begin UI | Kill ZK, more GateControl rule types |
| Day 5 | ZK in demo video (30 sec segment) | ZK in demo with caveats (20 sec) | "Roadmap" mention only (10 sec) |
| Day 7 | ZK frozen, all effort to polish + side entries | Same | Same — ZK absent from final video |

### Net Expected Value Calculation

| Scenario | P(%) | Score Impact | Hours Consumed | EV Contribution |
|----------|------|-------------|---------------|-----------------|
| Full GREEN (ZK works perfectly) | 25% | +0.50 weighted points | 20–24 | +0.125 |
| YELLOW (P1 two-step works) | 25% | +0.20 weighted points | 22–28 | +0.050 |
| RED (ZK killed, time partially wasted) | 50% | 0 (plus opportunity cost of ~16 hrs lost) | 8–16 | -0.10 (indirect) |
| **Weighted Expected Value** | — | **+0.075 net** | **~18 avg** | Marginally positive |

**Interpretation:** The ZK gamble has a marginally positive expected value but high variance. The +0.50 upside (if GREEN) is material for prize placement. The downside is capped by kill checkpoints — maximum 16 hours wasted before redirect. The portfolio strategy (side entries) provides a floor regardless of ZK outcome.

**Final recommendation:** Pursue ZK with disciplined kill checkpoints. The infrastructure from the ZK PoC reduces implementation risk below what a from-scratch ZK attempt would face. But respect the kills — the moment any RED trigger fires, stop immediately. The core GateControl + TradePost submission is strong enough to compete without ZK.

---

*End of analysis. This document should be reviewed on March 11 (Day 1) and updated with actual outcomes as kill checkpoints are reached.*
