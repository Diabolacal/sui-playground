# ZK GatePass Feasibility Report

**Retention:** Carry-forward

> **Date:** 2026-02-16  
> **Status:** Pre-hackathon research — code moratorium until March 11  
> **Type:** Feasibility validation (research + architecture analysis, no hackathon code produced)  
> **Inputs:** `vendor/eve-frontier-proximity-zk-poc`, `vendor/world-contracts`, CC product vision, hackathon roadmap, existing validation reports  
> **Method:** Four-subagent audit (ZK PoC, GateControl integration, devnet feasibility, kill-switch/fallback)

---

## Executive Conclusion: YELLOW-GREEN

**ZK GatePass is architecturally feasible and the integration path is clear, but one critical gap remains unproven: composing `groth16::verify_groth16_proof()` with `gate::issue_jump_permit()` in a single transaction.** Both primitives work independently (proven), but their combination has not been devnet-tested. A fallback (two-step on-chain verification) exists if single-tx composition fails.

| Dimension | Signal | Confidence |
|-----------|--------|------------|
| ZK proof verification on Sui | **GREEN** | High — proven in PoC integration tests |
| Gate extension witness pattern | **GREEN** | High — proven in world-contracts tests + devnet validation |
| Combined ZK + gate extension | **YELLOW** | Medium — architecturally sound, not yet devnet-tested |
| Circuit availability (membership) | **YELLOW** | Medium — new circuit needed but PoC infrastructure is reusable |
| Gas / performance | **GREEN** | High — well within all Sui limits |
| Security model | **GREEN** | High — clear design with gate binding + timestamp |
| Demo viability | **GREEN** | High — clear narrative, strong visual, 30-second segment |
| Fallback plan | **GREEN** | High — tribe filter + toll validated, non-ZK CC is competitive |

**Recommendation:** Pursue ZK integration on March 11 with disciplined kill checkpoints (Day 1: circuit, Day 2: on-chain verify, Day 3 AM: gate integration). Maximum 28 hours budget (25% of sprint). If any RED trigger fires, kill immediately — core CC remains strong without ZK.

---

## 1. What Is Proven

### 1.1 Groth16 On-Chain Verification (Proven — HIGH confidence)

The `eve-frontier-proximity-zk-poc` provides a complete, working Groth16 pipeline:

- **Proving system:** Groth16 on BN254 curve via Circom 2.2.0 + snarkjs 0.7.5
- **On-chain verifier:** Sui Move native `sui::groth16::verify_groth16_proof()` — NOT off-chain
- **Two working circuits:**
  - `location-attestation`: 3 public inputs, ~2,359 constraints, ~320ms proof gen
  - `distance-attestation`: 6 public inputs (5 + 1 output), ~1,010 constraints, ~250ms proof gen
- **Proof format:** 128 bytes (G1 + G2 + G1 compressed, arkworks serialization)
- **Public inputs:** 3–6 × 32 bytes = 96–192 bytes (little-endian BN254 field elements)
- **Verification key:** 320–448 bytes depending on circuit (stored on-chain)
- **Integration tests:** Full end-to-end on local Sui network — circuit compile → proof generation → on-chain verification → state mutation

**Evidence:** [location_attestation.move](../../../vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move) L237–244 calls `groth16::verify_groth16_proof()` directly. Integration tests in [locationAttestationStepByStep.spec.ts](../../../vendor/eve-frontier-proximity-zk-poc/test/on-chain/integration/locationAttestationStepByStep.spec.ts) confirm transactions succeed.

### 1.2 Gate Extension Witness Pattern (Proven — HIGH confidence)

The world-contracts gate system uses a typed witness pattern for custom gate logic:

- **Extension registration:** `gate::authorize_extension<Auth>(&mut gate, &owner_cap)` stores `TypeName` on gate
- **Permit issuance:** Extension module calls `gate::issue_jump_permit<Auth>(source, dest, character, Auth{}, expiry, ctx)`
- **Jump execution:** Character calls `gate::jump_with_permit(source, dest, character, permit, acl, clock, ctx)` — permit is single-use (deleted after validation)
- **Existing examples:** `tribe_permit`, `corpse_gate_bounty` — both use dynamic fields on `ExtensionConfig`
- **Composable config:** `ExtensionConfig` (shared) with typed dynamic fields (`TribeConfigKey`/`TribeConfig`, `BountyConfigKey`/`BountyConfig`)
- **Gate is shared but low-contention:** Permit issuance uses `&Gate` (immutable ref)

**Evidence:** [gate.move](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) L105 (`authorize_extension`), L199 (`issue_jump_permit`). Tests in [gate_tests.move](../../../vendor/world-contracts/contracts/world/tests/assemblies/gate_tests.move) validate full lifecycle.

### 1.3 Individual Validation (Proven — HIGH confidence, from prior devnet work)

- **Tribe filter:** Devnet GREEN — tribe-1 passes, tribe-2 blocked atomically (ETribeMismatch)
- **Coin toll:** Devnet GREEN — 1 SUI payment, atomic transfer to collector
- **Cross-address buy:** Devnet GREEN — 3 buys at different prices, all successful
- **SSU-backed storefront:** Devnet GREEN — witness-gated extension withdrawal without OwnerCap

**Evidence:** [shortlist-viability-validation-report.md](shortlist-viability-validation-report.md) — 7/7 tests GREEN.

---

## 2. What Is NOT Proven

### 2.1 Combined ZK + Gate Extension (Critical Gap)

**No devnet test has combined `groth16::verify_groth16_proof()` with `gate::issue_jump_permit()` in the same transaction.** Both work independently, but the composition has not been validated.

**Specific concerns:**

| Concern | Risk | Mitigation |
|---------|------|------------|
| **Groth16 depth-0 constraint** | Medium — PoC notes that `groth16::verify_groth16_proof()` requires `entry` function (depth 0). If `gate::issue_jump_permit()` adds call depth, verification may fail. | Two-step fallback (P1): separate `entry` for verification and permit issuance. |
| **Package naming conflict** | Low-Medium — ZK PoC's Move package is named `world`, same as world-contracts. Both cannot be dependencies of the same package. | Rename/extract ZK verifier code into a separate package (e.g., `zkgate_verifier`). ~4–6 hours. |
| **VK from dynamic field** | Low — `df::borrow()` returns a reference; need to confirm `vector<u8>` from DF is accepted by `groth16::prepare_verifying_key()`. | Standard Move reference semantics; should work. |
| **Cross-package dependency** | Very Low — gate extension importing both `world::gate` and `sui::groth16`. Both are standard published packages/native modules. | Standard Move import pattern. |

### 2.2 Membership Circuit (Not Yet Designed)

The PoC has location and distance circuits. A gate membership circuit must be designed:

- **Purpose:** Prove "my character ID is in the allowed Merkle tree" without revealing which leaf
- **Design sketch:** 2 public inputs (`merkle_root`, `nullifier_hash`), ~500–1,000 constraints
- **Reuse:** PoC's Poseidon Merkle infrastructure (`MerkleVerifierLevel`, `poseidon-lite`, trusted setup) is directly reusable
- **Estimated effort:** 4–6 hours (circuit design + compile + trusted setup)

### 2.3 Sponsored Transaction Integration

All gate jumps require `AdminACL.verify_sponsor(ctx)`. Not tested on local devnet. The ZK extension must work within this sponsorship model — the verification gas is paid by the sponsor (game operator), not the player.

---

## 3. Proposed Interface Shape

### 3.1 Data Structures

```move
module zk_gate::zk_pass;

/// Witness type — registered via gate::authorize_extension<ZkPassAuth>()
public struct ZkPassAuth has drop {}

/// Stored as dynamic field on ExtensionConfig
public struct ZkGateConfigKey has copy, drop, store {}
public struct ZkGateConfig has drop, store {
    vkey_bytes: vector<u8>,          // Serialized verification key (~320-448 bytes)
    required_public_inputs: u8,      // Expected number of public inputs
    max_proof_age_ms: u64,           // Maximum age of proof (timestamp binding)
}
```

### 3.2 Function Signatures

```move
/// Setup: gate owner registers ZK extension and stores VK
public fun configure_zk_gate(
    extension_config: &mut ExtensionConfig,
    admin_cap: &AdminCap,
    vkey_bytes: vector<u8>,
    required_public_inputs: u8,
    max_proof_age_ms: u64,
);

/// Access: pilot submits ZK proof to get a JumpPermit
entry fun request_zk_access(
    extension_config: &ExtensionConfig,     // Shared — reads VK
    source_gate: &Gate,                      // Shared — immutable ref
    destination_gate: &Gate,                 // Shared — immutable ref
    character: &Character,                   // Shared — immutable ref
    proof_points_bytes: vector<u8>,          // 128 bytes (Groth16 proof)
    public_inputs_bytes: vector<u8>,         // N×32 bytes (LE field elements)
    clock: &Clock,                           // Shared — for expiry
    ctx: &mut TxContext,
);
```

### 3.3 Call Flow (Single PTB — Ideal)

```
Client:
  1. Generate membership proof off-chain (snarkjs, ~300ms)
  2. Serialize proof + public inputs (formatProofForSui)
  3. Construct PTB:
     - zk_pass::request_zk_access(config, src_gate, dst_gate, character, proof, inputs, clock)
     → internally: groth16 verify → issue_jump_permit<ZkPassAuth>() → JumpPermit transferred
     - gate::jump_with_permit(src_gate, dst_gate, character, permit, acl, clock)
     → jump executes, permit consumed
```

### 3.4 Call Flow (Two-Step — Fallback P1)

```
Client:
  Step 1: zk_pass::verify_and_approve(config, character, proof, inputs, clock, ctx)
     → internally: groth16 verify → store ZkApproval as dynamic field on config
  Step 2: zk_pass::claim_jump_permit(config, src_gate, dst_gate, character, clock, ctx)
     → internally: read ZkApproval → issue_jump_permit<ZkPassAuth>() → delete approval
  Step 3: gate::jump_with_permit(src_gate, dst_gate, character, permit, acl, clock, ctx)
```

---

## 4. Proof Format Contract

### 4.1 Bytes Flowing Through the System

| Component | Direction | Size | Format | Lifetime |
|-----------|-----------|------|--------|----------|
| **Verification Key** | Stored on-chain (dynamic field) | 320–448 bytes | arkworks compressed LE (G1 + G2×3 + IC) | Persistent |
| **Proof Points** | PTB argument | 128 bytes | G1(32) ∥ G2(64) ∥ G1(32) compressed | Ephemeral |
| **Public Inputs** | PTB argument | 64–192 bytes | N × 32-byte LE BN254 field elements | Ephemeral |
| **JumpPermit** | Created on-chain | ~100 bytes | Move struct (character_id, route_hash, expiry) | Single-use |

### 4.2 Transaction Size Budget

| Component | Bytes |
|-----------|-------|
| Proof points | 128 |
| Public inputs (6 worst case) | 192 |
| Object references (Gate×2, Character, ExtensionConfig, Clock, AdminACL) | ~250 |
| Move call target + type args | ~200 |
| Transaction envelope | ~200 |
| **Total ZK-specific overhead** | **~970 bytes** |
| **Transaction limit** | **131,072 bytes (128 KB)** |

**Verdict:** ZK overhead is < 1% of transaction limit. Transaction size is a non-issue.

---

## 5. Security Model

### 5.1 Proof Generation

**Client-side (player) generation.** The player holds private witness data (Merkle path, membership secret). A game authority provides signed attestation data (POD). The player generates the proof locally using snarkjs/WASM. This preserves the ZK privacy property — the prover reveals nothing about their identity beyond membership.

### 5.2 Replay Resistance

| Mechanism | Binding | Implementation | Contention Impact |
|-----------|---------|----------------|-------------------|
| **Gate binding** | Proof is valid only for a specific gate (or route) | Gate ID or route_hash as public input; Move code verifies match | None — read-only check |
| **Timestamp binding** | Proof expires after `max_proof_age_ms` | Timestamp as public input; Move code checks `ts > clock.now() - max_age` | None — read-only check |
| **Nonce binding** (optional, production) | One proof per character per epoch | Per-character nonce as dynamic field; increment after use | Adds shared-mutable writes — skip for hackathon |

**Hackathon recommendation:** Gate binding + timestamp binding (no shared-mutable state). Nonce is a documented stretch goal.

### 5.3 Who Can Issue Proofs

- **Proofs are self-generated** by the prover (player client)
- **Verification key** is set by the gate owner (trusted setup)
- **Merkle root** (the "allowlist") is a public input — whoever maintains the Merkle tree controls membership
- **Replay prevention** binds proof to gate + time window
- **No trusted verifier** needed for on-chain Groth16 — the blockchain verifies directly

### 5.4 Trust Model Comparison

| Model | Trusted Party | Privacy | On-Chain Verification |
|-------|---------------|---------|----------------------|
| **Allowlist (address set)** | Gate owner | None — addresses visible | Dynamic field lookup |
| **Signed attestation (Ed25519)** | Attestation signer | Partial — signature reveals who was attested | Signature check |
| **ZK membership proof (Groth16)** | Trusted setup ceremony only | Full — prover identity hidden | Native Groth16 verification |

---

## 6. Performance / Gas Expectations and Constraints

### 6.1 Gas Cost Estimates

| Operation | Estimated Gas (MIST) | Notes |
|-----------|---------------------|-------|
| `groth16::prepare_verifying_key()` | ~500,000 | Native BN254 VK preparation |
| `groth16::verify_groth16_proof()` | ~2,000,000–4,000,000 | Native BN254 pairing (Miller loop + final exp) |
| Dynamic field read (`df::borrow`) | ~5,000 | Standard DF access |
| `gate::issue_jump_permit()` | ~100,000–200,000 | Object creation + transfer |
| `gate::jump_with_permit()` | ~150,000–300,000 | Validation + event + object deletion |
| **Total ZK-gated jump** | **~3,000,000–5,000,000** | **~0.003–0.005 SUI** |
| Non-ZK gated jump (tribe permit) | ~500,000–800,000 | ~0.0005–0.0008 SUI |
| Default jump (no extension) | ~200,000–400,000 | ~0.0002–0.0004 SUI |

**ZK adds ~6–10× gas overhead** over a tribe permit check. Absolute cost remains under 0.005 SUI — acceptable for sponsored transactions.

### 6.2 Sui Constraints Checklist

| Constraint | Limit | ZK GatePass | Status |
|------------|-------|-------------|--------|
| Public inputs (Groth16) | 8 | 2–6 (membership: 2, proximity: 6) | **PASS** |
| Object size | 250 KB | VK: ~448 bytes (0.18%) | **PASS** |
| PTB commands | 1,000 | 2–3 commands | **PASS** |
| Transaction size | 128 KB | ~970 bytes (< 1%) | **PASS** |
| Dynamic fields per tx | 1,024 | 1–2 reads | **PASS** |
| Struct field limit | 32 | ZkGateConfig: 3 fields | **PASS** |

### 6.3 Client-Side Performance

| Operation | Time | Notes |
|-----------|------|-------|
| Proof generation (membership, ~1K constraints) | ~250–500ms | snarkjs in browser/WASM |
| Proof generation (location, ~2.4K constraints) | ~320ms | Measured in PoC |
| Proof serialization | ~10ms | arkworks format conversion |
| **Total client latency** | **~300–600ms** | Acceptable for gate UI interaction |

### 6.4 Shared Object Contention

No new shared-mutable objects introduced. ZK verification reads `ExtensionConfig` and `Gate` via immutable references. `JumpPermit` is an owned object transferred to the character. Contention profile is identical to existing gate extensions (tribe_permit, corpse_gate_bounty).

---

## 7. Kill Criteria and Fallback Plan

### 7.1 Kill Criteria (RED — Immediate Stop)

| # | Kill Trigger | Timeline | Redirect To |
|---|-------------|----------|-------------|
| R1 | Membership circuit fails to compile after 6 hours | Day 1 | Core polish (UI, dashboard) |
| R2 | Trusted setup fails or produces artifacts > 50 MB | Day 1 | Core polish |
| R3 | Groth16 verification fails on devnet after 4 hours debugging | Day 2 | TradePost polish + side entries |
| R4 | Total ZK time exceeds 8 hours with no on-chain verify | Day 2 mid | TradePost polish + side entries |
| R5 | Integration requires modifying GateControl core extension pattern | Day 3 | Kill — regression risk unacceptable |
| R6 | Demo rehearsal with ZK exceeds 3:30 total video | Day 5 | Cut ZK from video only |

### 7.2 GREEN/YELLOW/RED Signals

| Signal | Criteria | Action |
|--------|----------|--------|
| **GREEN** | All G1–G7 met: circuit compiles, setup completes, proof ≤ 2s, on-chain verify, gate integration, demo flow ≤ 5 actions, total ≤ 28h | ZK is the demo "wow moment" — 30-second segment |
| **YELLOW** | G1–G4 met but G5 fails (gate integration) | Use two-step on-chain verification (P1). Demo both steps. Score impact: -0.3 |
| **RED** | Any R1–R6 trigger fires | Kill ZK entirely. Redirect to core polish. |

### 7.3 Fallback Plan (GateControl Without ZK)

| Rule Type | Status | Demo-Ready |
|-----------|--------|------------|
| **Tribe Filter** | Devnet validated (GREEN) | Yes |
| **Coin Toll** | Devnet validated (GREEN) | Yes |
| **Time Window** | Designed, not implemented | 4–6 hours to build |
| **Allowlist** | Simple dynamic field lookup | 2–4 hours to build |

**Without ZK, the "wow moment" shifts to composable policy engine:** three rules activating on the same gate, configured from browser, enforced atomically.

### 7.4 Score Impact

| Scenario | Weighted Score | Delta from Full ZK |
|----------|---------------|-------------------|
| Full GREEN (ZK works) | ~8.48 | — |
| YELLOW (two-step ZK) | ~8.18 | -0.30 |
| RED (no ZK, tribe+toll+time) | ~7.98 | -0.50 |

Largest single-criterion loss without ZK: **Creativity (-1.5)**, where ZK is the primary differentiator. Other criteria see minimal impact. CC remains competitive for Best Entry without ZK.

### 7.5 Time Budget

| Phase | Hours | Kill Point |
|-------|-------|-----------|
| Circuit design + compile + setup | 4–6 | Day 1 EOD |
| Move wrapper + on-chain verify | 4–6 | Day 2 EOD |
| Gate extension integration | 4–6 | Day 3 noon |
| UI integration | 4–6 | Day 4 |
| Testing + buffer | 4 | Day 5 |
| **Maximum total** | **28** | **25% of sprint** |

---

## 8. March 11 Reimplementation Checklist (Docs Only)

### Day 1: Foundation

- [ ] Verify Docker, devnet, build pipeline
- [ ] Publish world-contracts to local devnet (GovernorCap → AdminCap → Characters → NWN → Gates → Link → Online)
- [ ] GateControl Move module: `GateAuth` witness + `PolicyConfig` + `TribeRule` + `CoinTollRule`
- [ ] Deploy GateControl. Test tribe pass/fail + toll payment.
- [ ] **ZK: Design membership Merkle circuit (Circom). Compile. Trusted setup. Test proof gen off-chain.**
  - Kill if no compiled circuit by EOD.

### Day 2: Verification

- [ ] TradePost Move module: `TradeAuth` + `Listing` + `buy()`. Deploy. Test cross-address buy.
- [ ] **ZK: Move Groth16 wrapper module. Resolve `world` naming conflict. Deploy. Test on-chain verification.**
  - Kill if no on-chain verify after 4 hours.

### Day 3: Integration

- [ ] **ZK: Gate extension integration. `request_zk_access()` → `issue_jump_permit()`. Test on devnet.**
  - Kill if not working by noon. Fall back to two-step (P1) or kill entirely.
- [ ] GateControl: TimeWindow rule (stretch)
- [ ] Begin frontend scaffolding (dashboard layout, wallet connect)

### Day 4–5: UI + Demo Prep

- [ ] Frontend: policy builder UI, storefront UI, activity feed
- [ ] ZK: proof generation button in UI (if GREEN/YELLOW)
- [ ] Demo rehearsal — ZK segment ≤ 30s, total ≤ 3:00
- [ ] Demo storyboard + script

### Day 6–7: Polish + Freeze

- [ ] All code frozen by Day 7
- [ ] Demo video recording
- [ ] README, submission materials

### Day 8–14: Side Entries + Buffer

- [ ] Side entries (Fortune Gate, Salvage Protocol, Corpse Toll Road)
- [ ] Submission packaging
- [ ] Buffer for unexpected issues

---

## 9. Proposed Proof Format Reference

### 9.1 Membership Proof (Recommended for GatePass)

| Field | Type | Size | Notes |
|-------|------|------|-------|
| `merkle_root` | Public input | 32 bytes | Poseidon hash of allowlist Merkle tree |
| `nullifier_hash` (optional) | Public input | 32 bytes | Replay prevention (stretch) |
| `gate_id_hash` (optional) | Public input | 32 bytes | Gate binding |
| `proof_points` | Ephemeral | 128 bytes | G1+G2+G1 compressed |
| **Total per proof** | — | **192–256 bytes** | Well under all limits |

### 9.2 Proximity Proof (Reuse Existing Distance Circuit)

| Field | Type | Size | Notes |
|-------|------|------|-------|
| `merkle_root1` | Public input | 32 bytes | Character location attestation |
| `merkle_root2` | Public input | 32 bytes | Gate location attestation |
| `coords_hash1` | Public input | 32 bytes | Character location hash |
| `coords_hash2` | Public input | 32 bytes | Gate location hash |
| `distance_squared` | Public input | 32 bytes | Manhattan distance² |
| `max_timestamp` | Public output | 32 bytes | Freshness bound |
| `proof_points` | Ephemeral | 128 bytes | G1+G2+G1 compressed |
| **Total per proof** | — | **320 bytes** | 6 public inputs (within 8-input limit) |

---

## 10. Open Questions for March 11

1. **Groth16 call depth:** Does `groth16::verify_groth16_proof()` work from inside a public function called by an `entry` function? The PoC notes unit tests skip verification due to depth constraints, but integration tests (also `entry` functions) work. The gate extension's `issue_jump_permit()` is a `public fun` — is this an additional level?

2. **Package naming conflict resolution:** The PoC's `world` package vs. world-contracts' `world` package. Extract ZK verification code into a standalone package? How much code can be reused vs. rewritten?

3. **Membership circuit design:** Finalize inputs/outputs. Include nullifier for replay resistance, or defer? What Merkle depth is sufficient for demo (depth-4 = 16 members, depth-8 = 256 members)?

4. **Proof generation UX:** Browser WASM vs. Node.js? What's the proving key size for a membership circuit? Can it be served from CDN?

5. **Sponsored transaction access:** Can we register as an authorized sponsor on local devnet for testing? Required for any `jump_with_permit()` call.

---

## References

- [ZK Kill-Switch & Fallback Analysis](../architecture/zk-killswitch-fallback-analysis.md) — detailed GREEN/YELLOW/RED criteria, demo narratives, partial ZK options
- [GateControl Feasibility Report](../architecture/gatecontrol-feasibility-report.md) — gate extension architecture, capability hierarchy
- [Shortlist Viability Validation Report](shortlist-viability-validation-report.md) — devnet test evidence for tribe/toll/buy
- [Shortlist Viability Validation Plan](shortlist-viability-validation-plan.md) — test matrix
- [CivilizationControl Product Vision](../strategy/civilizationcontrol-product-vision.md)
- [Hackathon Portfolio Roadmap](../strategy/hackathon-portfolio-roadmap.md) — ZK integration decision (§3, §4)
- ZK PoC: `vendor/eve-frontier-proximity-zk-poc/` (Groth16 circuits, Move contracts, integration tests)
- World Contracts: `vendor/world-contracts/contracts/world/sources/assemblies/gate.move` (gate extension system)
- World Contracts: `vendor/world-contracts/contracts/extension_examples/` (tribe_permit, corpse_gate_bounty patterns)
