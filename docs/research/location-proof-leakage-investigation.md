# Location Proof Leakage Investigation

**Retention:** Prep-only

## Executive Summary

**Verdict: YELLOW — Bounded leakage exists. Exact pairwise distances are exposed, but raw coordinate recovery requires significant accumulation and at least one anchor point.**

The EVE Frontier world-contracts location proof system provides **integrity** (anti-tampering via Ed25519 signatures) but **zero confidentiality** for distance values. The `distance: u64` field in `LocationProofMessage` is transmitted as plaintext BCS-encoded transaction input data and is permanently, publicly readable from any `link_gates` transaction. Combined with publicly readable `max_distance` thresholds from the shared `GateConfig` object, an observer can build a growing distance graph of gate-linked structures.

However, converting pairwise distances into absolute 3D coordinates requires solving the distance geometry / trilateration problem, which needs ~4+ non-coplanar reference points with known absolute positions. This is a meaningful barrier but not an insurmountable one — EVE solar system positions have historically been public knowledge.

**Severity:** Medium. Distance leakage is real and trivially extractable, but does not directly yield coordinates. Coordinate recovery is theoretically possible with sufficient observations but requires external reference data.

**Impact on CivilizationControl:** Auto-placement of structures on a map is **not directly possible** from on-chain data alone. However, "within range" detection between specific structures is trivially confirmable, and relative spatial relationships can be reconstructed from accumulated distance proofs.

---

## Background: Location Commitment Model

Structures in EVE Frontier store their position as a **32-byte Poseidon2 hash** of their 3D coordinates:

```move
public struct Location has store {
    location_hash: vector<u8>,  // Poseidon2 hash, 32 bytes
}
```

Raw $(x, y, z)$ coordinates are **never stored on-chain**. The hash is a one-way commitment — computing coordinates from the hash alone is computationally infeasible (Poseidon2 has ~128-bit preimage resistance). This is the intended privacy model: the server knows coordinates, the chain knows only the commitment.

**Key implication:** Any leakage must come from *proof-level metadata* (distance values, error codes, thresholds), not from the hash itself. We are NOT attempting to reverse Poseidon2.

---

## Proof Types Examined

### 1. Gate Distance Proof (`verify_distance`)

**Source:** [`location.move` L153–175](../../../vendor/world-contracts/contracts/world/sources/primitives/location.move)

**Purpose:** Enforced during `gate::link_gates()` to verify two gates are within the maximum allowed range for their gate type.

#### 1.1 Proof Payload: `LocationProofMessage`

```move
public struct LocationProofMessage has drop {
    server_address: address,
    player_address: address,
    source_structure_id: ID,
    source_location_hash: vector<u8>,
    target_structure_id: ID,
    target_location_hash: vector<u8>,
    distance: u64,                    // ← NUMERIC DISTANCE (plaintext)
    data: vector<u8>,
    deadline_ms: u64,
}
```

**Finding: The proof struct contains an explicit `distance: u64` field.** This is the server-computed distance between the source and target structures, signed by an authorized server via Ed25519. The signature ensures integrity (the player cannot alter the distance), but the value itself is plaintext.

#### 1.2 Observable Outputs

| Channel | Observable? | Details |
|---------|-------------|---------|
| **Transaction input bytes** | **YES** | `distance_proof: vector<u8>` is a Sui transaction argument. All Sui tx inputs are permanently public (`sui_getTransactionBlock` with `showInput: true`). The BCS schema is known — any observer can deserialize and read `distance: u64`. |
| **`GateConfig.max_distance_by_type`** | **YES** | `GateConfig` is a **shared object** (created via `transfer::share_object()` in `gate::init()`). The `Table<u64, u64>` mapping `type_id → max_distance` is readable via `sui_getDynamicFieldObject`. |
| **Gate `type_id`** | **YES** | Stored on the `Gate` struct (shared object). Combined with `GateConfig`, anyone can look up the exact `max_distance` for any gate. |
| **Events** | **No distance.** | `GateCreatedEvent` contains `location_hash` and `type_id` but no distance. `JumpEvent` contains gate IDs and character — no distance. |
| **Return values** | **None.** | `verify_distance()` returns void. |
| **Stored state** | **No distance.** | The proof is consumed and dropped. No distance field persists on any on-chain object. |

#### 1.3 Error Surface

`verify_distance()` validation order at [`location.move` L163–175](../../../vendor/world-contracts/contracts/world/sources/primitives/location.move):

| Step | Check | Abort Code | Information Leaked |
|------|-------|------------|-------------------|
| 1 | Server in registry | `EUnauthorizedServer` (4) | Server identity invalid |
| 2 | Sender matches proof | `EUnverifiedSender` (2) | Wrong caller |
| 3 | Target hash matches | `EInvalidLocationHash` (3) | Wrong target structure |
| 4 | `distance <= max_distance` | **`EOutOfRange` (7)** | **Distance exceeds threshold** |
| 5 | Signature valid | `ESignatureVerificationFailed` (5) | Proof tampered |

**Key observation:** The distance check (step 4) occurs **before** signature verification (step 5). A malformed proof with excessive distance but invalid signature will abort at `EOutOfRange`, not at `ESignatureVerificationFailed`. This ordering leaks whether a given distance value exceeds the threshold, even for invalid proofs — although this is moot since the distance is already plaintext in the proof bytes.

On Sui, **failed transactions are recorded on-chain** with their abort code and module name. Any observer can distinguish `EOutOfRange` from other failure modes.

#### 1.4 Notable: No Deadline Check on Distance Proofs

`verify_distance()` does **not** accept a `Clock` parameter and performs **no deadline check**. In `gate::verify_gates_within_range()`, the `_clock: &Clock` parameter is accepted but unused (underscore-prefixed). This means valid distance proofs **never expire** and can be replayed indefinitely. This is a separate concern from leakage but is notable.

#### 1.5 Production Thresholds

From [`env.example`](../../../vendor/world-contracts/env.example):

| Gate Type ID | `max_distance` | Approximate Range |
|---|---|---|
| 88086 | 520,340,175,991,902,420 | ~55 light-years* |
| 84955 | 1,040,680,351,983,804,840 | ~110 light-years* |

*Assuming distance unit is meters (1 ly ≈ 9.461 × 10¹⁵ m). The exact 2:1 ratio suggests two gate tiers.

---

### 2. Proximity Proof (`verify_proximity` / `verify_proximity_proof_from_bytes`)

**Source:** [`location.move` L96–148](../../../vendor/world-contracts/contracts/world/sources/primitives/location.move)

**Purpose:** Used for SSU deposit/withdraw operations and inventory burns. Attests that a player is "in proximity" to a structure.

#### 2.1 Proof Payload

Uses the **same `LocationProofMessage` struct** as distance proofs — the `distance: u64` field is present in every proof.

**However,** `verify_proximity()` and `verify_proximity_proof_from_bytes()` **completely ignore the `distance` field.** They validate only:
1. Server authorization
2. Sender identity
3. Target location hash match
4. Deadline validity
5. Signature

The distance value is deserialized but never read. The proximity check is a pure boolean attestation: "the server certifies this player is near this structure."

#### 2.2 Observable Outputs

| Channel | Observable? | Details |
|---------|-------------|---------|
| **Transaction input bytes** | **YES** | Same as gate proofs — the `distance: u64` field is in the BCS-encoded proof bytes, publicly readable. Even though the on-chain code ignores it, the proof **still contains the distance**. |
| **Events** | **None.** | No proximity-specific events are emitted. |
| **Error surface** | **No distance-related errors.** | `verify_proximity` can abort with `EUnauthorizedServer`, `EUnverifiedSender`, `EInvalidLocationHash`, `EDeadlineExpired`, or `ESignatureVerificationFailed` — none of which reveal distance. |

#### 2.3 Where Proximity Proofs Are Used

| Operation | File | Distance Checked? |
|-----------|------|-------------------|
| `storage_unit::deposit_by_owner<T>()` | `storage_unit.move` | **No** — uses `verify_proximity_proof_from_bytes` |
| `storage_unit::withdraw_by_owner<T>()` | `storage_unit.move` | **No** — uses `verify_proximity_proof_from_bytes` |
| `storage_unit::chain_item_to_game_inventory<T>()` | `storage_unit.move` | **No** — uses `verify_proximity_proof_from_bytes` (through `inventory::burn_items_with_proof`) |
| `inventory::burn_items_with_proof()` | `inventory.move` | **No** — uses `verify_proximity_proof_from_bytes` |

Extension-based SSU operations (`deposit_item<Auth>`, `withdraw_item<Auth>`) require **no proximity proof at all** — only the extension witness type.

---

### 3. Same-Location Check (`verify_same_location`)

**Source:** [`location.move` L180–182](../../../vendor/world-contracts/contracts/world/sources/primitives/location.move)

**Purpose:** Used in `deposit_by_owner` to verify that an item's location hash matches the SSU's location hash.

```move
public fun verify_same_location(location_a_hash: vector<u8>, location_b_hash: vector<u8>) {
    assert!(location_a_hash == location_b_hash, ENotInProximity);
}
```

**Pure hash equality.** No proof, no server, no distance. Reveals only whether two structures are co-located (same Poseidon2 hash = same coordinates). This is a binary yes/no with no distance information.

---

## Inference Feasibility Analysis

### Can we recover exact distances between structures?

**YES — trivially.**

The `distance: u64` value is embedded in every `LocationProofMessage` in plaintext BCS encoding. When any player submits a `link_gates` transaction (or any proximity-checked transaction), the proof bytes are permanently stored as transaction input data on the Sui blockchain. Any observer with RPC access can:

1. Monitor `link_gates` transactions
2. Extract the `distance_proof: vector<u8>` argument
3. BCS-deserialize using the known `LocationProofMessage` schema
4. Read the `distance: u64` field directly

**No cryptographic skill required.** The signature provides integrity, not confidentiality.

Additionally, for proximity proofs (SSU deposit/withdraw), the `distance` field is present in the proof bytes even though the on-chain code ignores it. If the server populates this field truthfully for proximity proofs (rather than setting it to 0), those distances are also harvested.

### Can we narrow candidate solar systems?

**YES — with accumulation.**

An attacker passively observing all gate-linking transactions over time builds a **distance graph** where:
- Nodes = structures (gates)
- Edges = observed pairwise distances

Given the distance graph, **Multidimensional Scaling (MDS)** or trilateration can reconstruct a 3D point embedding that preserves all observed distances — up to a rigid transformation (rotation, translation, reflection). This is the well-known **distance geometry problem**.

**Requirements for absolute coordinate recovery:**

| Requirement | Assessment |
|---|---|
| ≥4 non-coplanar reference points with known absolute positions | EVE solar system coordinates are historically public; 1+ known anchor may suffice to orient the frame |
| Sufficient observed distances | Grows with every `link_gates` transaction; passive observation requires no server cooperation |
| Distance precision | Exact (u64 integer), no noise |
| Connected graph | Gate links create connectivity; isolated subgraphs can only be positioned relative to themselves |

### What assumptions are required?

1. **Passive observation:** Only requires blockchain read access (fully public). No server cooperation needed.
2. **Active querying:** Requesting specific distance proofs from the server requires game API access. The server could rate-limit or restrict proof issuance to gameplay-relevant pairs, limiting the attack surface.
3. **Absolute anchoring:** Converting relative positions to absolute coordinates requires at least one known reference point. If EVE Frontier publishes solar system coordinates (as EVE Online historically has), this is trivially available.
4. **Proof byte availability:** Sui stores full transaction data. Historical transactions remain queryable.

### Oracle querying risk

If we hypothetically had only the boolean pass/fail of `verify_distance()` (ignoring the plaintext distance in proof bytes):

- **Binary search is impossible** because the proof must be server-signed. A player cannot fabricate proofs with arbitrary distance values to probe the threshold.
- **However, `max_distance` is already public** from the shared `GateConfig` object, so the threshold is known without any querying.
- **The server is the gatekeeper** of distance values. If the server only issues proofs for legitimate gameplay interactions, the set of obtainable distances is bounded by player activity. But once issued and used on-chain, the distance is public forever.

---

## Risk Classification

### Overall: 🟡 YELLOW — Bounded leakage, not directly coordinate-recovering

| Risk Factor | Classification | Details |
|---|---|---|
| **Distance value leakage** | 🔴 Red | Exact `u64` distance exposed in every proof transaction |
| **Threshold leakage** | 🟡 Yellow | `max_distance` per gate type publicly readable, but low incremental value |
| **Error code partitioning** | 🟢 Green | Distinct errors exist but are redundant with direct distance reading |
| **Coordinate recovery** | 🟡 Yellow | Theoretically possible via trilateration with accumulated distances + anchor points, but requires significant effort and external data |
| **Same-location detection** | 🟢 Green | Reveals co-location only; likely already visible in-game |
| **Auto-map-placement** | 🟡 Yellow | Not directly possible from on-chain data alone; requires distance graph accumulation + reference positions |

The overall classification is **YELLOW** because:
- Distance leakage is real and trivial to exploit
- But it does not directly yield coordinates
- Coordinate recovery is theoretically possible but requires substantial accumulation, graph analysis, and at least one known anchor point
- The server controls proof issuance, limiting active querying (but not passive observation)

---

## Implications for CivilizationControl

### Can we auto-place structures on a map?

**Not directly from on-chain data alone.** Structure `Location` objects store only the Poseidon2 hash. Without raw coordinates or a coordinate-to-hash mapping, placement is impossible from hash inspection.

**However, with accumulated distance proofs:** If CivilizationControl passively indexes all `link_gates` transactions over time, it could reconstruct a **relative spatial embedding** of all gate-linked structures via MDS. With one or more known reference positions (e.g., from public EVE universe data), this embedding could be anchored to absolute coordinates. This would be a delayed, accumulation-based "map" rather than instant placement.

### Useful partial assists for CivilizationControl

| Capability | Feasible? | How |
|---|---|---|
| **"Same system" detection** | ✅ Yes | Compare `location_hash` values on structure objects |
| **"Within X distance" for a specific pair** | ✅ Yes | Read distance from any `link_gates` proof involving those structures |
| **"Structures near gate G"** | ✅ Partial | Read distances from all proofs involving gate G; limited to pairs that have been linked |
| **Relative spatial map** | ⚠️ Possible | Accumulate distance graph, apply MDS; quality depends on graph density |
| **Absolute coordinate map** | ⚠️ Theoretically possible | Requires relative map + anchor point(s) from external sources |
| **Real-time structure placement** | ❌ No | No mechanism to get coordinates for arbitrary structures without prior proof transactions |

### Server dependency

The game server is the sole source of `LocationProofMessage` instances. CivilizationControl cannot independently generate or verify distances — it can only **observe** distances from proofs that players have already submitted on-chain. The server controls:
- Which proof requests it fulfills
- What distance value it includes
- Rate limiting on proof issuance

This means the information leakage is **bounded by gameplay activity** — only structures that have been involved in gate-linking or proximity-checked operations expose their distances.

---

## Summary of Findings

| Proof Type | Distance in Payload? | Distance Checked? | Distance Observable? | Events with Distance? |
|---|---|---|---|---|
| **Gate linking** (`verify_distance`) | ✅ Yes, `u64` | ✅ Yes, `≤ max_distance` | ✅ Yes, from tx input bytes | ❌ No |
| **SSU proximity** (`verify_proximity_proof_from_bytes`) | ✅ Yes, `u64` | ❌ No, ignored | ✅ Yes, from tx input bytes* | ❌ No |
| **Same-location** (`verify_same_location`) | ❌ N/A | ❌ N/A | ❌ N/A | ❌ N/A |

\* Whether proximity proofs contain a meaningful distance depends on the server's behavior: it may set `distance: 0` for proximity proofs, or it may populate the true distance. If populated, it is observable from transaction data.

---

## Potential Mitigations (Informational)

These are not recommendations for CivilizationControl to implement — they describe what would need to change at the protocol level to eliminate leakage:

1. **ZK distance proof:** Replace plaintext `distance: u64` with a zero-knowledge proof that `distance ≤ max_distance`, revealing nothing about the actual value. This is the cryptographically sound solution.
2. **Encrypt proof bytes:** Encrypt the proof payload before submission, with the contract decrypting on-chain. Not practical on current Sui (no on-chain decryption primitive for this pattern).
3. **Remove distance from proximity proofs:** For operations that don't check distance (SSU interactions), the server could set `distance: 0` in the proof. This eliminates leakage from non-gate operations but doesn't fix gate linking.
4. **Server-side rate limiting:** Already partially in place — the server controls proof issuance. Tighter restrictions on which structure pairs get proofs would limit active querying but not passive observation of others' transactions.

---

## Confidence Level

**High confidence** in the technical findings. All conclusions are derived from direct source code analysis of `world-contracts`:

- [`location.move`](../../../vendor/world-contracts/contracts/world/sources/primitives/location.move) — proof structs, verification functions, error codes
- [`gate.move`](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — gate linking, distance enforcement, GateConfig
- [`storage_unit.move`](../../../vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move) — SSU proximity requirements
- [`sig_verify.move`](../../../vendor/world-contracts/contracts/world/sources/crypto/sig_verify.move) — signature verification
- [`env.example`](../../../vendor/world-contracts/env.example) — production threshold values

**What would increase confidence:**
- Confirming whether the server populates `distance` truthfully in proximity proofs (vs. setting to 0)
- Observing actual `link_gates` transactions on testnet/mainnet to verify proof byte contents
- Confirming whether EVE Frontier publishes absolute solar system coordinates (anchor points for trilateration)
- Confirming whether historical Sui transactions retain full input data indefinitely or prune

**No local devnet testing was needed** — the findings are fully derivable from source code inspection. The distance leakage is structural (the `distance: u64` field exists in every proof payload), not a runtime side-channel that would require empirical measurement.
