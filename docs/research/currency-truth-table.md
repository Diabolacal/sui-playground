# Currency Truth Table — EVE Frontier Ecosystem

**Retention:** Prep-only

> **Date:** 2026-03-03 (revalidated; originally 2026-02-16, interim update 2026-02-28)
> **Sources:** world-contracts Move code, EVE Frontier GitBook (via reference map), Sui docs reference map, builder-documentation submodule, internal strategy/ideas docs, validation reports
> **Purpose:** Single source of truth for the currency/token model as understood from this workspace

> **2026-03-10 submodule refresh:** Builder-scaffold `tokens/` package removed entirely. References to `tokens.move` below point to a deleted path.

---

## Summary

| Question | Answer | Confidence |
|----------|--------|------------|
| What players earn in-game | **LUX** (in-game currency) | Medium — mentioned in GitBook EVE Vault page only; no on-chain implementation found |
| What on-chain token exists | **EVE Token** (`Coin<EVE>`) | High — implemented in world-contracts v0.0.13 (`contracts/assets/sources/EVE.move`): 10B supply, 9 decimals, OTW via `coin_registry` |
| Tolls/prices use which token | **`Coin<SUI>`** in all builder code and validated examples | High — devnet-validated; all existing toll/trade code uses `Coin<SUI>` |
| Sponsored transactions supported | **Yes** — documented and implemented in Move code | High — `verify_sponsor()` in `access_control.move`, `AdminACL` with `authorized_sponsors` |
| Exchange rate (LUX ↔ EVE Token) | **10,000 Lux = 1 EVE token** | Medium — observed in live Ethereum cycle UI; not in builder docs; requires sandbox confirmation |
| Fixed or variable rate | **Not documented** | N/A |
| Move module/struct for EVE Token | **`Coin<EVE>`** in `contracts/assets/sources/EVE.move` | High — separate `AdminCap` + `EveTreasury` (deployer-owned); burn-only supply after init |

---

## 1. What Players Earn In-Game: LUX

| Fact | Source | Citation |
|------|--------|----------|
| LUX is the in-game currency | EVE Frontier GitBook → EVE Vault Introduction page | [evefrontier-builder-docs-map.md](evefrontier-builder-docs-map.md#L197): "Provides economic context (LUX for in-game, EVE Token for ecosystem)" |
| LUX is described as one of "two primary currencies" | EVE Frontier GitBook → EVE Vault Introduction page | [evefrontier-builder-docs-map.md](evefrontier-builder-docs-map.md#L201): "Mentions LUX and EVE Token as the two primary currencies — not documented in our code" |
| LUX has **no on-chain implementation** in world-contracts | Code search of all `.move` files | Grep for `Lux\|LUX\|lux` across `vendor/world-contracts/**/*.move` — zero matches |
| LUX is **not referenced** in any Move module, struct, or function | Code search | No `Coin<LUX>`, no `LUX` struct, no mint/burn functions for LUX exist |

**Assessment:** LUX appears to be a game-server-side currency, not an on-chain token. It is mentioned only in the EVE Frontier GitBook documentation (EVE Vault introduction page) and in our internal reference map's notes about that page. There is no Move code implementing LUX.

---

## 2. On-Chain Token: EVE Token

| Fact | Source | Citation |
|------|--------|----------|
| EVE Token is described as the "ecosystem" token | EVE Frontier GitBook → EVE Vault Introduction page | [evefrontier-builder-docs-map.md](evefrontier-builder-docs-map.md#L196-L197) |
| EVE Token now has a **`Coin<EVE>` implementation** in world-contracts (v0.0.13) | `contracts/assets/sources/EVE.move` | `Coin<EVE>`: 10B supply, 9 decimals, OTW pattern via `coin_registry`. Separate `AdminCap` (not world AdminACL) + `EveTreasury` (deployer-owned). Functions: `transfer_from_treasury`, `burn_from_treasury`. |
| world-contracts has a TODO to "mint initial supply of eve tokens" | `world.move` line 8 | [world.move](../../vendor/world-contracts/contracts/world/sources/world.move#L8): `// TODO: mint initial supply of eve tokens` |
| The `init()` function in `world.move` only creates a `GovernorCap` — no token minting | `world.move` lines 1-16 | [world.move](../../vendor/world-contracts/contracts/world/sources/world.move#L9-L15) |
| Inventory module has a TODO about using `Coin<T>` for items | `inventory.move` line 42 | [inventory.move](../../vendor/world-contracts/contracts/world/sources/primitives/inventory.move#L42): `// TODO: Use Sui's Coin<T> and Balance<T> for stackability` |
| Builder scaffold has an empty tokens template | `tokens.move` | [tokens.move](../../vendor/builder-scaffold/move-contracts/tokens/sources/tokens.move#L4): `public fun template() {}` (empty stub; `// TODO: Implement` comment removed as of 2026-02-18 sync) |
| Internal analysis confirms no coin/token module exists | Multiple internal docs | [hackathon-ideas-v2-doc-enabled.md](../ideas/hackathon-ideas-v2-doc-enabled.md#L61): "world-contracts has no coin/token module" |

**Assessment:** ~~Previously unimplemented.~~ As of world-contracts v0.0.13 (commit e508451), `Coin<EVE>` is implemented in `contracts/assets/sources/EVE.move`. It uses the OTW pattern via `coin_registry` with 10B supply and 9 decimals. It has a separate `AdminCap` (distinct from the world `AdminACL`) and an `EveTreasury` object owned by the deployer. Functions include `transfer_from_treasury`, `burn_from_treasury`, `complete_registration`, `treasury_balance`, `update_description`, and `update_icon_url`, with a 10M initial deployer allocation and burn-only supply after init. In the live Ethereum-based Frontier cycle, an EVE token is also surfaced in-game with Lux conversion.

**TS Tooling (Updated 2026-03-03):** Two CCP-internal scripts exist in `world-contracts/ts-scripts/assets/`: `transfer-eve.ts` (transfers EVE from deployer treasury) and `finalize-eve-currency.ts` (registers `Currency<EVE>` in Sui's `CoinRegistry` at 0xc). Both require `ASSETS_PACKAGE_ID` and `GOVERNOR_PRIVATE_KEY` env vars. These are deployment scripts, not builder-facing. The coin type string is `${ASSETS_PACKAGE_ID}::EVE::EVE`. No builder-scaffold scripts reference `Coin<EVE>`.

### Implementation State Clarification

| Environment | EVE Token Status | Notes |
|---|---|---|
| **Ethereum live cycle** | EVE token exists in current deployment | Surfaced in-game with Lux conversion (observed rate: 10,000 Lux = 1 EVE) |
| **Sui world-contracts repo** | `Coin<EVE>` implemented (v0.0.13) | `contracts/assets/sources/EVE.move`: 10B supply, 9 decimals, OTW via `coin_registry`, separate AdminCap + EveTreasury (deployer-owned) |
| **Devnet validation** | Uses `Coin<SUI>` for settlement | All builder examples and validated flows use SUI |
| **March 11 sandbox** | Must verify official economic token type | May differ from both live Ethereum cycle and current Sui contracts |

---

## 3. Tolls and Prices: What Token Type Is Used

| Fact | Source | Citation |
|------|--------|----------|
| All validated toll/trade flows use **`Coin<SUI>`** | Devnet validation report | [shortlist-viability-validation-report.md](../operations/shortlist-viability-validation-report.md#L62-L66): "price = 1,000,000,000 MIST (1 SUI)" and "`request_access()` with 1 SUI `Coin<SUI>` payment" |
| TradePost buy flow uses `Coin<SUI>` for payment | Devnet validation + architecture doc | [tradepost-cross-address-ptb-validation.md](../architecture/tradepost-cross-address-ptb-validation.md#L205): `payment: Coin<SUI>` |
| Prices are expressed in MIST (smallest SUI unit) | Validation report + architecture doc | [tradepost-cross-address-ptb-validation.md](../architecture/tradepost-cross-address-ptb-validation.md#L339): `price: u64, // price in MIST (smallest SUI unit)` |
| Product vision describes tolls as "SUI toll" throughout | Strategy doc | [civilizationcontrol-product-vision.md](../strategy/civilization-control/civilizationcontrol-product-vision.md#L35): "Tribe 12: 0.5 SUI toll" |
| Gate.move has **no built-in toll/payment mechanism** | Code search of gate.move | Grep for `coin\|toll\|price\|payment\|fee\|SUI` in gate.move — only `use sui::` import matches; no payment logic in the base gate module |
| Extension examples use **item-based bounties**, not coin payments | corpse_gate_bounty.move | [corpse_gate_bounty.move](../../vendor/world-contracts/contracts/extension_examples/sources/corpse_gate_bounty.move#L8): bounty requires depositing an Item (corpse), not paying coins |
| Builder docs gate extension example uses **generic `Coin<T>`** for toll payment | Builder documentation submodule | [gate/build.md](../../vendor/builder-documentation/smart-assemblies/gate/build.md#L140): `payment: Coin<T>,` with comment "verify payment amount, token type, allowlist, etc." (Updated 2026-03-03) |
| Builder docs SSU vending machine example uses **`Coin<SUI>`** explicitly | Builder documentation submodule | [storage-unit/README.md](../../vendor/builder-documentation/smart-assemblies/storage-unit/README.md#L95): `payment: Coin<SUI>,` |
| The `Coin<T>` pattern is generic — custom tokens (e.g., `Coin<TribeToken>`) could be used | Strategy memo + ideas docs | [civilizationcontrol-strategy-memo.md](../strategy/civilization-control/civilizationcontrol-strategy-memo.md#L130): "GateControl to accept ALPHA_COIN as toll, the toll rule must know the coin type at compile time" |
| Supporting both `Coin<SUI>` and `Coin<CustomToken>` requires separate buy functions or generic `Coin<T>` parameterization | Strategy memo | [civilizationcontrol-strategy-memo.md](../strategy/civilization-control/civilizationcontrol-strategy-memo.md#L132) |

**Assessment:** All implemented and validated toll/price mechanics use **`Coin<SUI>`** denominated in MIST. The base world-contracts gate module has no built-in payment logic — tolls are implemented at the **extension layer** by builders. The existing extension examples use item-based bounties (corpses), not coin payments. `Coin<SUI>` toll collection was successfully validated on devnet as a custom extension pattern.

---

## 4. Sponsored Transactions

| Fact | Source | Citation |
|------|--------|----------|
| `verify_sponsor()` function exists in `access_control.move` | Move source code | [access_control.move](../../vendor/world-contracts/contracts/world/sources/access/access_control.move#L158): `public fun verify_sponsor(admin_acl: &AdminACL, ctx: &TxContext)` |
| Checks that `tx_context::sponsor(ctx)` is present and in `authorized_sponsors` table | Move source code | [access_control.move](../../vendor/world-contracts/contracts/world/sources/access/access_control.move#L159-L162) |
| `AdminACL` struct contains `authorized_sponsors: Table<address, bool>` | Move source code | [access_control.move](../../vendor/world-contracts/contracts/world/sources/access/access_control.move#L37-L39) |
| `add_sponsor_to_acl()` requires `GovernorCap` | Move source code | [access_control.move](../../vendor/world-contracts/contracts/world/sources/access/access_control.move#L200-L205) |
| Gate operations call `admin_acl.verify_sponsor(ctx)` | gate.move | [gate.move](../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L262): `admin_acl.verify_sponsor(ctx)` |
| Storage Unit operations call `admin_acl.verify_sponsor(ctx)` | storage_unit.move | [storage_unit.move](../../vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L580) |
| Network Node operations call `admin_acl.verify_sponsor(ctx)` | network_node.move | [network_node.move](../../vendor/world-contracts/contracts/world/sources/network_node/network_node.move#L101) |
| Pattern: `tx.setSender(playerAddress)` + `tx.setGasOwner(adminAddress)` | GitBook "Interfacing with the EVE Frontier World" page | [evefrontier-builder-docs-map.md](evefrontier-builder-docs-map.md#L167-L168) |
| Sponsor must be in `AdminACL` — this is a **game-level overlay** on top of Sui's native sponsorship | Sui docs reference map | [sui-documentation-reference-map.md](sui-documentation-reference-map.md#L87-L89) |
| Test helpers add sponsor to ACL | test_helpers.move | [test_helpers.move](../../vendor/world-contracts/contracts/world/tests/test_helpers.move#L112): `access::add_sponsor_to_acl(&mut admin_acl, &gov_cap, admin())` |

**Assessment:** Sponsored transactions are **fully implemented and documented**. The pattern operates at two levels:
1. **Sui protocol level:** Any address can sponsor any transaction's gas via `setSender()` + `setGasOwner()` dual-signing
2. **EVE Frontier game level:** `verify_sponsor()` additionally checks that the gas sponsor address is whitelisted in the `AdminACL.authorized_sponsors` table

All world-contract admin operations (gate creation, SSU creation, network node operations) require sponsored transactions via `verify_sponsor()`.

**dapp-kit Integration (Updated 2026-03-04):** ~~The `useSponsoredTransaction()` React hook was documented in early `@evefrontier/dapp-kit` versions but was **removed in v0.0.15**.~~ Sponsored transactions are now handled via `useDAppKit()` from `@mysten/dapp-kit-react` for standard signing, or via the EVE Vault extension's custom `evefrontier:sponsoredTransaction` wallet feature for gas-free operations (see EveVault `sponsoredTransactionHandler.ts`).

---

## 5. Exchange Rate Details (LUX ↔ EVE Token)

| Fact | Source | Citation |
|------|--------|----------|
| **Observed exchange rate: 10,000 Lux = 1 EVE token** | Live Ethereum-based Frontier cycle UI | Observed in current live cycle UI; requires sandbox confirmation. Not documented in official builder docs or world-contracts code. |
| No exchange rate is documented in builder-facing sources | Full-text search across all `docs/**` and world-contracts code | No builder documentation, GitBook page, or Move code specifies a Lux-to-EVE conversion ratio |
| Exchange rates between faction tokens and SUI are described as "market-determined" for custom currencies | Ideas doc | [hackathon-ideas-v2-doc-enabled.md](../ideas/hackathon-ideas-v2-doc-enabled.md#L65): "Exchange rate between faction tokens and SUI is market-determined (manual OTC or Kiosk-based swap)" |

**Assessment:** The exchange rate of **10,000 Lux = 1 EVE token** has been observed in the current live Ethereum-based Frontier cycle UI, but this rate is not documented in any official builder documentation or world-contracts code. The rate may differ between cycles, chains, or game states. Builders should treat this as an observed data point requiring sandbox confirmation, not an architectural constant.

---

## 6. Fixed vs Variable Rate

**Not applicable.** No rate is documented. See Section 5.

---

## 7. Move Module/Struct Names for Token

### Existing Structs (world-contracts)

| Module | Struct | File | Line | Purpose |
|--------|--------|------|------|---------|
| `world::world` | `GovernorCap` | [world.move](../../vendor/world-contracts/contracts/world/sources/world.move#L3-L6) | 3-6 | Top-level governance capability; **NOT a token** |
| `world::inventory` | `Item` | [inventory.move](../../vendor/world-contracts/contracts/world/sources/primitives/inventory.move#L46-L54) | 46-54 | In-game item representation (has `key, store`); **NOT a Coin** |
| `world::access` | `AdminACL` | [access_control.move](../../vendor/world-contracts/contracts/world/sources/access/access_control.move#L37-L39) | 37-39 | Contains `authorized_sponsors` for sponsored tx verification |

### Token-Related Code Status

> **Updated 2026-02-28:** `Coin<EVE>` now exists as of world-contracts v0.0.13 (commit e508451).

| Expected | Status | Evidence |
|----------|--------|----------|
| `Coin<EVE>` | **Now exists** (v0.0.13) | `contracts/assets/sources/EVE.move`: 10B supply, 9 decimals, OTW via `coin_registry`, separate AdminCap + EveTreasury (deployer-owned) |
| `Coin<LUX>` | **Does not exist** | Zero matches across all `.move` files |
| `TreasuryCap<EVE>` | **Managed via `coin_registry`** | EVE uses OTW pattern; treasury cap is consumed during `coin_registry` registration (`make_supply_burn_only_init`) |
| `TreasuryCap<LUX>` | **Does not exist** | Zero matches |
| `coin::create_currency()` call | **Exists for EVE** | Used in `EVE.move` via `coin_registry::new_currency_with_otw` |
| `Balance<T>` usage for tokens | **Exists for EVE** | `EveTreasury` holds `Balance<EVE>` |
| `tokens::tokens` scaffold | **Empty stub** | [tokens.move](../../vendor/builder-scaffold/move-contracts/tokens/sources/tokens.move#L4): `public fun template() {}` (TODO comment removed as of 2026-02-18 sync) |

### Key TODO Comments

| File | Line | Comment |
|------|------|---------|
| [world.move](../../vendor/world-contracts/contracts/world/sources/world.move#L8) | 8 | `// TODO: mint initial supply of eve tokens` |
| [inventory.move](../../vendor/world-contracts/contracts/world/sources/primitives/inventory.move#L44) | 44 | `// TODO: Use Sui's Coin<T> and Balance<T> for stackability` (Updated 2026-03-03: line shifted from 42→44) |

---

## Cross-Reference: Currency Usage Across Internal Documents

| Document | Currency References | Key Takeaway |
|----------|-------------------|--------------|
| [civilizationcontrol-product-vision.md](../strategy/civilization-control/civilizationcontrol-product-vision.md) | SUI tolls (0.2–0.5 SUI), SUI-priced storefronts, `Coin<TribeToken>` as stretch goal | Core product uses SUI; faction currency is stretch |
| [civilizationcontrol-strategy-memo.md](../strategy/civilization-control/civilizationcontrol-strategy-memo.md) | `Coin<SUI>` default, `Coin<T>` generic for TribeMint stretch, `Coin<T>` cross-module complexity noted | SUI-denominated is the safe path; custom tokens add risk |
| [hackathon-ideas-grounded-v3-judged.md](../ideas/hackathon-ideas-grounded-v3-judged.md) | "5 SUI" prices, "1 SUI" tolls throughout | All concrete examples use SUI |
| [hackathon-ideas-v2-doc-enabled.md](../ideas/hackathon-ideas-v2-doc-enabled.md) | `Coin<SUI>` for V1 ideas, `Coin<TribeToken>` for Faction Mint idea | Custom tokens are a new idea on top of SUI base |
| [shortlist-viability-validation-report.md](../operations/shortlist-viability-validation-report.md) | All tests use `Coin<SUI>`, prices in MIST | Only SUI has been validated on devnet |
| [tradepost-cross-address-ptb-validation.md](../architecture/tradepost-cross-address-ptb-validation.md) | `Coin<SUI>` throughout, one mention of `Coin<TribeToken>` compatibility | Architecture designed for SUI, extensible to custom `Coin<T>` |
| [evefrontier-builder-docs-map.md](evefrontier-builder-docs-map.md) | LUX + EVE Token mentioned from GitBook | Only doc referencing official CCP currencies |
| [sui-documentation-reference-map.md](sui-documentation-reference-map.md) | `Coin<T>` / `TreasuryCap<T>` as Sui standards | `Coin<EVE>` now implemented in world-contracts v0.0.13 via `coin_registry` OTW pattern |

---

## Conclusions

1. **LUX is a game-server currency**, not an on-chain token. It is mentioned only in the EVE Frontier GitBook and has no Move implementation.

2. **EVE Token is now implemented.** As of world-contracts v0.0.13, `Coin<EVE>` exists in `contracts/assets/sources/EVE.move` (10B supply, 9 decimals, separate AdminCap + EveTreasury, burn-only after init with 10M deployer allocation). The `// TODO: mint initial supply of eve tokens` comment remains in `world.move` line 8, but token creation is handled in the separate `assets` package via `EVE.move`'s `init()`. CCP-internal TS scripts exist for treasury operations (`transfer-eve.ts`, `finalize-eve-currency.ts`). (Updated 2026-03-03)

3. **All builder-accessible currency operations currently use `Coin<SUI>`** (native Sui token). Tolls, trades, and prices are denominated in SUI/MIST. This is the only validated on-chain payment mechanism.

4. **Sponsored transactions are fully implemented** via `AdminACL.authorized_sponsors` + `verify_sponsor()` in `access_control.move`. All admin operations require sponsored transactions.

5. **No LUX ↔ EVE Token exchange rate exists** in any documentation or code in this workspace. The observed "10,000 Lux = 1 EVE" ratio from the live Ethereum cycle UI remains unsubstantiated in builder documentation or Move code.

6. **Custom tokens are possible via Sui's `Coin<T>` standard** but would need to be built from scratch. The builder-scaffold provides only an empty `tokens.move` stub. The TribeMint/Faction Mint concept (custom `Coin<TribeToken>`) is documented as a hackathon idea but has not been implemented.

7. **The gate module has no built-in toll mechanism.** Tolls are implemented as **extensions** using the dynamic field rule dispatch pattern, entirely at the builder layer.
