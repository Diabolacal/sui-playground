# Turret Localnet Validation Checklist

**Retention:** Carry-forward

> **Date:** 2026-03-02
> **Source:** turret.move (678 lines), extension_examples/turret.move (65 lines), turret_tests.move (1098 lines).
> **Status:** Planning checklist. No validation runs executed yet.
> **Scope:** Primarily CivilizationControl (CC). Applicability to CargoBond (CB) and Fortune Gauntlet (FG) noted per test.

---

## Key Dependency

Turrets are game-engine-created assemblies. Most creation flows (`anchor`, `share_turret`) require `ObjectRegistry`, `NetworkNode`, `Character`, `AdminACL`, and `EnergyConfig` objects provisioned by the world deployment. Tests marked **ENVIRONMENT-BLOCKED** require these objects.

### Legend

| Status | Meaning |
|--------|---------|
| **EXECUTABLE NOW** | Can be validated right now: source review, `sui move build`, `sui move test`, or `sui client call` on localnet (no game-engine objects needed) |
| **ENVIRONMENT-BLOCKED** | Test logic is sound and behavior IS testable, but requires game-engine-provisioned objects (ObjectRegistry, NetworkNode, Character, AdminACL, EnergyConfig) not creatable via CLI |
| **STRUCTURALLY IMPOSSIBLE** | Cannot be validated even with a full game-engine deployment — depends on behavior the contract architecture fundamentally cannot support |

---

## Three-Way Classification Summary

> **Date classified:** 2026-03-02
> **Evidence basis:** turret.move signature analysis, state/storage path analysis, targeting matrix review, closed-world constraint documentation.

| Classification | Count | IDs |
|---|---|---|
| **EXECUTABLE NOW** | 8 | P-01, P-02, P-03, P-04, X-04, A-01, A-02, A-03 |
| **ENVIRONMENT-BLOCKED** | 36 | C-01–C-06, E-01–E-04, L-01–L-06, D-01–D-09, O-01–O-04, X-01–X-03, X-05–X-07, A-04 |
| **STRUCTURALLY IMPOSSIBLE** | 1 | A-05 |
| **Total** | **45** | |

### Full Classification Table

| ID | Title | Classification | Rationale |
|---|---|---|---|
| P-01 | World contracts published | EXECUTABLE NOW | Can run `sui client publish` on localnet; no game-engine objects required. |
| P-02 | Extension package published after world | EXECUTABLE NOW | Can run `sui client publish` for extension package after world is deployed on localnet. |
| P-03 | Extension depends on world (not extension_examples) | EXECUTABLE NOW | Source review of `Move.toml` dependencies — no on-chain objects needed. |
| P-04 | x_auth() is public(package) | EXECUTABLE NOW | Source review of extension config module — visibility is compile-time verifiable. |
| C-01 | anchor creates Turret + OwnerCap | ENVIRONMENT-BLOCKED | Requires `ObjectRegistry`, `NetworkNode`, `Character`, `AdminACL` — all game-engine-provisioned singletons. |
| C-02 | Duplicate item_id rejected | ENVIRONMENT-BLOCKED | Requires a first successful `anchor` call plus game-engine objects for the second. |
| C-03 | Zero type_id rejected | ENVIRONMENT-BLOCKED | Requires `ObjectRegistry`, `NetworkNode`, `Character`, `AdminACL` for `anchor` call. |
| C-04 | Zero item_id rejected | ENVIRONMENT-BLOCKED | Requires `ObjectRegistry`, `NetworkNode`, `Character`, `AdminACL` for `anchor` call. |
| C-05 | share_turret makes Turret shared | ENVIRONMENT-BLOCKED | Requires a Turret (from `anchor`) plus `AdminACL`. |
| C-06 | share_turret requires verify_sponsor | ENVIRONMENT-BLOCKED | Requires a Turret plus `AdminACL` to test sponsorship enforcement. |
| E-01 | authorize_extension sets type | ENVIRONMENT-BLOCKED | Requires a shared Turret and its `OwnerCap<Turret>`, both created by `anchor`. |
| E-02 | Wrong OwnerCap rejected | ENVIRONMENT-BLOCKED | Requires two Turrets and their OwnerCaps to test mismatch — all from game-engine `anchor`. |
| E-03 | swap_or_fill replaces existing extension | ENVIRONMENT-BLOCKED | Requires an already-extended Turret plus OwnerCap. |
| E-04 | No event on extension change | ENVIRONMENT-BLOCKED | Requires running E-03; same object dependencies. |
| L-01 | online() transitions turret | ENVIRONMENT-BLOCKED | Requires Turret, `NetworkNode`, `EnergyConfig`, OwnerCap — all game-engine-provisioned. |
| L-02 | Wrong NetworkNode rejected | ENVIRONMENT-BLOCKED | Requires Turret plus multiple NetworkNodes — game-engine objects. |
| L-03 | Wrong OwnerCap rejected | ENVIRONMENT-BLOCKED | Requires Turret plus mismatched OwnerCap — both from `anchor`. |
| L-04 | offline() transitions turret | ENVIRONMENT-BLOCKED | Requires an online Turret plus `NetworkNode`, `EnergyConfig`, OwnerCap. |
| L-05 | verify_online returns receipt | ENVIRONMENT-BLOCKED | Requires an online Turret — depends on L-01 flow. |
| L-06 | verify_online rejects offline | ENVIRONMENT-BLOCKED | Requires a Turret in offline state — created via `anchor`. |
| D-01 | Same-tribe non-aggressor excluded | ENVIRONMENT-BLOCKED | Default targeting requires online Turret, Character, and BCS candidates — game-engine objects needed. |
| D-02 | Different-tribe included | ENVIRONMENT-BLOCKED | Requires online Turret and Character for `get_target_priority_list`. |
| D-03 | Same-tribe aggressor included | ENVIRONMENT-BLOCKED | Same object requirements as D-01. |
| D-04 | STARTED_ATTACK adds +10000 | ENVIRONMENT-BLOCKED | Requires online Turret + Character to invoke default targeting path. |
| D-05 | ENTERED adds +1000 (different tribe) | ENVIRONMENT-BLOCKED | Same object requirements as D-01. |
| D-06 | ENTERED no boost for same-tribe non-aggressor | ENVIRONMENT-BLOCKED | Same object requirements as D-01. |
| D-07 | STOPPED_ATTACK excludes target | ENVIRONMENT-BLOCKED | Same object requirements as D-01. |
| D-08 | PriorityListUpdatedEvent emitted | ENVIRONMENT-BLOCKED | Requires a complete default targeting call — game-engine objects. |
| D-09 | Empty candidate list | ENVIRONMENT-BLOCKED | Requires online Turret + Character even for empty candidate test. |
| O-01 | Default event contains all input candidates | ENVIRONMENT-BLOCKED | Requires running default targeting path — same object dependencies as D-01. |
| O-02 | Extension path: no world-module event | ENVIRONMENT-BLOCKED | Requires an extended online Turret invoked by game engine — game-engine objects + extension call. |
| O-03 | MoveAbort emits no events | ENVIRONMENT-BLOCKED | Requires a Turret object to call `verify_online` on — created via `anchor`. |
| O-04 | Default path aborts when extension set | ENVIRONMENT-BLOCKED | Requires an extended Turret — depends on E-01 flow. |
| X-01 | Extension overwrite | ENVIRONMENT-BLOCKED | Same as E-03 — requires Turret + OwnerCap from `anchor`. |
| X-02 | Receipt-turret mismatch | ENVIRONMENT-BLOCKED | Requires two online Turrets and their receipts — game-engine objects. |
| X-03 | Unconsumed receipt | ENVIRONMENT-BLOCKED | Requires an online Turret to obtain an OnlineReceipt. |
| X-04 | destroy_online_receipt type check | EXECUTABLE NOW | Compile-time type constraint — verifiable with `sui move build` against intentionally wrong Auth type. |
| X-05 | Orphaned turret unanchor | ENVIRONMENT-BLOCKED | Requires Turret with no energy source — game-engine provisioning for initial creation. |
| X-06 | unanchor wrong NetworkNode | ENVIRONMENT-BLOCKED | Requires Turret and multiple NetworkNodes — game-engine objects. |
| X-07 | Malformed BCS candidates | ENVIRONMENT-BLOCKED | Requires online Turret + Character to invoke targeting with bad BCS. |
| A-01 | Default turret tribe-filter matches gate tribe_permit | EXECUTABLE NOW | Source comparison of `turret.move` vs `tribe_permit.move` — no objects needed. |
| A-02 | authorize_extension identical pattern | EXECUTABLE NOW | Source comparison of authorize_extension in turret.move vs gate.move — no objects needed. |
| A-03 | Closed-world difference: turret vs gate | EXECUTABLE NOW | Source comparison of extension calling conventions — documented architectural fact. |
| A-04 | Default behavior = CC policy | ENVIRONMENT-BLOCKED | Requires executing D-01 through D-03 on localnet, which need game-engine objects. Source review confirms the logic, but on-chain validation is blocked. |
| A-05 | CB/FG turret applicability | STRUCTURALLY IMPOSSIBLE | Closed-world constraint: `get_target_priority_list` has fixed 4-arg signature enforced by game engine. Bond-checking (CB) and scoring logic (FG) require external shared objects that cannot be passed to the extension. |

---

## 1. Publish Prerequisites

| ID | Title | Steps | Expected Result | Status | Applies To |
|----|-------|-------|-----------------|--------|------------|
| P-01 | World contracts published | `sui client publish --path vendor/world-contracts/contracts/world` | `world::turret` module available | EXECUTABLE NOW | ALL |
| P-02 | Extension package published after world | Publish extension pkg with world dependency | Extension `get_target_priority_list` entry point available | EXECUTABLE NOW | ALL |
| P-03 | Extension depends on world (not extension_examples) | Inspect `Move.toml` `[dependencies]` | `world` listed; `extension_examples` NOT used as dependency | EXECUTABLE NOW | ALL |
| P-04 | x_auth() is public(package) | Source review of extension config module | `public(package) fun x_auth()`, not `public` | EXECUTABLE NOW | ALL |

---

## 2. Object Creation Flows

| ID | Title | Steps | Expected Result | Status | Applies To |
|----|-------|-------|-----------------|--------|------------|
| C-01 | anchor creates Turret + OwnerCap | `turret::anchor(registry, nwn, character, admin_acl, item_id, type_id, location_hash)` | Turret returned; OwnerCap transferred to character; `TurretCreatedEvent` emitted | ENVIRONMENT-BLOCKED | ALL |
| C-02 | Duplicate item_id rejected | anchor with existing item_id | Abort code 5 (`ETurretAlreadyExists`) | ENVIRONMENT-BLOCKED | ALL |
| C-03 | Zero type_id rejected | anchor with type_id=0 | Abort code 3 (`ETurretTypeIdEmpty`) | ENVIRONMENT-BLOCKED | ALL |
| C-04 | Zero item_id rejected | anchor with item_id=0 | Abort code 4 (`ETurretItemIdEmpty`) | ENVIRONMENT-BLOCKED | ALL |
| C-05 | share_turret makes Turret shared | `turret::share_turret(turret, admin_acl)` | Turret becomes shared object | ENVIRONMENT-BLOCKED | ALL |
| C-06 | share_turret requires verify_sponsor | Call without sponsorship from non-ACL address | Abort in access_control module | ENVIRONMENT-BLOCKED | ALL |

---

## 3. Extension Authorization

| ID | Title | Steps | Expected Result | Status | Applies To |
|----|-------|-------|-----------------|--------|------------|
| E-01 | authorize_extension sets type | `turret::authorize_extension<TurretAuth>(turret, owner_cap)` | `turret.extension = Some(TypeName)` | ENVIRONMENT-BLOCKED | ALL |
| E-02 | Wrong OwnerCap rejected | authorize_extension with mismatched OwnerCap | Abort code 0 (`ETurretNotAuthorized`) | ENVIRONMENT-BLOCKED | ALL |
| E-03 | swap_or_fill replaces existing extension | authorize_extension with different Auth type on same turret | Extension silently replaced, NO event | ENVIRONMENT-BLOCKED | CC |
| E-04 | No event on extension change | Perform E-03 | Zero extension-change events in tx effects | ENVIRONMENT-BLOCKED | CC |

> **CC governance note:** Extension can be silently swapped. Off-chain detection requires polling `turret.extension` field.

---

## 4. Online/Offline Lifecycle

| ID | Title | Steps | Expected Result | Status | Applies To |
|----|-------|-------|-----------------|--------|------------|
| L-01 | online() transitions turret | `turret::online(turret, nwn, energy_config, owner_cap)` | Status online; energy reserved | ENVIRONMENT-BLOCKED | ALL |
| L-02 | Wrong NetworkNode rejected | online with mismatched nwn | Abort code 1 (`ENetworkNodeMismatch`) | ENVIRONMENT-BLOCKED | ALL |
| L-03 | Wrong OwnerCap rejected | online with wrong OwnerCap | Abort code 0 (`ETurretNotAuthorized`) | ENVIRONMENT-BLOCKED | ALL |
| L-04 | offline() transitions turret | `turret::offline(turret, nwn, energy_config, owner_cap)` | Status offline; energy released | ENVIRONMENT-BLOCKED | ALL |
| L-05 | verify_online returns receipt | `turret::verify_online(turret)` on online turret | OnlineReceipt returned (must consume in same tx) | ENVIRONMENT-BLOCKED | ALL |
| L-06 | verify_online rejects offline | verify_online on offline turret | Abort code 2 (`ENotOnline`) | ENVIRONMENT-BLOCKED | ALL |

---

## 5. Default Targeting (No Extension)

| ID | Title | Candidate Setup | Expected Result | Status | Applies To |
|----|-------|----------------|-----------------|--------|------------|
| D-01 | Same-tribe non-aggressor excluded | tribe=X (owner tribe), is_aggressor=false | Not in return list | ENVIRONMENT-BLOCKED | CC |
| D-02 | Different-tribe included | tribe=Y (Y != owner tribe) | In return list with base weight | ENVIRONMENT-BLOCKED | CC |
| D-03 | Same-tribe aggressor included | tribe=X, is_aggressor=true | In return list (aggressor overrides tribe exclusion) | ENVIRONMENT-BLOCKED | CC |
| D-04 | STARTED_ATTACK adds +10000 | behaviour_change=2, weight=100 | Return weight = 10100 | ENVIRONMENT-BLOCKED | ALL |
| D-05 | ENTERED adds +1000 (different tribe) | behaviour_change=1, tribe=Y, weight=50 | Return weight = 1050 | ENVIRONMENT-BLOCKED | ALL |
| D-06 | ENTERED no boost for same-tribe non-aggressor | behaviour_change=1, tribe=X, is_aggressor=false | Excluded from return list | ENVIRONMENT-BLOCKED | CC |
| D-07 | STOPPED_ATTACK excludes target | behaviour_change=3 (any tribe) | Not in return list | ENVIRONMENT-BLOCKED | ALL |
| D-08 | PriorityListUpdatedEvent emitted | Any default-path call | Event with full candidate list | ENVIRONMENT-BLOCKED | ALL |
| D-09 | Empty candidate list | Empty BCS vector | Empty return + event still emitted | ENVIRONMENT-BLOCKED | ALL |

> **CC alignment confirmation:** D-01 through D-03 validate that default turret behavior = "tribe_only" territorial defense. If these pass, no custom CC turret extension is needed.

---

## 6. Denial Observability

| ID | Title | Steps | Expected Result | Status | Applies To |
|----|-------|-------|-----------------|--------|------------|
| O-01 | Default event contains all input candidates | Default targeting call | `PriorityListUpdatedEvent.priority_list` = input candidates (not filtered output) | ENVIRONMENT-BLOCKED | CC |
| O-02 | Extension path: no world-module event | Turret with extension; game calls extension | No `world::turret::PriorityListUpdatedEvent` in tx effects | ENVIRONMENT-BLOCKED | CC |
| O-03 | MoveAbort emits no events | verify_online on offline turret | Transaction aborts; zero events | ENVIRONMENT-BLOCKED | ALL |
| O-04 | Default path aborts when extension set | Call world's get_target_priority_list on extended turret | Abort code 7 (`EExtensionConfigured`) | ENVIRONMENT-BLOCKED | CC |

> **Evidence model:** Default path emits event with full candidate list; exclusion is implicit. Extension path requires extension to emit its own events. Abort path produces no events (evidence = tx digest + MoveAbort code only).

---

## 7. Edge Cases

| ID | Title | Steps | Expected Result | Status | Applies To |
|----|-------|-------|-----------------|--------|------------|
| X-01 | Extension overwrite | authorize_extension with different Auth on already-extended turret | Silently replaced; no event | ENVIRONMENT-BLOCKED | CC |
| X-02 | Receipt-turret mismatch | verify_online(A); pass receipt to get_target_priority_list(B) | Abort code 8 (`EInvalidOnlineReceipt`) | ENVIRONMENT-BLOCKED | ALL |
| X-03 | Unconsumed receipt | verify_online only (no consumption call) | Transaction aborts (hot potato has no drop) | ENVIRONMENT-BLOCKED | ALL |
| X-04 | destroy_online_receipt type check | Attempt with wrong Auth type | Compilation error (type constraint) | EXECUTABLE NOW | ALL |
| X-05 | Orphaned turret unanchor | `unanchor_orphan` on turret with no energy source, offline | Turret destroyed | ENVIRONMENT-BLOCKED | ALL |
| X-06 | unanchor wrong NetworkNode | unanchor with mismatched nwn | Abort code 1 | ENVIRONMENT-BLOCKED | ALL |
| X-07 | Malformed BCS candidates | Pass garbage bytes as target_candidate_list | Abort during BCS deserialization | ENVIRONMENT-BLOCKED | ALL |

---

## 8. Gate-Turret Policy Alignment

| ID | Title | Method | Expected Result | Status | Applies To |
|----|-------|--------|-----------------|--------|------------|
| A-01 | Default turret tribe-filter matches gate tribe_permit | Source comparison | Both enforce tribe-based access; turret excludes same-tribe non-aggressors; gate tribe_permit allows same-tribe only | EXECUTABLE NOW | CC |
| A-02 | authorize_extension identical pattern | Source comparison | Both use swap_or_fill on `extension: Option<TypeName>`, require OwnerCap, emit no event | EXECUTABLE NOW | CC |
| A-03 | Closed-world difference: turret vs gate | Source comparison | Gate extension PTB can include shared objects; turret extension signature is fixed by game engine | EXECUTABLE NOW | CC |
| A-04 | Default behavior = CC policy | Confirm D-01 through D-03 on localnet | Default turret = tribe_only; no custom extension needed | ENVIRONMENT-BLOCKED | CC |
| A-05 | CB/FG turret applicability | Architecture review | Bond-checking and scoring logic cannot run inside turret extension (closed-world) | STRUCTURALLY IMPOSSIBLE | CB, FG |

---

## Object Dependency Matrix

| Object | Created By | Builder-Creatable? | Used By |
|--------|------------|-------------------|---------|
| `ObjectRegistry` | World init | No (singleton) | anchor |
| `NetworkNode` | World admin | No (game infra) | anchor, online, offline, unanchor |
| `Character` | World admin | No (game-issued) | anchor, get_target_priority_list |
| `AdminACL` | World init | No (singleton) | anchor, share_turret, unanchor |
| `EnergyConfig` | World admin | No (game infra) | online, offline, unanchor |
| `OwnerCap<Turret>` | anchor | Indirectly | authorize_extension, online, offline |
| `Turret` | anchor + share_turret | Indirectly | All turret operations |

> **Implication:** 36 of 45 tests are ENVIRONMENT-BLOCKED on localnet without the full world deployment. 8 tests are EXECUTABLE NOW (publish verification P-01–P-04, source review A-01–A-03, compile check X-04). 1 test (A-05) is STRUCTURALLY IMPOSSIBLE due to turret extension closed-world constraint.

---

## BCS Encoding Reference

For constructing test `target_candidate_list` bytes:

```
TargetCandidate BCS (sequential, no per-field length prefix):
  item_id:          u64  (8 bytes LE)
  type_id:          u64  (8 bytes LE)
  group_id:         u64  (8 bytes LE)
  character_id:     u32  (4 bytes LE)
  character_tribe:  u32  (4 bytes LE)
  hp_ratio:         u64  (8 bytes LE)
  shield_ratio:     u64  (8 bytes LE)
  armor_ratio:      u64  (8 bytes LE)
  is_aggressor:     bool (1 byte: 0x00 or 0x01)
  priority_weight:  u64  (8 bytes LE)
  behaviour_change: u8   (0-3)

vector<TargetCandidate>: ULEB128 length + concatenated candidate bytes

ReturnTargetPriorityList BCS:
  target_item_id:   u64  (8 bytes LE)
  priority_weight:  u64  (8 bytes LE)
```
