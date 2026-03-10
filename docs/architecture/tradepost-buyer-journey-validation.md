# TradePost Buyer Journey — Feasibility Validation

**Retention:** Sandbox-only

> **Date:** 2026-02-18 (re-checked 2026-02-19)
> **Verdict:** PARTIAL PASS (unchanged after re-check)
> **Sources:** vendor/world-contracts v0.0.13 @ e508451 (storage_unit.move, inventory.move, metadata.move), vendor/builder-documentation @ 185d7a8 (dapp-kit.md, storage-unit/README.md, dapps/*), vendor/builder-scaffold @ c97989f (smart_gate/, dapps/), docs/operations/shortlist-viability-validation-report.md, docs/architecture/tradepost-cross-address-ptb-validation.md, live GitBook (docs.evefrontier.com) cross-check 2026-02-19
> **Scope:** Validate that the TradePost "buyer journey" (fly up → interact → browse listings → buy → receive items) is implementable with available EVE Frontier Sui/Move primitives

> **2026-03-10 submodule refresh:** Builder-scaffold renamed `smart_gate/` → `smart_gate_extension/`, `storage_unit/` → `storage_unit_extension/`. References below use pre-rename paths.

---

## A) Verdict: PARTIAL PASS

### What PASSES

| Surface | Status | Evidence |
|---|---|---|
| Cross-address atomic buy (extension witness pattern) | **VALIDATED** | 3 devnet tx digests; see [validation report](../operations/shortlist-viability-validation-report.md) Test 5 |
| SSU-backed storefront lifecycle (6 txs) | **VALIDATED** | Full lifecycle tested; see validation report Test 7 |
| `withdraw_item<Auth>` without OwnerCap | **VALIDATED** | Source-confirmed + devnet tests; see [cross-address PTB validation](tradepost-cross-address-ptb-validation.md) |
| `Coin<SUI>` transfer in same PTB as item withdrawal | **VALIDATED** | Standard Sui object transfer pattern, tested |
| Extension `authorize_extension<TradeAuth>` on SSU | **VALIDATED** | Identical pattern to gate extension, source-confirmed |
| Read path: SSU state + inventory via GraphQL / dynamic fields | **VALIDATED** | dapp-kit `getObjectWithDynamicFields`, `useSmartObject()` |
| Custom event emission for Signal Feed | **VALIDATED** | Extension packages can emit arbitrary events; world-contracts has no built-in trade events |
| `Metadata.url` field exists on SSU | **VALIDATED** | `metadata.move`: `url: String`, owner-updatable via `update_url()` |

### What is UNKNOWN (requires March 11 testing)

| Surface | Risk | Detail |
|---|---|---|
| **In-game dApp interaction model** | **HIGH** | How does the EVE Frontier game client present a builder's dApp when a player interacts with an SSU? All builder-docs "Connecting In-Game" pages are `//TODO`. |
| **dApp URL source** | **HIGH** | Does the game client read `Metadata.url` to load an iframe? Is there a default SSU UI? Is the URL configured elsewhere? Undocumented. |
| **Testnet world-contracts deployment** | **MEDIUM** | All validation was on local devnet. The hackathon test server may have different world-contracts version, gas costs, or object limits. |
| **~~Partial-quantity withdraw~~** | **~~LOW~~** **RESOLVED** | ~~`withdraw_item` takes the ENTIRE `Item` for a `type_id` (full quantity). No partial withdraw exists.~~ |

> **RESOLVED (v0.0.15):** `withdraw_item<Auth>` now accepts `quantity: u32`, enabling partial withdrawals. Full-stack workaround no longer needed.

### What FAILS

| Surface | Status | Impact |
|---|---|---|
| No builder-scaffold SSU example | **GAP** | Must build TradePost extension from scratch using gate `config.move` as template. The `storage_unit/` scaffold is an empty stub. |
| No in-game dApp documentation | **GAP** | Cannot validate the buyer-side UX flow ("fly up → see listings in-game") without hackathon test server access. |
| No trade/marketplace primitives in world-contracts | **Expected** | Listings, prices, order logic must be 100% custom extension code. |

### Risk Assessment

**Core on-chain TradePost mechanics are proven.** The risk is entirely at the UX integration layer — specifically, how a buyer standing at an SSU in the game client accesses the TradePost dApp. If the game client does NOT open an embedded browser for SSU interaction, the "fly up and buy" user story breaks — the buyer would need to use an external browser with the SSU's object ID, which is a significantly weaker demo narrative.

**Fallback position:** If SSU in-game dApp embedding is unavailable or too risky, the demo beat sheet already includes a [GateControl-only fallback variant](../core/civilizationcontrol-demo-beat-sheet.md) (2 minutes, no TradePost). TradePost could still be demonstrated via external browser + on-chain evidence overlays.

---

## B) Minimal TradePost Architecture

### Object Types

```
┌────────────────────────────────────────────────────────┐
│ StorageUnit (shared, world-contracts)                  │
│   extension: Option<TypeName> = Some(TradeAuth)        │
│   metadata: Option<Metadata> = { url: "https://..." }  │
│   Dynamic Fields:                                      │
│     [owner_cap_id] → Inventory { items: VecMap<u64,    │
│                        Item> }  ← PRIMARY (seller's)   │
│     [visitor_cap_id] → Inventory { ... } ← EPHEMERAL   │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ ExtensionConfig (shared, our extension)                │
│   id: UID                                              │
│   Dynamic Fields:                                      │
│     [ListingKey { type_id }] → Listing { ... }         │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ Listing (stored as dynamic field on ExtensionConfig)   │
│   seller: address                                      │
│   ssu_id: ID                                           │
│   item_type_id: u64                                    │
│   price_mist: u64                                      │
│   is_active: bool                                      │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ AdminCap (owned, our extension)                        │
│   config_id: ID                                        │
│   — held by SSU owner for listing management           │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ TradeAuth (witness, drop only)                         │
│   — instantiated only inside our extension package     │
│   — authorizes withdraw_item / deposit_item on SSU     │
└────────────────────────────────────────────────────────┘
```

### Write Transactions (PTB Shapes)

#### 1. Setup (one-time, by SSU owner)

```
tx {
  // Create ExtensionConfig + AdminCap
  let (config, admin_cap) = trade_post::create_config(ctx);
  share_object(config);
  transfer(admin_cap, sender);

  // Authorize extension on SSU
  let owner_cap = character::borrow_owner_cap<StorageUnit>(character, ssu);
  storage_unit::authorize_extension<TradeAuth>(ssu, owner_cap);
  character::return_owner_cap(character, owner_cap);

  // Optionally set dApp URL
  metadata::update_url(ssu.metadata, ssu.key, owner_cap, "https://tradepost.example.com/?assemblyId=<ssu_id>");
}
```

#### 2. Create Listing (by SSU owner)

```
tx {
  // Add listing as dynamic field on ExtensionConfig
  trade_post::create_listing(
    config,        // &mut ExtensionConfig (shared)
    admin_cap,     // &AdminCap (owned by seller)
    ssu_id,        // ID — which SSU this listing is for
    item_type_id,  // u64 — type of item being sold
    price_mist,    // u64 — price in MIST
  );
}
```

**Events emitted:** `ListingCreatedEvent { config_id, ssu_id, item_type_id, price_mist, seller }`

#### 3. Buy (by any player — the core buyer journey tx)

```
tx {
  // Split exact payment from buyer's coin
  let payment = coin::split(buyer_coin, listing.price_mist, ctx);

  // Extension-mediated withdrawal from SSU owner's inventory
  // No OwnerCap needed — TradeAuth witness is created internally
  let item = trade_post::buy(
    config,         // &mut ExtensionConfig (shared)
    ssu,            // &mut StorageUnit (shared)
    character,      // &Character (buyer's, shared)
    listing_key,    // ListingKey — identifies which listing
    payment,        // Coin<SUI> — exact price
  );
  // Inside buy():
  //   1. Verify listing.is_active && listing.ssu_id matches
  //   2. storage_unit::withdraw_item<TradeAuth>(ssu, character, TradeAuth{}, type_id, ctx)
  //   3. transfer::public_transfer(payment, listing.seller)
  //   4. listing.is_active = false
  //   5. emit TradeSettledEvent

  // Item transferred to buyer
  transfer::public_transfer(item, buyer_address);
}
```

**Events emitted:** `TradeSettledEvent { config_id, ssu_id, listing_key, item_type_id, buyer, seller, price_mist }`

**Key property:** The buyer signs the transaction. No seller signature needed. The extension witness (`TradeAuth`) is created inside the `buy()` function, authorizing `withdraw_item` from the SSU owner's primary inventory.

#### 4. Cancel Listing (by SSU owner)

```
tx {
  trade_post::cancel_listing(config, admin_cap, listing_key);
}
```

**Events emitted:** `ListingCancelledEvent { config_id, ssu_id, item_type_id }`

### Read APIs (for dApp / Signal Feed)

| Data Needed | API / Method | Notes |
|---|---|---|
| SSU state (status, location, metadata) | `dapp-kit: useSmartObject()` or `getAssemblyWithOwner(assemblyId)` | Auto-polling available |
| SSU owner inventory (items + quantities) | `getObjectWithDynamicFields(ssuId)` → filter by `owner_cap_id` key | Items stored as `VecMap<u64, Item>` inside `Inventory` |
| Active listings | `getObjectWithDynamicFields(configId)` → filter `ListingKey` entries | Or query Listing objects by package/type |
| Trade history | Subscribe/query `TradeSettledEvent` by package ID | Event indexing via Sui RPC `queryEvents` |
| Revenue totals | Aggregate `TradeSettledEvent.price_mist` + `TollCollectedEvent.amount` | Client-side aggregation or backend indexer |
| Listing state change | Poll `Listing.is_active` field or listen for `TradeSettledEvent` | Real-time: event subscription; batch: polling |

### Events for Signal Feed

Our extension must emit these custom events (world-contracts provides NO trade/revenue events):

| Event | Fields | Trigger |
|---|---|---|
| `ListingCreatedEvent` | `config_id, ssu_id, item_type_id, price_mist, seller` | `create_listing()` |
| `TradeSettledEvent` | `config_id, ssu_id, item_type_id, buyer, seller, price_mist` | `buy()` |
| `ListingCancelledEvent` | `config_id, ssu_id, item_type_id` | `cancel_listing()` |

World-contracts will additionally emit:
| Event | Source | Trigger |
|---|---|---|
| `ItemWithdrawnEvent` | `world::inventory` | Automatically on `withdraw_item<TradeAuth>()` |
| `ItemDepositedEvent` | `world::inventory` | If buyer deposits item into another SSU |

---

## C) March 11 Test Checklist

### CRITICAL (must-verify-first on hackathon test server)

| # | Test | Method | Pass Criteria | Fallback if Fails |
|---|---|---|---|---|
| T1 | **In-game SSU dApp interaction** | Deploy an SSU with `Metadata.url` set to a test dApp. Have a player character fly to the SSU and interact. Does the game open the dApp in an embedded browser? | Game client opens dApp URL with `assemblyId` parameter | Demo via external browser + on-chain evidence overlays |
| T2 | **dApp URL configuration source** | Test whether `Metadata.url` is what the game client reads. Try updating with `metadata::update_url()` and re-interacting. | Updated URL loads in-game | Check Discord/builder channels for alternative configuration method |
| T3 | **Extension authorization on testnet SSU** | Call `authorize_extension<TradeAuth>(ssu, owner_cap)` on the hackathon test server's world-contracts deployment. | Extension type stored; `withdraw_item<TradeAuth>` works | If API changed, update function signatures |
| T4 | **Cross-address buy on testnet** | Full buy flow: seller lists → buyer buys → item transferred → payment transferred. | Atomic completion, correct balance deltas | If fails, investigate world-contracts version differences |

### MEDIUM (validate after critical tests pass)

| # | Test | Method | Pass Criteria |
|---|---|---|---|
| T5 | `Metadata.url` update by SSU owner | Call `update_url()` with `OwnerCap<StorageUnit>` | URL field updated, `MetadataChangedEvent` emitted |
| T6 | Inventory query via GraphQL | Use dapp-kit `getObjectWithDynamicFields(ssuId)` to read SSU inventory contents | Item types, quantities, and IDs returned |
| T7 | Event query for trade history | `queryEvents` with our package ID filtering for `TradeSettledEvent` | Events retrievable with all fields indexed |
| T8 | Gas cost for buy PTB | Execute buy tx and measure gas consumption | Under 10M MIST (rough estimate for budget planning) |

### LOW (nice-to-have)

| # | Test | Method | Pass Criteria |
|---|---|---|---|
| T9 | Quantity handling | List and buy an item with `quantity > 1`. Verify full item is withdrawn. | Understand if we need quantity-1 items or can handle bulk |
| T10 | Multiple listings on same SSU | Create 3+ listings for different `type_id` values under one `ExtensionConfig` | Dynamic fields scale; no object size issues |
| T11 | Listing cancel + re-list cycle | Create → cancel → re-create listing for same `type_id` | No stale state issues |

---

## D) Doc Corrections Needed

### 1. Demo Beat Sheet — Sandbox Mock Event Names

[civilizationcontrol-demo-beat-sheet.md](../core/civilizationcontrol-demo-beat-sheet.md):

- **Beat 5** references `AccessGrant event` → should reference `TollCollectedEvent` (our custom extension event)
- **Beat 6** references `ItemPurchased event` → should reference `TradeSettledEvent` (our custom extension event)
- **Evidence Capture Checklist** row for Beat 5 says `AccessGrant event` → `TollCollectedEvent`
- **Evidence Capture Checklist** row for Beat 6 says `ItemPurchased event` → `TradeSettledEvent`

These sandbox mock event names were already flagged in [read-path-architecture-validation.md §6.1](read-path-architecture-validation.md) but the beat sheet was not updated.

### 2. Partial-Quantity Withdraw Constraint

~~Not documented anywhere. `withdraw_item` returns the FULL `Item` object for a given `type_id` (entire quantity). There is no partial-quantity withdrawal. Design implication: listings should represent the full item quantity, or the extension must implement quantity splitting logic (split item → withdraw → deposit remainder).~~

> **RESOLVED (v0.0.15):** `withdraw_item<Auth>` now accepts `quantity: u32`, enabling partial withdrawals. Quantity splitting workarounds are no longer required.

### 3. SSU dApp Interaction Model

No existing doc captures the finding that ALL builder-documentation pages for in-game dApp connection are `//TODO`. The strongest available signal is:
- `Metadata.url` field on SSU (plausible dApp URL slot)
- dapp-kit accepts `?assemblyId=0x...` URL parameter
- No confirmation that the game client reads `Metadata.url`

---

## E) In-Game dApp Loading Mechanism — Platform Status

> **Re-checked:** 2026-02-19 — submodules synced to latest, live GitBook cross-validated

### Verdict: STILL UNKNOWN

No documented mechanism exists for how the EVE Frontier game client loads or presents a builder's dApp when a player interacts with an SSU. This finding is unchanged after updating submodules and cross-checking the live GitBook.

### Evidence (exhaustive)

| Source | Version / Date | Finding |
|---|---|---|
| `vendor/builder-documentation/dapps/connecting-in-game.md` | 185d7a8 | Content: `//TODO` only |
| `vendor/builder-documentation/dapps/dapps-quick-start.md` | 185d7a8 | Content: `//TODO` only |
| `vendor/builder-documentation/dapps/connecting-from-an-external-browser.md` | 185d7a8 | Content: `//TODO` only |
| `vendor/builder-documentation/dapps/customizing-external-dapps.md` | 185d7a8 | Content: `//TODO` only |
| Live GitBook `docs.evefrontier.com/dapps/connecting-in-game` | Fetched 2026-02-19, "updated 7 days ago" | Content: `//TODO` only — matches local |
| Live GitBook `docs.evefrontier.com/dapps/dapps-quick-start` | Fetched 2026-02-19, "updated 7 days ago" | Content: `//TODO` only — matches local |
| Live GitBook `docs.evefrontier.com/dapp-kit-sdk/dapp-kit` | Fetched 2026-02-19 | Fully populated (304 lines). Describes **external browser** dApp SDK only. No in-game loading. Matches local. |
| `vendor/builder-documentation/dapp-kit/dapp-kit.md` | 185d7a8 | React SDK: `useSmartObject()`, `useConnection()`, ~~`useSponsoredTransaction()`~~. Assembly ID via `?assemblyId=0x...` URL param. No in-game rendering API. |

> **UPDATED (v0.0.15):** `useSponsoredTransaction()` hook is removed from dapp-kit. The pattern is now `useDAppKit()` for sponsored transaction flows.
| `vendor/builder-documentation/smart-assemblies/storage-unit/README.md` | 185d7a8 (unchanged) | 131 lines. Covers inventory + extensions. Zero mention of embedded browser, iframe, dApp URL, in-game UI. |
| `vendor/builder-documentation/SUMMARY.md` | 185d7a8 | TOC unchanged — same 4 //TODO dApp pages. No new pages added. |
| `vendor/world-contracts/.../metadata.move` | v0.0.13 @ e508451 | `Metadata { name, description, url }`. `update_url()` is owner-callable. No on-chain loading mechanism. |
| `vendor/world-contracts/.../storage_unit.move` | v0.0.13 @ e508451 | No new functions related to dApp loading. Same API surface as prior version. |

### Strongest Available Signal

1. **`Metadata.url`** on SSU/Gate structs is the only plausible slot for a dApp URL. Owner-updatable via `update_url()`.
2. **dapp-kit** accepts `?assemblyId=0x...` as a URL parameter, implying the client may pass the assembly ID to an external URL.
3. **CCP has 4 placeholder pages** in the docs TOC for dApps — the structure is pre-planned but content is unwritten.
4. **No confirmation** exists that the game client reads `Metadata.url`, opens an iframe, or presents any embedded browser.

### Implications for March 11

- **T1 and T2 remain CRITICAL** — these are the first tests to run on the hackathon test server
- If the game client does NOT embed dApps, the buyer interacts via external browser (weaker demo narrative but functional)
- The fallback demo variant (GateControl-only, 2 min) is unaffected — it requires no in-game dApp embedding
- **Recommendation:** Check EVE Frontier builder Discord channels for player reports or CCP guidance on SSU interaction UX before March 11

### world-contracts v0.0.13 Changes (relevant to TradePost)

- `inventory.move`: New validation `EItemVolumeMismatch` (error code 5) — `deposit_item` now rejects items whose `volume` field differs from existing items with the same `type_id`. ~~No impact on `withdraw_item` (still full-quantity only).~~
- No new trade/payment/marketplace primitives added.
- ~~No partial-quantity withdraw added.~~

> **RESOLVED (v0.0.15):** `withdraw_item<Auth>` now accepts `quantity: u32` for partial withdrawals. `EItemVolumeMismatch` error is removed in v0.0.15. `deposit_item<Auth>` now validates `parent_id` (items only return to origin SSU). New `deposit_to_owned<Auth>` enables cross-player delivery.

---

## Architectural Decision Record

**Decision:** TradePost remains in the hackathon core MVP, but with an explicit in-game UX dependency on March 11 test T1/T2.

**Rationale:**
- On-chain mechanics are fully proven (PASS on all chain-level surfaces)
- The fallback demo variant (GateControl-only) exists if in-game dApp integration is unavailable
- Even without in-game embedding, TradePost can be demonstrated via external browser + on-chain evidence overlays, which still proves atomic settlement
- The "buyer journey" narrative is strongest with in-game interaction but survivable without it

**Consequence:** Day 1 of hackathon, T1 and T2 must run before committing to TradePost in the demo video. If both fail, pivot to the fallback variant and relegate TradePost to "bonus" with external browser demo.

---

## References

- [Cross-Address PTB Validation](tradepost-cross-address-ptb-validation.md)
- [Read-Path Architecture Validation](read-path-architecture-validation.md)
- [Shortlist Viability Validation Report](../operations/shortlist-viability-validation-report.md)
- [Demo Beat Sheet](../core/civilizationcontrol-demo-beat-sheet.md)
- [March 11 Reimplementation Checklist](../core/march-11-reimplementation-checklist.md)
- [Product Vision](../strategy/civilization-control/civilizationcontrol-product-vision.md)
- builder-documentation SSU docs: `vendor/builder-documentation/smart-assemblies/storage-unit/README.md`
- builder-documentation dapp-kit: `vendor/builder-documentation/dapp-kit/dapp-kit.md`
- world-contracts source: `vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move`
- world-contracts inventory: `vendor/world-contracts/contracts/world/sources/primitives/inventory.move`
