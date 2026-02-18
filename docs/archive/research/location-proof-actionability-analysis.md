# Location Proof Actionability Analysis

**Retention:** Prep-only

## 1. Executive Verdict

**GREEN — Leakage exists but is NOT practically actionable for network-wide intelligence.**

The original [location-proof-leakage-investigation.md](location-proof-leakage-investigation.md) correctly identified that `distance: u64` values are exposed in plaintext in every `LocationProofMessage`. This follow-up investigation determines whether that leakage is **actionable in practice**.

The critical finding that changes the threat model: **`link_gates` requires ownership of BOTH gates by the SAME character.** This means all distance edges obtained from gate-linking transactions are **intra-player** — revealing distances between a single player's own structures. Cross-player distance observations from gate links are structurally impossible.

This single architectural constraint collapses the network-wide graph reconstruction threat from YELLOW to GREEN:

| Threat | Original Assessment | Revised Assessment | Reason |
|--------|--------------------|--------------------|--------|
| Distance leakage (per-link) | RED | RED (unchanged) | Exact u64 distance is plaintext in every proof |
| Cross-player distance enumeration | YELLOW (implicit) | **GREEN** | Same-owner constraint prevents cross-player gate links |
| Network-wide graph reconstruction | YELLOW | **GREEN** | Graph is fragmented into per-player subgraphs; no cross-player edges |
| Solar system inference | YELLOW | **GREEN** | No `solar_system_id` on gate objects; no coordinate-to-system mapping on-chain |
| CivilizationControl auto-placement | YELLOW | **GREEN (marginal value)** | Possible for own gates only; player already knows their positions |
| Third-party intelligence exploit | Implied possible | **GREEN** | Insufficient cross-player data to reconstruct network topology |

**Strategic recommendation: IGNORE for hackathon. Use cautiously only for own-gate visualizations in future product iterations.**

---

## 2. Ownership Scope Findings

### 2.1 Does `link_gates` require ownership of BOTH gates?

**YES — both gates require separate OwnerCap authorization.**

[gate.move L155–171](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) takes two distinct `OwnerCap<Gate>` parameters:

```move
public fun link_gates(
    ...
    source_gate_owner_cap: &OwnerCap<Gate>,
    destination_gate_owner_cap: &OwnerCap<Gate>,
    ...
) {
    assert!(access::is_authorized(source_gate_owner_cap, source_gate_id), EGateNotAuthorized);
    assert!(access::is_authorized(destination_gate_owner_cap, destination_gate_id), EGateNotAuthorized);
```

Each `OwnerCap<Gate>` is bound to exactly one gate ID at creation. The module header comment confirms design intent: *"To link 2 gates, they must be at least 20KM away from each other and owned by the same character."*

The `borrow_owner_cap<Gate>` function ([character.move L137–146](../../vendor/world-contracts/contracts/world/sources/character/character.move)) requires `character.character_address == ctx.sender()`, so both OwnerCaps must be borrowable by the same transaction sender — **effectively requiring the same character to own both gates.**

**Implication: ALL gate-linking distance observations are between structures owned by the same player. An observer learns nothing about cross-player spatial relationships from gate links.**

### 2.2 Validation Order in `link_gates` + `verify_gates_within_range`

Complete validation chain in execution order:

| Step | Check | Location | Abort Code |
|------|-------|----------|------------|
| 1 | `source_gate_owner_cap` authorized for `source_gate_id` | [gate.move L167](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | `EGateNotAuthorized` (3) |
| 2 | `destination_gate_owner_cap` authorized for `destination_gate_id` | [gate.move L168–171](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | `EGateNotAuthorized` (3) |
| 3 | Both gates have `linked_gate_id == None` | [gate.move L174–177](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | `EGatesAlreadyLinked` (7) |
| 4 | → enters `verify_gates_within_range` | [gate.move L625](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | — |
| 5 | `max_distance` lookup for `source_gate.type_id` in `GateConfig` | [gate.move L613–618](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | `EGateTypeIdEmpty` (0) |
| 6 | → enters `location::verify_distance` | [location.move L152](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) | — |
| 7 | Proof bytes deserialized via `unpack_proof` | [location.move L154](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) | BCS abort |
| 8 | `message.server_address` in `ServerAddressRegistry` | [location.move L222–225](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) | `EUnauthorizedServer` (4) |
| 9 | `message.player_address == ctx.sender()` | [location.move L226](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) | `EUnverifiedSender` (2) |
| 10 | `message.target_location_hash == source_gate.location.location_hash` | [location.move L227](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) | `EInvalidLocationHash` (3) |
| 11 | `message.distance <= max_distance` | [location.move L158](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) | `EOutOfRange` (7) |
| 12 | Ed25519 signature verification | [location.move L159–163](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) | `ESignatureVerificationFailed` (5) |

**Critical: ownership checks (steps 1–2) occur BEFORE distance proof validation (steps 6–12).** A malicious user cannot reach `verify_distance` on gates they don't own through the `link_gates` entry point.

### 2.3 Can a Malicious User Trigger `verify_distance` on Others' Gates?

**Theoretically yes via custom Move package, but not exploitable.**

`verify_distance` ([location.move L147–164](../../vendor/world-contracts/contracts/world/sources/primitives/location.move)) is a `public fun` with no ownership check. Gates are shared objects with a public `location()` accessor ([gate.move L362](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move)). A custom Move package could:

1. Take `&Gate` as input (any shared gate)
2. Call `gate::location(gate)` to get `&Location`
3. Call `location::verify_distance(location, ...)` with their proof

**But this is NOT exploitable because:**

- The attacker still needs a **valid server-signed proof issued to their address** (`player_address == ctx.sender()`)
- The server controls which proofs it issues — the attacker can't force the server to compute arbitrary distances
- The proof is cryptographically bound — the attacker already received the distance value from the server off-chain when requesting the proof
- No new information is revealed beyond what the server voluntarily disclosed

**Exploitability rating: NEGLIGIBLE.** The attack surface is server-gated. The on-chain code merely validates what the server already told the player.

### 2.4 Can Arbitrary Gate Pairs Be Queried for Distance?

**Constrained by server policy, not by on-chain validation.**

On-chain, `validate_proof_message` checks only the **source gate's** location hash against the proof — `source_structure_id`, `target_structure_id`, `source_location_hash`, and the **destination gate's location hash are NOT validated** on-chain. The signature ensures integrity of whatever the server signed.

The practical constraint is that the CCP game server decides:

- Which structure pairs it will compute distances for
- Whether to fulfill a player's proof request at all
- What rate limiting to apply

**This means**: even if the on-chain code would accept a proof for any pair, the bottleneck is convincing the server to *issue* one. The server likely restricts proof issuance to gameplay-relevant interactions.

---

## 3. Proximity Proof Findings

### 3.1 Does the Server Populate `distance` Truthfully in Proximity Proofs?

**INDETERMINATE — but strongly constrained even if yes.**

Evidence collected:

| Source | Finding |
|--------|---------|
| On-chain code | `verify_proximity` completely ignores `distance` field ([location.move L99–116](../../vendor/world-contracts/contracts/world/sources/primitives/location.move)). Only checks server auth, sender, location hash, deadline, signature. |
| Sandbox test scripts | Always use `--distance 0` ([generate_distance_proof.mjs L95](../../sandbox/validation/generate_distance_proof.mjs), [gate_lifecycle_rehearsal.sh L667](../../sandbox/validation/gate_lifecycle_rehearsal.sh)). These are our simulated server — not production behavior. |
| Builder scaffold | Contains **no proof generation code**. No API endpoints that construct `LocationProofMessage`. |
| ZK PoC repo | Uses a completely different proof system (Groth16 with `DistanceAttestationData`). Not relevant to production `LocationProofMessage`. |
| Production server code | **Proprietary — not available in any vendor repo.** |

**Likely scenarios (speculation, clearly labeled):**

1. **Most likely:** Server sets `distance = 0` for proximity proofs, since the contract ignores it and there's no reason to compute it.
2. **Possible:** Server always computes real distance (simpler implementation — one code path for all proofs).
3. **Unlikely:** Server sets a different value depending on context.

**Even in the worst case (real distance populated):** Proximity proofs are used for SSU deposit/withdraw operations. These are per-player interactions with structures near them — the player already knows their own position relative to the SSU. The distance reveals nothing the player didn't already perceive in-game.

### 3.2 Can Proximity Proofs Be Used as a Distance Oracle?

**NO — not practically.**

For proximity proofs to function as a distance oracle, an attacker would need to:

1. Request proximity proofs for arbitrary structure pairs from the server
2. Receive proofs with truthful `distance` values
3. Submit or inspect those proofs to extract distances

**Constraints:**

- Proximity proofs are issued for game interactions (deposit, withdraw) — not arbitrary pair queries
- `verify_proximity` checks `player_address == ctx.sender()` — the proof must be addressed to the player
- The server controls issuance — there's no API to request "give me the distance between structure A and structure B"
- Even if obtainable, proximity proof distances would only reveal the player's own distance to structures they interact with

**Exploitability rating: NEGLIGIBLE.** Server-gated, use-case-restricted, and single-player scoped.

---

## 4. Object Model Findings

### 4.1 Field Breakdown

**Gate** ([gate.move L68–79](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move)):

| Field | Type | Publicly Readable? |
|-------|------|--------------------|
| `id` | `UID` | Yes (shared object) |
| `key` | `TenantItemId` | Yes |
| `owner_cap_id` | `ID` | Yes |
| `type_id` | `u64` | Yes |
| `linked_gate_id` | `Option<ID>` | Yes — reveals link topology |
| `status` | `AssemblyStatus` | Yes |
| `location` | `Location` | Yes — but only the hash |
| `energy_source_id` | `Option<ID>` | Yes |
| `metadata` | `Option<Metadata>` | Yes |
| `extension` | `Option<TypeName>` | Yes |

**Location** ([location.move L32–34](../../vendor/world-contracts/contracts/world/sources/primitives/location.move)):

| Field | Type | Notes |
|-------|------|-------|
| `location_hash` | `vector<u8>` | Poseidon2 hash of $(x, y, z)$. 32 bytes. Preimage-resistant. |

**NetworkNode** ([network_node.move L64–76](../../vendor/world-contracts/contracts/world/sources/network_node/network_node.move)):

| Field | Type | Notes |
|-------|------|-------|
| `id` | `UID` | Shared object |
| `key` | `TenantItemId` | |
| `owner_cap_id` | `ID` | |
| `type_id` | `u64` | |
| `status` | `AssemblyStatus` | |
| `location` | `Location` | Poseidon2 hash only |
| `fuel` | `Fuel` | |
| `energy_source` | `EnergySource` | |
| `metadata` | `Option<Metadata>` | |
| `connected_assembly_ids` | `vector<ID>` | Power dependency graph (energy), NOT spatial |

**GateConfig** ([gate.move L64–67](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move)):

| Field | Type | Notes |
|-------|------|-------|
| `id` | `UID` | Shared object |
| `max_distance_by_type` | `Table<u64, u64>` | `type_id → max_distance`, publicly readable |

**Killmail** ([killmail.move L42–56](../../vendor/world-contracts/contracts/world/sources/killmail/killmail.move)):

| Field | Type | Notes |
|-------|------|-------|
| `solar_system_id` | `TenantItemId` | **Only location where solar system ID appears on-chain** |

### 4.2 Key Findings

**Is `solar_system_id` stored on Gate/Assembly objects?**
**NO.** No assembly-type struct (Gate, Assembly, StorageUnit, NetworkNode) has a `solar_system_id` field. Solar system IDs appear **only** on `Killmail` objects, which don't link back to specific gates or assemblies.

**Is there an on-chain system → coordinates mapping?**
**NO.** No such mapping exists anywhere in world-contracts.

**Is solar system placement already derivable from on-chain data?**
**NO.** The combination of:
- Coordinates hashed (Poseidon2, preimage-resistant)
- No `solar_system_id` on any assembly
- No coordinate → system mapping

means an observer **cannot determine which solar system a gate is in** from on-chain data alone.

**What IS publicly readable:**
- Gate link topology (`linked_gate_id` — which gates are paired)
- Power graph (`connected_assembly_ids` — which assemblies are powered by which NWN)
- Online/offline status
- Owner identity (via `owner_cap_id` → `Character`)
- Extension type on gates

**What IS NOT readable without off-chain data:**
- Actual coordinates
- Solar system assignment
- Distances (except from transaction proof bytes)

### 4.3 Events — No Distance Information

| Event | Distance? | Notes |
|-------|-----------|-------|
| `GateCreatedEvent` | No | Contains `location_hash`, `type_id`, `status` |
| `JumpEvent` | No | Contains gate IDs and character — no spatial data |
| `StatusChangedEvent` | No | Online/offline transitions |
| **`GatesLinkedEvent`** | **Does not exist** | `link_gates()` emits no event |

The absence of a `GatesLinkedEvent` means passive observers must monitor **raw transaction data** rather than events to detect gate links. This raises the observation cost slightly but does not prevent it.

---

## 5. Geometry Reconstruction Feasibility

### 5.1 Theoretical Framework

The **distance geometry problem**: given a set of pairwise distances between points, reconstruct the point coordinates in $\mathbb{R}^3$.

For $N$ points in 3D space:
- **Minimum constraints for unique rigid embedding:** $3N - 6$ independent distance measurements (up to rotation, translation, reflection)
- **With $k$ known anchor points:** reduces to $3(N - k)$ required measurements
- **With exact distances (no noise):** problem is well-defined and solvable via Multidimensional Scaling (MDS) or iterative methods

### 5.2 The Same-Owner Constraint Changes Everything

**Previously assumed threat model (from original doc):** Any observer builds a growing distance graph from *all* `link_gates` transactions across all players, eventually achieving network-wide reconstruction.

**Revised threat model:** The distance graph is **fragmented into per-player subgraphs**.

| Property | Value |
|----------|-------|
| Edge source | `link_gates` transaction proof bytes |
| Edge endpoints | Two gates owned by the **same character** |
| Cross-player edges | **Structurally impossible** from gate links |
| Cross-player edges from proximity proofs | Server-gated; `distance` field likely set to 0; single-player scoped |

**Graph structure:** A collection of disconnected small cliques (one per player with linked gates), not a connected network.

### 5.3 Per-Player Subgraph Analysis

A typical player might have 2–6 gates. Gate links are pairwise. Reconstruction feasibility:

| Player gates | Max links | Distance edges | 3D reconstruction? |
|---|---|---|---|
| 2 | 1 | 1 | No — 1 edge, need 0 constraints + 1 anchor (trivial line) |
| 3 | 3 | up to 3 | Barely — determines a triangle (2D plane), not 3D |
| 4 | 6 | up to 6 | Yes if ≥ 4 links exist and points are non-coplanar. $3(4) - 6 = 6$ |
| 6 | 15 | up to 15 | Over-determined — fully solvable |

**But**: Players typically link gates in pairs (1 link per 2 gates), not all-to-all. A player with 4 gates likely has 2 links (2 distances), not 6 — insufficient for 3D reconstruction.

**And**: Even when per-player reconstruction succeeds, the result is **relative** — it reveals the spatial arrangement of that player's own gates, not their position in the universe.

### 5.4 Cross-Player Reconstruction: Structural Impossibility

For network-wide spatial mapping, an attacker needs cross-player distance edges. Available sources:

| Source | Cross-player? | Distance populated? | Exploitable? |
|--------|--------------|--------------------|-|
| `link_gates` proofs | **NO** (same-owner constraint) | Yes | N/A |
| Proximity proofs (SSU) | Self-to-structure only | Unknown (likely 0) | **NO** |
| Events | No distance in any event | N/A | N/A |
| `verify_same_location` | Hash equality only (no distance) | N/A | Binary yes/no |

**No mechanism exists to obtain cross-player distance measurements from on-chain data.**

### 5.5 Would One Known Anchor Suffice?

**No, because anchor information cannot bridge disconnected subgraphs.** An anchor point (a gate with known absolute coordinates) helps orient ONE player's subgraph in absolute space — but it cannot connect that subgraph to other players' subgraphs without cross-player distance edges.

### 5.6 Complexity Estimate

| Task | Complexity | Practical? |
|------|-----------|------------|
| Extract distances from one player's `link_gates` txs | Trivial (BCS deserialize) | Yes |
| Reconstruct one player's gate layout (relative) | Standard MDS, $O(N^3)$ for $N$ gates | Yes, if sufficient links |
| Connect two players' subgraphs | Requires cross-player distance | **No — data doesn't exist** |
| Full network reconstruction | Requires connected graph + anchors | **No — structurally impossible from gate links alone** |

**Conclusion: Graph reconstruction is INFEASIBLE for network-wide intelligence. Per-player reconstruction is theoretically possible but provides low-value information (the player already knows where their own gates are).**

---

## 6. CivilizationControl Implications

### 6.1 Can We Use Link Distances for Auto-Placement?

**Technically yes, for the user's own gates only. Practically low value.**

If a CivilizationControl user has linked their gates, we could:

1. Watch their `link_gates` transactions
2. Extract distance values from proof bytes
3. Reconstruct relative gate positions via MDS/trilateration
4. Display a "relative network map"

**Constraints:**

| Factor | Assessment |
|--------|------------|
| Requires user to have linked gates | Most users link gates in pairs (1 link = 2 gates = 1 distance = no 2D/3D layout possible) |
| Requires 4+ linked gates for 3D | Unlikely for typical players |
| Relative positioning only | No absolute coordinates without external anchor |
| Player already knows their layout | From in-game — this provides no NEW information to the user |
| Requires tx indexing + BCS deserialization pipeline | Non-trivial engineering effort |

### 6.2 Can We Infer Relative Spacing Inside a User's Network?

**Yes, if they have ≥ 3 linked gates.** A triangle of 3 mutually-linked gates yields 3 distances, which uniquely determines a 2D triangle (up to reflection). This could be displayed as a "local network map" in the CivilizationControl UI.

**But the user must link all 3 pairs** — not just a chain A→B→C (which yields only 2 distances and no triangle). Since `link_gates` requires both OwnerCaps, a player CAN link their own gates in arbitrary configurations. Whether they DO is a behavioral question.

### 6.3 Pre-Hackathon Viability Assessment

**NOT VIABLE for hackathon scope.**

Requirements for this feature:

1. Transaction indexing service (or RPC polling)
2. BCS proof deserialization library
3. MDS/trilateration solver
4. Front-end spatial visualization
5. User with ≥ 3 linked gates for meaningful display

Engineering cost: **2–3 days minimum** for a minimal implementation. This is substantial relative to hackathon constraints and yields a feature that works only for users with multiple linked gates — a small subset.

**Alternative approaches with better ROI:**

| Approach | Effort | Value |
|----------|--------|-------|
| Manual pin placement by user | Low (UI only) | Works for all users immediately |
| Game API integration (if available) | Medium | Gets actual positions, not just distances |
| `location_hash` equality for co-location | Trivial | Grouping structures by system |

### 6.4 Is It Worth Building?

**No, for hackathon. Maybe for post-launch.**

- The engineering cost does not justify the marginal UX improvement over manual placement
- The feature works only for a subset of users (those with 3+ mutually-linked gates)
- The player already knows where their gates are — we're reconstructing knowledge they already have
- Manual pin placement (from the [UX spec](../ux/civilizationcontrol-ux-architecture-spec.md)) is simpler and works universally

**Post-launch consideration:** If CivilizationControl gains traction, automatic "network map sketching" from link distances could be a polish feature. It would complement manual placement, not replace it.

---

## 7. Risk Assessment & Strategic Recommendation

### 7.1 Classification

**Harmless bounded leak.**

| Question | Answer |
|----------|--------|
| Is this a harmless bounded leak? | **YES.** Distances are exposed but only between same-player structures. The player already knows this information. |
| Is this a potential ecosystem-level intelligence exploit? | **NO.** Cross-player distance data is structurally unavailable. Network-wide reconstruction is infeasible. |
| Would public exploitation likely be patched? | **Unlikely.** CCP is aware of the plaintext distance design (evidenced by the ZK PoC repo). The current system is an intentional simplification with no cross-player privacy impact. A move to ZK proofs would address this structurally but is a future protocol upgrade, not an emergency patch. |

### 7.2 Detailed Risk Matrix

| Threat Vector | Severity | Likelihood | Impact | Net Risk |
|---|---|---|---|---|
| Same-player distance extraction from `link_gates` | Low | Certain (tx data is public) | Negligible (player knows their own layout) | **NEGLIGIBLE** |
| Cross-player distance via `link_gates` | N/A | **Impossible** (same-owner constraint) | N/A | **NONE** |
| Cross-player distance via proximity proofs | Low | Very low (server likely sets distance=0; player-to-structure only) | Low | **NEGLIGIBLE** |
| Solar system identification | Low | **Impossible** from on-chain data (no `solar_system_id` on assemblies) | N/A | **NONE** |
| Network-wide graph reconstruction | Medium (if possible) | **Impossible** (disconnected per-player subgraphs) | N/A | **NONE** |
| Coordinate recovery via trilateration | Medium (if possible) | Very low (requires per-player reconstruction + external anchor) | Per-player only; player already knows | **NEGLIGIBLE** |

### 7.3 Strategic Recommendation

**IGNORE for hackathon. Do not build distance-based features.**

Rationale:

1. **No intelligence risk:** Cross-player network reconstruction is structurally impossible from on-chain data. The same-owner constraint on `link_gates` is the key architectural firewall.
2. **No product value:** Distance-based gate placement provides no information the player doesn't already have. Manual placement is simpler and more flexible.
3. **Engineering cost is not justified:** Building a tx-indexing + BCS-deserialization + MDS pipeline for a marginal polish feature is not appropriate for hackathon scope.
4. **No reputational risk:** Using publicly available on-chain data is not an exploit — distances between a player's own gates aren't sensitive. But building intelligence features that *appear* to do network mapping could create unnecessary concern.

**If asked about location data in the demo or submission:** "Structure positions are stored as Poseidon2 hashes on-chain. CivilizationControl uses manual placement for gate visualization — no position data is extracted from chain."

---

## Appendix A: Key Code References

| Topic | File | Lines |
|-------|------|-------|
| `link_gates` dual OwnerCap requirement | [gate.move](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | L155–171 |
| `verify_distance` (no ownership check) | [location.move](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) | L147–164 |
| `verify_proximity` (ignores distance) | [location.move](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) | L99–116 |
| `LocationProofMessage` struct | [location.move](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) | L42–62 |
| `borrow_owner_cap` sender check | [character.move](../../vendor/world-contracts/contracts/world/sources/character/character.move) | L137–146 |
| `Location` struct (hash only) | [location.move](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) | L32–34 |
| `Gate` struct (no solar_system_id) | [gate.move](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | L68–79 |
| `NetworkNode` struct | [network_node.move](../../vendor/world-contracts/contracts/world/sources/network_node/network_node.move) | L64–76 |
| `Killmail` (only on-chain solar_system_id) | [killmail.move](../../vendor/world-contracts/contracts/world/sources/killmail/killmail.move) | L42–56 |
| `GateConfig` shared object init | [gate.move](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | L705–710 |
| `unlink_gates_by_admin` (admin bypass) | [gate.move](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | L580–584 |

## Appendix B: Methodology

This investigation was conducted via static analysis of `vendor/world-contracts` source code. No vendor files were modified. No devnet deployment was necessary — the findings regarding ownership constraints, object model fields, and proof validation ordering are fully deterministic from code inspection.

Specifically examined:
- All proof verification functions in `location.move`
- The complete `link_gates` and `unlink_gates` call chains in `gate.move`
- All struct definitions for Gate, Assembly, NetworkNode, StorageUnit, Location, Killmail
- The `borrow_owner_cap` authorization check in `character.move`
- Builder scaffold and ZK PoC repos for server-side proof generation patterns
- Sandbox validation scripts for empirical proof construction evidence
- Event struct definitions across all assembly modules

## Appendix C: Relationship to Original Investigation

This document builds on [location-proof-leakage-investigation.md](location-proof-leakage-investigation.md) and does **not** contradict its technical findings. The original document correctly identified:

- ✅ `distance: u64` is plaintext in every proof (confirmed, unchanged)
- ✅ `max_distance` is publicly readable from `GateConfig` (confirmed, unchanged)
- ✅ Proof bytes are permanently stored as tx input data (confirmed, unchanged)
- ✅ `verify_distance` has no deadline check (confirmed, unchanged)

This follow-up **adds** the critical ownership analysis that was outside the original scope:

- 🆕 `link_gates` requires both OwnerCaps from the same character → no cross-player edges
- 🆕 Solar system ID is absent from all assembly structs → no system-level inference
- 🆕 Proximity proofs likely have `distance=0` and are server-gated → not an oracle
- 🆕 Graph is structurally disconnected → network reconstruction infeasible

The original document's YELLOW classification was appropriate for the scope of "does leakage exist?" — this document revises to GREEN for the scope of "is leakage actionable?"
