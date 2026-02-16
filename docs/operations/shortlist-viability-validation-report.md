# Shortlist Viability Validation Report

> **Date:** 2026-02-16  
> **Status:** Complete  
> **Verdict:** Both GateControl and TradePost are **GREEN — technically viable** on Sui local devnet.  
> **Plan reference:** [shortlist-viability-validation-plan.md](shortlist-viability-validation-plan.md)

---

## Environment

| Component | Detail |
|-----------|--------|
| **Platform** | Sui local devnet via Docker (`vendor/builder-scaffold/docker`) |
| **Sui CLI** | v1.65.2 (Ubuntu 24.04 + suiup) |
| **Container** | `docker-sui-local-run-1ec71ad07eb4` |
| **Move Edition** | `edition = "2024"` |
| **Build Flag** | `sui move build -e local` / `sui client publish -e local` |

### Accounts

| Role | Address |
|------|---------|
| ADMIN | `0x85483f9da07887da6024fdfbc22c1a0eb53475c70c7033aaca9ff06c13a688fe` |
| PLAYER_A | `0x075c99b3eedd7ae54e41b2e8ed61a5069c28742c381bf313b9a254c5ad07ee1c` |
| PLAYER_B | `0xe5f8dbd236299c1b799059d8c19792e975f5eb4fbcf75ac3e17a29480898169d` |

### Published Packages

| Package | ID |
|---------|-----|
| `gate_toll_validation` | `0xe62e64a53bc28ef3a3bd5da9412bf4c8360884db912e42e16f2cac003d5e63ec` |
| `trade_post_validation` | `0x5c5598bf0d677db297539e9d78ca732573d50bc290d737bbeea50660bb43c0fe` |

---

## Test Results Summary

| # | Test | Expected | Result | Evidence |
|---|------|----------|--------|----------|
| 1 | Extension Registration | GREEN | **GREEN ✓** | Code analysis — `gate.move` L105 `authorize_extension<Auth>()` + existing tests |
| 2 | Tribe Filter Rule | GREEN | **GREEN ✓** | Devnet — tribe-1 character passed, tribe-2 character blocked (ETribeMismatch code 0) |
| 3 | Coin Toll Design | GREEN | **GREEN ✓** | Devnet — 1 SUI toll paid + transferred to collector address |
| 4 | Cross-Address Withdrawal | GREEN | **GREEN ✓** | Code analysis — `withdraw_item<Auth>` takes witness, not OwnerCap; `test_swap_ammo_for_lens` validates |
| 5 | Atomic Buy PTB (Devnet) | GREEN | **GREEN ✓** | Devnet — 3 successful cross-address buys (details below) |
| 6 | Direct Access Blocked | GREEN | **GREEN ✓** | Code analysis — `withdraw_by_owner` requires `OwnerCap<T>` + proximity proof |
| 7 | SSU-Backed Storefront (Devnet) | GREEN | **GREEN ✓** | Devnet — witness-gated extension withdrawal + atomic buy (details below) |

**Overall: 7/7 GREEN. No blocking issues found.**

---

## Detailed Evidence

### Test 2+3: GateControl — Tribe Filter + Coin Toll (Devnet)

**Module:** `gate_toll_validation::gate_toll`

**Setup:**
- ADMIN created `GateConfig` (shared): `0xfbb73175002a87f1ffd6f56056e4e24d741176dd24d871b952c9c0abd1ce4160`
- Tribe rule set: allowed tribe = 1
- Toll rule set: price = 1,000,000,000 MIST (1 SUI), collector = ADMIN

**PASS Scenario (PLAYER_A, tribe 1):**
- PLAYER_A created character with `tribe_id = 1`
- Called `request_access()` with 1 SUI `Coin<SUI>` payment
- Result: `status: Success`
- `AccessGrant` event emitted and object received by PLAYER_A
- 1 SUI transferred to ADMIN (collector)
- Devnet checkpoint: ~6260

**FAIL Scenario (PLAYER_B, tribe 2):**
- PLAYER_B created character with `tribe_id = 2`
- Called `request_access()` with 1 SUI `Coin<SUI>` payment
- Result: **Transaction ABORTED** — `MoveAbort` error code `0` (ETribeMismatch)
- No `AccessGrant` issued, no funds transferred (atomic rollback)
- Devnet checkpoint: ~6500

**Conclusion:** Tribe filter correctly allows matching tribes and blocks non-matching tribes. Coin toll payment and transfer work atomically with access control. Both rules compose cleanly on a shared `GateConfig` object with dynamic fields.

---

### Test 5: TradePost — Cross-Address Atomic Buy (Devnet)

**Module:** `trade_post_validation::trade_post`

**Pattern:** Seller mints Item, creates shared Listing with price. Buyer calls `buy()` in a single PTB with `--split-coins` for exact payment. Item transfers to buyer; coin transfers to seller. Listing marked `is_active: false`.

#### Buy Test 1: Trophy (5 SUI)

| Field | Value |
|-------|-------|
| Seller | ADMIN |
| Buyer | PLAYER_B |
| Item | Trophy (`type_id: 42`) |
| Price | 5 SUI (5,000,000,000 MIST) |
| Listing ID | `0xd83ae...` |
| Item ID | `0x3eec...` |
| Status | **SUCCESS** |

**Evidence:**
- `ItemPurchased` event emitted
- PLAYER_B owns Item object `0x3eec...` (confirmed via `sui client objects`)
- ADMIN received 5 SUI payment (balance increase confirmed)
- Listing `is_active: false`

#### Buy Test 2: Rare (2 SUI)

| Field | Value |
|-------|-------|
| Seller | ADMIN |
| Buyer | PLAYER_A |
| Item | Rare (`type_id: 99`) |
| Price | 2 SUI (2,000,000,000 MIST) |
| Listing ID | `0x43a7...` |
| Item ID | `0x504d...` |
| Status | **SUCCESS** |

**Evidence:**
- `ItemPurchased` event emitted
- PLAYER_A owns Item object `0x504d...`
- ADMIN received 2 SUI payment
- Listing `is_active: false`

#### Buy Test 3: Gem (3 SUI) — Clean Definitive Test

| Field | Value |
|-------|-------|
| Seller | ADMIN |
| Buyer | PLAYER_B |
| Item | Gem (`type_id: 101`) |
| Price | 3 SUI (3,000,000,000 MIST) |
| Listing ID | `0x857a869108e853f26d48ae29886d1211514215643c829858e5649464bc8d9b69` |
| Tx Digest | `3GtyTmJmLZxLQ3sqcuGTwoEm566Ts87c8Kedqjfh1NJ2` |
| Status | **SUCCESS** |

**Evidence:**
- Transaction digest: `3GtyTmJmLZxLQ3sqcuGTwoEm566Ts87c8Kedqjfh1NJ2`
- `ItemPurchased` event emitted
- Item transferred to PLAYER_B (`0xe5f8...` — confirmed as owner in tx output)
- 3 SUI (3,000,000,000 MIST) balance change recorded
- Listing `is_active: false`, `item_type_id: 101` — confirmed post-buy

**Conclusion:** Cross-address atomic buy works reliably. Three different items at three different prices, bought by two different buyers, all succeeded. The PTB composition (`--split-coins` + `--move-call buy`) is the correct pattern.

---

### Test 7: TradePost — SSU-Backed Storefront Buy (Devnet)

> **Added:** 2026-02-16 (SSU upgrade validation)  
> **Modules:** `trade_post_validation::mock_ssu` + `trade_post_validation::ssu_trade`  
> **Pattern:** Item stays in a shared StorageUnit. Listing is a "claim ticket" referencing `(ssu_id, item_type_id)`. `buy()` internally calls `mock_ssu::withdraw_item<TradeAuth>(ssu, TradeAuth{}, type_id)` — the buyer NEVER touches the OwnerCap.

#### Architecture

- **`mock_ssu.move`** — Standalone reproduction of the world-contracts `StorageUnit` extension pattern: `authorize_extension<Auth: drop>()`, `withdraw_item<Auth: drop>()` (witness-gated, no OwnerCap), `deposit_item()` (OwnerCap required), `create_storage_unit()`, `share_storage_unit()`
- **`ssu_trade.move`** — SSU-backed TradePost: `TradeAuth has drop {}` witness, `Listing` with `ssu_id`/`item_type_id` (no embedded item), `buy()` creates `TradeAuth{}` and calls cross-module `mock_ssu::withdraw_item<TradeAuth>()`
- **Zero world-contracts dependencies** — `Move.toml` has empty `[dependencies]`; pattern is faithfully reproduced as standalone modules

#### Transaction Log

| Step | Tx Digest | Status | Description |
|------|-----------|--------|-------------|
| Publish | `49KABHpbQJ1sDmkHvYdUTr9S8JWgjpgwu152Nmz1Qg7z` | Success | Package `0x3189a508...` |
| setup_storefront | `3vjNNocmCDEnMeghPEwTQFow7RWzB56bxTKV72oRPyFg` | Success | SSU `0xf08a3eaa...` + OwnerCap `0x260e7c86...` created |
| authorize_extension | `H3R3xKnzT1ksqYioxbnTSKbQfMdebrb75Dp8Qb2A3jcP` | Success | `TradeAuth` registered on SSU |
| stock_item | `CU6ZedANzjzpSiZtuicN2JjfwevjvtR1QRqhWHmCwfRt` | Success | Item `0x99a0f18c...` (type_id=42, "Rare Gem") deposited |
| create_listing | `VbTDAsE6xbDULr3jPXm6iXbJu8RFo6FUHvqjErRsuoc` | Success | Listing `0x21e1b374...` (5 SUI, references SSU) |
| **buy** | `42Uc2VqSGuHx9rYqBRNFJ3gUhgDpGmY76mjtVDM6usvw` | **Success** | Atomic PTB: coin split → buy → withdraw → transfer |

#### On-Chain State Verification

**Pre-buy SSU (contains item):**
```json
{
  "extension": { "name": "...::ssu_trade::TradeAuth" },
  "items": [{ "type_id": "42", "name": [82,97,114,101,32,71,101,109] }],
  "owner": "0x075c99b3..."
}
```

**Post-buy SSU (empty — item withdrawn via extension):**
```json
{
  "extension": { "name": "...::ssu_trade::TradeAuth" },
  "items": [],
  "owner": "0x075c99b3..."
}
```

**Post-buy Listing (inactive):**
```json
{ "is_active": false, "item_type_id": "42", "price": "5000000000", "ssu_id": "0xf08a3eaa..." }
```

**Buyer owns item:** `0x99a0f18c...` (type: `mock_ssu::Item`) — confirmed via `sui client objects`

**Balance transfer:**
| Address | Before | After | Delta |
|---------|--------|-------|-------|
| Seller | 999,943,884,528 | 1,004,943,884,528 | +5,000,000,000 (5 SUI received) |
| Buyer | 1,000,000,000,000 | 994,996,915,320 | −5,003,084,680 (5 SUI + gas) |

#### Caveats Proven

1. **Witness-gated withdrawal:** `buy()` creates `TradeAuth{}` internally and calls `withdraw_item<TradeAuth>()` — the BUYER never needs `OwnerCap`. The SSU's registered extension (`type_name::with_defining_ids<TradeAuth>()`) is verified before withdrawal.
2. **`authorize_extension` enforcement:** Extension must be registered before `withdraw_item` can succeed. The type name check (`EWrongExtension`) prevents unauthorized modules from withdrawing.
3. **Atomic PTB composition:** `--split-coins gas → --assign payment → --move-call buy` executes as a single transaction. Inside `buy()`: validate listing → validate payment → withdraw from SSU → transfer item to buyer → transfer payment to seller → mark listing inactive.
4. **Cross-address operation:** Seller (`0x075c...`) owns the SSU and stocks it. Buyer (`0x8548...`) signs the buy PTB. No seller signature needed at buy time.

**Conclusion:** SSU-backed storefront buy flow fully validated on local devnet. The extension witness pattern enables cross-address item withdrawal without OwnerCap sharing, exactly matching the production world-contracts architecture.

---

## Key Architectural Findings

### 1. Extension + Witness Pattern Is the Foundation (Code Analysis)
Both GateControl and TradePost are designed to use the same core pattern from world-contracts:
- Custom `Auth` struct with `has drop` ability
- Register extension via `authorize_extension<Auth>()` (one-time owner setup)
- Operations take `_: Auth` witness instance — NOT `OwnerCap`
- Enables cross-address operations without sharing private keys

> **Fidelity note:** This pattern was validated via code analysis and existing world-contracts unit tests, not by the sandbox devnet tests. The sandbox modules use standalone types (`GateConfig`, `Listing`, `MockCharacter`) with zero world-contracts dependencies. See [Validation Fidelity Notes](#validation-fidelity-notes) below.

### 2. Shared Objects Enable Cross-Address Coordination
- `GateConfig` (shared) — any player can call `request_access()` to check rules
- `Listing` (shared) — any player can call `buy()` with payment
- The seller doesn't need to be online or sign the buyer's transaction

### 3. Dynamic Fields Work for Composable Rules
- `TribeRule` and `TollRule` stored as dynamic fields on `GateConfig`
- Rules can be added, removed, or modified independently
- Each rule is a separate struct — clean composition without monolithic config

### 4. PTB Composition Pattern for Trades
```
sui client ptb \
  --split-coins gas "[PRICE_IN_MIST]" \
  --assign payment \
  --move-call PACKAGE::trade_post::buy LISTING_ID payment \
  --gas-budget 50000000
```
- `--split-coins` creates exact payment
- `--assign` passes it to the next command
- Single buyer-signed transaction, atomic execution

### 5. `self_transfer` Lint Warning Is Non-Blocking
The `buy()` function does `transfer::public_transfer(item, ctx.sender())` which triggers a non-critical lint. Acceptable for validation; real implementation can use `transfer::public_transfer(item, buyer_address)` with explicit address parameter if preferred.

---

## Pitfalls Discovered During Testing

1. **Move.toml format:** Must use `edition = "2024"` (not `"2024.beta"`). Must include `[environments] local = "0x0"`. Do NOT add explicit Sui git dependency — it conflicts with the built-in framework.

2. **PTB vector literal syntax:** Use `"vector[84u8,114u8]"` format, not `[84,114]`. The CLI requires explicit `u8` suffixes and the `vector[...]` wrapper.

3. **PowerShell + Docker CLI:** Avoid `&&` in command chaining through `docker exec`. Use `;` or separate commands. Double-quoted strings with special characters can cause escaping issues.

4. **Double-execution risk:** When piping `sui client ptb` output through PowerShell filters, the command can appear to execute twice (second attempt fails with `EListingNotActive`). Capture output to a variable first (`$output = docker exec ...`), then filter.

5. **Shared object initial_shared_version:** When referencing shared objects in PTBs, the CLI auto-resolves this. But in programmatic SDKs (TypeScript), you may need to specify `initialSharedVersion` explicitly.

---

## Validation Against Plan

| Plan Criterion | Status |
|----------------|--------|
| Transaction digest captured | ✅ `3GtyTmJmLZxLQ3sqcuGTwoEm566Ts87c8Kedqjfh1NJ2` (and 2 others) |
| Package IDs recorded | ✅ Both packages documented above |
| Object IDs captured | ✅ GateConfig, Listings, Items all recorded |
| Account addresses documented | ✅ ADMIN, PLAYER_A, PLAYER_B |
| Before/after states verified | ✅ Listing `is_active` false; items owned by buyers |
| Error messages captured | ✅ ETribeMismatch (code 0) for wrong-tribe test |
| Fallback needed? | **No** — primary approach works |

---

## Validation Fidelity Notes

> **Added:** 2026-02-16 (post-review audit)  
> **Purpose:** Disambiguate what the devnet tests proved vs. what remains code-analysis inference.

### TradePost: Shared Listing Escrow + SSU-Backed Storefront Both Devnet-Validated

> **Updated:** 2026-02-16 — SSU-backed storefront now independently validated on devnet (Test 7).

**What was proven on devnet — Escrow pattern (3 tx digests, Test 5):**
- A shared `Listing` object containing an embedded `Item` can be atomically purchased by a different address
- `buy()` extracts the item via `Option::extract` on the Listing's `item` field
- `Coin<SUI>` payment transfers atomically to the seller

**What was proven on devnet — SSU-backed pattern (6 tx digests, Test 7):**
- `authorize_extension<TradeAuth>()` — registers witness type on SSU extension slot
- `withdraw_item<TradeAuth>()` — witness-gated withdrawal from SSU WITHOUT OwnerCap
- Cross-module extension call: `ssu_trade::buy()` creates `TradeAuth{}` and calls `mock_ssu::withdraw_item<TradeAuth>()`
- Atomic PTB composition: coin split + SSU withdraw + item transfer + payment + listing update in one buyer-signed tx
- Pre/post state verified: SSU items 1→0, Listing `is_active` true→false, buyer owns item, seller received 5 SUI

**What remains code-analysis only (not devnet-tested):**
- Integration with actual `world-contracts` StorageUnit/Inventory/Character (the sandbox uses standalone mock types)
- The sandbox module has **zero world-contracts dependencies** (`Move.toml` `[dependencies]` is empty)
- `OwnerCap<StorageUnit>` borrowing from `Character` objects (world-contracts requires Character custody)
- Sponsored transaction requirement, proximity proofs, server signatures

**Correct narrative going forward:**
> Both shared-listing escrow AND SSU-backed storefront patterns validated on devnet. The extension witness pattern (authorize → withdraw via witness) is independently proven. Integration with world-contracts StorageUnit/Inventory/Character types remains code-analysis only.

### GateControl: Rule Composition Validated — Jump Permit Integration Not Yet Devnet-Tested

**What was proven on devnet (2 scenarios):**
- A shared `GateConfig` with dynamic field rules (`TribeRule`, `TollRule`) correctly filters access
- Tribe mismatch aborts the transaction atomically (error code 0 / `ETribeMismatch`)
- `Coin<SUI>` toll payment transfers to the collector address on success
- `AccessGrant` object is created and transferred to the caller on success

**What was NOT tested on devnet:**
- `gate::issue_jump_permit<Auth>()` — world-contracts permit issuance
- `gate::jump_with_permit()` — actual jump execution consuming `JumpPermit`
- `gate::authorize_extension<Auth>()` — extension registration on a `Gate` object
- `AdminACL.verify_sponsor()` — sponsored transaction requirement (both `jump()` and `jump_with_permit()` require this)
- `link_gates()` + server-signed distance/location proofs
- `NetworkNode` → fuel → online dependency chain
- The sandbox module has **zero world-contracts dependencies** (`Move.toml` `[dependencies]` is empty)

**Code-analysis evidence (not devnet-validated):**
- `gate::issue_jump_permit<Auth>()` uses the same typed witness pattern — custom extension modules create `Auth{}` and call it (source: `gate.move` L218-246)
- `gate_tests.move` validates: permit jump succeeds (L311-365), default jump blocked with extension (L388-419), wrong witness rejected (L445-472), permit consumed/single-use (L475-520), expired permit rejected (L523-563)
- The sandbox's rule logic (tribe filter + coin toll + abort semantics) is directly portable to an `issue_jump_permit`-based extension

**Correct narrative going forward:**
> Rule composition (tribe filter + coin toll) validated on devnet. Integration with world-contracts gate jump path (`issue_jump_permit` → `JumpPermit` → `jump_with_permit`) is architecturally supported by code analysis and world-contracts test evidence, but has not been independently devnet-tested. Sponsored transaction requirement (`AdminACL`) remains unresolved.

### Unresolved Risks Not Covered by This Validation

Three risks identified in the [GateControl Feasibility Report](../architecture/gatecontrol-feasibility-report.md) were not addressed:

1. **Sponsored transaction requirement** — `jump()` and `jump_with_permit()` both require `admin_acl.verify_sponsor(ctx)`. Not tested on devnet.
2. **Server-signed location/distance proofs** — `link_gates()` requires signed proofs from `ServerAddressRegistry`. No game server exists on local devnet.
3. **NetworkNode dependency chain** — ~6 sequential admin operations before a gate can accept jumps.

These do not block the hackathon (the extension logic is independent of the jump infrastructure), but they constrain live testnet deployment.

---

## Viability Conclusion

**Both CivilizationControl core modules are technically viable for the hackathon:**

- **GateControl (GREEN — rule logic devnet-validated; jump integration code-analysis only):** Tribe filtering and coin toll work via dynamic field rules on a shared config object. The gate denies access atomically when rules fail — no partial state changes. Integration with `gate::issue_jump_permit<Auth>()` and `gate::jump_with_permit()` is supported by code analysis and world-contracts unit tests, but was not independently tested on devnet. Sponsored transaction requirement (`AdminACL`) remains unresolved.

- **TradePost (GREEN — both escrow AND SSU-backed storefront devnet-validated):** Three escrow-style buys plus one SSU-backed buy confirmed on devnet. The SSU-backed pattern uses the typed witness extension pattern (`authorize_extension<TradeAuth>` + `withdraw_item<TradeAuth>`) to enable cross-address item withdrawal without OwnerCap sharing. Six SSU transactions (publish → setup → authorize → stock → list → buy) all succeeded. On-chain state verified: item withdrawn from SSU, transferred to buyer, payment to seller, listing deactivated. Integration with actual world-contracts types (StorageUnit, Inventory, Character) remains code-analysis only.

**Recommendation:** Proceed with CivilizationControl as the hackathon entry. GateControl is Day 1-2 priority. TradePost is Day 2-4. Both can be reimplemented from validated patterns in the carry-forward checklist.

---

## References

- [Validation Plan](shortlist-viability-validation-plan.md)
- [GateControl Feasibility Report](../architecture/gatecontrol-feasibility-report.md)
- [TradePost PTB Validation](../architecture/tradepost-cross-address-ptb-validation.md)
- [March 11 Carry-Forward Checklist](../core/march-11-reimplementation-checklist.md)
- [Hackathon Shortlist Recommendations](../ideas/hackathon-shortlist-recommendations.md)
