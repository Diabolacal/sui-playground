# EVE Frontier Builder Documentation Reference Map

**Retention:** Prep-only

> **Last updated:** 2026-03-11 (submodule refresh: 9222d42/3c65b22/2aed50b → cf0f3ab/a4fb8b0/8eb197e; evevault 30f74ef→a667394/v0.0.5)
> **Source:** https://docs.evefrontier.com/
> **Internal review by:** AI agent (initial mapping; refreshed 2026-03-03)

## Purpose

This document maps official EVE Frontier GitBook builder documentation to internal SUI Playground capabilities and defines when agents should consult it. It is a **structured reference index only** — no external content is mirrored or duplicated here.

The official docs are actively being rewritten for the Sui blockchain transition. Many pages contain `//TODO` placeholders. Code in `vendor/world-contracts` is canonical; GitBook is explanatory.

> **Local reading source:** `vendor/builder-documentation` (submodule added 2026-02-18, updated 2026-03-11 — commit cf0f3ab) contains the GitBook source markdown. Read locally for content; cite the public GitBook URLs in documentation and code comments.

---

## Site Structure Overview

The official docs (`https://docs.evefrontier.com/`) are organized into these top-level sections. A machine-readable index is available at `https://docs.evefrontier.com/llms.txt`.

| Section | Base URL Path | Pages | Status |
|---------|--------------|-------|--------|
| Welcome | `/welcome` | 5 pages | Mostly complete |
| Tools | `/tools` | 4 pages | `dapp-kit.md`, `efctl.md`, `debugging.md`, `interfacing-with-the-eve-frontier-world.md` moved here |
| Quickstart | `/quickstart` | 1 page | `environment-setup.md` moved here |
| Smart Contracts | `/smart-contracts` | 4 pages | Substantive content (Object Model, Ownership Model now populated); AdminCap → AdminACL rename reflected; new `move-patterns-in-frontier.md` |
| Smart Assemblies | `/smart-assemblies` | 7+ pages (Gate, SSU, Turret, Smart Character, Network Node, Modding intro) | All assembly types documented; Turret docs fully populated; Gate/SSU build pages expanded |
| dApps | `/dapps` | 4 pages + dapp-kit | dApp sub-pages still TODO; `@evefrontier/dapp-kit` SDK now populated |
| EVE Vault | `/eve-vault` | 4 pages | Introduction done; `wallets-and-identity.md` moved here; Browser Extension URL updated; GAS Faucet page deleted |
| Troubleshooting | `/troubleshooting` | 2 pages | `player.md` deleted; `builder.md` and `wallet.md` remain |
| Contributing | `/contributing` | 2 pages | Complete; **repo now public for contributions** |

---

## Relevant Sections (Structured List)

### Why Build on EVE Frontier?

- **URL:** https://docs.evefrontier.com/welcome
- **Last updated:** ~3 days ago (as of 2026-02-15)
- **Summary:** High-level overview of the builder value proposition. Explains Smart Assemblies as programmable structures, the open economic sandbox, World Contracts composability, and the Sui integration rationale.
- **Why it matters for us:** Sets context for what "building" means in EVE Frontier — not cosmetic but strategic infrastructure with programmable logic.
- **Overlaps with:**
  - `docs/architecture/sui-playground-capabilities.md` §1 (mental model)
- **Notable clarifications:** Confirms that World Contracts extend to characters, items, killmails — not just assemblies.

### Smart Infrastructure

- **URL:** https://docs.evefrontier.com/smart-assemblies
- **Last updated:** ~3 days ago
- **Summary:** Defines Smart Assemblies as programmable, player-built on-chain structures. Lists the three current types (Storage Unit, Gate, Turret). Explains that assemblies are built with Move on Sui and can be extended by builders with custom logic.
- **Why it matters for us:** Confirms the assembly taxonomy and that builder extensions are the primary moddability mechanism.
- **Overlaps with:**
  - `vendor/world-contracts/contracts/world/sources/assemblies/` (all three assembly modules)
  - `vendor/builder-scaffold/move-contracts/` (scaffold templates)
  - `docs/architecture/sui-playground-capabilities.md` §4 (structure deep dive)
- **Notable clarifications:** Lists future expansion potential beyond the three current types. Confirms assemblies use Sui shared objects for concurrent access.

### Constraints

- **URL:** https://docs.evefrontier.com/welcome/constraints (rendered at `/smart-assemblies` context)
- **Last updated:** ~3 days ago
- **Summary:** Documents technical and gameplay constraints: gas costs, Sui per-transaction limits (250KB object size, 32 struct fields, 1024 dynamic fields per tx), Move package immutability with upgrade via UpgradeCap, game physics location binding, and permission models.
- **Why it matters for us:** Critical for avoiding runtime errors. Sui-specific limits (object size, dynamic field count) are not documented in our capabilities doc but directly affect contract design.
- **Overlaps with:**
  - Sui protocol documentation (external)
  - `docs/architecture/sui-playground-capabilities.md` §3 (limitations)
- **Notable clarifications:** Explicit mention of 250KB object max size and 1024 dynamic fields per transaction — these are hard limits that affect inventory design and large-state patterns. Also: Move structs max 32 fields.

### Sui & Move Fundamentals

- **URL:** https://docs.evefrontier.com/welcome/sui-and-move-fundamentals (rendered via navigation)
- **Last updated:** ~3 days ago
- **Summary:** Primer on Sui (object-centric model, low latency, parallel execution) and Move (resource-oriented, modules/scripts, strong typing, upgradeable). Explains how Frontier uses Sui for assets-as-objects, ownership, and on-chain game logic.
- **Why it matters for us:** Good onboarding reference for operators unfamiliar with Sui/Move. Links to official Sui docs for deeper learning.
- **Overlaps with:**
  - Sui official docs (`docs.sui.io`)
- **Notable clarifications:** None beyond what Sui docs provide. Useful as a curated entry point.

### Wallets & Identity

- **URL:** https://docs.evefrontier.com/welcome/wallets-and-identity
- **Last updated:** ~3 days ago
- **Summary:** Describes EVE Vault as the official wallet (web + Chrome extension) using zkLogin for seedless OAuth-based authentication. Explains the identity model: wallet = passport for both in-game and dApp interactions. Single sign-on via extension approval.
- **Why it matters for us:** Explains the production authentication flow that `vendor/evevault` implements. Understanding zkLogin is essential for any dApp that needs player identity.
- **Overlaps with:**
  - `vendor/evevault/` (implementation)
  - `docs/architecture/sui-playground-capabilities.md` §5 (evevault analysis)
- **Notable clarifications:** Confirms zkLogin means no seed phrases — OAuth provider (Google, Apple) is the identity source. Also mentions FusionAuth as the EVE Frontier OAuth provider.

### Environment Setup

- **URL:** https://docs.evefrontier.com/tools/environment-setup
- **Last updated:** ~3 days ago
- **Summary:** Setup guide with two paths: Docker (recommended, any OS) using `builder-scaffold`, or manual installation (Windows/Linux/macOS) using `suiup` for Sui CLI. Includes Node.js/pnpm for TypeScript SDK interaction.
- **Why it matters for us:** The Docker path references `builder-scaffold` — our `vendor/builder-scaffold/docker/` setup. The manual path documents `suiup` installation which is useful for native-only workflows.
- **Overlaps with:**
  - `vendor/builder-scaffold/docker/` (Docker setup)
  - `docs/architecture/sui-playground.md` (our quickstart)
- **Notable clarifications:** References a ~~`build` branch of builder-scaffold and a `localnet-setup/docker` directory~~ **Fixed (2026-02-20):** Clone command no longer references `-b build` branch. Docker path corrected to `docker`. `suiup` bash install script documented for Windows (Git Bash). Node.js/pnpm for TypeScript SDK interaction.

### GAS Faucet

- **URL:** https://docs.evefrontier.com/tools/gas-faucet
- **Last updated:** ~4 days ago
- **Summary:** Placeholder page (`//TODO`). No content yet.
- **Why it matters for us:** Our local devnet auto-funds from faucet; testnet faucet details may be documented here when completed.
- **Notable clarifications:** None — page is empty.

### Introduction to Smart Contracts

- **URL:** https://docs.evefrontier.com/smart-contracts/introduction-to-smart-contracts
- **Last updated:** ~3 days ago
- **Summary:** Explains what smart contracts are in the EVE Frontier context. Covers Move on Sui, deterministic execution, modular design. Details access control patterns: function visibility (`public`, `public(package)`, `public(entry)`), capability-based access (`OwnerCap`, `AdminACL`, `JumpPermit`), typed witness pattern, `Publisher` object, and `TxContext` usage. **Updated 2026-02-20:** `AdminCap` → `AdminACL` rename reflected; `Publisher` object now documented.
- **Why it matters for us:** The access control patterns section is essential reading before writing extensions. Explains the capability pattern, hot-potato pattern, and shared objects — all used extensively in world-contracts.
- **Overlaps with:**
  - `vendor/world-contracts/contracts/world/sources/access/access_control.move`
  - `docs/architecture/sui-playground-capabilities.md` §4.9 (access control model)
- **Notable clarifications:** Links to Move Book for capability and witness patterns. Explicitly documents that shared objects use Sui's built-in versioning for concurrent updates. **Updated 2026-02-28:** Move docs URL updated from `/concepts/move` to `/concepts/sui-move-concepts`.

### EVE Frontier World Explainer

- **URL:** https://docs.evefrontier.com/smart-contracts/eve-frontier-world-explainer
- **Last updated:** ~3 days ago
- **Summary:** The most architecturally important page. Documents the three-layer architecture (Primitives → Assemblies → Extensions), explains each layer's role, details the typed witness extension pattern with code examples, covers location privacy (hashed coordinates + proximity proofs), and outlines the security model (Admin/Owner/Extension operations).
- **Why it matters for us:** This is the authoritative architectural explanation of how world-contracts is designed. The three-layer diagram and extension registration flow are essential context for writing any builder extension.
- **Overlaps with:**
  - `vendor/world-contracts/docs/architechture.md` (source-level ADR)
  - `vendor/world-contracts/contracts/world/` (all modules)
  - `docs/architecture/sui-playground-capabilities.md` §4 (structure capabilities)
- **Notable clarifications:**
  - Primitives expose `public(package)` functions — players cannot call them directly; only assemblies use them internally.
  - Extension registration is dynamic — no redeployment of assemblies needed.
  - Privacy model: hashed locations on-chain, proximity verification via server proofs (with ZK as future alternative).
  - **Updated 2026-02-20:** Security model language now uses `AdminACL` ("operations require the transaction to be sponsored by an authorised server") instead of `AdminCap`.

### Interfacing with the EVE Frontier World

- **URL:** https://docs.evefrontier.com/smart-contracts/interfacing-with-the-eve-frontier-world
- **Last updated:** ~3 days ago
- **Summary:** Documents write and read paths for chain interaction. Write path: Sui TypeScript SDK with transaction building, `borrow_owner_cap` pattern, and sponsored transactions (player signs intent, sponsor pays gas). Read path: GraphQL (preferred), gRPC (for throughput), and event subscriptions. **Updated 2026-02-20:** JSON-RPC section removed entirely (deprecated). `SuiClient` paragraph added for read operations. TS SDK link updated to `sdk.mystenlabs.com/typescript`.
- **Why it matters for us:** The sponsored transaction pattern and `borrow_owner_cap` hot-potato flow are critical for any chain interaction. The code examples show the exact SDK calls needed. Also documents the deprecation of JSON-RPC in favor of GraphQL/gRPC.
- **Overlaps with:**
  - `vendor/world-contracts/ts-scripts/` (TypeScript examples)
  - `docs/architecture/sui-playground-capabilities.md` §4.1, §4.2 (operation tables)
- **Notable clarifications:**
  - Sponsored transactions: `tx.setSender(playerAddress)` + `tx.setGasOwner(adminAddress)` — sponsor must be in `AdminACL`.
  - `borrow_owner_cap` / `return_owner_cap` is a hot-potato pattern — cap must be returned in the same transaction.
  - **JSON-RPC is fully removed from docs (not just deprecated).** New integrations should use GraphQL, gRPC, or `SuiJsonRpcClient` (SDK v2; replaces the deprecated `SuiClient` from `@mysten/sui/client`).

### Smart Storage Unit

- **URL:** https://docs.evefrontier.com/smart-assemblies/storage-unit
- **Last updated:** ~3 days ago
- **Summary:** Introduction to SSU as a Move smart contract object. Explains core design, developer/player interaction patterns, and references the world-contracts repo for practical examples. Now 126 lines with substantive content (previously had `//TODO` prerequisites section — now populated).
- **Why it matters for us:** Directly maps to `vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move` and the scaffold template at `vendor/builder-scaffold/move-contracts/storage_unit_extension/` *(renamed from `storage_unit/` in scaffold v3c65b22, 2026-03-10)*.
- **Overlaps with:**
  - `vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move` (796 lines)
  - `docs/architecture/sui-playground-capabilities.md` §4.2
- **Notable clarifications:** Build page (`/gate/build`) exists but is still a stub (header only). Page structure changed from Configure/Deploy to single Build page. **Updated 2026-02-20:** Docs now show `deposit_by_owner`/`withdraw_by_owner` taking `AdminACL` instead of proximity proof (temporarily; docs say proximity proof returns "once a location service is available"). ~~**Code-docs discrepancy:** world-contracts code still has proximity_proof in these functions.~~ **Updated 2026-02-28:** Discrepancy resolved — world-contracts code now matches docs. `withdraw_by_owner` takes `admin_acl: &AdminACL` and calls `admin_acl.verify_sponsor(ctx)`. Proximity proof removed from all owner-path SSU functions. Our extension path (deposit_item/withdraw_item<Auth>) is unaffected. **Updated 2026-03-03 (v0.0.15):** AdminACL REMOVED from `deposit_by_owner` and `withdraw_by_owner` — now just requires OwnerCap + sender == character_address. Three access modes documented: extension-based (main inventory), extension-to-owned (`deposit_to_owned<Auth>`), owner-direct (owned inventory). New `deposit_to_owned<Auth>` enables extensions to push items into any player's owned inventory. `withdraw_item<Auth>` now takes `quantity: u32` + `ctx` params. Items have `parent_id` for deposit validation. **Updated 2026-03-09 (v0.0.16):** `withdraw_item<Auth>` now also requires SSU to be online (`ENotOnline` check added). **Updated 2026-03-11 (v0.0.18):** New **open inventory** system: `deposit_to_open_inventory<Auth>` / `withdraw_from_open_inventory<Auth>` — contract-controlled inventory slot not tied to any player. Created lazily or at anchor time. Key derived deterministically via `blake2b256`. `inventory_keys` now starts with 2 entries at anchor (main + open). New `freeze_extension_config` / `is_extension_frozen` / `is_extension_configured` functions (anti-rugpull mechanism, shared `extension_freeze.move` module). New errors: `EExtensionConfigFrozen` (13), `EExtensionNotConfigured` (14), `EOpenStorageNotInitialized` (15).

### Smart Storage Unit — Build

- **URL:** https://docs.evefrontier.com/smart-assemblies/storage-unit/build (restructured from Configure/Deploy to single Build page)
- **Last updated:** ~4–9 days ago
- **Summary:** Stub page (header only, no content). Replaces previous Configure and Deploy sub-pages.
- **Why it matters for us:** When completed, will document the step-by-step workflow for building SSU extensions. Until then, our capabilities doc §4.2 and `world-contracts/ts-scripts/storage-unit/` are the only references.

### Smart Gate

- **URL:** https://docs.evefrontier.com/smart-assemblies/gate
- **Last updated:** ~3 days ago
- **Summary:** Substantive gate documentation (120 lines). Covers default vs custom behavior, JumpPermit struct, Move function signatures ("Gate API" section with `AdminACL` as required param for `jump_with_permit`), and includes scaffold links. Significantly expanded from initial intro page.
- **Why it matters for us:** Directly maps to our most complex structure type. The extension pattern (authorize → issue permits → gate jumps) is the primary builder moddability surface. **AdminCap → AdminACL rename reflected in docs.** Inline TypeScript examples removed; scaffold is now the reference.
- **Overlaps with:**
  - `vendor/world-contracts/contracts/world/sources/assemblies/gate.move` (718 lines)
  - `vendor/world-contracts/contracts/extension_examples/` (3 extension examples)
  - `vendor/builder-scaffold/move-contracts/smart_gate_extension/` (canonical gate extension examples — renamed from `smart_gate/` in scaffold v3c65b22, 2026-03-10)
  - `docs/architecture/sui-playground-capabilities.md` §4.1
- **Notable clarifications:** **Build page (`/gate/build`) is now populated** — full end-to-end build guide covering scaffold walkthrough (config.move, tribe_permit.move, corpse_gate_bounty.move), publish, configure rules, authorize extension, issue permit, jump with permit. Includes a minimal toll gate example. Scaffold links now point to `main` branch. **Updated 2026-03-11 (v0.0.18):** New `freeze_extension_config` / `is_extension_frozen` / `is_extension_configured` / `extension_type` functions. `authorize_extension` now blocked after freeze (`EExtensionConfigFrozen`). Anti-rugpull mechanism shared across gate/turret/SSU via `extension_freeze.move`.

### Smart Turret

- **URL:** https://docs.evefrontier.com/smart-assemblies/turret
- **Last updated:** ~4 days ago (docs page may still be TODO)
- **Summary:** ~~Placeholder page (`//TODO`). No content yet.~~ **Updated 2026-03-02:** world-contracts v0.0.14 now includes a full `turret.move` module (677 lines) + 1097-line test suite + extension example + TS scripts. Turret is a programmable structure with target-priority logic, typed witness extension pattern (same as gate/SSU), BCS-serialized `TargetCandidate` / `ReturnTargetPriorityList` protocol, `OnlineReceipt` hot-potato, and network node energy management.
- **Why it matters for us:** Turrets are now a **real and fully implemented assembly type**. Uses the same extension pattern as gates (typed witness `authorize_extension<Auth>`, `swap_or_fill`). The `get_target_priority_list` function is the builder-extensible entry point — game calls it with BCS-encoded target candidates, extension returns priority weights. Turret extensions MUST consume the `OnlineReceipt` hot-potato via `destroy_online_receipt(receipt, auth_witness)`.
- **Notable clarifications:** Turret extension in `extension_examples/sources/turret.move` replaces the old gate extension example (gate.move was deleted from extension_examples). Default targeting rules: owner always excluded (by character_id match), same-tribe non-aggressors excluded, `STARTED_ATTACK` adds +10000 weight, `ENTERED` adds +1000 weight. **Updated 2026-03-09 (v0.0.17):** Turret anchor now initializes metadata (empty strings) instead of `option::none()`. **Updated 2026-03-11 (v0.0.18):** `freeze_extension_config` / `is_extension_frozen` added (same anti-rugpull pattern as gate/SSU). `authorize_extension` blocked after freeze. `unanchor`/`unanchor_orphan` clean up frozen marker.

### dApps Quick Start / Connecting / Customizing

- **URL:** https://docs.evefrontier.com/dapps/dapps-quick-start (+ 3 sub-pages)
- **Last updated:** ~4+ days ago
- **Summary:** All four pages are `//TODO` placeholders.
- **Why it matters for us:** When completed, these will document how to build and connect dApps to EVE Frontier. Until then, `vendor/evevault/` is the reference implementation for Sui wallet standard integration.
- **Notable clarifications:** `vendor/builder-scaffold/dapps/` now contains a React dApp starter using `@evefrontier/dapp-kit` (added 2026-02-18).

### New Pages Discovered (2026-02-18)

The following pages were identified in `vendor/builder-documentation` (2026-02-18 sync). All confirmed populated with substantive content:

| Page | Likely URL | Lines | Summary |
|------|-----------|-------|--------|
| Object Model | `/smart-contracts/object-model` | 53 | Sui object types & ownership in EVE Frontier context |
| Ownership Model | `/smart-contracts/ownership-model` | 104 | Cap-based ownership & access hierarchy |
| Smart Character | `/smart-assemblies/smart-character` | 34 | Character object structure & interactions |
| Network Node | `/smart-assemblies/network-node` | 77 | Network Node assembly type documentation |
| Introduction to Modding | `/smart-assemblies/introduction` | 32 | Builder extension onboarding guide — links to Gate, SSU, Turret |
| @evefrontier/dapp-kit SDK | `/dapp-kit/dapp-kit` | ~230 | React SDK for building EVE Frontier dApps on Sui. **Updated 2026-03-03:** Full TypeDoc link added (`sui-docs.evefrontier.com`), `useSponsoredTransaction` hook removed from docs, transaction pattern simplified to `useDAppKit()` from `@mysten/dapp-kit-react`. Peer-dep sync warning added. |

### Introduction to EVE Vault

- **URL:** https://docs.evefrontier.com/eve-vault/introduction-to-eve-vault
- **Last updated:** ~3 days ago
- **Summary:** Documents EVE Vault as the wallet and inventory manager. Covers zkLogin authentication, Sui Wallet Standard compliance, FusionAuth OAuth, Chrome extension features, and the LUX/EVE Token economy.
- **Why it matters for us:** Provides economic context (LUX for in-game, EVE Token for ecosystem). Confirms the production auth stack: FusionAuth → zkLogin → Sui address.
- **Overlaps with:**
  - `vendor/evevault/` (full implementation)
  - `docs/architecture/sui-playground-capabilities.md` §5
- **Notable clarifications:** Mentions LUX and EVE Token as the two primary currencies — not documented in our code. ~~Wallet Game Setup, Browser Extension sub-pages are `//TODO`.~~ **Updated 2026-03-03:** Browser Extension page now populated (install guide, PIN, sign-in flow, screenshots). Wallet Game Setup still `//TODO`. **Updated 2026-03-11:** Browser Extension page updated to reference v0.0.5 download.

### Contributing / Work in Progress

- **URL:** https://docs.evefrontier.com/contributing/a-work-in-progress and `/contributing/contributing`
- **Last updated:** ~5 days ago
- **Summary:** Acknowledges the docs are being actively rewritten for Sui transition. ~~Community contribution is planned but not yet available (repo not public).~~ **Updated 2026-02-20:** Repo is now public for contributions. Provides PR workflow guidance and editorial guidelines.
- **Why it matters for us:** ~~Community docs repo is not yet public, so we cannot contribute fixes for `//TODO` pages.~~ Repo is now public — community contributions are accepted.

---

## Gaps Between Code and Docs

### GitBook Clarifies Behavior Not Obvious from Move Modules

- **Three-layer architecture** (Primitives → Assemblies → Extensions): The layer separation and `public(package)` restriction on primitives is not self-documenting from code alone.
- **Sponsored transaction pattern**: The `setSender(player)` + `setGasOwner(admin)` + `AdminACL` verification flow is documented with TypeScript examples in the Interfacing page but only implied by `verify_sponsor()` calls in Move code.
- **Hot-potato pattern semantics**: The World Explainer explains *why* `OfflineAssemblies` and `ReturnOwnerCapReceipt` lack `drop` — to enforce atomic multi-step transactions. This design intent is not in code comments.
- **Location privacy rationale**: The docs explain that hashed coordinates preserve information asymmetry (hidden bases) — the Move code stores hashes but doesn't explain the game-design motivation.
- **Sui-specific constraints**: Object size limits (250KB), max struct fields (32), max dynamic fields per tx (1024) are documented in the Constraints page but not referenced in world-contracts code.
- **JSON-RPC deprecation**: ~~The Interfacing page notes Sui is deprecating JSON-RPC in favor of GraphQL/gRPC~~ **Updated 2026-02-20:** JSON-RPC section fully removed from the Interfacing page. `SuiJsonRpcClient` (SDK v2, replaces deprecated `SuiClient`), GraphQL, and gRPC are the only documented read paths.
- **LUX / EVE Token economy**: The EVE Vault introduction mentions two currencies (LUX and EVE Token) not referenced in world-contracts code.

### Code Is Canonical But Docs Lag

- **Build pages**: ~~Assembly Build pages (restructured from Configure/Deploy) are still stubs~~ **Updated 2026-02-20:** Gate Build page is now fully populated (end-to-end guide). SSU Build page is still a stub. Our capabilities doc (§4, §8) supplements for SSU deployment flows.
- ~~**Turret module**: Neither docs nor code have turret implementation — docs page is `//TODO`, code has no turret module.~~ **RESOLVED 2026-03-02:** world-contracts v0.0.14 implements turret.move (677 lines + 1097-line test suite). Turret extension example added. Docs page may still lag.
- **GAS Faucet**: Docs page is `//TODO` — our local devnet auto-funds; testnet faucet details unknown.
- **dApps integration**: dApp sub-pages (Quick Start, Connecting, Customizing) are still `//TODO`. However, `@evefrontier/dapp-kit` SDK documentation is now populated (304 lines in `vendor/builder-documentation/dapp-kit/dapp-kit.md`). **Updated 2026-02-20:** `vendor/builder-scaffold/dapps/` now contains a working React dApp starter with `@evefrontier/dapp-kit` integration (queries.ts shows assembly info + wallet status components).
- **Extension examples**: ~~The Interfacing page mentions extension registration but doesn't show the full flow.~~ **Updated 2026-02-20:** Gate Build page now documents the full extension flow end-to-end. `vendor/world-contracts/contracts/extension_examples/` has 3 working examples (**Updated 2026-03-02:** gate.move deleted, turret.move added — still 3 examples: config.move, storage_unit.move, turret.move). `vendor/builder-scaffold/move-contracts/smart_gate_extension/` has 3 canonical reference implementations (config.move, tribe_permit.move, corpse_gate_bounty.move). *(Renamed from `smart_gate/` in scaffold v3c65b22, 2026-03-10.)*
- **ZK proximity proofs**: The docs mention zero-knowledge proofs as a "future" alternative to server-signed proofs. Our `vendor/eve-frontier-proximity-zk-poc/` is a working Groth16 implementation — ahead of the docs.
- **builder-scaffold branch**: ~~The Environment Setup page references a `build` branch and `localnet-setup/docker` directory~~ **Updated 2026-02-20:** Fixed — docs now reference `main` branch and correct `docker` directory. Submodule reference removed from builder-documentation repo.
- **AdminCap → AdminACL discrepancy (2026-02-20)**: Docs now consistently use `AdminACL` (shared object with authorized sponsor addresses). World-contracts code already uses AdminACL. No functional discrepancy — naming alignment only.
- ~~**SSU proximity proof discrepancy (2026-02-20)**: Docs show `deposit_by_owner`/`withdraw_by_owner` taking AdminACL instead of proximity proof. Code still uses proximity proof.~~ **RESOLVED 2026-02-28:** world-contracts code now matches docs — proximity proof fully removed from owner-path SSU functions, replaced by `admin_acl.verify_sponsor(ctx)`. Our extension path was never affected.
- **SDK migration (NEW 2026-02-28)**: Both world-contracts and builder-scaffold TS scripts migrated from `SuiClient` (`@mysten/sui/client`) to `SuiJsonRpcClient` (`@mysten/sui/jsonRpc`). EVE Vault previously migrated to `SuiGrpcClient` (`@mysten/sui/grpc`). Three different client types across the ecosystem — builder dApps should use `SuiJsonRpcClient`.
- **EVE token asset (NEW 2026-02-28)**: New `contracts/assets/` package in world-contracts. `Coin<EVE>` with 10B supply, 9 decimals, AdminCap + EveTreasury pattern. `transfer_from_treasury`, `burn_from_treasury` functions. Relevant for CivilizationControl coin toll (potential to accept EVE instead of just SUI).
- **Gate link/unlink events (NEW 2026-02-28)**: `GateLinkedEvent` and `GateUnlinkedEvent` now emitted by `link_gates`/`unlink_gates`. Useful for dashboard monitoring.
- **Proximity proof removed from builder-scaffold (NEW 2026-02-28)**: `ts-scripts/utils/proof.ts` entirely deleted. `collect-corpse-bounty.ts` no longer takes proximity proofs. Uses AdminACL + sponsored tx instead.
- **EVE Vault default chain (NEW 2026-02-28)**: Default chain switched from `SUI_DEVNET_CHAIN` to `SUI_TESTNET_CHAIN`. Chain order in wallet adapter: testnet first, devnet second.
- **Turret assembly implemented (NEW 2026-03-02)**: world-contracts v0.0.14 adds full `turret.move` module (677 lines). Typed witness extension pattern identical to gate/SSU. `get_target_priority_list` is the builder-extensible entry point. BCS-serialized `TargetCandidate` / `ReturnTargetPriorityList` protocol. `OnlineReceipt` hot-potato. Default rules: same-tribe non-aggressors excluded, STARTED_ATTACK +10000 weight, ENTERED +1000 weight. Extension example replaces deleted gate.move in `extension_examples/`. anchor/unanchor require AdminACL.
- **Gate extension example DELETED (NEW 2026-03-02)**: `contracts/extension_examples/sources/gate.move` removed. Replaced by `turret.move` extension example. Builder-scaffold `smart_gate_extension/` remains the canonical gate extension reference. *(Renamed from `smart_gate/` in scaffold v3c65b22, 2026-03-10.)*
- **EVE Vault sponsored transaction flow (NEW 2026-03-02)**: New `sponsoredTransactionHandler.ts` (221 lines) + `SignSponsoredTransaction.tsx` popup (159 lines). Server provides `bcsDataB64Bytes` + `preparationId`; player signs with zkLogin; execution via `/transactions/sponsored/execute` API endpoint. Sponsored tx now fully functional (previously stubbed).
- **Fuel withdraw refactor (NEW 2026-03-02)**: `fuel::withdraw` now requires `type_id: u64` parameter. Validates fuel type_id matches (was previously just `is_some` check). Supports backend fuel services.
- **Builder-scaffold dapp-kit published (NEW 2026-03-02)**: `@evefrontier/dapp-kit` switched from local file reference to published npm `^0.1.0`. New `pnpm-workspace.yaml` for build approvals.
- **Inventory Item/ItemEntry split (NEW 2026-03-03)**: world-contracts v0.0.15 refactors inventory to a Coin/Balance analogy: `ItemEntry` (at-rest, `copy, drop, store`, no UID) vs `Item` (in-transit, wraps UID + `parent_id` + location). Withdrawal creates a fresh `Item` with UID; deposit destroys it. `parent_id` on `Item` is set to the assembly ID on withdrawal and validated on deposit — items can only be deposited back to their origin SSU (or via `deposit_to_owned<Auth>`).
- **`withdraw_item<Auth>` signature change (BREAKING 2026-03-03)**: Now takes `quantity: u32` + `ctx: &mut TxContext` — supports partial withdrawal. Previously withdrew the entire item stack. All call sites (TradePost, posture-switch validation, extension tests) must add `quantity` arg.
- **`deposit_item<Auth>` now validates `parent_id` (BREAKING 2026-03-03)**: Asserts `inventory::parent_id(&item) == storage_unit_id`. Items withdrawn from SSU-A can only be deposited back into SSU-A (same assembly). Cross-SSU deposit requires `deposit_to_owned<Auth>` instead.
- **New `deposit_to_owned<Auth>` function (NEW 2026-03-03)**: Extension-authorized deposit into a player's owned inventory. Target player does NOT need to be the tx sender. Creates owned inventory if it doesn't exist. Enables async trading, guild hangars, automated rewards. Validates `parent_id` and tenant match.
- **AdminACL removed from owner-path SSU functions (NEW 2026-03-03)**: `deposit_by_owner` and `withdraw_by_owner` no longer take `admin_acl: &AdminACL`. Just OwnerCap + sender == character_address. `update_energy_source_connected_*` functions also lost AdminACL param. Owner operations are fully self-service now.
- **`EItemVolumeMismatch` error removed (NEW 2026-03-03)**: Replaced by `ETypeIdMismatch` (code 6) and `ESplitQuantityInvalid` (code 7). Volume is now treated as static per type_id — mismatches silently use stored volume.
- **dapp-kit API simplified (NEW 2026-03-03)**: `useSponsoredTransaction` hook removed from docs. `dAppKit` import changed to `useDAppKit()` from `@mysten/dapp-kit-react`. Full TypeDoc API published at `http://sui-docs.evefrontier.com/`. Assembly ID now via URL param `?tenant=utopia&itemId=...` instead of env var.
- **EVE Vault browser extension docs populated (NEW 2026-03-03)**: Install guide for Chrome (load unpacked), PIN creation, sign-in flow with Utopia credentials, dashboard screenshots. Links to evevault repo releases (v0.0.3).
- **corpse_gate_bounty AdminACL removed (NEW 2026-03-03)**: `collect_corpse_bounty` no longer takes `admin_acl` param. `withdraw_by_owner` call updated with `quantity: 1` arg.
- **Third test character (NEW 2026-03-03)**: `create-character.ts` now supports `PLAYER_C_PRIVATE_KEY` env var for a third character (`GAME_CHARACTER_C_ID`).
- **PlayerProfile struct (NEW 2026-03-09, v0.0.16)**: `character::create_character` now auto-creates a `PlayerProfile { id, character_id }` struct and transfers it to the player's wallet address. Enables clients to query characters by wallet. Marked as temporary — to be replaced by OwnerCap-to-wallet flow.
- **transfer_owner_cap_to_address fix (NEW 2026-03-09, v0.0.16)**: `access::transfer_owner_cap_to_address<T>` Character type detection fixed — now uses `module_string()` + `datatype_string()` instead of full TypeName comparison (which was broken across package boundaries).
- **Assembly-level metadata update functions (NEW 2026-03-09, v0.0.16)**: All assembly types (gate, turret, SSU, assembly, network_node) and Character now have `update_metadata_name`, `update_metadata_description`, `update_metadata_url` functions. Requires OwnerCap authorization.
- **Killmail refactored with registry (NEW 2026-03-09, v0.0.16)**: `create_killmail` signature changed — now takes `registry: &mut KillmailRegistry`, raw `u64` IDs (not TenantItemId), `&Character` reference, `u8` loss_type. New `KillmailRegistry` module added. Killmail struct fields renamed: `killmail_id`→`key`, `killer_character_id`→`killer_id`, `victim_character_id`→`victim_id`. New `reported_by_character_id` field. Duplicate check via `EKillmailAlreadyExists`.
- **Unlink/unanchor gate functions (NEW 2026-03-09, v0.0.16)**: `gate::unlink_and_unanchor` and `gate::unlink_and_unanchor_orphan` — convenience admin functions to unlink and destroy a gate in one call.
- **Extension withdraw_item online guard (NEW 2026-03-09, v0.0.16)**: `storage_unit::withdraw_item<Auth>` now asserts `storage_unit.status.is_online()` — cannot withdraw items from an offline SSU via extension. Previously only owner-path had this check.
- **Gate type matching required for linking (NEW 2026-03-09, v0.0.17)**: `gate::link_gates` now asserts `source_gate.type_id == destination_gate.type_id` (error: `EGateTypeMismatch`). Gates of different types cannot be linked.
- **Turret anchor initializes metadata (NEW 2026-03-09, v0.0.17)**: `turret::anchor` now creates metadata (empty strings) on anchor instead of `option::none()`. Ensures turrets always have metadata for `update_metadata_*` calls.
- **Turret owner exclusion in target priority (NEW 2026-03-09, v0.0.17)**: `effective_weight_and_excluded` now excludes the turret owner by `character_id` match (in addition to same-tribe exclusion). Prevents turrets from targeting their own operator.
- **LocationRegistry + reveal_location on ALL assemblies (NEW 2026-03-10, world-contracts 2aed50b)**: New shared `LocationRegistry` object (Table<ID, Coordinates>). `Coordinates` struct: `solarsystem: u64`, `x/y/z: String` (strings to support negative values). New `reveal_location()` function on Assembly, Gate, StorageUnit, Turret, and NetworkNode — AdminACL sponsored call stores plain-text coordinates on-chain so dApps can discover structure positions. `LocationRevealedEvent` emitted. `get_location(registry, assembly_id) → Option<Coordinates>` for reads. Accessor functions: `solarsystem()`, `x()`, `y()`, `z()`. Marked temporary — "use until the offchain location reveal service is ready." **HIGH CC IMPACT:** Eliminates need for manual structure position input during onboarding. SVG map can be populated from on-chain data. Wallet→PlayerProfile→Character→OwnerCaps→Structures→LocationRegistry gives full discovery chain.
- **builder-documentation: PlayerProfile discovery documented (NEW 2026-03-10)**: `smart-character.md` now includes "Discovering character from wallet address" section. Ownership model deduplicated to link to character page. Confirms: query objects owned by wallet with type `PlayerProfile` → `character_id` → fetch `Character` shared object.
- **builder-scaffold renamed smart_gate→smart_gate_extension, storage_unit→storage_unit_extension (NEW 2026-03-10)**: Move contracts and TS scripts directories renamed to `_extension` suffix. `tokens/` package removed entirely. Docs refactored to remove redundancy.
- **builder-documentation restructured (NEW 2026-03-09)**: 35 commits. Files moved: `wallets-and-identity.md` → `eve-vault/`, `environment-setup.md` → `quickstart/`, `dapp-kit.md` → `tools/`, `interfacing-with-the-eve-frontier-world.md` → `tools/`. New files: `move-patterns-in-frontier.md`, `tools/efctl.md`, `tools/debugging.md`. Deleted: `welcome/contstraints.md`, `troubleshooting/player.md`, `eve-vault/gas-faucet.md`. Turret docs now fully populated. SSU build page expanded. Gate docs simplified. Ownership model now includes `transfer_owner_cap_to_address` and PlayerProfile. EVE Vault URL updated for browser extension.
- **builder-scaffold PostgreSQL indexer (NEW 2026-03-09, v0.0.1)**: 6 commits. New PostgreSQL Indexer + GraphQL support. Docker overlay for custom indexer stack. `CONTRIBUTING.md` expanded. dapp-kit updated to 0.1.2. Node.js install via APT instead of curl|bash. Additional build/deploy docs.
- **EVE Vault v0.0.4 (NEW 2026-03-09)**: 8 commits. Sponsored tx now sends metadata to endpoint. Gas estimation for token transfers. Device reset + centralized logout. Reusable SignPopupAuthGate component. Fix sign message bytes and auth flow. EVE token support added. `useSendToken` significantly enhanced. New GraphQL epoch queries. New `resetVaultOnDevice` with tests. `storageKeys.ts` centralized. Send token screen added. Lockscreen enhanced.
- **Extension freeze / anti-rugpull mechanism (NEW 2026-03-11, v0.0.18)**: New `extension_freeze.move` module shared across gate/turret/SSU. `freeze_extension_config(assembly, owner_cap)` permanently locks the authorized extension — `authorize_extension` blocked with `EExtensionConfigFrozen` after freeze. `ExtensionConfigFrozenEvent { assembly_id }` emitted. `is_extension_frozen()` view function. Marker cleaned up on `unanchor`/`unanchor_orphan`. **HIGH CC IMPACT:** Enables trust-building demo moment — operator freezes gate extension to prove toll rules can't be changed.
- **SSU open inventory system (NEW 2026-03-11, v0.0.18)**: New `deposit_to_open_inventory<Auth>` / `withdraw_from_open_inventory<Auth>` — contract-controlled inventory slot on each SSU not tied to any player. Key derived deterministically via `blake2b256(bcs(id) ++ "open_inventory")`. Created at anchor time (SSU `inventory_keys` now starts with 2 entries: main + open). Extension-only access — no owner or player direct access. Use cases: shared prize pools, loot tables, contract-mediated escrow, atomic courier handoffs. New errors: `EOpenStorageNotInitialized` (15). New view functions: `has_open_storage()`, `open_storage_key()`.
- **Gate/turret new view functions (NEW 2026-03-11, v0.0.18)**: `is_extension_configured()`, `extension_type()` added to gate. `is_extension_frozen()` added to gate/turret/SSU. Useful for dApp read paths.
- **builder-scaffold docs overhaul (NEW 2026-03-11)**: 1 commit. Complete documentation rewrite: `builder-flow-docker.md`, `builder-flow-host.md`, `builder-flow.md` (shared steps). README rewritten as landing page. Docker readme expanded. `sui client test-publish` with `--pubfile-path` documented. New scripts: `pnpm collect-corpse-bounty`, `pnpm authorise-storage-unit-extension`.
- **builder-documentation EVE Vault v0.0.5 (NEW 2026-03-11)**: Browser extension download URL updated from v0.0.4 to v0.0.5. Single file change.
- **EVE Vault v0.0.5 (NEW 2026-03-11)**: Multi-tenant auth server switching. New TenantSelector component, `tenantStore`, `tenantConfig`. Supports stillness/utopia/testevenet/nebula FusionAuth servers. Per-tenant OIDC storage keys and client secrets. `getUserManager()` now takes `tenantId` param. Env vars changed from single `VITE_FUSIONAUTH_CLIENT_SECRET` to per-tenant `VITE_TENANT_<NAME>_CLIENT_SECRET`. Wallet standard interface unchanged — no impact on dApp integration.

---

## Agent Usage Rules

1. **Before generating chain interaction flows, sponsorship patterns, or deployment steps**, consult this reference map and the linked official docs pages — especially the "Interfacing with the EVE Frontier World" and "World Explainer" pages.
2. **Code in `vendor/world-contracts` is canonical; GitBook is explanatory.** If behavior described in docs contradicts Move code, the code wins. Flag the discrepancy.
3. **If official docs show a "Last updated" date newer than this document's review date** (2026-03-09), re-check the relevant pages before finalizing logic.
4. **For access control patterns**, consult "Introduction to Smart Contracts" — the capability, witness, and hot-potato patterns are explained with rationale not present in code comments.
5. **For Sui-specific limits** (object size, field counts, gas), consult the "Constraints" page and cross-reference with Sui protocol docs.
6. **Do not copy GitBook content into internal docs.** Summarize insights and link to the official page. This avoids drift and respects content ownership.

---

## Freshness Policy

### Review Cadence

- **During active development:** Manual review once per week. Check the `llms.txt` index at `https://docs.evefrontier.com/llms.txt` for structural changes, then spot-check pages relevant to current work.
- **Before hackathon submission freeze:** Full review of all "Relevant Sections" listed above. Update summaries and gap analysis.
- **After major EVE Frontier announcements:** Re-check immediately — doc updates often follow announcements within days.

### Drift Detection

- Each page in the official docs shows a "Last updated" relative timestamp at the bottom.
- Compare against this document's review date (top of file). If any relevant page shows a newer update, re-read it before relying on cached summaries here.
- The `llms.txt` endpoint provides the full page index — a new entry indicates a new page that should be mapped here.

### What NOT to Do

- Do not automate scraping or mirroring of the GitBook site.
- Do not embed large text excerpts from official docs — link and summarize only.
- Do not treat this map as a substitute for reading the official docs when working on chain interaction logic.

---

## Quick URL Reference

| Page | URL |
|------|-----|
| Home / Welcome | https://docs.evefrontier.com/welcome |
| Smart Infrastructure | https://docs.evefrontier.com/smart-assemblies |
| Constraints | https://docs.evefrontier.com/welcome/constraints |
| Sui & Move Fundamentals | https://docs.evefrontier.com/welcome/sui-and-move-fundamentals |
| Wallets & Identity | https://docs.evefrontier.com/welcome/wallets-and-identity |
| Environment Setup | https://docs.evefrontier.com/tools/environment-setup |
| GAS Faucet | https://docs.evefrontier.com/tools/gas-faucet |
| Intro to Smart Contracts | https://docs.evefrontier.com/smart-contracts/introduction-to-smart-contracts |
| Object Model | https://docs.evefrontier.com/smart-contracts/object-model |
| Ownership Model | https://docs.evefrontier.com/smart-contracts/ownership-model |
| World Explainer | https://docs.evefrontier.com/smart-contracts/eve-frontier-world-explainer |
| Interfacing with the World | https://docs.evefrontier.com/smart-contracts/interfacing-with-the-eve-frontier-world |
| Introduction to Modding | https://docs.evefrontier.com/smart-assemblies/introduction |
| Smart Character | https://docs.evefrontier.com/smart-assemblies/smart-character |
| Network Node | https://docs.evefrontier.com/smart-assemblies/network-node |
| Storage Unit | https://docs.evefrontier.com/smart-assemblies/storage-unit |
| Storage Unit — Build | https://docs.evefrontier.com/smart-assemblies/storage-unit/build |
| Gate | https://docs.evefrontier.com/smart-assemblies/gate |
| Gate — Build | https://docs.evefrontier.com/smart-assemblies/gate/build |
| Turret | https://docs.evefrontier.com/smart-assemblies/turret |
| @evefrontier/dapp-kit SDK | https://docs.evefrontier.com/dapp-kit |
| dApps Quick Start | https://docs.evefrontier.com/dapps/dapps-quick-start |
| EVE Vault Introduction | https://docs.evefrontier.com/eve-vault/introduction-to-eve-vault |
| LLMs Index | https://docs.evefrontier.com/llms.txt |
| LLMs Full Content | https://docs.evefrontier.com/llms-full.txt |
| Contributing | https://docs.evefrontier.com/contributing/a-work-in-progress |
