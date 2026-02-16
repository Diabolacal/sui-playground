# CivilizationControl — The Frontier Control Room

**Retention:** Carry-forward

> *"The frontier doesn't reward the strongest. It rewards whoever builds the infrastructure that everyone else depends on."*

---

## The Problem (In Human Terms)

You lead a tribe of forty pilots in EVE Frontier. You control a dozen gates, a handful of storage units, and a fragile web of network nodes burning fuel around the clock.

Here's what your day looks like:

You wake up, check in, and discover that two of your gates went offline six hours ago because a network node ran dry. Nobody told you. There were no alerts, no warnings — it just stopped working. Hostile pilots used the gap. Two killmails on your people. One was hauling fuel to the station that needed it.

You have eight storage units scattered across three systems. Someone in your tribe asks where the fuel reserves are. You don't know. You'd have to query each SSU individually, manually, one at a time. So you ask around in Discord.

An ally from another tribe wants to trade ammo for fuel cells. There's no marketplace. No escrow. No listings. No trust layer. You could manually coordinate a deposit — you put fuel in an SSU, they put ammo in another SSU — and hope nobody walks away. There is no atomic trade. No receipts. No storefront.

Meanwhile, your gates are open to anyone. You want a simple policy: *free for your tribe, a small toll for allies, closed to hostiles.* But the current system gives you one extension slot per gate. Binary access: everyone in, or everyone out. To do anything more nuanced, you'd need to write Move smart contracts yourself, deploy them, configure each gate individually, and hope you don't break the one your logistics pilots depend on.

**This is the state of infrastructure management on the frontier today.**

Smart assemblies are powerful. The on-chain architecture supports composable access rules, cross-address inventory operations, and atomic multi-step transactions. The primitives are there. But the tools to wield them — the dashboard, the policy builder, the marketplace, the monitoring layer — don't exist.

The gap between "what the blockchain can do" and "what a tribe leader can actually do" is the entire product.

---

## The Vision

**CivilizationControl is the control room that the frontier doesn't have yet.**

Imagine a single screen where you see your entire infrastructure at a glance. Every gate you own, every storage unit, every network node — alive and reporting. Green indicators for gates passing traffic. Amber for fuel running low. Red for offline.

On one side, your gate policies: who gets in, what they pay, and when. Not as raw contract calls — as toggles, dropdowns, and clear language. *Tribe 7: free passage. Tribe 12: toll required. Everyone else: blocked.* Apply to one gate, or all gates in the northern cluster.

On the other side, your storefronts. Items stocked in your SSUs, listed with prices, browsable by anyone in range. A buyer clicks. Payment flows. The item transfers. One atomic transaction, no trust required, no coordination in Discord.

In the center, a live activity feed. Gate jumps. Purchases. Toll revenue. Who's coming through your territory, how much they're paying, and what they're buying. Not raw blockchain events — readable, filterable, human information.

**CivilizationControl doesn't add new primitives to EVE Frontier. It takes the primitives that already exist — the extension system, the shared objects, the PTB composition layer — and makes them usable by the people who actually run civilizations.**

This is a territory dashboard. A management layer for the infrastructure you already own. A way to finally *see your frontier*.

---

## Currency Model: Lux, On-Chain Tokens, and Gas

> **Status:** Partially validated. On-chain settlement uses `Coin<SUI>` today. In the Sui world-contracts repository, an EVE token implementation is not yet present (TODO noted in `world.move`). However, in the live Ethereum-based Frontier cycle, an EVE token is surfaced in-game with Lux conversion (observed rate: 10,000 Lux = 1 EVE token). Lux is the in-game engine currency that players earn and spend — it has no on-chain representation in the Sui codebase.

### How Players Think About Money

- **Lux** is the in-game currency. Players earn Lux, see prices in Lux, and think in Lux. This is the language of the game economy.
- **On-chain settlement** currently uses `Coin<SUI>` (the Sui blockchain's native token). Tolls, trades, and storefront purchases all settle in SUI on-chain.
- **EVE Token** is the ecosystem settlement token. In the live Ethereum-based Frontier cycle, it exists in-game with Lux conversion (observed rate: 10,000 Lux = 1 EVE token). However, in the current Sui world-contracts repository, no `Coin<EVE>` type, `TreasuryCap<EVE>`, or minting mechanism exists yet — only a `// TODO` placeholder. This discrepancy reflects differing implementation states between chains and cycles.
- **Gas (SUI)** is a separate concern — the transaction fee for executing on-chain operations. Gas should be abstracted from the player experience, ideally via sponsored transactions.

### CivilizationControl UX Implications

| Layer | What Players See | What Happens On-Chain |
|-------|-------------------|----------------------|
| **Toll** | "Toll: 5 Lux" | `Coin<SUI>` transfer (amount TBD by exchange rate) |
| **Trade** | "Fuel Rod: 35 Lux" | `Coin<SUI>` payment in atomic PTB |
| **Revenue** | "Revenue: 240 Lux today" | Aggregated `Coin<SUI>` receipts |
| **Gas** | Hidden / "Sponsored" | SUI gas fee (ideally sponsored) |

### Assumptions and Unknowns (Requires Validation)

| Item | Status | Notes |
|------|--------|-------|
| Lux-to-SUI exchange rate | **Partially known** | Observed in live Ethereum cycle UI: 10,000 Lux = 1 EVE token. Lux-to-SUI rate depends on EVE-to-SUI exchange, which is undefined. If CivilizationControl displays Lux values, the conversion rate must be confirmed in the March 11 sandbox — either by the game server, a fixed ratio, or builder configuration. |
| EVE Token availability | **Sui: unimplemented; Ethereum live cycle: exists** | `vendor/world-contracts` (Sui) contains only a `// TODO` placeholder. Builder contracts (`tokens.move` in scaffold) are empty stubs. The live Ethereum-based Frontier cycle surfaces EVE token in-game. |
| Automatic Lux→on-chain conversion | **Not confirmed** | No mechanism exists that converts Lux to any on-chain token automatically. This may be a game-server-side operation, a future platform feature, or a UX design requirement for CivilizationControl to solve. |
| Sponsored transactions for gas abstraction | **Implemented but access-controlled** | `AdminACL.verify_sponsor()` exists in world-contracts. Builders need AdminACL authorization. Requires sandbox validation on March 11. |
| `Coin<T>` generic toll support | **Architecturally possible** | The toll mechanism can accept any `Coin<T>` type. If TribeMint ships, faction currency tolls are feasible. Current validation uses `Coin<SUI>` only. |

### Design Principle

**CivilizationControl surfaces Lux values as the primary player-facing denomination.** On-chain settlement details (`Coin<SUI>`, gas fees, transaction digests) are implementation concerns that the UI abstracts away. Where both values are relevant, the UI displays both:

> *Toll: 5 Lux (0.5 SUI)*
> *Fuel Rod: 35 Lux (3.5 SUI)*

If/when EVE Token launches or a Lux exchange rate is established, the UI layer adapts without changing the underlying Move contracts.

CivilizationControl displays prices in Lux (player-native), settles on-chain in the game's economic token, and abstracts gas from the player experience.

---

## What It Feels Like to Use

You open CivilizationControl and log in through EVE Vault.

The dashboard loads and you see your structures laid out: six gates, four SSUs, three network nodes. The northern gate cluster is green — all online, all passing traffic. The southern pair shows amber — fuel below 30% on the connected NWN.

You click into Gate North-3. The policy panel shows your current rules: **Tribe Filter** (Tribe 7 allowed) and **Toll** (2 Lux per jump). Both rules are active, composed as layers — not either/or, but both-and. A small counter shows 47 jumps in the last 24 hours and 94 Lux collected in tolls.

You toggle the toll from 2 to 5 Lux. One click. The policy updates on-chain. No Move code, no CLI, no deploy step.

Then you switch to TradePost. Your forward supply depot — SSU Echo-2 — is listed as a storefront. Four items stocked: fuel rods, repair paste, ammo cells, and a rare lens module. Each has a price in Lux. You see that two fuel rod listings sold overnight. Revenue: 60 Lux. The buyer history shows two different pilots — one from an allied tribe, one unaffiliated. Both paid, both received their items, both transactions settled atomically on-chain.

You stock five more fuel rods and list them at 35 Lux each.

The activity feed scrolls quietly in the sidebar. A jump notification from Gate North-1: pilot from Tribe 12, toll paid 5 Lux. A purchase notification from SSU Echo-2: pilot bought repair paste, 20 Lux. A fuel warning from NWN-South: estimated 8 hours remaining.

For the first time, you can see your toll and trade revenue in real time — in Lux, the currency you actually think in. Not in a spreadsheet. Not in Discord messages. On a dashboard that shows you what's happening, right now, across every structure you own.

---

## Core Modules

### GateControl — Gate Access Governance

Gates are the arteries of the frontier. Whoever sets the rules on gates shapes who moves through their space — and in a universe where distance is vast and resources are scarce, access policy is power.

GateControl turns gate policy configuration from a technical chore into a governance tool. A tribe leader doesn't need to understand Move's type system to say: *my gates are open to allies and closed to hostiles.* They don't need to deploy contracts to charge a toll. They don't need to reconfigure twenty gates one at a time.

GateControl is not about access lists. It's about **governance** — the ability to define, in clear terms, who passes through your gates and under what conditions. It plugs into the existing gate extension model and layers composable rules on top of Frontier's jump system, enforced on-chain, trustlessly, without relying on honor systems or Discord agreements.

What's validated and real:
- Tribe-based filtering: matching tribe passes, non-matching tribe is blocked atomically.
- Toll collection: payment transfers to the gate operator's address on jump (settled on-chain via `Coin<SUI>`).
- Rule composition: tribe filter AND toll as independent, stackable layers on the same gate.
- All tested and passing on devnet. None of this is theoretical.

### TradePost — Frontier Commerce

Every frontier eventually needs a market. Not a centralized exchange — a network of storefronts, each attached to a physical storage unit in space, each stocked by its owner, each open to buyers ready to pay.

TradePost turns SSUs into shops. An operator stocks items from their inventory, sets prices (displayed in Lux), and publishes listings. A buyer browsing the storefront sees what's available, clicks buy, and the entire transaction settles atomically on-chain — payment to the seller, item to the buyer, listing marked complete. One signature. No counterparty risk. No coordination. No trust required.

What's validated and real:
- Atomic buy flow: buyer pays, receives item, seller receives payment — single on-chain transaction (currently `Coin<SUI>`).
- Cross-address item transfer: the extension's typed witness authorizes withdrawal from the seller's SSU without the seller being online.
- SSU-backed storefront: full lifecycle tested — publish, setup, authorize, stock, list, buy.
- Three successful cross-address buys at different prices, each with verifiable on-chain events.

### Why They're a System, Not Tools

GateControl and TradePost aren't two separate features that happen to ship together. They create a feedback loop:

A gate toll charges for passage through your territory. Where do those pilots spend their funds? At the storefront on the other side. What does the storefront sell? Fuel, ammo, supplies — the things you need to keep jumping, keep fighting, keep surviving. The toll feeds the commerce. The commerce justifies the toll. The operator profits from both sides of the loop.

When a buyer at your TradePost pays 30 Lux for a fuel cell — an item that the gate on the other side of the system is also demanding as a toll condition — two modules create emergent economic interaction without explicit coupling. The gate drives demand. The storefront fills it. The tribe leader profits from both.

That's not two tools. That's an integrated management suite — gate policy and frontier commerce reinforcing each other.

---

## What Makes This Different

Smart assemblies already exist. Gate extensions already exist. The EVE Frontier builder docs explain how to write a tribe filter, how to create a toll, how to manage SSU inventories. So why does CivilizationControl matter?

**Because the primitives are not the product.**

The primitives are Move modules, typed witnesses, dynamic field dispatch, and PTB composition. They're powerful, elegant, and completely inaccessible to the 98% of tribe leaders who don't write smart contracts.

What doesn't exist yet:
- **No dashboard.** No way to see all your structures, their status, their activity, in one place.
- **No policy builder.** No way to configure gate rules without writing Move code.
- **No marketplace.** No way to list items for sale, discover prices, or buy trustlessly.
- **No monitoring.** No way to see toll revenue, gate traffic, fuel levels, or trade history.
- **No integration.** No way to see how gates, SSUs, and economy interact as a connected system.

CivilizationControl is not another Move contract demo. It's the missing layer between on-chain infrastructure and the people who operate it. Smart assemblies are already powerful — CivilizationControl makes that power accessible to tribe leaders who shouldn't need to be developers.

**The differentiator is not what it does on-chain. It's what it makes possible for players who never look at a chain.**

---

## Demo Narrative (3-Minute Video)

### Opening — The Problem (0:00–0:40)

*[Screen: a terminal with raw Sui CLI commands scrolling. Dense, technical, intimidating.]*

**Voiceover:** *"This is what managing a gate on EVE Frontier looks like today. Raw commands. Manual queries. No visibility. If you're a tribe leader running twenty gates across three systems... you're flying blind."*

*[Quick cuts: error messages, manual fuel queries, Discord screenshots of "is the gate down?" messages.]*

**Voiceover:** *"Smart assemblies are the most powerful tool in the frontier. The problem is, they don't come with a dashboard."*

### The Reveal — CivilizationControl (0:40–1:10)

*[Cut to: the CivilizationControl dashboard loading. Clean UI. Structure sidebar populating with gates and SSUs. Status indicators going green.]*

**Voiceover:** *"CivilizationControl changes that. One screen. Every gate. Every storage unit. Live status. Real-time activity."*

*[Camera pans across the dashboard: structure list, policy panel, event feed.]*

**Voiceover:** *"This is what infrastructure management should feel like on the frontier."*

### Control — GateControl in Action (1:10–1:50)

*[Click into a gate. Policy panel opens. Tribe filter toggle set to Tribe 7. Toll slider set to 5 Lux.]*

**Voiceover:** *"GateControl lets you set the rules on your gates — who passes through, and what they pay. Tribe filter. Toll. Both active on the same gate, composing as layers within the existing extension model."*

*[A jump event appears in the activity feed: Pilot from Tribe 7, toll paid: 5 Lux. Green checkmark.]*

**Voiceover:** *"A friendly pilot jumps through. Tribe matches, toll paid, passage granted. One atomic transaction."*

*[A second jump attempt: Pilot from Tribe 3. Red X. Access denied.]*

**Voiceover:** *"A hostile pilot tries the same gate. Tribe mismatch. Blocked. No passage, no appeal, no workaround. On-chain enforcement."*

### Economy — TradePost in Action (1:50–2:30)

*[Switch to TradePost view. SSU storefront with listed items: fuel rods, ammo cells, repair paste. Prices in Lux.]*

**Voiceover:** *"TradePost turns your storage units into storefronts. Stock items, set prices, publish listings."*

*[A buyer interface appears. Selects a fuel rod listing at 30 Lux. Clicks Buy. Transaction confirmation appears. ItemPurchased event in the feed.]*

**Voiceover:** *"A pilot passes through your toll gate — paying 5 Lux — lands at your SSU, and buys fuel for 30 Lux. One click. Atomic settlement. No counterparty risk. The fuel is in their inventory. The revenue is in yours."*

*[Revenue counter ticks up.]*

**Voiceover:** *"The toll feeds the foot traffic. The storefront captures the demand. Your infrastructure pays for itself."*

### The System — Closing (2:30–3:00)

*[Pull back to full dashboard view. Multiple gates, multiple SSUs, activity feed scrolling with jumps and purchases. Revenue totals accumulating.]*

**Voiceover:** *"CivilizationControl is more than a single-purpose gate extension or a standalone marketplace. It's a unified management layer — composable gate policies and frontier commerce, integrated in one control room. Your gates, your rules, your revenue."*

*[Title card: CivilizationControl — The Frontier Control Room]*

**Voiceover:** *"Built on EVE Frontier's extension model. Built for tribe leaders. Built to make your infrastructure worth managing."*

---

## Why This Wins

### Player Utility — "Meaningfully changes how players operate"

This is the highest-leverage criterion. CivilizationControl solves a problem that every tribe leader currently handles through Discord, spreadsheets, and trust. Gate management becomes a dashboard. Trading becomes a storefront. Infrastructure monitoring becomes a feed. The utility isn't theoretical — it's the difference between 20 manual CLI commands and one screen.

### EVE Frontier Relevance & Vibe — "Natural extension of EVE Frontier"

CivilizationControl doesn't import a concept from another ecosystem. It emerges from EVE Frontier's own design: tribal identity, gate infrastructure, SSU inventories, territorial control. The language is frontier-native. The features map directly to how tribes already organize. It extends the game's own systems, not someone else's template.

### Mod Design — "Not a one-off feature"

Two interconnected modules sharing auth patterns and economic flow. GateControl and TradePost compose as a system — toll revenue drives commercial demand, commerce justifies infrastructure investment. This is system-level design, not a single trick. Judges who've read the docs will recognize the composable dynamic field rule pattern and the cross-address PTB composition as thoughtful architectural choices.

### Concept Implementation — "How well concept translated to working mod"

Everything shown in the demo is real. Seven validation tests passed on devnet. Tribe filters block. Tolls collect. Trades settle atomically. Cross-address operations work. This isn't a mockup with a contract that partially compiles. It's a working system built on validated patterns.

### Creativity & Originality — "Bold, novel, uniquely Frontier"

No one has built a management dashboard for EVE Frontier gate and SSU operations. Tribe leaders have structures but no way to see, configure, or monetize them as a unified system. The composable rule engine — stackable tribe filters and tolls on the same gate via dynamic field dispatch — is a novel pattern that the current builder docs don't demonstrate.

### UX & Usability — "Intuitive and usable in real play"

This is the core thesis. The on-chain primitives exist. The UX doesn't. CivilizationControl is, at its heart, a usability project — turning raw smart contract capability into a dashboard that a non-developer tribe leader can operate. Toggle a policy. Stock a storefront. Watch the revenue. No CLI, no Move code, no PTB composition by hand.

### Visual Presentation & Demo — "Clarity and confidence of presentation"

The demo follows a cinematic narrative arc: Problem → Reveal → Control → Economy → System. It opens with the pain (raw CLI), delivers the solution (the dashboard), demonstrates the mechanics (gate policy, atomic trade), and closes with the system-level payoff (interconnected economy). The recorded format gives full control over pacing, framing, and storytelling.

### Player Vote (25% of Best Entry Score)

Players vote for mods they want to use. A tribe leader watching the demo will see their own daily pain reflected in the opening — and their fantasy realized in the dashboard. CivilizationControl is the kind of project that makes a player say "I want that" because it solves a problem they already have. Not a clever toy. A tool they need.

---

## MVP vs Stretch

### Must Ship (Core — Non-Negotiable)

| Deliverable | Why It's Core |
|---|---|
| **GateControl Move module** — tribe filter + coin toll, composable as dynamic field rules | The gate policy engine is the headline feature. Without it, there's no "control" in CivilizationControl. |
| **GateControl web UI** — toggle-based policy builder for gate rules | Without the UI, GateControl is just another Move contract. The dashboard IS the product. |
| **TradePost Move module** — listing CRUD + atomic PTB buy flow | Commerce anchors the economy narrative. Gate tolls without a marketplace is half a story. |
| **TradePost web UI** — browse listings, one-click buy | Same principle: the UI surfaces the value. A contract without a frontend is a demo, not a product. |
| **Dashboard shell** — structure sidebar, module switching, connected layout | The "control room" framing requires a unified view. Individual screens don't tell the system story. |
| **Live event feed** — gate jumps, trade completions, toll revenue | Real-time activity turns a static dashboard into a living control room. This is the "wow" moment. |
| **Recorded demo video** (2–3 minutes) | Required for submission. The demo IS the presentation for judges and voters. |

### Would Be Amazing (Stretch — In Priority Order)

| Stretch Goal | What It Adds | Condition |
|---|---|---|
| **TribeMint** — faction currency (`Coin<TribeToken>`) | Completes the "tribal economy" narrative; tolls and trades denominated in faction currency instead of raw `Coin<SUI>`. Enables Lux-equivalent pricing in a builder-controlled token. Emotionally powerful but adds integration complexity. | Only after both core modules pass a complete demo rehearsal. |
| **LootDrop** — VRF loot crate via on-chain randomness | Adds a "surprise and delight" layer; storefronts can sell mystery crates. Compelling demo moment. | Only if TribeMint is stable. |
| **Stillness testnet deployment** | Earns the "Best Live Frontier Integration" bonus criterion. Shows real-world deployment confidence. | Only if core is polished and time permits. Blocked by sponsored transaction resolution. |

### Not in Scope (Explicitly Excluded)

- Time-window rule types for gates (interesting but not MVP)
- Revenue analytics dashboards (the feed provides live data; historical charts are polish)
- Mobile/responsive layout (desktop-first is fine for demo and hackathon)
- ZK privacy rules for gate access (potential separate submission targeting different prize)
- Cross-faction diplomatic exchange protocols (fascinating but scope creep)

---

## One Last Thing

EVE Frontier gives players programmable building blocks and drops them in a hostile, lawless frontier. The game says: *build your civilization.*

But right now, the builders are working blind. The contracts are powerful, the architecture is elegant, and nobody has built the control room that makes any of it usable.

CivilizationControl isn't the most technically exotic entry in this hackathon. It doesn't use zero-knowledge proofs or AI oracles or novel cryptographic primitives.

What it does is something simpler and harder: it takes the tools that already exist — gates, storage units, tribes, tolls, trades — and turns them into a system that a real tribe leader can see, configure, and profit from. Without writing code. Without trusting strangers. Without flying blind.

The frontier is full of powerful primitives. It's waiting for someone to build the dashboard.

**That's what we're building.**

---

*CivilizationControl — The Frontier Control Room*
*EVE Frontier Hackathon 2026*
