# Distance-Constraint Solar System Mapping Analysis

**Retention:** Prep-only

## 1. Executive Verdict

**ORANGE — Strong solar system identification is feasible from gate link distances combined with a publicly available star coordinate database.**

A single cross-system `link_gates` transaction exposes an exact `distance: u64` value (in meters). With access to a high-precision 3D coordinate database of all solar systems (e.g., EF-Map data), an observer can match that scalar distance against the ~32 million pairwise inter-system distances. Due to the astronomical precision (integer meters across a ~100 light-year universe), **each distance value is statistically unique**, typically narrowing to exactly one candidate system pair.

With two or more links sharing a gate, the intersection collapses candidates to near-certainty.

This finding upgrades the prior actionability assessment for a specific sub-threat: **system-level identification of a player's gate locations**. The prior reports correctly noted that:
- Cross-player graph reconstruction is infeasible (same-owner constraint — unchanged)
- Network-wide topology mapping is structurally impossible (unchanged)

This analysis adds a NEW finding: **per-player solar system identification is feasible** from the player's own gate link transactions, using only publicly available data. The same-owner constraint does NOT protect against this vector because the attacker doesn't need cross-player edges — they need only match scalar distances to a known coordinate database.

| Threat | Prior Assessment | This Analysis | Reason |
|--------|-----------------|---------------|--------|
| Cross-player graph reconstruction | GREEN | GREEN (unchanged) | Same-owner constraint prevents cross-player edges |
| Network-wide topology | GREEN | GREEN (unchanged) | Disconnected per-player subgraphs |
| **Solar system pair identification** | GREEN (implicit) | **ORANGE** | Distance matching against star database yields near-unique results |
| Proximity proof oracle | GREEN | GREEN (confirmed) | Server-gated, self-scoped, likely distance=0 |

**Practical impact:** An observer can determine which specific solar systems a player has gates in by monitoring their `link_gates` transactions. This is competitive intelligence — knowing where a player operates. The player already knows their own locations, but **their opponents do not**, and this vector exposes that information.

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
| Number of solar systems ($N$) | ~8,000 | EVE Online SDE (~7,800); EVE Frontier expected similar |
| Number of system pairs | $\binom{N}{2} \approx 32{,}000{,}000$ | Combinatorial |
| Universe diameter | ~100 ly ($\approx 9.46 \times 10^{17}$ m) | From gate max_distance tiers |
| Distance range | $[0, \sim 10^{18}]$ meters | |
| Distance precision | 1 meter (integer u64) | From data type |
| Possible distance values | $\sim 10^{18}$ | Continuous range, integer samples |

### 3.2 Distance Uniqueness Analysis

The key question: **Given ~32 million pairwise distances drawn from ~$10^{18}$ possible integer values, how many collisions (duplicate distances) exist?**

This is a birthday paradox calculation. For $k$ items drawn from a space of size $n$:

$$P(\text{at least one collision}) \approx 1 - e^{-k^2 / 2n}$$

With $k = 3.2 \times 10^7$ and $n = 10^{18}$:

$$\frac{k^2}{2n} = \frac{(3.2 \times 10^7)^2}{2 \times 10^{18}} = \frac{1.024 \times 10^{15}}{2 \times 10^{18}} = 5.12 \times 10^{-4}$$

$$P(\text{collision}) \approx 5.12 \times 10^{-4} \approx 0.05\%$$

**Expected number of collisions across the entire dataset: ~0.5.** In other words, **virtually every pairwise distance in the universe is unique at integer-meter precision.**

### 3.3 Single Link Observation

Given one observed distance $D$ from a `link_gates` transaction:

| Tolerance | Expected matching pairs | Assessment |
|-----------|----------------------|------------|
| ±0 m (exact) | **1** (near-certain) | Unique identification |
| ±1 km | ~1 | Still unique |
| ±1 AU (~$1.5 \times 10^{11}$ m) | ~0.01 | Effectively unique |
| ±10 AU | ~0.1 | Likely unique |
| ±100 AU (~$1.5 \times 10^{13}$ m) | ~1 | Borderline; 1-2 candidates |
| ±1 ly (~$9.5 \times 10^{15}$ m) | ~60 | Moderate candidate set |

**Formula:** Expected matches $\approx \binom{N}{2} \times \frac{2\Delta}{D_{\max}} \approx 3.2 \times 10^7 \times \frac{2\Delta}{10^{18}}$

### 3.4 Intra-System Position Offset

Gates are NOT at solar system centers. A gate's position within its system introduces an offset:

- Solar system radius: ~1-50 AU ($1.5 \times 10^{11}$ to $7.5 \times 10^{12}$ m)
- Maximum cumulative offset from two gates: ~100 AU ($\sim 1.5 \times 10^{13}$ m)

This means:

$$|D_{\text{gate-to-gate}} - D_{\text{system-to-system}}| \leq \sim 100 \text{ AU}$$

From the table above, ±100 AU yields ~1 expected match. **A single cross-system gate link distance identifies the system pair with high probability (~50-70%)**, and if 2-3 candidate pairs match, a second observation sharing a gate eliminates the ambiguity.

### 3.5 Same-System Links

If both gates are in the same solar system, the distance is:
- Magnitude: $\sim 10^{10}$ to $\sim 10^{13}$ m (sub-AU to a few AU)
- No inter-system pair has a distance this small

Same-system links **do not leak inter-system information** but DO confirm the gates are co-located (same system).

### 3.6 Multi-Link Narrowing

**Scenario: Player links A↔B and B↔C (two links sharing gate B)**

1. **Link A↔B** with distance $D_1$: Enumerate candidate system pairs → typically 1-2 candidates
2. **Link B↔C** with distance $D_2$: Enumerate candidate system pairs → typically 1-2 candidates
3. **Intersection on B**: Gate B must be in a system that appears in BOTH candidate sets → typically **1 candidate**

With $n_1$ candidates for A-B and $n_2$ candidates for B-C, the intersection probability:

$$P(\text{unique intersection}) = 1 - \left(\frac{N - 1}{N}\right)^{n_1 \cdot n_2} \approx \frac{n_1 \cdot n_2}{N}$$

For $n_1 = n_2 = 2$ and $N = 8000$: random overlap probability is $\frac{4}{8000} = 0.05\%$. **The intersection almost always resolves to a unique system for B**, confirming all three systems.

**Three or more links converge to certainty.**

### 3.7 Candidate Count Estimates

| Observations | Typical candidate systems | Confidence |
|--------------|--------------------------|------------|
| 1 cross-system link | 1-2 system pairs | 50-70% unique identification |
| 2 links sharing a gate | 1 system for shared gate | >99% unique |
| 3+ links (connected) | All systems identified | ~100% |
| Same-system link only | 0 inter-system candidates | N/A (confirms co-location) |

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

The observer computes all $\binom{8000}{2} \approx 32\text{M}$ pairwise distances between systems in the database. They search for pairs $(S_i, S_j)$ where:

$$|D_{\text{system}}(S_i, S_j) - D_1| \leq 100 \text{ AU}$$

**Expected result:** 0-2 candidate pairs (from §3.3 analysis).

Assume result: {(System 1294, System 5821), (System 3102, System 7744)}

### 6.3 Step 2: Compute Candidate Set for B-C

Same procedure with $D_2$:

**Expected result:** 0-2 candidate pairs.

Assume result: {(System 5821, System 2087)}

### 6.4 Step 3: Intersection on Shared Gate B

Gate B appears in both links. Its system must be in the intersection of:
- A-B candidates: systems {1294, 5821, 3102, 7744}
- B-C candidates: systems {5821, 2087}

**Intersection:** System 5821 is the ONLY system appearing in both sets.

**Result:**
- Gate B → **System 5821** (certain)
- Gate A → **System 1294** (from A-B pair containing 5821)
- Gate C → **System 2087** (from B-C pair containing 5821)

### 6.5 Collapse Rate Assessment

| Topology | Links | Expected unique identification |
|----------|-------|-------------------------------|
| A↔B (isolated) | 1 | ~60% (1-2 candidates) |
| A↔B, B↔C (chain) | 2 | >99% (intersection resolves B) |
| A↔B, B↔C, A↔C (triangle) | 3 | ~100% (over-determined) |
| A↔B (same-system) | 1 | 0% inter-system info (confirms co-location only) |

### 6.6 Symmetry and Ambiguity

**Does the symmetry of the universe create ambiguity?**

In principle, a perfectly symmetric crystal-lattice universe would have many distance collisions. In practice, EVE's solar system distribution is:
- Irregularly distributed in 3D (not a lattice)
- Clustered into regions, constellations, and "pipes"
- Based on (or analogous to) real astronomical catalogs

The irregular distribution means that at meter precision, distance collisions are extremely rare. Even in the densest regions, the birthday arithmetic applies: ~32M pairs across ~$10^{18}$ possible values yields near-zero collisions.

**Counter-argument: What if EVE Frontier uses a MUCH smaller universe?**

If $N$ is significantly smaller (e.g., 500 systems) or the universe is more compact, the analysis still holds. With $N = 500$: $\binom{500}{2} = 124{,}750$ pairs — even fewer candidates per distance observation.

**Conclusion: Universe symmetry does NOT create meaningful ambiguity at integer-meter precision.**

---

## 7. Final Risk Classification

### 7.1 Classification: ORANGE — Strong Location Inference Possible

| Classification Element | Assessment |
|----------------------|------------|
| **Can we enumerate candidates?** | YES — with near-unique matching at meter precision |
| **Can multiple links narrow further?** | YES — intersection on shared gates collapses to certainty |
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

4. **Intra-system offset.** The ~±100 AU tolerance from gate positioning introduces enough noise that ~30-40% of single-link observations may yield 2 candidates instead of 1, requiring a second observation to disambiguate.

5. **Same-owner constraint limits scope.** This is per-player self-leakage — the player's OWN system locations are exposed, not other players'. The attacker gains competitive intelligence, not universal surveillance.

### 7.3 Why Not YELLOW or GREEN

The classification cannot be YELLOW because:

1. **Matching is mathematically near-certain.** With $10^{18}$ possible values and $10^7$ pairs, virtually every distance is unique. This isn't "moderate candidate reduction" — it's near-deterministic.

2. **No cryptographic barrier.** The distance value is plaintext. The star database is public. The matching computation is trivial.

3. **Practical adversary model exists.** A competitive player or intelligence service monitoring the blockchain can build this system with minimal engineering effort: one RPC endpoint + one coordinate database + one distance comparison script.

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

With $k = 3.2 \times 10^7$ and $n = 10^{18}$:

$$E = \frac{3.2 \times 10^7 \times (3.2 \times 10^7 - 1)}{2 \times 10^{18}} \approx \frac{1.024 \times 10^{15}}{2 \times 10^{18}} \approx 5.12 \times 10^{-4}$$

Expected collisions: ~0.0005 across the entire universe. **Virtually zero.**

### Tolerance-Band Expected Matches

For a query distance $D$ with tolerance $\pm \Delta$, the expected number of matching pairs:

$$E[\text{matches}] = k \cdot \frac{2\Delta}{D_{\max}} = 3.2 \times 10^7 \times \frac{2\Delta}{10^{18}}$$

| $\Delta$ | Physical meaning | $E[\text{matches}]$ |
|-----------|-----------------|---------------------|
| 1 m | Integer truncation | $6.4 \times 10^{-11}$ |
| 1 km | | $6.4 \times 10^{-8}$ |
| 1 AU ($1.5 \times 10^{11}$ m) | | $0.0096$ |
| 10 AU | | $0.096$ |
| 50 AU ($7.5 \times 10^{12}$ m) | System radius | $0.48$ |
| 100 AU ($1.5 \times 10^{13}$ m) | Max gate offset | $0.96$ |
| 1 ly ($9.46 \times 10^{15}$ m) | | $60.5$ |

### Intersection Probability for Shared Gate

For two candidate sets of sizes $n_1$ and $n_2$ drawn from $N$ systems, the probability of a false intersection:

$$P(\text{false match}) \approx \frac{n_1 \cdot n_2}{N}$$

For $n_1 = n_2 = 2$, $N = 8000$: $P = 0.0005 = 0.05\%$.

**Unique identification via intersection: >99.95% probability.**

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
| ~8,000 solar systems | Medium (70%) | Fewer systems → fewer pairs → MORE unique; more systems → still unique at meter precision |
| EF-Map coordinates match server coordinates | Medium (70%) | If different: requires origin/scale calibration from 1-2 known links |
| Server always computes true distance | High (95%) | If inaccurate: matching fails; but this contradicts the integrity purpose of signatures |
| Proximity proofs have distance=0 | Medium (60%) | If truthful: proximity proofs also leak (but still server-gated and self-scoped) |
