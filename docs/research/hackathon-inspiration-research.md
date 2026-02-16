# Hackathon Inspiration Research — EVE Frontier Builder Extensions

**Retention:** Prep-only

> **Date:** 2026-02-15
> **Agent Role:** Hackathon Inspiration Research
> **Grounded in:** world-contracts source, eve-frontier-proximity-zk-poc, builder-scaffold, player-value-ux-analysis, and cross-ecosystem research

---

## 1. Past Blockchain Hackathon Winners (Relevant Patterns)

### 1.1 Sui Ecosystem Hackathons

#### Sui Overflow (2024)
Sui's flagship global hackathon attracted 300+ projects across DeFi, gaming, infrastructure, and social. Relevant winners and notable entries:

| Project | Track | What It Did | Pattern for EVE Frontier |
|---------|-------|-------------|--------------------------|
| **Bucket Protocol** | DeFi | Over-collateralized stablecoin with dynamic interest rates and multi-asset vaults | **Vault economics pattern** — SSU inventory as collateral vaults; items have value that can back lending/borrowing positions via extension |
| **SuiPlay (Mysten Labs)** | Gaming Infra | Web3 gaming handheld console with native NFT/token integration | **Hardware-first UX** — design extensions assuming non-crypto-native gamers; minimize wallet friction via zkLogin (evevault pattern) |
| **Turbos Finance** | DeFi | Concentrated liquidity AMM on Sui with limit orders | **Automated market making** — SSU marketplace extension with limit order book; items priced via constant-product or order-book mechanism |
| **Aftermath Finance** | DeFi | Liquid staking + DEX + lending in one protocol | **Composable DeFi primitive** — fuel as a stakeable/tradeable asset; NWN fuel deposits earning yield for energy provision |
| **Navi Protocol** | DeFi | Lending/borrowing with flash loans on Sui | **Flash-loan analogue** — borrow items from an SSU within a single PTB, use them (e.g., as gate toll), return them by end of tx. Uses hot-potato pattern already present in world-contracts |
| **MoveBit** | Security | Formal verification tool for Move smart contracts | **Verified extensions** — a registry of audited/verified gate/SSU extensions that gate owners can trust; community-vetted code |

#### Sui Builder House Series (2024-2025)
Multiple regional events (Dubai, Paris, Seoul, Denver). Notable patterns from workshops and demos:

| Pattern Observed | Source | EVE Frontier Mapping |
|------------------|--------|---------------------|
| **Dynamic NFTs with composable traits** | Multiple Builder House demos | Characters could accumulate on-chain reputation traits (killmail stats, gate traffic served, trade volume) as composable badges |
| **Kiosk protocol for marketplace** | Sui Kiosk standard (Mysten Labs) | Item trading via Sui's Kiosk standard — items wrapped in `TransferPolicy`-governed kiosks for controlled marketplace |
| **Shared object as coordination primitive** | Common Sui pattern | `AllianceRegistry`, `ReputationLedger`, `PolicyConfig` — all shared objects enabling multi-player coordination |
| **Programmable Transaction Blocks (PTBs)** | Sui Builder workshops | Complex multi-step operations (offline NWN → offline all connected assemblies → withdraw fuel) composed atomically in a single PTB |

#### Sui Hackathon — "Build on Sui" Series (Dorahacks, 2024-2025)
Dorahacks-hosted Sui hackathons with bounties from ecosystem projects:

| Project | What It Did | Pattern for EVE Frontier |
|---------|-------------|--------------------------|
| **SuiNS** (Sui Name Service) | Human-readable names on Sui | **Structure naming** — register human-readable names for gates/SSUs (e.g., "alpha-gate.evefrontier.sui") using SuiNS integration or custom registry |
| **Deepbook** | Central Limit Order Book on Sui | **On-chain order matching** — item buy/sell orders matched on-chain; more capital-efficient than AMM for low-liquidity game items |
| **ZKLogin dApps** | Multiple projects using Sui's zkLogin | **Frictionless onboarding** — gate/SSU management dApps where players log in via Google/Apple without managing keys (evevault already implements this) |

### 1.2 Move Language Hackathons (Aptos + Sui)

#### Aptos World Tour Hackathon (2024)
Aptos's Move-based hackathons surfaced patterns applicable to Sui Move:

| Project | What It Did | Pattern for EVE Frontier |
|---------|-------------|--------------------------|
| **AptosArena** | On-chain PvP game with verifiable randomness | **On-chain combat resolution** — extend killmail system with verifiable random functions (VRF) for loot drops or combat outcomes |
| **Topaz** | NFT marketplace with royalty enforcement via Move capabilities | **Capability-gated royalties** — toll gates where a percentage of SUI payment flows to an alliance treasury, enforced by Move capability checks |
| **Econia** | Hybrid order book (on-chain matching, off-chain settlement) | **Hybrid marketplace** — on-chain order matching for items with off-chain UX for browsing/price discovery |
| **Pontem (Liquidswap)** | AMM with Move generics for type-safe pool creation | **Generic pool pattern** — `Pool<ItemType, SUI>` using Move generics for type-safe item/SUI swap pools per item category |

#### Move CTF (Capture the Flag) Competitions
Multiple Move security CTFs have surfaced common vulnerability patterns:

| Vulnerability Pattern | How It Maps |
|-----------------------|-------------|
| **Witness type spoofing** | Extensions must use `drop`-only witnesses; never give witnesses `copy` or `store` abilities. EVE Frontier extensions already follow this correctly. |
| **Hot-potato escape** | The `OfflineAssemblies` and `ReturnOwnerCapReceipt` hot-potato patterns must consume all obligations. CTFs have shown that forgetting to process one element breaks invariants. |
| **Shared object contention** | High-traffic gates could face contention. Pattern: batch permit issuance off-peak, cache permits client-side. |
| **Type confusion in generics** | `OwnerCap<Gate>` vs `OwnerCap<StorageUnit>` — Move's type system prevents confusion, but extension devs must be careful with generic auth types. |

### 1.3 Gaming Blockchain Hackathons

#### Ethereum Game Jam / ETHGlobal Gaming Track (2023-2025)
On-chain gaming hackathons using Ethereum/L2s with ECS frameworks (MUD, DOJO):

| Project | What It Did | Pattern for EVE Frontier |
|---------|-------------|--------------------------|
| **Dark Forest** (Ethereum) | Fully on-chain space exploration with ZK fog-of-war | **ZK fog-of-war for EVE Frontier** — the ZK PoC's location attestation is directly analogous. Dark Forest proved this works at scale for gaming. Players reveal locations selectively. |
| **OPCraft** (Optimism) | On-chain Minecraft-like with autonomous worlds | **Autonomous world extensions** — builder extensions as "mods" that anyone can deploy (already the EVE Frontier extension model) |
| **Loot Survivor** (StarkNet) | On-chain roguelike with deterministic combat | **Deterministic PvE** — extension that spawns "challenges" at gates (solve puzzle → get permit), where challenge generation is deterministic from on-chain state |
| **Primodium** (Ethereum L2) | On-chain base-building RTS with resource management | **Resource management dashboard** — fuel/energy/inventory management mirrors Primodium's factory management. The NWN→assembly dependency tree is analogous to Primodium's production chains. |
| **Influence** (StarkNet) | Space MMO with on-chain resource extraction and trade | **Industrial chains** — fuel refining, item manufacturing flows through SSU networks. Most directly comparable to EVE Frontier's economic model. |

#### Treasure DAO Game Builder Series (2024)
On-chain gaming infrastructure hackathons:

| Pattern | What It Demonstrated | EVE Frontier Application |
|---------|---------------------|--------------------------|
| **Guild infrastructure tools** | DAO-managed game asset pools | Corp asset management: shared SSU access, pooled fuel reserves, delegated gate management |
| **Achievements as composable NFTs** | On-chain achievement system with unlockable perks | Gate access gated by achievement NFTs ("completed 100 jumps" → premium gate access) |
| **Interoperable game items** | Items usable across game modes | Items with `key + store` abilities in world-contracts already support cross-contract composability |

### 1.4 Infrastructure / Governance Hackathons

#### ETHGlobal — Governance & DAO Track (2023-2025)

| Project | What It Did | Pattern for EVE Frontier |
|---------|-------------|--------------------------|
| **Snapshot X** | On-chain governance with storage proofs | **Alliance voting** — corp/alliance decisions (change gate policy, admit new members) decided by on-chain vote. Storage proofs verify token holdings for weighted votes. |
| **Tally** | DAO governance dashboard | **Corp governance dashboard** — proposal creation, voting, execution all on-chain. Tallies tribe membership for quorum. |
| **Zodiac** (Gnosis) | Modular DAO toolkit with roles and permissions | **Modular role system** — directly maps to corp access manager pattern. Zodiac's "modifier" pattern ≈ EVE Frontier's extension witness pattern. |
| **Hats Protocol** | Tree-structured role-based access control | **Hierarchical corp permissions** — GovernorCap → AdminCap → OwnerCap hierarchy extended with sub-roles (Officer, Member, Recruit). Hats' tree structure maps perfectly. |

#### Chainlink Constellation Hackathon (2024)

| Pattern | Source | EVE Frontier Application |
|---------|--------|--------------------------|
| **Automation (Keepers)** | Chainlink Automation winners | Auto-refuel NWNs, auto-offline structures on threat detection, scheduled gate policy changes |
| **VRF for randomized events** | Chainlink VRF projects | Randomized gate toll discounts, loot box mechanics at SSUs, random patrol encounters |
| **Price feeds for game economies** | Chainlink Data Feeds | Item price oracle — aggregate marketplace data into a price feed for arbitrage/analytics |

---

## 2. Sui Ecosystem dApps (Relevant Patterns)

### 2.1 Governance / Permissions / DAO

| Project | What It Provides | Pattern for EVE Frontier |
|---------|------------------|--------------------------|
| **SuiDAO Framework** | Generic DAO tooling on Sui (proposals, voting, treasury) | Alliance governance: members vote on gate policies, treasury spending, member admission. Proposals as shared objects with voting period + quorum. |
| **Kriya DEX** | Decentralized exchange with governance token | Governance over marketplace parameters (listing fees, trade fees) via token-weighted voting |
| **Turbos Finance Governance** | Protocol-owned liquidity with community governance | Gate network governance: community decides which gates to subsidize, toll rates, alliance admissions |
| **Sui Multisig** | Native Sui multisig support (k-of-n signing) | Corp treasury multisig: require 2-of-3 officers to approve OwnerCap transfers, extension changes, or fuel withdrawals. Sui's native multisig eliminates need for custom contracts. |

### 2.2 Automation / Policy Engines

| Project | What It Provides | Pattern for EVE Frontier |
|---------|------------------|--------------------------|
| **Cetus Protocol** | AMM with concentrated liquidity and automated rebalancing | **Automated inventory rebalancing** — items automatically redistributed across SSUs based on demand/consumption (off-chain bot, on-chain execution) |
| **Sui Automation Framework** (community) | Scheduled transaction execution via keeper networks | **Keeper-driven operations** — scheduled fuel deposits, periodic gate policy updates, automated offline-on-threat |
| **FlowX Finance** | DEX aggregator with smart routing | **Gate route aggregation** — find cheapest/fastest/safest path through gate network considering toll prices, access requirements, and threat levels |

### 2.3 Gaming Infrastructure on Sui

| Project | What It Provides | Pattern for EVE Frontier |
|---------|------------------|--------------------------|
| **SuiPlay0X1** (Mysten Labs) | Web3 gaming hardware + ecosystem | **Hardware wallet for EVE** — sign gate/SSU transactions via dedicated gaming device; specialized UX for structure management |
| **Playtron** | Gaming OS with Web3 integration | **OS-level integration** — gate jump notifications, fuel alerts as system-level notifications |
| **Sui Gaming SDK** (community) | Standard patterns for on-chain game entities | **Standardized extension SDK** — reusable composable patterns for gate/SSU extensions with testing framework |
| **Mysten Labs' Object Display** | Human-readable on-chain object metadata | **Structure display** — gates/SSUs/NWNs with rich on-chain metadata (name, icon, description) using Sui's `Display` standard |

### 2.4 Access Control Patterns in Move

| Pattern | Where It Appears | EVE Frontier Application |
|---------|------------------|--------------------------|
| **Witness pattern** | Core Sui Move (stdlib) | Already used in world-contracts extensions. Best practice for typed authorization. |
| **Hot-potato pattern** | Sui lending protocols, world-contracts | `OfflineAssemblies`, `ReturnOwnerCapReceipt` — forces atomic multi-step operations. Can be extended for escrow (deposit → trade → return-receipt). |
| **Transfer-to-object** | Sui's `Receiving` type | `OwnerCap` stored inside `Character` via transfer-to-object. Foundation for delegated key management. |
| **Dynamic fields as config** | DeFi protocols, world-contracts extension examples | `TribeConfig`, `TimeConfig`, `PolicyConfig` — arbitrary configuration attached to objects without upgrading the contract. |
| **Capability delegation** | DAO frameworks on Sui | Time-limited or revocable capability wrappers: wrap `OwnerCap<T>` in a `Delegation<T>` with expiry timestamp and revocation flag. |

### 2.5 ZK Proof Usage on Sui

| Project | What It Demonstrates | EVE Frontier Application |
|---------|---------------------|--------------------------|
| **Sui's native `sui::groth16`** | BN254 Groth16 verification (up to 8 public inputs) | Already used in the ZK PoC for location/distance attestation. Constraint: max 8 public inputs. |
| **zkLogin (Mysten Labs)** | ZK proof of JWT ownership for address derivation | Player authentication without key management. evevault implements this for EVE Frontier's OAuth. |
| **SuiFrens** (with zkProofs) | ZK-gated minting of collectibles | **ZK-gated gate access** — prove membership in an allowlist (Merkle tree) without revealing which member you are. Anonymize gate jumps. |
| **eve-frontier-proximity-zk-poc** | Location + distance Groth16 attestation (this workspace) | Directly applicable: gate linking with trustless distance proofs, SSU proximity verification without server dependency |
| **Poseidon on Sui** | `sui::poseidon::poseidon_bn254()` — native Poseidon hash | Merkle tree commitments for allowlists, credential attestation, selective data revelation |

---

## 3. EVE Frontier Builder Community

### 3.1 Official Builder Program

EVE Frontier (by CCP Games) has actively cultivated a builder community since the game's early access. Key observations from public sources:

| Source | Key Information |
|--------|----------------|
| **CCP Games Press Release (2025)** | "EVE Frontier to Launch on Layer-1 Blockchain Sui" — confirmed Sui as the production chain. World contracts are the canonical on-chain layer. |
| **Builder Program** | CCP operates a builder program with documentation at `docs.evefrontier.com` (referenced in builder-scaffold README). Builders deploy custom extensions to smart structures (gates, SSUs). |
| **Extension Examples (world-contracts repo)** | Three official examples: tribe-gated access, tribe permit via shared config, corpse bounty for gate access. These demonstrate the canonical extension pattern. |
| **builder-scaffold repo** | Official CCP-provided scaffold with Docker devnet, Move templates, and zkLogin example. Designed for builders to get started quickly. |
| **world-contracts repo** | Open-sourced (GitHub: `projectawakening/world-contracts`) for community visibility and collaboration. Production game contracts published at separate repo (`projectawakening/world-chain-contracts`). |
| **eve-frontier-proximity-zk-poc** | CCP-built PoC for trustless location/distance verification via Groth16. Shows CCP's direction toward ZK-based privacy for game mechanics. |

### 3.2 Community Builder Patterns (Inferred from Architecture)

The extension pattern in world-contracts is designed for a specific builder workflow:

```
1. Builder writes a Move module with a witness type (e.g., `struct MyAuth has drop {}`)
2. Builder deploys the module to Sui
3. Structure owner registers the extension type on their structure
4. Default operations are gated; only the extension can authorize actions
5. Extension logic can be arbitrarily complex (check tribe, require payment, verify ZK proof, etc.)
```

**Observed builder community interests** (from architecture docs, extension examples, and PoC):
- **Tribe-based access control** — the most common use case; tribe membership as the gating criterion
- **Economic gating** — corpse bounty example shows pay-to-pass patterns
- **Privacy-preserving interactions** — ZK PoC shows CCP is investing in reducing trust assumptions
- **Modular configuration** — `ExtensionConfig` dynamic-field pattern for runtime-configurable extensions
- **Cross-structure coordination** — gate linking, NWN→assembly dependencies suggest demand for multi-structure tooling

### 3.3 Known Community Tools & Projects

| Project/Tool | Status | What It Does |
|--------------|--------|--------------|
| **evevault** (this workspace) | Reference implementation | zkLogin wallet for EVE Frontier — Chrome extension + web app. Maps OAuth identity → Sui address. |
| **world-contracts TS scripts** | Official | TypeScript automation: deploy contracts, create characters/structures, link gates, mint items, generate location proofs. |
| **Smart Assembly Explorer** | Community (referenced in docs) | Tool highlighting on-chain smartassembly data including inventory data and transaction history. |
| **builder-scaffold Docker** | Official | One-command local devnet with pre-funded accounts and scaffold templates. |
| **zkLogin interactive CLI** | Official (in builder-scaffold) | Complete zkLogin flow example against EVE Frontier's OAuth + Mysten prover. |

### 3.4 EVE Frontier Hackathon Context

| Aspect | Detail |
|--------|--------|
| **Hackathon format** | Builder hackathons with focus on smart structure extensions (gates, SSUs, NWNs) |
| **Judging criteria (inferred)** | Innovation in extension design, player value, composability with existing structures, technical sophistication |
| **Build timeline** | Typically 2-4 weeks with LLM-accelerated development |
| **Infrastructure available** | Local devnet (Docker), testnet, world-contracts source, builder-scaffold, ZK PoC |
| **Key constraint** | No game server access — on-chain objects exist but have no in-game visual representation. Projects must demonstrate value through on-chain interactions, dashboards, or extension logic. |

---

## 4. Pattern Extraction: 15 Reusable Patterns

### Pattern 1: Toll Gate (Payment-Gated Access)

| Aspect | Detail |
|--------|--------|
| **Source** | Turbos Finance (Sui DEX) + Topaz royalties (Aptos) + EVE Frontier corpse bounty example |
| **How It Maps** | Gate extension that requires `Coin<SUI>` payment before issuing `JumpPermit`. Revenue flows to gate owner. Dynamic pricing via `TollConfig` dynamic field. |
| **Structures** | `Gate` (extension: `TollAuth`), `Coin<SUI>` |
| **Feasibility** | **Easy** — straightforward Coin handling in Move; `issue_jump_permit<TollAuth>()` after payment confirmed. ~50 LoC of new extension code. |

### Pattern 2: Multi-Rule Policy Engine

| Aspect | Detail |
|--------|--------|
| **Source** | Zodiac (Gnosis modular DAO) + Hats Protocol (tree RBAC) + Chainlink Automation |
| **How It Maps** | Single `PolicyAuth` extension with ordered rule list: TribeCheck, Payment, TimeWindow, ReputationThreshold, Cooldown. Evaluated sequentially; first deny/allow wins. Configurable via dynamic fields. |
| **Structures** | `Gate` (extension: `PolicyAuth`), `PolicyConfig` shared object, `Clock`, `Character` |
| **Feasibility** | **Medium** — rule evaluation logic is straightforward; visual policy builder requires frontend work. Start with pre-built rule templates. ~200 LoC Move + frontend. |

### Pattern 3: Corp Access Manager (Role-Based Permissions)

| Aspect | Detail |
|--------|--------|
| **Source** | Hats Protocol (tree RBAC) + Zodiac (role modifiers) + Gnosis Safe (multisig) |
| **How It Maps** | `CorpAuth` witness extension for SSUs and gates. `CorpConfig` shared object maps `character_id → role`, `role → permissions`. Check on every gated operation. |
| **Structures** | `StorageUnit` + `Gate` (extension: `CorpAuth`), `CorpConfig` shared object, `Character` |
| **Feasibility** | **Medium** — well-scoped Move contract + admin UI. Extends existing `ExtensionConfig` pattern. ~300 LoC Move. |

### Pattern 4: SSU Marketplace (Vending Machine)

| Aspect | Detail |
|--------|--------|
| **Source** | Deepbook (Sui CLOB) + Econia (Aptos orderbook) + Turbos Finance (AMM) |
| **How It Maps** | `MarketAuth` extension on SSU. Listings stored as dynamic fields (type_id → price × quantity). Buyer sends SUI → extension calls `withdraw_item<MarketAuth>()` → item transferred. |
| **Structures** | `StorageUnit` (extension: `MarketAuth`), `Marketplace` shared object, `Coin<SUI>` |
| **Feasibility** | **Medium** — core marketplace logic ~250 LoC. Item lifecycle (SSU → escrow → buyer) needs careful handling. |

### Pattern 5: ZK-Gated Access (Anonymous Gate Jumps)

| Aspect | Detail |
|--------|--------|
| **Source** | Dark Forest (ZK fog-of-war) + SuiFrens (ZK-gated minting) + eve-frontier-proximity-zk-poc |
| **How It Maps** | Gate extension requiring a Groth16 proof of allowlist membership (Merkle tree). Prover demonstrates "I am in this allowlist" without revealing which member they are. Uses `sui::groth16` + `sui::poseidon`. |
| **Structures** | `Gate` (extension: `ZKAuth`), custom Groth16 circuit, `AllowlistRoot` shared object |
| **Feasibility** | **Hard** — requires custom circom circuit (~2000 constraints for Merkle membership), trusted setup, circuit compilation. ZK PoC infrastructure provides foundation. ~500 LoC Move + circuit + TS proof generation. |

### Pattern 6: Escrow Trading Protocol

| Aspect | Detail |
|--------|--------|
| **Source** | Navi Protocol (flash loans) + Ethereum escrow patterns + Sui hot-potato pattern |
| **How It Maps** | `EscrowAuth` on SSUs. `TradeEscrow` shared object holds items + SUI. Both parties deposit → atomic swap → items redistributed. Timeout → refund. |
| **Structures** | `StorageUnit` (extension: `EscrowAuth`), `TradeEscrow` shared object, `Coin<SUI>` |
| **Feasibility** | **Medium** — Item `key + store` abilities allow holding in shared objects. Main complexity: multi-SSU coordination in single PTB. ~300 LoC. |

### Pattern 7: Fuel Futures / Energy Market

| Aspect | Detail |
|--------|--------|
| **Source** | Aftermath Finance (liquid staking) + Cetus Protocol (liquidity pools) + EVE Online's fuel economy |
| **How It Maps** | Players deposit fuel into a shared `FuelPool` → receive `FuelReceipt` tokens representing their share. NWN owners buy fuel from the pool at market rates. Creates a fuel market with price discovery. |
| **Structures** | `NetworkNode` (fuel deposit), custom `FuelPool` shared object, `FuelReceipt` token |
| **Feasibility** | **Medium** — fuel deposits are admin-gated in current contracts. Workaround: wrapper module that pools contributions and distributes to NWNs. ~200 LoC. |

### Pattern 8: Alliance Registry & Federated Gate Network

| Aspect | Detail |
|--------|--------|
| **Source** | Snapshot X (on-chain governance) + Tally (DAO dashboard) + EVE Online's alliance system |
| **How It Maps** | `AllianceRegistry` shared object: member tribes, leadership, policies. `AllianceAuth` gate extension checks registry membership. All alliance gates share policy without per-gate configuration. |
| **Structures** | `Gate` (extension: `AllianceAuth`), `AllianceRegistry` shared object, `Character` (tribe check) |
| **Feasibility** | **Medium** — clean use of shared objects + dynamic fields. Cross-player gate linking remains a limitation (each corp links their own gates; alliance = shared access policy). ~250 LoC. |

### Pattern 9: Killmail Analytics & Threat Intelligence

| Aspect | Detail |
|--------|--------|
| **Source** | zKillboard (EVE Online community tool) + Dune Analytics (blockchain) + The Graph (indexing) |
| **How It Maps** | Off-chain indexer for `KillmailCreatedEvent`. Aggregate by solar system, character, time period. Produce heat maps, player threat profiles, K/D ratios. Feed into gate extensions (deny access to known hostiles). |
| **Structures** | `Killmail` (event indexing), `Character` (identity correlation), `Gate` (threat-aware extension) |
| **Feasibility** | **Easy** — pure event indexing + dashboard. No contract changes. Integration with gate extension adds medium complexity. ~100 LoC indexer + frontend. |

### Pattern 10: Structure Insurance Protocol

| Aspect | Detail |
|--------|--------|
| **Source** | Nexus Mutual (DeFi insurance) + InsurAce + EVE Online's SRP (Ship Replacement Program) |
| **How It Maps** | Insurance pool: members contribute SUI premium. On `Killmail` with `LossType::STRUCTURE` matching an insured structure, the pool pays out to the owner. Actuary-style risk scoring based on solar system danger level (kill frequency). |
| **Structures** | `Killmail` (claim trigger), custom `InsurancePool` shared object, `Coin<SUI>`, `Character` |
| **Feasibility** | **Medium-Hard** — claim verification requires correlating killmails with structure ownership. Oracle pattern needed for automated payouts. ~400 LoC. |

### Pattern 11: Reputation-Weighted Governance

| Aspect | Detail |
|--------|--------|
| **Source** | Gitcoin Passport (sybil resistance) + Hats Protocol (RBAC) + Dark Forest (reputation from exploration) |
| **How It Maps** | On-chain `ReputationRegistry`: score derived from killmail K/D, trade volume, gate traffic served, structure uptime. Reputation gates: gate extensions require minimum reputation score. Endorsement staking: vouch for others by locking SUI. |
| **Structures** | `Character`, `Killmail`, custom `ReputationRegistry` shared object, `Gate`/`StorageUnit` extensions |
| **Feasibility** | **Medium** — registry is straightforward; fair scoring algorithm design is the challenge. Start with endorsement-only (human judgment). ~300 LoC Move + indexer. |

### Pattern 12: Cargo Manifest (Inter-SSU Logistics)

| Aspect | Detail |
|--------|--------|
| **Source** | Influence (StarkNet space MMO) + Primodium (RTS logistics) + real-world bill of lading |
| **How It Maps** | `CargoManifest` shared object wraps items withdrawn from source SSU. Holder travels through gate network. At destination, manifest is "opened" and items deposited into target SSU. Proximity checks at both endpoints. |
| **Structures** | `StorageUnit` (extension: `LogisticsAuth`), `CargoManifest` object, `Gate` (transit tracking), `Location` (proximity proofs) |
| **Feasibility** | **Medium-Hard** — item lifecycle management (SSU → manifest → SSU) with proximity verification at both ends. ~350 LoC Move. |

### Pattern 13: Time-Locked Gate Schedules

| Aspect | Detail |
|--------|--------|
| **Source** | Chainlink Automation (time-triggered actions) + real-world bridge/ferry schedules |
| **How It Maps** | Gate extension using `Clock::timestamp_ms()` to enforce operating hours. `ScheduleConfig` dynamic field: `open_at_ms`, `close_at_ms`, `timezone_offset`. Permits only issued during open hours. |
| **Structures** | `Gate` (extension: `ScheduleAuth`), `Clock`, `ScheduleConfig` dynamic field |
| **Feasibility** | **Easy** — ~80 LoC Move extension. `Clock` is already available in gate functions. Composable with other rules in a policy engine. |

### Pattern 14: Bounty Board (Kill-to-Earn)

| Aspect | Detail |
|--------|--------|
| **Source** | Loot Survivor (StarkNet roguelike) + bug bounty platforms + EVE Online's bounty system |
| **How It Maps** | `BountyBoard` shared object: anyone can post a bounty (target character + SUI reward). When a `Killmail` matching the target appears, the killer claims the bounty. Verification: `killmail.killer_character_id == claimer_character_id`. |
| **Structures** | `Killmail` (claim verification), `Character` (bounty target + hunter), custom `BountyBoard` shared object, `Coin<SUI>` |
| **Feasibility** | **Easy-Medium** — ~150 LoC. Main challenge: preventing self-kills and ensuring killmail authenticity (admin-created killmails are trustworthy). |

### Pattern 15: Data Marketplace (Location Intelligence Trading)

| Aspect | Detail |
|--------|--------|
| **Source** | Ocean Protocol (data marketplace) + Dark Forest (info asymmetry) + eve-frontier-proximity-zk-poc POD attestation system |
| **How It Maps** | Sell location attestation data (POD data) for SUI. Buyers get cleartext coordinates for specific solar systems/objects. Sellers can prove data validity via ZK proofs without revealing all data. Selective revelation via Merkle inclusion proofs. |
| **Structures** | Custom `DataMarketplace` shared object, ZK PoC's POD attestation system, `Coin<SUI>` |
| **Feasibility** | **Hard** — requires deep integration with ZK PoC's POD/Merkle system. Conceptually elegant (the ZK PoC README explicitly mentions "data marketplace for buying and selling location information"). ~500 LoC Move + TS. |

---

## 5. "Weird/Novel" Ideas

### 5.1 Gate Graffiti Wall (Social Coordination via Jump History)

**Source inspiration:** Ethereum graffiti in block proposer extra_data fields; protest messages on Bitcoin transactions.

**Concept:** Every `JumpEvent` is permanent. Gate operators could allow jumpers to attach a short on-chain message (≤64 bytes) to their jump — stored as a dynamic field on the gate or emitted as an event. Over time, each gate accumulates a "graffiti wall" of messages from travelers. Social coordination tool, protest mechanism, or memorial.

**How it works:** Extension issues `JumpPermit` AND logs a `GraffitiEvent` with the jumper's message. Gate owner can moderate (disable extension, change to new extension that filters). The message is part of the PTB, so it's naturally atomic with the jump.

**Feasibility:** Easy — ~60 LoC extension. Novel social mechanic with no real-world analogue in existing blockchain games.

### 5.2 Proof-of-Presence (ZK Location Check-In)

**Source inspiration:** POAP (Proof of Attendance Protocol) + Dark Forest exploration proofs + Foursquare check-ins.

**Concept:** Players can "check in" at a location by generating a ZK proof (via the ZK PoC) that they were at specific coordinates at a specific time — without revealing the coordinates to anyone else. The check-in produces a `PresenceToken` (on-chain object) that proves "I was within range of Object X at time T." These tokens can gate access, serve as achievements, or be traded.

**How it works:** Player generates a location attestation proof → submits to a `PresenceRegistry` module → receives `PresenceToken` if the proof's coordinates hash matches a known location hash (e.g., a gate or SSU location). The location hash is public (on the structure), but the player's raw coordinates remain private.

**Feasibility:** Medium — leverages existing ZK PoC infrastructure. Novel combination of POAP + ZK + gaming. ~200 LoC Move + circuit reuse.

### 5.3 Dead Drop (Anonymous Item Exchange)

**Source inspiration:** Real-world espionage "dead drop" technique + Tornado Cash privacy pool concept (without the regulatory problems — game items, not financial assets).

**Concept:** An SSU extension that allows anonymous deposits and pickups. Depositor puts items into SSU with a commitment hash (Poseidon hash of a secret). Recipient proves knowledge of the secret (via ZK proof or simple hash preimage) to withdraw. Neither party knows the other's identity. The SSU acts as a "dead drop" — items are exchanged without direct interaction.

**How it works:** 
1. Depositor: `deposit_item<DeadDropAuth>()` with `Poseidon(secret)` stored as metadata
2. Recipient: `withdraw_item<DeadDropAuth>()` by providing `secret` — module computes `Poseidon(secret)` and checks match
3. For full anonymity: use ZK proof of preimage instead of revealing `secret` directly

**Feasibility:** Medium — Poseidon hashing available via `sui::poseidon`. Simple preimage version is ~100 LoC. Full ZK anonymity version requires a custom circuit. Creative combination of game mechanics + privacy tech.

### 5.4 Gate Auction (Dynamic Pricing via Reverse Dutch Auction)

**Source inspiration:** GDA (Gradual Dutch Auction) from DeFi + MEV auction mechanisms + congestion pricing (like London's congestion charge).

**Concept:** Gate toll price changes dynamically based on traffic. High traffic → price rises (congestion pricing). Low traffic → price drops to attract jumpers. Implemented as a reverse Dutch auction: toll starts high after each jump and decays over time until the next jump resets it. Creates natural price discovery for high-demand gates.

**How it works:** `AuctionConfig` dynamic field stores: `base_price`, `surge_multiplier`, `decay_rate_per_ms`, `last_jump_timestamp`. On each `issue_jump_permit<AuctionAuth>()` call, compute current price: `price = max(base_price, surge_multiplier * base_price * decay_function(now - last_jump))`. Accept `Coin<SUI> >= price`.

**Feasibility:** Easy-Medium — ~120 LoC Move. Mathematically interesting (exponential decay in integer arithmetic). No standard library needed — simple timestamp math. Novel pricing mechanism in gaming context.

### 5.5 Cross-Game Identity Bridge (EVE Frontier × External Attestation)

**Source inspiration:** Gitcoin Passport + Worldcoin + Sismo (ZK attestation) + LayerZero (cross-chain messaging).

**Concept:** Gate/SSU access gated by attestations from external systems. Examples: "Prove you own a specific NFT on Ethereum" (via bridge/oracle), "Prove you have > 1000 hours in EVE Online" (via OAuth attestation), "Prove your Twitter/Discord reputation score > X" (via oracle). Creates cross-game and cross-platform identity composability.

**How it works:** `AttestationRegistry` shared object stores verified claims (attestation type + character_id + verification timestamp). Oracle/relayer submits attestation proofs from external sources. Gate/SSU extensions check attestation registry before granting access.

**Feasibility:** Hard — requires oracle infrastructure or bridge. MVP with self-attested claims (admin-verified) is ~200 LoC. Full trustless version needs cross-chain messaging. Conceptually powerful — brings external identity into EVE Frontier's trust model.

---

## 6. Summary Matrix: All Patterns Ranked

| # | Pattern | Source Category | Structures | Feasibility | Player Value | Novelty |
|---|---------|----------------|------------|-------------|--------------|---------|
| 1 | Toll Gate | DeFi + corpse bounty example | Gate | Easy | High | Low |
| 2 | Multi-Rule Policy Engine | DAO tooling (Zodiac, Hats) | Gate + Clock | Medium | Very High | Medium |
| 3 | Corp Access Manager | RBAC (Hats Protocol) | Gate + SSU | Medium | Very High | Medium |
| 4 | SSU Marketplace | DEX (Deepbook, Econia) | SSU | Medium | Very High | Medium |
| 5 | ZK-Gated Access | Dark Forest, ZK PoC | Gate + Groth16 | Hard | High | High |
| 6 | Escrow Trading | Flash loans, hot-potato | SSU | Medium | High | Medium |
| 7 | Fuel Futures | Liquid staking (Aftermath) | NWN | Medium | Medium | High |
| 8 | Alliance Registry | DAO governance (Snapshot X) | Gate + Character | Medium | High | Medium |
| 9 | Killmail Analytics | zKillboard, Dune Analytics | Killmail | Easy | High | Low |
| 10 | Structure Insurance | DeFi insurance (Nexus Mutual) | Killmail + pool | Medium-Hard | Medium | High |
| 11 | Reputation Ledger | Gitcoin Passport, Dark Forest | Character + all | Medium | High | Medium |
| 12 | Cargo Manifest | Space MMOs (Influence) | SSU + Gate | Medium-Hard | Medium | Medium |
| 13 | Time-Locked Schedules | Chainlink Automation | Gate + Clock | Easy | Medium | Low |
| 14 | Bounty Board | Roguelikes, EVE Online | Killmail + SUI | Easy-Medium | High | Medium |
| 15 | Data Marketplace | Ocean Protocol, ZK PoC | ZK PODs | Hard | High | Very High |
| W1 | Gate Graffiti Wall | Ethereum block graffiti | Gate | Easy | Medium | Very High |
| W2 | Proof-of-Presence | POAP + ZK + Dark Forest | ZK PoC | Medium | Medium | Very High |
| W3 | Dead Drop | Espionage + privacy pools | SSU + Poseidon | Medium | Medium | Very High |
| W4 | Gate Auction | GDA, congestion pricing | Gate + Clock | Easy-Medium | High | High |
| W5 | Cross-Game Identity | Gitcoin Passport, oracles | Gate + oracle | Hard | High | Very High |

---

## 7. Recommended Hackathon Focus Areas

### Tier 1: "Win the Hackathon" (High impact, demonstrable, feasible in 20 days)

1. **Gate Policy Engine + Dashboard** (Patterns 2 + 9 + 13) — Composable gate rules with killmail-informed threat detection and time scheduling. Visual policy builder + monitoring dashboard. Demonstrates deep integration with world-contracts.

2. **SSU Marketplace + Escrow** (Patterns 4 + 6) — Player-driven economy layer with trustless item trading. Most directly addresses EVE Frontier's missing marketplace primitive.

3. **Corp Access Manager + Alliance Network** (Patterns 3 + 8) — Multi-role permissions for organized play. Directly solves the most-requested community feature (multi-owner access).

### Tier 2: "Technical Wow Factor" (Showcase ZK / novel patterns)

4. **ZK-Gated Access + Dead Drop + Data Marketplace** (Patterns 5 + W3 + 15) — Privacy-as-a-feature: anonymous gate access, anonymous item exchange, location intelligence trading. Full use of the ZK PoC infrastructure. Highest novelty score.

5. **Gate Auction + Toll Gate** (Patterns W4 + 1) — Dynamic pricing for gate access. Elegant combination of DeFi mechanism design with gaming infrastructure. Mathematically interesting, easy to implement.

### Tier 3: "Community Impact" (Long-term ecosystem value)

6. **Reputation Ledger + Bounty Board + Killmail Intelligence** (Patterns 11 + 14 + 9) — Social layer for EVE Frontier: reputation scoring, bounty hunting, threat intelligence. Creates the metagame layer.

---

*Research compiled from: Sui Overflow 2024, Sui Builder House series, Dorahacks Build on Sui, Aptos World Tour, ETHGlobal gaming tracks, Chainlink Constellation, Dark Forest (Ethereum), Influence (StarkNet), Primodium (L2), Zodiac (Gnosis), Hats Protocol, world-contracts source, eve-frontier-proximity-zk-poc, builder-scaffold, evevault reference architecture, player-value-ux-analysis.md findings, CCP Games press releases, EVE Frontier builder documentation references.*
