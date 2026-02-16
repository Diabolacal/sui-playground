# EVE Frontier Hackathon — V2 Ideas: Documentation-Enabled

**Retention:** Archive

> **Archived:** Superseded by [hackathon-ideas-grounded-v3-judged.md](../../ideas/hackathon-ideas-grounded-v3-judged.md). All 8 doc-enabled ideas (IDs 21–28) are incorporated in the v3 scored list.

> **Purpose:** New hackathon ideas specifically enabled by Sui-level or EVE Frontier GitBook knowledge that wasn't incorporated in the [v1 ideas document](hackathon-ideas-grounded.md). Every idea here maps to a specific Sui feature or GitBook insight absent from the original 20 ideas.
>
> **Generated:** 2026-02-15 | **Methodology:** Cross-referenced `docs/research/sui-documentation-reference-map.md` and `docs/research/evefrontier-builder-docs-map.md` against all 20 v1 ideas to identify unused Sui primitives and GitBook patterns.

---

## What's Different from V1

The v1 ideas use these Sui features: dynamic fields, PTBs, hot-potato patterns, Clock, events, Groth16 ZK, SUI Coin transfers, sponsored transactions.

The v1 ideas do **NOT** use: Kiosk standard, on-chain randomness (`sui::random`), Display standard, storage rebates as a mechanic, `Coin<T>` custom tokens, transfer policies, Tables/Bags, UpgradeCap iteration, zkLogin as a product feature, or GraphQL as a differentiated API layer.

Each idea below is grounded in at least one of these unused features.

---

## New Idea 1: Loot Crate — Randomized Item Drops from SSUs

- **One-liner:** Players deposit items into a "crate SSU," and anyone can pay to open it and receive a random item from the pool — using Sui's on-chain VRF randomness.
- **Why it's new:** `sui::random::Random` (VRF-based on-chain randomness) is documented in the Sui reference map but unused in all 20 v1 ideas. This enables probabilistic game mechanics that are verifiably fair — no server-side RNG, no trust required. The randomness calling convention (special `entry` function, cannot compose in PTBs) creates a unique design constraint that shapes the entire architecture.
- **Viability:** Yellow — the randomness calling convention (`entry fun` with `&Random`, non-composable in PTBs) means the "open crate" action must be a standalone entry function. The hot-potato `borrow_owner_cap` pattern used for SSU operations may conflict with the randomness constraint. Workaround: the crate module holds items independently (not inside a world-contracts SSU inventory) or uses a two-step flow (commit-reveal via randomness, then claim via separate PTB).
- **Required primitives:** StorageUnit (for depositing items into the crate pool), Item (the objects being randomized), custom `LootCrate` module with item pool and probability tables
- **Sui features used:** `sui::random::Random` (VRF randomness), `Coin<SUI>` (payment to open), Events (emit `CrateOpenedEvent` with result)
- **Proof/auth model:** Anyone can deposit items (permissionless contributes to pool). Opening costs SUI. Randomness is chain-provided and verifiable. Owner configures probability weights via OwnerCap.
- **Minimal demo path:** Deploy a `LootCrate` shared object holding 5 different item types with equal probability. Build a web page showing crate contents + odds. "Open Crate" button calls the `entry` function with `&Random`, emits an event with the won item, and transfers it to the caller.
- **Key risk:** The `&Random` calling convention may prevent combining randomness with SSU `withdraw_item` in a single PTB, forcing items to live outside the SSU inventory system (breaking immersion).

---

## New Idea 2: Kiosk Bazaar — Protocol-Native Item Marketplace with Royalties

- **One-liner:** A marketplace for EVE Frontier items using Sui's native Kiosk standard, with enforced transfer policies that route royalties to item creators and configurable trade restrictions per item type.
- **Why it's new:** The Sui Kiosk standard is explicitly documented in the reference map as "not referenced in world-contracts" and "essential if a hackathon idea involves item exchange." V1 Idea 3 (SSU Storefront) builds a *custom* extension-based marketplace, but it doesn't use Kiosk or transfer policies at all. Kiosk is a fundamentally different architecture: it's a Sui protocol primitive with built-in listing/purchasing/delisting mechanics and composable transfer policy enforcement. This means royalties, trade restrictions, and allowlists are protocol-enforced — not application-enforced.
- **Viability:** Yellow — Items must be extracted from SSU inventories (dynamic fields) into standalone objects to list in a Kiosk. The `Item` struct has `key + store` which is Kiosk-compatible, but the SSU → Kiosk bridge flow needs careful design. Transfer policies require a `Publisher` object (obtained at package publish time).
- **Required primitives:** StorageUnit (`withdraw_item` to extract items), Item (has `key + store` — compatible with Kiosk), custom `TransferPolicy<Item>` with royalty rules
- **Sui features used:** `sui::kiosk::Kiosk` (listing/purchasing), `sui::transfer_policy::TransferPolicy` (royalties, restrictions), `sui::kiosk::KioskOwnerCap` (marketplace management), `sui::display::Display<Item>` (rich item rendering in marketplace UI)
- **Proof/auth model:** Seller extracts item from SSU via extension witness, lists in personal Kiosk. Buyer purchases via Kiosk protocol (SUI payment). Transfer policy enforces royalty split. No gate/location proofs needed.
- **Minimal demo path:** Create a `TransferPolicy<Item>` with a 5% royalty rule. Withdraw 3 items from an SSU, list them in a Kiosk with prices. Build a web UI showing listings. "Buy" button triggers Kiosk purchase + transfer policy resolution. Show royalty flowing to creator address.
- **Key risk:** The Item struct is defined in world-contracts (not our package), so creating a `TransferPolicy<Item>` may require the `Publisher` object from the world-contracts package — which we may not have. Workaround: wrap items in a custom type or fork.

---

## New Idea 3: Salvage Protocol — Storage Rebate Bounties for Abandoned Structures

- **One-liner:** A cleanup-incentive protocol where players earn SUI for decommissioning abandoned structures — funded by Sui's storage rebate mechanism that returns deposited SUI when objects are deleted.
- **Why it's new:** Storage rebates are documented in the Sui reference map ("incentivizes cleanup — `unanchor()` destroying assemblies") but no v1 idea leverages this economic mechanism. This creates a genuinely new gameplay loop: structures cost SUI to exist (storage fees), and that SUI is returned when the structure is deleted. The Salvage Protocol adds a bounty layer so anyone can profit from cleaning up abandoned space infrastructure.
- **Viability:** Green — `unanchor()` exists in world-contracts and destroys assembly objects. Storage rebates are automatic Sui-level behavior. The bounty-posting and claim mechanics are straightforward Move. Main question: does the rebate go to the transaction sender or the object owner? (Sui docs: rebate goes to the transaction sender's gas coin.)
- **Required primitives:** Gate/StorageUnit/NetworkNode (`unanchor()` for destruction), access control (OwnerCap needed for unanchor — a delegation mechanism is required for third-party cleanup), custom `SalvageBounty` module
- **Sui features used:** Storage rebates (automatic SUI return on object deletion), `Coin<SUI>` (bounty escrow), Events (emit `SalvageClaimEvent`)
- **Proof/auth model:** Structure owner posts a "salvage order" (delegates unanchor authority + posts optional bonus bounty). Any player can execute the salvage. The salvager receives: (a) Sui storage rebate (automatic) + (b) posted bounty (from escrow). Alternatively, an "abandonment detection" heuristic (offline for N days + no fuel) triggers eligibility.
- **Minimal demo path:** Deploy 3 structures, let one go offline (no fuel). Owner posts a salvage bounty via the protocol. A different account claims the bounty, executing `unanchor()`. Show the storage rebate + bounty flowing to the salvager's address. Display a "salvage board" in a web UI.
- **Key risk:** `unanchor()` likely requires the OwnerCap, so delegating destruction authority to a third party needs a capability-passing mechanism (similar to multi-sig pattern in Idea 19, but simpler — one-time delegation).

---

## New Idea 4: Faction Mint — Tribe-Specific Custom Currencies

- **One-liner:** Each tribe/faction mints its own on-chain currency using Sui's `Coin<T>` standard, creating a parallel economy where gate tolls, SSU trades, and bounties can be denominated in faction tokens.
- **Why it's new:** V1 ideas use `Coin<SUI>` for payments (Insurance Idea 10, Bounty Idea 12, Storefront Idea 3) but no idea creates *custom tokens*. The Sui reference map documents `Coin<T>` / `TreasuryCap<T>` as "foundation for any custom token" and notes "world-contracts has no coin/token module." The GitBook mentions LUX and EVE Token as planned currencies but they don't exist in code. This idea fills that gap at the faction level — each tribe has its own economy.
- **Viability:** Green — `Coin<T>` creation is a well-documented, simple Move pattern (one-time witness + `coin::create_currency()`). TreasuryCap governance maps cleanly to OwnerCap patterns. Integration with gate tolls or SSU trades requires the extension layer to accept `Coin<FactionToken>` instead of `Coin<SUI>`.
- **Required primitives:** Character (`tribe_id` for faction membership), Gate extension (accept faction currency as toll), SSU extension (price items in faction currency), custom `FactionMint` module with `TreasuryCap<FACTION_A>`, etc.
- **Sui features used:** `sui::coin::Coin<T>` (custom currency), `sui::coin::TreasuryCap<T>` (minting authority), one-time witness pattern (coin creation), `sui::coin::CoinMetadata` (name, symbol, decimals, icon)
- **Proof/auth model:** Tribe leader holds `TreasuryCap<TRIBE_TOKEN>` — controls minting. Members earn tokens via tribe activities (deposits, gate maintenance, bounties). Tokens are spent on inter-tribe commerce or intra-tribe services. Exchange rate between faction tokens and SUI is market-determined (manual OTC or Kiosk-based swap).
- **Minimal demo path:** Deploy two faction currencies (e.g., `ALPHA_COIN` and `BETA_COIN`). Mint tokens to respective tribe members. Deploy a gate extension that accepts `ALPHA_COIN` as toll. Show: Alpha member pays toll in tribe currency → jumps. Beta member doesn't hold Alpha tokens → denied. Build a simple web UI showing balances and a "pay toll" flow.
- **Key risk:** Multiple custom Coin types make PTB construction more complex (must handle merge/split per token type). If the ecosystem grows, token fragmentation could harm liquidity. Also, gate/SSU extensions must be parameterized by coin type (generics in Move).

---

## New Idea 5: Zero-Friction Portal — zkLogin + Sponsored Tx Onboarding dApp

- **One-liner:** A gasless "try EVE Frontier in 30 seconds" web app where new players authenticate with Google (zkLogin), get a sponsored transaction for their first gate jump, and see their character on-chain — no wallet, no gas, no seed phrase.
- **Why it's new:** The Sui reference map documents zkLogin as mapping "OAuth identity → deterministic Sui address" and the GitBook documents the sponsored transaction pattern (`setSender(player)` + `setGasOwner(sponsor)`). No v1 idea combines these two features into an onboarding product. V1 ideas assume players already have wallets and SUI. This idea targets the *pre-player* funnel — converting a curious visitor into an on-chain participant in one click.
- **Viability:** Yellow — zkLogin requires an external prover (Mysten Enoki or self-hosted) and an OAuth provider (FusionAuth for production, Google for sandbox). The `builder-scaffold/zklogin/` directory contains a working TypeScript implementation. Sponsored transactions require `AdminACL` configuration. The combination is well-documented but involves multiple external dependencies.
- **Required primitives:** Character (create for new player), Gate (first jump as demo interaction), AdminACL (sponsor configuration), zkLogin scaffold (`vendor/builder-scaffold/zklogin/`)
- **Sui features used:** zkLogin (OAuth → Sui address), sponsored transactions (gasless UX), PTBs (combine character creation + gate jump in one tx)
- **Proof/auth model:** Player authenticates via Google OAuth → JWT → zkLogin proof → deterministic Sui address. dApp constructs a PTB (create character + jump through a demo gate). dApp's admin account sponsors gas. Player signs with an ephemeral key (derived from zkLogin). Result: player sees their character + jump event on a dashboard — zero crypto knowledge required.
- **Minimal demo path:** Deploy world-contracts on local devnet. Set up a local Google OAuth app (or mock the JWT flow). Build a landing page: "Sign in with Google" → character appears → "Jump through this gate" → sponsored tx executes → show result. Total flow: 3 clicks.
- **Key risk:** External prover dependency (Enoki) may not be available or may require API keys. Local mocking of zkLogin is possible but reduces authenticity. FusionAuth (the production OAuth provider) requires credentials we don't have.

---

## New Idea 6: Fortune Gate — Probabilistic Jump Access via On-Chain Randomness

- **One-liner:** A gate extension where the outcome of each jump attempt is probabilistic — configurable chance of success, denial, bonus reward, or random toll amount — using Sui's VRF-based on-chain randomness.
- **Why it's new:** V1 Idea 1 (Gate Policy Engine) creates *deterministic* rules (tribe filter, time window, fixed toll). This idea introduces *non-deterministic* gate behavior using `sui::random::Random`, which isn't used in any v1 idea. The Sui reference map explicitly notes the randomness calling convention constraint (special `entry` function, cannot compose in PTBs), which creates a unique design challenge for gate extensions.
- **Viability:** Yellow — The `&Random` parameter requires a special `entry` function signature. Since `gate::issue_jump_permit()` is the existing permit mechanism, the randomness check must happen *before* or *alongside* permit issuance. This may require a two-step flow: (1) call randomness `entry` function to generate outcome + commit, (2) call normal gate flow based on committed outcome. Alternatively, build a self-contained gate that doesn't use the standard permit system.
- **Required primitives:** Gate (`authorize_extension`, potentially bypass standard permit flow), custom `FortuneGate` module with outcome tables (deny, allow, allow+bonus, varied toll)
- **Sui features used:** `sui::random::Random` (VRF randomness), `sui::random::RandomGenerator` (per-tx generator), Events (emit `FortuneOutcomeEvent` with result)
- **Proof/auth model:** Gate owner configures probability table (e.g., 70% pass, 15% deny, 10% half-toll, 5% free pass). Player calls the `entry` function with `&Random`. Module generates outcome, emits event, and either issues permit or denies. OwnerCap for configuration.
- **Minimal demo path:** Deploy a fortune gate with simple probability: 80% success, 20% denial. Build a web UI showing the probability table and a "Try Your Luck" button. Execute 10 jumps, display outcomes in a log. Show that outcomes are verifiably random (VRF proof on-chain).
- **Key risk:** If randomness can't compose with the existing gate permit system, the module may need to reimplement gate jump logic (duplicating core assembly code), which is fragile and harder to maintain.

---

## New Idea 7: Trophy Case — Item Display Registry for Wallet Visibility

- **One-liner:** A Move module + web tool that applies Sui's Display standard to EVE Frontier items, making them visible with rich metadata (name, image, description, rarity) in any Sui wallet or explorer — plus a player-facing "trophy case" gallery.
- **Why it's new:** The Sui reference map explicitly notes that "world-contracts Item doesn't implement `sui::display::Display<T>`" and that "without Display, objects appear as raw structs in explorers." No v1 idea addresses this gap. Every item-centric idea (Storefront, Dead Drop, Corpse Toll, Loot Crate) would benefit from Display, but none implement it. This is the foundational visual layer.
- **Viability:** Green — Display is a well-documented Sui standard. Templates are managed on-chain via the `Publisher` object. The main constraint is that Display templates require the `Publisher` from the package that defined the type — since `Item` is in world-contracts, we'd need either (a) the world-contracts Publisher, (b) a wrapper type with its own Publisher, or (c) a community Display registry pattern.
- **Required primitives:** Item (the display target), custom wrapper type if direct Display on `Item` isn't possible, Character (for "my items" gallery)
- **Sui features used:** `sui::display::Display<T>` (rich object metadata), `sui::package::Publisher` (Display template management), `sui::display::new()` / `sui::display::set()` (template configuration)
- **Proof/auth model:** The Display template is set once by the package publisher. No per-item auth needed — Display applies to all objects of the type. Gallery view is read-only (no proofs).
- **Minimal demo path:** Publish a package with a `TrophyItem` wrapper type. Create a `Display<TrophyItem>` template with name, description, image_url fields. Mint 5 trophy items with different metadata. Show them rendering in Sui Explorer / wallet with rich display. Build a web gallery page querying owned items.
- **Key risk:** If the goal is to display *real* world-contracts Items (not custom wrappers), we need the world-contracts `Publisher` object — which may not be accessible in sandbox. Wrapper approach works but adds indirection.

---

## New Idea 8: Extension Forge — Upgradeable Smart Assembly Extensions with Safe Iteration

- **One-liner:** A developer framework and toolkit for publishing gate/SSU extensions with upgrade-safe patterns, using Sui's UpgradeCap policies to iterate on extension logic post-deploy without re-registering.
- **Why it's new:** The Sui reference map documents UpgradeCap with "compatible, additive, dependency-only" upgrade policies and notes it's relevant for "post-deploy iteration." No v1 idea addresses the *developer experience* of building extensions — all 20 ideas assume "deploy and done." In reality, hackathon builders will need to iterate rapidly, and understanding upgrade constraints is critical. This is a meta-tool that makes every other idea more practical.
- **Viability:** Green — Package upgrades are a core Sui feature. The key insight: `compatible` upgrades allow adding new functions and types without breaking existing callers. This means an extension can add new rule types, fix bugs, or extend state *after* it's already registered on a gate/SSU — if designed with upgrade-safety in mind from the start.
- **Required primitives:** Gate and SSU extension pattern (witness types, `authorize_extension`), UpgradeCap (held by deployer), custom extension template with upgrade-safe state design
- **Sui features used:** `sui::package::UpgradeCap` (upgrade authority), upgrade policies (compatible, additive, dependency-only), `sui::package::authorize_upgrade()` / `sui::package::commit_upgrade()`
- **Proof/auth model:** Extension developer holds UpgradeCap. Upgrades are authorized by the cap holder. Gate/SSU owners who registered the extension automatically use the latest version (Move packages resolve to the latest compatible version). No player-facing auth changes.
- **Minimal demo path:** Publish a v1 gate extension (simple tribe filter). Register it on a gate. Then publish a v2 upgrade (add time-window rule) using `compatible` policy. Show the gate now enforcing both tribe + time rules without re-registration. Build a CLI tool or web UI for managing upgrades.
- **Key risk:** Extension re-registration behavior after upgrade needs testing — does the gate still recognize the extension's witness type after a compatible upgrade? If the witness type's module changes, the authorization may break. Needs devnet validation.

---

## Filtered Recommendations: Top 5

### Keep: New Idea 4 — Faction Mint (Custom Currencies)

**Why keep:** Highest impact-to-effort ratio. `Coin<T>` is a simple, well-documented pattern. Creates an entirely new economic layer that *composes* with multiple v1 ideas (gate tolls in faction currency, SSU trades in faction currency, bounties in faction currency). Demonstrates understanding of Sui's token standard. Green viability. Strong judge story: "We gave every tribe its own economy."

**Risk:** Medium — generics in extension code add complexity but are manageable.

### Keep: New Idea 2 — Kiosk Bazaar (Protocol-Native Marketplace)

**Why keep:** Fundamentally different architecture from v1 Idea 3 (SSU Storefront). Using Kiosk shows the builder understands Sui's native commerce protocol, not just custom escrow. Transfer policies with royalties are a powerful demo ("item creator earns 5% on every resale"). Judge differentiation: "We used Sui's Kiosk standard — the protocol-native way to trade."

**Risk:** Yellow — Items bridging from SSU to Kiosk needs design work. `Publisher` requirement for transfer policies may be a blocker.

### Keep: New Idea 1 — Loot Crate (Randomized Drops)

**Why keep:** `sui::random` is a marquee Sui feature that no v1 idea uses. Loot crates are universally understood by gamers and hackathon judges. The calling convention constraint (`entry fun` + `&Random`) forces a creative architecture that demonstrates deep Sui knowledge. Verifiable fairness is a strong narrative.

**Risk:** Yellow — randomness + hot-potato interaction is uncertain. May need items outside SSU inventory.

### Keep: New Idea 5 — Zero-Friction Portal (zkLogin + Sponsored Tx Onboarding)

**Why keep:** Solves the biggest adoption problem in all blockchain gaming: onboarding friction. Combines two documented-but-unused features (zkLogin + sponsored tx) into a product that every other hackathon project would want to embed. The builder-scaffold already has zkLogin TypeScript code. Judge story: "Any player can try EVE Frontier in 30 seconds with just a Google account."

**Risk:** Yellow — external prover dependency. But the conceptual demo (even with mocked JWT) is compelling.

### Keep: New Idea 3 — Salvage Protocol (Storage Rebate Bounties)

**Why keep:** Uses a Sui economic primitive (storage rebates) as a *gameplay mechanic* — genuinely creative. Creates a cleanup-incentive loop that the ecosystem actually needs (abandoned structures waste storage). Simple to implement. Judge story: "We turned Sui's gas economics into gameplay — players earn money by cleaning up space junk."

**Risk:** Low — storage rebates are automatic. Main complexity is delegating `unanchor()` authority.

### Cut: New Idea 6 — Fortune Gate (Probabilistic Jumps)

**Why cut:** Same `sui::random` feature as Loot Crate, but weaker narrative. "Random gate access" is more frustrating than fun — players want reliability from infrastructure. The calling convention constraint is harder to solve for gates (tighter integration with permit system) than for SSUs (self-contained crate). Keep Loot Crate as the randomness showcase.

### Cut: New Idea 7 — Trophy Case (Display Registry)

**Why cut:** Important infrastructure but thin as a standalone hackathon entry. Better positioned as a *feature within* another idea (e.g., Kiosk Bazaar items have Display, Loot Crate drops have Display). The Publisher requirement for world-contracts Items may be a hard blocker that reduces it to wrapper types only.

### Cut: New Idea 8 — Extension Forge (Upgradeable Extensions)

**Why cut:** Developer tooling doesn't demo well at hackathons — judges want player-facing features. UpgradeCap is important knowledge but the "wow" moment is weak: "we upgraded an extension without re-registering" is niche. Better as a *technique documented in a README* than a standalone project.

---

## Summary Table

| # | Name | Sui Feature | Viability | Rec |
|---|------|-------------|-----------|-----|
| 1 | Loot Crate | `sui::random` | Yellow | **KEEP** |
| 2 | Kiosk Bazaar | Kiosk + Transfer Policies | Yellow | **KEEP** |
| 3 | Salvage Protocol | Storage Rebates | Green | **KEEP** |
| 4 | Faction Mint | `Coin<T>` Custom Tokens | Green | **KEEP** |
| 5 | Zero-Friction Portal | zkLogin + Sponsored Tx | Yellow | **KEEP** |
| 6 | Fortune Gate | `sui::random` | Yellow | Cut (overlap w/ #1) |
| 7 | Trophy Case | `sui::display::Display` | Green | Cut (thin standalone) |
| 8 | Extension Forge | UpgradeCap | Green | Cut (weak demo) |

---

## Cross-Reference: V2 Ideas vs V1 Ideas

| V2 Idea | Nearest V1 Idea | Why It's Different |
|---------|-----------------|-------------------|
| Loot Crate | #3 SSU Storefront | Storefront is deterministic buy/sell; Loot Crate is probabilistic VRF drops |
| Kiosk Bazaar | #3 SSU Storefront | Storefront uses custom extension escrow; Kiosk uses Sui's native marketplace protocol with transfer policies |
| Salvage Protocol | #17 Energy Arbitrage | Energy Arbitrage optimizes uptime; Salvage Protocol incentivizes *destruction* via storage rebates |
| Faction Mint | #8 Corpse Toll Road | Corpse Toll uses SUI payment; Faction Mint creates new tribe-specific currencies |
| Zero-Friction Portal | None | No v1 idea addresses player onboarding or uses zkLogin as a product feature |

---

## Appendix: Sui Features Coverage (V1 + V2 Combined)

| Sui Feature | V1 Usage | V2 Usage |
|-------------|----------|----------|
| Dynamic Fields | Ideas 1, 3, 7, 8, 14, 16 | — |
| PTBs / Hot-Potato | Ideas 1, 3, 5, 7, 8, 17, 19 | Ideas 1, 2, 4 |
| Clock | Ideas 11, 17 | — |
| Events | Ideas 2, 4, 6, 13, 20 | Ideas 1, 3, 6 |
| Groth16 ZK | Ideas 5, 9, 18 | — |
| `Coin<SUI>` transfers | Ideas 3, 10, 12 | Ideas 1, 3 |
| Sponsored Tx | (assumed in many) | Idea 5 (core feature) |
| **`sui::random`** | **Not used** | **Ideas 1, 6** |
| **Kiosk + Transfer Policies** | **Not used** | **Idea 2** |
| **Storage Rebates** | **Not used as mechanic** | **Idea 3** |
| **`Coin<T>` Custom Tokens** | **Not used** | **Idea 4** |
| **zkLogin** | **Not used as product** | **Idea 5** |
| **`Display<T>`** | **Not used** | **Idea 7** |
| **UpgradeCap** | **Not used** | **Idea 8** |

---

*Generated by LLM research agent from `docs/research/sui-documentation-reference-map.md`, `docs/research/evefrontier-builder-docs-map.md`, and `docs/ideas/hackathon-ideas-grounded.md`. No code was written; no commits were made.*
