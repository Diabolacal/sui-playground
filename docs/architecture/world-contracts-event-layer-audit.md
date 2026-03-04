# World-Contracts Event Layer & Observability Audit

**Retention:** Carry-forward

> Deep technical audit of all event structs and emit sites in `vendor/world-contracts/` (v0.0.15).
> Research only — no files modified.

---

## A) Complete Event Inventory

### Summary: 34 `event::emit` call sites across 10 modules, 20 distinct event struct types.

---

### Module: `world::status` (primitives/status.move)

| Event Struct | When Emitted | Fields |
|---|---|---|
| `StatusChangedEvent` | Every anchor, online, offline, unanchor of ANY assembly (Gate, SSU, Turret, Assembly, NetworkNode) | `assembly_id: ID`, `assembly_key: TenantItemId`, `status: Status` (NULL/OFFLINE/ONLINE), `action: Action` (ANCHORED/ONLINE/OFFLINE/UNANCHORED) |

**Emit sites:** 1 helper `emit_status_changed()` called from `anchor()`, `online()`, `offline()`, `unanchor()` — all `public(package)`.

**Note:** This is the **single most important event** for UI observability. Every status transition of every assembly flows through here.

---

### Module: `world::gate` (assemblies/gate.move)

| Event Struct | When Emitted | Fields |
|---|---|---|
| `GateCreatedEvent` | `anchor()` creates a new gate | `assembly_id: ID`, `assembly_key: TenantItemId`, `owner_cap_id: ID`, `type_id: u64`, `location_hash: vector<u8>`, `status: Status` |
| `GateLinkedEvent` | `link_gates()` successfully links two gates | `source_gate_id: ID`, `source_gate_key: TenantItemId`, `destination_gate_id: ID`, `destination_gate_key: TenantItemId` |
| `GateUnlinkedEvent` | `unlink()` (called by `unlink_gates` and `unlink_gates_by_admin`) | `source_gate_id: ID`, `source_gate_key: TenantItemId`, `destination_gate_id: ID`, `destination_gate_key: TenantItemId` |
| `JumpEvent` | `jump_internal()` (called by both `jump()` default and `jump_with_permit()`) | `source_gate_id: ID`, `source_gate_key: TenantItemId`, `destination_gate_id: ID`, `destination_gate_key: TenantItemId`, `character_id: ID`, `character_key: TenantItemId` |

**Emit sites:** 4 (GateCreatedEvent ×1, GateLinkedEvent ×1, GateUnlinkedEvent ×1, JumpEvent ×1).

**Key observation:** `JumpEvent` fires for BOTH default jump and extension-gated jump. This is the primary gate traversal evidence. However, there is **no event for ~~extension authorization,~~ permit issuance, or permit denial**. *(Correction 2026-03-04: v0.0.15 added `ExtensionAuthorizedEvent` to gate.move. Permit issuance and denial still have no events.)*

---

### Module: `world::storage_unit` (assemblies/storage_unit.move)

| Event Struct | When Emitted | Fields |
|---|---|---|
| `StorageUnitCreatedEvent` | `anchor()` creates a new SSU | `storage_unit_id: ID`, `assembly_key: TenantItemId`, `owner_cap_id: ID`, `type_id: u64`, `max_capacity: u64`, `location_hash: vector<u8>`, `status: Status` |

**Emit sites:** 1.

**Key observation:** SSU module itself emits only the creation event. All inventory operations (deposit, withdraw, mint, burn) are emitted by the `inventory` primitive (see below). Status changes (online/offline) go through `status.move`.

---

### Module: `world::turret` (assemblies/turret.move)

| Event Struct | When Emitted | Fields |
|---|---|---|
| `TurretCreatedEvent` | `anchor()` creates a new turret | `turret_id: ID`, `turret_key: TenantItemId`, `owner_cap_id: ID`, `type_id: u64` |
| `PriorityListUpdatedEvent` | `get_target_priority_list()` (default, non-extension path) | `turret_id: ID`, `priority_list: vector<TargetCandidate>` |

**Emit sites:** 2.

**Key observation:** `PriorityListUpdatedEvent` is only emitted by the **default** targeting function. Extension turret modules emit their own version (see extension_examples).

---

### Module: `world::assembly` (assemblies/assembly.move)

| Event Struct | When Emitted | Fields |
|---|---|---|
| `AssemblyCreatedEvent` | `anchor()` creates a generic assembly | `assembly_id: ID`, `assembly_key: TenantItemId`, `owner_cap_id: ID`, `type_id: u64` |

**Emit sites:** 1.

---

### Module: `world::network_node` (network_node/network_node.move)

| Event Struct | When Emitted | Fields |
|---|---|---|
| `NetworkNodeCreatedEvent` | `anchor()` creates a new NWN | `network_node_id: ID`, `assembly_key: TenantItemId`, `owner_cap_id: ID`, `type_id: u64`, `fuel_max_capacity: u64`, `fuel_burn_rate_in_ms: u64`, `max_energy_production: u64` |

**Emit sites:** 1.

**Key observation:** No event for NWN going online/offline directly — that routes through `status.move`'s `StatusChangedEvent`.

---

### Module: `world::character` (character/character.move)

| Event Struct | When Emitted | Fields |
|---|---|---|
| `CharacterCreatedEvent` | `create_character()` | `character_id: ID`, `key: TenantItemId`, `tribe_id: u32`, `character_address: address` |

**Emit sites:** 1.

**Key observation:** **No event for tribe change** (`update_tribe` mutates `character.tribe_id` silently). **No event for address change** (`update_address` also silent).

---

### Module: `world::access` (access/access_control.move)

| Event Struct | When Emitted | Fields |
|---|---|---|
| `OwnerCapCreatedEvent` | `create_owner_cap()` and `create_owner_cap_by_id()` | `owner_cap_id: ID`, `authorized_object_id: ID` |
| `OwnerCapTransferred` | `transfer()` (private, called by `transfer_owner_cap_to_address` and `create_and_transfer_owner_cap`) | `owner_cap_id: ID`, `authorized_object_id: ID`, `previous_owner: address`, `owner: address` |

**Emit sites:** 3 (OwnerCapCreatedEvent ×2, OwnerCapTransferred ×1).

**Key observation:** **No event for ACL membership changes** (`add_sponsor_to_acl` has no emit). No event for sponsor removal (no function exists for this).

---

### Module: `world::inventory` (primitives/inventory.move)

| Event Struct | When Emitted | Fields |
|---|---|---|
| `ItemMintedEvent` | `mint_items()` (game→chain bridge) | `assembly_id: ID`, `assembly_key: TenantItemId`, `character_id: ID`, `character_key: TenantItemId`, `item_id: u64`, `type_id: u64`, `quantity: u32` |
| `ItemDepositedEvent` | `deposit_item()` | Same fields as above |
| `ItemWithdrawnEvent` | `withdraw_item()` | Same fields as above |
| `ItemDestroyedEvent` | `delete()` (inventory destruction on unanchor) | `assembly_id: ID`, `assembly_key: TenantItemId`, `item_id: u64`, `type_id: u64`, `quantity: u32` (no character fields) |
| `ItemBurnedEvent` | `burn_items()` (chain→game bridge) | Same fields as ItemMintedEvent |

**Emit sites:** 5 (one per event type).

**Key observation:** Inventory events are **well-structured** with both assembly and character IDs for correlation. This is the most complete event coverage in the codebase.

---

### Module: `world::energy` (primitives/energy.move)

| Event Struct | When Emitted | Fields |
|---|---|---|
| `StartEnergyProductionEvent` | `start_energy_production()` (NWN goes online) | `energy_source_id: ID`, `current_energy_production: u64` |
| `StopEnergyProductionEvent` | `stop_energy_production()` (NWN goes offline) | `energy_source_id: ID` |
| `EnergyReservedEvent` | `reserve_energy()` (assembly goes online) | `energy_source_id: ID`, `assembly_type_id: u64`, `energy_reserved: u64`, `total_reserved_energy: u64` |
| `EnergyReleasedEvent` | `release_energy()` (assembly goes offline) | `energy_source_id: ID`, `assembly_type_id: u64`, `energy_released: u64`, `total_reserved_energy: u64` |

**Emit sites:** 4.

---

### Module: `world::fuel` (primitives/fuel.move)

| Event Struct | When Emitted | Fields |
|---|---|---|
| `FuelEfficiencySetEvent` | `set_fuel_efficiency()` (admin config) | `fuel_type_id: u64`, `efficiency: u64` |
| `FuelEfficiencyRemovedEvent` | `unset_fuel_efficiency()` (admin config) | `fuel_type_id: u64` |
| `FuelEvent` | Multiple: deposit, withdraw, start_burning, stop_burning, consume_fuel_units, delete | `assembly_id: ID`, `assembly_key: TenantItemId`, `type_id: u64`, `old_quantity: u64`, `new_quantity: u64`, `is_burning: bool`, `action: Action` (DEPOSITED/WITHDRAWN/BURNING_STARTED/BURNING_STOPPED/BURNING_UPDATED/DELETED) |

**Emit sites:** 8 (FuelEfficiencySetEvent ×1, FuelEfficiencyRemovedEvent ×1, FuelEvent ×6).

---

### Module: `world::metadata` (primitives/metadata.move)

| Event Struct | When Emitted | Fields |
|---|---|---|
| `MetadataChangedEvent` | `create_metadata()`, `update_name()`, `update_description()`, `update_url()` | `assembly_id: ID`, `assembly_key: TenantItemId`, `name: String`, `description: String`, `url: String` |

**Emit sites:** 1 (helper `emit_metadata_changed` called from 4 places).

---

### Module: `world::killmail` (killmail/killmail.move)

| Event Struct | When Emitted | Fields |
|---|---|---|
| `KillmailCreatedEvent` | `create_killmail()` (admin-only PvP record) | `killmail_id: TenantItemId`, `killer_character_id: TenantItemId`, `victim_character_id: TenantItemId`, `solar_system_id: TenantItemId`, `loss_type: LossType`, `kill_timestamp: u64` |

**Emit sites:** 1.

---

### Modules with NO events

| Module | Notes |
|---|---|
| `world::world` | Only GovernorCap init. No events. |
| `world::location` | Verification-only. No events. |
| `world::in_game_id` | Pure struct/helper. No events. |
| `world::object_registry` | Registry init. No events. |
| `world::sig_verify` | Crypto utility. No events. |
| `assets::EVE` | Token module. No events (Coin framework handles transfer events natively). |

---

## B) Missing Events — Critical for UI/Demo

### 1. Gate extension authorizes or denies a jump?
**NO EVENT.** ~~`authorize_extension<Auth>()` in gate.move calls `swap_or_fill` silently — no emit.~~ *(Correction 2026-03-04: v0.0.15 added `ExtensionAuthorizedEvent` — emitted by `authorize_extension()` on Gate, SSU, and Turret.)* `issue_jump_permit<Auth>()` creates a `JumpPermit` object and transfers it, but **emits no event**. Denial is a `MoveAbort` (no events on abort). The only event is `JumpEvent` which fires AFTER successful jump — it doesn't distinguish default vs. extension-gated jumps.

**Gap severity: ~~HIGH~~ MEDIUM.** Extension authorization is now observable. For CivilizationControl, there's still no on-chain event distinguishing "ally passed with permit" from "anyone jumped via default gate." The `JumpEvent` fires for both paths identically.

### 2. Extension registration (`authorize_extension`)?
~~**NO EVENT.** `authorize_extension<Auth>()` on Gate, SSU, and Turret all silently set `extension.swap_or_fill()` with no event emission.~~ *(Correction 2026-03-04: v0.0.15 added `ExtensionAuthorizedEvent` to all three assembly types. Fields: `assembly_id`, `extension_type`.)*

**Gap severity: ~~MEDIUM~~ RESOLVED.** Policy deployment is now observable via `ExtensionAuthorizedEvent`.

### 3. Toll collection?
**NO EVENT from world-contracts.** Toll is entirely a CC extension responsibility. The world-contracts gate module has no toll/fee mechanism at all (confirmed by prior research). CC extension code must emit its own toll events.

**Gap severity: N/A** (CC must implement its own).

### 4. SSU item withdrawn/deposited?
**YES — COVERED.** `ItemWithdrawnEvent` and `ItemDepositedEvent` both fire with full correlation fields (`assembly_id`, `character_id`, `type_id`, `quantity`).

### 5. Tribe changes?
**NO EVENT.** `character::update_tribe()` mutates `tribe_id` directly with no emit. The only tribe-related event is `CharacterCreatedEvent` which includes initial `tribe_id`.

**Gap severity: LOW** (tribe changes are admin-only game server operations, not player-initiated).

### 6. ACL membership changes?
**NO EVENT.** `add_sponsor_to_acl()` adds to the table silently. No removal function exists.

**Gap severity: LOW** (ACL is governor-level config, not visible in player UI).

### 7. Posture changes (online/offline)?
**YES — COVERED via `StatusChangedEvent`.** Every `online()` and `offline()` call on any assembly routes through `status.move` which emits `StatusChangedEvent` with `action: ONLINE` or `action: OFFLINE`. Full `assembly_id` and `assembly_key` included.

---

## C) Event Design Quality Assessment

### ID Correlation
- **Good:** Most events include both `assembly_id: ID` and `assembly_key: TenantItemId`, enabling correlation by both Sui object ID and in-game item ID.
- **Good:** Inventory events include both `character_id` and `character_key` for player correlation.
- **Missing:** `JumpEvent` has `character_id` but no `character_address`. You need a separate read to get the wallet address.
- **Missing:** `StatusChangedEvent` has no `owner_cap_id` — you can't tell WHO changed the status without reading the transaction sender.

### Timestamps
- **Missing from ALL events.** No event includes a timestamp field. You must rely on the transaction's `timestampMs` from the `SuiTransactionBlockResponse`. This is fine for Sui (timestamp is always in the response), but means events alone don't carry temporal data.

### JSON-RPC Filtering (`suix_queryEvents`)
- **Good:** All event structs use `has copy, drop` — they are proper Sui events filterable by `MoveEventType`.
- **Good:** Event type names are descriptive and unique per module (e.g., `world::gate::JumpEvent`, `world::status::StatusChangedEvent`).
- **Limitation:** You cannot filter by field values (e.g., "JumpEvents for gate X") using `suix_queryEvents` — you can only filter by event type. Field-level filtering requires a custom indexer or client-side post-filter.
- **Pattern:** To get all events for a specific gate, you'd filter by `MoveEventType` for the set of event types, then post-filter by `assembly_id` client-side.

### Redundant/Missing Fields
- **`StatusChangedEvent` includes both `status` (new state) and `action` (transition type).** The `action` field is technically redundant with the status transition (ONLINE status + ONLINE action always co-occur), but useful for indexing.
- **`FuelEvent` uses a polymorphic `Action` enum** — good design for a single event type covering multiple transitions.
- **`JumpEvent` is missing:** `permit_id` (was a permit used?), `extension_type` (which extension authorized it?), `timestamp_ms`. Without these, you can't reconstruct the "hostile denied" proof moment from events alone.

### State Reconstruction Without Indexer
- **Partial.** You can reconstruct: creation history, status transitions, inventory flows, energy/fuel state changes, jump history.
- **Cannot reconstruct:** Current object state (need `getObject`), extension configuration (no events), tribe assignments after creation (no events), ACL membership (no events).

---

## D) Indexer-Required vs Pollable

### Observable via Events Alone (Event Subscription / `suix_queryEvents`)
| State Change | Event | Sufficient? |
|---|---|---|
| Assembly created | `*CreatedEvent` | YES |
| Assembly online/offline | `StatusChangedEvent` | YES (action + assembly_id) |
| Gate linked/unlinked | `GateLinkedEvent` / `GateUnlinkedEvent` | YES |
| Character jumped | `JumpEvent` | YES (but no distinction default vs. permit) |
| Item minted/deposited/withdrawn/burned | `Item*Event` | YES (full fields) |
| Fuel deposited/withdrawn/burning | `FuelEvent` | YES |
| Energy reserved/released | `EnergyReservedEvent` / `EnergyReleasedEvent` | YES |
| OwnerCap created/transferred | `OwnerCap*` events | YES |
| Killmail recorded | `KillmailCreatedEvent` | YES |

### Requires Object State Reads (`devInspectTransactionBlock` or `getObject`)
| State | Why | How to Query |
|---|---|---|
| Current extension type on gate/SSU/turret | ~~No event on `authorize_extension`~~ `ExtensionAuthorizedEvent` added in v0.0.15 | `getObject` → read `extension` field, or subscribe to `ExtensionAuthorizedEvent` |
| Current inventory contents | Events give history; need snapshot for "what's in the SSU now" | `devInspectTransactionBlock` on view functions |
| Character tribe | No event on `update_tribe` | `getObject` → read `tribe_id` field |
| Gate link status | Events give history, but could be linked/unlinked since | `getObject` → read `linked_gate_id` field |
| Fuel current quantity | FuelEvent gives snapshots, but clock drift means current state needs read | `getObject` → read fuel field |
| AdminACL membership | No events at all | `getObject` → read `authorized_sponsors` table |
| EVE token balances | Standard Coin framework | `suix_getBalance` / `suix_getCoins` |

### Requires Custom Indexer
| Use Case | Why |
|---|---|
| "Show me all jumps through my gate in the last hour" | `suix_queryEvents` + client-side filter works for moderate volume; at scale, need indexer |
| "Aggregate revenue from toll collection" | Toll events come from CC extension, not world-contracts; need indexer to aggregate |
| "List all SSUs with items of type X" | No event-based way to query current inventory across multiple SSUs |
| "Dashboard of all assemblies owned by a character" | Need to correlate OwnerCap events with current state |

### Minimum Observability Path for Hackathon Demo
1. **Event Subscription:** Use `suix_subscribeEvent` with filters for `StatusChangedEvent`, `JumpEvent`, and CC extension custom events.
2. **Object Reads:** Use `getObject` for current state snapshots (extension config, inventory, tribe).
3. **Transaction Effects:** Use `sui_getTransactionBlock` with `showEvents: true` for post-hoc proof of specific transactions.
4. **No custom indexer needed** if demo uses a bounded set of known object IDs and event-type filters.

---

## E) Demo Proof Moment Gap Analysis

### Proof Moment 1: "Policy deploys on-chain"
**Action:** `authorize_extension<CCAuth>(gate, owner_cap)` + DF config writes.

**Event fired:** **NONE from `authorize_extension`.** The `StatusChangedEvent` does NOT fire (extension registration doesn't change status). No event in world-contracts marks this.

**Mitigation:** 
- CC extension code should emit a custom `PolicyDeployedEvent` when the extension is authorized.
- Alternatively, use the **transaction digest** as proof. The successful PTB that calls `authorize_extension` is itself the evidence. Read it back with `sui_getTransactionBlock`.
- Can read the gate object post-tx to confirm `extension` field is set.

**Verdict: GAP — CC must emit its own event or rely on tx digest.**

---

### Proof Moment 2: "Hostile character denied"
**Action:** Hostile character attempts jump → extension logic denies permit → `MoveAbort`.

**Event fired:** **NONE.** `MoveAbort` transactions emit no events. The abort itself is in the transaction effects (`status: failure`), but no structured event data.

**Mitigation:**
- **Negative proof path:** Query the transaction that attempted the jump → show it failed with specific error code.
- **Alternative:** CC extension could issue a "soft deny" that emits a `JumpDeniedEvent` before aborting (but this is impossible — events from aborted transactions are discarded on Sui).
- **Best approach:** Demo the *absence* of a `JumpEvent` for the hostile character while showing a successful `JumpEvent` for an ally. The contrast IS the proof.
- **Strongest approach:** Have the UI call a CC view function (`can_jump(character, gate) → bool`) and display the result before attempting the jump.

**Verdict: GAP — MoveAbort emits nothing. Must use tx failure status + contrast with permitted jump.**

---

### Proof Moment 3: "Ally tolled + revenue collected"
**Action:** Ally calls CC extension → toll deducted → permit issued → jump succeeds.

**Events fired:**
- `JumpEvent` — confirms the jump succeeded (but doesn't prove toll was paid)
- NO world-contracts event for toll/fee payment

**Mitigation:**
- CC extension MUST emit custom events: `TollCollectedEvent { gate_id, character_id, amount, token_type }`.
- For the demo, show: (1) CC custom TollCollectedEvent, (2) JumpEvent, (3) EVE balance change via `suix_getBalance`.
- The `Coin<EVE>` transfer in the PTB is visible in `objectChanges` of the transaction response.

**Verdict: GAP — CC must emit custom toll event. World-contracts provides JumpEvent only.**

---

### Proof Moment 4: "TradePost buy + item settlement"
**Action:** Buyer deposits EVE → SSU extension transfers items → items land in buyer's owned inventory.

**Events fired:**
- `ItemWithdrawnEvent` — when item leaves seller's inventory
- `ItemDepositedEvent` — when item enters buyer's owned inventory (via `deposit_to_owned`)
- **NO event for the payment side** (EVE transfer is a Coin operation, not an inventory event)

**Mitigation:**
- CC trade extension should emit: `TradeExecutedEvent { ssu_id, buyer_id, seller_id, item_type, quantity, price_eve }`.
- The `ItemWithdrawnEvent` + `ItemDepositedEvent` pair is **sufficient to prove item movement**.
- EVE payment is provable via `objectChanges` in the transaction response (Coin<EVE> objects split/transferred).
- For demo: show the pair of inventory events + the Coin changes from the same tx.

**Verdict: PARTIALLY COVERED — Inventory events prove item flow. CC must add trade price event. Payment proof via tx objectChanges.**

---

### Proof Moment 5: "Revenue visible"
**Action:** Display cumulative toll revenue.

**Query path:**
- **Simplest:** `suix_getBalance(gate_owner_address, "0x...::EVE::EVE")` — shows current EVE balance.
- **Historical:** Query CC custom `TollCollectedEvent` events via `suix_queryEvents` → sum `amount` fields.
- **On-chain aggregate:** CC could store a running total in a DF on the gate's `ExtensionConfig`. Read via `getObject` + `getDynamicFieldObject`.

**Events fired from world-contracts:** None relevant (EVE transfers are Coin framework).

**Mitigation:**
- For hackathon demo, `suix_getBalance` is instant and sufficient.
- For historical view, CC must emit `TollCollectedEvent` and client sums.
- OR store a counter DF and read it.

**Verdict: NO GAP for live balance. GAP for historical revenue timeline (CC must emit events or store DF counter).**

---

## Summary: Event Coverage Matrix

| Capability | World-Contracts Events | CC Extension Must Provide | Proof Method |
|---|---|---|---|
| Policy deployment | NONE | `PolicyDeployedEvent` recommended | tx digest + object read |
| Jump authorization (permit) | NONE (only `JumpEvent` post-jump) | `PermitIssuedEvent` recommended | JumpEvent + custom event |
| Jump denial | NONE (MoveAbort) | Cannot emit (abort discards) | tx failure status + contrast |
| Toll collection | NONE | `TollCollectedEvent` **required** | Custom event + balance check |
| Posture switch | `StatusChangedEvent` (online/offline) | Optional `PostureSwitchedEvent` for richer data | StatusChangedEvent sufficient |
| Item deposit/withdraw | `ItemDepositedEvent` / `ItemWithdrawnEvent` | None needed | Native events sufficient |
| Trade execution | Item events only | `TradeExecutedEvent` recommended | Item events + custom + objectChanges |
| Revenue query | NONE | `TollCollectedEvent` or DF counter | Balance RPC or custom event aggregation |
| Extension registration | NONE | `ExtensionRegisteredEvent` recommended | tx digest + object read |
| Tribe changes | NONE | N/A (admin operation) | Object read |

---

## Recommendations

### For Hackathon Demo (Minimum Viable Observability)

1. **CC extension MUST emit:**
   - `TollCollectedEvent { gate_id, character_id, amount }`
   - Optionally: `PermitIssuedEvent`, `PostureSwitchedEvent`, `PolicyDeployedEvent`

2. **UI subscribes to:**
   - `world::status::StatusChangedEvent` (posture changes)
   - `world::gate::JumpEvent` (jump evidence)
   - `world::inventory::ItemDepositedEvent` / `ItemWithdrawnEvent` (trade evidence)
   - CC custom events (toll, permit)

3. **Object reads for current state:**
   - Gate object → `extension` field (policy deployed?)
   - Character object → `tribe_id` (friend or foe?)
   - `suix_getBalance` → EVE balance (revenue)

4. **No custom indexer needed** for demo scale.

### For Production (Post-Hackathon)

1. Request upstream: `ExtensionRegisteredEvent` on `authorize_extension`.
2. Request upstream: `TribeChangedEvent` on `character::update_tribe`.
3. Build lightweight indexer for event aggregation (toll revenue timelines, jump analytics).
4. Consider DF-based counters for on-chain revenue aggregation (avoids indexer dependency).
