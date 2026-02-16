# EVE Frontier Hackathon — Grounded Project Ideas

> **Grounded in world-contracts.** Every idea in this document maps to real on-chain operations in the EVE Frontier `world-contracts` package (gates, storage units, network nodes, characters, killmails) and the builder extension pattern. No magical game-server powers assumed beyond the hackathon sandbox that will be provided.
>
> **Generated:** 2026-02-15 | **Hackathon starts:** 2026-03-11 (~20 days of LLM-accelerated build time)

---

## Capability Constraints (What We Cannot Do)

Before any idea, acknowledge hard boundaries:

| Constraint | Detail |
|------------|--------|
| **No turret module** | No dedicated turret/defense structure in world-contracts. `Killmail` tracks kills but turret logic is absent. |
| **No Carbon client rendering** | On-chain objects exist but have no in-game 3D representation without the game server sandbox. |
| **No entity spawning** | `anchor()` creates on-chain objects; the game server instantiates them in-world. We assume sandbox provides this. |
| **No FusionAuth/Enoki** | zkLogin requires external credentials. Frame as "optional integration" only. |
| **ZK PoC is standalone** | `eve-frontier-proximity-zk-poc` does NOT import world-contracts. Bridging requires a wrapper or fork — feasible but explicit work. |
| **No range proofs** | No circuit exists for "prove quantity ≥ N" — would need a new circom circuit. |
| **No item bridge** | `game_item_to_chain_inventory()` exists but is normally server-called. Locally/sandbox: we assume authority via sponsored tx. |

**What we DO have access to:**
- Full GovernorCap → AdminCap → OwnerCap hierarchy (we deploy contracts, we are god)
- Gate extensions (authorize_extension, issue_jump_permit, witness pattern)
- SSU extensions (deposit_item, withdraw_item, Auth witness)
- Server-signed proof mocking (register local keypair as server address)
- ZK Groth16 circuits: location (~320ms) and distance (~250ms) attestation
- AdminACL sponsor management
- NWN fuel/energy lifecycle
- Killmail creation and querying
- Full Sui event system + object inspection

---

## Project Ideas

### Idea 1: Gate Policy Engine — Composable Access Rules

- **One-liner:** A web dashboard where gate owners define conditional jump access rules (tribe, time-of-day, toll, reputation) without writing Move code.
- **Why it's cool:** Makes gate access policies configurable through a dashboard — tribe filters, time windows, tolls — without writing Move code. Uses the existing extension model to layer composable rules on top of Frontier's gate system. Corp leaders manage gate policies from a browser. Judges see "accessible gate policy configuration" — a capability layer that doesn't exist in EVE Online.
- **World-contract primitives used:** Gate (`authorize_extension`, `issue_jump_permit`, `jump_with_permit`), Character (`tribe()`), ExtensionConfig (dynamic fields for composable rules)
- **Proofs/auth model:** OwnerCap for gate management; sponsor ACL for jump execution; no server proofs needed for gate access (only for linking). Extension witness pattern: a single deployed "policy engine" extension module with configurable rules stored as dynamic fields.
- **Front-end concept:** Web dApp with: (1) "My Gates" list with status indicators, (2) Rule builder (drag-and-drop: tribe filter, time window, toll amount, cooldown), (3) Live jump log (subscribe to `JumpEvent`), (4) One-click "deploy policy" button that calls `authorize_extension` + sets dynamic field config.
- **Minimal demo slice (48 hours):** Deploy a single Move extension module with `TribeConfig` dynamic field (mirror `tribe_permit.move` example). Build a React form that reads character tribe, sets the config, and issues permits. Show a jump succeeding/failing based on tribe.
- **Stretch goals:** Multi-rule composition (tribe AND time-of-day AND toll), rule templates ("Alliance gate", "Toll bridge", "VIP-only"), jump analytics dashboard, batch policy updates across gate networks.
- **Hard blockers / unknowns:** Dynamic field schema for composable rules needs careful design. Unknown: can we stack multiple `Auth` witnesses on one gate, or must it be one module with internal composition? (Test in playground first.)
- **De-risk plan:** Test `authorize_extension` + `issue_jump_permit` end-to-end on local devnet (Experiment 6 from capabilities doc). Validate dynamic field composition patterns with 2+ rule types.
- **Judge story:** "We made EVE Frontier gate policies accessible — any gate owner can configure composable access rules from a browser without writing code. This is like having Cloudflare Access for space." Demonstrates deep world-contracts integration + real Move extension code + clean UX.

---

### Idea 2: Corp Command Center — Multi-Structure Dashboard

- **One-liner:** A real-time web dashboard showing all your structures (gates, SSUs, NWNs), their status, fuel levels, inventories, and recent events, with alerts for critical states.
- **Why it's cool:** No one wants to `sui client object` 50 times. Corp leaders need operational visibility. This is the "home screen" every EVE Frontier builder will want but doesn't exist yet.
- **World-contract primitives used:** Gate (`status`, `linked_gate_id`, `extension`), StorageUnit (`status`, `inventory_keys`, `metadata`), NetworkNode (`status`, `fuel`, `connected_assembly_ids`), Character (owner mapping), all `StatusChangedEvent` + `FuelEvent` subscriptions
- **Proofs/auth model:** Read-only (no proofs needed). Uses `sui client objects` / SuiJSON RPC to query owned objects. Optional: connect via evevault wallet standard for auth.
- **Front-end concept:** React dashboard with: (1) Structure grid (cards: Gate/SSU/NWN with status badges), (2) NWN fuel gauges with time-to-empty estimates, (3) SSU inventory browser (item types, quantities, volumes), (4) Event feed (recent jumps, deposits, withdrawals, status changes), (5) Alert panel (fuel low, structure offline, NWN disconnected).
- **Minimal demo slice (48 hours):** Read-only dashboard that queries 3-5 pre-deployed structures via Sui RPC, shows status/fuel/inventory in cards, and displays last 10 events. No write operations.
- **Stretch goals:** Real-time WebSocket event subscription, fuel burn rate prediction ("NWN goes offline in 4h 23m"), multi-character view (corp), push notifications (via browser notifications), export to CSV.
- **Hard blockers / unknowns:** Need to correctly parse dynamic fields for inventory. Fuel burn rate calculation requires understanding the `fuel` module's efficiency model.
- **De-risk plan:** Deploy world-contracts + create 3 structures on local devnet (Experiments 3/4/7), then build RPC queries for each object type. Validate fuel state parsing.
- **Judge story:** "Every EVE Frontier builder will need this. We're the Dune Analytics of EVE Frontier structures." Pure utility play — solves a real problem every player has, demonstrates understanding of all assembly types.

---

### Idea 3: SSU Storefront — Player-Run Marketplace

- **One-liner:** Turn any Smart Storage Unit into a shop: list items with prices, browse/buy from a web interface, with on-chain escrow via a custom extension.
- **Why it's cool:** EVE Frontier has no built-in marketplace. This creates player-driven commerce infrastructure anchored to physical locations (SSUs). Industrialists dream of this.
- **World-contract primitives used:** StorageUnit (`authorize_extension`, `deposit_item`, `withdraw_item`, `game_item_to_chain_inventory`), custom extension with `ListingConfig` dynamic fields (price, item_type_id, quantity), SUI Coin for payment
- **Proofs/auth model:** Extension witness for deposit/withdraw. Buyer pays SUI → extension verifies payment → issues withdrawal of listed item. Owner manages listings via OwnerCap. Sponsor ACL for initial item minting.
- **Front-end concept:** Web dApp with: (1) "Browse Storefronts" — list of SSUs with active listings, (2) Shop page — item cards with prices, (3) "Buy" button — PTB that sends SUI + calls extension's `buy()` function, (4) "Manage Listings" — owner sets prices, quantities, adds/removes items.
- **Minimal demo slice (48 hours):** Deploy extension with a single `Listing` struct (price, type_id, quantity). Implement `buy()` that checks SUI payment, withdraws item from SSU inventory, transfers to buyer. Build a simple React list of items + buy button.
- **Stretch goals:** Order book (limit orders), price history (from events), multi-SSU aggregated search, reputation system (successful trades count), bulk buy/sell, featured listings.
- **Hard blockers / unknowns:** Items have `key + store` but are in SSU inventories as dynamic fields. Need to verify that `withdraw_item<Auth>()` can transfer items cross-address (to buyer's character/SSU). Payment flow: do we hold SUI in escrow or direct transfer?
- **De-risk plan:** Test `deposit_item` + `withdraw_item` extension pattern on local devnet. Verify item transfer mechanics. Prototype a minimal `buy()` function in Move that accepts SUI Coin.
- **Judge story:** "We built the first decentralized marketplace for EVE Frontier — players can set up shops in space and trade without trusting each other." High player value + economy narrative + demonstrates SSU extension mastery.

---

### Idea 4: Killmail Intelligence — PvP Analytics Dashboard

- **One-liner:** A web app that indexes killmails from the Sui chain, visualizes kill patterns (who, where, what), and generates threat assessments and territorial heat maps.
- **Why it's cool:** zKillboard is the most-used third-party tool in EVE Online — this is its EVE Frontier equivalent, but on-chain and verifiable. PvP players and corp leaders obsess over kill data.
- **World-contract primitives used:** Killmail (query `KillmailCreatedEvent`), Character (`tribe_id`, `character_address`), Gate/SSU/NWN location data (for spatial correlation), `LossType` enum (SHIP vs STRUCTURE)
- **Proofs/auth model:** Read-only indexing. No proofs needed. Queries `sui_getEvents` RPC filtered by `KillmailCreatedEvent` package+module.
- **Front-end concept:** React app with: (1) Kill feed (sortable by time, loss type, tribe), (2) Player profiles (kill/death ratios, favorite targets, threat score), (3) Heat map (solar systems with kill density — uses location hashes as keys even if not decoded), (4) Corp/tribe leaderboards, (5) Structure loss tracker (which SSUs/gates are dying and where).
- **Minimal demo slice (48 hours):** Create 10+ killmails on local devnet with varying data. Build an indexer that queries events, stores in local state. Display a sortable kill feed with basic stats (kills by tribe, by loss type).
- **Stretch goals:** Real-time kill alerts, threat prediction ("this area has 3x more kills than average"), corp war tracking (tribe A vs tribe B kills over time), API for other builders to query, embeddable widgets.
- **Hard blockers / unknowns:** Killmail data richness depends on what fields are stored (need to inspect the `Killmail` struct). Location correlation requires understanding location hash mapping. On sandbox, we create killmails ourselves (admin-only function) — need to generate interesting test data.
- **De-risk plan:** Create a batch of killmails on local devnet (Experiment 9), query events, validate data fields available. Build mock data generator for demo.
- **Judge story:** "zKillboard for EVE Frontier — but on-chain, verifiable, and real-time. Every PvP player needs this." Universal appeal + low implementation risk + demonstrates chain data utilization.

---

### Idea 5: ZK Gate Pass — Anonymous Jump Access via Zero-Knowledge Proofs

- **One-liner:** A gate extension where players prove they're authorized to jump WITHOUT revealing their identity, tribe, or exact location — using the Groth16 ZK circuits from the proximity PoC.
- **Why it's cool:** This is genuinely novel — no other hackathon entry will have privacy-preserving gate access. It demonstrates that EVE Frontier can support trustless privacy on-chain. Judges see "ZK proofs in a game" — high "wow" factor.
- **World-contract primitives used:** Gate (`authorize_extension`, `issue_jump_permit`, `jump_with_permit`), ZK PoC (`location_attestation`, `distance_attestation` circuits), custom extension that wraps ZK verification
- **Proofs/auth model:** Client generates a Groth16 location attestation proof (~320ms). The gate extension verifies it on-chain via `sui::groth16`. If the proof is valid (player is within range of the gate's committed location), a JumpPermit is issued. The gate never learns the player's exact coordinates or identity (only that a valid proof exists).
- **Front-end concept:** Web dApp with: (1) "Generate Proof" button (runs snarkjs in browser or calls local service), (2) Proof status indicator, (3) "Jump" button (submits proof + calls extension), (4) Gate owner admin panel (set authorized location commitment, manage allowed signers).
- **Minimal demo slice (48 hours):** Deploy the ZK PoC Move modules alongside a wrapper extension that calls `verify_location_attestation()` and issues a `JumpPermit` if valid. Generate a proof client-side, submit it, show the jump succeeding. Focus on the "proof works on-chain" demo.
- **Stretch goals:** Distance-gated access (prove you're within N units), anonymous toll payment (ZK proof + Coin transfer without linking identity), proof batching for multiple gates, browser-based proof generation (snarkjs WASM).
- **Hard blockers / unknowns:** The ZK PoC is standalone — it doesn't import world-contracts. Need a bridge: either (a) wrapper module that calls both ZK verification and gate permit issuance, or (b) fork world-contracts to accept Groth16 proofs. Approach (a) is safer. Browser-side proof generation with snarkjs WASM needs testing for performance.
- **De-risk plan:** Run ZK PoC integration tests first (Experiments 11-12) to validate circuit compilation + on-chain verification. Then build a minimal wrapper extension. Test snarkjs WASM in browser for proof generation time.
- **Judge story:** "We brought zero-knowledge proofs to EVE Frontier — players can use gates without revealing who they are or where they are. This is the future of privacy-preserving game infrastructure." Highest novelty score. Requires technical depth but is achievable with the PoC already in-repo.

---

### Idea 6: Fuel Watch — NWN Monitoring & Auto-Alert System

- **One-liner:** A monitoring service that tracks Network Node fuel levels across your fleet, predicts when each NWN will run dry, and alerts you before structures go offline.
- **Why it's cool:** Fuel management is tedious but critical — if your NWN goes offline, ALL connected gates and SSUs cascade offline. This is the "Datadog for your space infrastructure."
- **World-contract primitives used:** NetworkNode (`fuel`, `status`, `connected_assembly_ids`), `FuelEvent` subscription, `StatusChangedEvent`, fuel efficiency model (`fuel::set_fuel_efficiency`), Energy config (`energy::set_energy_config`)
- **Proofs/auth model:** Read-only monitoring (no proofs). Optional: OwnerCap-gated admin view for fuel deposit actions. Sponsor ACL for fuel deposit transactions.
- **Front-end concept:** Web app with: (1) Fleet overview (NWN cards with fuel gauges + time-to-empty), (2) Connected assemblies tree (which gates/SSUs depend on each NWN), (3) Fuel burn timeline (historical + projected), (4) Alert rules (email/webhook/browser notification when fuel < threshold), (5) One-click refuel action (if wallet connected).
- **Minimal demo slice (48 hours):** Deploy 2 NWNs with different fuel levels. Build a page showing fuel state, connected assembly count, and a hardcoded burn rate estimation. Display "time to offline" countdown.
- **Stretch goals:** Multi-account fleet view, fuel cost optimization ("refuel NWN-A first, it has more assemblies"), historical fuel consumption analytics, automated refuel bot (watches and deposits fuel when low), webhook integrations.
- **Hard blockers / unknowns:** Fuel burn rate calculation logic needs to match the Move `fuel` module's math exactly. Need to understand the `efficiency` parameter and how `Clock` timestamps affect burn.
- **De-risk plan:** Deploy a NWN, deposit fuel, bring online, wait, check fuel state at intervals. Reverse-engineer the burn rate formula from the Move source.
- **Judge story:** "Every builder will lose structures to fuel starvation — we solved that problem. This is infrastructure monitoring for decentralized space." Practical utility + demonstrates understanding of NWN mechanics.

---

### Idea 7: Alliance Gate Network — Multi-Owner Jump Highways

- **One-liner:** A protocol for multiple gate owners to form an alliance, contribute gates to a shared network, and manage joint access policies — like a decentralized highway authority.
- **Why it's cool:** Individual gates are useful; a coordinated network of gates is transformative. This creates emergent gameplay around territorial control and logistics — the most "EVE-like" idea possible.
- **World-contract primitives used:** Gate (`link_gates`, `authorize_extension`, `issue_jump_permit`), Character (`tribe_id`), custom extension for "AllianceGate" with `AllianceConfig` shared object, access control (OwnerCap for per-gate management, shared config for alliance-wide policies)
- **Proofs/auth model:** Server-signed distance proofs for linking (mock locally). OwnerCap for individual gate operations. Alliance membership managed via a custom shared object with a `VecSet<address>` of member characters. Sponsor ACL.
- **Front-end concept:** Web dApp with: (1) Alliance creation/join flow, (2) Network topology visualizer (gates as nodes, links as edges, interactive graph), (3) Alliance policy manager (default: open to all alliance members; optional: toll for outsiders), (4) Gate contribution dashboard (each member's gate count, uptime), (5) Jump route planner (find shortest path through alliance network).
- **Minimal demo slice (48 hours):** Deploy 4 gates owned by 2 different characters, link them into a network, deploy an alliance extension that checks membership in a shared config object. Show a graph visualization of the network. Demonstrate a member jumping vs a non-member being denied.
- **Stretch goals:** Revenue sharing (toll revenue split among alliance members), gate uptime SLAs, automatic route optimization, alliance mergers, diplomatic relations between alliances, real-time network status.
- **Hard blockers / unknowns:** Gate linking requires owner of BOTH gates. In an alliance, how do we handle linking between different owners? May need a multi-sig or delegation pattern (not natively supported — need extension design). Distance proof mocking for multiple gate pairs.
- **De-risk plan:** Test linking 2 gates with different owners' OwnerCaps in a single PTB. If that requires `borrow_owner_cap` for both, validate the hot-potato composition. Design alliance membership contract separately.
- **Judge story:** "We built decentralized highway infrastructure for EVE Frontier — multiple players coordinate gates into a network with shared access policies. This is the kind of emergent cooperation that defines EVE." Deep gameplay + multi-contract architecture + network effects.

---

### Idea 8: Corpse Toll Road — Pay-to-Jump with In-Game Items

- **One-liner:** Gate owners set a "toll" that requires depositing specific items (corpses, fuel, rare materials) at a nearby SSU to earn a jump permit — creating player-driven gate economics.
- **Why it's cool:** Directly inspired by the `corpse_gate_bounty` extension example but generalized. Creates an in-game economy loop: gathering → depositing → jumping → gathering. Emergent gameplay that writes itself.
- **World-contract primitives used:** Gate (`authorize_extension`, `issue_jump_permit`), StorageUnit (`withdraw_item`, `deposit_item` via extension), custom extension with `TollConfig` (required item `type_id`, quantity), Character
- **Proofs/auth model:** Extension witness for SSU operations. Proximity proof for player's `withdraw_by_owner` (mocked locally). Sponsor ACL. The existing `corpse_gate_bounty.move` example is the template — generalize it to accept configurable item types.
- **Front-end concept:** Web dApp or in-game overlay with: (1) "Toll Gates" directory (gates with active tolls), (2) Toll details (what item, how many, nearby SSU location), (3) "Pay Toll" flow (deposit item → receive permit → jump), (4) Gate owner "Set Toll" form (item type, quantity, linked SSU).
- **Minimal demo slice (48 hours):** Fork `corpse_gate_bounty.move` to accept a configurable `type_id` instead of hardcoded corpse. Deploy it, set toll to a specific item type. Build a web form showing toll requirements and a "Pay & Jump" button that executes the full PTB (withdraw from player SSU → deposit to toll SSU → receive permit → jump).
- **Stretch goals:** Multi-item tolls (require item A AND item B), dynamic pricing (toll increases with traffic), revenue dashboard for gate owners, toll history/analytics, "free pass" tokens for allies.
- **Hard blockers / unknowns:** The `corpse_gate_bounty` example combines SSU withdraw + SSU deposit + gate permit in one PTB. Need to validate this multi-operation PTB locally. Item `type_id` mapping (what items exist in sandbox?) is unknown until sandbox details arrive.
- **De-risk plan:** Deploy `corpse_gate_bounty.move` as-is on local devnet and execute the full flow. Then modify to accept configurable type_id. This is the most directly testable idea — the reference code already exists.
- **Judge story:** "We created toll roads in space — pay with loot to jump through gates. This creates a natural economy loop that drives player interaction." Builds on existing extension example (safe foundation) + adds novel economics.

---

### Idea 9: Dead Drop — Anonymous Item Exchange via ZK Proofs

- **One-liner:** Two players exchange items through an SSU without either knowing who the other is — using ZK location proofs to verify proximity without revealing identity.
- **Why it's cool:** Anonymous trade in a space MMO. Spy gameplay, black market mechanics, diplomatic backchannel exchanges. The ZK PoC enables something no server-signed proof can: true anonymity.
- **World-contract primitives used:** StorageUnit (`deposit_item`, `withdraw_item` via extension), ZK PoC (`location_attestation` for proximity verification), custom "DeadDrop" extension with anonymous deposit/withdrawal slots
- **Proofs/auth model:** ZK location attestation proves a player is near the SSU without revealing their identity. The extension creates numbered "slots" — depositor leaves items in slot N, withdrawer proves proximity + knows slot N, collects items. No identities recorded on-chain (only proof of valid proximity).
- **Front-end concept:** Web dApp with: (1) "Create Dead Drop" — owner designates an SSU and creates a numbered slot, (2) "Deposit" — prove proximity via ZK, deposit items to slot, receive a secret access code, (3) "Collect" — enter access code + prove proximity via ZK, withdraw items from slot. Minimal UI: just slot number, proof status, and action buttons.
- **Minimal demo slice (48 hours):** Deploy a wrapper extension that stores items in SSU inventory keyed by a hash (the "slot"). Depositor provides a preimage (secret); withdrawer provides the same preimage to claim. Add ZK proximity proof as the location verification layer. Show two different addresses depositing and withdrawing without linking.
- **Stretch goals:** Time-locked drops (expire after N hours), multi-item drops, reputation-gated drops (require previous successful trades), encrypted metadata (what's in the drop, encrypted to recipient's key), dead drop discovery (find nearby drops without knowing contents).
- **Hard blockers / unknowns:** Bridging ZK PoC with SSU extension requires a wrapper module. Anonymous slots need a hashing scheme (Poseidon on-chain via `sui::poseidon` or simple `sha256`). Privacy is only as strong as the ZK proof — need to ensure no identity leaks in events.
- **De-risk plan:** Build the slot-based deposit/withdraw without ZK first (just hash preimage). Then layer ZK proximity proof on top. Test ZK proof generation in browser.
- **Judge story:** "We built anonymous dead drops in space — players can exchange items without either side knowing who the other is, verified by zero-knowledge proofs. This is spy gameplay on the blockchain." Maximum novelty. Unique technical depth.

---

### Idea 10: Structure Insurance — Automated Killmail-Triggered Payouts

- **One-liner:** Players insure their structures by depositing SUI into an insurance pool. When a killmail records their structure's destruction, the contract automatically pays out — verifiable, no claims process.
- **Why it's cool:** Automated, trustless insurance is a classic DeFi primitive applied to gaming. It creates a market for risk — players can insure high-value structures. Judges see "DeFi meets gaming" crossover.
- **World-contract primitives used:** Killmail (`create_killmail`, `KillmailCreatedEvent`, `LossType::STRUCTURE`), custom insurance module with Pool (SUI balance), Policy objects (insured structure ID, coverage amount), Character (policyholder)
- **Proofs/auth model:** Admin creates killmails (production: game server does this). Insurance contract watches for killmails matching insured structure IDs. Payout is automatic in the `process_claim()` function called by anyone after a matching killmail exists. No proofs needed — killmails are on-chain truth.
- **Front-end concept:** Web dApp with: (1) "Insure Structure" form (select structure, choose coverage amount, deposit premium), (2) Insurance portfolio (your policies, coverage amounts, premiums paid), (3) Claims dashboard (recent killmails, matched policies, payouts), (4) Pool stats (total insured value, loss ratio, pool balance).
- **Minimal demo slice (48 hours):** Deploy an insurance module with `create_policy()` (deposit SUI, specify structure ID), `process_claim()` (look up killmail by structure ID, verify `LossType::STRUCTURE`, transfer payout). Create a killmail, show automatic payout. Build simple web form for creating policies.
- **Stretch goals:** Variable premiums (based on location risk from killmail heat map), multi-tier coverage, insurance DAO (pool governed by token holders), re-insurance markets, actuarial analytics.
- **Hard blockers / unknowns:** How to programmatically match a killmail to an insured structure ID — need to inspect killmail struct fields for structure identifiers. Killmail creation is admin-only (sandbox: we control admin). Premium pricing model needs design.
- **De-risk plan:** Create a killmail with known structure ID (Experiment 9), then build a lookup function. Validate SUI Coin transfer mechanics in a simple Move module.
- **Judge story:** "Trustless insurance for space structures — when your gate gets destroyed, you get paid automatically, verified by on-chain killmails. No claims adjusters in space." DeFi + gaming crossover + demonstrates killmail utilization.

---

### Idea 11: Time-Locked Vault — Scheduled SSU Access Windows

- **One-liner:** An SSU extension that only allows deposit/withdrawal during configurable time windows — creating scheduled market hours, timed supply drops, or "after-hours" secure storage.
- **Why it's cool:** Time-based access control is simple to explain, universally understood ("the vault opens at midnight"), and creates gameplay tension. Judges see "smart contract + time = emergent gameplay."
- **World-contract primitives used:** StorageUnit (`authorize_extension`, `deposit_item`, `withdraw_item`), Clock object (Sui system), custom extension with `ScheduleConfig` dynamic field (open_hour, close_hour, days_active)
- **Proofs/auth model:** Extension witness for SSU operations. Time verification uses Sui's `Clock` object (`clock::timestamp_ms()`). No location proofs needed for extension-mediated access. OwnerCap for schedule management.
- **Front-end concept:** Web dApp with: (1) "My Vaults" — SSUs with time-lock status (open/closed, next open time), (2) "Set Schedule" — owner configures open/close times, (3) "Deposit/Withdraw" — active only during open windows (button grayed out otherwise), (4) Countdown timer to next open/close.
- **Minimal demo slice (48 hours):** Deploy extension with `ScheduleConfig` holding `open_timestamp_ms` and `close_timestamp_ms`. `withdraw_item` checks `clock.timestamp_ms() >= open && clock.timestamp_ms() <= close`. Build React page showing countdown + deposit/withdraw buttons.
- **Stretch goals:** Recurring schedules (daily/weekly), multi-zone time support, auction windows (highest bidder gets withdrawal rights during window), "flash sale" events, emergency override by owner.
- **Hard blockers / unknowns:** Sui Clock granularity and timezone handling. Local devnet clock may not advance realistically — need to test. Simple epoch-based windows are safest.
- **De-risk plan:** Test `clock::timestamp_ms()` behavior on local devnet. Build minimal extension, call at different devnet times. Use short windows (minutes, not hours) for demo.
- **Judge story:** "We made storage units respect time — vaults that open on schedule, creating timed supply drops and market hours in space. Simple concept, deep implications." Elegant + easy to demo + universally understandable.

---

### Idea 12: Bounty Board — Player-Posted Kill Contracts

- **One-liner:** A shared on-chain bounty board where players post bounties on targets. When a killmail matching the target appears, the bounty automatically pays out to the killer.
- **Why it's cool:** Bounty systems are beloved in EVE Online but notoriously gameable. On-chain enforcement (killmail verification + automatic payout) makes bounties trustless and ungameable. PvP players love this.
- **World-contract primitives used:** Killmail (match target character/structure), Character (`tribe_id`, address), custom bounty module with Bounty objects (target, reward, poster), SUI Coin for escrow
- **Proofs/auth model:** Bounty creation: deposit SUI into escrow. Bounty claim: anyone can call `claim_bounty()` with a killmail ID. Contract verifies killmail.victim matches bounty.target and killmail.attacker matches claimant. Auto-transfers escrowed SUI.
- **Front-end concept:** Web dApp with: (1) Bounty board (active bounties: target, reward, poster), (2) "Post Bounty" form (target address/name, reward amount), (3) "Claim Bounty" (enter killmail ID, auto-verification), (4) Leaderboard (top bounty hunters), (5) My Bounties (posted + earned).
- **Minimal demo slice (48 hours):** Deploy bounty contract with `post_bounty(target, Coin<SUI>)` and `claim_bounty(bounty, killmail)`. Create test killmails. Build web form for posting + claiming. Show automated payout.
- **Stretch goals:** Anonymous bounties (ZK proof that poster authorized the bounty without revealing identity), multi-target bounties, bounty pools (multiple posters fund same target), time-limited bounties (expire and return funds), hunt tracking.
- **Hard blockers / unknowns:** Killmail struct must contain attacker and victim identifiers we can match against. Need to verify killmail fields. In sandbox, we create killmails ourselves.
- **De-risk plan:** Inspect killmail struct fields (Experiment 9). Verify we can match character address or ID to killmail participants. Prototype SUI escrow transfer.
- **Judge story:** "Trustless bounty hunting — post a bounty, it pays out automatically when the kill is verified on-chain. No more bounty scams." Classic EVE mechanic + blockchain enforcement + immediately understandable.

---

### Idea 13: Gate Traffic Analytics — Jump Network Intelligence

- **One-liner:** Index all JumpEvents, visualize gate traffic patterns, and provide gate owners with utilization data, peak hours, and revenue optimization insights.
- **Why it's cool:** Gate owners are blind — they deploy gates but have no idea how much traffic flows through them. This is Google Analytics for jump gates. Data-driven gate management.
- **World-contract primitives used:** Gate (`JumpEvent` subscription — source/destination gate IDs + character), Character (tribe mapping), StatusChangedEvent, gate metadata
- **Proofs/auth model:** Read-only event indexing. No proofs. Optional: OwnerCap-gated views for private gate analytics.
- **Front-end concept:** Web app with: (1) Network map (gates as nodes, traffic volume as edge thickness), (2) Per-gate analytics (jumps/hour, unique characters, tribe distribution), (3) Peak hour heatmap, (4) Comparison view (my gate vs network average), (5) Revenue estimator (if toll gates: projected income at different toll levels).
- **Minimal demo slice (48 hours):** Deploy 3 linked gates, execute 20+ jumps with different characters. Build indexer from JumpEvents. Display per-gate jump counts + timeline chart.
- **Stretch goals:** Real-time streaming, predictive analytics ("traffic will increase 30% during weekend"), competitor analysis, toll pricing optimizer, API for other builders.
- **Hard blockers / unknowns:** JumpEvent must contain gate IDs and character reference. Need to verify event payload format. Volume of events on sandbox may be low for meaningful analytics.
- **De-risk plan:** Deploy gates, execute jumps, query JumpEvents via Sui RPC. Validate event schema. Generate synthetic traffic data for demo.
- **Judge story:** "We built the first analytics platform for EVE Frontier infrastructure — gate owners can see their traffic, optimize their tolls, and make data-driven decisions." Analytics + infrastructure = strong narrative.

---

### Idea 14: Tribal Diplomacy Protocol — On-Chain Alliance Management

- **One-liner:** A Move module + web dApp for tribes to establish formal diplomatic relations (ally, neutral, hostile) on-chain, with gate access policies that automatically reflect diplomatic status.
- **Why it's cool:** Diplomacy in EVE is done via spreadsheets and Discord. On-chain diplomacy creates enforceable, transparent agreements that automatically affect infrastructure access. This is "smart contract diplomacy."
- **World-contract primitives used:** Character (`tribe_id`), Gate (`authorize_extension`, `issue_jump_permit` — permit issuance checks diplomatic status), custom DiplomacyConfig shared object (tribe→tribe relation mappings)
- **Proofs/auth model:** DiplomacyConfig updated by tribe representatives (authorized via a per-tribe `TribeAdminCap`). Gate extension reads diplomatic status before issuing permits.
- **Front-end concept:** Web dApp with: (1) Diplomacy matrix (tribe × tribe grid: ally/neutral/hostile), (2) "Propose Relation" flow (send proposal, counterparty accepts/rejects), (3) Treaty history, (4) "Apply to Gates" — batch-update all your gate extensions to reflect current diplomacy. Shows which gates allow/deny which tribes.
- **Minimal demo slice (48 hours):** Deploy DiplomacyConfig with `set_relation(tribe_a, tribe_b, status)`. Deploy gate extension that reads relation status before issuing permits. Show: Allied tribe member jumps ✓, Hostile tribe member denied ✗. Build diplomacy matrix UI.
- **Stretch goals:** Treaty expiration, mutual defense pacts (automatic bounty posting on hostiles), economic treaties (toll discounts for allies), public treaty registry, historical treaty visualization.
- **Hard blockers / unknowns:** How to authorize per-tribe representatives — need a "TribeAdminCap" mechanism. In sandbox we control all characters' tribe IDs. Multi-party agreement (both tribes must approve relation change) adds complexity.
- **De-risk plan:** Start with unilateral relations (one-sided, no approval needed). Create characters with different tribe IDs, test tribe-gated access. Then add bilateral approval.
- **Judge story:** "We put diplomacy on the blockchain — tribes can form enforceable alliances that automatically open gates and deny enemies. No more broken promises." Unique EVE-flavored concept + governance + automation.

---

### Idea 15: Logistics Router — Optimal Jump Route Planner

- **One-liner:** Given a set of linked gates, compute and display the shortest path between any two points in the jump network — a Google Maps for EVE Frontier's gate infrastructure.
- **Why it's cool:** As gate networks grow, route planning becomes non-trivial. Haulers need efficient routes. Military planners need to know enemy chokepoints. This is pure utility with high discoverability.
- **World-contract primitives used:** Gate (`linked_gate_id` for network topology), Gate metadata (names, locations), `StatusChangedEvent` (for live network state), Character (for personalized routing based on gate access)
- **Proofs/auth model:** Read-only graph computation. Queries gate link topology via RPC. Optional: check which gates the user's character can actually access (tribe-gated, toll-gated) and route around denied gates.
- **Front-end concept:** Web app with: (1) Interactive network graph (nodes = gates, edges = links), (2) Route search (from gate A to gate B → shortest path highlighted), (3) Access-aware routing ("you can't jump through gate X — rerouting"), (4) Network stats (total gates, links, disconnected components, chokepoints).
- **Minimal demo slice (48 hours):** Deploy 6+ gates with various links. Read topology from chain. Implement Dijkstra/BFS in the front-end. Display graph + highlighted shortest path.
- **Stretch goals:** Live topology updates (gate goes offline → route recalculates), fuel cost estimation (jumps use energy), multi-stop route planning, network vulnerability analysis ("if gate X dies, these routes break"), shareable route links.
- **Hard blockers / unknowns:** Gate links are stored as `linked_gate_id` (optional) — need to build full bidirectional graph from chain state. Gate location hashes can't be decoded (privacy-preserving) — use gate names/IDs instead of spatial coordinates for display.
- **De-risk plan:** Deploy 4 gates, link them in a chain, query `linked_gate_id` for each. Build adjacency list. Validate graph construction.
- **Judge story:** "Google Maps for EVE Frontier — find the fastest route through the gate network, with real-time awareness of which gates you can actually access." Universal utility + graph visualization is visually impressive.

---

### Idea 16: Gate Graffiti Wall — On-Chain Message Board at Jump Points

- **One-liner:** Attach a decentralized message board to any gate — players leave messages (warnings, ads, jokes, intel) that anyone jumping sees, stored immutably on-chain.
- **Why it's cool:** It's weird, fun, and social. "Messages in bottles at jump points" — creates emergent social gameplay, player-driven content, and information warfare. Unlike the logistical ideas, this is pure social expression.
- **World-contract primitives used:** Gate (anchor point for messages — gate ID used as key), custom Graffiti module with `Message` objects (dynamic fields on a shared `GraffitiBoard` keyed by gate ID), Character (author attribution + optional anonymity)
- **Proofs/auth model:** Any player can post (permissionless). Messages stored as dynamic fields on a shared object keyed by gate ID. Optional: gate owner can moderate (delete messages) via OwnerCap. Optional ZK twist: anonymous messages via ZK proximity proof (prove you were at the gate without revealing who you are).
- **Front-end concept:** Simple web app or in-game overlay with: (1) "Read Wall" — latest messages at selected gate, (2) "Post" — text input + submit, (3) Optional: "React" (upvote/flag), (4) "Browse Gates" — see which gates have most activity.
- **Minimal demo slice (48 hours):** Deploy GraffitiBoard shared object. Implement `post_message(gate_id, text, character)` and `read_messages(gate_id)`. Build a React page showing messages for a selected gate with a text input for posting.
- **Stretch goals:** Message expiry (oldest messages pruned after N posts), encrypted messages (only intended recipient can read — use ecies), image/link embeds, reputation scoring (prolific posters get badges), "most graffiti'd gate" leaderboard, anonymous posting via ZK proof.
- **Hard blockers / unknowns:** Dynamic field storage costs on Sui (messages accumulate). Gas costs for posting. Need a pruning strategy. Message size limits.
- **De-risk plan:** Test dynamic field creation/read on local devnet. Verify gas costs for 100+ messages per gate. Design pruning mechanism before demo day.
- **Judge story:** "We built bathroom graffiti for space jump gates. Silly? Yes. But it's the most social, human, expressive thing you can do on-chain in a game. And it's all immutable." Novelty + fun + memorable demo.

---

### Idea 17: Energy Arbitrage Bot — Automated Structure Management

- **One-liner:** A bot/automation layer that monitors NWN fuel levels, assembly energy consumption, and automatically manages structure online/offline status to maximize uptime within fuel budgets.
- **Why it's cool:** Managing structures manually is tedious. This automates the "infrastructure ops" of EVE Frontier — like Kubernetes for space bases. Corp leaders who manage dozens of structures need this.
- **World-contract primitives used:** NetworkNode (`fuel`, `online`, `offline`, `deposit_fuel`, `connected_assembly_ids`), Gate (`online`, `offline`), StorageUnit (`online`, `offline`), `FuelEvent`, `StatusChangedEvent`, Clock (fuel timing)
- **Proofs/auth model:** OwnerCap for all online/offline/fuel operations. Bot holds or borrows OwnerCaps via `borrow_owner_cap`. Sponsor ACL for fuel deposits. No location proofs needed for lifecycle management.
- **Minimal demo slice (48 hours):** Deploy NWN + 3 assemblies. Build a script that monitors fuel, sets optimal online/offline schedule, and executes PTBs. Show automated offline when fuel is critically low (protecting the NWN from uncontrolled shutoff).
- **Stretch goals:** Priority-based assembly management (keep gates online before SSUs), fuel purchase automation (if marketplace exists), predictive maintenance, multi-NWN optimization, Slack/Discord alerts.
- **Hard blockers / unknowns:** NWN `offline()` hot-potato pattern requires processing ALL connected assemblies in one PTB — complex PTB construction. Bot needs persistent OwnerCap access (security concern).
- **De-risk plan:** Test the `offline()` → `offline_connected_assembly()` hot-potato chain for 2-3 assemblies. Validate PTB construction for multi-step atomic transitions.
- **Judge story:** "Kubernetes for space — automated infrastructure management that keeps your structures online and optimizes fuel usage." Infra-automation narrative + demonstrates complex PTB construction.

---

### Idea 18: Proof-of-Presence Badge — "I Was There" NFTs

- **One-liner:** Players who visit specific locations (structures, events, battles) earn on-chain badges proving they were there — using ZK proximity proofs so their exact position is never recorded.
- **Why it's cool:** POAPs (Proof of Attendance Protocol) are a proven concept in web3 events. This applies the same idea to in-game locations with privacy-preserving proofs. Collectible + social + ZK.
- **World-contract primitives used:** ZK PoC (`location_attestation` — prove presence near a location), custom Badge module (mint NFT-like objects), Character (recipient), Gate/SSU (anchor locations for badge events)
- **Proofs/auth model:** Event organizer commits a location (Poseidon hash). Player generates ZK location attestation proof proving proximity. Badge minting contract verifies the proof on-chain via `sui::groth16`. Badge is transferred to player's address. No identity or exact location recorded.
- **Front-end concept:** Web dApp with: (1) "Active Events" — list of locations offering badges, (2) "Claim Badge" — generate proof + submit, (3) "My Badges" — collection gallery, (4) Event creation (organizer sets location + badge metadata).
- **Minimal demo slice (48 hours):** Deploy badge contract with `mint_badge(proof, event_config)`. Pre-commit a location. Generate a proof using ZK PoC tooling. Show badge appearing in player's collection after proof verification.
- **Stretch goals:** Badge rarity tiers (based on distance: closer = rarer), time-limited events, badge trading/marketplace, badge-gated gate access ("only players who have the Starfall Badge can use this gate"), cross-event collections.
- **Hard blockers / unknowns:** Same bridge challenge as Idea 5 — ZK PoC is standalone. Badge standard on Sui (use `sui::display` + `key/store`). Browser-side proof generation performance.
- **De-risk plan:** Run ZK PoC integration tests first. Build a simple NFT-like object on local devnet. Then bridge the two.
- **Judge story:** "Proof of presence for space — visit a location, earn a verifiable badge, without anyone knowing where you were. Privacy-preserving collectibles in a game." ZK + collectibles + gaming = strong narrative.

---

### Idea 19: Corp Treasury Manager — Multi-Sig Structure Ownership

- **One-liner:** A module enabling corp-level ownership of structures via a multi-sig pattern — N-of-M corp officers must approve critical operations (offline, unanchor, extension changes).
- **Why it's cool:** Currently, structures have single owners (one OwnerCap). This is fine for solo players but dangerous for corps — one rogue officer can offline everything. Multi-sig ownership is table-stakes for organized play.
- **World-contract primitives used:** OwnerCap pattern (wrap in multi-sig), Gate/SSU/NWN (all OwnerCap-gated operations), Character (corp officers), custom MultiSig module with Proposal objects and vote tracking
- **Proofs/auth model:** MultiSig contract holds the OwnerCap. Officers submit Proposal objects (e.g., "take gate X offline"). When N-of-M officers approve, the contract borrows the OwnerCap via `borrow_owner_cap` and executes the operation. Uses Sui's transfer-to-object for OwnerCap custody.
- **Front-end concept:** Web dApp with: (1) Corp structures list (with multi-sig status), (2) Pending proposals (description, votes so far, remaining needed), (3) Vote buttons, (4) Audit log (all proposals + outcomes).
- **Minimal demo slice (48 hours):** Deploy a 2-of-3 multi-sig module. Transfer a gate's OwnerCap to it. Create a "go offline" proposal, have 2 accounts approve, show the gate going offline. Build a proposal list + vote UI.
- **Stretch goals:** Configurable thresholds per operation type (offline = 2/3, unanchor = 3/3), time-locked proposals (48h approval window), emergency override (single officer + higher threshold), delegation, role-based access (officers vs members).
- **Hard blockers / unknowns:** OwnerCap is transferred to Character via `Receiving`. Multi-sig contract needs to hold the OwnerCap and be able to call `borrow_owner_cap` — need to verify the object-to-object transfer model supports a contract-held cap.
- **De-risk plan:** Test transferring OwnerCap to a non-Character object. If that's not supported, design a Character-based proxy (multi-sig "Character" that represents the corp). Test `borrow_owner_cap` from a module context.
- **Judge story:** "Multi-sig governance for space structures — no single officer can go rogue. This is the DAO tooling that EVE Frontier corps need to operate safely." Governance + security + immediate utility.

---

### Idea 20: Gate Leaderboard — Competitive Gate Network Rankings

- **One-liner:** A public leaderboard ranking gate networks by traffic volume, uptime, coverage, and user satisfaction — gamifying infrastructure management.
- **Why it's cool:** Leaderboards drive competition. Gate owners compete to have the most reliable, most trafficked network. Creates a feedback loop: better gates → more traffic → higher ranking → more visibility → more traffic. Judges understand leaderboards instantly.
- **World-contract primitives used:** Gate (`JumpEvent` for traffic), `StatusChangedEvent` (for uptime calculation), NetworkNode (`FuelEvent` for operational consistency), Character (gate owner attribution)
- **Proofs/auth model:** Read-only event indexing. No proofs. Computed entirely from on-chain events.
- **Front-end concept:** Web app with: (1) Global rankings (table: rank, gate/network name, traffic, uptime %, coverage), (2) Gate profile page (stats, recent jumps, owner badge), (3) Comparison tool (side-by-side gate networks), (4) Historical charts, (5) "Network of the Week" spotlight.
- **Minimal demo slice (48 hours):** Deploy 5 gates with varying traffic (different jump counts). Build indexer + ranking algorithm. Display ranked leaderboard with basic stats (jump count, online time).
- **Stretch goals:** Reputation NFTs for top-ranked gates, competitive seasons, weighted scoring (uptime matters more than raw traffic), "verified" badges for gates with high uptime SLAs, embed widgets for gate owners.
- **Hard blockers / unknowns:** Uptime calculation requires correlating StatusChangedEvents over time — needs a historical indexer. Traffic volume may be low on sandbox.
- **De-risk plan:** Generate synthetic traffic data. Build event indexer that processes StatusChangedEvent timestamps. Prototype ranking algorithm.
- **Judge story:** "The Yelp for space gates — see which gate networks are the most reliable, most used, and best maintained. Gamified infrastructure management." Immediately understandable + drives engagement.

---

## Top 5 Shortlist

Based on: feasibility in 20-day LLM-accelerated build, player value, demo moment strength, unique world-contract feature usage, and minimal external dependencies.

### 1. Gate Policy Engine (Idea 1)

**Why #1:** Deepest world-contracts integration (extension pattern, dynamic fields, witness types). Highest practical value (every gate owner wants this). Clean demo: "set a rule, see a jump denied." The extension examples (`tribe_permit.move`, `corpse_gate_bounty.move`) provide validated starting code.

**5-step execution outline:**
1. **Days 1–3:** Fork `tribe_permit.move` into a generalized policy module with `PolicyConfig` dynamic fields supporting 3 rule types (tribe, time-window, toll). Test on local devnet.
2. **Days 4–7:** Build React dashboard: gate selector, rule builder (form-based), deploy/update policy buttons. Wire to Sui RPC for gate state reading + PTB construction for writes.
3. **Days 8–10:** Add JumpEvent subscription for live jump log. Polish rule composition (AND/OR logic). Test with multiple gates + characters.
4. **Days 11–14:** Build "judge demo" flow: create gate → set policy → show authorized jump → show denied jump → show live analytics. Record fallback video.
5. **Days 15–20:** Polish UX, edge cases, README, demo script. Stretch: batch policy updates, multiple gate management.

### 2. Corp Command Center (Idea 2)

**Why #2:** Universal utility — every single builder/player can use this. Pure read-side (low risk of breaking anything). Strong "wow" moment: one screen showing all your structures with live status. Pairs perfectly with any other project as the "dashboard layer."

**5-step execution outline:**
1. **Days 1–3:** Deploy world-contracts + create 3+ structures (NWN, Gate, SSU) on local devnet. Build RPC query layer for each object type.
2. **Days 4–7:** Build React dashboard with structure cards (gate/SSU/NWN), status badges, fuel gauges. Parse dynamic fields for inventory.
3. **Days 8–10:** Add event feed (last N events, filtered by structure type). Add fuel time-to-empty estimation.
4. **Days 11–14:** Build alert rules (fuel < threshold → red indicator). Polish mobile-responsive layout.
5. **Days 15–20:** Demo flow, video fallback, README. Stretch: real-time WebSocket, multi-account view.

### 3. ZK Gate Pass (Idea 5)

**Why #3:** Highest novelty score — no other hackathon entry will have ZK-gated game infrastructure. The ZK PoC is already in-repo with working circuits. "Privacy-preserving gate access" is a 30-second demo that makes judges say "wait, what?" Risk is higher (bridge challenge) but payoff is highest.

**5-step execution outline:**
1. **Days 1–3:** Run ZK PoC full test suite (Experiments 11-12). Validate circuit compilation + on-chain proof verification. Confirm all passes.
2. **Days 4–7:** Build wrapper Move module that (a) verifies ZK location attestation and (b) issues a jump permit if valid. Deploy alongside world-contracts gate.
3. **Days 8–10:** Build browser-based proof generation (snarkjs WASM). Build React UI: "Prove Location" button → proof generation → "Jump" button → permit issuance → jump execution.
4. **Days 11–14:** End-to-end demo: player generates proof in browser (~320ms), submits to chain, gate verifies, permit issued, jump executed. Test with different locations (authorized vs unauthorized).
5. **Days 15–20:** Polish demo flow, handle edge cases, video fallback. Stretch: distance-gated access, anonymous toll.

### 4. SSU Storefront (Idea 3)

**Why #4:** Fills the biggest gap in EVE Frontier (no marketplace). Economy-focused projects have historically done well in blockchain hackathons. The extension pattern (`deposit_item`/`withdraw_item`) is well-documented. Strong demo: "browse items, click buy, item appears in your inventory."

**5-step execution outline:**
1. **Days 1–3:** Build `Storefront` extension module: `Listing` struct (price, type_id, quantity), `list_item()`, `buy()` (verify SUI payment, withdraw item, transfer). Test on local devnet.
2. **Days 4–7:** Build React storefront UI: item cards with prices, "Buy" button (constructs PTB: send SUI + call buy), seller listing management.
3. **Days 8–10:** Add multiple SSU storefronts, search/filter, listing creation flow. Test cross-character purchases.
4. **Days 11–14:** Polish checkout flow, add purchase history (from events), seller dashboard.
5. **Days 15–20:** Demo script, video fallback, README. Stretch: order book, price history.

### 5. Bounty Board (Idea 12)

**Why #5:** Universally understood concept (bounties!). Clean DeFi crossover (escrow + automatic payout). Killmail integration demonstrates chain data utilization. Strong demo: "post bounty → kill happens → money transfers automatically." Low implementation risk — straightforward Move contract + web frontend.

**5-step execution outline:**
1. **Days 1–3:** Build bounty contract: `post_bounty(target, Coin<SUI>)`, `claim_bounty(bounty_id, killmail_id)` (verify killmail matches target, transfer escrowed SUI). Test on local devnet.
2. **Days 4–7:** Build React bounty board: active bounties list, "Post Bounty" form, "Claim" button with killmail verification.
3. **Days 8–10:** Generate test killmails, demonstrate automated payout. Add leaderboard (top bounty hunters from event history).
4. **Days 11–14:** Polish UX, add bounty expiry (return funds after timeout), multiple active bounties.
5. **Days 15–20:** Demo script, video fallback. Stretch: anonymous bounties (ZK proof of poster authority).

---

## Appendix A: Contract Hooks Reference

Mapping ideas to specific module operations they depend on:

| Idea | Gate ops | SSU ops | NWN ops | Killmail | Access | Location/Proofs | ZK PoC | Custom Module |
|------|----------|---------|---------|----------|--------|-----------------|--------|---------------|
| 1. Gate Policy Engine | `authorize_extension`, `issue_jump_permit`, `jump_with_permit` | — | — | — | OwnerCap, sponsor ACL | — | — | PolicyConfig (dynamic fields) |
| 2. Command Center | `status` read | `status`, `inventory` read | `fuel`, `connected_assembly_ids` read | — | — | — | — | — (read-only) |
| 3. SSU Storefront | — | `authorize_extension`, `deposit_item`, `withdraw_item` | — | — | OwnerCap | — | — | Storefront + Listing |
| 4. Killmail Intel | — | — | — | `KillmailCreatedEvent` query | — | location hash correlation | — | — (read-only) |
| 5. ZK Gate Pass | `authorize_extension`, `issue_jump_permit`, `jump_with_permit` | — | — | — | — | — | `verify_location_attestation` | ZK-Gate wrapper |
| 6. Fuel Watch | — | — | `fuel`, `FuelEvent`, `online`, `offline` | — | OwnerCap | — | — | — (read + optional write) |
| 7. Alliance Network | `link_gates`, `authorize_extension`, `issue_jump_permit` | — | — | — | OwnerCap (multiple) | distance proof (mock) | — | AllianceConfig |
| 8. Corpse Toll Road | `authorize_extension`, `issue_jump_permit` | `withdraw_item`, `deposit_item` | — | — | OwnerCap, sponsor ACL | proximity proof (mock) | — | TollConfig |
| 9. Dead Drop | — | `deposit_item`, `withdraw_item` | — | — | — | — | `verify_location_attestation` | DeadDrop slots |
| 10. Structure Insurance | — | — | — | `KillmailCreatedEvent` match | — | — | — | InsurancePool + Policy |
| 11. Time-Locked Vault | — | `authorize_extension`, `deposit_item`, `withdraw_item` | — | — | OwnerCap | — | — | ScheduleConfig + Clock |
| 12. Bounty Board | — | — | — | Killmail match | — | — | — | Bounty + escrow |
| 13. Traffic Analytics | `JumpEvent` query | — | — | — | — | — | — | — (read-only) |
| 14. Tribal Diplomacy | `authorize_extension`, `issue_jump_permit` | — | — | — | TribeAdminCap (custom) | — | — | DiplomacyConfig |
| 15. Logistics Router | `linked_gate_id` topology | — | — | — | — | — | — | — (read-only, client-side) |
| 16. Gate Graffiti Wall | gate ID as key | — | — | — | optional OwnerCap moderation | — | optional ZK proximity | GraffitiBoard + Message |
| 17. Energy Arbitrage | — | `online`, `offline` | `fuel`, `online`, `offline`, `deposit_fuel` | — | OwnerCap, sponsor ACL | — | — (bot/script) |
| 18. PoP Badge | — | — | — | — | — | — | `verify_location_attestation` | Badge NFT |
| 19. Corp Treasury | gate/SSU/NWN OwnerCap ops | — | — | — | `borrow_owner_cap`, multi-sig | — | — | MultiSig + Proposal |
| 20. Gate Leaderboard | `JumpEvent`, `StatusChangedEvent` | — | — | — | — | — | — | — (read-only) |

---

## Appendix B: Key Function Signatures

```
// Gate extension flow
gate::authorize_extension<Auth>(gate, character, owner_cap, ctx)
gate::issue_jump_permit<Auth>(source_gate, dest_gate, character, Auth{}, expires_at_ms, ctx) → JumpPermit
gate::jump_with_permit(source_gate, dest_gate, admin_acl, character, permit, ctx)
gate::jump(source_gate, dest_gate, admin_acl, character, ctx)
gate::link_gates(gate_a, gate_b, gate_config, character_a, owner_cap_a, character_b, owner_cap_b, server_registry, distance_proof, clock, ctx)

// SSU extension flow
storage_unit::authorize_extension<Auth>(ssu, character, owner_cap, ctx)
storage_unit::deposit_item<Auth>(ssu, character, item, Auth{}, ctx)
storage_unit::withdraw_item<Auth>(ssu, character, item_id, Auth{}, ctx) → Item
storage_unit::game_item_to_chain_inventory(ssu, admin_acl, character, tenant, type_id, item_id, volume, quantity, location, ctx)

// Access control
access::create_admin_cap(governor_cap, ctx) → AdminCap
access::create_owner_cap<T>(admin_cap, object, ctx) → OwnerCap<T>
access::add_sponsor_to_acl(admin_acl, admin_cap, sponsor_address)
access::register_server_address(server_registry, admin_cap, server_address)
character::borrow_owner_cap<T>(character, owner_cap_receiving, ctx) → (OwnerCap<T>, ReturnOwnerCapReceipt)

// NWN fuel
network_node::deposit_fuel(nwn, admin_acl, character, owner_cap, fuel_amount, ctx)
network_node::online(nwn, character, owner_cap, clock, ctx)
network_node::offline(nwn, character, owner_cap) → OfflineAssemblies

// ZK PoC
location_attestation::verify_location_attestation(verification_data, vkey_bytes, proof_points_bytes, public_inputs_bytes) → LocationAttestationPublicData
distance_attestation::verify_distance_attestation(obj_id_1, obj_id_2, vkey_bytes, proof_points_bytes, public_inputs_bytes, registry)
```

---

## Appendix C: Web Inspiration Notes

Sources informing these ideas (brief citations for internal reference):

| Pattern | Source | Relevance |
|---------|--------|-----------|
| Composable access policies | Hats Protocol (ETH governance) | Hierarchical, role-based permissions for game structures |
| On-chain analytics dashboard | Dune Analytics (Ethereum) | Read-only chain data → useful UX for structure owners |
| ZK-gated access | Dark Forest (ETH game) | Privacy-preserving game mechanics via ZK proofs |
| Bounty boards | Gitcoin Bounties / EVE Online bounty system | Escrow + verification → auto-payout |
| Toll roads / pay-to-access | Axie Infinity scholarship model, bridge toll DApps | Monetization layer for infrastructure owners |
| Multi-sig governance | Gnosis Safe / Zodiac (ETH DAO tooling) | N-of-M approval for structure operations |
| Leaderboards | Various GameFi hackathon winners | Gamification of infrastructure management |
| POAP / proof-of-presence | POAP Protocol (ETH events), Zupass (ZK attendance) | Location-verified collectibles |
| Diplomacy protocols | Nouns DAO governance, Primodium alliance mechanics | On-chain treaty management |
| Dead drops / anonymous exchange | Tornado Cash mechanism (adapted for items), SecureDrop concept | Privacy-preserving item exchange |
| Fuel monitoring | Datadog / PagerDuty (infrastructure monitoring) | Alerting + prediction for game infra |
| Route optimization | Google Maps / OSRM routing engines | Graph traversal on gate network topology |
| Killboard analytics | zKillboard (EVE Online), The Graph Protocol | Event indexing → analytics platform |
| Storefront / marketplace | OpenSea, Tensor (Solana), SuiFrens marketplace | Item listing + escrow trading |
| Time-locked access | Yearn Finance vaults, token vesting contracts | Scheduled access windows for gameplay |

---

*Generated by LLM agent from `docs/sui-playground-capabilities.md` and parallel research sub-agents. No code was written; no commits were made. All ideas are grounded in verified world-contract capabilities.*
