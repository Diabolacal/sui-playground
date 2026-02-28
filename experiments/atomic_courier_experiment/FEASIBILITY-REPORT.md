# Atomic Courier — Feasibility Report

**Retention:** Sandbox-only

## Verdict: FEASIBLE ✓

Withdraw + deposit + Coin transfer all execute atomically in a single PTB on Sui. The transaction either completes entirely or fails entirely — no partial state.

## Test Execution Summary

| Step | Operation | Result |
|------|-----------|--------|
| 1 | Setup (register server, add sponsor to ACL) | ✓ |
| 2 | Create Character | ✓ |
| 3 | Create NetworkNode | ✓ |
| 4 | Deposit Fuel + Online NWN | ✓ |
| 5 | Create SSU A (source) | ✓ |
| 6 | Create SSU B (destination) | ✓ |
| 7 | Online both SSUs | ✓ |
| 8 | Authorize XAuth extension on both SSUs | ✓ |
| 9 | Mint item into SSU A | ✓ |
| **10** | **ATOMIC TRANSFER** | **✓** |

## Atomic Transfer Transaction

**Digest:** `EfVqghq3Tv3UPb553ZbJ8uinEhCBoMd9k2zyZG122hun`

### Operations in Single PTB
1. `splitCoins(gas, [1000])` — create reward coin
2. `atomic_transfer::atomic_transfer_test(ssuA, ssuB, character, 446, rewardCoin)` which internally:
   - `storage_unit::withdraw_item<XAuth>(ssuA, character, x_auth(), 446, ctx)` → `Item`
   - `storage_unit::deposit_item<XAuth>(ssuB, character, item, x_auth(), ctx)`
   - `transfer::public_transfer(rewardCoin, courier)`
   - `event::emit(AtomicTransferEvent{...})`

### Emitted Event
```json
{
  "character_id": "0x8bfb71592bbd2c5aa6895e655c89af17e514c1959b7c06b91e1c402b9749f22b",
  "courier": "0xce00d0d0048e08f05bc33676b37a37a1b47c813088f40b366d54690fa8c1d462",
  "dest_ssu_id": "0x2573636537e1036ce3f4496dcb24fc7e1dcbb03df2d94b63913eb5d0ecfd0fc8",
  "item_type_id": "446",
  "reward_amount": "1000",
  "source_ssu_id": "0xfd0e48548ec741ec3c5ac84f5e7760caf44e708f47c1369fafe593048dce398c"
}
```

### Gas Analysis
| Metric | Value |
|--------|-------|
| Computation | 1,000,000 MIST |
| Storage | 14,675,600 MIST |
| Rebate | 13,550,724 MIST |
| **Net** | **2,124,876 MIST (~0.002 SUI)** |

### Objects Mutated (5)
1. SSU A (`StorageUnit`) — item withdrawn from inventory
2. SSU B (`StorageUnit`) — item deposited into inventory
3. SSU A Inventory (dynamic field) — item count decremented
4. SSU B Inventory (dynamic field) — item count incremented
5. Gas Coin (`Coin<SUI>`) — split for reward

## Borrow Analysis

| Function | Auth Required | AdminACL? | Sponsorship? |
|----------|--------------|-----------|--------------|
| `withdraw_item<XAuth>` | `XAuth` (drop witness) | No | No |
| `deposit_item<XAuth>` | `XAuth` (drop witness) | No | No |
| `transfer::public_transfer` | None | No | No |

**Key finding:** The entire atomic transfer requires NO AdminACL and NO sponsored transaction. The extension's `XAuth` witness (minted via `public(package) fun x_auth()`) provides all necessary authorization. This means the operation is player-callable (or callable by any party) without admin involvement.

## Gate Jump Viability

The `issue_jump_permit` function also uses the same `Auth` witness pattern (no AdminACL). However, `jump_with_permit` requires AdminACL + sponsorship. This means:

- **Toll without jump** (Concept 3 "Atomic Courier"): Fully feasible — SSU item transfer + payment, no AdminACL needed
- **Toll with jump**: Requires AdminACL for the `jump_with_permit` call, but `issue_jump_permit` is player-direct. A combined PTB would need sponsored tx for the jump portion.

## Architecture Implications for CivilizationControl

1. **Extension-based access is sufficient** for SSU operations — no need for AdminACL in the courier transfer path
2. **Single PTB atomicity** eliminates the need for escrow or multi-step flows
3. **Low gas cost** (~0.002 SUI) makes per-transfer fees practical
4. **`public(package)` witness minting** ensures only the extension package can authorize operations — secure by design
5. **Character `&Character` (immutable ref)** works for withdraw/deposit — character is not mutated, only SSUs are

## Environment

- **Network:** Local Sui devnet (Docker, `http://127.0.0.1:9000`)
- **Sui CLI:** 1.66.2-a9a6825eaf62
- **Package:** Combined world + experiment (published via `test-publish --with-unpublished-dependencies`)
- **Package ID:** `0xe8aff0035db4e0754fa3565bb68049cb4cb1a1daa6bda6b9e20b016efb511d25`

## Files

- `sources/atomic_transfer.move` — Core test function (withdraw + deposit + transfer)
- `sources/config.move` — Extension pattern (ExtensionConfig + AdminCap + XAuth)
- `phase3-reseed-and-test.ts` — Complete end-to-end test script
- `Move.toml` — Package manifest

## Recommendation

**Proceed with Atomic Courier as a viable CivilizationControl mechanism.** The on-chain atomicity guarantee eliminates the primary risk (partial execution / item loss). The extension-based auth model means no admin involvement is needed for the transfer operation itself — only for initial setup (SSU creation, extension authorization, NWN fueling).
