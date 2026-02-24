# March 11 Reimplementation Checklist

**Retention:** Carry-forward

> **Date:** 2026-02-16 (updated with full gate lifecycle rehearsal evidence; environment model to be confirmed March 11)  
> **Status:** Pre-hackathon carry-forward document — **ALL MODULES VALIDATED ON DEVNET** + **FULL GATE LIFECYCLE REHEARSED**  
> **Source:** Validated patterns from `sui-playground` sandbox  
> **Scope:** CivilizationControl — GateControl + TradePost (core), TribeMint (stretch)  
> **Evidence:** See [validation report](../operations/shortlist-viability-validation-report.md) for module tests; [gate lifecycle runbook](../operations/gate-lifecycle-runbook.md) for complete 13-step gate lifecycle with transaction digests

---

## Purpose

This document captures everything needed to **reimplement CivilizationControl from scratch** in a fresh hackathon repo on March 11. It is a pattern reference and checklist — not code to copy.

**What this is:**
- Validated architectural patterns distilled from world-contracts analysis
- Assumptions that must hold (verify on hackathon day)
- A step-by-step day-1 checklist
- Known pitfalls learned from sandbox testing

**What this is NOT:**
- A code dump — all sandbox code stays in `sui-playground`
- A substitute for reading the world-contracts source — this is a map, not the territory

> **Upstream reference code (2026-02-20 submodule refresh):** `vendor/builder-scaffold/move-contracts/smart_gate/` now contains 3 canonical reference implementations directly relevant to CivilizationControl: `config.move` (ExtensionConfig + AdminCap + XAuth + DF helpers), `tribe_permit.move` (tribe-based gate access), `corpse_gate_bounty.move` (SSU+gate cross-assembly composition). Full TS scripts at `ts-scripts/smart_gate/` and utility library at `ts-scripts/utils/` (config, derive-object-id, proof generation, sponsored tx dual-sign). Builder-documentation `gate/build.md` now provides an end-to-end build guide. New deployment automation scripts at `vendor/world-contracts/scripts/` (deploy-world.sh, seed-world.sh).

---

## What Was Validated

### GateControl — Risk: GREEN

The Smart Gate typed witness extension pattern fully supports composable gate policies. Validated findings:

1. **Extension registration works**: `gate::authorize_extension<Auth>()` stores a `TypeName` (including defining package ID) on the gate. Once set, default `jump()` is blocked — only `jump_with_permit()` works.
2. **Both gates must have the same extension type** authorized for `issue_jump_permit` to succeed. The witness type's `with_defining_ids` includes the package ID, so the same package must be deployed for both gates.
3. **JumpPermit is single-use**: created by the extension, consumed by `jump_with_permit()`, direction-agnostic route hash.
4. **Coin toll is straightforward**: standard `Coin<T>` transfer inside the extension function before issuing the permit. Dramatically simpler than the item-based corpse bounty pattern.
5. **Dynamic field rule composition**: the `extension_examples::config` module proves storing multiple rule types as dynamic fields under a shared config object.
6. **Tribe filtering**: simple `u32` comparison against `character.tribe_id`. Well-tested in existing examples.
7. **Single extension per gate/SSU** (verified in source): The `extension` field is `Option<TypeName>` — only one extension type can be active at a time. `authorize_extension` with a new type replaces the previous via `swap_or_fill`. Extension identity uses `type_name::with_defining_ids<Auth>()`, which includes the defining package ID (stable across upgrades). **Design consequence:** GateControl rules AND any ZK privacy rule MUST live in the SAME extension package and share a single `Auth` witness type. Multiple rule types are composed via dynamic fields under one extension, NOT via multiple extensions on the same gate.
8. **Policy authoring is data-driven, not code-driven** (validated 2026-02-19): The ExtensionConfig + dynamic field pattern enables fully UI-configurable gate policies. CivilizationControl publishes ONE extension package; users configure rules via PTBs that modify dynamic fields on the shared config object. No end user writes or publishes Move code. Per-gate differentiation via gate-ID-keyed compound DF keys. See [policy authoring model validation](../architecture/policy-authoring-model-validation.md) for full analysis.

**Policy Lifecycle (validated model):**
- **Create:** UI constructs PTB calling `set_tribe_rule()`, `set_coin_toll()`, etc. on shared `ExtensionConfig`. Single PTB for multi-rule changes.
- **Apply:** Gate owner calls `authorize_extension<GateAuth>` on both linked gates (OwnerCap borrow/return). Can be same PTB as config if same owner.
- **Update:** Same as Create — single PTB to change any rule parameter. No redeployment.
- **Reuse:** Extension type shared across all enrolled gates. Per-gate config via gate-ID-keyed DFs. "Copy policy" = UI reads Gate A config, writes same values for Gate B.
- **Remove rules:** `remove_rule()` DF calls. Extension itself cannot be removed (no `deauthorize_extension`), only swapped.

### TradePost — Risk: GREEN (downgraded from Yellow)

Cross-address PTB item transfer risk is **mitigated**. The typed witness extension pattern on StorageUnit enables atomic buyer-signed trades without the seller's OwnerCap.

1. **Extension-based SSU access does NOT require OwnerCap**: `withdraw_item<Auth>()` and `deposit_item<Auth>()` only need the `Auth` witness value and shared object references. No sender check, no OwnerCap.
2. **Always accesses main inventory**: extension functions use `storage_unit.owner_cap_id` as the dynamic field key, accessing the owner's inventory — not an ephemeral per-caller inventory.
3. **Existing test proves the pattern**: `test_swap_ammo_for_lens` in `storage_unit_tests.move` validates cross-address extension-mediated inventory operations.
4. **TradePost is simpler than the swap test**: it avoids `deposit_by_owner`/`withdraw_by_owner` entirely — no proximity proof, no ephemeral inventory, no OwnerCap needed in the buy path.
5. **Item has `key + store` abilities**: `transfer::public_transfer(item, buyer_address)` is valid after withdrawal.
6. **Coin payment is trivial**: `Coin<T>` has `key + store`, standard `transfer::public_transfer` to seller.
7. **Multi-signer PTB does NOT exist on Sui**: confirmed that the extension pattern is the correct (and only viable) path for cross-address atomic trades.
8. **deposit_item() now merges quantities (2026-02-20)**: When depositing an item with a `type_id` that already exists in the inventory, quantities are merged automatically (world-contracts commit `09c2ec2`). Volumes must match (`EItemVolumeMismatch` error code 5). Simplifies re-stocking — no need to check for existing items.

### Infrastructure Setup Chain — Risk: GREEN (verbose but mechanical)

The full deployment sequence from world-contracts init to a working jump/trade was mapped:

1. Publish world package → GovernorCap created
2. Create AdminCap, register server address, add sponsor to AdminACL
3. Configure fuel type + energy config
4. Create Characters (with tribe IDs)
5. Anchor NetworkNode → fuel → online
6. Anchor Gates → connect to NWN → online → link (requires distance proof)
7. Authorize extensions on gates/SSUs

### Capability Hierarchy — Risk: GREEN

Three-tier access control is clean and well-documented:
- **GovernorCap** (singleton) → creates AdminCaps, manages server registry + sponsor ACL
- **AdminCap** → anchors/unanchors structures, creates OwnerCaps, creates characters
- **OwnerCap\<T\>** → per-object operations (online, link, authorize_extension)
- OwnerCaps are held by Character objects (transfer-to-object pattern)
- Borrow/return is a hot-potato pattern: `borrow_owner_cap<T>()` → operation → `return_owner_cap()`

---

## Assumptions That Must Hold

Verify these on hackathon day. If any break, reassess the corresponding module.

### Critical Assumptions

| # | Assumption | Source | How to Verify |
|---|-----------|--------|---------------|
| A1 | `gate::authorize_extension<Auth>()` still accepts any custom witness type with `drop` ability | gate.move `authorize_extension` function signature | Publish a test extension, call `authorize_extension` |
| A2 | `gate::issue_jump_permit<Auth>()` is public and callable from external packages | gate.move function visibility | Compile a dependent package that calls it |
| A3 | `storage_unit::withdraw_item<Auth>()` is public and does NOT require OwnerCap | storage_unit.move function signature | Compile + test a buy() flow |
| A4 | `Item` struct has `key, store` abilities (enabling `transfer::public_transfer`) | inventory.move struct definition | Check abilities in Move.toml or source |
| A5 | `jump()` and `jump_with_permit()` still require `admin_acl.verify_sponsor(ctx)` (sponsored tx) | gate.move jump functions | Read source; plan sponsorship setup |
| A6 | Dynamic fields on shared objects work as config stores for extension rules | Sui core behavior | Standard Sui feature — unlikely to change |
| A7 | `Coin<T>` has `key, store` and `transfer::public_transfer` works for payment forwarding | Sui coin module | Standard Sui feature |
| A8 | Single extension type per gate/SSU (`Option<TypeName>`) — no multi-extension support | gate.move, storage_unit.move extension field | Check `extension` field type |
| A9 | Policy authoring is data-driven (dynamic field config) — users never publish Move | Extension examples, builder-scaffold, builder-documentation | **VERIFIED 2026-02-19** — See [policy authoring model validation](../architecture/policy-authoring-model-validation.md) |
| A10 | Per-gate DF keys with compound key structs work | Standard Sui DF capability | Day-1: publish test package with `GateRuleKey { gate_id: ID }` |
| A11 | OwnerCap<Gate> can gate config updates (self-service model) | Design choice, not in examples | Day-1: add `&OwnerCap<Gate>` param to config function |

### Environmental Assumptions

| # | Assumption | How to Verify |
|---|-----------|---------------|
| E1 | `world-contracts` repo has not been restructured or renamed | Check GitHub repo, pull latest |
| E2 | `builder-scaffold` Docker devnet still works with same entrypoint (fallback environment) | `docker compose run --rm sui-local` |
| E3 | Sui CLI supports `--gas-sponsor` flag on `sui client ptb` (NOT `--sponsor`, NOT on `sui client call`) | `sui client ptb --help` |
| E4 | Local devnet genesis creates faucet for funding test accounts | Check container startup logs |
| E5 | **Hackathon test server** is available from March 11 with same world-contracts as Stillness | Connect via provided RPC URL; verify with `sui client active-env` |
| E6 | Test server provides admin-spawnable structures and unlimited currency | Verify with organizer documentation or test server admin tools |
| E7 | Test server world-contracts package IDs are discoverable (pre-published) | Query test server RPC for known package types |

---

## Pattern Catalog

### Pattern 1: Gate Extension with Typed Witness

**What:** Register a custom auth type on a gate to intercept all jumps with custom logic.

**Key types:**
- Custom witness struct: `struct GateAuth has drop {}` — must have `drop`, nothing else
- The witness type's `TypeName` (including defining package ID) is stored on the gate
- Both source and destination gates must authorize the same extension type

**Key functions (from world-contracts):**
- `gate::authorize_extension<Auth>(&mut gate, &owner_cap)` — registers extension
- `gate::issue_jump_permit<Auth>(source, dest, character, Auth{}, expiry, ctx)` — issues permit
- `gate::jump_with_permit(source, dest, character, permit, admin_acl, clock, ctx)` — consumes permit

**Design decisions:**
- Expose a public function (e.g., `gate_auth()`) that creates the witness value — only your module can instantiate it
- Store all rule configuration in a shared config object using dynamic fields (following `extension_examples::config` pattern)
- Permit expiry should be generous (hours/days) to account for transaction delays
- **Single extension constraint:** Each gate supports exactly one `Auth` type (`Option<TypeName>`). All rule types (tribe filter, coin toll, ZK proof) must be dispatched from the same extension module using one shared witness type. This is verified in `gate.move` — the `extension` field stores a single `TypeName` via `swap_or_fill`, not a collection.

**Source files to study:**
- `vendor/world-contracts/contracts/extension_examples/sources/config.move` — shared config + DF helpers
- `vendor/world-contracts/contracts/extension_examples/sources/tribe_permit.move` — tribe filter
- `vendor/world-contracts/contracts/extension_examples/sources/corpse_gate_bounty.move` — item toll

### Pattern 2: Dynamic Field Rule Dispatch

**What:** Store multiple rule types (tribe filter, coin toll, time window) as dynamic fields under a single shared config object. The extension's permit-issuing function checks each applicable rule before issuing the permit.

**Key types:**
- Unique key struct per rule: `struct TribeRuleKey has copy, drop, store {}`
- Value struct per rule: `struct TribeRule has drop, store { tribe_id: u32 }`
- Config object: shared, with `UID` for dynamic fields

**Key functions:**
- `df::add(&mut config.id, TribeRuleKey {}, TribeRule { tribe_id })` — add rule
- `df::borrow<TribeRuleKey, TribeRule>(&config.id, TribeRuleKey {})` — check rule
- `df::exists_(&config.id, TribeRuleKey {})` — check if rule is active

**Design decision:** Check rules sequentially in the permit-issuing function. If a tribe rule exists, verify tribe. If a coin toll exists, verify payment. This makes rules composable without combinatorial explosions.

**Source files to study:**
- `vendor/world-contracts/contracts/extension_examples/sources/config.move` — `set_rule`, `borrow_rule`, `has_rule` helpers

### Pattern 3: Coin Toll for Gate Access

**What:** Require payment in SUI (or a custom `Coin<T>`) to receive a JumpPermit.

**Key flow:**
1. Read toll config from dynamic field on shared GateConfig
2. Assert `coin::value(&payment) >= price`
3. Transfer payment to treasury address via `transfer::public_transfer`
4. Issue JumpPermit via `gate::issue_jump_permit<GateAuth>(...)`

**Design decisions:**
- Treasury address is a field in the toll config (configurable per gate deployment)
- Caller splits the coin in the PTB before calling (`--split-coins gas [amount]`)
- For generic `Coin<T>` support (faction currencies), the function must be generic over T
- For MVP, hardcode to `Coin<SUI>` — add generic support if TribeMint ships

**Why this is easier than item toll:** No StorageUnit dependency, no proximity proof, no OwnerCap borrowing. Pure coin transfer.

### Pattern 4: SSU Extension for Cross-Address Trading (TradePost)

**What:** Seller authorizes a `TradeAuth` witness type on their SSU. The TradePost module uses this witness to withdraw items from the seller's inventory and transfer them to the buyer, atomically.

**Key flow — seller setup:**
1. Seller calls `storage_unit::authorize_extension<TradeAuth>(&mut ssu, &owner_cap)`
2. Seller calls `trade_post::create_listing(ssu, item_type_id, price, ctx)` → creates shared `Listing`

**Key flow — buyer purchase (single PTB, buyer-signed):**
1. `trade_post::buy(ssu, character, listing, payment, ctx)` which internally:
   - Calls `storage_unit::withdraw_item<TradeAuth>(ssu, character, TradeAuth{}, type_id, ctx)` → gets `Item`
   - Calls `transfer::public_transfer(item, ctx.sender())` → item goes to buyer
   - Calls `transfer::public_transfer(payment, listing.seller)` → payment goes to seller
   - Destroys the `Listing`

**Critical insight:** `withdraw_item<Auth>` needs NO OwnerCap, NO sender check, and accesses the MAIN inventory (keyed by `owner_cap_id`). This is the designed cross-address mechanism.

**Design decisions:**
- Listing should be a shared object (enables discovery without off-chain coordination)
- Each SSU can only have ONE extension — a TradePost SSU is a dedicated shop
- Handle overpayment with `coin::split` and return change to buyer
- SSU must be online for trades to execute (status check inside `withdraw_item`)

**Source files to study:**
- `vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move` — `withdraw_item`, `deposit_item`, extension auth
- `vendor/world-contracts/contracts/world/tests/assemblies/storage_unit_tests.move` — `test_swap_ammo_for_lens` (cross-address proof)
- `vendor/world-contracts/contracts/extension_examples/sources/corpse_gate_bounty.move` — similar extension-mediated pattern

### Pattern 5: Infrastructure Deployment Sequence

**What:** The full chain from fresh devnet to working gates and SSUs.

**Sequence (each step depends on the previous):**
1. **Publish world package** → receive `GovernorCap`
2. **Create AdminCap** → `access::create_admin_cap(governor_cap)` (module is `world::access`, NOT `world::access_control`)
3. **Register server address** → `server::register(server_registry, admin_cap, server_addr)`
4. **Add sponsor to ACL** → `access::add_access(admin_acl, admin_cap, sponsor_addr)` — **must be a different address than the sender for sponsored txs**
5. **Configure fuel** → `fuel::set_fuel_efficiency(fuel_config, admin_cap, type_id, efficiency)`
6. **Configure energy** → `energy::set_energy_config(energy_config, admin_cap, gate_type_id, energy_amount)`
7. **Set gate max distance** → `gate::set_max_distance(gate_config, admin_cap, type_id, max_distance)`
8. **Create Characters** → `character::create_character(...)` + `share_character()`
9. **Anchor NetworkNode** → `network_node::anchor(...)` + `share_network_node()`
10. **Fuel NWN + online** → `deposit_fuel()` + `online()`
11. **Anchor Gates** → `gate::anchor(...)` + `share_gate()` (repeat for each gate)
12. **Online Gates** → `gate::online(...)` (needs energy from NWN)
13. **Link Gates** → `gate::link_gates(...)` (needs server-signed distance proof)
14. **Anchor SSUs** → `storage_unit::anchor(...)` + `share_storage_unit()`
15. **Online SSUs** → `storage_unit::online(...)`
16. **Authorize extensions** → on both gates and trade SSUs

**Self-signed proofs (devnet only):** Generate an Ed25519 keypair, register its derived address as "server address" in step 3, then sign distance proofs with it for `link_gates()`. **Signature format:** `digest = blake2b256(0x030000 || bcs_message_bytes)`, Ed25519-sign the digest. **Proof format:** `[0x00 flag] + [64-byte sig] + [32-byte pubkey]` = 97 bytes. `verify_distance` does NOT check deadline (unlike `verify_proximity`). `vector<u8>` args in PTB must use `"vector[0xHH,0xHH,...]"` format. Full working proof generator at `sandbox/validation/generate_distance_proof.mjs` (ESM, requires `@noble/hashes@2`). See [gate lifecycle runbook](../operations/gate-lifecycle-runbook.md) Step 9.

### Pattern 6: OwnerCap Borrow/Return Hot-Potato

**What:** Every gate/SSU owner operation requires borrowing the OwnerCap from the Character object, using it, then returning it — all in the same transaction.

**Key flow (in a single PTB):**
1. `character::borrow_owner_cap<Gate>(character, receiving_ticket)` → `(OwnerCap<Gate>, ReturnReceipt)`
2. Use the OwnerCap: `gate::online(&mut gate, &mut nwn, &energy_config, &owner_cap)`
3. `character::return_owner_cap(character, owner_cap, receipt)` — must happen or tx aborts

**Critical:** This is a hot-potato pattern — the `ReturnReceipt` has no `drop` ability. If you forget to return the OwnerCap, the transaction aborts. PTB composition handles this naturally.

### Pattern 7: Sponsored Transactions

**What:** `jump()` and `jump_with_permit()` require the transaction to be sponsored by an address in `AdminACL`.

**On local devnet / hackathon test server:** Register a second address as sponsor in `AdminACL`. Use `--gas-sponsor "@0xADDR"` flag on PTB. **Critical:** Self-sponsorship does NOT work — `ctx.sponsor()` returns `None` when sender == gas payer. Must use a *different* address as sponsor. The `sui client ptb` command is required (not `sui client call`) for sponsored transactions. On the hackathon test server, AdminACL access depends on organizer configuration — verify early.

**Rehearsal evidence:** Validated with PLAYER_A as sponsor, ADMIN as sender. See [gate lifecycle runbook](../operations/gate-lifecycle-runbook.md) Steps 6b, 13.

**On Stillness (live server):** The game server sponsors player transactions. Extensions add rules on top of this — they don't bypass sponsorship.

---

## Day-1 Checklist (Ordered Steps)

### Hour 0: Repository Setup (30 min)

- [ ] Confirm hackathon has started (UTC timestamp check)
- [ ] Create fresh GitHub repo (no prior commits)
- [ ] `git init` + first commit with only intended template files
- [ ] Add submodules:
  ```
  git submodule add https://github.com/evefrontier/builder-scaffold.git vendor/builder-scaffold
  git submodule add https://github.com/evefrontier/world-contracts.git vendor/world-contracts
  ```
- [ ] Verify commit timestamp is on or after March 11
- [ ] Push to GitHub
- [ ] Register on Deepsurge (if not done)

### Hour 0.5: Environment Verification (30 min)

**Primary target: Hackathon Test Server** (available from March 11). Local devnet is a fallback.

- [ ] Pull latest `world-contracts` — check for API changes since Feb 16
- [ ] Verify assumptions A1–A4 by reading key function signatures:
  - `gate.move`: `authorize_extension`, `issue_jump_permit`, `jump_with_permit`
  - `storage_unit.move`: `withdraw_item`, `deposit_item`, `authorize_extension`
  - `inventory.move`: `Item` struct abilities
- [ ] **Connect to hackathon test server:** `sui client new-env --alias testserver --rpc <RPC_URL>` → `sui client switch --env testserver`
- [ ] Verify test server connection: `sui client active-env` → "testserver"
- [ ] Check test server for pre-published world-contracts (query known types)
- [ ] **Fallback:** Start local devnet: `cd vendor/builder-scaffold/docker && docker compose run --rm sui-local`
- [ ] If using local devnet: Publish world package: `sui client publish --gas-budget 500000000`
- [ ] Record all shared object IDs (GovernorCap, AdminACL, ObjectRegistry, etc.)

### Hour 1: GateControl Module (2–3 hours)

- [ ] Create Move package: `contracts/gatecontrol/`
- [ ] Define `GateAuth has drop {}` witness struct
- [ ] Define `GateControlConfig` shared object with UID for dynamic fields
- [ ] Implement rule key/value structs:
  - `TribeRuleKey` / `TribeRule { tribe_id: u32 }`
  - `CoinTollKey` / `CoinTollRule { price: u64, treasury: address }`
- [ ] Implement `request_jump_permit()`:
  1. Check tribe rule (if exists) → compare character.tribe_id
  2. Check coin toll (if exists) → verify payment, transfer to treasury
  3. Call `gate::issue_jump_permit<GateAuth>(...)`
- [ ] Implement admin functions: `set_tribe_rule()`, `set_coin_toll()`, `remove_rule()`
- [ ] Write Move unit tests (`#[test]` functions)
- [ ] `sui move build` + `sui move test`

### Hour 3: TradePost Module (2–3 hours)

- [ ] Create Move package: `contracts/tradepost/`
- [ ] Define `TradeAuth has drop {}` witness struct
- [ ] Define `Listing` struct: `{ id, storage_unit_id, seller, item_type_id, price }`
- [ ] Implement `create_listing()` — seller creates, listing is shared
- [ ] Implement `buy()`:
  1. Verify listing matches SSU
  2. Verify payment >= price
  3. `storage_unit::withdraw_item<TradeAuth>(ssu, character, TradeAuth{}, type_id, ctx)`
  4. `transfer::public_transfer(item, ctx.sender())`
  5. Handle payment: exact or with change
  6. `transfer::public_transfer(payment, listing.seller)`
  7. Destroy listing
- [ ] Implement `cancel_listing()` — seller only
- [ ] Write Move unit tests
- [ ] `sui move build` + `sui move test`

### Hour 5: Integration on Local Devnet / Test Server (2 hours)

- [ ] Run infrastructure setup chain (Pattern 5) — on test server if admin tools available, otherwise local devnet
- [ ] Publish GateControl extension package
- [ ] Authorize extension on both test gates
- [ ] Test: correct tribe → permit issued → jump succeeds → JumpEvent emitted
- [ ] Test: wrong tribe → transaction aborts
- [ ] Test: coin toll → payment transferred → permit issued
- [ ] Publish TradePost extension package
- [ ] Authorize extension on test SSU
- [ ] Mint test items into SSU
- [ ] Create listing as seller
- [ ] Buy as different address → Item transferred, payment received
- [ ] Capture all transaction digests

### Hour 7: Event Emission + Custom Events (1 hour)

- [ ] Add custom events to GateControl: `TribeCheckPassedEvent`, `TollPaidEvent`
- [ ] Add custom events to TradePost: `ListingCreatedEvent`, `ItemSoldEvent`, `ListingCancelledEvent`
- [ ] Verify events appear in `sui client events --package <pkg>`

### Hour 8+: Dashboard / Web UI

- [ ] Set up frontend project (Vite + React + TypeScript)
- [ ] Install `@mysten/sui` SDK
- [ ] Gate policy builder: toggle tribe rule, set toll price
- [ ] TradePost browser: list items, one-click buy
- [ ] Event feed: subscribe to JumpEvents + ItemSoldEvents

---

## Known Pitfalls

### Move / On-Chain

| Pitfall | What Happens | How to Avoid |
|---------|-------------|--------------|
| **Forget `return_owner_cap`** | Transaction aborts (hot-potato) | Always pair `borrow_owner_cap` with `return_owner_cap` in the same PTB |
| **Redeploy extension package** | TypeName changes (includes package ID) — existing gate extensions break | Plan for single deployment. If you must redeploy, re-authorize extensions on all gates. |
| **Missing sponsor setup** | All jumps fail with `verify_sponsor` error | Add your address to `AdminACL` via `add_sponsor_to_acl` before testing jumps |
| **SSU offline** | `withdraw_item` / `deposit_item` abort with status check | Ensure SSU is online (connected to fueled NetworkNode) |
| **Wrong `Character` reference in events** | Misleading event data | Pass the actual buyer's character to `withdraw_item` for meaningful events |
| **Single extension per object** | Can't have GateControl AND a different extension on the same gate | This is by design. Each gate/SSU gets one extension type. |
| **Distance proof for `link_gates`** | No game server to sign proofs on local devnet | Self-sign: register local keypair as server address, sign your own proof (BCS format, blake2b+ed25519). Use `generate_distance_proof.mjs` as reference. On hackathon test server, check if admin tools provide distance proofs. |
| **NetworkNode dependency chain** | ~6 sequential admin operations before gates can go online | Script the full setup chain. Consider a single PTB with all setup calls. |
| **Coin splitting in PTB** | Buyer must split exact payment from gas coin | Use `--split-coins gas [amount]` in CLI, or `txb.splitCoins()` in SDK |
| **Item leaves SSU as standalone object** | `withdraw_item` creates a freestanding `Item` — not inside any inventory | This is expected for TradePost. Buyer can later deposit into their own SSU. |

### Environment

| Pitfall | How to Avoid |
|---------|--------------|
| **Chain ID mismatch after fresh genesis** | Always use `--build-env local` flag for build/publish on local devnet. Extension packages need `[environments]` section in Move.toml (`local = "<chain-id>"`) AND a `Pub.local.toml` referencing already-published World dependency. On hackathon test server, use the server's chain ID instead. |
| **Port 9000 conflict** | Don't run ZK PoC native devnet and Docker devnet simultaneously |
| **Docker volume stale state** | If devnet behaves oddly, delete `workspace-data/` and `docker volume rm docker_sui-keystore` |
| **world-contracts API changed** | Pull latest on hackathon day, verify assumptions A1–A4 before writing code |
| **Test server unavailable** | Fall back to local devnet. All patterns are validated on local devnet. Evidence quality equivalent for demo purposes. |

---

## DO NOT COPY — Sandbox Code Notice

**⚠️ All code in `sui-playground` is sandbox exploration code. Do NOT copy it into the hackathon repo.**

Reasons:
1. **Hackathon rules require original work** developed on or after the start date. Copying pre-existing code violates Section 5.
2. **Git history would reveal pre-hackathon timestamps** if sandbox code is transplanted.
3. **Sandbox code was written for exploration**, not production quality. Reimplementing from patterns produces better code.
4. **The patterns documented here are sufficient** to rewrite each module in 2–3 hours with LLM assistance.

**What you CAN carry forward:**
- This document (patterns, checklists, pitfalls)
- The `docs/core/` documents (workspace abstract, Copilot memory guidelines)
- The `.github/copilot-instructions.md` template (workflow guardrails)
- Knowledge of world-contracts architecture (it's open-source, not your code)

**What you CANNOT carry forward:**
- Any `.move` files from `sui-playground`
- Any TypeScript/React code from `sui-playground`
- Test scripts, deployment scripts, or helper utilities authored in this sandbox
- Working Memory documents with implementation details

---

## References

### World-Contracts Source (Canonical)

| Module | Path | Key Functions |
|--------|------|---------------|
| Gate | `vendor/world-contracts/contracts/world/sources/assemblies/gate.move` | `authorize_extension`, `issue_jump_permit`, `jump_with_permit`, `jump`, `link_gates`, `online` |
| Storage Unit | `vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move` | `authorize_extension`, `withdraw_item`, `deposit_item`, `game_item_to_chain_inventory` |
| Network Node | `vendor/world-contracts/contracts/world/sources/network_node/network_node.move` | `anchor`, `online`, `deposit_fuel`, `connect_assemblies` |
| Access Control | `vendor/world-contracts/contracts/world/sources/access/access_control.move` | Module name is `world::access` (NOT `world::access_control`). Functions: `create_admin_cap`, `add_access` (sponsors), `verify_sponsor` |
| Character | `vendor/world-contracts/contracts/world/sources/character/character.move` | `create_character`, `borrow_owner_cap`, `return_owner_cap` |
| Inventory | `vendor/world-contracts/contracts/world/sources/primitives/inventory.move` | `withdraw_item`, `deposit_item`, `Item` struct |
| Sig Verify | `vendor/world-contracts/contracts/world/sources/crypto/sig_verify.move` | `verify_signature`, `derive_address_from_public_key` |

### Extension Examples (Pattern Templates)

| Module | Path | Pattern Demonstrated |
|--------|------|---------------------|
| Config | `vendor/world-contracts/contracts/extension_examples/sources/config.move` | Shared config + dynamic field helpers |
| Gate (tribe) | `vendor/world-contracts/contracts/extension_examples/sources/gate.move` | Simple tribe filter |
| Tribe Permit | `vendor/world-contracts/contracts/extension_examples/sources/tribe_permit.move` | Tribe permit with shared config |
| Corpse Bounty | `vendor/world-contracts/contracts/extension_examples/sources/corpse_gate_bounty.move` | Item toll + SSU interaction |

### Tests (Validation Evidence)

| Test | Path | What It Proves |
|------|------|---------------|
| Gate tests | `vendor/world-contracts/contracts/world/tests/assemblies/gate_tests.move` | Full gate lifecycle + extension pattern |
| SSU tests | `vendor/world-contracts/contracts/world/tests/assemblies/storage_unit_tests.move` | Cross-address extension access (`test_swap_ammo_for_lens`) |

### Official Documentation

| Resource | URL | What to Consult |
|----------|-----|-----------------|
| EVE Frontier Builder Docs | https://docs.evefrontier.com/ | Sponsored tx pattern, smart assembly architecture, extension overview |
| Sui Documentation | https://docs.sui.io/ | Object model, PTB composition, Coin standard, dynamic fields, events |
| Sui LLMs index | https://docs.sui.io/llms.txt | Machine-readable page index for targeted lookups |

### Internal Reference Docs

| Document | Path | Purpose |
|----------|------|---------|
| Strategy memo | `docs/strategy/civilizationcontrol-strategy-memo.md` | Decision rationale: why 2 core + 1 stretch |
| GateControl validation | `docs/architecture/gatecontrol-feasibility-report.md` | Full gate architecture analysis + toll options |
| TradePost validation | `docs/architecture/tradepost-cross-address-ptb-validation.md` | Cross-address proof + SSU extension analysis |
| Capabilities deep dive | `docs/architecture/sui-playground-capabilities.md` | Full devnet capabilities + experiment list |
| Hackathon rules digest | `docs/research/hackathon-event-rules-digest.md` | Eligibility, judging, submission requirements |
| Bootstrap checklist | `docs/operations/hackathon-bootstrap-checklist.md` | Repo initialization steps |

---

## Hard Stop Conditions

| Condition | Detection | Action |
|-----------|----------|--------|
| `gate::authorize_extension` no longer public or signature changed | Assumption A1 fails on environment verification | Fork world-contracts with minimal fix, or redesign GateControl to work without extension customization |
| `storage_unit::withdraw_item` now requires OwnerCap | Assumption A3 fails | Pivot to escrow pattern (Option B in TradePost validation doc) |
| world-contracts repo deleted or made private | Submodule add fails | Contact organizers; use cached copy from builder-scaffold |
| TradePost cross-address buy fails on devnet | Integration test (Hour 5) fails | Pivot TradePost to stretch module; submit GateControl as solo entry (Strategy A from strategy memo) |
| Docker devnet won't start | Environment verification fails | Use native `sui start --with-faucet` instead of Docker |
| Hackathon test server unavailable on Day 1 | Cannot connect via provided RPC URL | Fall back to local devnet; switch to test server when available |

---

## TribeMint (Stretch Module — Build Only If Core Is Stable)

If GateControl + TradePost are stable by end of Day 4:

1. Create `Coin<TRIBE_TOKEN>` using Sui's one-time witness pattern (`OTW`)
2. `TreasuryCap` held by tribe governor (admin)
3. Mint initial supply to tribe members
4. Modify GateControl coin toll to accept `Coin<TRIBE_TOKEN>` (generic `Coin<T>` variant)
5. Modify TradePost to accept `Coin<TRIBE_TOKEN>` as payment
6. Demo moment: buyer pays faction currency at TradePost for an item — same currency accepted as gate toll

**If TribeMint cannot ship cleanly, omit it.** The two-module system (GateControl + TradePost) scores 8.42 weighted without it. Adding a buggy third module hurts more than helps.
