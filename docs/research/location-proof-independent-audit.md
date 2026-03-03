# Location Proof Independent Audit

**Retention:** Prep-only

## 1. Executive Summary

### Scope
This is a fresh adversarial review of on-chain location/distance proof pathways in Move source.
Known `link_gates` plaintext distance exposure was treated as already understood and not re-litigated as the primary issue.

### Mechanism Classification
- **verify_proximity / verify_proximity_proof_from_bytes:** **YELLOW**
  - Signature + server + sender + target hash are enforced, but multiple signed fields are not semantically validated and remain observable/correlatable metadata surfaces.
  - Evidence: [vendor/world-contracts/contracts/world/sources/primitives/location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L105-L151), [vendor/world-contracts/contracts/world/sources/primitives/location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L213-L224), [vendor/world-contracts/contracts/world/sources/primitives/location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L232-L244).

- **verify_same_location:** **GREEN**
  - Minimal logic (hash equality only), no extra scalar parsing; leakage risk primarily comes from upstream hash publication and call context, not this primitive itself.
  - Evidence: [vendor/world-contracts/contracts/world/sources/primitives/location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L180-L182).

- **SSU proximity pathways (world-contracts storage):** **YELLOW**
  - Proof bytes are accepted in multiple entry functions; same-location check exists only on one owner deposit path; other paths rely solely on proximity proof.
  - Evidence: [vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move](vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L139-L172), [vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move](vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L226-L306), [vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move](vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L244-L250).

- **Distance proof path (`verify_distance`) used by gate linking:** **ORANGE**
  - No deadline check at `verify_distance`; caller passes `_clock` but it is unused in gate wrapper. Replay/correlation window is materially broader than proximity paths.
  - Evidence: [vendor/world-contracts/contracts/world/sources/primitives/location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L154-L175), [vendor/world-contracts/contracts/world/sources/assemblies/gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L595-L613), [vendor/world-contracts/contracts/world/sources/assemblies/gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L600-L600).

- **ZK proximity/location attestation PoC flows:** **YELLOW**
  - Public inputs are intentionally provided as tx bytes and decoded on-chain (expected), but caller-provided timestamp is stored without direct cryptographic binding in `verify_location_attestation`.
  - Evidence: [vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move#L19-L25), [vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move#L231-L280), [vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/fixed_object.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/fixed_object.move#L37-L48), [vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/fixed_object.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/fixed_object.move#L110-L114), [vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/dynamic_object.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/dynamic_object.move#L80-L91), [vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/dynamic_object.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/dynamic_object.move#L137-L142).

- **ZK SSU-like distance attestation PoC (`verify_distance_attestation` / `inventory::transfer`):** **YELLOW**
  - Public scalars (`max_timestamp`, `distance_squared_meters`) are decodable from tx inputs by design; storage keying/order choices create additional correlation surfaces.
  - Evidence: [vendor/eve-frontier-proximity-zk-poc/move/world/sources/primitives/inventory.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/primitives/inventory.move#L12-L28), [vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move#L16-L23), [vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move#L27-L112), [vendor/eve-frontier-proximity-zk-poc/move/world/sources/registries/object_registry.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/registries/object_registry.move#L62-L83).

### Did prior Opus 4.6 analysis miss anything material?
**Yes — this code-first review found material additional surfaces beyond the known gate-distance plaintext issue, especially:**
1) unchecked but signed `LocationProofMessage` metadata fields, 2) no deadline enforcement in `verify_distance`, 3) timestamp trust/binding gaps in the PoC attestation write path.

---

## 2. Surface Inventory

| Entry / Public Path | Module | Location/Distance Input Surface | Exposed Inputs (on tx path) | Key Checks |
|---|---|---|---|---|
| `verify_proximity` | `world::location` | `LocationProof` struct | message + signature fields | server authorized, sender match, target hash match, deadline, signature ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L105-L127)) |
| `verify_proximity_proof_from_bytes` | `world::location` | `proof_bytes: vector<u8>` BCS decode | all `LocationProofMessage` fields + signature | same as above ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L130-L151), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L232-L261)) |
| `verify_distance` | `world::location` | `proof_bytes: vector<u8>` BCS decode | same as above | server/sender/target hash + distance<=max + signature; **no deadline check** ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L154-L175)) |
| `verify_same_location` | `world::location` | two location hashes | hash A, hash B | equality only ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L180-L182)) |
| `link_gates` | `world::gate` | `distance_proof: vector<u8>` | proof bytes | delegates to `verify_distance`; `clock` passed but helper uses `_clock` ([gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L154-L195), [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L595-L613)) |
| `chain_item_to_game_inventory` | `world::storage_unit` | `location_proof: vector<u8>` | proof bytes | `inventory::burn_items_with_proof` -> proximity check ([storage_unit.move](vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L139-L172), [inventory.move](vendor/world-contracts/contracts/world/sources/primitives/inventory.move#L194-L217)) |
| `deposit_by_owner` | `world::storage_unit` | `proximity_proof: vector<u8>` | proof bytes + item location hash | same-location + proximity proof ([storage_unit.move](vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L226-L268)) |
| `withdraw_by_owner` | `world::storage_unit` | `proximity_proof: vector<u8>` | proof bytes | proximity proof only ([storage_unit.move](vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L271-L306)) |
| `fixed_object::create` | PoC | signer key/sig, merkle multiproof, zk proof bytes/public inputs | all those vectors + `timestamp` | Groth16 + inclusion + signer ACL; stores location data ([fixed_object.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/fixed_object.move#L37-L126)) |
| `dynamic_object::set_location` | PoC | same as above | same | same checks + event ([dynamic_object.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/dynamic_object.move#L80-L145)) |
| `verify_location_attestation` | PoC | `vkey_bytes`, `proof_points_bytes`, `public_inputs_bytes` | zk artifacts | parses merkle root/coord hash/sig-key hash and validates proof/signature inclusion ([location_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move#L231-L280)) |
| `inventory::transfer` | PoC | distance proof bytes/public inputs | object IDs + zk artifacts | delegates to distance attestation verify ([primitives/inventory.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/primitives/inventory.move#L12-L28)) |
| `verify_distance_attestation` | PoC | `public_inputs_bytes` decodes max ts, roots, coord hashes, distance² | all decoded public outputs | checks against stored location data and may persist distance ([distance_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move#L147-L233)) |

> **Outdated (v0.0.15):** `deposit_by_owner` and `withdraw_by_owner` no longer require proximity proofs or AdminACL — just OwnerCap + sender address match.

---

## 3. Observability Matrix

| Field | Source Struct | Visible in tx input? | Visible in event? | Decodable from tx bytes? | Inference potential |
|---|---|---|---|---|---|
| `server_address` | `LocationProofMessage` | Yes (`proof`/`proof_bytes`) | No | Yes (BCS peel) | server-issuer fingerprint across users/sessions ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L53-L63), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L232-L238)) |
| `player_address` | `LocationProofMessage` | Yes | No | Yes | direct identity linkage to proof issuer cadence ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L53-L63), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L223-L223)) |
| `source_structure_id` | `LocationProofMessage` | Yes | No | Yes | potential stable source fingerprint (unchecked semantically) ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L56-L56), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L236-L236), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L220-L224)) |
| `source_location_hash` | `LocationProofMessage` | Yes | No | Yes | source-location clustering (unchecked semantically) ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L57-L57), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L239-L239), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L220-L224)) |
| `target_structure_id` | `LocationProofMessage` | Yes | No | Yes | target object correlation tag (unchecked semantically) ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L58-L58), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L240-L240), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L220-L224)) |
| `target_location_hash` | `LocationProofMessage` | Yes | Indirectly appears in creation events for structures | Yes | joins proof usage to known anchored structures ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L59-L59), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L224-L224), [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L95-L100), [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L440-L446), [storage_unit.move](vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L80-L86), [storage_unit.move](vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L390-L397)) |
| `distance` | `LocationProofMessage` | Yes | No | Yes | range-bucket inference / mobility profile ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L60-L60), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L166-L166), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L242-L242)) |
| `data` | `LocationProofMessage` | Yes | No | Yes | arbitrary metadata channel; not validated ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L61-L61), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L243-L243), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L220-L224)) |
| `deadline_ms` | `LocationProofMessage` | Yes | No | Yes | timing cadence correlation; absent in `verify_distance` enforcement ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L62-L62), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L117-L117), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L142-L142), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L154-L175)) |
| `route_hash` | `JumpPermit` | Yes (permit object fields on-chain) | Not emitted directly | N/A | persistent route fingerprint for gate pair usage ([gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L85-L91), [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L615-L624), [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L646-L661)) |
| `expires_at_timestamp_ms` | `JumpPermit` | Yes | Not emitted directly | N/A | temporal linkage windows for permit issuance/use ([gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L85-L91), [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L655-L655)) |
| `public_inputs_bytes` (location attestation) | PoC `verify_location_attestation` | Yes | No | Yes (`parse_public_inputs`) | exposes merkle root / coordinates hash / sig-key hash tuple ([location_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move#L80-L109), [location_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move#L231-L252)) |
| `timestamp` (location attestation data) | `LocationAttestationData` | Yes | No | trivially | user-supplied timestamp written to registry; not cryptographically compared in verifier ([location_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move#L19-L25), [fixed_object.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/fixed_object.move#L44-L48), [fixed_object.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/fixed_object.move#L110-L114), [dynamic_object.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/dynamic_object.move#L88-L91), [dynamic_object.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/dynamic_object.move#L137-L142)) |
| `public_inputs_bytes` (distance attestation) | PoC `verify_distance_attestation` | Yes | No | Yes (`parse_distance_public_inputs`) | exposes `max_timestamp`, both roots/hashes, `distance_squared_meters` ([distance_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move#L27-L112), [distance_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move#L147-L167)) |
| `distance_squared_meters` | `DistanceAttestationPublicData` / `DistanceData` | Yes | No | Yes | direct quantitative proximity disclosure usable for triangulation with external map priors ([distance_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move#L22-L22), [distance_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move#L89-L112), [object_registry.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/registries/object_registry.move#L17-L20)) |
| `max_timestamp` | `DistanceAttestationPublicData` / `DistanceData` | Yes | No | Yes | synchronizes two object timelines; supports time-correlation graphing ([distance_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move#L17-L17), [distance_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move#L197-L199), [object_registry.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/registries/object_registry.move#L17-L20)) |

---

## 4. Findings

### Confirmed safe areas
1. `verify_proximity*` verifies authorized server, sender binding, target-location hash, and signature over serialized message; straightforward tampering is blocked.
   - Evidence: [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L213-L224), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L116-L124), [sig_verify.move](vendor/world-contracts/contracts/world/sources/crypto/sig_verify.move#L50-L101).
2. `verify_same_location` is intentionally minimal and does not parse extra structure.
   - Evidence: [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L180-L182).
3. Jump permit is invalidated on use (object deleted), reducing permit replay after successful consumption.
   - Evidence: [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L663-L666).

### Potential leakage / inference surfaces
1. `LocationProofMessage` includes multiple observable scalars/hashes (`source_structure_id`, `source_location_hash`, `target_structure_id`, `data`) that are signed but not semantically checked by `validate_proof_message`.
   - Evidence: [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L53-L63), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L220-L224), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L236-L244).
2. Gate/SSU creation events emit `location_hash`, enabling joins with proof-bound `target_location_hash` and later activity streams.
   - Evidence: [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L95-L100), [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L440-L446), [storage_unit.move](vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L80-L86), [storage_unit.move](vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L390-L397).
3. `JumpEvent` exposes source/destination gate IDs and character IDs, allowing traversal graph construction when combined with emitted location hashes.
   - Evidence: [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L104-L111), [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L636-L642).
4. PoC attestation public inputs are intentionally passed as tx bytes and decoded into reusable hashes/scalars (`merkle_root*`, `coordinates_hash*`, `distance_squared_meters`, `max_timestamp`).
   - Evidence: [location_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move#L80-L109), [distance_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move#L27-L112).

### Unexpected / non-obvious surfaces
1. `verify_distance` omits deadline validation entirely; unlike proximity checks, it never calls `is_deadline_valid`.
   - Evidence: [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L154-L175), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L117-L117), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L142-L142).
2. `link_gates` passes `clock`, but helper uses `_clock` and does not enforce freshness.
   - Evidence: [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L163-L163), [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L600-L600).
3. PoC `timestamp` in `LocationAttestationData` is accepted from tx input and stored, but verifier does not compare it against Groth16 public outputs.
   - Evidence: [location_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move#L19-L25), [location_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move#L231-L280), [fixed_object.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/fixed_object.move#L110-L114), [dynamic_object.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/dynamic_object.move#L137-L142).
4. PoC distance storage key is ordered concatenation (`object_id1 || object_id2`), not canonicalized pair key; this can fragment/correlate directional pair records.
   - Evidence: [object_registry.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/registries/object_registry.move#L62-L83), [object_registry.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/registries/object_registry.move#L170-L192).

### Unvalidated / ignored-by-logic fields
1. In world-contracts `LocationProofMessage`, validated fields are limited to `server_address`, `player_address`, and `target_location_hash`; other message fields are not checked for semantic consistency.
   - Evidence: [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L220-L224), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L53-L63).
2. `data` is decoded but not interpreted/validated by contract logic.
   - Evidence: [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L243-L243), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L220-L224).
3. PoC location attestation `timestamp` influences storage recency but is not cryptographically bound inside verifier checks.
   - Evidence: [location_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move#L231-L280), [object_registry.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/registries/object_registry.move#L134-L148).

---

## 5. Correlation & Fingerprinting Analysis

### Cross-transaction linkage potential
- `server_address` + signed message shape + optional `data`/`source_*` fields can create reusable fingerprints across otherwise unrelated txs.
  - Evidence: [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L53-L63), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L220-L224), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L232-L244).
- Emitted `location_hash` in gate/SSU creation plus `JumpEvent` IDs enables reconstruction of route usage graphs.
  - Evidence: [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L95-L111), [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L440-L446), [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L636-L642), [storage_unit.move](vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L390-L397).
- PoC attestation public outputs (`coordinates_hash`, roots, distance², max timestamp) are directly correlatable across calls.
  - Evidence: [location_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move#L80-L109), [distance_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move#L27-L112).

### Replay analysis
- Proximity paths enforce deadlines, reducing replay window to proof freshness interval.
  - Evidence: [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L117-L117), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L142-L142), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L263-L266).
- Distance path (`verify_distance`) has no deadline check, so a valid signed message can be reused while other predicates still hold.
  - Evidence: [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L154-L175).
- Jump permits are single-use by deletion after validation.
  - Evidence: [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L663-L666).

### Signature reuse concerns
- `sig_verify::verify_signature` derives signer from embedded pubkey bytes and checks against expected address; cryptographically sound for signer binding.
  - Evidence: [sig_verify.move](vendor/world-contracts/contracts/world/sources/crypto/sig_verify.move#L40-L48), [sig_verify.move](vendor/world-contracts/contracts/world/sources/crypto/sig_verify.move#L89-L100).
- But if server reuses signatures/messages with static optional fields, on-chain observers can correlate repeated payload patterns even when use is valid.
  - Evidence: [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L53-L63), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L232-L261).

### Deadline misuse / timing leakage
- Explicit `deadline_ms` value itself is observable and can leak server issuance cadence.
  - Evidence: [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L62-L62), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L244-L244).
- Missing deadline enforcement in distance path is a materially larger risk than cadence leakage.
  - Evidence: [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L154-L175).
- PoC `timestamp` trust model can permit caller-controlled temporal metadata (subject to monotonic registry check).
  - Evidence: [location_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move#L19-L25), [object_registry.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/registries/object_registry.move#L134-L148).

---

## 6. Final Risk Classification

| Mechanism | Classification | Reasoning |
|---|---|---|
| `verify_same_location` | **GREEN** | Simple equality primitive; no extra decoded scalar surface beyond caller-supplied hashes ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L180-L182)). |
| `verify_proximity` / `verify_proximity_proof_from_bytes` | **YELLOW** | Strong signature + identity checks, but observable signed metadata fields are not semantically constrained, enabling correlation channels ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L213-L224), [location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L232-L244)). |
| SSU owner/game-bridge proximity usage | **YELLOW** | Multiple entry points ingest proof bytes; enforcement patterns differ by path and still expose same proof metadata surfaces ([storage_unit.move](vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L139-L172), [storage_unit.move](vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L226-L306)). |
| Distance verification path (`verify_distance` via gate linking) | **ORANGE** | Deadline omitted, with `_clock` unused at caller helper, creating larger replay/correlation window ([location.move](vendor/world-contracts/contracts/world/sources/primitives/location.move#L154-L175), [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L595-L613)). |
| PoC `verify_location_attestation` + fixed/dynamic writes | **YELLOW** | Public-input observability expected, but caller-provided timestamp is not bound in verifier and still influences stored state ([location_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move#L231-L280), [fixed_object.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/fixed_object.move#L110-L114), [dynamic_object.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/dynamic_object.move#L137-L142)). |
| PoC distance attestation + transfer path | **YELLOW** | Distance/timestamp/roots are intentionally public and decodable; pair-keying/storage choices add linkability surfaces ([distance_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move#L27-L112), [distance_attestation.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move#L197-L227), [object_registry.move](vendor/eve-frontier-proximity-zk-poc/move/world/sources/registries/object_registry.move#L62-L83)). |

## Bottom line
Independent verification found additional, non-trivial observability and inference surfaces not limited to the already-known gate distance plaintext exposure. The highest-priority hardening target is deadline/freshness enforcement consistency for distance proofs, followed by constraining or removing unused signed metadata fields in `LocationProofMessage`.