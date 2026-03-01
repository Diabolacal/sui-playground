# CivilizationControl — Atomic Implementation Plan

**Retention:** Carry-forward

## Document Authority

| Role | Document |
|------|----------|
| Execution authority | `march-11-reimplementation-checklist.md` |
| Intent authority | `spec.md` |
| Validation authority | `validation.md` |
| Expanded reference | `civilizationcontrol-implementation-plan.md` (this document) |

> If conflicts exist, defer to the March-11 Reimplementation Checklist for execution decisions.

> **PRE-HACKATHON PROVISIONAL PLAN**
> Must be re-audited against live world contracts and documentation before March 11 execution.

> **Date:** 2026-02-24  
> **Status:** Pre-hackathon planning — zero production code exists  
> **Scope:** All phases from Day-1 validation through demo submission  
> **Sources:** march-11-reimplementation-checklist.md, UX architecture spec, demo beat sheet, gatecontrol-feasibility-report.md, zk-gatepass-feasibility-report.md, read-path-architecture-validation.md, policy-authoring-model-validation.md, shortlist-viability-validation-report.md, builder-scaffold patterns  
> **Hackathon window:** March 11–31, 2026 (~72 effective hours)

### Status Legend (planning repo)

| Label | Meaning |
|-------|---------|
| **CONFIRMED** | Validated in local devnet sandbox (pre-hackathon) |
| **PROVISIONAL** | Architecturally sound; requires validation on hackathon test server (March 11+) |
| **BLOCKED** | Requires hackathon infrastructure or organizer-provided access (March 11+) |

---

## Phase 0: Day-1 Validation (Hours 0–2)

### S01 — Verify hackathon start date and create fresh repo

**Phase:** Day-1 Validation  
**Status:** CONFIRMED  
**Effort:** 0.5 hours  
**Dependencies:** None  
**Description:** Confirm hackathon has started (UTC timestamp ≥ March 11 2026). Create fresh GitHub repo with no prior commits. `git init`, add MIT license, README stub, `.gitignore`, `.github/copilot-instructions.md` template. First commit. Push to GitHub. Register on Deepsurge if not done.  
**Files:**
- `README.md`
- `LICENSE`
- `.gitignore`
- `.github/copilot-instructions.md`

**Definition of Done:**
- GitHub repo exists with first commit timestamped on or after March 11
- `git log --oneline` shows exactly one commit
- Deepsurge registration confirmed

---

### S02 — Add world-contracts and builder-scaffold as submodules

**Phase:** Day-1 Validation  
**Status:** CONFIRMED  
**Effort:** 0.25 hours  
**Dependencies:** S01  
**Description:** Add vendor submodules from upstream. Pull latest commits. Verify no breaking API changes since Feb 16 validation date.  
```
git submodule add https://github.com/evefrontier/world-contracts.git vendor/world-contracts
git submodule add https://github.com/evefrontier/builder-scaffold.git vendor/builder-scaffold
```
**Files:**
- `.gitmodules`
- `vendor/world-contracts/` (submodule)
- `vendor/builder-scaffold/` (submodule)

**Definition of Done:**
- `git submodule status` shows both submodules at latest commit
- `vendor/world-contracts/contracts/world/sources/assemblies/gate.move` exists and is readable

---

### S03 — Verify critical function signatures (Assumptions A1–A4)

**Phase:** Day-1 Validation  
**Status:** CONFIRMED  
**Effort:** 0.5 hours  
**Dependencies:** S02  
**Description:** Read and verify the 4 critical function signatures that the entire project depends on. Compare against the signatures documented in the reimplementation checklist. If any signature has changed, assess impact immediately.

Verify:
1. **A1:** `gate::authorize_extension<Auth: drop>(&mut Gate, &OwnerCap<Gate>)` — still public, still accepts any `Auth` with `drop`
2. **A2:** `gate::issue_jump_permit<Auth: drop>(...)` — still public, callable from external packages
3. **A3:** `storage_unit::withdraw_item<Auth: drop>(...)` — still public, does NOT require OwnerCap
4. **A4:** `Item` struct has `key, store` abilities — `transfer::public_transfer` valid

**Files:**
- `vendor/world-contracts/contracts/world/sources/assemblies/gate.move`
- `vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move`
- `vendor/world-contracts/contracts/world/sources/primitives/inventory.move`

**Definition of Done:**
- All 4 assumptions confirmed with exact function signatures documented
- OR: deviation identified with impact assessment and fallback plan written
- Results logged in `notes/day1-validation.md`

---

### S04 — Connect to hackathon test server and discover package IDs

**Phase:** Day-1 Validation  
**Status:** BLOCKED  
**Effort:** 0.5 hours  
**Dependencies:** S02  
**Description:** Connect Sui CLI to the hackathon test server RPC endpoint (provided by organizers on March 11). Discover pre-published world-contracts package IDs by querying known types. If test server unavailable, fall back to local devnet via builder-scaffold Docker.

Steps:
1. `sui client new-env --alias testserver --rpc <RPC_URL>`
2. `sui client switch --env testserver`
3. `sui client active-env` → verify "testserver"
4. Query for GovernorCap, AdminACL, ObjectRegistry shared objects
5. Record all package IDs and shared object IDs

Fallback: `cd vendor/builder-scaffold/docker && docker compose run --rm sui-local`, then `sui client publish` world package.

**Files:**
- `notes/day1-validation.md` (IDs recorded here)

**Definition of Done:**
- Connected to target network (test server or local devnet)
- World-contracts package ID recorded
- GovernorCap, AdminACL, ObjectRegistry, GateConfig IDs recorded
- OR: clear documentation of test server unavailability + successful local devnet fallback
- `sui client active-env` returns expected environment

**Assumption to verify:** Hackathon test server is available from March 11 with pre-published world-contracts (E5, E6, E7).

---

### S05 — Validate AdminACL sponsor access

**Phase:** Day-1 Validation  
**Status:** BLOCKED  
**Effort:** 0.5 hours  
**Dependencies:** S04  
**Description:** Determine whether sponsor access to AdminACL is available on the hackathon environment. This is the CRITICAL PATH blocker — `jump()` and `jump_with_permit()` require `admin_acl.verify_sponsor(ctx)`.

On test server: Check if admin tools allow adding a sponsor address. If GovernorCap is held by CCP, request sponsor registration or verify if builder addresses are pre-authorized.

On local devnet: Self-deploy world package → own GovernorCap → add own address as sponsor via `add_sponsor_to_acl()`. **Note:** `verify_sponsor` falls back to `ctx.sender()` when no sponsor is present — a non-sponsored tx works if sender is in AdminACL. For sponsored txs, use a different address as sponsor.

**Files:**
- `notes/day1-validation.md`

**Definition of Done:**
- Sponsor address registered in AdminACL AND confirmed via test transaction
- OR: Confirmed that sponsor registration is not possible + documented fallback (demo on local devnet)
- Self-sponsorship avoidance confirmed (sender ≠ sponsor address)

**Assumption to verify:** AdminACL sponsor access is obtainable without GovernorCap (BLOCKED item #1 from gap analysis). GovernorCap is held by CCP game operators.

---

### S06 — Validate per-gate dynamic field keys (Assumption A10)

**Phase:** Day-1 Validation  
**Status:** PROVISIONAL  
**Effort:** 0.25 hours  
**Dependencies:** S04  
**Description:** Publish a minimal test package that stores dynamic fields with compound key structs containing gate IDs (e.g., `TribeRuleKey { gate_id: ID }`). Verify that two different gate IDs produce independent DFs on the same shared config object. This validates the publish-once, configure-via-data model for per-gate rule differentiation.

**Files:**
- Temporary test package (publish and discard)
- `notes/day1-validation.md`

**Definition of Done:**
- Published test package with gate-ID-keyed DFs
- Confirmed two different gate_id keys store independent values
- Confirmed DF reads for one gate_id don't interfere with another

**Assumption to verify:** Compound key structs with embedded `ID` fields work as expected for per-gate dynamic field differentiation (standard Sui DF capability, but not yet tested in this context).

---

## Phase 1: Foundation (Hours 2–6)

### S07 — Scaffold React + Vite + TypeScript project

**Phase:** Foundation  
**Status:** PROVISIONAL  
**Effort:** 1 hour  
**Dependencies:** S01  
**Description:** Initialize frontend application with Vite + React + TypeScript. Install core dependencies: `@mysten/dapp-kit`, `@mysten/sui`, `@tanstack/react-query`. Set up project structure matching the UX architecture spec's screen hierarchy: pages for Command Overview, Gates, Trade Posts, Signal Feed, Configuration. Add Tailwind CSS (or similar utility-first CSS).

**In-game browser considerations:**
- Configure viewport meta tag for portrait orientation (787×1198 native in-game resolution)
- Add CSS breakpoint at ≤800px targeting the in-game embedded browser
- Default to dark theme (`prefers-color-scheme: dark`) — the game client background is dark
- Reference: [in-game-dapp-surface.md](../architecture/in-game-dapp-surface.md)

**Files:**
- `frontend/package.json`
- `frontend/tsconfig.json`
- `frontend/vite.config.ts`
- `frontend/src/main.tsx`
- `frontend/src/App.tsx`
- `frontend/src/pages/` (stub files)
- `frontend/src/components/` (stub files)
- `frontend/src/hooks/` (stub files)
- `frontend/src/lib/` (stub files)

**Definition of Done:**
- `npm run dev` starts dev server without errors
- `npm run build` produces production build without errors
- TypeScript strict mode enabled, no TS errors
- App renders a placeholder page in browser

**Assumption to verify:** `@mysten/dapp-kit` is compatible with the hackathon test server's Sui version. Verify via `npm install` + basic wallet connect test.

---

### S08 — Configure wallet adapter (dapp-kit + SuiClientProvider)

**Phase:** Foundation  
**Status:** PROVISIONAL  
**Effort:** 1 hour  
**Dependencies:** S07  
**Description:** Set up `@mysten/dapp-kit` wallet adapter with `SuiClientProvider`, `WalletProvider`, and `QueryClientProvider`. Configure network targeting (devnet/testnet/custom RPC from S04). Add Connect Wallet button in global header. Validate that wallet connection works with EVE Vault or standard Sui wallet.

Per UX spec §10: implement connection states (Not Connected, Connecting, Connected, Wrong Network, Extension Missing). Connected state shows truncated address + green dot.

**CRITICAL — In-game vs external browser context detection:**
- The in-game DApp browser provides an **EVM wallet** (detected via EIP-6963) but **zero Sui wallets** via Wallet Standard. This means Sui write operations (signing transactions) are impossible from within the game client.
- Detect context at startup: if EIP-6963 wallet discovered AND zero Sui Wallet Standard wallets → enter **read-only "Viewing Mode"**.
- In Viewing Mode: display a persistent "Viewing Mode" badge in the header. Hide or disable all write-action buttons (Deploy Policy, Buy, Create Listing, etc.). Show a tooltip: "Connect a Sui wallet in an external browser to perform actions."
- External browser: standard `@mysten/dapp-kit` WalletProvider flow with full read/write access.
- Reference: [in-game-dapp-surface.md §4](../architecture/in-game-dapp-surface.md)

**Assumption to verify (Day-1):** In-game browser provides EVM wallet but zero Sui wallets — confirm this is still the case on the hackathon test server.

**Files:**
- `frontend/src/App.tsx` (providers wrapping)
- `frontend/src/components/WalletConnect.tsx`
- `frontend/src/lib/networkConfig.ts`

**Definition of Done:**
- Wallet connects and address displays in UI header
- `useCurrentAccount()` returns connected account
- Network switch between devnet/testnet/custom works
- Wallet disconnect clears state
- `npm run build` passes

**Assumption to verify:** EVE Vault wallet adapter is compatible with `@mysten/dapp-kit` standard wallet interface. Fallback: use Sui Wallet (browser extension) for demo.

---

### S09 — Create CivControl Move package scaffold

**Phase:** Foundation  
**Status:** CONFIRMED  
**Effort:** 1 hour  
**Dependencies:** S02, S04  
**Description:** Create the CivilizationControl Move extension package following builder-scaffold patterns. Define the core types: `GateAuth has drop {}` witness, `TradeAuth has drop {}` witness, `CivControlConfig` shared object with UID for dynamic fields, `AdminCap` for global admin operations. Write `init()` function that creates the shared config and transfers AdminCap to publisher.

> **Note:** `AdminCap` follows the builder-scaffold pattern for future global admin operations (e.g., emergency config migration, fee parameter changes). MVP rule configuration uses `OwnerCap<Gate>` for per-gate self-service. AdminCap is reserved — no MVP function requires it.

References: `vendor/builder-scaffold/move-contracts/smart_gate/sources/config.move` (ExtensionConfig + AdminCap + XAuth + DF helpers).

**Critical design:** Both GateAuth and TradeAuth witnesses live in the SAME package because each gate/SSU supports only one extension type (`Option<TypeName>`). The config object is shared across all enrolled structures.

**Files:**
- `contracts/civcontrol/Move.toml`
- `contracts/civcontrol/sources/config.move`

**Definition of Done:**
- `sui move build` succeeds with no errors
- Package defines `GateAuth`, `TradeAuth`, `CivControlConfig`, `AdminCap`
- `init()` creates shared config + transfers AdminCap
- Package depends on world-contracts `world` package (correct dependency path)
- Module naming follows `civcontrol::config`

---

### S10 — Publish CivControl package to target network

**Phase:** Foundation  
**Status:** CONFIRMED  
**Effort:** 0.5 hours  
**Dependencies:** S09, S04  
**Description:** Publish the CivControl extension package to the target network (test server or local devnet). Record the package ID. Verify that `CivControlConfig` shared object was created. This is a critical milestone — the package ID becomes stable and is referenced by all PTB construction.

On local devnet: may need `[environments]` section in Move.toml with chain ID.

**Files:**
- `contracts/civcontrol/Move.toml` (add environment if needed)
- `notes/day1-validation.md` (package ID recorded)

**Definition of Done:**
- Package published successfully (tx digest recorded)
- Package ID recorded
- `CivControlConfig` shared object ID recorded
- `AdminCap` owned by publisher address
- `sui client object <config_id>` returns valid shared object

---

## Phase 2: GateControl Core (Hours 6–18)

### S11 — Implement tribe filter rule in Move

**Phase:** GateControl  
**Status:** CONFIRMED  
**Effort:** 2 hours  
**Dependencies:** S09  
**Description:** Implement tribe filter as a dynamic field rule on the shared config. Define `TribeRuleKey { gate_id: ID }` (copy, drop, store) and `TribeRule { tribe_id: u32 }` (drop, store). Implement admin functions:
- `set_tribe_rule(config, gate_id, tribe_id)` — adds or updates tribe DF
- `remove_tribe_rule(config, gate_id)` — removes tribe DF if exists

Gate the config functions with OwnerCap<Gate> verification: accept `&OwnerCap<Gate>` and assert `owner_cap.authorized_object_id() == gate_id` to enable self-service.

Reference: `vendor/world-contracts/contracts/extension_examples/sources/config.move` DF helpers, `vendor/builder-scaffold/move-contracts/smart_gate/sources/tribe_permit.move`.

**Files:**
- `contracts/civcontrol/sources/gate_rules.move`

**Definition of Done:**
- `sui move build` passes
- `sui move test` passes with unit test: set tribe rule → verify DF exists → remove → verify gone
- Rule functions accept OwnerCap<Gate> for authorization

---

### S12 — Implement coin toll rule in Move

**Phase:** GateControl  
**Status:** CONFIRMED  
**Effort:** 1.5 hours  
**Dependencies:** S09  
**Description:** Implement coin toll as a dynamic field rule. Define `CoinTollKey { gate_id: ID }` and `CoinTollRule { price_mist: u64, treasury: address }`. Implement admin functions:
- `set_coin_toll(config, gate_id, price_mist, treasury)` — adds or updates toll DF
- `remove_coin_toll(config, gate_id)` — removes toll DF

Per pattern catalog: toll is `Coin<SUI>` for MVP. Generic `Coin<T>` is stretch (TribeMint). Treasury address defaults to gate owner but is configurable (stored in the rule itself).

**Files:**
- `contracts/civcontrol/sources/gate_rules.move` (extend existing module)

**Definition of Done:**
- `sui move build` passes
- `sui move test` passes with unit test: set toll → verify DF → remove → verify gone
- TollRule stores `price_mist` as u64 and `treasury` as address

---

### S13 — Implement request_jump_permit entry function

**Phase:** GateControl  
**Status:** CONFIRMED  
**Effort:** 2.5 hours  
**Dependencies:** S11, S12  
**Description:** Implement the core entry function that evaluates all active rules and issues a JumpPermit if all pass. Function signature:

```move
public fun request_jump_permit(
    config: &CivControlConfig,
    source_gate: &Gate,
    dest_gate: &Gate,
    character: &Character,
    payment: Coin<SUI>,       // may be zero-value if no toll
    clock: &Clock,
    ctx: &mut TxContext,
)
```

Evaluation order (per UX spec §6 composition logic):
1. Check tribe rule (if DF exists for source gate) → compare `character.tribe()` (**Note:** `tribe_id()` is `#[test_only]`; use `tribe()`) → abort on mismatch
2. Check coin toll (if DF exists for source gate) → verify `coin::value(&payment) >= price` → transfer to treasury → return change if overpaid
3. All passed → call `gate::issue_jump_permit<GateAuth>(source, dest, character, GateAuth{}, expiry, ctx)`

Emit custom `TollCollectedEvent { gate_id, character_id, amount, timestamp_ms }` when toll is collected (required for Signal Feed per read-path §2.4).

Handle zero-value coin when no toll rule exists (destroy empty coin).

**Files:**
- `contracts/civcontrol/sources/gate_permit.move`

**Definition of Done:**
- `sui move build` passes
- `sui move test` passes with tests:
  - Correct tribe + correct toll → JumpPermit issued + TollCollectedEvent emitted
  - Wrong tribe → MoveAbort with expected error code
  - Insufficient payment → MoveAbort
  - No toll rule active + correct tribe → permit issued, zero coin destroyed
- Custom event struct `TollCollectedEvent` has `copy, drop` abilities

---

### S14 — Deploy GateControl extension to target network and integration test

**Phase:** GateControl  
**Status:** CONFIRMED  
**Effort:** 2 hours  
**Dependencies:** S10, S13, S05  
**Description:** End-to-end integration test of GateControl on the target network. Requires the infrastructure setup chain (Pattern 5 from checklist) to be complete: published world package, AdminCap, characters, NetworkNode, 2 linked gates.

Steps:
1. If on local devnet: run infrastructure setup (create characters, NWN, 2 gates, fuel, link)
2. Authorize `GateAuth` extension on both gates via `gate::authorize_extension<GateAuth>(&mut gate, &owner_cap)`
3. Set tribe rule (tribe_id = 1) and coin toll (5 SUI) for the linked gates
4. Test: correct tribe character + 5 SUI → request_jump_permit → JumpPermit issued → jump_with_permit succeeds
5. Test: wrong tribe character → MoveAbort (ETribeMismatch)
6. Test: correct tribe but insufficient payment → MoveAbort
7. Verify TollCollectedEvent and JumpEvent emitted

**Files:**
- Script or PTB commands for integration test
- `notes/day1-validation.md` (tx digests recorded)

**Definition of Done:**
- All 3 test scenarios produce expected outcomes
- JumpPermit issued and consumed (single-use confirmed)
- TollCollectedEvent emitted with correct gate_id, character_id, amount
- JumpEvent emitted by world-contracts
- All transaction digests recorded

---

### S15 — Build Gate List page (React)

**Phase:** GateControl  
**Status:** PROVISIONAL  
**Effort:** 2 hours  
**Dependencies:** S07, S08  
**Description:** Implement the Gate List view per UX spec §4. After wallet connects and Character is resolved, enumerate OwnerCap<Gate> objects via `suix_getOwnedObjects` (filter by StructType). Read each gate's state via `sui_multiGetObjects`. Display in a list/table with columns: Status (color dot), Name (user-assigned label from localStorage), ID (truncated), Link Partner, Extension badge, Rules summary, Fuel source status.

Implement portrait-responsive layout — card grid at ≤800px (in-game browser), table at ≥800px (external browser). Validate at 787px viewport width.

Read path follows §1 of read-path-architecture-validation.md:
1. Character ID → `suix_getOwnedObjects(character_object_address, OwnerCap<Gate> filter)` 
2. Extract `authorized_object_id` from each OwnerCap
3. `sui_multiGetObjects(gate_ids, { showContent: true })`

Per UX spec: empty state shows "No Gates Found" message (not a create button — gate creation requires AdminCap).

**Files:**
- `frontend/src/pages/GatesPage.tsx`
- `frontend/src/components/GateList.tsx`
- `frontend/src/hooks/useOwnedGates.ts`
- `frontend/src/lib/queries.ts`

**Definition of Done:**
- Gate list renders with real on-chain data after wallet connect
- Status indicators (online/offline) display correctly
- Truncated object ID with copy-to-clipboard
- Empty state renders when no gates found
- `npm run build` passes with no TS errors

**Assumption to verify:** `suix_getOwnedObjects` with StructType filter works on the hackathon test server. Character object address (not wallet address) is the target for OwnerCap discovery.

---

### S16 — Build Gate Detail page with overview section

**Phase:** GateControl  
**Status:** PROVISIONAL  
**Effort:** 1.5 hours  
**Dependencies:** S15  
**Description:** Implement Gate Detail view per UX spec §5. Single-page layout with collapsible sections. Overview header shows: Gate Name (editable label stored in localStorage), Object ID (full hex + copy), Status badge, Extension Type badge, Link Partner (name/ID or "Unlinked"), Energy Source (NWN + fuel status), Tags.

Quick Actions: Online/Offline toggle that constructs PTB: `borrow_owner_cap<Gate>` → `gate::online/offline` → `return_owner_cap`.

**Files:**
- `frontend/src/pages/GateDetailPage.tsx`
- `frontend/src/components/GateOverview.tsx`
- `frontend/src/hooks/useGateDetail.ts`
- `frontend/src/lib/ptb.ts` (PTB construction helpers)

**Definition of Done:**
- Gate detail page renders all overview fields from on-chain data
- Status badge reflects actual gate status
- Extension badge shows "GateControl" or "None"
- Link partner displays correctly (or "Unlinked")
- `npm run build` passes

**Assumption to verify:** Gate object content fields are readable via `sui_getObject` with `showContent: true`. Field names match world-contracts struct definitions.

---

### S17 — Build Rule Composer UI

**Phase:** GateControl  
**Status:** PROVISIONAL  
**Effort:** 3 hours  
**Dependencies:** S16, S13  
**Description:** Implement the Rule Composer panel per UX spec §6. Two module cards for MVP:

**Tribe Filter card:** Toggle on/off. Config: Allowed Tribe ID (numeric input, u32). Status line: "Tribe Filter: Allow Tribe 7 only" or "Off".

**Coin Toll card:** Toggle on/off. Config: Toll Amount (numeric input in MIST, display SUI equivalent). Treasury address (auto-filled with connected wallet, editable). Status line: "Coin Toll: 5 SUI per jump → Treasury: 0x1a2b...".

**Composition preview:** Auto-generated summary: "Active Policy: Tribe 7 only + 5 SUI toll".

**Diff display (if modifying):** Show before→after for changed rules.

**Deploy Policy button:** Constructs a single PTB that:
1. Borrows OwnerCap<Gate> from Character
2. Calls `set_tribe_rule()` and/or `set_coin_toll()` on config
3. If first time: calls `gate::authorize_extension<GateAuth>()` on both linked gates
4. Returns OwnerCap
5. Prompts wallet signature

Read current rule state by querying dynamic fields on CivControlConfig for the gate's ID.

**Files:**
- `frontend/src/components/RuleComposer.tsx`
- `frontend/src/components/TribeFilterCard.tsx`
- `frontend/src/components/CoinTollCard.tsx`
- `frontend/src/components/PolicyPreview.tsx`
- `frontend/src/lib/ptb.ts` (add deployPolicy PTB builder)
- `frontend/src/hooks/useGateRules.ts`

**Definition of Done:**
- Tribe filter toggle + config input renders
- Coin toll toggle + config input renders
- Policy summary auto-generates from active rules
- "Deploy Policy" button constructs correct PTB (inspectable in console)
- After wallet signs, on-chain state reflects the configured rules
- `npm run build` passes

**Assumption to verify:** `suix_getDynamicFields` returns DFs on the shared CivControlConfig keyed by gate ID. The DF value content is readable via `sui_getDynamicFieldObject`.

---

### S18 — Wire extension authorization for linked gate pairs

**Phase:** GateControl  
**Status:** CONFIRMED  
**Effort:** 1 hour  
**Dependencies:** S17  
**Description:** Ensure the "Deploy Policy" PTB also handles first-time extension authorization. When a gate has no extension (`extension: None`), the PTB must include `gate::authorize_extension<GateAuth>()` calls for BOTH the source gate and its linked partner (both gates must share the same extension type for `issue_jump_permit` to work).

If the linked gate has a different owner → display warning per UX spec §5b: "Partner gate has a different extension type. Jump permits will not work until both gates match." The PTB can only authorize gates the current player owns (has OwnerCap for).

**Files:**
- `frontend/src/lib/ptb.ts` (extend deployPolicy builder)
- `frontend/src/components/RuleComposer.tsx` (add extension status check)

**Definition of Done:**
- Deploy Policy PTB includes `authorize_extension` when gate has no extension
- Both gates in a linked pair are authorized in the same PTB (if same owner)
- Warning displayed if linked gate has different/no extension and different owner
- After signing, both gates show `extension: Some(TypeName)` matching CivControl package
- Integration test: policy deploy → tribe character jumps successfully

---

## Phase 3: TradePost Core (Hours 18–30)

### S19 — Implement Listing shared object in Move

**Phase:** TradePost  
**Status:** PROVISIONAL  
**Effort:** 2 hours  
**Dependencies:** S09  
**Description:** Define the `Listing` shared object struct and creation function:

```move
public struct Listing has key, store {
    id: UID,
    ssu_id: ID,           // StorageUnit this listing references
    seller: address,       // seller's address for payment routing
    item_type_id: u64,     // type of item being sold
    price_mist: u64,       // price in MIST
    is_active: bool,       // active/inactive state
}
```

Implement:
- `create_listing(config, ssu, owner_cap, item_type_id, price_mist, ctx)` → creates shared Listing. Verify caller owns the SSU via OwnerCap. SSU must have the extension authorized.
- `cancel_listing(listing, owner_cap, ctx)` → sets `is_active: false` (only seller/owner)
- Emit `ListingCreatedEvent` and `ListingCancelledEvent` (custom events for Signal Feed)

**Design around partial-quantity limitation:** Each listing sells the FULL item (no `split_item` in world-contracts). If seller has 100 units of type_id 42, the listing sells all 100. Document this constraint in the UI.

**Files:**
- `contracts/civcontrol/sources/trade_post.move`

**Definition of Done:**
- `sui move build` passes
- `sui move test` passes: create listing → verify fields → cancel → verify is_active=false
- Listing is a shared object (created via `transfer::share_object`)
- ListingCreatedEvent has `copy, drop` abilities
- Listings reference SSU by ID (not embedded item)

**Assumption to verify:** Shared Listing objects are discoverable via `suix_queryEvents` for ListingCreatedEvent (or `suix_getOwnedObjects` if not shared). Active listing discovery may require event-based indexing.

---

### S20 — Implement atomic buy function in Move

**Phase:** TradePost  
**Status:** CONFIRMED  
**Effort:** 2.5 hours  
**Dependencies:** S19  
**Description:** Implement the buyer-signed atomic buy function:

```move
public fun buy(
    config: &CivControlConfig,
    ssu: &mut StorageUnit,
    character: &Character,
    listing: &mut Listing,
    payment: Coin<SUI>,
    ctx: &mut TxContext,
)
```

Internal flow:
1. Assert `listing.is_active == true`
2. Assert `listing.ssu_id == object::id(ssu)`
3. Assert `coin::value(&payment) >= listing.price_mist`
4. Call `storage_unit::withdraw_item<TradeAuth>(ssu, character, TradeAuth{}, listing.item_type_id, ctx)` → gets `Item`
5. `transfer::public_transfer(item, ctx.sender())` → item to buyer
6. Split exact payment: `let exact = coin::split(&mut payment, listing.price_mist, ctx)`
7. `transfer::public_transfer(exact, listing.seller)` → payment to seller
8. Return change to buyer: `transfer::public_transfer(payment, ctx.sender())`
9. Set `listing.is_active = false`
10. Emit `TradeSettledEvent { ssu_id, buyer_character_id, seller_character_id, item_type_id, quantity, price, timestamp_ms }`

**Key insight from validation:** `withdraw_item<Auth>` does NOT require OwnerCap — only the `TradeAuth{}` witness value and shared object references. This enables buyer-signed cross-address atomic settlement.

**Files:**
- `contracts/civcontrol/sources/trade_post.move` (extend)

**Definition of Done:**
- `sui move build` passes
- `sui move test` passes:
  - Buyer with sufficient funds → item transferred + payment to seller + listing inactive
  - Buyer with insufficient funds → MoveAbort
  - Buy on inactive listing → MoveAbort
  - Overpayment → change returned to buyer
- TradeSettledEvent emitted with all fields
- Item has `key + store` → `transfer::public_transfer` valid (assumption A4)

---

### S21 — Deploy TradePost and integration test on target network

**Phase:** TradePost  
**Status:** CONFIRMED  
**Effort:** 2 hours  
**Dependencies:** S10, S20, S04  
**Description:** End-to-end integration test of TradePost on the target network. Requires: SSU anchored, fueled NWN, SSU online, items deposited in SSU.

Steps:
1. If not already done: anchor SSU, connect to NWN, bring online, deposit test items
2. Authorize `TradeAuth` extension on SSU: `storage_unit::authorize_extension<TradeAuth>(&mut ssu, &owner_cap)`
3. Create listing: seller creates Listing (shared) for item_type_id at price
4. Buy: different address constructs PTB with `--split-coins gas [amount]` + `buy()` call
5. Verify: item ownership transferred to buyer, payment to seller, listing inactive
6. Verify: TradeSettledEvent emitted

**Files:**
- Script or PTB commands for integration test
- `notes/day1-validation.md` (tx digests)

**Definition of Done:**
- Listing creation succeeds
- Cross-address buy succeeds (buyer ≠ seller)
- Item object now owned by buyer address
- Seller balance increased by listing price
- Listing is_active = false
- TradeSettledEvent and ItemWithdrawnEvent in transaction events
- All tx digests recorded

---

### S22 — Build Trade Post List page

**Phase:** TradePost  
**Status:** PROVISIONAL  
**Effort:** 1.5 hours  
**Dependencies:** S07, S08  
**Description:** Implement SSU List view per UX spec: list of owned StorageUnits with status, listing count, extension badge, revenue. Discovery follows same OwnerCap pattern as gates: `suix_getOwnedObjects(character_address, OwnerCap<StorageUnit> filter)` → `authorized_object_id` → `sui_multiGetObjects`.

**Files:**
- `frontend/src/pages/TradePostsPage.tsx`
- `frontend/src/components/TradePostList.tsx`
- `frontend/src/hooks/useOwnedSSUs.ts`

**Definition of Done:**
- SSU list renders with real on-chain data
- Status indicators (online/offline) correct
- Extension badge shows "TradePost" or "None"
- Empty state renders correctly
- `npm run build` passes

**Assumption to verify:** OwnerCap<StorageUnit> StructType filter string is correct for `suix_getOwnedObjects` on the target network.

---

### S23 — Build Trade Post Detail page with inventory + listing management

**Phase:** TradePost  
**Status:** PROVISIONAL  
**Effort:** 2.5 hours  
**Dependencies:** S22, S19  
**Description:** Implement SSU Detail view: overview (name, ID, status, extension), inventory browser (read items from SSU inventory via dynamic fields), listing management (create listing form, active listings list, cancel button).

Inventory reading: Use `suix_getDynamicFields` on the SSU's inventory UID to enumerate items. Each item has `type_id` (u64), `quantity` (u32), `volume` (u64), `item_id` (u64), `tenant` (String), `location`. **PROVISIONAL:** Item struct has NO `name` field — display `type_id` or resolve names via external lookup.

Create Listing form: select item from inventory → set price → submits PTB calling `create_listing()`.
Cancel Listing: button on each active listing → submits PTB calling `cancel_listing()`.

Per constraint: listing sells FULL item (no partial quantity split). UI displays "Full quantity" note.

**Files:**
- `frontend/src/pages/TradePostDetailPage.tsx`
- `frontend/src/components/InventoryBrowser.tsx`
- `frontend/src/components/ListingManager.tsx`
- `frontend/src/components/CreateListingForm.tsx`
- `frontend/src/hooks/useSSUDetail.ts`
- `frontend/src/hooks/useSSUInventory.ts`

**Definition of Done:**
- Inventory items display from on-chain SSU data
- Create Listing form submits valid PTB
- After signing, Listing shared object created
- Cancel Listing marks listing inactive
- "Full quantity" note visible on create form
- `npm run build` passes

**Assumption to verify:** SSU inventory structure (dynamic fields under `owner_cap_id` key) is readable via RPC. Item field layout matches `Item { id, key, type_id, quantity, volume, name }`.

---

### S24 — Build buyer-facing listing browser + buy flow

**Phase:** TradePost  
**Status:** PROVISIONAL  
**Effort:** 2 hours  
**Dependencies:** S23, S20  
**Description:** Implement the buyer's view: browse active listings, one-click buy. Listing discovery: query `ListingCreatedEvent` events from the CivControl package, read listing objects, filter for `is_active: true`.

Buy flow: buyer selects listing → confirms price → PTB constructs `splitCoins(gas, [price])` + `buy(config, ssu, character, listing, payment)` → wallet signs → confirmation: "Trade settled. [Item] acquired for [X] SUI."

Display balance deltas: buyer's SUI balance before/after. Seller's balance (if visible via listing.seller).

**Files:**
- `frontend/src/pages/BrowseListingsPage.tsx` (or integrate into TradePost page)
- `frontend/src/components/ListingBrowser.tsx`
- `frontend/src/components/BuyConfirmation.tsx`
- `frontend/src/hooks/useListings.ts`
- `frontend/src/lib/ptb.ts` (add buyItem PTB builder)

**Definition of Done:**
- Active listings display with item type, price, seller
- Buy button constructs correct PTB with coin split
- After signing, item ownership transfers + payment routes
- Confirmation message shows settled trade details
- Inactive/sold listings filtered or marked
- `npm run build` passes

**Assumption to verify:** Listing shared objects are discoverable. Options: (a) query ListingCreatedEvent by package → get listing IDs, (b) if listing IDs are known, direct object reads. Event-based discovery is preferred.

---

## Phase 4: UX Polish + Signal Feed (Hours 30–40)

### S25 — Build Command Overview (Dashboard) page

**Phase:** UX  
**Status:** PROVISIONAL  
**Effort:** 2.5 hours  
**Dependencies:** S15, S22  
**Description:** Implement Command Overview per UX spec §3. Landing page after wallet connect + Character resolution. Shows:

- **Aggregated Metrics cards:** Total structures count, Online/Offline counts, Active policies count (gates with non-null extension), Total revenue (from event aggregation)
- **Alert/Warning cards:** Offline structures (red), Low fuel (amber), Unlinked gates (gray), Unconfigured gates (no extension)
- **Recent Signal Preview:** Last 5 events from Signal Feed
- **Quick Action shortcuts (stretch):** "Deploy Policy", "Create Listing"

Derive health data from object state polling. Revenue requires event aggregation (S26).

**Files:**
- `frontend/src/pages/CommandOverviewPage.tsx`
- `frontend/src/components/MetricCards.tsx`
- `frontend/src/components/AlertCards.tsx`
- `frontend/src/components/RecentSignals.tsx`
- `frontend/src/hooks/useStructureSummary.ts`

**Definition of Done:**
- Dashboard renders with real aggregated data
- Structure counts correct
- At least one alert type displays (offline or low fuel)
- Recent signals show last 5 events (even if placeholder)
- Demo beat 2 ("The Reveal") can be captured from this screen
- `npm run build` passes

**Assumption to verify:** Batch object reads via `sui_multiGetObjects` return sufficient data for all metric calculations (status, extension, linked_gate_id).

---

### S26 — Build Signal Feed with event polling

**Phase:** UX  
**Status:** PROVISIONAL  
**Effort:** 3 hours  
**Dependencies:** S25, S14, S21  
**Description:** Implement Signal Feed per UX spec: chronological event stream across all owned structures. Data sources per read-path §2:

1. **JumpEvent** (world-contracts) — passage signal. Query via `suix_queryEvents({ MoveEventType: "...::gate::JumpEvent" })`, filter by owned gate IDs client-side.
2. **TollCollectedEvent** (CivControl extension) — toll revenue. Query by CivControl package event type.
3. **TradeSettledEvent** (CivControl extension) — trade revenue. Query by CivControl package event type.
4. **StatusChangedEvent** (world-contracts) — online/offline changes.
5. **FuelEvent** (world-contracts) — fuel lifecycle events.

Polling interval: 10 seconds (MVP). Display format per UX spec §5e: timestamp, event type icon, description, amount (if applicable), tx digest link.

Revenue aggregation: sum TollCollectedEvent + TradeSettledEvent amounts for the revenue counter.

**Files:**
- `frontend/src/pages/SignalFeedPage.tsx`
- `frontend/src/components/SignalFeed.tsx`
- `frontend/src/components/SignalEntry.tsx`
- `frontend/src/hooks/useEventPolling.ts`
- `frontend/src/lib/eventParser.ts`

**Definition of Done:**
- Signal Feed page renders chronological event list
- At least 3 event types display correctly (JumpEvent, TollCollectedEvent, TradeSettledEvent)
- Polling refreshes every 10 seconds
- Revenue total computed from toll + trade events
- Events scoped to player's owned structures
- Demo beats 4, 5, 6 can display signal entries
- `npm run build` passes

**Assumption to verify:** `suix_queryEvents` with `MoveEventType` filter works on the hackathon RPC endpoint. Cursor-based pagination returns events in chronological order.

---

### S27 — Implement Character resolution flow

**Phase:** UX  
**Status:** PROVISIONAL  
**Effort:** 1.5 hours  
**Dependencies:** S08  
**Description:** Implement the Character resolution flow per UX spec §10b and read-path §1.1. After wallet connects, resolve wallet address → Character ID.

MVP: Manual fallback (Option D) — "Enter your Character ID" input field after wallet connect. Validate format (Sui object ID), verify Character object exists via RPC, verify `character_address == connected wallet`.

Stretch: Attempt automatic resolution via `suix_queryEvents({ MoveEventType: "...::character::CharacterCreatedEvent" })` filtered by `character_address` field.

Store resolved Character ID in session storage. All structure discovery depends on this.

**In-game URL context:** If launched from the in-game DApp browser, check URL path parameters for structure context. The DApp URL format should support `/gate/<objectId>` or `/ssu/<objectId>` so that clicking a structure in-game deep-links directly to its detail page, bypassing manual Character resolution for read-only viewing.

**Files:**
- `frontend/src/components/CharacterResolver.tsx`
- `frontend/src/hooks/useCharacter.ts`
- `frontend/src/lib/queries.ts` (character resolution queries)

**Definition of Done:**
- Manual Character ID input field appears after wallet connect
- Valid Character ID → structures load
- Invalid ID → error message per UX spec §10b error states
- Wallet/Character mismatch detected and displayed
- Resolved Character ID persists across page reloads (session storage)
- `npm run build` passes

**Assumption to verify:** Character object's `character_address` field is readable via `sui_getObject` with `showContent: true`.

---

### S28 — Add structure labeling (localStorage)

**Phase:** UX  
**Status:** CONFIRMED  
**Effort:** 0.5 hours  
**Dependencies:** S15  
**Description:** Implement user-assigned labels for structures stored in localStorage. Per UX spec §5a: inline editable name field. Default: truncated object ID. Labels keyed by object ID in localStorage. Used throughout gate list, detail, and Signal Feed for human-readable structure names.

**Files:**
- `frontend/src/hooks/useStructureLabels.ts`
- `frontend/src/components/EditableLabel.tsx`

**Definition of Done:**
- Labels editable inline on gate list and detail pages
- Labels persist across page reloads (localStorage)
- Default display is truncated object ID when no label set
- Labels appear in Signal Feed entries
- `npm run build` passes

---

### S29 — Implement error states and transaction feedback

**Phase:** UX  
**Status:** PROVISIONAL  
**Effort:** 1.5 hours  
**Dependencies:** S17, S24  
**Description:** Implement transaction feedback states across all write operations: pending (spinner), success (confirmation with tx digest), failure (error with MoveAbort code parsing). Per demo beat sheet: denied jump shows "Jump denied. Tribe mismatch." Signal Feed entry with red indicator.

Parse wallet adapter failure responses: `effects.status: "failure"` → extract module + abort code → map to human-readable message. Known abort codes:
- `civcontrol::gate_permit` code 0 → "Tribe mismatch"
- `civcontrol::gate_permit` code 1 → "Insufficient payment"
- `civcontrol::trade_post` code 0 → "Listing inactive"

Add toast notifications for transient feedback. Error cards per UX spec §10e for persistent issues.

**Files:**
- `frontend/src/components/TransactionFeedback.tsx`
- `frontend/src/components/ToastNotification.tsx`
- `frontend/src/lib/errorMapper.ts`
- `frontend/src/hooks/useTransactionStatus.ts`

**Definition of Done:**
- Pending transaction shows spinner
- Successful transaction shows digest link
- Failed transaction shows human-readable error message
- MoveAbort codes parsed for known extension errors
- Toast notifications appear and auto-dismiss
- `npm run build` passes

**Assumption to verify:** `@mysten/dapp-kit` `useSignAndExecuteTransaction` hook returns failure details including abort module and code.

---

### S30 — Polish narrative labels and voice compliance

**Phase:** UX  
**Status:** CONFIRMED  
**Effort:** 1 hour  
**Dependencies:** S25, S26  
**Description:** Audit all UI-facing text against the Voice & Narrative Guide canonical terminology table. Replace any generic SaaS terms:

| Replace | With |
|---------|------|
| Dashboard | Command Overview |
| Activity / Notifications / Log | Signal Feed |
| Objects / Items / Smart Assemblies | Structures / Gates / Trade Posts |
| Settings | Configuration |
| User / Admin | Operator |
| Submit / Save | Deploy |
| Error | Fault |
| Active / Inactive | Online / Offline |

Run Narrative Impact Check (§8) on: navigation labels, page titles, headings, empty states, confirmation messages.

**Files:**
- All `frontend/src/pages/*.tsx`
- All `frontend/src/components/*.tsx`

**Definition of Done:**
- Zero instances of banned terms in user-visible UI text
- Navigation sidebar uses canonical labels
- Empty states match UX spec language
- Confirmation messages use "Deploy" not "Submit"
- No celebration ("Congratulations!"), no hedging ("Something may have gone wrong")

---

## Phase 5: ZK GatePass Stretch (Hours 40–56, if time permits)

### S31 — ZK Kill Gate R1: Verify circom + snarkjs toolchain in hackathon env

**Phase:** ZK-Stretch  
**Status:** CONFIRMED  
**Effort:** 0.5 hours  
**Dependencies:** S14  
**Description:** Verify that the Circom 2.2.0 + snarkjs 0.7.5 toolchain compiles and generates proofs in the hackathon environment. Compile the membership circuit (depth 10, Poseidon(2), 2,430 constraints). Generate a test proof. If toolchain fails → **KILL ZK immediately** and return to UX polish.

**Kill criteria R1:** If circuit compilation takes > 30 minutes or fails with dependency errors, kill ZK.

**Files:**
- `circuits/membership/membership.circom`
- `circuits/membership/circuit.json`

**Definition of Done:**
- Membership circuit compiles successfully
- Test proof generates in < 5 seconds
- Proof is 128 bytes (Groth16 BN254 compressed)
- OR: Kill decision documented with reason

---

### S32 — ZK Kill Gate R2: Verify browser-side proof generation (WASM)

**Phase:** ZK-Stretch  
**Status:** PROVISIONAL  
**Effort:** 1 hour  
**Dependencies:** S31  
**Description:** Verify that snarkjs WASM prover generates valid membership proofs in the browser. Load circuit WASM + zkey into browser. Generate proof with test inputs. Serialize to Sui format (128 bytes proof + 32 bytes public input). Verify timing < 2 seconds.

**In-game browser limitation:** The in-game browser lacks `crossOriginIsolated` (no COOP/COEP headers), so `SharedArrayBuffer` is unavailable and snarkjs WASM prover is limited to **single-threaded mode**. Verify proof generation time in single-threaded mode stays under the kill threshold. Test explicitly with `Cross-Origin-Isolation: false` in DevTools to simulate.

**Kill criteria R2:** If browser proof generation takes > 5 seconds or WASM loading fails → KILL.

**Files:**
- `frontend/src/lib/zkProver.ts`
- `frontend/public/circuits/` (WASM + zkey files)

**Definition of Done:**
- Browser generates valid proof from test inputs
- Proof serialized to Sui format (128 bytes + 32 bytes)
- Generation time < 2 seconds
- OR: Kill decision documented

**Assumption to verify:** snarkjs WASM prover works in modern browsers without CSP issues. Circuit files (WASM ~2MB, zkey ~500KB) load within 3 seconds.

---

### S33 — ZK Kill Gate R3: Publish ZK gate module and verify on-chain

**Phase:** ZK-Stretch  
**Status:** CONFIRMED  
**Effort:** 1.5 hours  
**Dependencies:** S31, S10  
**Description:** Implement and publish the `zk_gate` module within the CivControl package. Defines `ZKAuth has drop {}`, `ZKGateConfig` (stores VK bytes), `verify_membership()` function.

```move
public fun verify_and_issue_permit(
    config: &CivControlConfig,
    zk_config: &ZKGateConfig,
    source_gate: &Gate,
    dest_gate: &Gate,
    character: &Character,
    proof_points: vector<u8>,
    public_inputs: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext,
)
```

Internally: `groth16::prepare_verifying_key()` → `groth16::verify_groth16_proof()` → if valid, call `gate::issue_jump_permit<GateAuth>(...)` (uses the same GateAuth witness, not a separate ZKAuth — single extension constraint).

**Kill criteria R3:** If on-chain verification fails or gas exceeds 10M MIST → KILL.

**Files:**
- `contracts/civcontrol/sources/zk_gate.move`

**Definition of Done:**
- `sui move build` passes
- Module published to target network
- Test: valid proof → JumpPermit issued (~1M MIST gas)
- Test: invalid proof → MoveAbort
- OR: Kill decision documented

---

### S34 — ZK Kill Gate R4: End-to-end browser → chain ZK jump

**Phase:** ZK-Stretch  
**Status:** PROVISIONAL  
**Effort:** 2 hours  
**Dependencies:** S32, S33  
**Description:** Full integration: browser generates membership proof → serializes → constructs PTB calling `verify_and_issue_permit()` → signs → submits → JumpPermit issued on-chain → `jump_with_permit()` consumes permit.

**Kill criteria R4:** If end-to-end flow fails after 2 hours of debugging → KILL.

**Files:**
- `frontend/src/lib/ptb.ts` (add zkJump PTB builder)
- `frontend/src/components/ZKGateAccess.tsx`

**Definition of Done:**
- Browser → proof generation → PTB → wallet sign → on-chain verify → permit → jump
- Total user-facing latency < 5 seconds
- OR: Kill decision documented

**Assumption to verify:** PTB can include the 128-byte proof + 32-byte public inputs as `vector<u8>` arguments to the Move function via `@mysten/sui` SDK.

---

### S35 — ZK Rule Composer integration

**Phase:** ZK-Stretch  
**Status:** PROVISIONAL  
**Effort:** 1.5 hours  
**Dependencies:** S34, S17  
**Description:** Add ZK Membership card to the Rule Composer UI per UX spec §6. Toggle on/off. Config: member list editor (off-chain — only Merkle root goes on-chain). Display: "ZK Membership: Active (root: 0x3f2a...)".

Member list management: simple address list editor. Compute Poseidon Merkle root client-side. Store VK + root on CivControlConfig via PTB.

**Files:**
- `frontend/src/components/ZKMembershipCard.tsx`
- `frontend/src/lib/merkleTree.ts`
- `frontend/src/lib/ptb.ts` (add setZKConfig PTB builder)

**Definition of Done:**
- ZK Membership card renders in Rule Composer
- Member list editable
- Merkle root computed and displayed
- Deploy stores VK + root on-chain
- ZK-gated jump works end-to-end via UI
- OR: Kill decision documented

**Assumption to verify:** Poseidon hash in browser (circomlibjs) matches the circuit's Poseidon implementation.

---

## Phase 6: Demo Recording + Submission (Hours 56–72)

### S36 — Set up demo environment with pre-deployed state

**Phase:** Demo  
**Status:** CONFIRMED  
**Effort:** 2 hours  
**Dependencies:** S14, S21  
**Description:** Prepare the demo environment with all required pre-deployed state:

- 3 funded accounts: Operator, Hostile Pilot (wrong tribe), Ally Pilot / Buyer (matching tribe)
- 2 linked gates (both with GateAuth extension, tribe rule = 7, toll = 5 SUI)
- 1 SSU Trade Post (with TradeAuth extension, stocked with Fuel Rod item, listing at 30 SUI)
- 1 NWN (fueled, online, connected to gates + SSU)
- Structure labels assigned in the UI
- All structures online

**In-game browser validation:** After deploying the DApp to a reachable URL, load it inside the EVE Frontier in-game browser. Verify:
- Page loads without CSP or CORS errors
- Viewport renders correctly at 787×1198 portrait
- Read-only Viewing Mode activates (EVM wallet detected, no Sui wallet)
- Deep-link URL `/gate/<objectId>` resolves to the correct gate detail
- No `crossOriginIsolated`-dependent features fail silently
- Reference: [in-game-dapp-surface.md](../architecture/in-game-dapp-surface.md)

Run the full infrastructure setup sequence (Pattern 5) if on local devnet. On test server: use admin tools.

**Files:**
- Setup script or documented PTB sequence
- `notes/demo-setup.md`

**Definition of Done:**
- All 3 accounts funded and Character objects created
- 2 gates linked, online, extension authorized, tribe+toll rules set
- 1 SSU online, extension authorized, item stocked, listing active
- Operator balance recorded (pre-demo baseline)

---

### S37 — Capture Beat 1: "The Problem" CLI footage

**Phase:** Demo  
**Status:** CONFIRMED  
**Effort:** 0.5 hours  
**Dependencies:** S36  
**Description:** Pre-record terminal session showing raw `sui client ptb` commands from the gate lifecycle. Show 13-step complexity. Include a failed PTB error. Optionally capture a Discord screenshot "is the gate down?" message. This is the "before" state for the demo.

**Files:**
- Recorded video clip / screenshots

**Definition of Done:**
- Terminal recording shows ≥5 complex PTB commands scrolling
- At least 1 error message visible
- Clip is < 25 seconds

---

### S38 — Capture Beats 2–7: Live UI recording

**Phase:** Demo  
**Status:** PROVISIONAL  
**Effort:** 3 hours  
**Dependencies:** S36, S25, S26, S17, S24  
**Description:** Record the primary demo variant (3 minutes) live from the UI:

- **Beat 2 (0:25–0:50):** Command Overview loads, structures populate, status indicators resolve
- **Beat 3 (0:50–1:20):** Gate detail → Rule Composer → set tribe 7 + 5 SUI toll → Deploy Policy → tx confirmation
- **Beat 4 (1:20–1:45):** Hostile pilot jump attempt → wallet returns failure → Signal Feed shows denied (red)
- **Beat 5 (1:45–2:10):** Ally pilot jump → toll paid → Signal Feed shows permitted (green) + revenue counter +5 SUI
- **Beat 6 (2:10–2:40):** Trade Post browse → Buy fuel rod 30 SUI → atomic settlement → Signal Feed + revenue
- **Beat 7 (2:40–3:00):** Pull back to Command Overview, full state visible, hold 3 seconds, title card

Per demo beat sheet: if TradePost UI not ready, use GateControl-only fallback variant (2 minutes, Beats 1–5 + close).

**Files:**
- Recorded video (primary variant)

**Definition of Done:**
- All 5 non-negotiable proof moments captured:
  1. Policy deploy tx digest visible
  2. Hostile denied tx digest + MoveAbort visible
  3. Ally tolled tx + operator balance delta visible
  4. Trade buy tx + buyer/seller balance deltas visible
  5. Aggregate revenue in Command Overview visible
- Video ≤ 3:30 (3:00 target)
- No secrets visible (keys, full addresses, unrelated browser data)

**Assumption to verify:** Transaction confirmation latency is < 5 seconds on the target network. If > 5s, use narration-over-wait technique per beat sheet.

---

### S39 — Optional: Capture ZK accent segment

**Phase:** Demo  
**Status:** PROVISIONAL  
**Effort:** 1 hour  
**Dependencies:** S34, S38  
**Description:** If ZK GatePass is integrated and stable: record the 30-second ZK accent segment. Insert before the closing beat. Show Signal Feed "ZK pass verified" entry with green indicator + ZK badge. Overlay: tx digest, `is_valid: true`, gas (~1M MIST), circuit stats.

Skip if ZK is killed or unstable.

**Files:**
- Recorded video clip (30 seconds)

**Definition of Done:**
- ZK proof verified on-chain in recorded flow
- Signal Feed shows ZK-specific entry
- Proof overlay data captured
- OR: Omitted (ZK killed)

---

### S40 — Add proof overlays and edit final demo video

**Phase:** Demo  
**Status:** CONFIRMED  
**Effort:** 2 hours  
**Dependencies:** S37, S38  
**Description:** Post-production: splice Beat 1 CLI footage + Beats 2–7 live recording. Add evidence overlays:
- Beat 3: tx digest of policy deploy + gate object state
- Beat 4: tx digest of denied attempt + MoveAbort code
- Beat 5: tx digest + TollCollectedEvent + balance delta
- Beat 6: tx digest + TradeSettledEvent + balance deltas + listing state
- Beat 7: aggregate revenue total

Add title card: "CivilizationControl — The Frontier Control Room". Add package ID badge in corner.

**Files:**
- Final demo video file

**Definition of Done:**
- Final video ≤ 3:30
- All 5 proof overlays present with real tx digests
- No secrets visible
- Title card + package ID visible

---

### S41 — Write submission README

**Phase:** Demo  
**Status:** CONFIRMED  
**Effort:** 1.5 hours  
**Dependencies:** S14, S21, S38  
**Description:** Write the hackathon submission README.md. Include: project overview, problem statement, solution description, architecture diagram, how to run, demo video link, package IDs, technology stack, team info, acknowledgments. Reference judging criteria from hackathon rules digest.

**Files:**
- `README.md` (hackathon repo root)

**Definition of Done:**
- README covers: problem, solution, architecture, setup instructions, demo video link
- Package IDs listed
- Technology stack listed (Sui Move, React, @mysten/dapp-kit)
- Judging-criteria aligned: innovation, technical execution, game impact, presentation
- No sandbox references

---

### S42 — Final submission: repo hygiene + Deepsurge registration

**Phase:** Demo  
**Status:** CONFIRMED  
**Effort:** 0.5 hours  
**Dependencies:** S41  
**Description:** Final pre-submission checklist:
- All code committed and pushed
- No secrets in repo (grep for mnemonics, private keys, .env files)
- Demo video link in README
- Deepsurge project registered with GitHub repo URL
- Submission before deadline (March 31, 2026 23:59 UTC)
- Verify git history shows all work on or after March 11

**Files:**
- Entire repository

**Definition of Done:**
- `git log --all` shows no commits before March 11
- No `.env` files, keystores, or secrets in repo
- Demo video accessible via link
- Deepsurge submission confirmed
- README complete

---

## Cross-Cutting / Parallel Steps

### S43 — Implement app-wide polling and state management

**Phase:** Foundation (built incrementally across phases)  
**Status:** PROVISIONAL  
**Effort:** 2 hours (spread across S15, S22, S26)  
**Dependencies:** S08  
**Description:** Implement the core polling loop and state management layer used by all pages. 10-second polling interval for structure state + events. Use `@tanstack/react-query` for caching and automatic refetching.

Key queries:
- `useOwnedStructures(characterId)` — discovers OwnerCaps → reads structures
- `useStructureState(objectId)` — reads individual structure state
- `useEventPolling(packageId, eventTypes)` — polls events by type with cursor pagination

All queries auto-refetch on 10-second interval. Stale data tolerance: 1 cycle (10s).

**Files:**
- `frontend/src/hooks/useOwnedStructures.ts`
- `frontend/src/hooks/useStructureState.ts`
- `frontend/src/hooks/useEventPolling.ts`
- `frontend/src/lib/queries.ts`

**Definition of Done:**
- Polling loop runs at 10-second interval
- Structure state updates reflected in UI within 1 poll cycle
- New events appear in Signal Feed within 1 poll cycle
- No duplicate queries (react-query deduplication)
- `npm run build` passes

**Assumption to verify:** `@tanstack/react-query` `refetchInterval` option works correctly with Sui RPC queries via `@mysten/dapp-kit`.

---

### S44 — Implement PTB construction helper library

**Phase:** Foundation (built incrementally across S17, S18, S24)  
**Status:** CONFIRMED  
**Effort:** 2 hours (spread across phases)  
**Dependencies:** S08, S10  
**Description:** Centralized PTB construction library for all write operations. Each function returns a `Transaction` object ready for wallet signing.

Functions:
- `buildDeployPolicyTx(config, gate, linkedGate, character, rules)` — authorize extension + set rules
- `buildUpdateRulesTx(config, gateId, rules)` — modify existing rules
- `buildCreateListingTx(config, ssu, ownerCap, itemTypeId, price)` — create trade listing
- `buildBuyTx(config, ssu, character, listing, price)` — buyer purchase
- `buildCancelListingTx(listing, ownerCap)` — cancel listing
- `buildOnlineOfflineTx(character, structure, nwn, energyConfig, online)` — toggle status

All builders use hot-potato OwnerCap borrow/return pattern where needed. Coin splitting handled via `txb.splitCoins()`.

**Files:**
- `frontend/src/lib/ptb.ts`
- `frontend/src/lib/constants.ts` (package IDs, type strings)

**Definition of Done:**
- Each PTB builder produces a valid `Transaction` object
- Hot-potato pattern (borrow → use → return) correctly composed
- Coin splitting included for toll/buy operations
- Package IDs configurable (not hardcoded)
- At least one PTB tested end-to-end (wallet sign → on-chain effect)
- `npm run build` passes

---

### S45 — Implement Strategic Network Map (SVG topology)

**Phase:** UX (stretch within Phase 4)  
**Status:** PROVISIONAL  
**Effort:** 3 hours  
**Dependencies:** S25, S28  
**Description:** Implement the Strategic Network Map per UX spec §9a. React SVG component (~150–200 LoC). Nodes represent pinned systems/structures. Edges represent gate links. State encoding: node color/border for online/offline/warning, edge styling for link status.

Only renders structures that have manual spatial pins (§8). Unpinned structures appear only in the list view. Click node → navigate to structure detail. Hover → tooltip.

Always-visible disclaimer: "User-curated placement; not on-chain."

**Files:**
- `frontend/src/components/StrategicNetworkMap.tsx`
- `frontend/src/hooks/useSpatialPins.ts`

**Definition of Done:**
- SVG renders pinned structures as nodes
- Gate links drawn as edges between linked gates
- Node colors reflect structure status
- Click navigates to detail page
- Disclaimer visible
- `npm run build` passes

**Assumption to verify:** Manual pin data from localStorage is sufficient to render a meaningful topology. At least 3 structures should be pinned for demo.

---

### S46 — Gate Preset Switching (Enhancement, Cuttable)

**Phase:** UX (enhancement — after S45, cuttable without affecting core delivery)  
**Status:** PROVISIONAL  
**Effort:** 2–3 hours  
**Dependencies:** S45, S44, S18  
**Description:** Provide preset topology configurations for a gate network. The operator selects from predefined topologies (A/B/C presets) via the Strategic Network Map UI. On click, the system issues the necessary `unlink_gates` + `link_gates` transactions to realize the target topology.

**Scope:**
- 2–3 hardcoded preset topologies (e.g., "Hub-and-spoke", "Ring", "Full mesh") for the operator's owned gates
- UI: Preset selector buttons on the Strategic Network Map (§9a). Clicking a preset shows a diff preview (current vs. target links), then executes on confirmation.
- PTB helper: `buildPresetTopologyTx(currentLinks, targetLinks)` in `ptb.ts` — batches `unlink_gates` and `link_gates` calls

**Non-Goals (hard scope guardrails):**
- No automation (no scheduled switching, no event-triggered switching)
- No pathfinding or routing engine
- No dynamic preset generation (presets are hardcoded for demo)
- No multi-owner coordination (only gates owned by the operator)

**Key Constraint:** `link_gates` requires AdminACL sponsor + server-signed distance proof. `unlink_gates` requires only OwnerCaps. This asymmetry means teardown (unlink) is player-callable but setup (re-link) is server-dependent. If distance proof is unavailable, preset switching can only demonstrate unlinking (partial demo still valuable — "shutdown route" preset).

**Files:**
- `frontend/src/components/PresetSelector.tsx`
- `frontend/src/lib/presets.ts` (topology definitions)
- `frontend/src/lib/ptb.ts` (add `buildPresetTopologyTx`)

**Definition of Done:**
- Preset buttons visible on Strategic Network Map
- Clicking preset shows link diff (add/remove)
- Confirmation triggers appropriate unlink + link transactions
- Event feed shows topology change
- `npm run build` passes

**Demo value:** 5–10 seconds — click preset → links visually update on map → event feed confirms. Placed as optional accent in demo beat sheet (after core proof moments).

---

## Summary Table

| ID | Title | Phase | Status | Effort | Deps |
|----|-------|-------|--------|--------|------|
| S01 | Create fresh hackathon repo | Day-1 | CONFIRMED | 0.5h | — |
| S02 | Add submodules | Day-1 | CONFIRMED | 0.25h | S01 |
| S03 | Verify critical function signatures | Day-1 | CONFIRMED | 0.5h | S02 |
| S04 | Connect to hackathon server + discover IDs | Day-1 | BLOCKED | 0.5h | S02 |
| S05 | Validate AdminACL sponsor access | Day-1 | BLOCKED | 0.5h | S04 |
| S06 | Validate per-gate DF keys | Day-1 | PROVISIONAL | 0.25h | S04 |
| S07 | Scaffold React + Vite project | Foundation | PROVISIONAL | 1h | S01 |
| S08 | Configure wallet adapter | Foundation | PROVISIONAL | 1h | S07 |
| S09 | Create CivControl Move package | Foundation | CONFIRMED | 1h | S02, S04 |
| S10 | Publish CivControl to target network | Foundation | CONFIRMED | 0.5h | S09, S04 |
| S11 | Implement tribe filter rule (Move) | GateControl | CONFIRMED | 2h | S09 |
| S12 | Implement coin toll rule (Move) | GateControl | CONFIRMED | 1.5h | S09 |
| S13 | Implement request_jump_permit (Move) | GateControl | CONFIRMED | 2.5h | S11, S12 |
| S14 | Deploy GateControl + integration test | GateControl | CONFIRMED | 2h | S10, S13, S05 |
| S15 | Build Gate List page (React) | GateControl | PROVISIONAL | 2h | S07, S08 |
| S16 | Build Gate Detail page | GateControl | PROVISIONAL | 1.5h | S15 |
| S17 | Build Rule Composer UI | GateControl | PROVISIONAL | 3h | S16, S13 |
| S18 | Wire extension authorization for pairs | GateControl | CONFIRMED | 1h | S17 |
| S19 | Implement Listing shared object (Move) | TradePost | PROVISIONAL | 2h | S09 |
| S20 | Implement atomic buy function (Move) | TradePost | CONFIRMED | 2.5h | S19 |
| S21 | Deploy TradePost + integration test | TradePost | CONFIRMED | 2h | S10, S20, S04 |
| S22 | Build Trade Post List page | TradePost | PROVISIONAL | 1.5h | S07, S08 |
| S23 | Build Trade Post Detail + inventory | TradePost | PROVISIONAL | 2.5h | S22, S19 |
| S24 | Build buyer listing browser + buy flow | TradePost | PROVISIONAL | 2h | S23, S20 |
| S25 | Build Command Overview page | UX | PROVISIONAL | 2.5h | S15, S22 |
| S26 | Build Signal Feed with event polling | UX | PROVISIONAL | 3h | S25, S14, S21 |
| S27 | Implement Character resolution flow | UX | PROVISIONAL | 1.5h | S08 |
| S28 | Add structure labeling (localStorage) | UX | CONFIRMED | 0.5h | S15 |
| S29 | Implement error states + tx feedback | UX | PROVISIONAL | 1.5h | S17, S24 |
| S30 | Polish narrative labels + voice | UX | CONFIRMED | 1h | S25, S26 |
| S31 | ZK R1: Verify circom toolchain | ZK-Stretch | CONFIRMED | 0.5h | S14 |
| S32 | ZK R2: Browser proof generation | ZK-Stretch | PROVISIONAL | 1h | S31 |
| S33 | ZK R3: Publish ZK module + on-chain verify | ZK-Stretch | CONFIRMED | 1.5h | S31, S10 |
| S34 | ZK R4: E2E browser → chain ZK jump | ZK-Stretch | PROVISIONAL | 2h | S32, S33 |
| S35 | ZK Rule Composer integration | ZK-Stretch | PROVISIONAL | 1.5h | S34, S17 |
| S36 | Set up demo environment | Demo | CONFIRMED | 2h | S14, S21 |
| S37 | Capture Beat 1 CLI footage | Demo | CONFIRMED | 0.5h | S36 |
| S38 | Capture Beats 2–7 live UI | Demo | PROVISIONAL | 3h | S36, S25, S26, S17, S24 |
| S39 | Optional: ZK accent segment | Demo | PROVISIONAL | 1h | S34, S38 |
| S40 | Edit final demo video + overlays | Demo | CONFIRMED | 2h | S37, S38 |
| S41 | Write submission README | Demo | CONFIRMED | 1.5h | S14, S21, S38 |
| S42 | Final submission + repo hygiene | Demo | CONFIRMED | 0.5h | S41 |
| S43 | Polling + state management (cross-cutting) | Foundation | PROVISIONAL | 2h | S08 |
| S44 | PTB construction library (cross-cutting) | Foundation | CONFIRMED | 2h | S08, S10 |
| S45 | Strategic Network Map (SVG) | UX (stretch) | PROVISIONAL | 3h | S25, S28 |
| S46 | Gate Preset Switching (enhancement) | UX (enhancement) | PROVISIONAL | 2.5h | S45, S44, S18 |

---

## Effort Summary

| Phase | Steps | Total Hours |
|-------|-------|-------------|
| Day-1 Validation | S01–S06 | 2.5h |
| Foundation | S07–S10 | 3.5h |
| GateControl Core | S11–S18 | 14.5h |
| TradePost Core | S19–S24 | 12.5h |
| UX Polish + Signal Feed | S25–S30 | 10.5h |
| ZK GatePass (stretch) | S31–S35 | 6.5h |
| Demo + Submission | S36–S42 | 11h |
| Cross-cutting | S43–S46 | 9.5h |
| **Total** | **46 steps** | **~70.5h** |

Fits within the 72-hour hackathon window with ~1.5 hours of buffer. ZK stretch (6.5h) and Gate Preset Switching (2.5h) are independently cuttable without affecting core submission.

---

## Critical Path

```
S01 → S02 → S03 ──────────────────────────────────────────────────────┐
              └→ S04 → S05 ─────────────────────────────────────────┐ │
              └→ S09 → S11 → S13 ──┐                               │ │
                       S12 → S13 ──┤                               │ │
                                   └→ S14 → S36 → S37 ──┐         │ │
              └→ S04 → S10 ──────────────┘               │         │ │
                                                          │         │ │
S01 → S07 → S08 → S15 → S16 → S17 → S18 ────────────────┤         │ │
                   └→ S22 → S23 → S24 ───────────────────┤         │ │
                                                          │         │ │
                   S25 → S26 ─────────────────────────────┤         │ │
                   S27 (parallel)                         │         │ │
                   S28 (parallel)                         │         │ │
                   S29, S30 (polish) ─────────────────────┤         │ │
                                                          │         │ │
                                              S38 ← all above      │ │
                                              S40 ← S37 + S38      │ │
                                              S41 ← S40            │ │
                                              S42 ← S41            │ │
```

**Minimum viable demo path (GateControl only, ~35h):**
S01 → S02 → S03 → S04 → S05 → S09 → S10 → S11 → S12 → S13 → S14 → S07 → S08 → S15 → S16 → S17 → S18 → S25 → S26 → S27 → S29 → S30 → S36 → S37 → S38 → S40 → S41 → S42

---

## Hard Stop Conditions (from reimplementation checklist)

| Condition | Detection Step | Action |
|-----------|---------------|--------|
| `gate::authorize_extension` signature changed | S03 | Fork world-contracts or redesign |
| `storage_unit::withdraw_item` requires OwnerCap | S03 | Pivot TradePost to escrow pattern |
| AdminACL sponsor inaccessible | S05 | Demo on local devnet only |
| world-contracts deleted or private | S02 | Contact organizers; use cached copy |
| Cross-address buy fails on devnet | S21 | Cut TradePost; submit GateControl only |
| Docker devnet won't start | S04 | Use native `sui start --with-faucet` |

---

## References

- [March 11 Reimplementation Checklist](march-11-reimplementation-checklist.md)
- [Demo Beat Sheet](civilizationcontrol-demo-beat-sheet.md)
- [UX Architecture Spec](../ux/civilizationcontrol-ux-architecture-spec.md)
- [GateControl Feasibility Report](../architecture/gatecontrol-feasibility-report.md)
- [TradePost Cross-Address Validation](../architecture/tradepost-cross-address-ptb-validation.md)
- [ZK GatePass Feasibility Report](../operations/zk-gatepass-feasibility-report.md)
- [Read-Path Architecture Validation](../architecture/read-path-architecture-validation.md)
- [Policy Authoring Model Validation](../architecture/policy-authoring-model-validation.md)
- [Shortlist Viability Validation Report](../operations/shortlist-viability-validation-report.md)
- [Hackathon Rules Digest](../research/hackathon-event-rules-digest.md)
- [In-Game DApp Surface Analysis](../architecture/in-game-dapp-surface.md)
