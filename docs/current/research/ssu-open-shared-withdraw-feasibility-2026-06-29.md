# SSU Open Shared Withdraw Feasibility — 2026-06-29

**Retention:** Prep-only

**Status:** Active research artifact (source-grounded feasibility + cheap validation spike).
**Audience:** Operator (non-coder) + a downstream agent who will build the smallest prototype.
**Scope guard:** This pass is a *feasibility document*. It does **not** build the production dApp,
a marketplace, shared tribe storage, dashboards, audit timelines, pricing, or permission systems. It
answers one question: *can a connected player open a shared storage area in an SSU, pick an item +
quantity, and withdraw it into their own slot in that same SSU?*

---

## Executive Verdict

**Feasible with caveats — buildable now on the current contracts, with one small new Move extension
package required.**

In plain English: **Yes, this works today.** The current EVE Frontier world contracts (v0.0.24,
the version live on `testnet_stillness`) already contain everything the on-chain side needs:

- a **shared/"open" inventory** area inside every Smart Storage Unit that a registered extension can
  withdraw from (`withdraw_from_open_inventory`), and
- a **per-player owned inventory** slot inside the same SSU that a registered extension can deposit
  into (`deposit_to_owned`), created automatically the first time a player receives something.

A tiny custom Move "extension" (one witness type + one function ≈ 30 lines) chains those two calls in
a single transaction, so the item moves from the shared area straight into the calling player's own
slot. The SSU owner authorizes that extension once. After that, players claim with a single
gas-paid transaction; **no admin, no sponsor, and no capability object is required on the claim path.**

The **caveats** are real but small, and none of them block a prototype:

1. **A new Move package must be published.** The flow cannot be done with stock world functions alone
   — the open-inventory functions are *extension-gated*, so you must publish and authorize a witness.
   This is the one piece of new on-chain code.
2. **Stocking is a prerequisite.** The shared area is only fillable through the same extension
   (`deposit_to_open_inventory`). Someone (normally the owner) must stock it before anyone can claim.
3. **"Shared" means anyone can drain it.** If the extension lets any character claim, then any
   character can claim *everything* (down to whatever guard you add). For the MVP, the smallest sane
   guard is a self-sender check so items can only land in the caller's *own* slot; a tribe/allowlist
   guard is a clean later upgrade.
4. **Reading the shared area's contents for the UI is the only "hard" part**, and it is optional.
   The minimal UI can ship with a `type_id` + quantity input and skip the decoded table.
5. **Live-chain behavior is unverified.** All evidence here is from source + Move unit tests
   (passing on v0.0.24). No transaction has been run against `testnet_stillness` in this pass.

Technical reasoning follows in *Current Contract Surface*, *Proposed Minimal Flow*, and
*Authorization and Security*.

---

## Plain-English Goal

A player flies up to a Smart Storage Unit (SSU) that has a "free shelf" — a shared area the owner has
stocked. The player opens a small web page (the SSU's custom dApp, reached by pressing **F** in the
game and clicking the unit's URL). The page looks like the game: black background, white text, a
plain table or a couple of input boxes. The player picks an item and a quantity, clicks **"Withdraw
to my SSU inventory,"** signs one transaction in their wallet, and the item moves out of the shared
shelf and into *their own* personal slot inside that same SSU (their "ephemeral inventory"). From
there they can pull it into the game with the normal game→chain bridge.

That is the whole product. No prices, no listings, no escrow, no dashboards.

---

## Source Pinning

| Item | Value |
|------|-------|
| Parent repo | `Diabolacal/sui-playground` |
| Branch | `docs/ssu-open-shared-withdraw-feasibility` |
| Starting commit | `f0e8a06756058ff593daa30f6c7e775893d950f2` |
| `vendor/world-contracts` | `d1929fad79736f6db66b74f946658807ce4704bf` (tag `0.0.24-1-gd1929fa`) |
| `vendor/builder-documentation` | `b4b943eafb1b4f8389f151d2dc9ab5234bf47e9b` |
| `vendor/builder-scaffold` | `ebc321a760e3701954e3d445fa92fe881267ea94` (tag `v0.0.2-2-gebc321a`) |
| `vendor/evevault` | `aad5d109ddc97f402adbe3dd54776dd2213225e4` (tag `v0.0.12-1-gaad5d10`) — referenced for wallet only, not deeply audited |
| `vendor/eve-frontier-proximity-zk-poc` | `4078e70791afaf4baa579b52d34cc1ef5a87c1eb` — not consulted (irrelevant to this flow) |
| Sui CLI | `sui 1.68.1-3c0f387ebb40-dirty` |
| Active Sui env | `testnet_stillness` (RPC `https://fullnode.testnet.sui.io:443`, chain-id `4c78adac`) |
| `world` package on `testnet_stillness` | `0x8b8a46ed766fa1358ce7c5c51f6a164b13d627a63e45343f69ed0ba0446c1aa1` (version 1; `original-id` == `published-at`) — from `contracts/world/Published.toml` |
| Date | 2026-06-29 |

> All four `testnet_*` deployments in `Published.toml` share chain-id `4c78adac` — they are different
> `world` package instances on the **same Sui testnet chain**, not different chains. `stillness` is the
> currently-active instance.

---

## Source Files Reviewed

**world-contracts (canonical Move):**
- `contracts/world/sources/assemblies/storage_unit.move` — full read (1083 lines)
- `contracts/world/sources/primitives/inventory.move` — full read (556 lines)
- `contracts/world/sources/character/character.move` — full read (293 lines)
- `contracts/world/sources/access/access_control.move` — full read (305 lines)
- `contracts/world/sources/assemblies/extension_freeze.move` — full read
- `contracts/world/tests/assemblies/storage_unit_tests.move` — witness/template + open-inventory and
  `deposit_to_owned` tests (lines 1–175, 2089–2431)
- `contracts/extension_examples/sources/config.move` — `XAuth` witness + `ExtensionConfig` rule pattern
- `contracts/world/Move.toml`, `contracts/world/Published.toml`

**world-contracts TS scripts:**
- `ts-scripts/storage-unit/helper.ts`, `withdraw-deposit.ts`, `deposit-to-ephemeral-inventory.ts`,
  `game-item-to-chain.ts`
- `ts-scripts/builder_extension/authorise-storage-unit.ts`
- `ts-scripts/utils/config.ts`, `ts-scripts/utils/dev-inspect.ts`

**builder-documentation:**
- `smart-assemblies/storage-unit/README.md`, `smart-assemblies/storage-unit/build.md`
- `dapps/connecting-in-game.md`, `tools/dapp-kit.md`

**builder-scaffold:**
- `move-contracts/storage_unit_extension/sources/storage_unit_extension.move` (stub), `Move.toml`

**Existing sui-playground docs (reused, revalidated):**
- `docs/architecture/world-contracts-auth-model.md` (auth model; predates v0.0.24 freeze/open-inventory)
- `docs/validation/ssu-extension-e2e-validation.md` (TP-05; validated `withdraw_item`+`deposit_to_owned` on v0.0.15)
- `docs/current/research/project-ideation-2026-06-27/implementation-briefs/ssu-inventory-intelligence.md`
  (read-path findings; **a different, larger project** — see *Non-duplication*)

---

## Current Contract Surface

All paths below are `contracts/world/sources/...` in `vendor/world-contracts` at `d1929fa`. Line
numbers are from that commit.

### The three inventories inside an SSU

A `StorageUnit` (`storage_unit.move:87`) stores its inventories as **dynamic fields** keyed by `ID`,
with the keys tracked in `inventory_keys: vector<ID>`:

| Inventory | Dynamic-field key | Created | Who can write |
|-----------|-------------------|---------|---------------|
| **Main / "primary"** (owner's hangar) | `storage_unit.owner_cap_id` | at `anchor` | owner (`*_by_owner`) or extension (`deposit_item`/`withdraw_item`) |
| **Open / "shared"** | `open_storage_key(su)` — a derived ID | at `anchor` (v0.0.24); lazily for older SSUs | **extension only** (`deposit_to_open_inventory` / `withdraw_from_open_inventory`) |
| **Owned / "ephemeral"** (per player) | `character.owner_cap_id()` | lazily on first deposit | owner-direct, bridge, or **extension** (`deposit_to_owned`) |

- **Open inventory key** is deterministic: `open_storage_key_from_id` =
  `blake2b256( bcs(storage_unit_id) ++ b"open_inventory" )` → address → `ID` (`storage_unit.move:882`).
  Public view `open_storage_key(su): ID` (`:578`) and `has_open_storage(su): bool` (`:583`).
- **Open inventory is created at anchor** in v0.0.24 (`anchor` pushes `owner_cap_id` then
  `open_inv_key`, both with the SSU's `max_capacity` — `storage_unit.move:638-647`). For SSUs anchored
  *before* open storage existed, `ensure_open_inventory` (`:893`) creates it lazily on first
  `deposit_to_open_inventory`. **`withdraw_from_open_inventory` does *not* create it** — it asserts
  existence and aborts `EOpenStorageNotInitialized` if absent (`:362-363`).
- **Owned/"ephemeral" inventory is keyed by `character.owner_cap_id()`** and **auto-created** by
  `deposit_to_owned` if missing, bootstrapping capacity from the owner inventory
  (`storage_unit.move:402-410`). The builder docs call this the "ephemeral inventory"; the script
  `deposit-to-ephemeral-inventory.ts` confirms: *"Ephemeral inventory is owned by the character."*
  **Open ≠ owned**: they are two different dynamic-field slots.

### The two functions the flow needs (verified signatures)

```move
// storage_unit.move:348 — extension-only withdraw from the shared/open area.
public fun withdraw_from_open_inventory<Auth: drop>(
    storage_unit: &mut StorageUnit,
    character: &Character,
    _: Auth,
    type_id: u64,
    quantity: u32,
    ctx: &mut TxContext,
): Item

// storage_unit.move:383 — extension-authorized deposit into a player's owned/ephemeral inventory.
public fun deposit_to_owned<Auth: drop>(
    storage_unit: &mut StorageUnit,
    character: &Character,
    item: Item,
    _: Auth,
    _: &mut TxContext,
)
```

Guards inside these functions (current source):

- **Both** require `storage_unit.extension.contains(type_name::with_defining_ids<Auth>())` — i.e. the
  `Auth` witness type must be the registered extension (`:357-359`, `:391-393`). Wrong/forged witness
  aborts `EExtensionNotAuthorized`.
- **Both** require the SSU to be online (`ENotOnline`, `:361`, `:395`).
- `withdraw_from_open_inventory` requires the open inventory to exist (`EOpenStorageNotInitialized`,
  `:363`) and the item to exist in it (`EItemDoesNotExist` from `inventory.move:380`).
- `deposit_to_owned` requires `item.tenant() == su.key.tenant()`, `character.tenant() ==
  su.key.tenant()`, and **`item.parent_id() == storage_unit_id`** (`:396-398`).
- **Neither function checks `ctx.sender()`.** There is *no* built-in "is this the caller's character"
  check on the claim path. Any sender-binding guard must live in *your* extension. (Contrast the
  owner-direct `withdraw_by_owner`/`deposit_by_owner`, which *do* assert
  `character.character_address() == ctx.sender()` and require an `OwnerCap` + proximity proof.)

### Why the two halves compose (the "same SSU" guarantee)

`withdraw_from_open_inventory` calls `inventory::withdraw_item(..., assembly_id = storage_unit_id,
...)`, and `inventory::withdraw_item` stamps the returned transit `Item` with `parent_id =
assembly_id` (`inventory.move:412`). So an item withdrawn from the open area of SSU *X* has
`parent_id == X`. `deposit_to_owned` then accepts it because its check is exactly `item.parent_id() ==
storage_unit_id` for the **same** SSU *X* (`storage_unit.move:398`). Tenants also match because items
only enter the open area via `deposit_to_open_inventory`, which stamps the SSU's tenant. **The
open→owned hop within one SSU is structurally valid.** (Cross-SSU is correctly *rejected* — see the
passing `test_deposit_to_owned_fail_parent_id_mismatch`.)

### Events (v0.0.24 — the breaking change matters here)

`inventory.move` now emits **V2** events carrying an `inventory_key: ID`:

- Withdraw emits `ItemWithdrawnEventV2 { assembly_id, assembly_key, inventory_key, character_id,
  character_key, item_id, type_id, quantity }` (`inventory.move:399`).
- Deposit emits `ItemDepositedEventV2 { ... inventory_key ... }` (`inventory.move:351`).

A full claim therefore emits, in order: `ItemWithdrawnEventV2 { inventory_key = open_storage_key }`
then `ItemDepositedEventV2 { inventory_key = character.owner_cap_id }`. The legacy
`ItemWithdrawnEvent` / `ItemDepositedEvent` structs still *exist* but are **no longer emitted** (the
Move compiler now flags their fields as unused — observed during validation). **Any indexer or script
listening for the non-V2 names will silently miss every deposit/withdraw.** This is the #155 breaking
change flagged in the June 2026 submodule-refresh note, and it is the single most important
stale-code trap for this build.

### Extension authorization / freeze / revoke

- `authorize_extension<Auth: drop>(su, owner_cap: &OwnerCap<StorageUnit>)` (`:127`) — registers the
  witness type. Requires only the SSU's `OwnerCap` (no admin/sponsor). Uses `swap_or_fill`, so the
  owner can replace it later — **unless frozen**.
- `freeze_extension_config(su, owner_cap)` (`:147`) — one-time, irreversible; after freeze the owner
  cannot change or revoke the extension (until unanchor). Builds player trust at the cost of no
  bug-fix path for that SSU.
- `revoke_extension_authorization(su, owner_cap)` (`:160`) — clears the extension; **blocked after
  freeze**.

---

## Proposed Minimal Flow

**Cleanest flow = one new extension function called by the player, chaining the two stock functions in
one transaction.** Confirmed against source and tests.

```text
Player wallet  ──signs──▶  PTB: ssu_open_claim::claim::claim_from_open(su, character, type_id, qty)
                                   │
                                   ├─ assert character.character_address() == ctx.sender()  (your guard)
                                   ├─ world::storage_unit::withdraw_from_open_inventory<ClaimAuth>(...) → Item
                                   └─ world::storage_unit::deposit_to_owned<ClaimAuth>(..., Item, ...)
                                          ▼
                          Item now in the caller's owned/ephemeral slot in the SAME SSU
```

### Move pseudocode (signatures verified; illustrative, not production)

```move
module ssu_open_claim::claim;   // a NEW downstream package, NOT in this repo

use world::{
    character::{Self, Character},
    storage_unit::{Self, StorageUnit},
    inventory::Item,
};

/// Extension witness. Can only be constructed inside this module, so no other
/// package can forge it. `drop` is required by the world storage_unit functions.
public struct ClaimAuth has drop {}

#[error(code = 0)]
const ENotCharacterOwner: vector<u8> = b"Sender is not this character's wallet";

/// Withdraw `quantity` of `type_id` from the SSU's open (shared) inventory into the
/// caller's own owned/ephemeral inventory in the SAME SSU, in one transaction.
///
/// `public` (not `entry`) so a dApp PTB can call it; no return value to capture.
public fun claim_from_open(
    storage_unit: &mut StorageUnit,   // the shared SSU object (shared on-chain)
    character: &Character,            // the caller's character (shared on-chain)
    type_id: u64,
    quantity: u32,
    ctx: &mut TxContext,
) {
    // MVP guard: caller must be the wallet bound to this character, so the item can
    // only land in the caller's own slot. Public, cross-package: character.move:76.
    assert!(character::character_address(character) == ctx.sender(), ENotCharacterOwner);

    let item: Item = storage_unit::withdraw_from_open_inventory<ClaimAuth>(
        storage_unit, character, ClaimAuth {}, type_id, quantity, ctx,
    );

    storage_unit::deposit_to_owned<ClaimAuth>(
        storage_unit, character, item, ClaimAuth {}, ctx,
    );
}
```

**`character.character_address()` is available and public** (`character.move:76`), so the proposed
guard from the task brief is valid as written. `character.owner_cap_id()` (`:88`),
`character.tenant()` (`:80`), `character.tribe()` (`:84`) and `character.id()` (`:64`) are all `public`
too, so richer guards are possible without extra capabilities.

### Companion: stocking the shared area (prerequisite, owner-driven)

The open area can only be filled through the same extension, so the package also needs a stock
function (owner moves items from their main hangar to the shared shelf). This mirrors the upstream
test `deposit_to_open_and_withdraw_from_open`:

```move
/// Owner-only stock: pull from main hangar, push to the shared/open area.
public fun stock_open<T: key>(
    storage_unit: &mut StorageUnit,
    character: &Character,
    owner_cap: &OwnerCap<T>,           // owner proves control of the SSU
    type_id: u64,
    quantity: u32,
    ctx: &mut TxContext,
) {
    let item = storage_unit::withdraw_by_owner(           // owner path (proximity-proof gated)
        storage_unit, character, owner_cap, type_id, quantity, ctx,
    );
    storage_unit::deposit_to_open_inventory<ClaimAuth>(   // extension path into open
        storage_unit, character, item, ClaimAuth {}, ctx,
    );
}
```

> Note: `withdraw_by_owner` requires a server-signed **proximity proof** and `OwnerCap` (it is the
> owner-direct path), so stocking is the heavier operation. The *claim* path deliberately avoids both.
> An alternative stocking route is `withdraw_item<ClaimAuth>` (extension path, no proof) from main →
> `deposit_to_open_inventory<ClaimAuth>`, which is exactly what the upstream test does. The MVP can
> pick whichever the owner finds simpler; stocking is not on the player's hot path.

### Why this is the cleanest shape

- A single PTB `moveCall` to `claim_from_open` — minimal client code.
- No `OwnerCap` borrow/return dance on the claim path (that 3-step pattern is only for owner-direct and
  setup operations).
- No `AdminACL` / sponsor object threaded through (the upstream test helper
  `swap_ammo_for_lens_via_extension` is explicitly annotated *"No AdminACL needed anywhere in the
  flow."*).

---

## Authorization and Security

**Who signs / who pays / what objects are needed — claim path:**

| Concern | Answer |
|---------|--------|
| Who signs the claim tx | The **player** (their wallet). |
| Who pays gas | The player, by default (custom-dApp txns are gas-consuming — see *In-Game dApp Integration*). Sponsorship is optional. |
| Capabilities required | **None.** No `OwnerCap<Character>`, no `OwnerCap<StorageUnit>`, no `AdminCap`, no `AdminACL`, no sponsor. |
| Objects passed | the **shared** `StorageUnit` (mutable ref), the **shared** `Character` (ref), `type_id: u64`, `quantity: u32`. |
| Gate that makes it work | the SSU has the extension registered (`ClaimAuth`), SSU is online, item present in open area. |

**Who authorizes the extension (one-time setup):** the **SSU owner**, using their
`OwnerCap<StorageUnit>`. That cap was transferred to the *Character object's address* at anchor
(`storage_unit.move:634`), so the owner borrows it in-transaction via
`character::borrow_owner_cap<StorageUnit>` (which checks `character_address == ctx.sender()`), calls
`storage_unit::authorize_extension<ClaimAuth>`, then `return_owner_cap`. This is exactly
`ts-scripts/builder_extension/authorise-storage-unit.ts`, **signed by the owner — no AdminACL/sponsor.**

- **`OwnerCap<StorageUnit>` only?** Yes — `authorize_extension` needs just that. No AdminCap/AdminACL.
- **Does the player need their own `OwnerCap<Character>`?** **No** — the claim path passes the
  `Character` by shared reference and uses the sender check; it never borrows the character's cap.
- **Does the SSU owner need AdminCap/sponsorship?** No for `authorize_extension`. (AdminACL/sponsor is
  only for admin operations like `anchor`, `share_storage_unit`, `reveal_location`, the game→chain
  bridge — see `docs/architecture/world-contracts-auth-model.md`.)

**Can any player drain the open inventory?** With the self-sender guard above, **any character can
claim from the shared area into their own slot** — including claiming *all* of it. That is the
intended semantics of a "shared/open" shelf; the guard only ensures items land in the *caller's own*
slot (it stops a griefer from scattering items into third parties' slots). It does **not** ration or
restrict *who* may claim.

**Smallest reasonable guard for this MVP (ranked):**

1. **Self-sender check** (`character_address() == ctx.sender()`) — *recommended default.* One line,
   no config, no extra objects. Prevents deposit-to-strangers; accepts "anyone may claim" as the
   feature.
2. **Tribe check** (`character.tribe() == allowed_tribe`) — restrict to a tribe. Needs the allowed
   tribe id stored in extension config (a shared `ExtensionConfig` object, per
   `extension_examples/config.move`). Risks overlapping with the *existing shared tribe storage*
   project — avoid unless clearly differentiated.
3. **Owner-configurable allowlist** of character IDs — most flexible, most code; a later upgrade.
4. **No guard** — *not recommended*: lets any sender deposit the withdrawn item into *any* character's
   slot, enabling grief/spam.

**Risks if fully public (no guard):** any sender can route the shared area's contents into arbitrary
characters' owned slots (spam/grief, and confusing provenance). The self-sender guard removes this at
near-zero cost, so the MVP should include it.

**Freeze — recommend NOT freezing for the MVP.** `freeze_extension_config` is one-way and removes any
ability to fix a bug or swap the extension on that SSU. Keep the extension *unfrozen* during prototype
and early operation so the owner can `revoke_extension_authorization` or replace it if the extension
misbehaves. Freezing is a *trust* feature to offer later, once the extension is audited and stable.
(Historical note: `docs/architecture/world-contracts-auth-model.md` flags `swap_or_fill` as a
"replaceable extension / rug-pull" risk — that observation predates the freeze feature, which is the
mitigation. For an *open free-shelf* MVP there is little to rug, so unfrozen is the right default.)

**Witness forgery:** `ClaimAuth` can only be constructed inside its defining module, so no other
package can mint it. The world functions bind to `type_name::with_defining_ids<ClaimAuth>()`, which
includes the extension's **published package ID** — meaning if you *upgrade* the extension to a new
package ID, the SSU must be re-authorized (and a *frozen* SSU could not be). Plan upgrades before
freezing.

---

## Inventory Read Path

Goal: show the player what is in the shared area. Ranked by effort; **the UI does not need any of
these to function** — it can start with manual `type_id` entry.

**What reads easily (devInspect / view calls):**
- `storage_unit::has_open_storage(su): bool` (`:583`) and `storage_unit::open_storage_key(su): ID`
  (`:578`) both return copyable values and are readable via `devInspectTransactionBlock` — exactly the
  pattern in `ts-scripts/utils/dev-inspect.ts` (`devInspectMoveCallFirstReturnValueBytes`) and
  `ts-scripts/storage-unit/helper.ts` (which reads `owner_cap_id` the same way). So the dApp can
  always learn the open slot's key.

**What does *not* read directly:**
- `storage_unit::inventory(su, key): &Inventory` (`:558`) returns a **reference**, which a PTB/devInspect
  cannot capture as a result. And `Inventory` exposes only `contains_item(type_id): bool` and
  `max_capacity(): u64` publicly (`inventory.move:189,204`); the item map
  (`items: VecMap<u64, ItemEntry>`) and the per-type quantities are **private** (`item_quantity`,
  `inventory_item_length` are `#[test_only]`). **There is no public Move view that lists the open
  area's contents.** This matches the inventory-intelligence brief's finding: *"contents are not
  enumerable from events alone."*

**So, to list contents, use off-chain RPC on the dynamic field (the real read path):**
1. Get the open key: `open_storage_key(su)` via devInspect (or recompute off-chain:
   `blake2b256( su_id_bytes(32) ++ utf8("open_inventory") )`).
2. `sui_getDynamicFieldObject(parentId = su_id, name = { type: "0x2::object::ID", value: openKey })`
   → returns the `Inventory` value as JSON, including `items` (a `VecMap` serialized as
   `{ contents: [ { key: <type_id>, value: { tenant, type_id, item_id, volume, quantity } } ] }`).
   This yields the full `type_id → quantity` table. The EVE Frontier dApp-kit exposes
   `getObjectWithJson` / `executeGraphQLQuery` (GraphQL `dynamicFields`) for the same data.
3. Resolve `type_id → human name + icon` with dApp-kit's `getDatahubGameInfo(typeId)` (returns
   `{ name, iconUrl }`).

**Recommended fallback (start here): "phase-1 claim by `type_id` only."** Ship the UI with a `type_id`
field + quantity field and the claim button. No decoding, no GraphQL. Add the decoded table (steps
1–3 above) as a fast follow once the claim path is proven. Do **not** overbuild this — the decoded
table is "medium" effort, not a blocker, and it drifts toward the (separately-scoped) inventory
dashboard if over-invested.

---

## In-Game dApp Integration

From `dapps/connecting-in-game.md` and `tools/dapp-kit.md`:

- **Attaching a custom dApp URL:** the SSU owner opens the unit's **Base dApp** in-game (fly to it,
  press **F**), clicks "Edit unit," and sets the **dApp URL**. Only the owner may set it. (On-chain
  this is `storage_unit::update_metadata_url`, submitted as a *sponsored* metadata edit by the Base
  dApp.)
- **URL parameters available in-game:** the page is opened with
  **`https://yourdapp.com/?tenant=<tenant>&itemId=<itemId>`** (dApp-kit Quick Start). dApp-kit's
  `useSmartObject()` reads these and fetches the assembly via GraphQL. **So the page can infer the
  target SSU from the URL** — no manual address entry needed. (The SSU object ID is derivable from
  `objectRegistry` + the in-game `itemId` + tenant, mirroring `deriveObjectId` in the TS scripts; or
  taken from what `useSmartObject()` resolves.)
- **Wallet:** the player connects **EVE Vault** or a **Sui wallet** via dApp-kit `useConnection()`
  (`handleConnect`). The connected wallet address is the `ctx.sender()` that the self-guard checks
  against `character.character_address()`. The wallet→character link can be resolved via the player's
  `PlayerProfile` object (transferred to the wallet at character creation, `character.move:50,174`) —
  *flagged temporary upstream*, so resolve defensively.
- **Gas / sponsorship:** custom-dApp transactions are **gas-consuming** — *"Users must have SUI in
  their wallet... A Sui faucet is available."* So **player-paid gas is acceptable and is the default**
  for the MVP. Sponsorship is *optional*: dApp-kit advertises "Sponsored Transactions — gas-free via
  EVE Frontier backend" (`useSponsoredTransaction`), so a sponsor can be added later, but **no custom
  sponsor is required** to ship.
- **Execution:** build a `@mysten/sui` `Transaction`, one `moveCall` to
  `ssu_open_claim::claim::claim_from_open`, then `dAppKit.signAndExecute({ transaction })`
  (Mysten dApp-kit, surfaced through EVE Frontier's `EveFrontierProvider`). Confirm with a digest /
  `waitForTransaction`.
- **Browser/wallet constraints:** the page runs inside the EVE Frontier embedded browser (a Chromium
  CEF WebView — see `docs/research/capabilities.json` for a prior capability probe). It must be a
  plain web page (static SPA is ideal), tolerate the embedded WebView, and use the dApp-kit wallet
  bridge rather than assuming a desktop extension popup. Keep it dependency-light.

---

## Minimal UI Specification

Deliberately boring. Black background, white text, monospace, no icons required.

```
┌───────────────────────────────────────────────┐   (black bg, white mono text)
│ SHARED STORAGE — <assembly name or itemId>     │
│ SSU: 0x8b3…a1aa1   tenant: stillness           │
│ Wallet: 0x12…cdef   (Connect / Connected)      │
│ Character: Jita-Trader-01   ●online            │
│───────────────────────────────────────────────│
│ OPEN INVENTORY                                 │
│   type_id     name            qty              │  ← table IF readable;
│   88069       Ammo            240              │    otherwise omit table and
│   88070       Lens             15              │    show the two inputs below
│───────────────────────────────────────────────│
│ type_id: [ 88069        ]                      │  ← always present (fallback path)
│ quantity:[ 10           ]                      │
│                                                │
│        [ Withdraw to my SSU inventory ]        │
│───────────────────────────────────────────────│
│ status: awaiting signature…                    │  ← idle → building tx →
│ digest: —                                      │    awaiting signature →
└───────────────────────────────────────────────┘    submitted (digest) / failed (reason)
```

Required elements:
- Assembly/SSU name or `itemId` (+ resolved object ID), tenant.
- Connected wallet + resolved character (and SSU online/offline state — an offline SSU will abort
  `ENotOnline`, so surface it).
- Open-inventory table **if** the read path is wired; otherwise just the `type_id` + `quantity` inputs.
- One button: **"Withdraw to my SSU inventory."**
- A status line cycling: `idle → building tx → awaiting signature → submitted (digest 0x…) → done`,
  or `failed: <reason>` (map common aborts: `ENotOnline`, `EItemDoesNotExist`,
  `EOpenStorageNotInitialized`, `EInventoryInsufficientQuantity`, `ENotCharacterOwner`).

Explicitly **out**: marketplace/listing/pricing UI, shared-tribe-storage concepts, social features,
dashboards, audit timelines, alerts, icons. (Tribe/allowlist UI appears only if you choose guard
option 2/3.)

---

## Implementation Options

| Option | Includes | Excludes | Complexity | Main risk | Recommended next step |
|--------|----------|----------|------------|-----------|-----------------------|
| **A. Source-only feasibility (this doc) → build later** | This document + the validation evidence | Any code | Done | Verdict ages if contracts move | Use as the brief for Option B/C |
| **B. Minimal Move extension package + static page** | New `ssu_open_claim` package (`ClaimAuth` + `claim_from_open` + `stock_open`); Move test; publish to `testnet_stillness`; authorize on a real SSU; tiny Vite/React page with dApp-kit, `type_id`+qty input, claim button | Decoded inventory table; sponsorship; pricing; dashboards | **Medium** (≈1 Move module + 1 page; publish + 1 authorize tx) | Publishing + first live claim unproven (gas, witness defining-id, online state) | **Recommended.** Build the package first, unit-test it, publish, authorize on a test SSU, then wire the page. |
| **C. Static page only (assume extension already exists)** | Just the web page hitting an already-published+authorized extension | The Move package | Low | Blocked until an extension exists/authorized; nothing to call otherwise | Only after B publishes the package |
| **D. Tiny indexer/API for the read table** | Small Node/Worker that RPC-reads the open dynamic field + resolves `type_id`→name, serving JSON to the page | The write/claim path | Low–Medium | Over-builds toward the inventory-dashboard project; V2-event/`PlayerProfile` drift | Defer; only if a live decoded table is wanted and direct RPC in the page proves awkward |

**Recommended path:** **Option B**, with the read table deferred (start on the `type_id`-input
fallback). Option D is optional polish, not MVP.

---

## Validation Performed

**Distinguish: source-audit evidence vs tests actually run vs commands not run vs live-chain checks.**

### Source-audit evidence (read directly from `d1929fa`)
- `withdraw_from_open_inventory` / `deposit_to_open_inventory` / `deposit_to_owned` /
  `authorize_extension` signatures, guards, and the open-key derivation — read in
  `storage_unit.move`.
- `Item.parent_id = assembly_id` stamping and V2 event shapes — read in `inventory.move`.
- `character_address()` / `owner_cap_id()` / `tenant()` / `tribe()` are `public` — read in
  `character.move`.
- The extension witness + "no AdminACL" composition template — read in `storage_unit_tests.move`
  (`SwapAuth`, `swap_ammo_for_lens_via_extension`).

### Tests actually run (this pass)
- `git submodule status` → SHAs pinned above.
- `sui --version` → `sui 1.68.1-3c0f387ebb40-dirty`.
- `sui client active-env` → `testnet_stillness`; `sui client envs` enumerated.
- **`sui move test --path vendor/world-contracts/contracts/world deposit_to_o`** → **PASS (4/4)** on
  v0.0.24:
  - `deposit_to_open_and_withdraw_from_open` — proves `withdraw_from_open_inventory<Auth>` works and
    open inv exists at anchor.
  - `deposit_to_owned_creates_owned_inventory` — proves `deposit_to_owned<Auth>` auto-creates the
    owned slot and lands the item.
  - `test_deposit_to_owned_fail_not_authorized` — proves the `EExtensionNotAuthorized` witness guard.
  - `test_deposit_to_owned_fail_parent_id_mismatch` — proves the same-SSU `parent_id` guard.
  - Compiler warnings confirmed the legacy `ItemWithdrawnEvent`/`ItemDepositedEvent` fields are now
    unused (V2 migration is real).
  - *Each half of the proposed flow passes on current source; the open→owned composition is
    structurally guaranteed by the shared `Item { parent_id == storage_unit_id }` contract, though no
    single upstream test chains exactly open→owned — that combined test is the documented next-pass
    spike.*

> Vendor hygiene: the `sui move` runs touched tracked `Move.lock` files inside
> `vendor/world-contracts` and `vendor/builder-scaffold` (dependency-resolution/CRLF churn). **All
> were restored** via `git -C vendor/<name> checkout -- <lock>`; vendor is pristine (only `build/`,
> which is gitignored, remains locally). No commits were made inside any submodule.

### Commands that could NOT be run / were deliberately not run
- A **fresh `sandbox/validation/ssu_open_claim_validation/` spike was *not* created.** First cheap
  attempt — `sui move test` on the existing `sandbox/validation/ssu_extension_test` (a v0.0.15-era
  package) — failed with *"Packages with old-style Move.toml files cannot depend on new-style
  packages"* against the v0.0.24 world manifest. Rather than migrate that package or hand-roll the
  ~150-line world bootstrap (NWN/energy/fuel/server-registry/SSU online/mint) into a new package — the
  "large or brittle" case the brief says to skip — I relied on the upstream world tests, which already
  exercise both halves on v0.0.24. Exact spike recipe is in *Recommended Next Prompt*.
- No publish, no on-chain transaction, no devInspect against `testnet_stillness`.
- No wallet/browser smoke test (no front-end exists yet).

### Remaining live-chain checks (must do before trusting the build)
1. Publish a throwaway `ssu_open_claim` to `testnet_stillness`; confirm the witness's defining
   package ID is what `authorize_extension` records.
2. On a real test SSU: `authorize_extension<ClaimAuth>` (owner), `stock_open` (owner), then
   `claim_from_open` (a *different* wallet) — confirm the item lands in the second character's owned
   slot and that **`ItemWithdrawnEventV2` + `ItemDepositedEventV2`** fire with the expected
   `inventory_key`s.
3. Confirm the open dynamic field is RPC-readable via `getDynamicFieldObject` and decodes to the
   `type_id → quantity` table.
4. Confirm a player-paid (unsponsored) claim succeeds from a funded wallet inside the in-game browser.

---

## Risks, Caveats, and Kill Criteria

- **New package required (low risk).** The claim cannot be done with stock world functions — the
  open-inventory functions are extension-gated. Mitigation: the package is ~30–60 lines; the scaffold
  (`builder-scaffold/move-contracts/storage_unit_extension`) and the auth script already exist.
- **Stocking prerequisite (low risk, UX caveat).** The shared area is empty until someone stocks it
  via the extension. The claim UI should handle "nothing here / type not present"
  (`EItemDoesNotExist`, `EOpenStorageNotInitialized`) gracefully.
- **"Shared" = drainable (by design).** Document clearly to the owner that an open shelf can be
  emptied by any eligible claimer. If that is unacceptable, use the tribe/allowlist guard — but verify
  it does not duplicate the **existing shared-tribe-storage project** (June 2026 operator context).
- **V2 event trap (medium).** Build/read paths must use `ItemWithdrawnEventV2`/`ItemDepositedEventV2`
  + `inventory_key`. The in-repo `ts-scripts/storage-unit/withdraw-deposit.ts` still references the
  **stale** `::inventory::ItemWithdrawnEvent` (line 77) — do not copy that listener. The build.md/
  README in `builder-documentation` also **predate the open-inventory API** (they document
  `deposit_item`/`withdraw_item`/`deposit_to_owned` but not `*_open_inventory`) — trust the source.
- **Online requirement.** Claims abort if the SSU is offline (`ENotOnline`). Surface SSU status.
- **`PlayerProfile` is temporary upstream.** Wallet→character resolution may change; resolve
  defensively (don't hard-couple to `PlayerProfile`).
- **Upgrade vs freeze.** `with_defining_ids` binds the registered extension to its package ID; an
  upgrade needs re-authorization, and **freezing forecloses that** — keep MVP SSUs unfrozen.
- **Contract drift.** Verdict is pinned to `world-contracts@d1929fa` (v0.0.24). Operator context says
  contracts should be ~stable through Q3 2026, but **re-run the validation if the submodule advances**.

**Kill criteria (stop / rethink if any are true on live chain):**
1. The first half — a non-owner wallet successfully calling `withdraw_from_open_inventory` via the
   authorized witness — *fails* on `testnet_stillness` despite passing in unit tests (would indicate a
   live/runtime gap vs `test_scenario`).
2. `deposit_to_owned` rejects the open-withdrawn item (parent_id/tenant) on live chain.
3. The open dynamic field cannot be read off-chain at all (would force Option D even for a basic
   table — still not fatal, since the `type_id`-input fallback stands).
4. The in-game embedded browser cannot complete a wallet `signAndExecute` for a player-paid tx (would
   force a sponsored-tx detour).

**Non-duplication:** this is *not* shared tribe storage (no shared custody/pooling), *not* a
marketplace (no listings/pricing/settlement), and *not* the SSU inventory-intelligence dashboard
(no cross-SSU rollup, no audit timeline). It is a single-SSU, owner-stocked "free shelf → claim to my
slot" utility.

---

## Recommended Next Prompt

> **Build the smallest `ssu_open_claim` prototype (Option B).** Source of truth:
> `docs/current/research/ssu-open-shared-withdraw-feasibility-2026-06-29.md`. Pin to
> `world-contracts@d1929fa` (v0.0.24) on `testnet_stillness`.
>
> 1. **Validation spike (do first, it's cheap).** Create `sandbox/validation/ssu_open_claim_validation/`
>    as a **new-style** Move package (copy the Move.toml shape from
>    `vendor/builder-scaffold/move-contracts/storage_unit_extension/Move.toml`: `world = { local =
>    "../../../vendor/world-contracts/contracts/world" }`, `[environments] testnet_stillness =
>    "4c78adac"`, no `[addresses]`). Add `ClaimAuth has drop {}` and one `#[test]` that bootstraps the
>    world like `vendor/world-contracts/contracts/world/tests/assemblies/storage_unit_tests.move`
>    (setup world + character + NWN + SSU, bring online, mint, `authorize_extension<ClaimAuth>`,
>    `deposit_to_open_inventory<ClaimAuth>`), then runs `withdraw_from_open_inventory<ClaimAuth>` →
>    `deposit_to_owned<ClaimAuth>` for a **second** character and asserts the item lands in that
>    character's owned slot. Run `sui move test --path sandbox/validation/ssu_open_claim_validation`
>    (switch active env to one NOT in the package `[environments]` if you hit a chain-hash mismatch).
>    Do not touch `vendor/`.
> 2. **Production package (downstream repo, NOT this one).** Same `ClaimAuth` + `public fun
>    claim_from_open(...)` (with the `character_address() == ctx.sender()` guard) + `stock_open(...)`.
>    Publish to `testnet_stillness`; record the package ID.
> 3. **Authorize on a real SSU** (owner wallet) by adapting
>    `ts-scripts/builder_extension/authorise-storage-unit.ts` to `ClaimAuth`; stock the open area.
> 4. **Static page** (Vite/React + `@evefrontier/dapp-kit`): read `?tenant=&itemId=`, `useConnection()`
>    + `useSmartObject()`, a `type_id`+quantity form, and one `dAppKit.signAndExecute` PTB calling
>    `claim_from_open`. Black bg / white mono / one button / status line per the UI spec. Defer the
>    decoded inventory table.
> 5. **Live checks:** confirm a *second* wallet can claim, that `ItemWithdrawnEventV2`/
>    `ItemDepositedEventV2` fire with the right `inventory_key`s, and that an unsponsored player-paid
>    tx succeeds. Keep the SSU **unfrozen**.
