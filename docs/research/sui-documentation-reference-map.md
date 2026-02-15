# SUI Documentation Reference Map

## Purpose

This document maps chain-level canonical documentation from [docs.sui.io](https://docs.sui.io) to the SUI Playground workspace. It defines consultation rules, identifies architectural constraints, and establishes a canonical source hierarchy for agents and builders.

This is **not** a mirror of SUI documentation. It is a structured awareness layer that tells agents and builders *where to look* and *what matters* for this project context.

---

## Primary Discovery Source

- **URL:** https://docs.sui.io/llms.txt
- **Format:** Structured markdown index of all SUI documentation pages with descriptions
- **Why authoritative:** Maintained by Mysten Labs as the canonical machine-readable index. Covers all sections with stable URL paths. Use this as the entry point when searching for chain-level documentation on any Sui topic.
- **Usage:** Agents should fetch/consult `llms.txt` when needing to locate the correct SUI docs page for a topic, rather than guessing URLs.

---

## Relevant Sections (Structured)

### Move Language & Conventions

- **URL:** https://docs.sui.io/concepts/sui-move-concepts, https://docs.sui.io/concepts/sui-move-concepts/conventions
- **Why relevant:** All world-contracts and builder extensions are written in Move. Conventions define naming, module layout, init function patterns.
- **Impacts on world-contract usage:** Extensions must follow Move 2024 conventions. Struct abilities (`key`, `store`, `drop`, `copy`) directly control what objects can do — hot-potato patterns rely on deliberately omitting `drop`.
- **Notable constraints:** 32 max struct fields per struct (Move compiler limit).
- **Relationship to EVE Frontier docs:** GitBook explains capabilities conceptually; SUI docs define the compiler-enforced ability semantics.

### Object Model

- **URL:** https://docs.sui.io/guides/developer/objects/object-model
- **Why relevant:** Everything on Sui is an object. World-contracts uses shared objects (Gate, StorageUnit, NetworkNode, Character), owned objects (OwnerCap), and wrapped objects.
- **Impacts on world-contract usage:** Object ownership type determines consensus path (shared = consensus latency ~2-3s; owned = fast path). Max object size is 250 KB — impacts inventory design.
- **Notable constraints:** 250 KB max object size enforced at serialization. Objects without `store` cannot be transferred.
- **Relationship to EVE Frontier docs:** GitBook mentions shared objects briefly; SUI docs define the full 4-type ownership model (address-owned, shared, immutable, wrapped).

### Object Ownership

- **URL:** https://docs.sui.io/guides/developer/objects/object-ownership
- **Sub-pages:** address-owned, shared, immutable, wrapped, party
- **Why relevant:** Builders must choose the correct ownership type for extension objects. Wrong choice causes consensus bottlenecks or access issues.
- **Impacts on world-contract usage:** All Smart Assembly types (Gate, SSU, NetworkNode) are shared objects — subject to consensus ordering. OwnerCap uses transfer-to-object (Receiving pattern).
- **Notable constraints:** Shared objects cannot benefit from Sui's fast-path. Concurrent access to the same shared object is consensus-bound.

### Dynamic Fields

- **URL:** https://docs.sui.io/guides/developer/objects/dynamic-fields
- **Why relevant:** World-contracts uses dynamic fields for inventory storage (per-OwnerCap VecMap), extension config storage, and component data. The extension example `config.move` demonstrates this pattern.
- **Impacts on world-contract usage:** Dynamic fields are NOT included in object serialization — `sui client object <ID>` won't show them. Must use `sui client dynamic-field <PARENT_ID>` or GraphQL. Deleting a parent does NOT auto-delete dynamic fields (orphan risk). Adding/removing modifies parent version.
- **Notable constraints:** 1,024 dynamic fields per transaction. Distinction between `dynamic_field::add` and `dynamic_object_field::add` matters (parent-child vs name-value semantics).
- **Relationship to EVE Frontier docs:** Not covered in GitBook. SUI docs are the only source for dynamic field behavior.

### Tables and Bags

- **URL:** https://docs.sui.io/guides/developer/objects/tables-bags
- **Why relevant:** Higher-level wrappers around dynamic fields with entry counting. Not used in world-contracts but useful for extensions needing key-value stores with simpler API.
- **Impacts on world-contract usage:** Alternative to raw dynamic fields for extension state. Protects against accidental deletion when non-empty.
- **Notable constraints:** Same underlying limits as dynamic fields.

### Transfers & Custom Transfer Rules

- **URL:** https://docs.sui.io/guides/developer/objects/transfers, https://docs.sui.io/guides/developer/objects/transfers/custom-rules, https://docs.sui.io/guides/developer/objects/transfers/transfer-policies
- **Why relevant:** World-contracts uses capability-gated transfers. Sui's transfer policy system enables royalties, restrictions, or custom logic on object transfers — relevant if hackathon ideas involve item trading.
- **Impacts on world-contract usage:** Transfer-to-Object (`Receiving` pattern) is used for OwnerCap → Character transfers. Only the parent's owner can `receive` child objects.
- **Notable constraints:** Receiving requires the parent to be shared or owned. Transfer policies are enforced by Kiosk — not applicable to direct transfers unless using Kiosk.

### Programmable Transaction Blocks (PTBs)

- **URL:** https://docs.sui.io/guides/developer/transactions/prog-txn-blocks, https://docs.sui.io/guides/developer/transactions/building-ptb
- **Why relevant:** World-contracts' hot-potato patterns (borrow_owner_cap → action → return_owner_cap) **require** PTBs. Most real operations need 3+ commands in a single PTB.
- **Impacts on world-contract usage:** Complex flows (link two gates, offline with assemblies) may require 6+ PTB commands. Understanding result flow between commands is critical.
- **Notable constraints:** Max 1,000 commands per PTB. Gas costs scale with command count. Hot-potato structs (no `drop`) **must** be consumed within the same PTB or the transaction aborts.
- **Relationship to EVE Frontier docs:** GitBook shows PTB code examples; SUI docs define composition rules, input/result types, and limits.

### PTB Inputs and Results

- **URL:** https://docs.sui.io/concepts/transactions/inputs-and-results
- **Why relevant:** Understanding how results flow between PTB commands is essential for the borrow → action → return pattern. Two types of inputs: objects and pure values.
- **Impacts on world-contract usage:** Each PTB command's result can be passed as input to subsequent commands. This is how hot-potato structs are threaded through multi-step operations.

### Sponsored Transactions

- **URL:** https://docs.sui.io/guides/developer/transactions/sponsor-txn
- **Why relevant:** Enables gasless player UX. Pattern: `tx.setSender(player)` + `tx.setGasOwner(sponsor)`, both sign. Critical for onboarding players who don't hold SUI.
- **Impacts on world-contract usage:** World-contracts adds a game-level overlay: `verify_sponsor(admin_acl, ctx)` checks that the gas sponsor is in the ACL whitelist. Forgetting to add the sponsor address to AdminACL causes aborts even if Sui-level sponsorship is correct.
- **Notable constraints:** At the Sui level, any address can sponsor any transaction. The ACL check is game-specific, not chain-enforced.
- **Relationship to EVE Frontier docs:** GitBook shows the pattern; SUI docs define the dual-signing protocol and edge cases.

### Coin Standard & Currency

- **URL:** https://docs.sui.io/standards/coin, https://docs.sui.io/standards/currency, https://docs.sui.io/guides/developer/currency
- **Why relevant:** Foundation for any custom token, bounty, or economic mechanic. World-contracts has no coin/token module — any hackathon idea involving currencies implements `Coin<T>` directly.
- **Impacts on world-contract usage:** `TreasuryCap<T>` controls minting authority (single holder, like GovernorCap). Splitting/merging coins are native operations.
- **Notable constraints:** One-time witness pattern required for coin creation. `TreasuryCap` must be held securely.
- **Relationship to EVE Frontier docs:** GitBook mentions LUX/EVE Token conceptually but no Coin<T> module exists in world-contracts.

### Coin Management

- **URL:** https://docs.sui.io/concepts/coin-mgt
- **Why relevant:** Sui uses coins as owned objects. Wallets/dApps must handle multiple coin objects, merging, and splitting explicitly in PTBs.
- **Impacts on world-contract usage:** Gas smashing merges coins automatically for gas payment, but non-gas coin operations require explicit merge/split commands.

### Events

- **URL:** https://docs.sui.io/guides/developer/accessing-data/using-events
- **Why relevant:** World-contracts emits structured events (JumpEvent, ItemMintedEvent, KillmailCreatedEvent). Events are the primary off-chain integration mechanism for dApps.
- **Impacts on world-contract usage:** Events are NOT stored on-chain — emitted during execution and indexed by full nodes. Historical access depends on node pruning policy. Query via GraphQL (preferred), JSON-RPC (deprecated), or WebSocket subscriptions.
- **Notable constraints:** Events are ephemeral. A dApp needing historical event data requires an indexer or must store critical state in objects/dynamic fields.
- **Relationship to EVE Frontier docs:** GitBook acknowledges events exist and suggests GraphQL; SUI docs define the subscription API and query format.

### NFTs & Object Display

- **URL:** https://docs.sui.io/guides/developer/nft, https://docs.sui.io/guides/developer/nft-index, https://docs.sui.io/standards/display
- **Why relevant:** World-contracts' `Item` struct has `key + store` but doesn't implement `sui::display::Display<T>`. Any builder wanting wallet/explorer-visible items needs the Display standard.
- **Impacts on world-contract usage:** Without Display, objects appear as raw structs in explorers. Trophies, achievements, loot should implement Display for visibility.
- **Notable constraints:** Display templates are managed on-chain. Updates require the `Publisher` object.
- **Relationship to EVE Frontier docs:** Not covered in GitBook. SUI docs are the only source.

### Kiosk Standard

- **URL:** https://docs.sui.io/standards/kiosk, https://docs.sui.io/standards/kiosk-apps
- **Why relevant:** Decentralized marketplace protocol for trading objects with custom transfer policies. Essential if a hackathon idea involves item exchange, auctions, or market mechanics.
- **Impacts on world-contract usage:** Not referenced in world-contracts. Would be built alongside, not inside, world-contracts if used.
- **Relationship to EVE Frontier docs:** Not mentioned in GitBook. SUI docs are canonical.

### Gas Model

- **URL:** https://docs.sui.io/concepts/tokenomics/gas-in-sui
- **Why relevant:** Transactions pay for both computation and long-term storage. Understanding gas budgets is critical for complex PTBs.
- **Impacts on world-contract usage:** World-contracts TS scripts use `100_000_000` MIST (0.1 SUI) as convention. Complex multi-command PTBs need higher budgets. Storage rebates are returned when deleting objects (e.g., `unanchor()` destroying assemblies).
- **Notable constraints:** Gas budget must be declared before execution. Under-budgeting aborts the transaction. Over-budgeting returns unused gas minus storage deposit.

### Gas Smashing

- **URL:** https://docs.sui.io/concepts/transactions/gas-smashing
- **Why relevant:** Sui automatically merges multiple gas coins into a single object for gas payment. Relevant when a player's SUI is fragmented.
- **Impacts on world-contract usage:** Simplifies gas payment for players with many small coin objects — no manual merge needed for gas.

### On-Chain Randomness

- **URL:** https://docs.sui.io/guides/developer/on-chain-primitives/randomness-onchain
- **Why relevant:** `sui::random::Random` provides verifiable on-chain randomness (VRF-based). Not in world-contracts. Any hackathon idea involving loot drops, random encounters, or probabilistic outcomes needs this.
- **Impacts on world-contract usage:** Must use special `entry` function signature that takes `&Random`. Cannot be composed in arbitrary PTB commands — design constraint.
- **Notable constraints:** Randomness functions have special calling conventions. Vulnerable to MEV if used naively — read the security considerations.

### Clock / Time Access

- **URL:** https://docs.sui.io/guides/developer/on-chain-primitives/access-time
- **Why relevant:** `sui::clock::Clock` is a shared object at fixed address `0x6`. World-contracts uses it for fuel burn timing (network_node) and jump permit expiry (gate).
- **Impacts on world-contract usage:** Clock must be passed as a transaction argument referencing `0x6`. Resolution is ~1 second (consensus time) — not suitable for sub-second game logic.
- **Notable constraints:** Hardcoded at object ID `0x6`. Always available. Resolution limited by consensus timing.

### Groth16 ZK Verification

- **URL:** https://docs.sui.io/guides/developer/cryptography/groth16
- **Why relevant:** The ZK proximity PoC uses `sui::groth16` for on-chain proof verification. Sui docs cover API details: curve selection (BN254/BLS12-381), proof format, public input encoding.
- **Impacts on world-contract usage:** The existing PoC uses BN254 curve. Public inputs limited to 8 field elements (proximity circuit uses 6 — near limit). Verification cost dominated by pairing operations.
- **Notable constraints:** Max 8 public inputs. Proof format must match exactly or verification fails. BN254 and BLS12-381 are the only supported curves.
- **Relationship to EVE Frontier docs:** ZK is listed as "future" in GitBook. SUI docs are the only source for `sui::groth16` API.

### zkLogin

- **URL:** https://docs.sui.io/concepts/cryptography/zklogin, https://docs.sui.io/guides/developer/cryptography/zklogin-integration
- **Why relevant:** Maps OAuth identities (Google, Apple, FusionAuth) to deterministic Sui addresses. Enables authenticated player onboarding without wallet management.
- **Impacts on world-contract usage:** zkLogin addresses are normal Sui addresses — can own objects, sign transactions, receive coins. The world-contracts `zklogin/` scaffold demonstrates the integration.
- **Notable constraints:** Requires external prover (Mysten Enoki or self-hosted). Cannot be done fully locally. Adds OAuth + prover dependency.
- **Relationship to EVE Frontier docs:** GitBook references Enoki/FusionAuth; SUI docs define the full integration flow (JWT, ephemeral keys, salt, proofs).

### Package Upgrades

- **URL:** https://docs.sui.io/guides/developer/packages/upgrade
- **Why relevant:** World-contracts holds an `UpgradeCap` from `sui::package`. Understanding upgrade policies (compatible, additive, dependency-only) determines what changes are possible post-deploy.
- **Impacts on world-contract usage:** Post-deploy iteration requires understanding what changes are compatible vs breaking.
- **Notable constraints:** Upgrade policy is set at publish time. More restrictive policies cannot be relaxed. `compatible` allows adding functions/types but not removing.

### Storage Model

- **URL:** https://docs.sui.io/concepts/sui-architecture/sui-storage
- **Why relevant:** Storage rebates, object size costs, and fee structure directly impact contract design decisions. Large objects cost more to store and modify.
- **Impacts on world-contract usage:** Inventory design must consider storage costs. Deleting objects returns stored SUI via rebates.

### Local Network / Testing

- **URL:** https://docs.sui.io/guides/developer/getting-started/local-network
- **Why relevant:** Local devnet is the primary development environment for this workspace. Fresh genesis assigns random chain IDs.
- **Impacts on world-contract usage:** The `-e local` flag is required for all Move builds against local devnet. Without it, chain ID mismatch causes build failures.
- **Notable constraints:** Local network state is ephemeral. Must re-publish after restart.
- **Relationship to EVE Frontier docs:** Our `docs/architecture/sui-playground.md` covers the Docker-based local devnet setup specific to this workspace.

### Security Model

- **URL:** https://docs.sui.io/concepts/sui-architecture/sui-security
- **Why relevant:** Assets on Sui are typed objects that can only be used by their owners unless smart contract logic permits otherwise. Foundational for understanding capability-gated access in world-contracts.

---

## Architectural Constraints Identified

Key chain-level constraints that impact design decisions in this workspace:

| Constraint | Limit | Impact |
|------------|-------|--------|
| Object size | 250 KB max | Bounds inventory storage per object; large VecMaps may hit this |
| Struct fields | 32 max per struct | Limits data density per struct; use dynamic fields for overflow |
| Dynamic fields per tx | 1,024 max | Caps batch inventory operations per transaction |
| PTB commands | 1,000 max per transaction | Bounds complex hot-potato chains; NetworkNode with many assemblies at risk |
| Groth16 public inputs | 8 max | Proximity circuit uses 6; limits proof complexity |
| Shared object finality | ~2-3 seconds | All Smart Assembly types subject to consensus latency |
| Clock resolution | ~1 second | Not suitable for sub-second game timing |
| Gas budget | Must be pre-declared | Under-budgeting aborts; convention is 0.1-0.5 SUI |
| Storage rebates | Returned on object deletion | Incentivizes cleanup (unanchor, burn) |
| Randomness calling convention | Special `entry` function required | Cannot compose `&Random` in arbitrary PTB flows |

**Additional behavioral constraints:**
- Hot-potato structs (no `drop` ability) **must** be consumed within the same PTB — enforced by the Move compiler, not runtime.
- Dynamic fields are invisible to `sui client object` — must query separately via `sui client dynamic-field` or GraphQL.
- Events are ephemeral — emitted during execution, indexed by full nodes, subject to pruning. Not stored on-chain.
- Sponsored transaction ACL is a game-level check (`verify_sponsor`) overlaying Sui's permissionless sponsorship model.
- Transfer-to-Object (`Receiving`) requires the parent's owner to authorize — relevant for OwnerCap stored inside Character objects.
- Local devnet requires `-e local` flag for Move builds to match chain ID.

---

## Canonical Source Hierarchy

When consulting documentation, follow this priority order:

### 1. `vendor/world-contracts` Move Code (Project-Specific Canonical)
- **When to consult:** Implementing Move logic, understanding game-level access control, capability patterns, struct definitions, entry point signatures.
- **Authority:** Definitive for project-specific behavior. If code contradicts any documentation, the code wins.
- **Scope:** Smart Assembly types, extensions API, inventory system, location primitives, ACL model, hot-potato patterns.

### 2. SUI Documentation — docs.sui.io (Chain Canonical)
- **When to consult:** Reasoning about object model, gas mechanics, PTB composition, coin/token standards, dynamic field behavior, cryptographic primitives, events, on-chain randomness, package upgrades, storage model.
- **Authority:** Definitive for chain-level behavior. Sui protocol enforces these rules regardless of game-level logic.
- **Discovery:** Use https://docs.sui.io/llms.txt to locate the correct page.
- **Scope:** Everything the Sui blockchain enforces — from abilities to gas to consensus.

### 3. EVE Frontier GitBook — docs.evefrontier.com (Explanatory Layer)
- **When to consult:** Understanding gameplay flows, deployment procedures, three-layer architecture, sponsored transaction patterns, world architecture concepts.
- **Authority:** Explanatory — describes intent and patterns. If it contradicts Sui docs or world-contracts code, defer to those.
- **Caveat:** Actively being rewritten for Sui transition. Many pages contain `//TODO` placeholders.
- **Reference map:** `docs/research/evefrontier-builder-docs-map.md`

### 4. Internal Documentation (Derived Understanding)
- **When to consult:** Workspace setup, capability analysis, hackathon ideas, decision history, operational procedures.
- **Authority:** Derived from the above sources. Must be validated against upstream if in doubt.
- **Scope:** `docs/architecture/`, `docs/research/`, `docs/ideas/`, `docs/operations/`

### Resolution Rule
When ambiguity exists between sources: **world-contracts code > SUI docs > GitBook > internal docs**. Flag discrepancies rather than silently choosing one interpretation.

---

## Agent Consultation Policy

1. **When generating Move logic:** Consult `vendor/world-contracts` first for patterns, struct definitions, and entry points. Follow existing conventions (witness pattern, hot-potato, `public(package)` visibility).

2. **When reasoning about object model, gas, PTBs, coins, events, or chain limits:** Consult SUI docs via `llms.txt` at https://docs.sui.io/llms.txt. These are chain-enforced behaviors that no game-level code can override.

3. **When reasoning about deployment flow or gameplay mechanics:** Consult EVE Frontier GitBook via `docs/research/evefrontier-builder-docs-map.md` for the relevant page.

4. **Conflict resolution:** If GitBook and SUI docs disagree, SUI docs override. If world-contracts code and GitBook disagree, code overrides. Flag all discrepancies.

5. **Before assuming chain behavior:** Always verify against SUI docs. Do not assume object size limits, gas costs, PTB constraints, or ability semantics from memory. Check the canonical source.

6. **Do not mirror:** Never copy SUI documentation content into this repository. Summarize insights, link to the canonical page, and move on.

---

## Freshness Policy

- **Check SUI `llms.txt`** once per week during active development to detect new or restructured pages.
- **Always re-check** before hackathon submission freeze — chain-level docs may have been updated.
- **Do not mirror documentation locally.** This reference map contains URLs and distilled summaries only.
- **If a SUI docs page returns 404:** Search `llms.txt` for the topic — the page may have been reorganized. Update the URL in this document.
- **Review cadence for this document:** Update whenever a new Sui feature is used in the project or a constraint is discovered that isn't documented here.

---

## Cross-Reference: Key SUI Pages for Hackathon Use Cases

| Hackathon Theme | Primary SUI Docs | Secondary |
|----------------|-----------------|-----------|
| Custom currency / bounties | `/standards/coin`, `/guides/developer/currency` | `/concepts/coin-mgt` |
| Item trading / marketplace | `/standards/kiosk`, `/guides/developer/objects/transfers/transfer-policies` | `/standards/display` |
| Gasless player UX | `/guides/developer/transactions/sponsor-txn` | `/concepts/tokenomics/gas-in-sui` |
| ZK proofs (proximity, identity) | `/guides/developer/cryptography/groth16` | `/concepts/cryptography/zklogin` |
| Loot drops / randomness | `/guides/developer/on-chain-primitives/randomness-onchain` | — |
| Time-locked mechanics | `/guides/developer/on-chain-primitives/access-time` | — |
| Complex multi-step operations | `/guides/developer/transactions/building-ptb` | `/concepts/transactions/inputs-and-results` |
| Off-chain dashboards | `/guides/developer/accessing-data/using-events` | `/guides/developer/accessing-data/query-with-graphql` |
| Trophy / achievement NFTs | `/guides/developer/nft`, `/standards/display` | `/guides/developer/nft/nft-soulbound` |
| Extension state management | `/guides/developer/objects/dynamic-fields` | `/guides/developer/objects/tables-bags` |
