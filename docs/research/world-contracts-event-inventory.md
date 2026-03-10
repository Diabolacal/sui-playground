# World-Contracts Complete Event Inventory

**Retention:** Prep-only

> **Generated:** 2026-03-05 UTC from direct source code inspection.
> **Source:** `vendor/world-contracts/` (v0.0.15), `vendor/builder-scaffold/`, `experiments/`, `sandbox/`.
> **Non-canonical; may become stale.** Verify against Move source before relying on specifics.
>
> Comprehensive inventory of ALL event structs and emit sites.

---

## Summary

| Scope | Event Struct Types | Emit Sites |
|---|---|---|
| `world` module (core contracts) | **30** | **36** |
| `extension_examples` | **1** | **1** |
| **Total vendor/world-contracts** | **31** | **37** |
| `experiments/` (sandbox) | 6 | 6 |
| `sandbox/` (validation tests) | ~15+ | ~20+ |

> **Correction vs. existing audit:** The prior audit ([world-contracts-event-layer-audit.md](../architecture/world-contracts-event-layer-audit.md)) states "20 distinct event struct types / 34 emit sites." The actual count is **30 event struct types / 37 emit sites** — the summary was undercounted even before the v0.0.15 `ExtensionAuthorizedEvent` additions.

---

## 1. Complete Event Table — World Contracts Core

### Module: `world::status` — [primitives/status.move](../../vendor/world-contracts/contracts/world/sources/primitives/status.move)

| # | Event Struct | Fields | Emitting Function(s) | Struct Line | Emit Line |
|---|---|---|---|---|---|
| 1 | `StatusChangedEvent` | `assembly_id: ID`, `assembly_key: TenantItemId`, `status: Status` (NULL/OFFLINE/ONLINE), `action: Action` (ANCHORED/ONLINE/OFFLINE/UNANCHORED) | `emit_status_changed()` private helper — called from `anchor()`, `online()`, `offline()`, `unanchor()` (all `public(package)`) | L34 | L109 |

**Notes:** Single most important event for UI. Every status transition of every assembly (Gate, SSU, Turret, Assembly, NWN) flows through this. 1 literal emit site, called from 4 package functions.

---

### Module: `world::gate` — [assemblies/gate.move](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move)

| # | Event Struct | Fields | Emitting Function(s) | Struct Line | Emit Line |
|---|---|---|---|---|---|
| 2 | `GateCreatedEvent` | `assembly_id: ID`, `assembly_key: TenantItemId`, `owner_cap_id: ID`, `type_id: u64`, `location_hash: vector<u8>`, `status: status::Status` | `anchor()` | L95 | L481 |
| 3 | `GateLinkedEvent` | `source_gate_id: ID`, `source_gate_key: TenantItemId`, `destination_gate_id: ID`, `destination_gate_key: TenantItemId` | `link_gates()` (inside the public function, after link validation) | L104 | L229 |
| 4 | `GateUnlinkedEvent` | `source_gate_id: ID`, `source_gate_key: TenantItemId`, `destination_gate_id: ID`, `destination_gate_key: TenantItemId` | `unlink()` private — called from `unlink_gates()` and `unlink_gates_by_admin()` | L111 | L741 |
| 5 | `JumpEvent` | `source_gate_id: ID`, `source_gate_key: TenantItemId`, `destination_gate_id: ID`, `destination_gate_key: TenantItemId`, `character_id: ID`, `character_key: TenantItemId` | `jump_internal()` private — called from both `jump()` (default) and `jump_with_permit()` | L118 | L691 |
| 6 | `ExtensionAuthorizedEvent` | `assembly_id: ID`, `assembly_key: TenantItemId`, `extension_type: TypeName`, `previous_extension: Option<TypeName>`, `owner_cap_id: ID` | `authorize_extension<Auth>()` | L127 | L141 |

**Emit sites:** 5. **Key gaps:** No event for `issue_jump_permit()` (permit issuance), no event for jump denial (MoveAbort discards events).

---

### Module: `world::storage_unit` — [assemblies/storage_unit.move](../../vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move)

| # | Event Struct | Fields | Emitting Function(s) | Struct Line | Emit Line |
|---|---|---|---|---|---|
| 7 | `StorageUnitCreatedEvent` | `storage_unit_id: ID`, `assembly_key: TenantItemId`, `owner_cap_id: ID`, `type_id: u64`, `max_capacity: u64`, `location_hash: vector<u8>`, `status: Status` | `anchor()` | L89 | L440 |
| 8 | `ExtensionAuthorizedEvent` | `assembly_id: ID`, `assembly_key: TenantItemId`, `extension_type: TypeName`, `previous_extension: Option<TypeName>`, `owner_cap_id: ID` | `authorize_extension<Auth>()` | L99 | L116 |

**Emit sites:** 2. All inventory operations (deposit, withdraw, mint, burn) are emitted by `world::inventory`.

---

### Module: `world::turret` — [assemblies/turret.move](../../vendor/world-contracts/contracts/world/sources/assemblies/turret.move)

| # | Event Struct | Fields | Emitting Function(s) | Struct Line | Emit Line |
|---|---|---|---|---|---|
| 9 | `TurretCreatedEvent` | `turret_id: ID`, `turret_key: TenantItemId`, `owner_cap_id: ID`, `type_id: u64` | `anchor()` | L121 | L456 |
| 10 | `PriorityListUpdatedEvent` | `turret_id: ID`, `priority_list: vector<TargetCandidate>` | `get_target_priority_list()` — default (non-extension) path only | L128 | L282 |
| 11 | `ExtensionAuthorizedEvent` | `assembly_id: ID`, `assembly_key: TenantItemId`, `extension_type: TypeName`, `previous_extension: Option<TypeName>`, `owner_cap_id: ID` | `authorize_extension<Auth>()` | L133 | L147 |

**Emit sites:** 3. Extension turret modules emit their own version of `PriorityListUpdatedEvent`.

---

### Module: `world::assembly` — [assemblies/assembly.move](../../vendor/world-contracts/contracts/world/sources/assemblies/assembly.move)

| # | Event Struct | Fields | Emitting Function(s) | Struct Line | Emit Line |
|---|---|---|---|---|---|
| 12 | `AssemblyCreatedEvent` | `assembly_id: ID`, `assembly_key: TenantItemId`, `owner_cap_id: ID`, `type_id: u64` | `anchor()` | L49 | L160 |

**Emit sites:** 1. Generic assembly — Gate, SSU, Turret have their own more specific creation events.

---

### Module: `world::network_node` — [network_node/network_node.move](../../vendor/world-contracts/contracts/world/sources/network_node/network_node.move)

| # | Event Struct | Fields | Emitting Function(s) | Struct Line | Emit Line |
|---|---|---|---|---|---|
| 13 | `NetworkNodeCreatedEvent` | `network_node_id: ID`, `assembly_key: TenantItemId`, `owner_cap_id: ID`, `type_id: u64`, `fuel_max_capacity: u64`, `fuel_burn_rate_in_ms: u64`, `max_energy_production: u64` | `anchor()` | L77 | L260 |

**Emit sites:** 1. No online/offline event here — routed through `StatusChangedEvent` via `status.move`.

---

### Module: `world::character` — [character/character.move](../../vendor/world-contracts/contracts/world/sources/character/character.move)

| # | Event Struct | Fields | Emitting Function(s) | Struct Line | Emit Line |
|---|---|---|---|---|---|
| 14 | `CharacterCreatedEvent` | `character_id: ID`, `key: TenantItemId`, `tribe_id: u32`, `character_address: address` | `create_character()` | L45 | L123 |

**Emit sites:** 1. **Key gaps:** No event for `update_tribe()` (L167), `update_address()` (L177), `update_tenant_id()` (L188), `delete_character()` (L196).

---

### Module: `world::access` — [access/access_control.move](../../vendor/world-contracts/contracts/world/sources/access/access_control.move)

| # | Event Struct | Fields | Emitting Function(s) | Struct Line | Emit Line |
|---|---|---|---|---|---|
| 15 | `OwnerCapCreatedEvent` | `owner_cap_id: ID`, `authorized_object_id: ID` | `create_owner_cap()` (L217), `create_owner_cap_by_id()` (L234) | L62 | L217, L234 |
| 16 | `OwnerCapTransferred` | `owner_cap_id: ID`, `authorized_object_id: ID`, `previous_owner: address`, `owner: address` | `transfer()` private — called by `transfer_owner_cap_to_address()` and `create_and_transfer_owner_cap()` | L67 | L265 |

**Emit sites:** 3 (OwnerCapCreatedEvent ×2, OwnerCapTransferred ×1). **Key gaps:** No event for `add_sponsor_to_acl()` (L228), `remove_server_address()`, or `delete_owner_cap()`.

---

### Module: `world::inventory` — [primitives/inventory.move](../../vendor/world-contracts/contracts/world/sources/primitives/inventory.move)

| # | Event Struct | Fields | Emitting Function(s) | Struct Line | Emit Line |
|---|---|---|---|---|---|
| 17 | `ItemMintedEvent` | `assembly_id: ID`, `assembly_key: TenantItemId`, `character_id: ID`, `character_key: TenantItemId`, `item_id: u64`, `type_id: u64`, `quantity: u32` | `mint_items()` (game→chain bridge) | L109 | L246 |
| 18 | `ItemBurnedEvent` | `assembly_id: ID`, `assembly_key: TenantItemId`, `character_id: ID`, `character_key: TenantItemId`, `item_id: u64`, `type_id: u64`, `quantity: u32` | `burn_items()` (chain→game bridge) | L119 | L448 |
| 19 | `ItemDepositedEvent` | `assembly_id: ID`, `assembly_key: TenantItemId`, `character_id: ID`, `character_key: TenantItemId`, `item_id: u64`, `type_id: u64`, `quantity: u32` | `deposit_item()` | L129 | L323 |
| 20 | `ItemWithdrawnEvent` | `assembly_id: ID`, `assembly_key: TenantItemId`, `character_id: ID`, `character_key: TenantItemId`, `item_id: u64`, `type_id: u64`, `quantity: u32` | `withdraw_item()` | L139 | L369 |
| 21 | `ItemDestroyedEvent` | `assembly_id: ID`, `assembly_key: TenantItemId`, `item_id: u64`, `type_id: u64`, `quantity: u32` | `delete()` (inventory destruction on unanchor) | L149 | L401 |

**Emit sites:** 5. Best-structured events in the codebase — all include both assembly and character correlation IDs (except ItemDestroyedEvent which has no character context).

---

### Module: `world::energy` — [primitives/energy.move](../../vendor/world-contracts/contracts/world/sources/primitives/energy.move)

| # | Event Struct | Fields | Emitting Function(s) | Struct Line | Emit Line |
|---|---|---|---|---|---|
| 22 | `StartEnergyProductionEvent` | `energy_source_id: ID`, `current_energy_production: u64` | `start_energy_production()` (NWN goes online) | L36 | L144 |
| 23 | `StopEnergyProductionEvent` | `energy_source_id: ID` | `stop_energy_production()` (NWN goes offline) | L41 | L154 |
| 24 | `EnergyReservedEvent` | `energy_source_id: ID`, `assembly_type_id: u64`, `energy_reserved: u64`, `total_reserved_energy: u64` | `reserve_energy()` (assembly goes online) | L45 | L176 |
| 25 | `EnergyReleasedEvent` | `energy_source_id: ID`, `assembly_type_id: u64`, `energy_released: u64`, `total_reserved_energy: u64` | `release_energy()` (assembly goes offline) | L52 | L203 |

**Emit sites:** 4.

---

### Module: `world::fuel` — [primitives/fuel.move](../../vendor/world-contracts/contracts/world/sources/primitives/fuel.move)

| # | Event Struct | Fields | Emitting Function(s) | Struct Line | Emit Line |
|---|---|---|---|---|---|
| 26 | `FuelEvent` | `assembly_id: ID`, `assembly_key: TenantItemId`, `type_id: u64`, `old_quantity: u64`, `new_quantity: u64`, `is_burning: bool`, `action: Action` (DEPOSITED/WITHDRAWN/BURNING_STARTED/BURNING_STOPPED/BURNING_UPDATED/DELETED) | `deposit()` (L242), `withdraw()` (L266), `start_burning()` (L298), `stop_burning()` (L337), `delete()` (L355), `consume_fuel_units()` (L427) | L74 | L242, L266, L298, L337, L355, L427 |
| 27 | `FuelEfficiencySetEvent` | `fuel_type_id: u64`, `efficiency: u64` | `set_fuel_efficiency()` (admin config) | L84 | L165 |
| 28 | `FuelEfficiencyRemovedEvent` | `fuel_type_id: u64` | `unset_fuel_efficiency()` (admin config) | L89 | L181 |

**Emit sites:** 8 (FuelEvent ×6, FuelEfficiencySetEvent ×1, FuelEfficiencyRemovedEvent ×1). `FuelEvent` uses polymorphic `Action` enum — effective pattern for consolidated fuel state tracking.

---

### Module: `world::metadata` — [primitives/metadata.move](../../vendor/world-contracts/contracts/world/sources/primitives/metadata.move)

| # | Event Struct | Fields | Emitting Function(s) | Struct Line | Emit Line |
|---|---|---|---|---|---|
| 29 | `MetadataChangedEvent` | `assembly_id: ID`, `assembly_key: TenantItemId`, `name: String`, `description: String`, `url: String` | `emit_metadata_changed()` private helper — called from `create_metadata()`, `update_name()`, `update_description()`, `update_url()` | L21 | L88 |

**Emit sites:** 1 (helper called from 4 places).

---

### Module: `world::killmail` — [killmail/killmail.move](../../vendor/world-contracts/contracts/world/sources/killmail/killmail.move)

| # | Event Struct | Fields | Emitting Function(s) | Struct Line | Emit Line |
|---|---|---|---|---|---|
| 30 | `KillmailCreatedEvent` | `killmail_id: TenantItemId`, `killer_character_id: TenantItemId`, `victim_character_id: TenantItemId`, `solar_system_id: TenantItemId`, `loss_type: LossType`, `kill_timestamp: u64` | `create_killmail()` (admin-only) | L55 | L100 |

> **Outdated (v0.0.17):** `KillmailCreatedEvent` fields renamed: `killmail_id`→`key`, `killer_character_id`→`killer_id`, `victim_character_id`→`victim_id`. New field: `reported_by_character_id`. New `KillmailRegistry` module + `create_killmail` signature changed. New event #31: `MetadataChangedEvent` in `metadata.move`. Full re-inventory recommended.

**Emit sites:** 1. Only event with `solar_system_id` (spatial context).

---

### Modules with NO events

| Module | File | Notes |
|---|---|---|
| `world::world` | `sources/world.move` | Only GovernorCap init |
| `world::location` | `sources/primitives/location.move` | Verification-only helpers |
| `world::in_game_id` | `sources/primitives/in_game_id.move` | Pure struct/helper |
| `world::object_registry` | `sources/object_registry.move` | Registry init |
| `world::sig_verify` | `sources/primitives/sig_verify.move` | Crypto utility |
| `assets::EVE` | `contracts/assets/sources/EVE.move` | Token module (Coin framework handles transfer events natively) |

---

## 2. Extension Examples Events

### Module: `extension_examples::turret` — [extension_examples/sources/turret.move](../../vendor/world-contracts/contracts/extension_examples/sources/turret.move)

| # | Event Struct | Fields | Emitting Function(s) | Struct Line | Emit Line |
|---|---|---|---|---|---|
| 31 | `PriorityListUpdatedEvent` | `turret_id: ID`, `priority_list: vector<u8>` (note: `vector<u8>` BCS, not `vector<TargetCandidate>` like the world version) | `get_target_priority_list()` | L19 | L59 |

### No events in these extension examples:

| Module | File | Notes |
|---|---|---|
| `extension_examples::tribe_permit` | `sources/tribe_permit.move` | Issues `JumpPermit` via `gate::issue_jump_permit<XAuth>()` — no custom event |
| `extension_examples::corpse_gate_bounty` | `sources/corpse_gate_bounty.move` | Calls `deposit_item`/`withdraw_by_owner`/`issue_jump_permit` — no custom event |
| `extension_examples::config` | `sources/config.move` | Config/admin helpers — no events |

---

## 3. Builder-Scaffold Events

### `vendor/builder-scaffold/move-contracts/smart_gate/` *(renamed to `smart_gate_extension/` in scaffold v3c65b22, 2026-03-10)*

**No events emitted.** The builder-scaffold versions of `tribe_permit.move` and `corpse_gate_bounty.move` contain only `copy, drop, store` key structs (`TribeConfigKey`, `BountyConfigKey`) — no `event::emit` calls. They rely entirely on world-contracts events.

---

## 4. Experiments Events

### Module: `atomic_courier_experiment::atomic_transfer` — [experiments/atomic_courier_experiment/sources/atomic_transfer.move](../../experiments/atomic_courier_experiment/sources/atomic_transfer.move)

| Event Struct | Fields | Emitting Function | Struct Line | Emit Line |
|---|---|---|---|---|
| `AtomicTransferEvent` | `source_ssu_id: ID`, `dest_ssu_id: ID`, `character_id: ID`, `item_type_id: u64`, `reward_amount: u64`, `courier: address` | `atomic_transfer_test()` | L19 | L73 |

### Module: `atomic_courier_experiment::courier_escrow` — [experiments/atomic_courier_experiment/sources/courier_escrow.move](../../experiments/atomic_courier_experiment/sources/courier_escrow.move)

| Event Struct | Fields | Emitting Function | Struct Line | Emit Line |
|---|---|---|---|---|
| `JobPostedEvent` | `job_id: ID`, `creator: address`, `reward_amount: u64`, `collateral_required: u64`, `deadline_ms: u64` | `post_job()` | L76 | L141 |
| `JobAcceptedEvent` | `job_id: ID`, `courier: address`, `collateral_amount: u64` | `accept_job()` | L84 | L191 |
| `JobCompletedEvent` | `job_id: ID`, `creator: address`, `courier: address`, `reward_amount: u64`, `collateral_returned: u64` | `complete_job()` | L90 | L236 |
| `JobExpiredEvent` | `job_id: ID`, `creator: address`, `courier: address`, `collateral_slashed: u64`, `reward_returned: u64`, `caller: address` | `claim_expired()` | L98 | L286 |
| `JobCancelledEvent` | `job_id: ID`, `creator: address`, `reward_returned: u64` | `cancel_job()` | L107 | L323 |

---

## 5. Sandbox Validation Events (Summary)

These are test/mock events in sandbox validation packages. Not production.

### `sandbox/validation/gate_toll_validation/sources/gate_toll.move`

| Event Struct | Fields | Notes |
|---|---|---|
| `GateCreated` | `gate_id: address`, `owner: address` | Mock gate creation |
| `TribeRuleSet` | `gate_id: address`, `allowed_tribe: u32` | Mock tribe config |
| `TollRuleSet` | `gate_id: address`, `price: u64` | Mock toll config |
| `TollPaid` | `gate_id: address`, `traveler: address`, `amount: u64` | Mock toll payment |
| `AccessGranted` | `gate_id: address`, `character_id: address`, `traveler: address` | Mock access granted |
| `AccessDenied` | `gate_id: address`, `character_id: address`, `reason: vector<u8>` | Mock access denied |

### `sandbox/validation/trade_post_validation/sources/mock_ssu.move`

| Event Struct | Fields | Notes |
|---|---|---|
| `SSUCreated` | `ssu_id: address`, `owner: address` | Mock SSU |
| `ExtensionAuthorized` | `ssu_id: address`, `extension_type: vector<u8>` | Mock extension auth |
| `ItemDeposited` | `ssu_id: address`, `item_type: u64`, `quantity: u64` | Mock deposit |
| `ItemWithdrawn` | `ssu_id: address`, `item_type: u64`, `quantity: u64` | Mock withdraw |

### `sandbox/validation/trade_post_validation/sources/ssu_trade.move`

| Event Struct | Fields | Notes |
|---|---|---|
| `ListingCreated` | `listing_id: ID`, `seller: address`, `item_type: u64`, `quantity: u64`, `price_per_unit: u64` | Mock listing |
| `ItemPurchased` | `listing_id: ID`, `buyer: address`, `item_type: u64`, `quantity: u64`, `total_price: u64` | Mock purchase |
| `ListingCancelled` | `listing_id: ID`, `seller: address` | Mock cancel |

### `sandbox/validation/zk_gate/sources/zk_gate.move`

| Event Struct | Fields | Notes |
|---|---|---|
| `ZKVerificationResult` | `success: bool`, `signal_0: u64`, `message: vector<u8>` | ZK proof validation |
| `ZKAuthIssued` | `root_bytes_len: u64` | ZK auth token |
| `AuthConsumed` | `message: vector<u8>` | ZK auth consumed |
| `CompositionResult` | `success: bool`, `message: vector<u8>` | ZK composition test |

### `sandbox/validation/zk_gatepass_validation/sources/groth16_test.move`

| Event Struct | Fields | Notes |
|---|---|---|
| `VerificationResult` | `verified: bool`, `message: vector<u8>` | Groth16 verification |
| `GasMeasurement` | `step: vector<u8>` | Gas profiling |

---

## 6. Important Actions WITHOUT Events (Gaps)

### Critical for CivilizationControl

| Action | Module | Function | Line | Gap Severity | CC Impact |
|---|---|---|---|---|---|
| **Permit issuance** | `world::gate` | `issue_jump_permit<Auth>()` | L258–L295 | **HIGH** | No way to distinguish "permit issued" from "jump completed". CC must emit custom `PermitIssuedEvent`. |
| **Jump denial** | `world::gate` | Any abort in extension logic | N/A | **HIGH** | `MoveAbort` discards all events. Cannot emit denial events on Sui. Must use tx failure status + contrast approach. |
| **Tribe change** | `world::character` | `update_tribe()` | L167 | LOW | Admin-only operation. No player-facing event. Need `getObject` to read current tribe. |
| **Address change** | `world::character` | `update_address()` | L177 | LOW | Admin-only operation. |
| **Character deletion** | `world::character` | `delete_character()` | L196 | LOW | Admin-only. |
| **ACL membership add** | `world::access` | `add_sponsor_to_acl()` | L228 | LOW | Governor-level config, not player-visible. |
| **OwnerCap deletion** | `world::access` | `delete_owner_cap()` | L269 | LOW | Admin cleanup operation. |
| **Toll/fee payment** | N/A | No native mechanism | N/A | **N/A** | Toll is entirely a CC extension responsibility. No world-contracts toll mechanism exists. |

### Lower Priority Gaps

| Action | Module | Function | Notes |
|---|---|---|---|
| Tenant ID update | `world::character` | `update_tenant_id()` | Emergency admin function |
| Server address registration | `world::access` | `register_server_address()` / `remove_server_address()` | Governor-level config |
| Gate config (max distance by type) | `world::gate` | init/admin functions | One-time config |
| Energy config updates | `world::energy` | `set_energy_config()` / `remove_energy_config()` | Admin config |

---

## 7. Events Lacking Spatial Identifiers

Most events reference assemblies by `assembly_id` / `assembly_key` (TenantItemId) but do NOT include explicit spatial data (solar system, location hash, coordinates). Spatial context must be resolved by reading the assembly object.

| Event | Has Spatial Data? | Notes |
|---|---|---|
| `GateCreatedEvent` | **YES** — `location_hash: vector<u8>` | Only creation-time location |
| `StorageUnitCreatedEvent` | **YES** — `location_hash: vector<u8>` | Only creation-time location |
| `KillmailCreatedEvent` | **YES** — `solar_system_id: TenantItemId` | Best spatial data of any event |
| `NetworkNodeCreatedEvent` | **NO** | Has `assembly_key` only; location is in the object |
| `JumpEvent` | **NO** | Has gate IDs but no location — resolve via gate objects |
| `StatusChangedEvent` | **NO** | Assembly ID only |
| All inventory events | **NO** | Assembly ID + character ID; resolve via SSU object for location |
| All fuel/energy events | **NO** | `assembly_id` or `energy_source_id` only |
| `MetadataChangedEvent` | **NO** | Assembly ID only |
| All `ExtensionAuthorizedEvent` | **NO** | Assembly ID only |
| `OwnerCap*` events | **NO** | Object IDs only |

**Summary:** Only 3 of 30 event types include spatial data. All others require an object read to determine location. For a UI dashboard, maintain a local cache of `assembly_id → location` from creation events and object reads.

---

## 8. Differences from Existing Audit

Compared to [world-contracts-event-layer-audit.md](../architecture/world-contracts-event-layer-audit.md):

### Summary Count Correction
| Metric | Old Audit States | Actual (Verified) |
|---|---|---|
| Distinct event struct types | 20 | **30** (27 pre-v0.0.15 + 3 ExtensionAuthorizedEvent) |
| Emit sites | 34 | **37** (33 pre-v0.0.15 + 3 ExtensionAuthorizedEvent emits + 1 extension_examples) |

The old summary of "20 types / 34 sites" undercounted the types even at the time of writing. The detailed body of the audit correctly lists all events but the summary number was never accurate.

### v0.0.15 Additions (Already Noted as Corrections in Old Audit)
The existing audit has inline corrections (dated 2026-03-04) noting `ExtensionAuthorizedEvent` was added. These corrections are accurate:
- `world::gate::ExtensionAuthorizedEvent` — L127/L141
- `world::storage_unit::ExtensionAuthorizedEvent` — L99/L116
- `world::turret::ExtensionAuthorizedEvent` — L133/L147

### Field-Level Differences
- **`ExtensionAuthorizedEvent`** includes `previous_extension: Option<TypeName>` — not noted in some old audit corrections. This field enables tracking extension replacement, not just initial registration.
- **`FuelEvent`** Action enum now includes `DELETED` variant — consistent with what the old audit documents.
- **No other field changes detected** between the old audit's listed fields and current source.

### Gap Analysis Remains Accurate
The old audit's gap analysis (Section B) remains correct with its inline corrections:
- ~~No ExtensionAuthorizedEvent~~ → RESOLVED in v0.0.15
- No PermitIssuedEvent → STILL MISSING
- No tribe change event → STILL MISSING
- No ACL change event → STILL MISSING
- No toll/fee mechanism → STILL TRUE (CC must implement)
- MoveAbort emits nothing → STILL TRUE (Sui platform constraint)

---

## 9. CC-Relevant Event Quick Reference

### Events CC should subscribe to for demo/production:

| Event | Module | Why |
|---|---|---|
| `StatusChangedEvent` | `world::status` | Posture changes (online/offline for all assemblies) |
| `JumpEvent` | `world::gate` | Gate traversal evidence — both default and with-permit |
| `ExtensionAuthorizedEvent` | `world::gate` | Policy deployment confirmation |
| `ExtensionAuthorizedEvent` | `world::storage_unit` | Trade extension registration |
| `ItemDepositedEvent` | `world::inventory` | Trade settlement, item delivery |
| `ItemWithdrawnEvent` | `world::inventory` | Trade item extraction |
| `GateLinkedEvent` / `GateUnlinkedEvent` | `world::gate` | Gate topology changes |
| `OwnerCapCreatedEvent` | `world::access` | New assembly ownership (bootstrapping) |

### Custom events CC extension MUST emit:

| Event | Purpose | Minimum Fields |
|---|---|---|
| `TollCollectedEvent` | Prove toll was paid before jump | `gate_id: ID`, `character_id: ID`, `amount: u64`, `token_type: TypeName` |
| `PermitIssuedEvent` | Prove permit was issued (world-contracts does not emit) | `gate_id: ID`, `character_id: ID`, `tribe_id: u32`, `expires_ms: u64` |

### Custom events CC extension SHOULD emit (recommended):

| Event | Purpose |
|---|---|
| `PostureSwitchedEvent` | Rich posture change data beyond individual StatusChangedEvent per assembly |
| `PolicyDeployedEvent` | Semantic event for "CC extension installed on gate" |
| `TradeExecutedEvent` | Trade price/quantity beyond native inventory events |

---

## 10. Cross-Reference: `event::emit` by File

Quick lookup — every literal `event::emit` call with line number:

```
access/access_control.move    L217  OwnerCapCreatedEvent      (create_owner_cap)
access/access_control.move    L234  OwnerCapCreatedEvent      (create_owner_cap_by_id)
access/access_control.move    L265  OwnerCapTransferred       (transfer — private)
assemblies/assembly.move      L160  AssemblyCreatedEvent      (anchor)
assemblies/gate.move          L141  ExtensionAuthorizedEvent  (authorize_extension)
assemblies/gate.move          L229  GateLinkedEvent           (link_gates)
assemblies/gate.move          L481  GateCreatedEvent          (anchor)
assemblies/gate.move          L691  JumpEvent                 (jump_internal — private)
assemblies/gate.move          L741  GateUnlinkedEvent         (unlink — private)
assemblies/storage_unit.move  L116  ExtensionAuthorizedEvent  (authorize_extension)
assemblies/storage_unit.move  L440  StorageUnitCreatedEvent   (anchor)
assemblies/turret.move        L147  ExtensionAuthorizedEvent  (authorize_extension)
assemblies/turret.move        L282  PriorityListUpdatedEvent  (get_target_priority_list)
assemblies/turret.move        L456  TurretCreatedEvent        (anchor)
character/character.move      L123  CharacterCreatedEvent     (create_character)
killmail/killmail.move        L100  KillmailCreatedEvent      (create_killmail)
network_node/network_node.move L260 NetworkNodeCreatedEvent   (anchor)
primitives/energy.move        L144  StartEnergyProductionEvent (start_energy_production)
primitives/energy.move        L154  StopEnergyProductionEvent  (stop_energy_production)
primitives/energy.move        L176  EnergyReservedEvent        (reserve_energy)
primitives/energy.move        L203  EnergyReleasedEvent        (release_energy)
primitives/fuel.move          L165  FuelEfficiencySetEvent     (set_fuel_efficiency)
primitives/fuel.move          L181  FuelEfficiencyRemovedEvent (unset_fuel_efficiency)
primitives/fuel.move          L242  FuelEvent                  (deposit)
primitives/fuel.move          L266  FuelEvent                  (withdraw)
primitives/fuel.move          L298  FuelEvent                  (start_burning)
primitives/fuel.move          L337  FuelEvent                  (stop_burning)
primitives/fuel.move          L355  FuelEvent                  (delete)
primitives/fuel.move          L427  FuelEvent                  (consume_fuel_units — private)
primitives/inventory.move     L246  ItemMintedEvent            (mint_items)
primitives/inventory.move     L323  ItemDepositedEvent         (deposit_item)
primitives/inventory.move     L369  ItemWithdrawnEvent         (withdraw_item)
primitives/inventory.move     L401  ItemDestroyedEvent         (delete)
primitives/inventory.move     L448  ItemBurnedEvent            (burn_items — private)
primitives/metadata.move      L88   MetadataChangedEvent       (emit_metadata_changed — private)
primitives/status.move        L109  StatusChangedEvent         (emit_status_changed — private)
--- extension_examples ---
extension_examples/turret.move L59  PriorityListUpdatedEvent   (get_target_priority_list)
```

**Total: 36 emit sites in world module + 1 in extension_examples = 37**
