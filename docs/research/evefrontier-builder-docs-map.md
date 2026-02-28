# EVE Frontier Builder Documentation Reference Map

**Retention:** Prep-only

> **Last updated:** 2026-02-28 (submodule refresh: c2628fd/9edb532/ed238c2/09c2ec2 → 6b6fae8/6bc43a1/687d432/e508451)
> **Source:** https://docs.evefrontier.com/
> **Internal review by:** AI agent (initial mapping; refreshed 2026-02-28)

## Purpose

This document maps official EVE Frontier GitBook builder documentation to internal SUI Playground capabilities and defines when agents should consult it. It is a **structured reference index only** — no external content is mirrored or duplicated here.

The official docs are actively being rewritten for the Sui blockchain transition. Many pages contain `//TODO` placeholders. Code in `vendor/world-contracts` is canonical; GitBook is explanatory.

> **Local reading source:** `vendor/builder-documentation` (submodule added 2026-02-18, updated 2026-02-28 to commit 6b6fae8) contains the GitBook source markdown. Read locally for content; cite the public GitBook URLs in documentation and code comments.

---

## Site Structure Overview

The official docs (`https://docs.evefrontier.com/`) are organized into these top-level sections. A machine-readable index is available at `https://docs.evefrontier.com/llms.txt`.

| Section | Base URL Path | Pages | Status |
|---------|--------------|-------|--------|
| Welcome | `/welcome` | 5 pages | Mostly complete |
| Tools | `/tools` | 2 pages | Partial (GAS Faucet is TODO) |
| Smart Contracts | `/smart-contracts` | 5 pages | Substantive content (Object Model, Ownership Model now populated); AdminCap → AdminACL rename reflected |
| Smart Assemblies | `/smart-assemblies` | 7+ pages (Gate, SSU, Turret, Smart Character, Network Node, Modding intro) | Introductions now substantive (Gate 120 lines, SSU 126 lines); **Gate Build page now populated** (end-to-end guide); SSU Build still stub; Turret still TODO |
| dApps | `/dapps` | 4 pages + dapp-kit | dApp sub-pages still TODO; `@evefrontier/dapp-kit` SDK now populated (304 lines) |
| EVE Vault | `/eve-vault` | 4 pages | Introduction done; GAS Faucet, Wallet Game Setup, Browser Extension still TODO |
| Troubleshooting | `/troubleshooting` | 3 pages | All TODO |
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
  - **JSON-RPC is fully removed from docs (not just deprecated).** New integrations should use GraphQL, gRPC, or SuiClient.

### Smart Storage Unit

- **URL:** https://docs.evefrontier.com/smart-assemblies/storage-unit
- **Last updated:** ~3 days ago
- **Summary:** Introduction to SSU as a Move smart contract object. Explains core design, developer/player interaction patterns, and references the world-contracts repo for practical examples. Now 126 lines with substantive content (previously had `//TODO` prerequisites section — now populated).
- **Why it matters for us:** Directly maps to `vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move` and the scaffold template at `vendor/builder-scaffold/move-contracts/storage_unit/`.
- **Overlaps with:**
  - `vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move` (796 lines)
  - `docs/architecture/sui-playground-capabilities.md` §4.2
- **Notable clarifications:** Build page (`/gate/build`) exists but is still a stub (header only). Page structure changed from Configure/Deploy to single Build page. **Updated 2026-02-20:** Docs now show `deposit_by_owner`/`withdraw_by_owner` taking `AdminACL` instead of proximity proof (temporarily; docs say proximity proof returns "once a location service is available"). ~~**Code-docs discrepancy:** world-contracts code still has proximity_proof in these functions.~~ **Updated 2026-02-28:** Discrepancy resolved — world-contracts code now matches docs. `withdraw_by_owner` takes `admin_acl: &AdminACL` and calls `admin_acl.verify_sponsor(ctx)`. Proximity proof removed from all owner-path SSU functions. Our extension path (deposit_item/withdraw_item<Auth>) is unaffected.

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
  - `vendor/builder-scaffold/move-contracts/smart_gate/` (canonical gate extension examples)
  - `docs/architecture/sui-playground-capabilities.md` §4.1
- **Notable clarifications:** **Build page (`/gate/build`) is now populated** — full end-to-end build guide covering scaffold walkthrough (config.move, tribe_permit.move, corpse_gate_bounty.move), publish, configure rules, authorize extension, issue permit, jump with permit. Includes a minimal toll gate example. Scaffold links now point to `main` branch.

### Smart Turret

- **URL:** https://docs.evefrontier.com/smart-assemblies/turret
- **Last updated:** ~4 days ago
- **Summary:** Placeholder page (`//TODO`). No content yet.
- **Why it matters for us:** No turret module exists in world-contracts either (noted in our capabilities doc §4.4). This is a future capability.
- **Notable clarifications:** Both the docs and code confirm turrets are not yet implemented. Only killmails reference structures via `LossType::STRUCTURE`.

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
| @evefrontier/dapp-kit SDK | `/dapp-kit/dapp-kit` | 304 | React SDK for building EVE Frontier dApps on Sui |

### Introduction to EVE Vault

- **URL:** https://docs.evefrontier.com/eve-vault/introduction-to-eve-vault
- **Last updated:** ~3 days ago
- **Summary:** Documents EVE Vault as the wallet and inventory manager. Covers zkLogin authentication, Sui Wallet Standard compliance, FusionAuth OAuth, Chrome extension features, and the LUX/EVE Token economy.
- **Why it matters for us:** Provides economic context (LUX for in-game, EVE Token for ecosystem). Confirms the production auth stack: FusionAuth → zkLogin → Sui address.
- **Overlaps with:**
  - `vendor/evevault/` (full implementation)
  - `docs/architecture/sui-playground-capabilities.md` §5
- **Notable clarifications:** Mentions LUX and EVE Token as the two primary currencies — not documented in our code. Wallet Game Setup, Browser Extension sub-pages are `//TODO`.

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
- **JSON-RPC deprecation**: ~~The Interfacing page notes Sui is deprecating JSON-RPC in favor of GraphQL/gRPC~~ **Updated 2026-02-20:** JSON-RPC section fully removed from the Interfacing page. SuiClient, GraphQL, and gRPC are the only documented read paths.
- **LUX / EVE Token economy**: The EVE Vault introduction mentions two currencies (LUX and EVE Token) not referenced in world-contracts code.

### Code Is Canonical But Docs Lag

- **Build pages**: ~~Assembly Build pages (restructured from Configure/Deploy) are still stubs~~ **Updated 2026-02-20:** Gate Build page is now fully populated (end-to-end guide). SSU Build page is still a stub. Our capabilities doc (§4, §8) supplements for SSU deployment flows.
- **Turret module**: Neither docs nor code have turret implementation — docs page is `//TODO`, code has no turret module.
- **GAS Faucet**: Docs page is `//TODO` — our local devnet auto-funds; testnet faucet details unknown.
- **dApps integration**: dApp sub-pages (Quick Start, Connecting, Customizing) are still `//TODO`. However, `@evefrontier/dapp-kit` SDK documentation is now populated (304 lines in `vendor/builder-documentation/dapp-kit/dapp-kit.md`). **Updated 2026-02-20:** `vendor/builder-scaffold/dapps/` now contains a working React dApp starter with `@evefrontier/dapp-kit` integration (queries.ts shows assembly info + wallet status components).
- **Extension examples**: ~~The Interfacing page mentions extension registration but doesn't show the full flow.~~ **Updated 2026-02-20:** Gate Build page now documents the full extension flow end-to-end. `vendor/world-contracts/contracts/extension_examples/` has 3 working examples. `vendor/builder-scaffold/move-contracts/smart_gate/` has 3 canonical reference implementations (config.move, tribe_permit.move, corpse_gate_bounty.move).
- **ZK proximity proofs**: The docs mention zero-knowledge proofs as a "future" alternative to server-signed proofs. Our `vendor/eve-frontier-proximity-zk-poc/` is a working Groth16 implementation — ahead of the docs.
- **builder-scaffold branch**: ~~The Environment Setup page references a `build` branch and `localnet-setup/docker` directory~~ **Updated 2026-02-20:** Fixed — docs now reference `main` branch and correct `docker` directory. Submodule reference removed from builder-documentation repo.
- **AdminCap → AdminACL discrepancy (2026-02-20)**: Docs now consistently use `AdminACL` (shared object with authorized sponsor addresses). World-contracts code already uses AdminACL. No functional discrepancy — naming alignment only.
- ~~**SSU proximity proof discrepancy (2026-02-20)**: Docs show `deposit_by_owner`/`withdraw_by_owner` taking AdminACL instead of proximity proof. Code still uses proximity proof.~~ **RESOLVED 2026-02-28:** world-contracts code now matches docs — proximity proof fully removed from owner-path SSU functions, replaced by `admin_acl.verify_sponsor(ctx)`. Our extension path was never affected.
- **SDK migration (NEW 2026-02-28)**: Both world-contracts and builder-scaffold TS scripts migrated from `SuiClient` (`@mysten/sui/client`) to `SuiJsonRpcClient` (`@mysten/sui/jsonRpc`). EVE Vault previously migrated to `SuiGrpcClient` (`@mysten/sui/grpc`). Three different client types across the ecosystem — builder dApps should use `SuiJsonRpcClient`.
- **EVE token asset (NEW 2026-02-28)**: New `contracts/assets/` package in world-contracts. `Coin<EVE>` with 10B supply, 9 decimals, AdminCap + EveTreasury pattern. `transfer_from_treasury`, `burn_from_treasury` functions. Relevant for CivilizationControl coin toll (potential to accept EVE instead of just SUI).
- **Gate link/unlink events (NEW 2026-02-28)**: `GateLinkedEvent` and `GateUnlinkedEvent` now emitted by `link_gates`/`unlink_gates`. Useful for dashboard monitoring.
- **Proximity proof removed from builder-scaffold (NEW 2026-02-28)**: `ts-scripts/utils/proof.ts` entirely deleted. `collect-corpse-bounty.ts` no longer takes proximity proofs. Uses AdminACL + sponsored tx instead.
- **EVE Vault default chain (NEW 2026-02-28)**: Default chain switched from `SUI_DEVNET_CHAIN` to `SUI_TESTNET_CHAIN`. Chain order in wallet adapter: testnet first, devnet second.

---

## Agent Usage Rules

1. **Before generating chain interaction flows, sponsorship patterns, or deployment steps**, consult this reference map and the linked official docs pages — especially the "Interfacing with the EVE Frontier World" and "World Explainer" pages.
2. **Code in `vendor/world-contracts` is canonical; GitBook is explanatory.** If behavior described in docs contradicts Move code, the code wins. Flag the discrepancy.
3. **If official docs show a "Last updated" date newer than this document's review date** (2026-02-28), re-check the relevant pages before finalizing logic.
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
