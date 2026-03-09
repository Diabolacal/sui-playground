# Version Pinning Verification Report

**Retention:** Sandbox-only
**Date:** 2026-03-03
**Environment:** Sui CLI v1.66.1

> **⚠️ SUPERSEDED (v0.0.15, 2026-03-03):** This document verified signatures at v0.0.14 (78854fe). world-contracts is now at v0.0.15 (74d30c8). A3 (`withdraw_item`) signature has changed — now includes `quantity: u32` + `ctx: &mut TxContext`. A1, A2, A4 remain valid. Gate/turret/access modules are unchanged.
>
> **⚠️ SUPERSEDED (v0.0.17, 2026-03-09):** world-contracts updated to v0.0.17 (26d0a8c). Further changes: `create_killmail` signature completely changed, `link_gates` adds type_id matching, `withdraw_item` adds online guard, new `MetadataChangedEvent`, new `PlayerProfile` struct. See `docs/core/march-11-reimplementation-checklist.md` for full change list.

## World-Contracts Pin

| Field | Value |
|-------|-------|
| Commit | `78854fed4a21bd4a2e39c38b257ca95f2d6d09d3` |
| Tag | `v0.0.14` |
| Commit message | `feat: turret implementation (#95)` |
| Submodule path | `vendor/world-contracts` |

## Function Signature Verification (A1–A4)

### A1: gate::authorize_extension (gate.move:128)

```move
public fun authorize_extension<Auth: drop>(gate: &mut Gate, owner_cap: &OwnerCap<Gate>)
```

**Status:** MATCHES expected. Takes `&mut Gate` + `&OwnerCap<Gate>`. Uses `swap_or_fill` internally.

### A2: gate::issue_jump_permit (gate.move:240)

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

**Status:** MATCHES expected. Takes `&Gate` × 2 (source + dest), `&Character`, Auth witness, expiry timestamp, ctx. Both gates must have matching extension type.

### A3: storage_unit::withdraw_item (storage_unit.move:200)

```move
public fun withdraw_item<Auth: drop>(
    storage_unit: &mut StorageUnit,
    character: &Character,
    _: Auth,
    type_id: u64,
    _: &mut TxContext,
): Item
```

**Status:** MATCHES expected. NO OwnerCap parameter — only Auth witness required. Returns `Item` object.

### A4: Item struct (inventory.move:48)

```move
public struct Item has key, store { ... }
```

**Status:** MATCHES expected. Has `key, store` abilities → `transfer::public_transfer` is valid.

## Additional Signatures Verified

### gate::jump_with_permit (gate.move)

Verified present. Consumes JumpPermit. Emits JumpEvent.

### turret::authorize_extension (turret.move)

Same `swap_or_fill` pattern as gate. Takes `&mut Turret, &OwnerCap<Turret>`.

### turret::online / turret::offline (turret.move:140-167)

Player-callable via `OwnerCap<Turret>`. State guards abort if already in target state.

## March 11 Re-Verification Steps

On Day 1, before any code:
```bash
# 1. Check if upstream has changed
git -C vendor/world-contracts fetch
git -C vendor/world-contracts log HEAD..origin/main --oneline

# 2. If changes exist, review for breaking signatures
git -C vendor/world-contracts diff HEAD origin/main -- contracts/world/sources/assemblies/gate.move
git -C vendor/world-contracts diff HEAD origin/main -- contracts/world/sources/assemblies/storage_unit.move
git -C vendor/world-contracts diff HEAD origin/main -- contracts/world/sources/primitives/inventory.move

# 3. Update submodule if needed
git submodule update --remote vendor/world-contracts
```

**Decision:** If ANY of A1–A4 signatures changed, assess impact before proceeding. If `issue_jump_permit` or `withdraw_item` removed → project may be unviable.
