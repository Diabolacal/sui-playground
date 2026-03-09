# Turret Contract Surface Summary (world-contracts v0.0.14)

**Retention:** Carry-forward

> **Date:** 2026-03-02
> **Source:** Direct code inspection of `vendor/world-contracts/contracts/world/sources/assemblies/turret.move` (678 lines), `vendor/world-contracts/contracts/extension_examples/sources/turret.move` (65 lines), `vendor/world-contracts/contracts/world/tests/assemblies/turret_tests.move` (1098 lines).
> **Status:** Code-verified. No turret flows have been executed on localnet or testnet yet.

---

## Overview

Smart Turrets are the third assembly type in world-contracts, alongside Gates and Storage Units. Turrets control **targeting priority** -- which ships to shoot and in what order. They use the same extension pattern as gates (typed witness + `swap_or_fill`) but serve a fundamentally different purpose:

| Assembly | Extension Controls | Enforcement Model |
|----------|-------------------|-------------------|
| Gate | Permit issuance (allow/deny jump) | Binary access control (permit or no permit) |
| SSU | Deposit/withdraw access | Binary access control (authorized or not) |
| **Turret** | **Targeting priority list** | **Weighted priority (higher = shot first)** |

Turrets have **no allow/deny lists, no permits, and no explicit denial mechanism**. Enforcement is expressed purely through priority weighting.

---

## Key Types

### Turret (shared object)
```move
public struct Turret has key {
    id: UID,
    key: TenantItemId,
    owner_cap_id: ID,
    type_id: u64,
    status: AssemblyStatus,
    location: Location,
    energy_source_id: Option<ID>,
    metadata: Option<Metadata>,
    extension: Option<TypeName>,
}
```
No `uid()` accessor -- dynamic fields on Turret are inaccessible from extension packages.

### OnlineReceipt (hot potato)
```move
public struct OnlineReceipt { turret_id: ID }
```
No abilities (no key, store, drop, copy). Must be consumed in the same transaction via `destroy_online_receipt<Auth>(receipt, auth_witness)` or by the default `get_target_priority_list`.

### TargetCandidate
```move
public struct TargetCandidate has copy, drop, store {
    item_id: u64,          // target ship/NPC ID
    type_id: u64,          // ship/NPC type
    group_id: u64,         // ship group (0 for NPCs)
    character_id: u32,     // pilot character id (0 for NPCs)
    character_tribe: u32,  // pilot tribe (0 for NPCs)
    hp_ratio: u64,         // 0-100 structure HP %
    shield_ratio: u64,     // 0-100 shield %
    armor_ratio: u64,      // 0-100 armor %
    is_aggressor: bool,    // attacking anyone on grid?
    priority_weight: u64,  // initial weight from game
    behaviour_change: BehaviourChangeReason,
}
```

### ReturnTargetPriorityList
```move
public struct ReturnTargetPriorityList has copy, drop, store {
    target_item_id: u64,
    priority_weight: u64,
}
```

### BehaviourChangeReason (enum)
```move
public enum BehaviourChangeReason has copy, drop, store {
    UNSPECIFIED,    // 0
    ENTERED,        // 1 -- target entered proximity
    STARTED_ATTACK, // 2 -- target started attacking base
    STOPPED_ATTACK, // 3 -- target stopped attacking base
}
```

---

## Entry Functions

### Owner Operations (OwnerCap required)

| Function | Signature | Auth | Notes |
|----------|-----------|------|-------|
| `authorize_extension<Auth: drop>` | `(turret: &mut Turret, owner_cap: &OwnerCap<Turret>)` | OwnerCap | swap_or_fill; emits `ExtensionAuthorizedEvent` with `previous_extension` (v0.0.15+ / PR #110) |
| `online` | `(turret, network_node, energy_config, owner_cap)` | OwnerCap | Reserves energy on NetworkNode |
| `offline` | `(turret, network_node, energy_config, owner_cap)` | OwnerCap | Releases energy |

### Admin Operations (AdminACL required)

| Function | Signature | Auth | Notes |
|----------|-----------|------|-------|
| `anchor` | `(registry, network_node, character, admin_acl, item_id, type_id, location_hash, ctx) -> Turret` | AdminACL (no verify_sponsor) | Creates Turret + OwnerCap; emits TurretCreatedEvent |
| `share_turret` | `(turret, admin_acl, ctx)` | AdminACL + verify_sponsor | Makes Turret a shared object |
| `update_energy_source` | `(turret, network_node, admin_acl, ctx)` | AdminACL + verify_sponsor | Turret must be offline |

> **v0.0.15 update:** `update_energy_source` no longer requires AdminACL parameter — now callable with OwnerCap only.
| `unanchor` | `(turret, network_node, energy_config, admin_acl, ctx)` | AdminACL + verify_sponsor | Destroys turret |
| `unanchor_orphan` | `(turret, admin_acl, ctx)` | AdminACL + verify_sponsor | Turret must be offline + no energy source |

### Targeting Operations (no auth beyond OnlineReceipt)

| Function | Signature | Notes |
|----------|-----------|-------|
| `verify_online` | `(turret: &Turret): OnlineReceipt` | Returns hot potato; aborts if offline (E=2) |
| `get_target_priority_list` (default) | `(turret, owner_character, target_candidate_list_bcs, receipt): vector<u8>` | Aborts if extension configured (E=7); emits PriorityListUpdatedEvent |
| `destroy_online_receipt<Auth: drop>` | `(receipt, auth_witness)` | Extension consumes receipt with its witness |

---

## Default Targeting Rules

From `effective_weight_and_excluded()` (turret.move L662-685):

> **v0.0.17 update:** Line numbers updated (was L626-650). Owner is now excluded by `character_id` match in addition to same-tribe exclusion.

| Condition | Result |
|-----------|--------|
| Same tribe as owner AND not aggressor | **EXCLUDED** (not in return list) |
| STOPPED_ATTACK | **EXCLUDED** |
| STARTED_ATTACK | weight + 10,000 |
| ENTERED + (different tribe OR aggressor) | weight + 1,000 |
| UNSPECIFIED | weight unchanged |

Constants: `STARTED_ATTACK_WEIGHT_INCREMENT = 10000`, `ENTERED_WEIGHT_INCREMENT = 1000`.

**Key insight for CivilizationControl:** Default turret behavior IS the "tribe_only" territorial defense policy. Same-tribe non-aggressors are excluded from targeting. No custom extension needed.

---

## Events

| Event | Fields | Emitted By |
|-------|--------|------------|
| `TurretCreatedEvent` | `turret_id, turret_key, owner_cap_id, type_id` | `anchor()` |
| `PriorityListUpdatedEvent` | `turret_id, priority_list: vector<TargetCandidate>` | Default `get_target_priority_list` only |

**Missing events:** ~~`authorize_extension` emits no event (same as gate).~~ *(Correction 2026-03-04: v0.0.15 added `ExtensionAuthorizedEvent` on Gate, SSU, and Turret.)* Extension-path targeting emits no world-module event (extension must emit its own).

---

## Error Codes

| Code | Constant | Meaning |
|------|----------|---------|
| 0 | `ETurretNotAuthorized` | Wrong OwnerCap |
| 1 | `ENetworkNodeMismatch` | Turret not connected to this NetworkNode |
| 2 | `ENotOnline` | Turret is offline |
| 3 | `ETurretTypeIdEmpty` | type_id = 0 |
| 4 | `ETurretItemIdEmpty` | item_id = 0 |
| 5 | `ETurretAlreadyExists` | Duplicate item_id in registry |
| 6 | `ETurretHasEnergySource` | Energy source already connected |
| 7 | `EExtensionConfigured` | Default path called but extension is set |
| 8 | `EInvalidOnlineReceipt` | Receipt turret_id mismatch |

---

## Extension Pattern

Identical to gate extension pattern:
1. Owner calls `authorize_extension<Auth>(turret, owner_cap)` -- registers Auth type via swap_or_fill
2. Game detects extension, calls extension's `get_target_priority_list` instead of default
3. Extension calls `verify_online(turret)` to get OnlineReceipt
4. Extension processes candidates and returns BCS `vector<ReturnTargetPriorityList>`
5. Extension calls `destroy_online_receipt(receipt, AuthWitness{})` to consume hot potato

### Closed-World Constraint (Critical)

The extension function signature is **fixed by the game engine**:
```move
public fun get_target_priority_list(
    turret: &Turret,
    _: &Character,
    target_candidate_list: vector<u8>,
    receipt: OnlineReceipt,
): vector<u8>
```

The extension **cannot** access external shared objects (ExtensionConfig, policy databases, bond records). No `uid()` accessor exists on Turret, so dynamic fields are also inaccessible. Extensions are pure functions over candidate data + owner character + turret metadata.

This differs from gate extensions, where `issue_jump_permit` is called via player-constructed PTBs that CAN include additional shared objects (like ExtensionConfig).

### Security Note
Extension examples use `public fun x_auth()` (insecure). Builder-scaffold uses `public(package) fun x_auth()` (correct). Any production extension MUST use `public(package)`.

---

## Comparison with Gate

| Aspect | Gate | Turret |
|--------|------|--------|
| Purpose | Travel control | Combat targeting |
| Enforcement | Binary (permit/deny) | Weighted priority |
| Extension controls | Permit issuance | Targeting priority list |
| Linking | Two gates link to each other | No linking |
| Permit system | JumpPermit (key+store, expirable) | None |
| Default behavior (no extension) | Anyone can jump | Tribe-based priority filtering |
| Default behavior (with extension) | Jump blocked; permit required | Game calls extension's targeting function |
| Hot potato | None | OnlineReceipt |
| Can extension access external state? | Yes (player constructs PTB with shared objects) | No (game constructs call with fixed args) |
| Module initializer | Creates GateConfig (shared singleton) | No init() function |

---

## Hackathon Project Implications

| Project | Can Use Turrets? | Approach |
|---------|-----------------|----------|
| **CivilizationControl** | Partially -- default behavior matches tribe_only preset | No custom extension needed; default targeting IS the tribal defense policy |
| **CargoBond** | No -- extension can't read bond status | Turret integration deferred; gates remain sole access control |
| **Fortune Gauntlet** | No -- extension can't read gauntlet/scoring state | Turret consequence is narrative-only; cooldown + deny are the implemented consequences |

See [turret-project-semantics-and-mismatches.md](../analysis/turret-project-semantics-and-mismatches.md) for detailed mismatch analysis.

---

## Validation Status

No turret flows have been executed on localnet or testnet. See [turret-localnet-validation-checklist.md](../operations/turret-localnet-validation-checklist.md) for the full test plan (45 total: 8 executable now, 36 environment-blocked, 1 structurally impossible). See [turret-closed-world-clarified.md](turret-closed-world-clarified.md) for evidence-backed constraint analysis.
