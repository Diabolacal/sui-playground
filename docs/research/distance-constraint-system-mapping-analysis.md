# Distance-Constraint Solar System Mapping Analysis

**Retention:** Prep-only

## 1. Executive Verdict

**ORANGE — Strong solar system identification is feasible from gate link distances combined with a publicly available star coordinate database.**

A single cross-system `link_gates` transaction exposes an exact `distance: u64` value (in meters). With access to a high-precision 3D coordinate database of all ~24,000 solar systems (e.g., EF-Map data), an observer can match that scalar distance against the ~288 million pairwise inter-system distances. Due to the astronomical precision (integer meters across inter-stellar scales), **each distance value is statistically unique**, typically narrowing to a small candidate set. Filtering by gate-type max range (55 ly for standard, 110 ly for large gates) further reduces the search space.

With two or more links sharing a gate — the normal topology for chain-linked player networks — intersection collapses candidates to near-certainty.

This finding upgrades the prior actionability assessment for a specific sub-threat: **system-level identification of a player's gate locations**. The prior reports correctly noted that:
- Cross-player graph reconstruction is infeasible (same-owner constraint — unchanged)
- Network-wide topology mapping is structurally impossible (unchanged)

This analysis adds a NEW finding: **per-player solar system identification is feasible** from the player's own gate link transactions, using only publicly available data. The same-owner constraint does NOT protect against this vector because the attacker doesn't need cross-player edges — they need only match scalar distances to a known coordinate database.

Additionally, this data is **historically queryable** — an observer does not need to monitor transactions in real time. All `link_gates` transaction inputs (including the plaintext distance) are permanently recorded on-chain and retrievable via standard Sui RPC or GraphQL queries after the fact.

| Threat | Prior Assessment | This Analysis | Reason |
|--------|-----------------|---------------|--------|
| Cross-player graph reconstruction | GREEN | GREEN (unchanged) | Same-owner constraint prevents cross-player edges |
| Network-wide topology | GREEN | GREEN (unchanged) | Disconnected per-player subgraphs |
| **Solar system pair identification** | GREEN (implicit) | **ORANGE** | Distance matching against star database yields near-unique results |
| Proximity proof oracle | GREEN | GREEN (confirmed) | Server-gated, self-scoped, likely distance=0 |

**Practical impact:** An observer can determine which specific solar systems a player has gates in by querying their `link_gates` transactions (live or historical). This is competitive intelligence — knowing where a player operates. The player already knows their own locations, but **their opponents do not**, and this vector exposes that information.

---

## 2. Distance Metric Equivalence

### 2.1 Production System: `distance: u64` in `LocationProofMessage`

**Source:** [location.move](../../vendor/world-contracts/contracts/world/sources/primitives/location.move#L57) — `distance: u64` field in `LocationProofMessage`.

The production world-contracts system uses a server-signed `LocationProofMessage` containing a `distance: u64` field. The on-chain contract does NOT compute distance — it merely validates `message.distance <= max_distance` in [`verify_distance()`](../../vendor/world-contracts/contracts/world/sources/primitives/location.move#L154-L170). The server computes and signs the actual distance value.

### 2.2 Unit Determination: Meters (Strong Evidence)

From [env.example](../../vendor/world-contracts/env.example#L51-L52):

```
GATE_TYPE_IDS=88086,84955
MAX_DISTANCES=520340175991902420,1040680351983804840
```

Comparison against light-year conversions (1 ly = 9,460,730,472,580,800 m per IAU definition):

| Gate Type | `max_distance` | Computed ly equivalent | Nearest round ly | Deviation |
|-----------|---------------|----------------------|------------------|-----------|
| 88086 | 520,340,175,991,902,420 | 55.0000 ly | 55 ly | ~42 km (~0.00000003%) |
| 84955 | 1,040,680,351,983,804,840 | 110.0000 ly | 110 ly | ~83 km (~0.00000002%) |

**Calculation:**
- $55 \times 9{,}460{,}730{,}472{,}580{,}800 = 520{,}340{,}175{,}991{,}944{,}000$
- Config value: $520{,}340{,}175{,}991{,}902{,}420$
- $\Delta = 41{,}580 \text{ m} \approx 42 \text{ km}$

The ~42 km deviation from a round 55 ly likely reflects: (a) gate threshold computed from actual coordinate boundaries rather than round ly values, or (b) minor floating-point rounding in the original threshold calculation.

**Conclusion: The `distance: u64` unit is meters with extremely high confidence.** The match to integer light-year conversions is within 0.00000003% — this cannot be coincidental.

### 2.3 Not Squared Distance

The squared distance hypothesis can be eliminated by range analysis:

- $55 \text{ ly} = 5.20 \times 10^{17} \text{ m}$
- $(5.20 \times 10^{17})^2 = 2.71 \times 10^{35}$
- $\text{u64 max} = 2^{64} - 1 = 1.84 \times 10^{19}$

Squared meter distances at inter-system scale would overflow `u64` by 16 orders of magnitude. The production `distance: u64` **must** be linear, not squared.

### 2.4 ZK PoC Comparison (Different System)

The [ZK PoC distance-attestation circuit](../../vendor/eve-frontier-proximity-zk-poc/src/on-chain/circuits/distance-attestation/distance-attestation.circom) uses a fundamentally different metric:

```
// Manhattan Distance = |x1 - x2| + |y1 - y2| + |z1 - z2|
// Distance Squared = (Manhattan Distance)²
distanceSquared === distanceSquaredMeters;
```

This is **squared Manhattan distance**, not Euclidean — and is a completely separate proof system (Groth16-based) from the production Ed25519-signed system. The ZK PoC is an experimental future replacement; it uses different data structures (`DistanceAttestationPublicData` with `distance_squared_meters: u64`) and different on-chain verification ([`distance_attestation.move`](../../vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move)).

**The ZK PoC is NOT relevant to the production distance leakage analysis.** If deployed, it would actually IMPROVE the situation by hiding the raw distance behind a ZK proof — the public input `distanceSquaredMeters` could be replaced with a range proof circuit.

### 2.5 Distance Metric Summary

| Property | Production System | ZK PoC (Future) |
|----------|------------------|-----------------|
| **Metric** | Linear (Euclidean assumed) | Squared Manhattan |
| **Unit** | Meters | Meters (squared) |
| **Computed by** | Server (off-chain) | ZK circuit (prover) |
| **On-chain verification** | `distance <= max_distance` | Groth16 proof verification |
| **Publicly visible** | Yes (plaintext in proof bytes) | Yes (public input) |
| **Truncation** | Integer (u64) | Integer (u64) |
| **Tolerance band** | ±0.5 m (from integer truncation) | ±0.5 m² (from truncation) |

### 2.6 Coordinate Space Equivalence

The `LocationAttestationData` type in the ZK PoC ([locationType.ts](../../vendor/eve-frontier-proximity-zk-poc/src/shared/types/locationType.ts#L12-L19)) includes:

```typescript
coordinates: SolarSystemCoords;  // { x: number, y: number, z: number }
solarSystem: number;             // solar system ID
```

The `coordinatesHash` is computed as `Poseidon4(x, y, z, salt)` where `x`, `y`, `z` are direct coordinate values and `salt` is a 32-byte random value for brute-force protection.

**EF-Map data provides solar system XYZ coordinates** in what appears to be the same coordinate space. If the EF-Map coordinates use the same origin and unit (meters) as the game server, then:

$$D_{\text{computed}} = \sqrt{(x_1 - x_2)^2 + (y_1 - y_2)^2 + (z_1 - z_2)^2}$$

would match the on-chain `distance: u64` to within the gate's intra-system offset.

**Hinge variable status:** The unit equivalence between on-chain distance and EF-Map coordinates is **resolved with high confidence** — both use meters. The remaining uncertainty is whether the distance metric is Euclidean or some other linear metric. Euclidean is the overwhelmingly likely choice, and the max_distance matching confirms a linear (not squared) quantity.

---

## 3. Candidate Enumeration Feasibility

### 3.1 Universe Parameters

| Parameter | Estimated Value | Source |
|-----------|----------------|--------|
| Number of solar systems ($N$) | ~24,000 | EVE Frontier universe size (updated estimate) |
| Number of system pairs | $\binom{N}{2} \approx 288{,}000{,}000$ | Combinatorial |
| Standard gate max range | 55 ly ($5.20 \times 10^{17}$ m) | [env.example](../../vendor/world-contracts/env.example#L51-L52) `max_distance` |
| Large gate max range | 110 ly ($1.04 \times 10^{18}$ m) | Same source |
| Distance precision | 1 meter (integer u64) | From data type |
| Possible distance values (within 55 ly) | $\sim 5.2 \times 10^{17}$ | Continuous range, integer samples |

### 3.2 Max-Range Bounding

A critical constraint: each gate type has a maximum link range. Observed distances from `link_gates` transactions are bounded:

- **Standard gates (type 88086):** $D \leq 55$ ly
- **Large gates (type 84955):** $D \leq 110$ ly

This means the observer need only search system pairs whose inter-system distance is within the relevant gate type's max range (plus an intra-system offset tolerance). Pairs beyond this range are immediately excluded.

**Search space reduction:** The exact reduction depends on the spatial extent and geometry of the EVE Frontier universe. In a universe where the diameter significantly exceeds the max gate range — expected for a universe with ~24,000 systems — the reduction is substantial. If the universe spans ~200–300 ly, a 55 ly max range excludes the vast majority of the ~288M total system pairs, potentially reducing the candidate pool by 5–20×.

Let $k_R$ denote the number of system pairs within range $R$:

| Gate Type | Max Range $R$ | Estimated $k_R$ (fraction of 288M) | Notes |
|-----------|--------------|-------------------------------------|-------|
| Standard (55 ly) | 55 ly | ~15–40% of 288M → ~43–115M pairs | Depends on universe extent |
| Large (110 ly) | 110 ly | ~40–80% of 288M → ~115–230M pairs | Larger fraction but still bounded |

Even without precise universe geometry, **filtering by max range meaningfully reduces the search space** and should always be applied.

### 3.3 Distance Uniqueness Analysis (Birthday Paradox)

The key question: **Given ~288 million pairwise distances drawn from ~$5 \times 10^{17}$ possible integer values (at 55 ly scale), how many collisions (duplicate distances) exist?**

For $k$ items drawn uniformly from a space of size $n$:

$$E[\text{collisions}] = \frac{k(k-1)}{2n}$$

**Unbounded (all pairs):** With $k = 2.88 \times 10^8$ and $n = 10^{18}$:

$$E = \frac{(2.88 \times 10^8)^2}{2 \times 10^{18}} = \frac{8.29 \times 10^{16}}{2 \times 10^{18}} \approx 0.041$$

**Bounded (standard gate, 55 ly):** With $k_R \approx 7 \times 10^7$ (mid-estimate) and $n = 5.2 \times 10^{17}$:

$$E = \frac{(7 \times 10^7)^2}{2 \times 5.2 \times 10^{17}} \approx 0.0047$$

Expected collisions: **< 0.05 in either case.** Even with 3× more systems than previously assumed, virtually every pairwise distance remains unique at integer-meter precision.

### 3.4 Single Link Observation

Given one observed distance $D$ from a `link_gates` transaction, the expected number of matching system pairs within tolerance $\pm\Delta$:

$$E[\text{matches}] = k_R \times \frac{2\Delta}{D_{\max}}$$

Where $k_R$ is the number of in-range candidate pairs and $D_{\max}$ is the max range for the gate type.

**Conservative baseline (all 288M pairs, full range):**

| Tolerance ($\Delta$) | Physical meaning | $E[\text{matches}]$ (all pairs) |
|-----------|-----------------|---------------------|
| 1 m | Integer truncation | $5.8 \times 10^{-10}$ |
| 1 km | | $5.8 \times 10^{-7}$ |
| 1 AU ($1.5 \times 10^{11}$ m) | | $0.086$ |
| 10 AU | Typical intra-system offset | $0.86$ |
| 50 AU ($7.5 \times 10^{12}$ m) | System radius | $4.3$ |
| 100 AU ($1.5 \times 10^{13}$ m) | Worst-case gate offset | $8.6$ |
| 1 ly ($9.46 \times 10^{15}$ m) | | $5{,}450$ |

**With max-range filtering (standard gate, ~70M in-range pairs):**

| Tolerance ($\Delta$) | $E[\text{matches}]$ (bounded) |
|-----------|-------------------------------|
| 10 AU | $0.40$ |
| 50 AU | $2.0$ |
| 100 AU | $4.0$ |

**Key takeaway:** At ±10 AU tolerance (typical gate placement offset), a single link yields a unique or near-unique system pair even with 24,000 systems. At ±100 AU (worst-case), the candidate set grows to ~4–9 pairs, requiring a second observation to disambiguate.

### 3.5 Intra-System Position Offset

Gates are NOT at solar system centers. A gate's position within its system introduces an offset between the gate-to-gate distance and the system-center-to-system-center distance:

$$|D_{\text{gate-to-gate}} - D_{\text{system-to-system}}| \leq \delta_{\text{source}} + \delta_{\text{dest}}$$

Where $\delta$ is each gate's displacement from its system center.

- **Typical offset:** ~10 AU per gate, so ~20 AU combined. Based on gameplay patterns where gates are placed near stations or stargates within the inner system.
- **Worst-case offset:** ~50 AU per gate, so ~100 AU combined. Represents gates placed at extreme positions within a large solar system.

| Tolerance assumption | Combined offset | $E[\text{matches}]$ (bounded, std gate) | Assessment |
|---------------------|----------------|----------------------------------------|------------|
| Typical (±20 AU) | 20 AU | ~0.8 | Near-unique; 1 candidate |
| Conservative (±50 AU) | 50 AU | ~2.0 | 1–3 candidates |
| Worst-case (±100 AU) | 100 AU | ~4.0 | 2–6 candidates |

The tolerance band is the dominant factor in match quality. Tighter tolerances (justified by typical gate placement) yield dramatically better candidate reduction.

### 3.6 Same-System Links

If both gates are in the same solar system, the distance is:
- Magnitude: $\sim 10^{10}$ to $\sim 10^{13}$ m (sub-AU to a few AU)
- No inter-system pair at inter-stellar distances matches this range

Same-system links **do not leak inter-system information** but DO confirm the gates are co-located (same system). However, in practice players do not link gates within the same system (see §3A — Network Shape in Practice).

### 3.7 Multi-Link Narrowing

**Scenario: Player links A↔B and B↔C (two links sharing system B)**

1. **Link A↔B** with distance $D_1$: Enumerate candidate system pairs → typically 1–4 candidates
2. **Link B↔C** with distance $D_2$: Enumerate candidate system pairs → typically 1–4 candidates
3. **Intersection on B**: System B must appear in BOTH candidate sets → typically **1 candidate**

With $n_1$ candidates for A-B and $n_2$ candidates for B-C, the probability of a false intersection (random overlap from different systems):

$$P(\text{false match}) \approx \frac{n_1 \cdot n_2}{N}$$

For $n_1 = n_2 = 4$ (worst-case tolerance) and $N = 24{,}000$: $P = \frac{16}{24{,}000} = 0.067\%$.

**Unique identification via intersection: >99.9% probability** even at worst-case tolerances and with the corrected 24,000-system universe.

**Three or more links converge to certainty.**

### 3.8 Candidate Count Estimates (Revised)

| Observations | Typical candidates | Confidence | Notes |
|--------------|-------------------|------------|-------|
| 1 cross-system link (±20 AU) | 1 system pair | ~70% unique | Typical placement tolerance |
| 1 cross-system link (±100 AU) | 2–6 system pairs | ~20% unique alone | Worst-case tolerance |
| 2 links sharing a gate | 1 system for shared gate | >99.9% unique | Intersection resolves B |
| 3+ links (connected chain) | All systems identified | ~100% | Over-determined |
| Same-system link only | 0 inter-system candidates | N/A | Confirms co-location only |

---

## 3A. Network Shape in Practice

### 3A.1 Single-Link-per-Gate Constraint

Each gate object has a single `linked_gate_id: Option<ID>` field — not a vector — meaning a gate can be linked to **at most one** other gate at any time. The `link_gates` function enforces that both the source and destination gates must be unlinked before a new link can be created:

```move
assert!(
    option::is_none(&source_gate.linked_gate_id) &&
    option::is_none(&destination_gate.linked_gate_id),
    EGatesAlreadyLinked,
);
```

Source: [gate.move](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — `Gate` struct (L71–82), `link_gates` assertion (L181–185).

Links are **bidirectional**: `link_gates` sets `linked_gate_id` on both the source and destination gate objects symmetrically. Unlinking clears both sides.

### 3A.2 Pair-Link Chains

Because each gate links to exactly one other, player gate networks form **linear chains**, not arbitrary topologies:

```
System A          System B          System C          System D
[Gate A1] ←————→ [Gate B1]  [Gate B2] ←————→ [Gate C1]  [Gate C2] ←————→ [Gate D1]
```

- **Intermediate systems** (B, C) typically have **two gates**: one linked "backward" to the previous system, one linked "forward" to the next.
- **Endpoints** (A, D) have a single gate with one link.
- The chain can only be extended by deploying a new gate in the next system and linking it.

This is NOT a hub-and-spoke or mesh topology. A player cannot link one gate to multiple destinations simultaneously.

### 3A.3 Cross-System Links Only (Practical Constraint)

The on-chain contract has **no explicit prohibition** against linking two gates in the same solar system — the only check is `distance <= max_distance` via a server-signed proof. However, in practice:

- Players gain no travel utility from same-system links (the purpose of gate links is inter-system transit).
- The game server would need to sign a distance proof for two structures in the same system — the distance would be very small (sub-AU to tens of AU), which the server might reject or which would be operationally pointless.
- No known gameplay documentation or community practice describes same-system gate linking.

**For modeling purposes, treat all gate links as cross-system.** If a same-system link were observed, the very small distance (~10^10 to ~10^13 m) would be immediately distinguishable from inter-stellar distances and would confirm co-location without ambiguity.

### 3A.4 Impact on Intersection Logic

The chain topology creates a powerful narrowing pattern. Consider a 4-system chain:

| Link | Observed Distance | Candidate System Pairs |
|------|------------------|----------------------|
| A↔B | $D_1$ | {(S₁, S₂), (S₃, S₄)} |
| B↔C | $D_2$ | {(S₂, S₅), (S₆, S₇)} |
| C↔D | $D_3$ | {(S₅, S₈)} |

**Intersection on shared systems:**
1. Link 1 and Link 2 share system B → B must appear in both candidate sets → resolves to $S_2$
2. With B = $S_2$, Link 1 resolves A = $S_1$ and Link 2 resolves C = $S_5$
3. Link 3 confirms C = $S_5$ and resolves D = $S_8$

Each additional link in the chain:
- Adds one new system to identify
- Provides one additional distance constraint
- Creates a shared-system intersection with the previous link

**The chain never diverges.** A player's full gate network is a single path (possibly with branches if they have multiple gates in one system linking to different destinations), and every consecutive link pair constrains the intermediate system.

---

## 3B. Data Collection & Observability

### 3B.1 Core Finding: Historical Retrieval Is Fully Supported

An observer does **NOT** need to monitor `link_gates` transactions in real time. All transaction inputs — including the `distance_proof` bytes containing the plaintext `distance: u64` — are permanently stored on-chain and retrievable via standard Sui RPC methods after the fact.

**The observability question has two parts:**
1. **Is exposure possible at all?** → Yes. Transaction inputs are public on-chain data.
2. **Must you watch live to capture the data?** → No. Historical queries work. Live monitoring is only needed for *timely* collection, not for *possibility*.

### 3B.2 What Is Visible in a `link_gates` Transaction

When retrieved with `showInput: true`, a `link_gates` transaction exposes:

| Data | Visibility | Notes |
|------|-----------|-------|
| Source gate object ID | Visible | Object input in PTB |
| Destination gate object ID | Visible | Object input in PTB |
| Character object ID | Visible | Object input |
| `distance_proof` bytes (BCS-encoded) | **Fully visible** | Pure value argument |
| Sender address (player) | Visible | Transaction sender |
| Gas sponsor (if sponsored) | Visible | Transaction gas owner |
| Transaction timestamp | Visible | Checkpoint timestamp |

The `distance_proof` is a BCS-encoded `LocationProofMessage` + signature containing:

| Field | Type | Extractable? |
|-------|------|-------------|
| `server_address` | `address` | Yes |
| `player_address` | `address` | Yes |
| `source_structure_id` | `ID` | Yes |
| `source_location_hash` | `vector<u8>` | Yes (opaque 32-byte hash) |
| `target_structure_id` | `ID` | Yes |
| `target_location_hash` | `vector<u8>` | Yes (opaque 32-byte hash) |
| **`distance`** | **`u64`** | **Yes — plaintext gate-to-gate distance in meters** |
| `deadline_ms` | `u64` | Yes (proof expiry) |
| `signature` | `vector<u8>` | Yes (server Ed25519 signature) |

**Note:** `link_gates` does NOT emit an event. Detection requires querying transactions by function call or object mutation, not event filtering.

### 3B.3 Practical Collection Approaches

#### Ad Hoc Historical Query (given a player address or gate ID)

Minimal approach for targeted investigation:

1. Query `sui_queryTransactionBlocks` with filter `{ FromAddress: "<player_address>" }` or `{ ChangedObject: "<gate_object_id>" }`
2. Fetch full transaction with `sui_getTransactionBlock({ showInput: true })`
3. Filter for PTB commands targeting `<package>::gate::link_gates`
4. Extract the `distance_proof` pure argument and BCS-decode the `distance: u64`

**Alternatively**, use the `MoveFunction` filter to find ALL `link_gates` transactions across all players:

```
sui_queryTransactionBlocks({
  filter: { MoveFunction: { package: "0x...", module: "gate", function: "link_gates" } }
})
```

This approach works at any time — hours, days, or months after the transaction occurred — given that the node retains historical data (archival nodes, or Sui's standard full node with indexer enabled).

#### Continuous Indexer (for broad surveillance)

For comprehensive coverage:

1. Run a custom indexer subscribing to the Sui checkpoint stream (using `sui-data-ingestion` framework or equivalent)
2. Filter for transactions containing `MoveCall` to `gate::link_gates`
3. BCS-decode `distance_proof` from each match
4. Store in a database keyed by (source_gate, destination_gate, player, timestamp, distance)

Since `link_gates` emits no event, the indexer must inspect transaction inputs (not events).

#### GraphQL API (recommended for moderate-scale queries)

Sui's hosted GraphQL endpoint supports filtering by function, sender, and affected object with cursor-based pagination. This requires no infrastructure to maintain.

### 3B.4 Data Retention Caveat

Full nodes may prune old transaction data depending on configuration. For guaranteed long-term historical access:
- Use archival full nodes
- Run a Sui full node with `--indexer` flag (maintains PostgreSQL database)
- Or maintain a custom indexer that captures data at ingestion time

**Bottom line:** An attacker needs no special access or timing. Standard blockchain transparency guarantees apply — all `link_gates` inputs are public, permanent (on archival nodes), and trivially queryable.

---

## 4. Proximity Oracle Viability

### 4.1 Can Proximity Proofs Act as a Distance Oracle?

**NO — constrained by server policy, proof structure, and game mechanics.**

| Constraint | Evidence |
|------------|----------|
| `verify_proximity` ignores `distance` field | [location.move L99-116](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) — no distance check |
| Server likely sets `distance: 0` for proximity proofs | Sandbox scripts always use `--distance 0` ([generate_distance_proof.mjs L95](../../sandbox/validation/generate_distance_proof.mjs)); no reason for server to compute it |
| Proofs are self-scoped | `player_address == ctx.sender()` check; proof must be addressed to the requesting player |
| Server controls issuance | No API to request arbitrary structure-pair distances; proofs issued for gameplay interactions only |
| Proximity proofs used only for SSU operations | `deposit_by_owner`, `withdraw_by_owner`, `burn_items_with_proof` |

### 4.2 Trilateration via Repeated Proximity Proofs

**Scenario:** Player in System A requests proximity proof to SSU X (distance $D_1$), then moves to System B and repeats (distance $D_2$).

**This is NOT practical because:**

1. **Server likely sets `distance: 0`** — the field is structurally ignored by on-chain verification, so there is no incentive to compute real distances for proximity proofs
2. **Proximity proofs are issued for nearby structures** — the server would not issue a proximity proof for a structure in a distant system (the player is not "in proximity")
3. **Even if distance were populated:** proximity proofs prove "player is near structure X," not "structure X is at distance D from structure Y." The player already knows their own position
4. **Server can deny requests** — proof issuance is discretionary; arbitrary probing would be rate-limited or rejected

### 4.3 What If Distance IS Populated in Proximity Proofs?

Even in the worst case where the server truthfully populates `distance` for proximity proofs:

- The proof bytes are publicly observable in SSU transaction data
- Each SSU interaction reveals the player's distance to the SSU
- With the player's system known, this could narrow the SSU's system

**However:** This requires the player to interact with SSUs in different systems and collect multiple distances. This is a behavioral constraint — it requires active movement and interaction, not passive observation.

**Exploitability: NEGLIGIBLE.** Server-gated, use-case-restricted, single-player-scoped, and behaviorally constrained.

---

## 5. Same-Location Reconfirmation (Thread 4)

**Confirmed: `verify_same_location` provides ZERO distance information.**

```move
public fun verify_same_location(location_a_hash: vector<u8>, location_b_hash: vector<u8>) {
    assert!(location_a_hash == location_b_hash, ENotInProximity);
}
```

Source: [location.move L180-182](../../vendor/world-contracts/contracts/world/sources/primitives/location.move#L180-L182)

- Pure hash equality check (Poseidon2 hash comparison)
- No distance field present
- No range-based inference possible
- Binary yes/no: either same location or not
- Does not receive a proof payload — operates directly on stored `location_hash` values

**No information leakage beyond co-location.**

---

## 6. Practical Solar System Narrowing Model (Thread 5)

### 6.1 Scenario Setup

Player links:
- **A ↔ B**: Distance $D_1 = 2.37 \times 10^{17}$ m (~25 ly)
- **B ↔ C**: Distance $D_2 = 4.73 \times 10^{17}$ m (~50 ly)

All transactions are publicly observable on-chain. An observer has access to the EF-Map solar system coordinate database.

### 6.2 Step 1: Compute Candidate Set for A-B

The observer precomputes all pairwise distances between the ~24,000 systems in the database (or, more efficiently, only those within 55 ly of each other for standard gates). They search for pairs $(S_i, S_j)$ where:

$$|D_{\text{system}}(S_i, S_j) - D_1| \leq \Delta$$

Using ±20 AU (typical tolerance), **expected result:** 0–1 candidate pairs.
Using ±100 AU (worst-case tolerance), **expected result:** 2–6 candidate pairs.

Assume result (±50 AU): {(System 1294, System 5821), (System 3102, System 7744), (System 6010, System 9231)}

### 6.3 Step 2: Compute Candidate Set for B-C

Same procedure with $D_2$:

**Expected result:** 1–4 candidate pairs (at ±50 AU tolerance).

Assume result: {(System 5821, System 2087), (System 5821, System 4415)}

### 6.4 Step 3: Intersection on Shared System B

Gate B's system must appear in BOTH candidate sets. Because gate networks are chains (§3A), the system hosting gate B appears in both the A-B and B-C candidate pairs.

- A-B candidate systems (B-side): {5821, 7744, 9231}
- B-C candidate systems (B-side): {5821}

**Intersection:** System 5821 is the ONLY system appearing in both sets.

**Result:**
- System B → **System 5821** (certain)
- System A → **System 1294** (from A-B pair containing 5821)
- System C → one of {2087, 4415} — further narrowed by a third link C↔D if available

### 6.5 Chain Topology Advantage

In the pair-link chain model (§3A), each consecutive link pair shares exactly one system. This means:

- A chain of $n$ links provides $n-1$ intersection opportunities
- Each intersection independently resolves one intermediate system
- The endpoints are resolved as a side-effect of their neighboring intersection

**Example: A 5-system chain (A↔B↔C↔D↔E) with 4 links:**

| Step | Links Used | Intersection On | Resolves |
|------|-----------|----------------|----------|
| 1 | A↔B, B↔C | System B | A, B, C |
| 2 | B↔C, C↔D | System C | C confirmed, D |
| 3 | C↔D, D↔E | System D | D confirmed, E |

After processing the chain, all 5 systems are identified with near-certainty.

### 6.6 Collapse Rate Assessment

| Topology | Links | Expected unique identification | Notes |
|----------|-------|-------------------------------|-------|
| A↔B (isolated, ±20 AU) | 1 | ~70% (0–1 candidates) | Typical tolerance |
| A↔B (isolated, ±100 AU) | 1 | ~20% unique (2–6 candidates) | Worst-case tolerance |
| A↔B, B↔C (chain) | 2 | >99.9% (intersection resolves B) | N=24,000 makes false overlap 0.07% |
| A↔B↔C↔D (chain) | 3 | ~100% (all systems resolved) | Over-determined |
| A↔B (same-system) | 1 | 0% inter-system info | Confirms co-location only |

### 6.7 Symmetry and Ambiguity

**Does the symmetry of the universe create ambiguity?**

In principle, a perfectly symmetric crystal-lattice universe would have many distance collisions. In practice, EVE's solar system distribution is:
- Irregularly distributed in 3D (not a lattice)
- Clustered into regions, constellations, and "pipes"
- Based on (or analogous to) real astronomical catalogs

The irregular distribution means that at meter precision, distance collisions are extremely rare. Even with ~24,000 systems and ~288M pairs, the birthday arithmetic applies: ~288M pairs across ~$5 \times 10^{17}$ possible values (within 55 ly) yields expected collisions of ~0.04. **Virtually zero.**

**What if the universe is more compact than assumed?**

If the universe diameter is closer to 100 ly (making 55 ly cover most pairs), the max-range bounding provides less reduction, but the birthday math still holds — fewer distinct pairs in a given distance band means the same or better uniqueness.

If $N$ is significantly smaller (e.g., 500 systems): $\binom{500}{2} = 124{,}750$ pairs — even fewer candidates per distance observation. Uniqueness improves.

**Conclusion: Universe symmetry does NOT create meaningful ambiguity at integer-meter precision.** The corrected universe size (24,000 systems) increases pair count by ~9× compared to the prior 8,000-system estimate, but distance uniqueness remains overwhelming.

---

## 7. Final Risk Classification

### 7.1 Classification: ORANGE — Retained Under Corrected Assumptions

The ORANGE classification is **unchanged** after incorporating the corrected universe size (24,000 systems) and refined mechanics. The larger universe increases pair counts by ~9× but does not meaningfully degrade the attack — distance uniqueness remains overwhelming, and the larger system count actually *improves* intersection-based narrowing (lower false-overlap probability).

| Classification Element | Assessment |
|----------------------|------------|
| **Can we enumerate candidates?** | YES — even with 288M pairs, distances are near-unique at meter precision |
| **Does max-range bounding help the attacker?** | YES — filtering to ≤55 ly (standard) or ≤110 ly (large) reduces search space by up to 5–20× |
| **Can multiple links narrow further?** | YES — chain intersection on shared systems collapses to certainty (>99.9%) |
| **Must the attacker watch live?** | NO — historical queries via standard Sui RPC retrieve all inputs after the fact |
| **Is the attack practical?** | YES — requires only RPC access + public star database |
| **What does it reveal?** | Specific solar systems where a player has gates |
| **Who is affected?** | The player whose `link_gates` transactions are observed |
| **Is it actionable intelligence?** | YES — knowing a player's operational systems is valuable in EVE |
| **Is cross-player mapping possible?** | NO — same-owner constraint prevents this (unchanged) |

### 7.2 Why ORANGE and Not RED

The classification stops at ORANGE rather than RED because:

1. **Unit confirmation is inferential, not proven.** While the evidence strongly indicates meters, we cannot inspect the production server's distance computation function. An unknown scaling factor or coordinate transform could change the analysis.

2. **Metric uncertainty.** We assume Euclidean distance but can't confirm. If the server uses Manhattan distance, geodesic distance, or a custom metric, the pairwise distance computation would differ. However, most metrics for 3D point distances are nearly equivalent at the precision that matters.

3. **EF-Map coordinate fidelity.** If the EF-Map coordinates differ from the server's internal coordinates (different origin, axis orientation, or precision), a calibration step is required. This is solvable with 1-2 known reference links but adds operational complexity.

4. **Intra-system offset varies.** The tolerance band (±10–100 AU) directly controls candidate count. With worst-case ±100 AU, single-link identification yields 2–6 candidates (at N=24,000), requiring multi-link intersection. With typical ±20 AU, single-link identification is usually unique. The attacker's confidence depends on which tolerance applies.

5. **Same-owner constraint limits scope.** This is per-player self-leakage — the player's OWN system locations are exposed, not other players'. The attacker gains competitive intelligence, not universal surveillance.

6. **No confirmed exploit in the wild.** The attack is theoretically sound and practical to implement, but we have no evidence it has been deployed. The tooling (coordinate database + BCS decoder + RPC queries) requires moderate engineering effort.

### 7.3 Why Not YELLOW or GREEN

The classification cannot be YELLOW because:

1. **Matching is mathematically near-certain.** With ~$5 \times 10^{17}$ possible values (within 55 ly) and ~288M pairs, expected collisions are ~0.04 across the entire universe. Even with 3× the previously assumed system count, virtually every distance remains unique. This isn't "moderate candidate reduction" — it's near-deterministic.

2. **No cryptographic barrier.** The distance value is plaintext in the BCS-encoded proof bytes. The star database is public. The matching computation is trivial. Historical transaction data is permanently available via standard RPC.

3. **Practical adversary model exists.** A competitive player or intelligence service monitoring the blockchain can build this system with minimal engineering effort: one RPC endpoint + one coordinate database + one distance comparison script + one BCS decoder.

### 7.4 Comparison to Prior Assessments

| Document | Threat | Classification | This Analysis |
|----------|--------|---------------|---------------|
| [Leakage investigation](location-proof-leakage-investigation.md) | Distance leakage (general) | YELLOW | Confirmed; leakage exists |
| [Actionability analysis](location-proof-actionability-analysis.md) | Cross-player graph | GREEN | Confirmed; structurally impossible |
| [Actionability analysis](location-proof-actionability-analysis.md) | Solar system inference | GREEN | **UPGRADED to ORANGE** — distance matching against star DB not previously modeled |
| **This document** | Per-player system identification | **ORANGE** | NEW finding |

The prior GREEN for "solar system inference" was based on the observation that assemblies have no `solar_system_id` field and no on-chain coordinate-to-system mapping exists. **This remains true.** The NEW attack vector is: the observer doesn't need an on-chain mapping — they use an OFF-CHAIN star coordinate database to match observed distances to known inter-system distances.

---

## 8. CivilizationControl Implications

### 8.1 Defensive Posture

CivilizationControl should treat gate link distances as **system-identifying information** for the linker. When displaying gate link information or building features around gate topology:

- Do NOT emphasize or make easily extractable the raw distance values
- If a "sovereignty map" feature is built, be aware that the underlying distance data could reveal system locations to observers
- Consider whether CivilizationControl's own data aggregation could become a distance oracle for third parties

### 8.2 Product Feature Considerations

| Feature | Risk | Recommendation |
|---------|------|----------------|
| Gate link distance display | Low (player knows own distances) | OK for self-view; do NOT show other players' distances |
| "Network map" from distances | Medium (accelerates system identification) | Defer to post-hackathon; use manual placement instead |
| Distance-based analytics | Medium (aggregation creates queryable oracle) | Avoid aggregating cross-player distances |
| System identification warnings | Low (informational) | Consider alerting users that linking gates exposes their system pair |

### 8.3 Hackathon Relevance

**For hackathon: IGNORE.** This is an academic finding that does not change the product scope.

- CivilizationControl does not need to build countermeasures against distance-based system identification
- The finding is relevant to protocol-level design (CCP's domain), not application-level features
- No engineering work is recommended for hackathon based on this analysis

### 8.4 Long-Term Protocol Recommendation

The structurally sound fix is the one CCP is already exploring in the ZK PoC: replace plaintext distance values with zero-knowledge proofs that attest `distance <= max_distance` without revealing the actual value. The ZK PoC's `distance_attestation.circom` circuit already implements this pattern, though it currently uses Manhattan distance rather than Euclidean.

---

## Appendix A: Mathematical Derivations

### Birthday Paradox for Distance Collisions

For $k$ pairwise distances with each distance drawn from $[0, n)$, the expected number of collisions is:

$$E[\text{collisions}] = \binom{k}{2} \cdot \frac{1}{n} = \frac{k(k-1)}{2n}$$

**With N=24,000 systems (corrected from prior N=8,000):**

$k = \binom{24{,}000}{2} = 287{,}988{,}000 \approx 2.88 \times 10^8$

**Unbounded (full distance range $n = 10^{18}$):**

$$E = \frac{(2.88 \times 10^8)^2}{2 \times 10^{18}} = \frac{8.29 \times 10^{16}}{2 \times 10^{18}} \approx 0.041$$

**Bounded (within 55 ly, $n = 5.2 \times 10^{17}$, $k_R \approx 7 \times 10^7$):**

$$E = \frac{(7 \times 10^7)^2}{2 \times 5.2 \times 10^{17}} \approx 0.0047$$

Expected collisions: **< 0.05 in all cases.** Virtually zero, even with 9× more pairs than the prior estimate.

**Comparison to prior N=8,000 estimate:**

| Parameter | N=8,000 (prior) | N=24,000 (corrected) | Change |
|-----------|-----------------|---------------------|--------|
| Total pairs $k$ | $3.2 \times 10^7$ | $2.88 \times 10^8$ | 9× |
| $E[\text{collisions}]$ | $5.1 \times 10^{-4}$ | $4.1 \times 10^{-2}$ | 80× (still ~0) |
| Uniqueness | >99.9% | >96% | Marginal degradation |

### Tolerance-Band Expected Matches

For a query distance $D$ with tolerance $\pm \Delta$, the expected number of matching pairs:

$$E[\text{matches}] = k \cdot \frac{2\Delta}{D_{\max}}$$

**All pairs, full range ($k = 2.88 \times 10^8$, $D_{\max} = 10^{18}$):**

| $\Delta$ | Physical meaning | $E[\text{matches}]$ |
|-----------|-----------------|---------------------|
| 1 m | Integer truncation | $5.76 \times 10^{-10}$ |
| 1 km | | $5.76 \times 10^{-7}$ |
| 1 AU ($1.5 \times 10^{11}$ m) | | $0.086$ |
| 10 AU | Typical gate offset | $0.86$ |
| 50 AU ($7.5 \times 10^{12}$ m) | System radius | $4.32$ |
| 100 AU ($1.5 \times 10^{13}$ m) | Worst-case gate offset | $8.64$ |
| 1 ly ($9.46 \times 10^{15}$ m) | | $5{,}450$ |

**Bounded to 55 ly ($k_R \approx 7 \times 10^7$, $D_{\max} = 5.2 \times 10^{17}$):**

| $\Delta$ | $E[\text{matches}]$ |
|-----------|---------------------|
| 10 AU | $0.40$ |
| 20 AU | $0.81$ |
| 50 AU | $2.02$ |
| 100 AU | $4.04$ |

**Key insight:** The tolerance band is the dominant parameter. At ±10 AU (typical), even 288M pairs yield < 1 expected match. At ±100 AU (worst-case), ~4–9 candidates require multi-link intersection to resolve.

### Intersection Probability for Shared System

For two candidate sets of sizes $n_1$ and $n_2$ drawn from $N$ systems, the probability of a false intersection:

$$P(\text{false match}) \approx \frac{n_1 \cdot n_2}{N}$$

| Tolerance | $n_1 \approx n_2$ | $N$ | $P(\text{false match})$ | Unique ID probability |
|-----------|-------------------|-----|------------------------|-----------------------|
| ±20 AU | 1 | 24,000 | ~0% | ~100% |
| ±50 AU | 2 | 24,000 | 0.017% | 99.98% |
| ±100 AU | 4 | 24,000 | 0.067% | 99.93% |
| ±100 AU | 9 | 24,000 | 0.34% | 99.66% |

**Unique identification via intersection: >99.6% probability** across all tolerance assumptions with 24,000 systems.

## Appendix B: Key Code References

| Topic | File | Lines |
|-------|------|-------|
| `LocationProofMessage.distance: u64` | [location.move](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) | L42-62 |
| `verify_distance` (checks `distance <= max_distance`) | [location.move](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) | L154-170 |
| `verify_same_location` (hash equality only) | [location.move](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) | L180-182 |
| `verify_proximity` (ignores distance) | [location.move](../../vendor/world-contracts/contracts/world/sources/primitives/location.move) | L99-116 |
| `verify_gates_within_range` | [gate.move](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | L597-613 |
| `max_distance` config values | [env.example](../../vendor/world-contracts/env.example) | L51-52 |
| ZK PoC distance circuit (Manhattan squared) | [distance-attestation.circom](../../vendor/eve-frontier-proximity-zk-poc/src/on-chain/circuits/distance-attestation/distance-attestation.circom) | L1-178 |
| `DistanceAttestationPublicData.distance_squared_meters` | [distance_attestation.move](../../vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move) | L18-25 |
| `LocationAttestationData` (coordinates type) | [locationType.ts](../../vendor/eve-frontier-proximity-zk-poc/src/shared/types/locationType.ts) | L1-19 |
| `DistanceData` (ZK PoC registry) | [object_registry.move](../../vendor/eve-frontier-proximity-zk-poc/move/world/sources/registries/object_registry.move) | L15-20 |

## Appendix C: Methodology

This investigation was conducted via:

1. **Static code analysis** of `vendor/world-contracts` and `vendor/eve-frontier-proximity-zk-poc` source code. No vendor files were modified.
2. **Mathematical modeling** of distance uniqueness using birthday paradox analysis and tolerance-band expected value calculations.
3. **Unit determination** by comparing `max_distance` configuration values against known physical constants (light-year in meters).
4. **Scenario modeling** of multi-link intersection attacks using combinatorial probability.

No devnet testing was performed — the distance values are server-computed and signed, so local testing would only verify our own test values, not production behavior.

## Appendix D: Assumptions and Limitations

| Assumption | Confidence | Impact if Wrong |
|------------|-----------|-----------------|
| Distance unit is meters | High (99%+) | If non-meters: requires calibration; uniqueness analysis unchanged if linear unit |
| Distance metric is Euclidean | Medium (80%) | If Manhattan or other: distance computation changes; uniqueness is similar |
| ~24,000 solar systems | Medium-High (80%) | Fewer systems → fewer pairs → MORE unique; more systems → still unique at meter precision (see comparison table in Appendix A) |
| EF-Map coordinates match server coordinates | Medium (70%) | If different: requires origin/scale calibration from 1-2 known links |
| Server always computes true distance | High (95%) | If inaccurate: matching fails; but this contradicts the integrity purpose of signatures |
| Proximity proofs have distance=0 | Medium (60%) | If truthful: proximity proofs also leak (but still server-gated and self-scoped) |
| Gate links are cross-system only | High (90%) | No contract prohibition, but no gameplay utility for same-system links; if observed, trivially distinguishable by distance magnitude |
| Typical intra-system gate offset ~10 AU | Medium (65%) | If larger: tolerance band widens, more candidates per single link; intersection still resolves |
| Worst-case intra-system offset ~100 AU | Medium-High (75%) | If larger: single-link confidence degrades further but multi-link intersection compensates |
| Historical transaction data available | High (95%) | Archival nodes preserve data; standard full nodes may prune. Custom indexer guarantees retention |
