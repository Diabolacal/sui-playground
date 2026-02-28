# Hackathon Ideas V3 — Judging-Aligned Rankings

**Retention:** Carry-forward

> **Version:** V3 (judging-optimized)
> **Date:** 2026-02-15
> **Inputs:** V2-grounded (25 ideas), V2-doc-enabled (8 ideas), world-contracts source, Sui docs, web research
> **Purpose:** Rank all 28 unique ideas against official judging criteria + player vote; recommend a cohesive CivilizationControl module suite for submission.

---

## A) Executive Summary

### What V3 Adds Over V2

V2 established technical feasibility (Green/Yellow/Red verdicts) and identified the top-5 ideas by implementation risk. V3 layers three new dimensions:

1. **Judging rubric alignment** — Each of the 8 official criteria scored 0–10, producing a composite ranking that predicts actual judge behavior, not just technical viability.
2. **Player vote optimization (25% of score)** — Scored separately for shareability, wow factor, immediate utility, and memetic potential. Player vote flips several rankings versus judge-only scoring.
3. **Web research heuristics** — 15 actionable patterns from web3 gaming hackathon winners applied to calibrate scores and identify demo strategies.

### Recommended Primary Entry: CivilizationControl

A cohesive 3-module system (+ 1 stretch) that functions as an **infrastructure management dashboard** for EVE Frontier builders:

| Priority | Module | Draws From | Feasibility |
|----------|--------|-----------|-------------|
| 1 | **GateControl** — Composable gate policy engine | ID 1 + ID 8 + ID 14 | Green |
| 2 | **TradePost** — SSU storefront with atomic escrow | ID 3 | Yellow |
| 3 | **TribeMint** — Faction currency system | ID 24 | Green |
| Stretch | **LootDrop** — VRF randomized crate rewards | ID 21 | Yellow |

This suite maximizes "Mod Design" (system, not one-off), demonstrates 3 distinct Sui patterns (dynamic fields, PTB composition, Coin standard), and the demo storyline shows economic feedback loops flowing through all modules.

---

## B) Scoring Framework

### Judging Criteria (75% of total)

| # | Criterion | Weight | What 10/10 Looks Like |
|---|-----------|--------|----------------------|
| 1 | Concept & Feasibility | 12.5% | Identifies a real, felt pain point; proven prototype; clear adoption rationale |
| 2 | Mod Design | 12.5% | Composable system other builders can extend; handles adversarial multiplayer |
| 3 | Concept Implementation | 12.5% | Deployed on testnet, functional end-to-end, typed Move code with events |
| 4 | Player Utility | 12.5% | Immediately changes how players operate; quantifiable time/value improvement |
| 5 | Frontier Relevance & Vibe | 12.5% | Born from playing EVE Frontier; extensions of alliances, betrayal, economics |
| 6 | Creativity & Originality | 12.5% | Unique intersection of Sui object model + EVE gameplay nobody else attempted |
| 7 | UX & Usability | 12.5% | Blockchain hidden; game-relevant UI; sponsored tx; mobile-aware |
| 8 | Visual Presentation & Demo | 12.5% | Story-driven: problem → player encounter → demonstrated solve; memorable moment. Demo is submitted as a recorded video (re-recordable), so narrative clarity and visual polish matter more than live execution stability |

### Player Vote (25% of total)

| Score | Description |
|-------|-------------|
| 9–10 | Players would share the clip unprompted; immediate "I want this NOW" reaction |
| 7–8 | Players understand and appreciate it; would vote if they saw it |
| 5–6 | Technically interesting but low emotional engagement |
| 3–4 | Too abstract, too developer-focused, or requires explanation |
| 1–2 | Players scroll past; infrastructure/tooling with no player-facing hook |

### Composite Formula

```
Judge Average = mean(Concept, ModDesign, Implementation, PlayerUtility,
                     FrontierVibe, Creativity, UX, Demo)

Weighted Total = (Judge Average × 0.75) + (Player Vote × 0.25)
```

### Common Failure Modes (What Gets a 3/10)

- **Concept:** Generic DeFi concept that mentions EVE Frontier; no prototype
- **Mod Design:** Monolithic script; no separation; ignores adversarial environment
- **Implementation:** Code compiles but key features are stubbed; no deployment evidence
- **Player Utility:** "Players could use this..." but no player would bother
- **Frontier Vibe:** Could be deployed on any chain for any game
- **Creativity:** Tutorial with minor modifications; "Uniswap but for EVE"
- **UX:** CLI-only with raw JSON; requires knowing object IDs
- **Demo:** Slide-heavy, no working demonstration, unclear narrative, or excessively long
- **Player Vote:** Spreadsheet UI; developer tool; requires whitepaper to understand

---

## C) Ranked List — Top 10 by Weighted Total

### Scoring Table (All 28 Ideas)

| Rank | ID | Title | Con | Mod | Imp | Ply | Vib | Cre | UX | Dem | Judge Avg | PVote | **Weighted** | Risk |
|------|-----|-------|-----|-----|-----|-----|-----|-----|-----|-----|-----------|-------|-------------|------|
| 1 | 1 | Gate Policy Engine | 9 | 10 | 8 | 9 | 9 | 7 | 8 | 9 | 8.63 | 6 | **7.97** | Green |
| 2 | 3 | SSU Storefront | 8 | 8 | 7 | 8 | 9 | 7 | 8 | 8 | 7.88 | 8 | **7.91** | Yellow |
| 3 | 8 | Corpse Toll Road | 8 | 7 | 9 | 7 | 9 | 6 | 7 | 8 | 7.63 | 8 | **7.72** | Green |
| 4 | 21 | Loot Crate | 8 | 7 | 6 | 8 | 6 | 8 | 8 | 8 | 7.38 | 8 | **7.53** | Yellow |
| 5 | 7 | Alliance Gate Network | 9 | 8 | 5 | 8 | 10 | 8 | 6 | 8 | 7.75 | 7 | **7.56** | Yellow |
| 6 | 5 | ZK Gate Pass | 9 | 8 | 5 | 5 | 7 | 10 | 5 | 9 | 7.25 | 7 | **7.19** | Green¹ |
| 7 | 14 | Tribal Diplomacy | 8 | 7 | 6 | 7 | 9 | 7 | 6 | 7 | 7.13 | 6 | **6.84** | Yellow |
| 8 | 12 | Bounty Board | 8 | 6 | 4 | 8 | 9 | 6 | 6 | 6 | 6.63 | 8 | **6.97** | Yellow |
| 9 | 23 | Salvage Protocol | 7 | 6 | 7 | 5 | 9 | 9 | 6 | 6 | 6.88 | 5 | **6.41** | Green |
| 10 | 24 | Faction Mint | 7 | 7 | 7 | 7 | 8 | 6 | 5 | 7 | 6.75 | 5 | **6.31** | Green |
| 11 | 4 | Killmail Intelligence | 7 | 3 | 6 | 7 | 8 | 5 | 7 | 7 | 6.25 | 7 | **6.44** | Green |
| 12 | 9 | Dead Drop | 8 | 7 | 4 | 5 | 8 | 9 | 4 | 7 | 6.50 | 6 | **6.38** | Yellow |
| 13 | 18 | Proof-of-Presence Badge | 7 | 5 | 5 | 6 | 6 | 8 | 7 | 7 | 6.38 | 7 | **6.53** | Yellow |
| 14 | 22 | Kiosk Bazaar | 7 | 7 | 5 | 7 | 6 | 7 | 7 | 6 | 6.50 | 6 | **6.38** | Yellow |
| 15 | 2 | Corp Command Center | 7 | 4 | 6 | 8 | 7 | 4 | 8 | 6 | 6.25 | 5 | **5.94** | Green |
| 16 | 17 | Energy Arbitrage Bot | 7 | 8 | 6 | 8 | 8 | 6 | 4 | 5 | 6.50 | 3 | **5.63** | Yellow |
| 17 | 11 | Time-Locked Vault | 6 | 6 | 8 | 5 | 6 | 5 | 7 | 6 | 6.13 | 5 | **5.84** | Green |
| 18 | 16 | Gate Graffiti Wall | 6 | 6 | 5 | 5 | 7 | 6 | 6 | 5 | 5.75 | 6 | **5.81** | Yellow |
| 19 | 20 | Gate Leaderboard | 5 | 3 | 5 | 6 | 7 | 3 | 7 | 6 | 5.25 | 5 | **5.19** | Green |
| 20 | 26 | Fortune Gate | 6 | 6 | 5 | 4 | 5 | 6 | 6 | 6 | 5.50 | 5 | **5.38** | Yellow |
| 21 | 25 | Zero-Friction Portal | 7 | 3 | 5 | 8 | 3 | 5 | 9 | 7 | 5.88 | 4 | **5.41** | Yellow |
| 22 | 15 | Logistics Router | 5 | 3 | 5 | 6 | 7 | 4 | 6 | 5 | 5.13 | 4 | **4.84** | Green |
| 23 | 6 | Fuel Watch | 6 | 3 | 7 | 7 | 6 | 3 | 7 | 5 | 5.50 | 4 | **5.13** | Green |
| 24 | 13 | Gate Traffic Analytics | 6 | 3 | 7 | 6 | 5 | 3 | 7 | 5 | 5.25 | 3 | **4.69** | Green |
| 25 | 27 | Trophy Case | 4 | 3 | 5 | 5 | 3 | 3 | 5 | 4 | 4.00 | 3 | **3.75** | Green |
| 26 | 10 | Structure Insurance | 7 | 6 | 2 | 6 | 7 | 6 | 5 | 3 | 5.25 | 4 | **4.94** | Red |
| 27 | 19 | Corp Treasury Mgr | 5 | 2 | 3 | 5 | 7 | 2 | 3 | 3 | 3.75 | 2 | **3.31** | Red |
| 28 | 28 | Extension Forge | 4 | 5 | 6 | 2 | 2 | 3 | 3 | 3 | 3.50 | 2 | **3.13** | Green |

### Top 10 Rationales

#### #1 — Gate Policy Engine (ID 1) — Weighted: 7.97

**Why it would be adopted:** Every gate owner currently has binary open/closed control. This turns gates into programmable routers — tribe filters, time windows, item tolls — configured from a web dashboard without writing Move code.

**Demo moment:** "Character from the wrong tribe tries to jump — denied. Flip one toggle, now they can. Ten seconds, one transaction."

**Frontier vibe:** Gate policy is access governance. Policy composition mirrors how real-world infrastructure is managed — firewalls, access lists, traffic policies.

**Minimum viable build:** Single extension module with dynamic field rule dispatch + 3 rule types (tribe, time, toll). **Stretch:** ZK privacy policy rule type.

---

#### #2 — SSU Storefront (ID 3) — Weighted: 7.91

**Why it would be adopted:** EVE Frontier has station-based markets for centralized trading, but no commerce exists at player-deployed structures. SSU Storefront extends the economy into the field — remote outposts, forward operating bases, and toll-adjacent supply depots that station hubs can't reach. The atomic PTB buy flow (split coin → buy → transfer) is immediately understood by any gamer who has used an auction house.

**Demo moment:** "Click 'Buy Laser Cannon' — one transaction, item appears in your inventory. The first player-deployed storefront in EVE Frontier."

**Frontier vibe:** Player-run shops at forward-deployed SSUs in hostile space evoke the legendary null-sec market hubs of EVE Online — the frontier outpost general store, not a replacement for station trade.

#### Relationship to Station Markets

- **Station markets already handle** centralized hub trading — players list and buy items at NPC stations, with remote purchase supported but physical pickup required.
- **SSU Storefront adds** field-deployable, decentralized point-of-sale at player-owned infrastructure. Commerce can happen anywhere a player deploys an SSU — deep space, forward bases, gate-adjacent outposts.
- **They coexist** because station markets serve hub trading while SSU Storefront serves the frontier. Different locations, different use cases, complementary economics.
- **This strengthens Frontier gameplay** by extending the economic layer beyond station hubs, enabling emergent supply chains where outpost operators profit from proximity to dangerous or remote areas.

**Minimum viable build:** SSU extension module with `Listing` dynamic fields + web browse/buy UI. **Stretch:** Kiosk standard integration, faction currency support.

---

#### #3 — Corpse Toll Road (ID 8) — Weighted: 7.72

**Why it would be adopted:** Template code already exists (`corpse_gate_bounty.move`). Deploy → configure toll type → earn items. Lowest risk, highest certainty of a polished demo.

**Demo moment:** "Deposit a corpse at the toll booth — gate opens. No corpse? No jump. Space has a price."

**Frontier vibe:** Pay-with-loot creates emergent economy loops. Players farm items to access infrastructure — the gameplay design writes itself.

**Minimum viable build:** Deploy existing `corpse_gate_bounty.move` + web form for configuring `bounty_type_id`. **Stretch:** Multi-item toll, SUI payment option.

---

#### #4 — Loot Crate (ID 21) — Weighted: 7.53

**Why it would be adopted:** Gamers universally understand loot crates. `sui::random` VRF proves fairness verifiably — "no one could have rigged it" is a narrative that writes itself.

**Demo moment:** "Pay the entry fee, crack open the crate — Legendary Plasma Cannon or Common Space Dust. Check the VRF proof on-chain."

**Frontier vibe:** Loot drops are slightly generic (not uniquely EVE), but the execution using Sui's VRF is a marquee feature showcase.

**Minimum viable build:** Standalone `LootCrate` module with `sui::random`, configurable loot table as dynamic fields. **Stretch:** SSU extension integration, faction currency pricing.

---

#### #5 — Alliance Gate Network (ID 7) — Weighted: 7.56

**Why it would be adopted:** Coordinated infrastructure is the pinnacle of EVE gameplay. Gate owners forming jump highways with shared policies is the dream scenario for any organized corp.

**Demo moment:** "Four gates, two owners, one alliance — outsider tries to jump through the highway and gets denied."

**Frontier vibe:** Perfect 10/10 — this IS emergent multiplayer gameplay. Alliances, territory, shared infrastructure.

**Minimum viable build:** Single-owner gate linking + alliance config as shared object. **Stretch:** Cross-owner multi-party signing, diplomatic overrides.

---

#### #6 — ZK Gate Pass (ID 5) — Weighted: 7.19

**Why it would be adopted:** No other hackathon entry will have ZK-gated game infrastructure. The technical achievement is memorable and the "privacy-preserving jump" narrative is unique.

**Demo moment:** "'Generating zero-knowledge proof...' — proof verified on-chain — gate opens — and the blockchain never learned where you were."

**Frontier vibe:** Privacy in hostile space is survival instinct. Location-private travel extends the "trust no one" EVE culture.

**Minimum viable build:** Wrapper module integrating ZK PoC with gate extension, browser proof generation via snarkjs WASM. **Stretch:** Multiple circuit types, batch proof verification.

---

#### #7 — Tribal Diplomacy (ID 14) — Weighted: 6.84

**Why it would be adopted:** On-chain diplomacy that auto-enforces gate access is genuinely novel. No other game has foreign policy enforced by smart contracts.

**Demo moment:** "Set Tribe B to 'hostile' — their member tries to jump — denied. Change to 'ally' — they jump through. Diplomacy, enforced by code."

**Frontier vibe:** Diplomacy, betrayal, and alliances are peak EVE culture.

**Minimum viable build:** `DiplomacyConfig` shared object + gate extension checking tribe relations. **Stretch:** Multi-tribe voting on diplomatic changes.

---

#### #8 — Bounty Board (ID 12) — Weighted: 6.97

**Why it would be adopted:** "Bounty hunting on-chain" is the highest player-vote-appeal concept. PvP players will smash the vote button.

**Demo moment:** "Post a bounty. Target dies. Killmail appears. Bounty pays out."

**Frontier vibe:** Perfect for EVE's adversarial culture. Bounties create content — players hunt each other for economic reward.

**Minimum viable build:** Shared `BountyBoard` object with SUI escrow + oracle-assisted killmail verification. **Stretch:** Trustless verification if killmail getters are added upstream.

---

#### #9 — Salvage Protocol (ID 23) — Weighted: 6.41

**Why it would be adopted:** Turning Sui's storage rebate mechanism into a gameplay loop is the most creatively novel idea in the entire set — nobody else will think to make gas economics a game mechanic.

**Demo moment:** "This station's been abandoned — claim the salvage bounty, the structure dissolves, and Sui's own storage rebate pays you."

**Frontier vibe:** Scavenging wrecks is a beloved EVE Online profession. This maps perfectly.

**Minimum viable build:** `SalvageBounty` module wrapping `unanchor()` + bounty escrow. **Stretch:** Auto-detection of abandoned structures via fuel depletion events.

---

#### #10 — Faction Mint (ID 24) — Weighted: 6.31

**Why it would be adopted:** Every tribe gets its own economy. Gate tolls, trades, and bounties denominated in faction currency create real tribal identity.

**Demo moment:** "Alpha Tribe member pays gate toll in ALPHA tokens — Beta Tribe member walks up with SUI and gets denied. Your money's no good here."

**Frontier vibe:** Custom currencies are deeply EVE — ISK defined EVE Online's economy; Lux serves that role in EVE Frontier. Faction minting adds a builder-controlled on-chain complement, letting tribes denominate tolls and trade in their own tokens.

**Minimum viable build:** One-time witness `Coin<T>` pattern + `TreasuryCap` governance + gate/SSU integration. **Stretch:** Cross-faction exchange, treasury management.

---

## D) Bonus Prize Alignment

### Most Utility

| Rank | Idea | Why |
|------|------|-----|
| 1 | SSU Storefront (#3) | Extends commerce beyond station hubs — the first storefront at player-deployed infrastructure. Every SSU owner is a potential shopkeeper. |
| 2 | Gate Policy Engine (#1) | Every gate owner immediately benefits. Configurable access without code — universal operational utility. |
| 3 | Corp Command Center (#2) | Pure operational utility — single pane of glass for all structures. But no on-chain mod, just a read-only frontend. |

### Best Technical Implementation

| Rank | Idea | Why |
|------|------|-----|
| 1 | ZK Gate Pass (#5) | Groth16 proof → on-chain verification → game action. Unique technical depth across the full stack. |
| 2 | Gate Policy Engine (#1) | Dynamic field rule composition within single-extension constraint. Deepest world-contracts integration. |
| 3 | Energy Arbitrage Bot (#17) | Hot-potato `OfflineAssemblies` chain in PTB demonstrates advanced Sui transaction composition. |

### Most Creative

| Rank | Idea | Why |
|------|------|-----|
| 1 | Salvage Protocol (#23) | Uses Sui's own gas rebate mechanism as a gameplay reward. Nobody else will think of this. |
| 2 | ZK Gate Pass (#5) | ZK proofs for game infrastructure access — unique intersection of cryptography and gameplay. |
| 3 | Dead Drop (#9) | Spy gameplay on blockchain with hash-keyed slots. The concept is evocative even if diluted by event-layer privacy leak. |

### Weirdest Idea

| Rank | Idea | Why |
|------|------|-----|
| 1 | Fortune Gate (#26) | Slot-machine gate: 80% chance you jump, 20% you're stranded. Funny, dramatic, clip-worthy. |
| 2 | Gate Graffiti Wall (#16) | Spray-paint messages on blockchain gates. Memeable, emergent social content. |
| 3 | Proof-of-Presence Badge (#18) | ZK "I Was There" NFTs for battles. Niche but collectible culture resonates. |

### Best Live Frontier Integration

| Rank | Idea | What It Takes |
|------|------|--------------|
| 1 | Corpse Toll Road (#8) | Deploy existing template code to hackathon test server (build) and Stillness (live server, post-submission). Lowest barrier — working code exists. Needs AdminACL access for sponsored tx. |
| 2 | Gate Policy Engine (#1) | Deploy extension module + register on a real Stillness gate. Needs game account with owned gate + AdminACL for extension registration. |
| 3 | Faction Mint (#24) | Deploy `Coin<T>` to Stillness + integrate with existing gates/SSUs. Coin creation is permissionless; integration needs structure ownership. |

---

## E) CivilizationControl — Packaging Recommendation

### The Suite

**CivilizationControl** is an infrastructure management dashboard for EVE Frontier — a unified system where builders configure gate access policies, run storefronts, and mint faction currencies from a single dashboard.

| Module | Description | Draws From | Priority | Risk |
|--------|-------------|-----------|----------|------|
| **GateControl** | Composable gate policy engine — tribe filters, time windows, item tolls via dynamic field rule dispatch within a single extension module | ID 1 + ID 8 + ID 14 | 1 | Green |
| **TradePost** | SSU storefront — list items, browse/buy with atomic PTB escrow, prices displayed in Lux, settled on-chain via `Coin<SUI>` or faction tokens | ID 3 | 2 | Yellow |
| **TribeMint** | Faction currency — `Coin<TribeToken>` for gate tolls, storefront prices, cross-module economic integration | ID 24 | 3 | Green |
| **LootDrop** *(stretch)* | VRF loot crate — `sui::random` randomized item drops integrated into TradePost SSUs | ID 21 | 4 | Yellow |

### Shared Architecture

**Auth model:** All modules use the same hot-potato OwnerCap borrow pattern (`Character.borrow_owner_cap<T>() → OwnerCap<T> + ReturnReceipt → config operations → return_owner_cap()`). One wallet connection, one signing flow, uniform auth.

**UI shell:** Single web dashboard with structure inventory sidebar (all gates/SSUs/NWNs), module panels in the main area, and a live event feed. Every module is a panel within the same shell, not a separate app.

**Data model:**
- **GateControl:** `PolicyConfig` dynamic field on Gate with `TribeRule`, `TimeRule`, `TollRule` sub-fields
- **TradePost:** `Listing` dynamic field on SSU keyed by item_id, with price/currency/seller/active
- **TribeMint:** `TreasuryCap<T>` + `CoinMetadata<T>` + `FactionRegistry` shared object mapping tribe_id → coin type
- **Shared off-chain:** Structure index via GraphQL, event cache (JumpEvent, ItemDepositedEvent, ItemWithdrawnEvent), revenue tracking

### Implementation Order

1. **GateControl** (Priority 1) — Foundation. Deploy extension + tribe filter rule. This proves the pattern works and establishes the auth model all other modules share.
2. **TradePost** (Priority 2, parallel-start after GateControl auth is proven) — Strong individual weighted score (7.91). De-risk cross-address PTB item transfer on day 1.
3. **TribeMint** (Priority 3) — Individually modest (6.31), but it's the connective tissue. When GateControl accepts ALPHA_COIN as toll and TradePost accepts it as payment, the system becomes more than the sum of its parts.
4. **LootDrop** (Priority 4, stretch) — Only if modules 1–3 are stable. Demonstrates `sui::random` mastery. Strong player vote pull (8/10).

### Demo Storyline (3-Minute Video)

**Pre-deployed:** 2 linked gates, 1 SSU, 1 NWN, 3 characters (2× Tribe Alpha, 1× Tribe Beta), 5 test items, 100 ALPHA_COIN minted.

**Act 1 — "The Dashboard" (0:00–0:30)**
> "Every EVE Frontier builder has the same problem: you deploy structures, but you're blind. CivilizationControl changes that."

Open dashboard → three structure cards (Gate Alpha, Gate Beta, SSU Outpost) show status → NWN fuel at 80% → click Gate Alpha → no policy yet (open to all).

**Act 2 — "The Policy" (0:30–1:15)**
> "Let's make Gate Alpha smart."

Open GateControl panel → enable Tribe Filter (Tribe Alpha only) → enable Toll (Item Type 42) → click "Deploy Policy" → PTB executes on-chain.

- **Tribe Alpha member with item:** Jumps ✅ → Item-42 consumed → JumpEvent appears in feed
- **Tribe Beta member:** Denied ❌ → "Access Denied: tribe not authorized"

> "One extension, composable rules, configured from a browser."

**Act 3 — "The Market" (1:15–2:00)**
> "Now let's monetize the SSU."

Switch to TradePost → create 3 listings (Rare Component: 100 Lux, Fuel Cell: 50 Lux, Trophy: 25 ALPHA_COIN) → buyer browses → clicks "Buy Trophy" → PTB: split ALPHA_COIN → buy → item transfers → trade appears in feed.

> "Atomic, trustless commerce. On-chain settlement in SUI or faction tokens — displayed to players in Lux."

**Act 4 — "The Economy" (2:00–2:40)**
> "Where did ALPHA_COIN come from?"

Switch to TribeMint → show `TreasuryCap` + metadata → mint 50 ALPHA_COIN → balance updates. Pull back to dashboard → Revenue Summary shows gate tolls + storefront revenue + faction token circulation.

> "Every tribe can have its own economy flowing through every module."

**Act 5 — "The System" (2:40–3:00)**
> "We didn't build three tools. We built ONE system. Same auth, same dashboard, same economy. This is CivilizationControl: the control plane for EVE Frontier infrastructure."

Final dashboard view — all modules, event feed scrolling, revenue ticking.

**The Moment:** When the buyer pays 25 ALPHA_COIN for the Trophy — the same currency minted by the faction leader AND accepted as gate tolls — judges see three modules genuinely interconnected by economic feedback loops, not just co-located in a UI.

### Stretch Features

1. **LootDrop (VRF crate)** — Adds gamification to TradePost SSUs. `sui::random` is a marquee Sui feature. Player vote: 8/10. Build only if core 3 modules are stable.
2. **ZK Privacy Policy rule type** — Adds a "ZK Proof" rule to GateControl's policy engine. Jumpers prove authorization via Groth16 without revealing identity. Creativity: 10/10. Build only if ZK PoC bridge is solved.

---

## F) Technical Sanity Notes

No V3 recommendation violates a known constraint from V2. Key checks:

| Constraint | Status | Affected Ideas |
|------------|--------|---------------|
| **Killmail has no public getters** | Confirmed. External Move cannot read killmail fields. | ID 10 (Red), ID 12 (oracle fallback required) |
| **OwnerCap lacks `store`** | Confirmed. Cannot wrap or transfer externally. | ID 19 (Red — pivoted to Sui native multi-sig) |
| **Single gate extension slot** | Confirmed. `extension` is `Option<TypeName>`. GateControl solves this via internal composition with dynamic field sub-rules. | ID 1 (solved), ID 14 (absorbed into GateControl) |
| **Events are ephemeral** | Confirmed. No persistent on-chain event store. Off-chain indexer needed for analytics ideas. | ID 4, 12, 13, 20 |
| **250KB object size limit** | Confirmed. Ring-buffer pruning mandatory for any accumulator pattern. | ID 16 (Gate Graffiti Wall) |
| **PTB 1000 command limit** | Confirmed. Relevant for Energy Arbitrage Bot (hot-potato chain scales with connected assemblies). | ID 17 |
| **`sui::random` requires `entry` function** | Confirmed. Cannot compose freely in arbitrary PTB flows. Needs dedicated entry point. | ID 21, 26 |
| **ZK PoC package-naming conflict** | `world` name used by both ZK PoC and world-contracts. Wrapper module needed. | ID 5, 9, 18 |
| **Sui 8 Groth16 public inputs** | Confirmed. ZK circuits use 3 inputs — within limit. | ID 5 |
| **`deposit_item` does NOT require proximity proof** | Confirmed (extension-mediated). Extension controls deposit, not proximity server. | ID 11, ID 3 (TradePost) |

---

## G) Web Research Heuristics Applied

15 patterns from web3 gaming hackathon analysis, applied to scoring:

1. **Novel mechanism > visual polish** — ZK Gate Pass and Salvage Protocol scored up on Creativity; Corp Command Center scored down on ModDesign despite nice UI potential.
2. **Real-world utility bridge** — SSU Storefront scored highest on Player Utility because it connects chain activity to immediate in-game value (buying/selling items players need).
3. **Composability as superpower** — GateControl's dynamic field rule dispatch and Faction Mint's `Coin<T>` composability boosted ModDesign scores. These are systems others can build on.
4. **Scope ruthlessly — expect 25% completion** — The CivilizationControl suite is scoped to 3 core modules with pre-validated building blocks (existing template code for tolls, standard Coin pattern). Stretch features are explicitly optional.
5. **Demo-ready in under 2 minutes** — Each CivilizationControl module has a 30-second video segment; the full suite demo video is 3 minutes with progressive complexity.
6. **Gamify the unglamorous** — GateControl turns boring access-list management into a visual policy builder. TradePost turns SSU config into a shop-owner experience.
7. **"On-chain native" = couldn't exist without the chain** — Every top-10 idea exercises Sui-specific capabilities (object ownership, PTB composition, sponsored tx, VRF, ZK verification). Dashboard-only ideas scored down.
8. **Target sponsor prizes explicitly** — CivilizationControl demonstrates 3+ Sui primitives (dynamic fields, Coin standard, PTB composition, optionally VRF and ZK), positioning for Best Technical Implementation.
9. **Simple + fun beats complex + impressive** — Corpse Toll Road ranked #3 despite being the simplest implementation, because "pay corpse → jump gate" is immediately understood.
10. **Clear problem statement first** — Demo storyline opens with "you're blind" (the problem), not "we built" (the solution).
11. **Mobile-first consideration** — Dashboard UI concept is responsive; key actions (check status, approve trade) work on mobile.
12. **Real data > mock data** — Demo plan deploys to local devnet with real transactions, not hardcoded JSON. Recorded demo must show genuine on-chain execution.
13. **Easy onboarding = more testers = more votes** — CivilizationControl with sponsored tx lets judges try it without gas or wallet setup.
14. **Show the "control panel" moment** — The unified dashboard with updating structure cards, fuel gauges, and event feed is the signature visual. One striking dashboard view > multiple static pages. In a recorded video, this can be captured cleanly with annotations.
15. **State channels for real-time feel** — Off-chain optimistic UI with on-chain settlement for TradePost listing updates keeps the dashboard feeling responsive despite chain latency.

---

> ¹ ZK Gate Pass upgraded from Yellow to **Green** following local devnet validation (sandbox; to re-validate on hackathon test server March 11). See [validation report](../operations/shortlist-viability-validation-report.md) tests 8–10 and [ZK feasibility report](../operations/zk-gatepass-feasibility-report.md).

## Appendix: Full Idea Registry (28 Ideas)

| ID | Title | Source | Category | Feasibility |
|----|-------|--------|----------|-------------|
| 1 | Gate Policy Engine | V2-grounded | Extension | Green |
| 2 | Corp Command Center | V2-grounded | Dashboard | Green |
| 3 | SSU Storefront | V2-grounded | Economy | Yellow |
| 4 | Killmail Intelligence | V2-grounded | Analytics | Green |
| 5 | ZK Gate Pass | V2-grounded | ZK/Privacy | Green¹ |
| 6 | Fuel Watch | V2-grounded | Monitoring | Green |
| 7 | Alliance Gate Network | V2-grounded | Governance | Yellow |
| 8 | Corpse Toll Road | V2-grounded | Economy | Green |
| 9 | Dead Drop | V2-grounded | ZK/Privacy | Yellow |
| 10 | Structure Insurance | V2-grounded | Economy | Red |
| 11 | Time-Locked Vault | V2-grounded | Extension | Green |
| 12 | Bounty Board | V2-grounded | Economy | Yellow |
| 13 | Gate Traffic Analytics | V2-grounded | Analytics | Green |
| 14 | Tribal Diplomacy | V2-grounded | Governance | Yellow |
| 15 | Logistics Router | V2-grounded | Utility | Green |
| 16 | Gate Graffiti Wall | V2-grounded | Social | Yellow |
| 17 | Energy Arbitrage Bot | V2-grounded | Automation | Yellow |
| 18 | Proof-of-Presence Badge | V2-grounded | ZK/NFT | Yellow |
| 19 | Corp Treasury Manager | V2-grounded | Governance | Red |
| 20 | Gate Leaderboard | V2-grounded | Analytics | Green |
| 21 | Loot Crate | Both | Economy | Yellow |
| 22 | Kiosk Bazaar | Both | Economy | Yellow |
| 23 | Salvage Protocol | Both | Economy | Green |
| 24 | Faction Mint | Both | Economy | Green |
| 25 | Zero-Friction Portal | Both | Onboarding | Yellow |
| 26 | Fortune Gate | V2-doc-enabled | Economy | Yellow |
| 27 | Trophy Case | V2-doc-enabled | Infrastructure | Green |
| 28 | Extension Forge | V2-doc-enabled | Dev Tooling | Green |

---

## Currency Model: Lux, On-Chain Tokens, and Gas

> **Applicable to all economy-tagged ideas (IDs 3, 8, 10, 12, 21, 22, 23, 24, 26).**

EVE Frontier has a layered currency architecture that affects how CivilizationControl and all economy ideas should present values to players:

| Layer | Currency | Where It Lives | Player Visibility |
|-------|----------|----------------|-------------------|
| **In-game economy** | **Lux** | Game server | Primary — what players earn, see, and think in |
| **On-chain settlement** | **`Coin<SUI>`** | Sui blockchain | Secondary — shown as implementation detail or in parentheses |
| **Ecosystem token** | **`Coin<EVE>`** | Sui: implemented (v0.0.13); Ethereum live cycle: exists in-game | `contracts/assets/sources/EVE.move`: 10B supply, 9 decimals, separate AdminCap + EveTreasury. Live Ethereum cycle also surfaces EVE token with Lux conversion (10,000 Lux = 1 EVE) |
| **Builder faction token** | **`Coin<TribeToken>`** | Builder-deployed (TribeMint) | Optional — tribe-specific economic layer alongside Lux |
| **Gas** | **SUI** (gas fees) | Sui blockchain | Hidden — abstracted via sponsored transactions |

### Key Facts

- **Lux is never mentioned** in world-contracts Move code — it's a game-server concept with no on-chain representation.
- **`Coin<EVE>` is now implemented in Sui world-contracts** (v0.0.13, `contracts/assets/sources/EVE.move`): 10B supply, 9 decimals, OTW via `coin_registry`, separate AdminCap + EveTreasury (deployer-owned), burn-only after init. In the live Ethereum-based Frontier cycle, an EVE token is also surfaced in-game with Lux conversion (observed rate: 10,000 Lux = 1 EVE token). Whether on-chain settlement migrates from `Coin<SUI>` to `Coin<EVE>` requires sandbox validation.
- **All validated on-chain payments use `Coin<SUI>`.** Gate tolls and TradePost purchases settle in SUI.
- **Lux-to-EVE exchange rate observed: 10,000 Lux = 1 EVE token** (observed in live Ethereum cycle UI; requires sandbox confirmation). Lux-to-SUI rate depends on EVE-to-SUI exchange, which is undefined. If the UI displays Lux values, the conversion rate must be confirmed during March 11 sandbox testing.
- **Sponsored transactions are implemented** (`AdminACL.verify_sponsor()`) but require authorization. Gas abstraction is architecturally supported.

### UX Principle for Demo and Product

Player-facing language should use **Lux** as the primary denomination. On-chain settlement details appear in parentheses or in technical views:

> *"Toll: 5 Lux (settled on-chain)"*
> *"Fuel Rod: 50 Lux"*

**Assumption:** Lux-to-on-chain-token conversion rate and mechanism require validation during March 11 sandbox testing. This is a UX design requirement, not a blocker for Move contract development.

CivilizationControl displays prices in Lux (player-native), settles on-chain in the game's economic token, and abstracts gas from the player experience.
