# Fortune Gauntlet — Feasibility Analysis

**Retention:** Prep-only

Feasibility validation for a "Fortune Gauntlet" concept: sequential multi-gate checkpoint race with probabilistic permit issuance using Sui on-chain randomness.

**Date:** 2026-03-02  
**Inputs:** `vendor/world-contracts` (gate.move, assemblies), `vendor/builder-scaffold` (smart_gate extensions), Sui documentation reference map  
**Method:** Direct code inspection with line-level citations

---

## Executive Summary

The Fortune Gauntlet concept is **largely feasible** using current world-contracts surfaces. The core race mechanic (sequential gate traversal with time pressure) maps cleanly to existing primitives. Probabilistic permit issuance requires Sui's `Random` module, which imposes an `entry` function constraint that is compatible with the extension architecture. The main gap is consequence mechanics: turrets exist (v0.0.14) but their closed-world extension constraint prevents gauntlet state from reaching targeting logic. Credible proxies (cooldown, deny list, denial events) remain the correct approach.

| Capability | Verdict | Notes |
|---|---|---|
| Probabilistic permit issuance | ⚠️ Feasible with workaround | `entry` function constraint; compatible |
| Checkpoint progress tracking | ✅ Feasible now | Events + DFs for on-chain state |
| Consequence mechanics (turrets) | ❌ Not feasible (gauntlet-aware) | Turret extensions exist (v0.0.14) but closed-world constraint prevents gauntlet state access. Tribe-based targeting is the default — no FG-specific integration possible. ~~Previously "Partially feasible" — since corrected.~~ (Updated 2026-03-02.) |
| Consequence mechanics (proxy) | ⚠️ Feasible with workaround | DF-based cooldown + deny list |
| Multi-gate configuration | ✅ Feasible now | Per-package ExtensionConfig + per-gate DF keys |
| Time pressure via permit expiry | ✅ Feasible now | `expires_at_timestamp_ms` + `Clock` |

---

## 1. Randomness at Permit-Issue Time

### Current State

**No randomness usage exists** in world-contracts or builder-scaffold. Zero hits for `random`, `Random`, or `randomness` across all `.move` files in both submodules.

### `issue_jump_permit` Signature

From [gate.move](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L244-L278):

```move
public fun issue_jump_permit<Auth: drop>(
    source_gate: &Gate,
    destination_gate: &Gate,
    character: &Character,
    _: Auth,
    expires_at_timestamp_ms: u64,
    ctx: &mut TxContext,
)
```

Key observations:
- `public fun` (not `entry`) — callable from extension code
- Requires `Auth: drop` witness — minted by extension's `public(package) fun x_auth()`
- The function internally calls `transfer::transfer(jump_permit, character.character_address())` — no return value
- No AdminACL or OwnerCap required

### Can an Extension Incorporate `sui::random`?

**Yes — ⚠️ feasible with workaround.**

Sui's `Random` shared object (address `0x8`) requires special calling conventions per [Sui docs](https://docs.sui.io/guides/developer/on-chain-primitives/randomness-onchain):
- Functions that take `&Random` must be `entry` functions
- Cannot compose `&Random` in arbitrary PTB command chains

From [sui-documentation-reference-map.md](../research/sui-documentation-reference-map.md#L142-L147):
> Must use special `entry` function signature that takes `&Random`. Cannot be composed in arbitrary PTB flows.

**Architecture:**

```move
entry fun try_issue_permit(
    random: &Random,
    extension_config: &ExtensionConfig,
    source_gate: &Gate,
    destination_gate: &Gate,
    character: &Character,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // Read race config from DFs
    let checkpoint_cfg = extension_config.borrow_rule<CheckpointKey, CheckpointConfig>(...);

    // Generate random number
    let mut gen = random::new_generator(random, ctx);
    let roll = gen.generate_u8_in_range(1, 100);

    if (roll <= checkpoint_cfg.success_threshold) {
        // SUCCESS: Issue permit
        let ts = clock.timestamp_ms();
        let expires_at = ts + checkpoint_cfg.permit_expiry_ms;
        gate::issue_jump_permit<XAuth>(
            source_gate, destination_gate, character,
            config::x_auth(), expires_at, ctx,
        );
    } else {
        // DENIAL: Set cooldown, emit event
        // (detailed in §3 Consequence Mechanics)
    }
}
```

**Why `entry` works here:**
- `gate::issue_jump_permit` transfers the permit internally via `transfer::transfer` — no return value needed
- The denial path emits events and writes DFs — also no return value
- Since nothing is returned, the `entry` constraint does not break composability

**Constraint:** This function becomes the sole PTB command for permit requests — it cannot be chained with other MoveCall commands in the same PTB that depend on its outputs. This is acceptable for the race mechanic since permit issuance is a self-contained action.

**Verdict: ⚠️ Feasible with workaround** — `entry` function constraint is compatible with the extension pattern. The workaround (using `entry` instead of `public`) is minor and standard for any `Random`-consuming function on Sui.

---

## 2. Checkpoint Progress Tracking

### Permits as Checkpoint Proof

From [gate.move](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L82-L91), `JumpPermit` contains:

```move
public struct JumpPermit has key, store {
    id: UID,
    character_id: ID,
    route_hash: vector<u8>,
    expires_at_timestamp_ms: u64,
}
```

- `route_hash` binds the permit to a specific (source, destination) gate pair
- `character_id` binds it to a specific player
- `expires_at_timestamp_ms` provides time-bounding
- **Single-use:** consumed (object deleted) by `validate_jump_permit` at [gate.move#L693-L714](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L693-L714)

**Assessment:** A permit proves the player was granted passage at checkpoint N. However, permits are consumed on jump — they cannot serve as persistent proof of past checkpoints. Only the most recent outstanding permit exists as an object.

**Verdict: ⚠️ Partial** — permits prove current checkpoint eligibility, not historical progress.

### Events for Off-Chain Progress Tracking

Four event types in gate.move ([lines 95-126](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L95-L126)):

| Event | Fields | Emitted When |
|---|---|---|
| `GateCreatedEvent` | assembly_id, key, owner_cap_id, type_id, location_hash, status | Gate anchored |
| `GateLinkedEvent` | source_gate_id/key, destination_gate_id/key | Gates linked |
| `GateUnlinkedEvent` | source_gate_id/key, destination_gate_id/key | Gates unlinked |
| `JumpEvent` | source_gate_id/key, destination_gate_id/key, character_id/key | Player jumps |

`JumpEvent` ([gate.move#L118-L126](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L118-L126)) includes `character_id` and both gate IDs — sufficient for an off-chain indexer to reconstruct the full race timeline.

Additionally, the extension can emit **custom events** for richer tracking:

```move
public struct CheckpointPassedEvent has copy, drop {
    character_id: ID,
    gate_id: ID,
    checkpoint_number: u8,
    roll: u8, // the random roll
    timestamp_ms: u64,
}

public struct CheckpointDeniedEvent has copy, drop {
    character_id: ID,
    gate_id: ID,
    checkpoint_number: u8,
    roll: u8,
    cooldown_until_ms: u64,
}
```

**Verdict: ✅ Feasible now** — `JumpEvent` + custom extension events provide complete off-chain race timeline.

### On-Chain Progress Tracking via Dynamic Fields

ExtensionConfig ([config.move#L10-L12](../../../vendor/builder-scaffold/move-contracts/smart_gate/sources/config.move#L10-L12)) is a shared singleton:

```move
public struct ExtensionConfig has key {
    id: UID,
}
```

The builder-scaffold DF helper pattern ([config.move#L41-L85](../../../vendor/builder-scaffold/move-contracts/smart_gate/sources/config.move#L41-L85)) supports typed key/value pairs. Per-player progress state:

```move
/// Key: player-specific progress record
public struct PlayerProgressKey has copy, drop, store {
    character_id: ID,
}

/// Value: race state for this player
public struct PlayerProgress has store, drop {
    last_checkpoint: u8,
    last_checkpoint_timestamp_ms: u64,
    denial_count: u8,
    cooldown_until_ms: u64,
}
```

Each player's state is a separate dynamic field on ExtensionConfig. The extension reads/writes this state during `try_issue_permit`.

**Scalability note:** Each DF is a separate Sui object (~100-200 bytes). For a hackathon demo with <100 players, this is fine. At scale (10,000+ players), DF proliferation on a single shared object could cause consensus contention. Not a concern for demo scope.

**Checkpoint sequence enforcement:**

```move
// In try_issue_permit:
let progress = if (extension_config.has_rule<PlayerProgressKey>(key)) {
    extension_config.borrow_rule_mut<PlayerProgressKey, PlayerProgress>(&admin_cap, key)
} else {
    // First checkpoint — create initial progress
    extension_config.add_rule<PlayerProgressKey, PlayerProgress>(&admin_cap, key, default_progress);
    extension_config.borrow_rule_mut(...)
};

// Enforce sequential order
assert!(progress.last_checkpoint == expected_checkpoint - 1, EOutOfSequence);
```

**Problem:** `borrow_rule_mut` requires `&AdminCap` in the current builder-scaffold pattern. However, for the extension's own `try_issue_permit` function (which is `public(package)` or `entry`), the extension module has internal access to write DFs directly using `df::borrow_mut(&mut config.id, key)` — bypassing the AdminCap check for its own internal state management.

**Verdict: ✅ Feasible now** — DF-based per-player progress tracking works. Extension code has internal DF access.

---

## 3. Consequence Mechanics

### Turret Availability

**⚠️ Turret assembly exists but with closed-world constraint.** (Updated 2026-03-02 after turret support confirmed in world-contracts v0.0.14.)

World-contracts now has four assembly modules ([assemblies/ directory](../../../vendor/world-contracts/contracts/world/sources/assemblies/)):
1. `world::assembly` -- base assembly type
2. `world::gate` -- gate travel
3. `world::storage_unit` -- item storage
4. `world::turret` -- defensive targeting (678 lines)

Turret extensions follow the same `authorize_extension<Auth>` + `swap_or_fill` pattern as Gate. However, the extension's `get_target_priority_list` function has a fixed 4-argument signature and **cannot access external state** (no `uid()` accessor, no DF reads). Default targeting applies tribe-based filtering.

**Consequence for Fortune Gauntlet:** Gauntlet denial state (cooldown, denial count) stored in ExtensionConfig DFs cannot be read by turret extensions at targeting time. The `GauntletDenialEvent` approach (emit events for off-chain indexing) remains the correct audit trail.

**Verdict: ❌ Not feasible (gauntlet-aware)** — turret extensions exist but the closed-world constraint prevents gauntlet state from reaching them. Default tribe-based targeting operates independently and requires no integration. ~~Previously "⚠️ Partially feasible" — since corrected.~~

### Proxy Consequence Mechanisms

All proxy consequences below are implemented via dynamic fields on ExtensionConfig:

#### A. Temporary Cooldown (DF Timestamp) — ⚠️ Feasible

```move
public struct CooldownKey has copy, drop, store { character_id: ID }
public struct CooldownEntry has store, drop { until_ms: u64 }
```

On denial:
```move
let cooldown_ms = checkpoint_cfg.cooldown_duration_ms; // e.g., 30 seconds
let until = clock.timestamp_ms() + cooldown_ms;
df::add(&mut config.id, CooldownKey { character_id }, CooldownEntry { until_ms: until });
```

On next attempt:
```move
if (df::exists_(&config.id, CooldownKey { character_id })) {
    let entry: &CooldownEntry = df::borrow(&config.id, CooldownKey { character_id });
    assert!(clock.timestamp_ms() >= entry.until_ms, EOnCooldown);
    // Cooldown expired — remove entry
    let _: CooldownEntry = df::remove(&mut config.id, CooldownKey { character_id });
}
```

**Verdict: ⚠️ Feasible with workaround** — works within the extension module's DF access. The "workaround" is that cleanup of expired cooldowns requires either player re-attempt or an admin sweep.

#### B. Deny List (DF) — ⚠️ Feasible

Same pattern as cooldown but with a flag-based check:

```move
public struct DenyKey has copy, drop, store { character_id: ID }
public struct DenyEntry has store, drop { until_ms: u64, reason: u8 }
```

Can be combined with cooldown into a single `PlayerProgress` struct (§2 above) to avoid DF proliferation:

```move
public struct PlayerProgress has store, drop {
    last_checkpoint: u8,
    denial_count: u8,
    cooldown_until_ms: u64,   // 0 = no cooldown
    denied: bool,             // permanent deny (e.g., 3 strikes)
}
```

**Verdict: ⚠️ Feasible** — deny list is just a boolean flag in per-player state.

#### C. Time Penalty (Extended Permit Expiry) — ✅ Feasible

On denial, instead of blocking entirely, issue a permit with an extended expiry window — the player must wait before jumping:

```move
if (roll <= success_threshold) {
    // Normal expiry (e.g., 60 seconds)
    let expires_at = ts + normal_expiry_ms;
    gate::issue_jump_permit<XAuth>(..., expires_at, ctx);
} else {
    // Penalty expiry (e.g., 300 seconds — forced wait)
    let expires_at = ts + penalty_expiry_ms;
    gate::issue_jump_permit<XAuth>(..., expires_at, ctx);
}
```

**Wait — this doesn't actually force waiting.** `expires_at_timestamp_ms` is an *upper bound*, not a lower bound. The permit is valid immediately and expires at the timestamp. There is no "valid_from" field in JumpPermit.

**Revised approach:** On denial, do NOT issue a permit. Instead, record a cooldown timestamp in the DF. The player must wait for the cooldown to expire before they can attempt again. This is the cooldown pattern from (A) above.

**Verdict: ❌ Time penalty via permit expiry does not work** (no `valid_from` field). Use cooldown DF instead.

#### D. "Mark" Event (Off-Chain Signal) -- ✅ Feasible

(Updated 2026-03-02: Turrets now exist but the closed-world constraint means extensions cannot read external state. Events remain the correct integration path.)

```move
public struct GauntletDenialEvent has copy, drop {
    character_id: ID,
    character_key: TenantItemId,
    gate_id: ID,
    checkpoint_number: u8,
    denial_type: u8,        // 0=cooldown, 1=deny_list, 2=turret_mark (off-chain signal only; turrets cannot consume on-chain state)
    roll: u8,
    timestamp_ms: u64,
}
```

Events are emitted on-chain and indexable. The turret extension's closed-world constraint (fixed 4-arg signature, no DF access) means turret targeting cannot directly consume gauntlet state. However, an off-chain indexer or game server could consume `GauntletDenialEvent` to influence turret behavior outside the extension's scope.

**Verdict: ✅ Feasible now** -- events are emittable from any extension module and are permanent on-chain records. This is the recommended integration path given the turret closed-world constraint.

### Recommended Consequence Architecture

Combine all proxy mechanisms into the `PlayerProgress` DF:

```move
public struct PlayerProgress has store, drop {
    last_checkpoint: u8,
    last_checkpoint_ms: u64,
    denial_count: u8,
    cooldown_until_ms: u64,
}
```

On denial:
1. Increment `denial_count`
2. Set `cooldown_until_ms = now + base_cooldown * denial_count` (escalating)
3. Emit `GauntletDenialEvent` (with `denial_type = 2` for off-chain indexing if `denial_count >= 3`)

On next attempt:
1. Check `cooldown_until_ms` — reject if still active

---

## 4. Multi-Gate Configuration

### ExtensionConfig Architecture

From [config.move](../../../vendor/builder-scaffold/move-contracts/smart_gate/sources/config.move):

- **Per-package singleton:** One `ExtensionConfig` shared object per extension package ([line 10-12](../../../vendor/builder-scaffold/move-contracts/smart_gate/sources/config.move#L10-L12))
- **Created at publish time** via `init` function ([line 24-29](../../../vendor/builder-scaffold/move-contracts/smart_gate/sources/config.move#L24-L29))
- **All gates share one config:** Any gate authorized with `XAuth` looks up rules from the same ExtensionConfig

### Can One Extension Manage Multiple Gates with Different Roles?

**Yes — ✅ Feasible now.**

Store per-gate checkpoint config as dynamic fields keyed by gate ID:

```move
public struct GateCheckpointKey has copy, drop, store { gate_id: ID }
public struct GateCheckpoint has store, drop {
    checkpoint_number: u8,
    success_threshold: u8,   // 1-100
    cooldown_ms: u64,
    permit_expiry_ms: u64,
}
```

The admin configures each gate's role:
```move
public fun set_gate_checkpoint(
    config: &mut ExtensionConfig,
    admin_cap: &AdminCap,
    gate_id: ID,
    checkpoint_number: u8,
    success_threshold: u8,
    cooldown_ms: u64,
    permit_expiry_ms: u64,
) {
    config.set_rule(admin_cap, GateCheckpointKey { gate_id }, GateCheckpoint {
        checkpoint_number, success_threshold, cooldown_ms, permit_expiry_ms,
    });
}
```

### Race Configuration

Global race config as a separate DF:

```move
public struct RaceConfigKey has copy, drop, store {}
public struct RaceConfig has store, drop {
    total_checkpoints: u8,
    race_start_ms: u64,
    race_end_ms: u64,
}
```

### Setup Overhead for N Gates

For a race with N checkpoints:

| Operation | Count | PTB Commands per Op | Total Commands |
|---|---|---|---|
| `authorize_extension<XAuth>` per gate | N | 3 (borrow_owner_cap + authorize + return_owner_cap) | 3N |
| `set_gate_checkpoint` per gate | N | 1 | N |
| `set_race_config` | 1 | 1 | 1 |

Total: `4N + 1` PTB commands. With the 1000-command PTB limit, a single PTB can configure up to **~250 gates** — far more than needed for a demo.

**Practical note:** All N gates must be owned by the same character (or the extension admin must hold all OwnerCaps). The `authorize_extension` call requires the gate's `OwnerCap`.

**Verdict: ✅ Feasible now** — single extension package manages the entire race via per-gate DF configuration.

---

## 5. Time Mechanics

### JumpPermit Expiry

From [gate.move#L87](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L87):

```move
expires_at_timestamp_ms: u64,
```

Set by the extension at `issue_jump_permit` call time. Validated at jump time at [gate.move#L701](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L701):

```move
assert!(jump_permit.expires_at_timestamp_ms > clock.timestamp_ms(), EJumpPermitExpired);
```

### Clock Access

`sui::clock::Clock` is a shared system object, freely accessible. Used extensively in builder-scaffold:

- [tribe_permit.move#L64](../../../vendor/builder-scaffold/move-contracts/smart_gate/sources/tribe_permit.move#L64): `let ts = clock.timestamp_ms();`
- [corpse_gate_bounty.move#L77](../../../vendor/builder-scaffold/move-contracts/smart_gate/sources/corpse_gate_bounty.move#L77): `let ts = clock.timestamp_ms();`
- Both compute expiry as `ts + expiry_duration_ms`

### Race Time Limit via Permit Expiry

**Yes — ✅ Feasible now.**

Two time pressure mechanisms:

1. **Per-checkpoint expiry:** Set a tight permit expiry (e.g., 60 seconds). Player must jump before the permit expires, forcing pace.

2. **Global race deadline:** Check `clock.timestamp_ms() < race_config.race_end_ms` at each permit issuance. Refuse permits after the race window closes.

```move
// In try_issue_permit:
let now = clock.timestamp_ms();
let race_cfg = config.borrow_rule<RaceConfigKey, RaceConfig>(RaceConfigKey {});
assert!(now >= race_cfg.race_start_ms, ERaceNotStarted);
assert!(now < race_cfg.race_end_ms, ERaceEnded);

// Tight expiry creates urgency
let expires_at = now + checkpoint_cfg.permit_expiry_ms;
```

**Caveat:** There is no `valid_from` timestamp on JumpPermit — only `expires_at`. A permit is valid from the moment it's issued until `expires_at`. This means you cannot delay permit validity, only cap its duration.

**Verdict: ✅ Feasible now** — `expires_at_timestamp_ms` + `Clock` provides per-checkpoint time pressure and global race windows.

---

## Overall Architecture Sketch

```
┌─────────────────────────────────────────────────┐
│              Fortune Gauntlet Extension          │
│                (single Move package)             │
├─────────────────────────────────────────────────┤
│ ExtensionConfig (shared singleton)              │
│  ├─ RaceConfigKey → RaceConfig                  │
│  ├─ GateCheckpointKey{gate_A} → GateCheckpoint  │
│  ├─ GateCheckpointKey{gate_B} → GateCheckpoint  │
│  ├─ GateCheckpointKey{gate_C} → GateCheckpoint  │
│  ├─ PlayerProgressKey{player_1} → PlayerProgress│
│  └─ PlayerProgressKey{player_2} → PlayerProgress│
├─────────────────────────────────────────────────┤
│ entry fun try_issue_permit(                     │
│   &Random, &ExtensionConfig, &Gate, &Gate,      │
│   &Character, &Clock, &mut TxContext            │
│ )                                               │
│  1. Read GateCheckpoint for source_gate         │
│  2. Read/create PlayerProgress                  │
│  3. Enforce sequence (last_checkpoint + 1)      │
│  4. Check cooldown                              │
│  5. Roll random (sui::random)                   │
│  6. Success → issue_jump_permit + update prog   │
│  7. Denial → set cooldown + emit denial event   │
├─────────────────────────────────────────────────┤
│ Admin functions:                                │
│  set_race_config, set_gate_checkpoint,          │
│  reset_player_progress, clear_cooldowns         │
├─────────────────────────────────────────────────┤
│ Events:                                         │
│  CheckpointPassedEvent, CheckpointDeniedEvent,  │
│  RaceCompletedEvent, GauntletDenialEvent        │
└─────────────────────────────────────────────────┘
         │
         │ calls gate::issue_jump_permit<XAuth>()
         ▼
┌─────────────────────────┐
│   world::gate (L244)    │
│   Transfers JumpPermit  │
│   to character address  │
└─────────────────────────┘
         │
         │ player uses permit
         ▼
┌─────────────────────────┐
│ gate::jump_with_permit  │
│ (L294, requires         │
│  AdminACL + sponsor)    │
│ Validates + deletes     │
│ permit, emits JumpEvent │
└─────────────────────────┘
```

---

## Risk Summary

| Risk | Severity | Mitigation |
|---|---|---|
| `Random` requires `entry` — limits PTB composability | Low | Permit issuance is self-contained; no downstream PTB commands needed |
| Shared ExtensionConfig contention with many concurrent players | Medium | Acceptable for demo (<100 players). At scale, partition state across multiple objects |
| No turret system for real consequences | Low | Turrets exist (v0.0.14) but closed-world constraint prevents gauntlet state access. Proxy consequences (cooldown, deny, events) remain the correct approach. Events provide audit trail. Turret-aware consequences require turret calling convention changes, not off-chain integration. (Updated 2026-03-02.) |
| `jump_with_permit` requires AdminACL sponsor + dual-sign | High | Same constraint as all gate jumps. Not specific to Fortune Gauntlet. Requires sponsor infrastructure |
| Permit has no `valid_from` — cannot enforce "wait period" via permit alone | Low | Use DF cooldown timestamp instead. Architecture already accounts for this |
| Race state on single shared object = consensus bound | Medium | All shared-object interactions on Sui go through consensus (~2-3s). Sequential checkpoints are naturally paced |

---

## Open Questions

1. **Randomness MEV:** Can a player observe the random outcome and abort the transaction to retry? Sui's `Random` module is designed to prevent this (seed rotates per epoch), but the security model should be verified against current Sui docs before implementation.
2. **Permit reuse:** gate.move has a TODO at [line 706](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L706): "We can allow the permit to be used multiple times." If this changes, the race mechanic needs adjustment.
3. **Extension slot conflict:** Each gate has a single extension slot (via `swap_or_fill` at [gate.move#L130](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L130)). A gate used for the Fortune Gauntlet cannot simultaneously have a different extension (e.g., CivilizationControl toll gate). This is a permanent architectural constraint.
4. **Cross-player state isolation:** The shared ExtensionConfig means all player progress state is under one object. High-frequency concurrent writes from many players could create contention. For a demo, this is acceptable.

---

## Conclusion

The Fortune Gauntlet concept is **feasible as a hackathon entry** using current world-contracts and Sui primitives. The only non-trivial adaptation is the `entry` function requirement for `sui::random`, which is a standard Sui pattern. The turret closed-world constraint is compensated by credible proxy consequences (cooldown, deny list, events). Turrets are out of scope for MVP — see `turret-closed-world-clarified.md`. The most complex engineering challenge is the per-player on-chain state management via dynamic fields, which is well within Move's capabilities but requires careful DF key design.

**Estimated complexity:** Medium — single Move package (~200-300 LoC), admin config scripts, moderate PTB composition for setup.
