# TradePost Cross-Address PTB Risk Validation — Design Report

> **Sub-agent:** C — Cross-Address PTB Risk Validation Design
> **Date:** 2026-02-16
> **Status:** Complete — Risk MITIGATED
> **Sources:** `vendor/world-contracts/contracts/world/sources/` (canonical Move code)

---

## Executive Summary

**The cross-address PTB transfer risk identified in the hackathon shortlist is MITIGATED.** A buyer CAN sign a single PTB that atomically pays a seller AND receives an item from the seller's SSU — but NOT through direct OwnerCap access. Instead, the **typed witness extension pattern** already built into StorageUnit provides a clean, Sui-native path for cross-address inventory operations without requiring the seller's OwnerCap.

The world-contracts codebase already contains a working cross-address swap test (`test_swap_ammo_for_lens` in `storage_unit_tests.move`) that validates this pattern. TradePost extends it with Coin-based payment instead of item-for-item barter.

---

## A. Storage Unit Architecture

### Object Model

```
StorageUnit (shared object, has key)
├── id: UID
├── key: TenantItemId
├── owner_cap_id: ID                    ← ID of the SSU OwnerCap
├── type_id: u64
├── status: AssemblyStatus
├── location: Location
├── inventory_keys: vector<ID>          ← tracks all inventory DF keys
├── energy_source_id: Option<ID>
├── metadata: Option<Metadata>
├── extension: Option<TypeName>         ← SINGLE extension type allowed
│
├── [Dynamic Field: owner_cap_id → Inventory]     ← MAIN inventory (owner's)
├── [Dynamic Field: char_cap_id_A → Inventory]    ← ephemeral inventory (visitor A)
└── [Dynamic Field: char_cap_id_B → Inventory]    ← ephemeral inventory (visitor B)
```

### Ownership Hierarchy

```
GovernorCap (deployer)
  └── AdminCap (game server address)
        └── OwnerCap<StorageUnit> (owned by Character object, not an address)
              └── controls: authorize_extension, online/offline, deposit_by_owner, withdraw_by_owner
```

Key facts:
- **StorageUnit itself is a shared object** — created via `anchor()` + `share_storage_unit()`. Anyone can reference it in a PTB.
- **OwnerCap\<StorageUnit\> is an owned object** — transferred to the Character object via `transfer::transfer(owner_cap, object::id_address(character))`. Only the character's associated address can borrow it.
- **Character is a shared object** — anyone can pass `&Character` as a reference.
- **Inventory is a dynamic field** on the StorageUnit, keyed by the OwnerCap's object ID.
- **Item has `key, store` abilities** — can be transferred via `transfer::public_transfer`.

### Two Access Modes

| Mode | Functions | Auth Required | Inventory Accessed | Who Can Call |
|------|-----------|---------------|-------------------|-------------|
| **Extension-based** | `deposit_item<Auth>`, `withdraw_item<Auth>` | `Auth` witness (drop) | Main inventory (`owner_cap_id` key) | Anyone, IF the module defining `Auth` exposes a public function that creates `Auth {}` |
| **Owner-direct** | `deposit_by_owner`, `withdraw_by_owner` | `OwnerCap<T>` + proximity proof | Ephemeral inventory (per-OwnerCap key) | Only the OwnerCap holder (SSU owner or character owner) |

### Extension Authorization

```move
public fun authorize_extension<Auth: drop>(
    storage_unit: &mut StorageUnit,
    owner_cap: &OwnerCap<StorageUnit>,
) {
    assert!(access::is_authorized(owner_cap, object::id(storage_unit)), EAssemblyNotAuthorized);
    storage_unit.extension.swap_or_fill(type_name::with_defining_ids<Auth>());
}
```

- Uses `swap_or_fill` — only **ONE** extension type per SSU at a time.
- Requires `OwnerCap<StorageUnit>` — only the SSU owner can authorize an extension.
- Once set, extension-based `deposit_item`/`withdraw_item` functions check that the provided `Auth` type matches the registered extension.

### Critical Detail: Extension Functions Do NOT Require OwnerCap

```move
public fun withdraw_item<Auth: drop>(
    storage_unit: &mut StorageUnit,    // shared object ✅
    character: &Character,              // shared object ✅ (used only for event emission)
    _: Auth,                            // witness — only creatable by defining module
    type_id: u64,
    _: &mut TxContext,
): Item {
    assert!(storage_unit.extension.contains(&type_name::with_defining_ids<Auth>()), EExtensionNotAuthorized);
    let inventory = df::borrow_mut<ID, Inventory>(&mut storage_unit.id, storage_unit.owner_cap_id);
    inventory.withdraw_item(storage_unit_id, storage_unit.key, character, type_id)
}
```

**All parameters are either shared objects or internally-created witnesses.** No owned objects are required. This is the key that unlocks cross-address trading.

---

## B. The Cross-Address Problem — Analysis

### The Naive (Broken) Approach

A buyer might attempt to directly call `withdraw_by_owner()` on the seller's SSU:

```
Buyer's PTB:
  1. borrow_owner_cap from buyer's Character → get buyer's OwnerCap<Character>
  2. storage_unit::withdraw_by_owner(seller_ssu, ..., buyer_owner_cap, ...) → get Item
  3. transfer::public_transfer(item, buyer_address)
```

**This fails because:**

1. **OwnerCap mismatch:** `check_inventory_authorization()` checks whether the OwnerCap is authorized for either the StorageUnit ID (if `OwnerCap<StorageUnit>`) or the Character ID (if `OwnerCap<Character>`). The buyer's OwnerCap is authorized for the buyer's Character — NOT the seller's SSU.
2. **Inventory key mismatch:** Even if authorization passed, `withdraw_by_owner` accesses the inventory keyed by `object::id(owner_cap)`. The buyer's OwnerCap would access the buyer's ephemeral inventory (if any exists) — NOT the seller's main inventory.
3. **OwnerCap is owned by Character:** The seller's `OwnerCap<StorageUnit>` is stored on the seller's Character object. `borrow_owner_cap()` checks `character.character_address == ctx.sender()`. The buyer is the sender, so they CANNOT borrow the seller's OwnerCap.

### Why the Extension Pattern Solves It

The extension-based access functions (`deposit_item<Auth>`, `withdraw_item<Auth>`) bypass all three issues:

1. **No OwnerCap required** — authorization is via the typed witness, not OwnerCap.
2. **Always accesses main inventory** — uses `storage_unit.owner_cap_id` as the DF key, not the caller's OwnerCap ID.
3. **No sender check** — the witness is created inside the extension module, not by the caller.

### Summary Table

| Approach | OwnerCap Needed? | Sender Check? | Inventory Accessed | Works Cross-Address? |
|----------|-----------------|---------------|-------------------|---------------------|
| `withdraw_by_owner` | ✅ Yes | ✅ `ctx.sender() == character_address` | Ephemeral (per-cap) | ❌ No |
| `withdraw_item<Auth>` | ❌ No | ❌ No sender check | Main (owner's) | ✅ Yes |

---

## C. Failure Mode Analysis

### Mode 1: Buyer Directly Withdraws from Seller's SSU

**Attempt:** Buyer calls `withdraw_by_owner()` on seller's SSU with buyer's OwnerCap.

**Failure point:** `check_inventory_authorization()` at `storage_unit.move` line 689:
```move
fun check_inventory_authorization<T: key>(owner_cap: &OwnerCap<T>, storage_unit: &StorageUnit, character_id: ID) {
    let owner_cap_type = type_name::with_defining_ids<T>();
    let storage_unit_id = object::id(storage_unit);
    if (owner_cap_type == type_name::with_defining_ids<StorageUnit>()) {
        assert!(access::is_authorized(owner_cap, storage_unit_id), EInventoryNotAuthorized);
    } else if (owner_cap_type == type_name::with_defining_ids<Character>()) {
        assert!(access::is_authorized(owner_cap, character_id), EInventoryNotAuthorized);
    } else {
        assert!(false, EInventoryNotAuthorized);
    };
}
```

The buyer's OwnerCap is authorized for the buyer's character/objects, NOT for the seller's StorageUnit. **Result: `EInventoryNotAuthorized` abort.**

Even before this: the buyer cannot borrow the seller's `OwnerCap<StorageUnit>` because `borrow_owner_cap` checks `character.character_address == ctx.sender()`, and the seller's character address ≠ the buyer's sender address.

### Mode 2: Seller Pre-Approves Buyer

**Question:** Can the seller grant the buyer access without using the extension pattern?

**Answer: No direct mechanism exists.** The access control system has:
- `GovernorCap` → creates `AdminCap`
- `AdminCap` → creates `OwnerCap`
- `OwnerCap` → per-object authorization

There is no "delegate" or "approve" function that would let an OwnerCap holder grant temporary access to another address. The `transfer_owner_cap` function could transfer the OwnerCap to the buyer's character, but that transfers ALL control of the SSU — not scoped to a single operation.

**The extension pattern IS the pre-approval mechanism.** By authorizing an extension, the seller delegates inventory access to the logic defined in the extension module. This is the designed solution.

### Mode 3: Multi-Signer PTB

**Question:** Does Sui support PTBs signed by multiple independent addresses?

**Answer: No.** On Sui:
- A PTB has exactly one `sender` address.
- **Sponsored transactions** allow a `sponsor` to pay gas, but the transaction still has one sender. The sponsor cannot contribute owned objects.
- **Multi-sig addresses** allow multiple keys to collectively control one address, but this is one address with M-of-N signing — not two independent addresses each contributing owned objects.
- There is no native mechanism for Address A and Address B to both contribute their owned objects to a single atomic PTB.

**Verdict:** Multi-signer PTB is NOT a viable path for cross-address trading on Sui.

---

## D. Architecture Alternatives for Atomic Cross-Address Trading

### Option A: Extension-Mediated Direct Trade (RECOMMENDED)

**Pattern:** TradePost extension module mediates between seller's SSU inventory and buyer's payment.

**Flow:**
```
SETUP (seller, one-time):
  1. Seller calls authorize_extension<TradeAuth>(ssu, owner_cap)
  2. Seller calls trade_post::create_listing(ssu, type_id, price, ...)
     → creates a shared Listing object or dynamic field on a shared TradePost config

BUY (buyer, single PTB):
  1. Buyer calls trade_post::buy(
       seller_ssu: &mut StorageUnit,       // shared ✅
       character: &Character,               // shared ✅ (any character, for events)
       listing: Listing,                     // shared or value ✅
       payment: Coin<SUI>,                  // owned by buyer ✅
       ctx: &mut TxContext,
     )
  2. Inside buy():
     a. Verify listing matches SSU + item type + price
     b. let item = storage_unit::withdraw_item<TradeAuth>(ssu, character, TradeAuth{}, type_id, ctx)
     c. transfer::public_transfer(item, ctx.sender())     // Item has store ✅
     d. transfer::public_transfer(payment, listing.seller)  // Coin<SUI> has store ✅
     e. Destroy or update listing
```

**Smart contract changes needed:**
- New Move package: `trade_post` module
  - `TradeAuth` witness struct (drop)
  - `Listing` struct (key, store) — shared object, or dynamic field value
  - `TradePostConfig` struct (key) — shared object for extension config
  - `create_listing()` — seller creates listing (requires seller's signed PTB)
  - `cancel_listing()` — seller cancels (requires seller's signed PTB)
  - `buy()` — buyer purchases (requires buyer's signed PTB)

**PTB structure (buyer side):**
```
PTB (signed by buyer):
  MoveCall: trade_post::buy(
    seller_ssu,           // Input: shared object (StorageUnit)
    character,            // Input: shared object (any Character)  
    listing,              // Input: shared object (Listing)
    payment,              // Input: owned object (Coin<SUI>, split from buyer's coins)
  )
```

**Advantages:**
- Single PTB, single signer (buyer only)
- Truly atomic — item and payment transfer in one transaction
- Uses the extension pattern exactly as designed by world-contracts
- No modification to world-contracts needed
- Works with existing StorageUnit and Inventory types
- Coin\<SUI\> and Coin\<T\> both have `store`, so payment transfer is trivial

**Constraints:**
- Each SSU can only have ONE extension type — a TradePost SSU is a dedicated shop
- Seller must explicitly authorize the TradeAuth extension on their SSU
- Items stay in the main inventory until purchased (no separate escrow needed)

### Option B: Escrow Contract Pattern

**Pattern:** Seller pre-deposits items into a shared escrow object. Buyer claims from escrow.

**Flow:**
```
LIST (seller, PTB):
  1. Seller borrows OwnerCap
  2. Seller calls withdraw_by_owner() to get Item from their SSU
  3. Seller calls escrow::create_listing(item, price, ...)
     → Item is wrapped in a shared Listing object

BUY (buyer, PTB):
  1. Buyer calls escrow::buy(listing, payment)
     → Listing unwraps Item, transfers to buyer, transfers payment to seller
```

**Smart contract changes needed:**
- New Move package: `escrow` module
  - `Listing` struct (key) — wraps Item + price + seller address
  - `create_listing()` — wraps item in listing, shares it
  - `buy()` — unwraps item, transfers payment
  - `cancel_listing()` — returns item to seller

**Advantages:**
- No extension authorization needed on the SSU
- Listing object is self-contained — doesn't depend on SSU state
- Works even if the seller takes their SSU offline

**Disadvantages:**
- Item leaves the SSU inventory when listed → seller has reduced inventory during listing period
- Two transactions required for the seller (withdraw + list)
- If the SSU requires proximity proof for withdrawal, the seller must be in-game at the location
- The escrow contract must handle Item directly — more complex type management
- Loses the "items stay in SSU until sold" semantic (less immersive)

### Option C: Seller-Side Pre-Approval with Buyer Claim

**Pattern:** Seller creates a transferable "sale ticket" that a buyer can use to claim the item.

**Flow:**
```
LIST (seller, PTB):
  1. Seller calls trade_post::create_sale_ticket(ssu_id, type_id, price)
     → SaleTicket (shared object) with SSU reference and item details

CLAIM (buyer, PTB):
  1. Buyer calls trade_post::claim(sale_ticket, payment, seller_ssu, character)
     → Uses extension auth to withdraw from SSU, transfers item to buyer
```

**This is functionally equivalent to Option A** but with the listing name changed to "sale ticket." The extension mechanism is still required for the claim step. The only difference is terminology.

---

## E. Recommended Approach

### Option A: Extension-Mediated Direct Trade

**Rationale:**

1. **Most Sui-native:** Uses the typed witness extension pattern, which is the designed mechanism for cross-address SSU interactions. The world-contracts team explicitly built this for player-to-player interactions (see storage_unit.move header comment: "Storage Units support two access modes to enable player-to-player interactions").

2. **Least code:** No need to manage Item objects outside of inventories. Items stay in the SSU until purchased. The TradePost module only needs `create_listing`, `cancel_listing`, `buy`, and `update_price`.

3. **Most atomic:** The buy() function is a single Move call in a single PTB. No escrow, no multi-step flows, no cleanup.

4. **Proven pattern:** The `test_swap_ammo_for_lens` test in `storage_unit_tests.move` validates cross-address extension-mediated inventory operations. TradePost replaces the "swap" with "sell for Coin."

5. **Existing evidence:** The `corpse_gate_bounty` extension demonstrates the exact same pattern — a third-party module using `deposit_item<XAuth>` and `withdraw_by_owner<T>` to mediate player-SSU interactions.

### Module-Level Design

```move
module trade_post::trade_post;

use sui::coin::Coin;
use sui::sui::SUI;
use world::storage_unit::StorageUnit;
use world::character::Character;

/// Typed witness for SSU extension authorization
public struct TradeAuth has drop {}

/// Represents an active listing on a seller's SSU
public struct Listing has key, store {
    id: UID,
    storage_unit_id: ID,       // which SSU holds the item
    seller: address,            // seller's address (receives payment)
    item_type_id: u64,         // type_id of the item being sold
    price: u64,                // price in MIST (smallest SUI unit)
}

/// Create a listing for an item in the seller's SSU
/// Seller must have authorized TradeAuth extension on the SSU
public fun create_listing(
    storage_unit: &StorageUnit,
    item_type_id: u64,
    price: u64,
    ctx: &mut TxContext,
): Listing { ... }

/// Buy a listed item — buyer's single-PTB entry point
public fun buy(
    storage_unit: &mut StorageUnit,
    character: &Character,
    listing: Listing,
    payment: Coin<SUI>,
    ctx: &mut TxContext,
) {
    // 1. Verify listing matches SSU
    // 2. Verify payment >= price
    // 3. Withdraw item via extension:
    //    let item = storage_unit::withdraw_item<TradeAuth>(ssu, character, TradeAuth{}, type_id, ctx);
    // 4. Transfer item to buyer:
    //    transfer::public_transfer(item, ctx.sender());
    // 5. Transfer payment to seller:
    //    transfer::public_transfer(payment, listing.seller);
    // 6. Destroy listing
}

/// Cancel a listing (seller only)
public fun cancel_listing(listing: Listing, ctx: &mut TxContext) {
    assert!(listing.seller == ctx.sender(), ENotSeller);
    // Destroy listing — item remains in SSU inventory
}
```

---

## F. Minimal Validation Test Plan

### Objective

Prove that a buyer-signed PTB can atomically withdraw an item from a seller-owned SSU and transfer payment, using the extension pattern.

### Prerequisites

- Local Sui devnet running (via Docker or `sui start`)
- `world` package published (or use unit tests within the `world` package)

### Strategy: Use the Existing Test Framework

The simplest validation path is to write a new test case in the existing world-contracts test suite that proves the exact TradePost buy flow. This avoids the need for a standalone devnet deployment.

### Test Module Structure

```move
// File: contracts/trade_post/sources/trade_post.move (new package)
// OR: Add test to contracts/world/tests/ (simpler for validation)

module trade_post::trade_post;

use sui::coin::{Self, Coin};
use sui::sui::SUI;
use world::storage_unit::StorageUnit;
use world::character::Character;
use world::inventory::Item;

public struct TradeAuth has drop {}

public struct Listing has key, store {
    id: UID,
    storage_unit_id: ID,
    seller: address,
    item_type_id: u64,
    price: u64,
}

public fun create_listing(
    storage_unit: &StorageUnit,
    item_type_id: u64,
    price: u64,
    ctx: &mut TxContext,
): Listing {
    Listing {
        id: object::new(ctx),
        storage_unit_id: object::id(storage_unit),
        seller: ctx.sender(),
        item_type_id,
        price,
    }
}

public fun buy(
    storage_unit: &mut StorageUnit,
    character: &Character,
    listing: Listing,
    mut payment: Coin<SUI>,
    ctx: &mut TxContext,
) {
    assert!(listing.storage_unit_id == object::id(storage_unit), 0);
    assert!(coin::value(&payment) >= listing.price, 1);

    // Withdraw item from seller's SSU via extension auth
    let item = storage_unit.withdraw_item<TradeAuth>(
        character,
        TradeAuth {},
        listing.item_type_id,
        ctx,
    );

    // Transfer item to buyer
    transfer::public_transfer(item, ctx.sender());

    // Handle payment (exact amount or split change)
    let seller = listing.seller;
    if (coin::value(&payment) > listing.price) {
        let change = coin::split(&mut payment, coin::value(&payment) - listing.price, ctx);
        transfer::public_transfer(change, ctx.sender());
    };
    transfer::public_transfer(payment, seller);

    // Destroy listing
    let Listing { id, .. } = listing;
    object::delete(id);
}

public fun cancel_listing(listing: Listing, ctx: &mut TxContext) {
    assert!(listing.seller == ctx.sender(), 2);
    let Listing { id, .. } = listing;
    object::delete(id);
}
```

### CLI-Based Devnet Test Steps

If running against a local devnet (more representative of real-world validation):

```bash
# 1. Start local devnet
sui start --with-faucet

# 2. Create two addresses (seller & buyer)
sui client new-address ed25519  # → seller_address
sui client new-address ed25519  # → buyer_address

# 3. Fund both addresses
sui client faucet --address <seller_address>
sui client faucet --address <buyer_address>

# 4. Publish world package (if not already deployed)
cd vendor/world-contracts/contracts/world
sui client publish --gas-budget 500000000

# 5. Publish trade_post package
cd contracts/trade_post
sui client publish --gas-budget 200000000

# 6. Setup: Admin creates characters, SSU, mints items (admin-signed PTBs)
# These require AdminCap — use the package publisher address
sui client ptb \
  --move-call world::character::create_character ... \
  --move-call world::storage_unit::anchor ... \
  --move-call world::storage_unit::share_storage_unit ...

# 7. Seller authorizes TradeAuth extension on their SSU
sui client switch --address <seller_address>
sui client ptb \
  --move-call world::character::borrow_owner_cap<world::storage_unit::StorageUnit> \
    <seller_character> <owner_cap_receiving> \
  --move-call world::storage_unit::authorize_extension<trade_post::trade_post::TradeAuth> \
    <seller_ssu> <owner_cap> \
  --move-call world::character::return_owner_cap<world::storage_unit::StorageUnit> \
    <seller_character> <owner_cap> <receipt>

# 8. Seller creates a listing
sui client ptb \
  --move-call trade_post::trade_post::create_listing \
    <seller_ssu> <item_type_id> <price> \
  --assign listing \
  --transfer-objects [listing] <seller_address>
# (or share the listing)

# 9. Buyer purchases — THE KEY TEST
sui client switch --address <buyer_address>
sui client ptb \
  --split-coins gas [<price>] \
  --assign payment \
  --move-call trade_post::trade_post::buy \
    <seller_ssu> <character> <listing> payment

# 10. Verify: buyer now owns the Item object
sui client object <item_id>
# Should show owner = buyer_address

# 11. Verify: seller received payment
sui client gas <seller_address>
# Should show increased balance
```

### Success Criteria

| Check | How to Verify | Expected Result |
|-------|--------------|-----------------|
| Item withdrawn from seller's SSU | Query SSU inventory (not directly queryable without a view fn — check events) | `ItemWithdrawnEvent` emitted with correct `type_id` |
| Item owned by buyer | `sui client object <item_id>` | `owner: <buyer_address>` |
| Payment received by seller | `sui client gas <seller_address>` | Balance increased by `price` amount |
| Listing consumed | `sui client object <listing_id>` | Object deleted (404 or "not found") |
| Transaction atomic | Single tx digest for buy | All operations in one transaction |
| No OwnerCap required for buyer | Transaction signed only by buyer | Transaction succeeds without seller's OwnerCap |

---

## G. Evidence to Capture

### Transaction Digests

| Step | What to Record | Why |
|------|---------------|-----|
| Publish trade_post | Package ID + tx digest | Proves the module compiles and deploys |
| `authorize_extension<TradeAuth>` | Tx digest | Proves seller setup works |
| `create_listing` | Listing object ID + tx digest | Proves listing creation works |
| `buy()` | **Tx digest + events** | **PRIMARY EVIDENCE** — proves atomic cross-address trade |

### Object IDs

| Object | Record | Purpose |
|--------|--------|---------|
| Seller's StorageUnit | Object ID | Reference for SSU state queries |
| Listing | Object ID (before buy) | Verify it's consumed after buy |
| Item (after buy) | Object ID | Verify ownership transferred to buyer |
| Payment Coin (after buy) | Coin balance on seller | Verify payment received |

### Events to Check

The `buy()` call should emit (from world-contracts):
- `ItemWithdrawnEvent` — item left seller's SSU inventory
- (indirectly via `transfer::public_transfer`) — item ownership assigned to buyer

The TradePost module should also emit its own:
- `ItemSoldEvent { listing_id, buyer, seller, item_type_id, price }` — custom event for trade tracking

### Proof Format

```markdown
## Trade Validation Evidence

### Test Execution
- Network: local devnet / testnet
- Date: YYYY-MM-DD
- Trade Post Package: <package_id>

### Transaction: Buy
- Digest: <tx_digest>
- Sender: <buyer_address>
- Gas: <gas_amount>

### Pre-State
- Seller SSU (<ssu_id>): contains Item type_id=88069, quantity=10
- Buyer: owns Coin<SUI> balance >= price

### Post-State
- Seller SSU (<ssu_id>): Item type_id=88069 withdrawn (ItemWithdrawnEvent)
- Buyer: owns Item object <item_id> (verified via sui client object)
- Seller: received Coin<SUI> (balance increased by <price>)
- Listing (<listing_id>): deleted

### Conclusion
✅ Atomic cross-address trade validated via extension pattern.
   No OwnerCap from seller required. Single buyer-signed PTB.
```

---

## H. Technical Nuances & Caveats

### 1. Single Extension Per SSU

`storage_unit.extension` is `Option<TypeName>` — only one extension type at a time. A TradePost SSU cannot simultaneously use a different extension (e.g., GateControl). This is fine: sellers deploy a dedicated "shop" SSU. This actually reinforces the CivilizationControl narrative — different SSUs serve different roles.

### 2. Character Reference in Extension Functions

`withdraw_item<Auth>` and `deposit_item<Auth>` require `&Character`, but only for event emission — no authorization check on the character. Any shared Character can be passed. For meaningful events, pass the buyer's character to track who received the item.

### 3. Item `transfer::public_transfer` Viability

`Item` has `key, store` abilities — `transfer::public_transfer` is valid. However, the `inventory.move` comment says "Item should always have a parent eg: Inventory, ship etc." This is a design guideline, not an enforcement. For TradePost, items leave the SSU and arrive at the buyer's address as standalone objects. The buyer can later deposit them into their own SSU.

### 4. Tenant Mismatch Guard

`deposit_item<Auth>` checks `inventory::tenant(&item) == storage_unit.key.tenant()`. Items can only be deposited into SSUs of the same tenant. This is not a concern for `withdraw_item` (the withdrawn item retains its tenant). Cross-tenant trading would require items to be in same-tenant SSUs.

### 5. SSU Must Be Online

Both extension functions assert `storage_unit.status.is_online()`. The seller's SSU must be online (connected to a NetworkNode with sufficient energy) for trades to execute.

### 6. Listing as Shared vs Owned Object

The `Listing` object can be either:
- **Shared:** Anyone can reference it in a PTB. Simpler for discovery. Requires consensus.
- **Owned by seller, then transferred:** Buyer would need to know the listing ID. The `buy` function would need to use `Receiving<Listing>` or the listing would need to be passed as a shared object.

**Recommendation:** Share the Listing object. This matches the pattern of most marketplace contracts on Sui and allows buyers to discover listings without off-chain coordination.

### 7. Payment Handling

For `Coin<SUI>`:
- Buyer can use `--split-coins gas [amount]` in PTB to split exact payment
- TradePost can accept overpayment and return change via `coin::split`
- For `Coin<TribeToken>` (TribeMint integration), same pattern applies — `Coin<T>` has `key, store`

### 8. Existing Test Evidence (Pre-Validation)

The `test_swap_ammo_for_lens` test in `storage_unit_tests.move` (line ~749) already proves:
- User A (buyer-equivalent) calls a function while signed as `user_a()`
- The function withdraws from User B's main inventory via `withdraw_item<SwapAuth>`
- The function deposits into User A's ephemeral inventory via `deposit_by_owner`
- No OwnerCap from User B is used in the withdrawal
- Cross-address inventory operation succeeds atomically

**This is the strongest existing evidence that the TradePost pattern will work.** Our TradePost simplifies it further by using `transfer::public_transfer` instead of `deposit_by_owner` (no proximity proof needed for the buyer).

---

## I. Risk Reclassification

| Risk Item | Previous | New | Rationale |
|-----------|----------|-----|-----------|
| Cross-address PTB item transfer | **Yellow** (unvalidated) | **Green** (pattern validated) | Extension-based access is the designed mechanism for cross-address SSU interactions. Existing test suite proves it works. No OwnerCap needed. |
| TradePost Move module | Yellow | **Yellow-Green** | Straightforward extension module following established patterns (corpse_gate_bounty, swap test). Main complexity is Listing lifecycle. |
| Coin payment in PTB | Unassessed | **Green** | Coin\<T\> has `key + store`, `transfer::public_transfer` is trivial. Standard pattern across Sui DeFi. |

---

## J. Comparison: TradePost vs test_swap_ammo_for_lens

| Aspect | Swap Test (Existing) | TradePost (Proposed) |
|--------|---------------------|---------------------|
| Cross-address? | ✅ User A acts on User B's SSU | ✅ Buyer acts on Seller's SSU |
| Auth mechanism | `SwapAuth` witness | `TradeAuth` witness |
| What buyer provides | Item (ammo) via ephemeral inventory | Coin\<SUI\> (payment) |
| What buyer receives | Item (lens) via `deposit_by_owner` | Item via `transfer::public_transfer` |
| Seller's OwnerCap used? | ❌ Not in withdraw step | ❌ Not in buy step |
| Proximity proof needed? | ✅ For `deposit_by_owner` / `withdraw_by_owner` | ❌ Not needed (no owner-direct access) |
| Listing/discovery | N/A (hardcoded item types) | Shared Listing objects |
| Payment | Item-for-item barter | Coin\<SUI\> or Coin\<T\> |

**TradePost is actually SIMPLER than the swap test** because it avoids `deposit_by_owner`/`withdraw_by_owner` entirely — no proximity proof, no ephemeral inventory, no OwnerCap needed in the buy path.

---

## K. Recommended Day-1 De-Risk Sequence

1. **Write the TradePost Move module** (~50-80 lines)
2. **Write a test case** following the `test_swap_ammo_for_lens` pattern but using Coin\<SUI\> for payment
3. **Run `sui move test`** in the world-contracts test framework (or a dependent package)
4. **If test passes:** Risk confirmed Green. Proceed to listing CRUD and UI.
5. **If test fails:** Diagnose — likely a package dependency or type visibility issue. Fall back to Option B (escrow).

**Estimated time for de-risk validation: 2-4 hours** (including Move module, test, and debugging).

---

## L. SSU-Backed Storefront Devnet Validation (2026-02-16)

> **Status:** PROVEN on local devnet. The extension witness pattern works exactly as designed.

The SSU-backed storefront pattern has been independently validated on local devnet using standalone mock modules (`mock_ssu.move` + `ssu_trade.move`) that reproduce the world-contracts extension pattern with zero external dependencies.

### Validated Transactions

| Step | Tx Digest | Status |
|------|-----------|--------|
| Publish | `49KABHpbQJ1sDmkHvYdUTr9S8JWgjpgwu152Nmz1Qg7z` | Success |
| `setup_storefront` | `3vjNNocmCDEnMeghPEwTQFow7RWzB56bxTKV72oRPyFg` | Success |
| `authorize_extension<TradeAuth>` | `H3R3xKnzT1ksqYioxbnTSKbQfMdebrb75Dp8Qb2A3jcP` | Success |
| `stock_item` | `CU6ZedANzjzpSiZtuicN2JjfwevjvtR1QRqhWHmCwfRt` | Success |
| `create_listing` | `VbTDAsE6xbDULr3jPXm6iXbJu8RFo6FUHvqjErRsuoc` | Success |
| `buy` (atomic PTB) | `42Uc2VqSGuHx9rYqBRNFJ3gUhgDpGmY76mjtVDM6usvw` | Success |

### Proven Properties

1. **Witness-gated withdrawal:** `buy()` creates `TradeAuth{}` and calls `mock_ssu::withdraw_item<TradeAuth>()` — buyer never needs OwnerCap
2. **Extension authorization enforced:** SSU extension slot contains `type_name::with_defining_ids<TradeAuth>()` — only this module can withdraw
3. **Atomic PTB composition:** `--split-coins gas → --assign payment → --move-call buy` in one buyer-signed tx
4. **Cross-address:** Seller owns SSU + stocks items; buyer signs buy tx — no seller signature at buy time
5. **Balance verified:** Seller +5 SUI, Buyer -5 SUI (+ gas)
6. **State verified:** SSU items 1→0, Listing `is_active` true→false, buyer owns Item

### Risk Reclassification Update

| Risk Item | Previous | Updated | Rationale |
|-----------|----------|---------|-----------|
| SSU-backed storefront buy | **Yellow-Green** (code analysis) | **Green** (devnet proven) | 6 successful txs on local devnet. Extension witness pattern independently validated. |

See full evidence in [Shortlist Viability Validation Report](../operations/shortlist-viability-validation-report.md#test-7-tradepost--ssu-backed-storefront-buy-devnet).
