# Shortlist Viability Validation Plan

> **Purpose:** Validate that GateControl and TradePost — the two core modules of CivilizationControl — are technically feasible on Sui using the EVE Frontier world-contracts extension pattern. Produce documented evidence for a confident March 11 reimplementation.
>
> **Date:** 2026-02-16
> **Status:** Complete — see [validation report](shortlist-viability-validation-report.md)

---

## Scope

| Module | Risk Rating | Validation Target |
|--------|-------------|-------------------|
| **GateControl** | Green | Confirm extension + witness pattern works; design coin-toll rule |
| **TradePost** | Yellow → TBD | Confirm cross-address PTB buy (extension-based `withdraw_item<Auth>`) |
| TribeMint | Green (deferred) | No validation needed — standard `Coin<T>` pattern |
| ZK Gate Pass | Yellow (stretch) | Out of scope unless time permits |

---

## Preconditions

### Infrastructure
- [ ] Docker Desktop running (Compose v2)
- [ ] Local devnet started via `cd vendor/builder-scaffold/docker && docker compose run --rm sui-local`
- [ ] Three funded accounts available: ADMIN, PLAYER_A, PLAYER_B
- [ ] Addresses exported to `workspace-data/.env.sui`

### Published Packages
- [ ] Sandbox validation Move packages published (under `sandbox/validation/`)
- [ ] Package IDs recorded in evidence section

---

## Test Matrix

### Test 1: GateControl — Extension Registration

**Objective:** Prove a custom gate extension can be deployed, registered on a gate, and gate jumping is blocked without the extension's permit.

**Approach:** Code analysis + Move unit test (no devnet required).

**Steps:**
1. Review `gate.move` `authorize_extension<Auth>()` — registers witness type on gate
2. Confirm that `jump()` aborts when extension is configured (code path: checks `gate.extension.is_some()`)
3. Confirm `jump_with_permit()` requires valid `JumpPermit` from correct Auth type

**Evidence:**
- Source reference: `vendor/world-contracts/contracts/world/sources/assemblies/gate.move` L105 (authorize_extension), L199 (issue_jump_permit)
- Test reference: `vendor/world-contracts/contracts/world/tests/assemblies/gate_tests.move` — `test_jump_with_permit_succeeds`, `test_default_jump_fails_with_extension`

**Success Criteria:** Code analysis confirms the pattern. Existing tests in world-contracts already validate this. **GREEN if tests pass.**

---

### Test 2: GateControl — Tribe Filter Rule

**Objective:** Prove tribe-based gate access filtering works via extension.

**Approach:** Code analysis of extension example.

**Steps:**
1. Review `extension_examples/sources/gate.move` — tribe gate implementation
2. Confirm: witness type `XAuth`, shared `GateRules { tribe: u32 }`, permit issuance checks `character.tribe() == gate_rules.tribe`
3. Confirm the permit is then used with `jump_with_permit()` on the world gate

**Evidence:**
- Source reference: `vendor/world-contracts/contracts/extension_examples/sources/gate.move`
- Pattern: `GateRules` shared object with `tribe: u32`, checked in `request_jump_permit`

**Success Criteria:** Pattern is clear, existing extension example validates approach. **GREEN.**

---

### Test 3: GateControl — Coin Toll Rule Design

**Objective:** Design a coin-based toll mechanism for gate access. No existing example — must be custom.

**Approach:** Design document + optional sandbox prototype.

**Design:**
```
module gate_toll::gate_toll {
    use world::gate;
    
    public struct TollAuth has drop {}
    
    public struct TollConfig has key {
        id: UID,
        price: u64,           // toll amount in MIST
        collector: address,   // where toll payments go
    }
    
    public fun pay_toll_and_jump(
        toll_config: &TollConfig,          // shared
        source_gate: &Gate,                // shared
        destination_gate: &Gate,           // shared
        character: &Character,             // owned by traveler
        payment: Coin<SUI>,               // owned by traveler
        clock: &Clock,                    // shared
        ctx: &mut TxContext,
    ) {
        assert!(coin::value(&payment) >= toll_config.price, ETollInsufficient);
        transfer::public_transfer(payment, toll_config.collector);
        gate::issue_jump_permit<TollAuth>(
            source_gate, destination_gate, character,
            TollAuth {}, clock.timestamp_ms(ctx) + 300_000, ctx
        );
        // Caller then uses the JumpPermit in jump_with_permit()
    }
}
```

**Key insight:** `issue_jump_permit` takes `Auth` by value (witness instance), not by reference. The extension module creates the witness inline. Coin transfer is a standard `transfer::public_transfer`.

**Feasibility:** Straightforward composition. The only dependency is that both gates must have `TollAuth` registered. No OwnerCap needed from traveler. Coin operations are standard Sui.

**Success Criteria:** Design is sound; no blocking issues identified. **GREEN.**

---

### Test 4: TradePost — Cross-Address Extension Withdrawal (CRITICAL)

**Objective:** Prove that a buyer (different address than SSU owner) can withdraw items from an SSU using extension-based auth in a single PTB.

**Approach:** Code analysis + existing test validation.

**Evidence from world-contracts:**

1. **`withdraw_item<Auth>` signature** (storage_unit.move L162):
   ```move
   public fun withdraw_item<Auth: drop>(
       storage_unit: &mut StorageUnit,
       character: &Character,
       _: Auth,           // witness instance, NOT OwnerCap
       type_id: u64,
       _: &mut TxContext,
   ): Item
   ```
   - Takes Auth witness, NOT OwnerCap → **buyer does not need seller's OwnerCap**
   - No proximity proof required
   - No server address verification required

2. **`test_swap_ammo_for_lens`** (storage_unit_tests.move L772):
   - User B owns SSU with lens items in owner inventory
   - User A (different address) calls swap function
   - `withdraw_item<SwapAuth>` withdraws lens from **owner's inventory** without OwnerCap
   - Test passes → **cross-address extension withdrawal is proven**

3. **`deposit_item<Auth>` signature** (storage_unit.move L130):
   ```move
   public fun deposit_item<Auth: drop>(
       storage_unit: &mut StorageUnit,
       character: &Character,
       _: Auth,
       item: Item,
       _: &mut TxContext,
   )
   ```
   - Same pattern as withdraw — Auth witness, not OwnerCap

**Conclusion:** Cross-address atomic buy is feasible:
- Seller authorizes `TradeAuth` extension on their SSU (one-time setup)
- Seller creates a shared `Listing` object with item metadata + price
- Buyer calls `buy()` in single PTB:
  1. Extension creates `TradeAuth {}` witness
  2. `withdraw_item<TradeAuth>` pulls item from SSU
  3. `transfer::public_transfer(payment, seller_address)` pays seller
  4. Item transferred to buyer (either `public_transfer` or deposit into buyer's inventory)

**Success Criteria:** Source code confirms pattern. Existing test validates cross-address withdrawal. **GREEN.**

---

### Test 5: TradePost — Atomic Buy PTB Composition (Devnet)

**Objective:** Validate the full end-to-end atomic buy flow on local devnet.

**Approach:** Sandbox Move module + CLI test.

**Steps:**
1. Deploy a minimal `trade_post` sandbox Move module with:
   - `TradeAuth` witness type
   - `Listing` shared object (item_type_id, price, seller_address)
   - `create_listing()` — seller creates listing
   - `buy()` — buyer atomically pays + receives item

2. Setup sequence:
   - ADMIN deploys world-contracts (or minimal subset)
   - ADMIN creates SSU, transfers OwnerCap to PLAYER_A (seller)
   - PLAYER_A deposits items into SSU
   - PLAYER_A authorizes `TradeAuth` extension on SSU
   - PLAYER_A creates a `Listing` (shared object)

3. Buy sequence (PLAYER_B signs):
   - `sui client switch --address PLAYER_B`
   - `sui client call --package <TRADE_PKG> --module trade_post --function buy --args <listing> <ssu> <character_b> <payment_coin> --gas-budget 100000000`

4. Verify:
   - PLAYER_B received item
   - PLAYER_A received payment
   - Listing removed or marked sold

**Success Criteria:** Transaction succeeds with `status: success`. All three state changes confirmed via `sui client object`.

---

### Test 6: TradePost — Failure Mode: Direct OwnerCap Access

**Objective:** Confirm that buyer CANNOT withdraw via `withdraw_by_owner` (negative test).

**Approach:** Code analysis (no devnet needed).

**Evidence:** `withdraw_by_owner` requires:
- `owner_cap: &OwnerCap<T>` — owned by seller, buyer cannot provide in their PTB
- `proximity_proof` — server-signed, buyer would need server authorization
- Sender check: `ctx.sender() == character.character_address()` — buyer's character, not seller's

**Conclusion:** Direct owner withdrawal by buyer is impossible by design. Extension pattern is the correct (and only) approach.

**Success Criteria:** Code analysis confirms impossibility. **GREEN (negative test passed).**

---

## Evidence Capture Requirements

For each devnet test, capture:
- [ ] Transaction digest
- [ ] Package ID(s)
- [ ] Object IDs (SSU, Listing, OwnerCap, items)
- [ ] Account addresses used
- [ ] Gas costs
- [ ] Error messages (if any)
- [ ] Before/after object states

Store evidence in: `docs/operations/shortlist-viability-validation-report.md`

---

## Decision Outcomes

| Test | Expected | Status |
|------|----------|--------|
| 1. Extension Registration | GREEN | ✅ GREEN |
| 2. Tribe Filter Rule | GREEN | ✅ GREEN |
| 3. Coin Toll Design | GREEN | ✅ GREEN |
| 4. Cross-Address Withdrawal | GREEN | ✅ GREEN |
| 5. Atomic Buy PTB (Devnet) | GREEN/YELLOW | ✅ GREEN |
| 6. Direct Access Blocked | GREEN | ✅ GREEN |

---

## Fallback Strategy

If Test 5 (atomic buy PTB) fails:

**Escrow pattern alternative:**
1. Seller deposits item into escrow contract (shared object)
2. Escrow holds item + price metadata
3. Buyer calls `buy()` on escrow — pays coin, receives item
4. No SSU extension needed — pure escrow

This is simpler but loses the "SSU as storefront" narrative. Use only if extension-based approach fails.

---

## Timeline

| Phase | Duration | Activity |
|-------|----------|----------|
| 1 | 30 min | Code analysis (Tests 1-4, 6) — no devnet needed |
| 2 | 30 min | Start devnet, publish world-contracts subset |
| 3 | 60 min | Deploy + run TradePost devnet test (Test 5) |
| 4 | 30 min | Document results + carry-forward plan |

---

## References

- [hackathon-shortlist-recommendations.md](../ideas/hackathon-shortlist-recommendations.md)
- [sui-playground.md](../architecture/sui-playground.md)
- [civilizationcontrol-strategy-memo.md](../strategy/civilizationcontrol-strategy-memo.md)
- `vendor/world-contracts/contracts/world/sources/assemblies/gate.move`
- `vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move`
- `vendor/world-contracts/contracts/extension_examples/sources/gate.move`
- `vendor/world-contracts/contracts/world/tests/assemblies/storage_unit_tests.move`
- `vendor/world-contracts/contracts/world/tests/assemblies/gate_tests.move`
