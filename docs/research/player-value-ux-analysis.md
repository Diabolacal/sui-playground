# Player Value / UX Analysis — EVE Frontier Hackathon Ideation

**Retention:** Prep-only

> **Date:** 2026-02-15
> **Agent Role:** Player Value / UX
> **Grounded in:** world-contracts source (gate.move, storage_unit.move, network_node.move, access_control.move, killmail.move, character.move, inventory.move, fuel.move) + extension_examples (gate, tribe_permit, corpse_gate_bounty, config)

---

## PLAYER PAIN POINTS & OPPORTUNITIES

### 1. Gate Operator Pain Points

| Pain Point | Root Cause (from contracts) | Opportunity |
|---|---|---|
| **Binary access model** | `authorize_extension<Auth>()` sets exactly one extension type. Once set, ALL jumpers need a `JumpPermit`. There's no "whitelist these addresses but gate others." | Multi-rule policy engine: combine tribe + payment + time + reputation in a single extension. |
| **Permit expiry is hardcoded per-extension** | Example extensions use `5 * 24 * 60 * 60 * 1000` (5 days). No player-facing way to set/change expiry. Gate owners must redeploy code to change timing. | Configurable expiry UI backed by a `TimeConfig` dynamic field — just like `TribeConfig` but for duration. |
| **No revenue model** | Default `jump()` is free. Extension examples only check tribe membership or corpse bounty. No built-in SUI payment or token toll. | Payment-gated extension: require `Coin<SUI>` (or custom token) transfer before issuing `JumpPermit`. Toll goes to gate owner's address. |
| **Linking requires same-owner control** | `link_gates()` checks `is_authorized(source_gate_owner_cap, ...)` AND `is_authorized(destination_gate_owner_cap, ...)` — both must be the same character's caps. Cross-player linking is impossible without OwnerCap transfer. | Alliance gate linking proposal: `OwnerCap<Gate>` delegation pattern (the contract already supports `transfer_owner_cap`) but no UI or protocol for temporary/revocable delegation. A "gate alliance" shared object could hold multiple OwnerCaps or proxy authorization. |
| **No gate traffic visibility** | `JumpEvent` is emitted but there's no on-chain counter or analytics. Gate owners can't see usage without running their own indexer. | Gate traffic dashboard fed by event indexing (Sui event queries or a lightweight off-chain indexer). |
| **Extension swap is destructive** | `extension.swap_or_fill()` replaces the previous extension type. No versioning, no migration path. | Extension migration UI with dry-run validation — show what happens before swapping. |
| **No multi-gate policy management** | Each gate is configured individually. A network of 20 gates requires 20 `authorize_extension` calls, 20 config updates. | Gate group abstraction: a `GateNetwork` shared object that fans out policy changes to all member gates. |
| **No conditional/time-of-day access** | Extension pattern supports arbitrary logic, but no example implements time-based rules. The `Clock` is available in all permit functions. | Time-gated extension: `issue_jump_permit()` checks `clock.timestamp_ms()` against a `TimeWindow` config (e.g., "open 18:00–06:00 UTC only"). |

### 2. Storage / Logistics Pain Points

| Pain Point | Root Cause (from contracts) | Opportunity |
|---|---|---|
| **No cross-SSU inventory view** | Each `StorageUnit` stores inventory as dynamic fields keyed by `OwnerCap ID`. To see all your items you'd query every SSU you own individually. | Unified inventory dashboard: index all `ItemMintedEvent` / `ItemDepositedEvent` / `ItemWithdrawnEvent` across SSUs, present aggregated view by `type_id`. |
| **No corp storage access** | World-contracts `OwnerCap<StorageUnit>` is per-character. The access module comment says "Future: Capability registry to support multi party access/shared control. Capabilities based on different roles/permission in a corporation/tribe." This doesn't exist yet. | Corp storage extension: a `CorpAccess` witness type that checks `character.tribe()` + a role table (leader/officer/member) before calling `deposit_item<CorpAuth>()` or `withdraw_item<CorpAuth>()`. |
| **No automated restocking** | `deposit_item<Auth>()` and `withdraw_item<Auth>()` are manual, single-tx operations. No batch or scheduled operations. | Restocking bot / automation layer: off-chain service that monitors `fuel.quantity()`, `inventory.used_capacity`, and submits `deposit_item` / `game_item_to_chain_inventory` txs when thresholds are crossed. |
| **No audit trail for inventory operations** | Events exist (`ItemDepositedEvent`, `ItemWithdrawnEvent`) but include only `character_id`, `type_id`, `quantity` — no timestamp (requires block timestamp lookup). No query UI. | Inventory audit log: index events with block timestamps, present as "who deposited/withdrew what at when" feed per SSU. |
| **Capacity management is blind** | `max_capacity` and `used_capacity` are on the `Inventory` struct but not exposed via convenient view functions for external monitoring. | Capacity alerts: poll `max_capacity` vs `used_capacity` and warn when > 80%, > 95% full. |
| **Item types are opaque** | Items have `type_id` (u64) but no on-chain name/description mapping. The game server knows what type_id=42 means; the chain doesn't. | Item type registry: shared object mapping `type_id → name/icon/category`. Can be populated by admin at publish time. |
| **No item transfer between SSUs** | To move items between SSUs you must: withdraw from SSU_A (requires proximity proof) → hold item in tx → deposit to SSU_B (requires same-tx proximity to both). Practically impossible without being at both locations simultaneously. | Logistics contract: intermediate "cargo manifest" object that encapsulates items in transit. Withdraw from SSU_A with a `CargoManifestAuth`, travel, deposit to SSU_B with the same manifest. |

### 3. Fuel / Energy Management Pain Points

| Pain Point | Root Cause (from contracts) | Opportunity |
|---|---|---|
| **No fuel alerts** | `has_enough_fuel()` and `need_update()` are view functions available on-chain but there's no push notification or monitoring layer. Fuel runs out silently. | Fuel monitoring service: off-chain poller that reads `Fuel.quantity`, `burn_rate_in_ms`, calculates time-to-empty, fires alerts (webhook/email/Discord bot). |
| **Manual fuel deposits** | `deposit_fuel()` requires an `OwnerCap<NetworkNode>` + sponsored tx. No auto-refuel mechanism. | Auto-refuel extension: off-chain bot with delegated gas sponsorship that calls `deposit_fuel()` when quantity drops below threshold. |
| **Cascading offline risk** | Taking a NWN offline (`offline()`) returns a hot potato `OfflineAssemblies` that MUST be consumed by offlining every connected assembly in the same PTB. If NWN runs out of fuel and isn't manually updated, connected assemblies continue to think they're online but the NWN fuel is depleted. | Dependency map visualization: show which gates/SSUs are connected to which NWNs, fuel status of each NWN, and "time to cascade" metric. |
| **No multi-NWN overview** | A player might own 5 NWNs powering 30 assemblies. There's no aggregate view — each NWN must be queried individually. | Fleet fuel dashboard: all NWNs + connected assemblies in one view, sorted by urgency (lowest fuel first). |
| **Fuel efficiency is global** | `FuelConfig.fuel_efficiency` maps `fuel_type_id → efficiency` globally (admin-set). Players can't optimize — they just use whatever efficiency the admin set. | At minimum, surface fuel efficiency data to players so they can choose fuel types. More ambitiously, propose a fuel market where efficiency matters for pricing. |
| **Burn rate visibility** | `burn_rate_in_ms` is set at NWN creation and exposed via view function, but calculating "hours remaining" requires knowing `quantity * efficiency / burn_rate`. | Human-readable fuel gauge: "X hours Y minutes remaining at current burn rate" — computed client-side from on-chain data. |

### 4. Security & Access Control Pain Points

| Pain Point | Root Cause (from contracts) | Opportunity |
|---|---|---|
| **No multi-owner access** | `OwnerCap<T>` is a single-owner capability. One character, one cap, one structure. The code comments explicitly note: "Future: Capability registry to support multi party access/shared control." | Corp capability delegation: a `SharedOwnerCap<T>` wrapper that holds the real `OwnerCap<T>` and checks a role table before proxying calls. Or: a "key ring" shared object that multiple characters can borrow from. |
| **OwnerCap transfer is permanent** | `transfer_owner_cap()` moves the cap to a new address. No lending/borrowing for structures (only `borrow_owner_cap` exists for Character→OwnerCap, not for delegating to another player). | Temporary delegation: time-limited or revocable delegation using a wrapper object with expiry. The Character's `borrow_owner_cap` hot-potato pattern could be extended to support inter-player delegation with a `DelegationReceipt`. |
| **No revocation mechanism** | Once an `OwnerCap` is transferred, the previous holder has no way to reclaim it without the new holder cooperating. No on-chain revocation list. | Emergency revocation: admin-level function to re-create `OwnerCap` for an object and invalidate the old one (by changing `owner_cap_id` on the assembly). Risky but necessary for stolen keys. |
| **No audit log for access operations** | `OwnerCapCreatedEvent` and `OwnerCapTransferred` exist, but there's no "access denied" event, no "who attempted what" logging. | Access audit trail: emit events on authorization failures (would require world-contracts modification or wrapper). Off-chain, index all `OwnerCapTransferred` events for ownership change history. |
| **Gas sponsorship is coarse-grained** | `AdminACL.authorized_sponsors` is a simple address→bool table. Either you're a sponsor or you're not. No per-operation or per-structure granularity. | Scoped sponsorship: extend `AdminACL` with per-structure or per-operation-type sponsor authorization (requires world-contracts change). Or: off-chain sponsorship proxy that applies rules before relaying sponsored txs. |
| **Permissions don't compose** | You can gate a gate with a tribe check OR a bounty check, not both. Extension is a single `TypeName`. | Composable policy: an extension that itself dispatches to multiple sub-policies (all-of, any-of, ranked). The `ExtensionConfig` dynamic-field pattern already supports attaching multiple config structs — the dispatch logic just needs to be built. |

### 5. PvP & Intelligence Pain Points

| Pain Point | Root Cause (from contracts) | Opportunity |
|---|---|---|
| **Killmails are write-only** | `create_killmail()` creates shared objects and emits `KillmailCreatedEvent`, but there are no query/view functions for filtering or aggregation. Killmails accumulate as individual shared objects. | Killmail analytics dashboard: index `KillmailCreatedEvent` data (killer, victim, solar_system, loss_type, timestamp). Provide filters by: solar system, character, timeframe, loss type (SHIP vs STRUCTURE). |
| **No territorial intelligence** | `Killmail.solar_system_id` reveals where kills happen. But there's no aggregation layer to show "System X had 47 kills last week." | Heat map: aggregate killmails by `solar_system_id` over time windows. Identify "hot zones" (dangerous) vs "cold zones" (safe). |
| **No threat assessment** | Individual killmails tell you "A killed B in system C." No player profiles, no K/D ratios, no serial killer detection. | Player threat profiles: aggregate killmails by `killer_character_id` → kill count, preferred solar systems, ship vs structure ratio. Flag high-threat characters. |
| **Structure loss is mixed into killmails** | `LossType::STRUCTURE` exists but there's no structured link between a killmail and the destroyed Gate/SSU/NWN object. | Structure loss tracker: correlate `LossType::STRUCTURE` killmails with assembly `unanchor` events (if the assembly was destroyed in combat vs voluntarily removed). |
| **Gate traffic is intelligence-blind** | `JumpEvent` shows who jumped where, but there's no correlation to killmail data or threat assessment. | Gate traffic + threat correlation: "A known hostile character jumped through your gate 5 minutes ago — alert." |
| **No gate network topology analysis** | `linked_gate_id` creates a graph, but there's no tool to visualize or query the network topology. | Gate network map: traverse `linked_gate_id` across all gates, render a graph. Show traffic flow, chokepoints, disconnected segments. |

### 6. Economy & Trade Pain Points

| Pain Point | Root Cause (from contracts) | Opportunity |
|---|---|---|
| **No marketplace** | There is no on-chain order book, escrow, or listing mechanism. Items exist inside SSU inventories and can flow game↔chain, but there's no price discovery or matching. | SSU-based marketplace extension: a `MarketAuth` extension on an SSU that allows players to list items (type_id + quantity + price) and other players to fill orders (send SUI, receive item via `withdraw_item<MarketAuth>()`). |
| **No price oracle** | Items have no on-chain price. `type_id` + `quantity` + `volume` exist but no value field. | Community price oracle: a shared object where trusted reporters (or automated crawlers) submit price observations. Or: derive implied prices from marketplace transaction events. |
| **No escrow mechanism** | Trading requires trust — one party deposits, the other must reciprocate. No atomic swap. | Escrow extension: a shared `TradeEscrow` object. Both parties deposit items/SUI. When both sides are filled, atomic swap executes. If timeout, refund. |
| **Items aren't independently tradeable** | `Item` has `key + store` but lives inside an `Inventory` (SSU dynamic field). You can't send an `Item` to another player's wallet directly — it must flow through SSU extension deposit/withdraw. | Item wrapper: an object that wraps an `Item` for direct p2p transfer (withdraw from SSU → wrap → transfer → unwrap → deposit to destination SSU). This is effectively a "cargo container." |
| **Volume constraints** | `Item.volume` contributes to `Inventory.used_capacity`. Moving high-volume items requires sufficient capacity at destination. | Volume calculator: "Will this trade fit in my SSU?" check before initiating transfer. Show remaining capacity per SSU. |
| **No trade history** | `ItemDepositedEvent` / `ItemWithdrawnEvent` exist but aren't labeled as "trades." No concept of counterparty or price in events. | Trade ledger extension: emit custom `TradeExecutedEvent` with buyer, seller, item type, quantity, price, timestamp. Index for trade history / analytics. |

---

## INTERACTION PATTERN PROPOSALS

### Pattern 1: Command Center Dashboard

| Aspect | Detail |
|---|---|
| **Pattern Name** | Command Center |
| **Player Value** | Single-pane-of-glass for all owned structures. Eliminates the need to query each structure individually. Every corp leader's first question: "Is everything online?" |
| **Key Screens / UX Elements** | • **Structure roster**: table of all Gates, SSUs, NWNs owned by a character, showing status (ONLINE / OFFLINE), linked NWN, fuel remaining (for NWNs). • **Dependency tree**: NWN → connected assemblies tree view. • **Alert badges**: red for offline, amber for low fuel (< 24h), green for healthy. • **Quick actions**: online/offline toggle per structure (submits tx). |
| **Structures Touched** | `NetworkNode` (fuel, status, connected_assemblies), `Gate` (status, linked_gate_id, energy_source_id), `StorageUnit` (status, energy_source_id, used_capacity) |
| **Data Sources** | `sui client objects` filtered by OwnerCap ownership; view functions: `is_network_node_online()`, `fuel_quantity()`, `connected_assemblies()`. Events: `StatusChangedEvent`. |
| **Feasibility** | High — purely read-only + simple tx submission. Can be built as a web app calling Sui RPC. |

---

### Pattern 2: Fuel Sentinel (Auto-Refuel Alerts)

| Aspect | Detail |
|---|---|
| **Pattern Name** | Fuel Sentinel |
| **Player Value** | "Never let your NWN go dark." Corp infrastructure going offline because someone forgot to refuel is the #1 avoidable disaster. This pattern saves empires. |
| **Key Screens / UX Elements** | • **Fuel gauge per NWN**: current quantity, burn rate, estimated time-to-empty (computed from `quantity`, `burn_rate_in_ms`, `fuel_efficiency`). • **Alert thresholds**: configurable (e.g., "warn at 48h, critical at 12h"). • **Alert channels**: in-app notification, webhook (Discord/Slack), email. • **Auto-refuel toggle** (future): if a fuel source (SSU with fuel items) is nearby, automatically submit `deposit_fuel()` tx. |
| **Structures Touched** | `NetworkNode` (fuel state: quantity, burn_rate_in_ms, is_burning, last_updated) |
| **Data Sources** | View functions: `fuel_quantity()`, `has_enough_fuel()`, `need_update()`. Clock for time calculation. `FuelEvent` for state changes. |
| **Feasibility** | High for alerts (off-chain polling). Medium for auto-refuel (needs delegated OwnerCap + gas sponsorship). |

---

### Pattern 3: Corp Access Manager (Multi-Role Permissions)

| Aspect | Detail |
|---|---|
| **Pattern Name** | Corp Access Manager |
| **Player Value** | "My corp has 50 members. I want officers to manage SSU inventory and members to only deposit." Currently impossible without manual OwnerCap sharing (permanent, irreversible). This is the most-requested feature for organized play. |
| **Key Screens / UX Elements** | • **Role definition**: create roles (Leader, Officer, Member, Recruit) with permission sets (can_deposit, can_withdraw, can_online, can_offline, can_manage_extension). • **Member roster**: characters → roles mapping. • **Structure assignment**: which roles can access which structures. • **Permission check**: before any gated operation, the extension checks `character.tribe()` + role table. • **Audit log**: all role changes and access attempts logged. |
| **Structures Touched** | `StorageUnit` (via extension: `deposit_item<CorpAuth>`, `withdraw_item<CorpAuth>`), `Gate` (via extension: `issue_jump_permit<CorpAuth>`). Backing store: a `CorpConfig` shared object with dynamic fields for roles/members. |
| **Extension Pattern** | New Move module: `CorpAuth` witness type. `ExtensionConfig`-style shared object with `RoleTable` (character_id → role) and `PermissionTable` (role → permissions). Check on every `deposit_item<CorpAuth>()` / `withdraw_item<CorpAuth>()` call. |
| **Feasibility** | Medium — requires a new extension contract + frontend. The extension pattern is well-suited for this; `ExtensionConfig` dynamic fields handle arbitrary config. |

---

### Pattern 4: SSU Marketplace (Storefront Extension)

| Aspect | Detail |
|---|---|
| **Pattern Name** | SSU Marketplace |
| **Player Value** | "Turn any SSU into a vending machine." The game has no built-in marketplace. SSU-based storefronts are the natural primitive — the inventory is already there, just add pricing. This creates an entire player-driven economy layer. |
| **Key Screens / UX Elements** | • **Storefront setup** (seller): select SSU, list items by type_id with ask price (in SUI). • **Browse & buy** (buyer): discover nearby SSUs with active listings, view price/quantity, one-click purchase. • **Order board** (buyer): place buy orders ("I want 100 units of type_id 42 at 0.5 SUI each") — filled when seller deposits matching items. • **Transaction history**: all trades with counterparty, price, timestamp. |
| **Structures Touched** | `StorageUnit` (inventory: deposit/withdraw), custom `Marketplace` shared object (listings, escrow). |
| **Extension Pattern** | New module: `MarketAuth` witness. `MarketplaceConfig` shared object with: `ListingTable` (item_type → price × quantity), `EscrowBalance` (SUI held pending). Buy flow: buyer sends SUI → extension verifies listing → calls `withdraw_item<MarketAuth>()` → transfers item to buyer's SSU or wraps as transferable object. Sell flow: owner calls `deposit_item()` with listing metadata. |
| **Feasibility** | Medium-High — the `deposit_item<Auth>` / `withdraw_item<Auth>` pattern is designed for exactly this. Main complexity: escrow handling and `Coin<SUI>` management within the extension. |

---

### Pattern 5: Killmail Intelligence Center

| Aspect | Detail |
|---|---|
| **Pattern Name** | Killmail Intelligence Center |
| **Player Value** | "Know the battlefield." Killmails are EVE Frontier's richest intelligence source — they tell you who's dangerous, where fights happen, and what's being destroyed. Currently they're write-only shared objects with no query layer. |
| **Key Screens / UX Elements** | • **Kill feed**: real-time stream of `KillmailCreatedEvent`, filterable by solar system, character, loss type. • **Solar system heat map**: aggregate kills per system over configurable time window (24h, 7d, 30d). Color-code by intensity. • **Player profiles**: per-character kill/death count, preferred systems, ship vs structure ratio. • **Threat advisory**: "Character X has killed 12 players in your gate's solar system this week." • **Loss analysis**: "Your corp lost 3 structures last month — all in System Y." |
| **Structures Touched** | `Killmail` (shared objects), `Character` (identity correlation) |
| **Data Sources** | `KillmailCreatedEvent`: `killmail_id`, `killer_character_id`, `victim_character_id`, `solar_system_id`, `loss_type`, `kill_timestamp`. Index these events off-chain or query via `sui client events`. |
| **Feasibility** | High — purely indexing + visualization. No contract changes needed. |

---

### Pattern 6: Gate Policy Engine (Composable Rules)

| Aspect | Detail |
|---|---|
| **Pattern Name** | Gate Policy Engine |
| **Player Value** | "My gate should be: free for my tribe, 1 SUI for allied tribes, and closed to everyone else — but only between 20:00-06:00 UTC." Currently you get one extension type with one hard-coded rule. The policy engine lets gate owners stack rules without writing Move code. |
| **Key Screens / UX Elements** | • **Policy builder** (visual): drag-and-drop rule blocks — Tribe Check, Payment Gate, Time Window, Reputation Threshold, Killmail Check ("no one with > 5 kills this week"), Cooldown. • **Priority ordering**: rules evaluated in sequence; first match (allow/deny) wins. • **Test mode**: "What happens if Character X tries to jump at 3am?" — dry-run simulation. • **Policy deployment**: compiles rules into `PolicyConfig` dynamic fields on a `PolicyAuth` extension. |
| **Structures Touched** | `Gate` (extension registration), `Character` (tribe check), `Clock` (time check), custom `PolicyConfig` shared object |
| **Extension Pattern** | Single `PolicyAuth` witness type. `PolicyConfig` stores an ordered vector of rule descriptors (enum: `TribeRule(tribe_id)`, `PaymentRule(amount)`, `TimeWindowRule(start_ms, end_ms)`, `ReputationRule(min_score)`, `CooldownRule(seconds_between_jumps)`). The `issue_jump_permit()` function iterates rules and evaluates each against the requesting character + clock + payment. |
| **Feasibility** | Medium — the core pattern works, but a fully visual policy builder requires significant frontend effort. Start with pre-built rule templates. |

---

### Pattern 7: Trust & Reputation Ledger

| Aspect | Detail |
|---|---|
| **Pattern Name** | Trust & Reputation Ledger |
| **Player Value** | "Should I let this player through my gate? Should I trade with them?" Without reputation, every interaction is zero-trust. A community-sourced reputation system enables richer social play — trusted traders, known pirates, reliable allies. |
| **Key Screens / UX Elements** | • **Reputation score** per character: derived from on-chain behavior (killmail K/D ratio, trade volume via marketplace events, gate jump history, structure ownership tenure). • **Endorsements**: characters can stake SUI to vouch for another character ("I trust Player X"). Slashable if vouched player behaves badly. • **Reputation gates**: gate extensions that check `reputation_score >= threshold` before issuing permits. • **Leaderboards**: top traders, most trusted, most dangerous. |
| **Structures Touched** | `Character` (identity), `Killmail` (PvP behavior), custom `ReputationRegistry` shared object, `Gate` (reputation-gated extension) |
| **Data Sources** | Killmail events (PvP behavior), marketplace events (trade behavior), gate jump events (mobility patterns), endorsement transactions (social vouching). |
| **Feasibility** | Medium — the on-chain reputation registry is straightforward. The challenge is defining fair scoring algorithms and preventing gaming. Start with endorsement-only (human judgment) before adding algorithmic scoring. |

---

### Pattern 8: Logistics Planner (Gate Route Optimizer)

| Aspect | Detail |
|---|---|
| **Pattern Name** | Logistics Planner |
| **Player Value** | "What's the fastest route from System A to System B through my alliance's gate network?" Gate networks form a graph — linked gates create edges. Route planning through this graph is the core logistics problem for corps and traders. |
| **Key Screens / UX Elements** | • **Gate network graph**: nodes = gates (with solar system labels), edges = active links. Color by owner/tribe. • **Route finder**: select start gate + destination gate, find shortest path(s). Show intermediate jumps. • **Access check**: for each gate on the route, verify the traveler has/can-get a JumpPermit (tribe check, payment requirement, etc.). Flag "blocked" segments in red. • **Cargo manifest**: "I'm moving 500 units of type X. Which route has SSUs with enough capacity as waypoints?" |
| **Structures Touched** | `Gate` (linked_gate_id, extension, status), `StorageUnit` (capacity along route), `Character` (tribe for access checks) |
| **Data Sources** | All shared `Gate` objects: traverse `linked_gate_id` to build graph. Cross-reference extension types to determine access requirements per gate. |
| **Feasibility** | Medium — graph construction from on-chain data is feasible (query all Gate objects, build adjacency list from `linked_gate_id`). Route optimization is off-chain computation. Access requirement detection requires knowing each gate's extension semantics. |

---

### Pattern 9: Inventory Reconciler (Cross-SSU Audit)

| Aspect | Detail |
|---|---|
| **Pattern Name** | Inventory Reconciler |
| **Player Value** | "Where the hell are my 2000 units of fuel?" With items spread across multiple SSUs, players lose track of what's where. Corps need inventory accounting across all their structures. This is EVE Frontier's version of a warehouse management system. |
| **Key Screens / UX Elements** | • **Global inventory view**: aggregate all items across all owned SSUs, grouped by `type_id`. Show total quantity, distribution across SSUs. • **Per-SSU breakdown**: what's in each SSU, capacity usage percentage. • **Discrepancy alerts**: "SSU_Alpha had 500 fuel yesterday, now has 200 — 300 units withdrawn by Character_X at timestamp T." • **Search**: "Find all SSUs containing type_id 42" — returns list with quantities and SSU locations. |
| **Structures Touched** | `StorageUnit` (inventory dynamic fields), `Item` (type_id, quantity, volume) |
| **Data Sources** | Direct object reads of SSU inventories (dynamic field access). Event indexing: `ItemMintedEvent`, `ItemDepositedEvent`, `ItemWithdrawnEvent`, `ItemBurnedEvent` for change tracking. |
| **Feasibility** | High — read-only aggregation. The main challenge is that inventories are dynamic fields keyed by OwnerCap ID — you need to know the OwnerCap IDs to query them. An indexer tracking `StorageUnitCreatedEvent` → `OwnerCapCreatedEvent` solves this. |

---

### Pattern 10: Alliance Gate Network Manager

| Aspect | Detail |
|---|---|
| **Pattern Name** | Alliance Gate Network |
| **Player Value** | "Our alliance of 5 corps wants a unified gate network. Each corp owns gates, but alliance members should jump freely across any of them." Currently impossible because extensions are per-gate and linking requires same-owner caps. This pattern makes large-scale cooperation viable. |
| **Key Screens / UX Elements** | • **Alliance registry**: shared object storing alliance membership (list of tribe_ids or character_ids). • **Join/leave**: characters can be added/removed by alliance leaders. • **Unified gate policy**: all alliance gates use a shared `AllianceAuth` extension that checks the alliance registry before issuing permits. • **Network health dashboard**: all alliance gates, their online status, fuel status of backing NWNs, traffic volume. • **Revenue sharing**: toll gates split revenue among alliance members proportionally. |
| **Structures Touched** | `Gate` (extension: `AllianceAuth`), `Character` (tribe check), custom `AllianceRegistry` shared object, `NetworkNode` (fuel monitoring for alliance NWNs) |
| **Extension Pattern** | `AllianceAuth` witness type. `AllianceRegistry` shared object with: `members: Table<ID, bool>` (character IDs), `tribes: Table<u32, bool>` (tribe IDs), `leaders: Table<ID, bool>` (who can manage). `issue_jump_permit()` checks `character.id()` in members OR `character.tribe()` in tribes. |
| **Feasibility** | Medium — the extension pattern supports this cleanly. The challenge is gate linking across owners (contract limitation). Workaround: each corp links their own gates, and the alliance is about shared access policies rather than physical linking. |

---

### Pattern 11: Structure Vulnerability Monitor

| Aspect | Detail |
|---|---|
| **Pattern Name** | Structure Vulnerability Monitor |
| **Player Value** | "Which of my structures are at risk?" Combines NWN fuel status (offline = vulnerable), killmail data (hostile activity nearby), and gate access configuration (is your gate open to enemies?) into a risk score per structure. |
| **Key Screens / UX Elements** | • **Risk heat map**: all owned structures plotted by solar system, color-coded by risk level (green/amber/red). • **Risk factors**: per-structure breakdown — fuel remaining (NWN connectivity), recent hostiles in system (killmail data), access policy strength (is the gate open?), structure loss history (killmails with `LossType::STRUCTURE` in this system). • **Alerts**: "3 ship kills in System X in the last hour — your SSU there has no extension protection." • **Mitigation recommendations**: "Enable tribe-gating on Gate_Y" / "Refuel NWN_Z within 6 hours." |
| **Structures Touched** | `NetworkNode` (fuel), `Gate` (extension state, status), `StorageUnit` (extension state, status), `Killmail` (threat data), `Character` (ownership) |
| **Data Sources** | Crosscut of: NWN fuel view functions, assembly status, killmail events by solar_system_id, gate extension configuration. |
| **Feasibility** | Medium — combines multiple data sources. Individual queries are straightforward; the risk scoring algorithm is the novel part. |

---

### Pattern 12: Escrow Trade Protocol

| Aspect | Detail |
|---|---|
| **Pattern Name** | Escrow Trade Protocol |
| **Player Value** | "I want to trade 100 ore for 50 SUI, but I don't trust the buyer to pay after I deposit." Trustless trading is the foundation of any economy. Without escrow, every trade requires personal trust or a middleman. |
| **Key Screens / UX Elements** | • **Create trade**: specify offered items (type_id, quantity) and wanted payment (SUI amount or other items). Published as a `TradeOffer` shared object. • **Accept trade**: counterparty reviews offer, deposits their side into escrow. • **Execute**: when both sides are funded, atomic swap executes — items move to buyer's SSU, SUI moves to seller's address. • **Cancel/expire**: either party can cancel before both sides are filled. Timeout auto-refunds. • **Trade history**: all completed/cancelled/expired trades with details. |
| **Structures Touched** | `StorageUnit` (source/destination for items), custom `TradeEscrow` shared object (holds items + SUI), `Character` (identity for counterparties) |
| **Extension Pattern** | `EscrowAuth` witness on SSUs. `TradeEscrow` shared object: `seller_items: VecMap<u64, Item>`, `buyer_payment: Balance<SUI>`, `status: enum(Open, Funded, Completed, Cancelled)`, `expires_at: u64`. On creation: seller calls `withdraw_item<EscrowAuth>()` → items stored in escrow. On accept: buyer sends `Coin<SUI>`. On execute: items transferred to buyer's SSU via `deposit_item<EscrowAuth>()`, SUI sent to seller. |
| **Feasibility** | Medium — requires careful handling of `Item` lifecycle (items must be unwrapped from SSU inventory, held in escrow object, then deposited into buyer's inventory). The `Item` struct has `key + store` abilities, so it can be held in a shared object. |

---

### Pattern 13: Gate Traffic Analytics

| Aspect | Detail |
|---|---|
| **Pattern Name** | Gate Traffic Analytics |
| **Player Value** | "My gate network does 200 jumps/day. Which gates are underused? Where should I build new ones?" Gate operators are infrastructure providers — they need business intelligence to optimize their network. |
| **Key Screens / UX Elements** | • **Traffic counters**: jumps per gate per time period (hour/day/week). • **Traffic flow**: source→destination heatmap showing which routes are busiest. • **Unique travelers**: distinct characters per gate per period. • **Peak hours**: when is traffic highest? (for time-gated pricing). • **Revenue per gate**: if using payment extensions, SUI earned per gate per period. • **Trend lines**: traffic growth/decline over time. |
| **Structures Touched** | `Gate` (via `JumpEvent`) |
| **Data Sources** | `JumpEvent`: `source_gate_id`, `destination_gate_id`, `character_id`. Index events with block timestamps. All computation is off-chain aggregation. |
| **Feasibility** | High — purely event indexing + visualization. Zero contract changes. |

---

### Pattern 14: Dead Man's Switch (Emergency Offline)

| Aspect | Detail |
|---|---|
| **Pattern Name** | Dead Man's Switch |
| **Player Value** | "If I don't check in within 48 hours, shut everything down." Players go AFK. Corps have key-man risk — if the leader disappears, structures with depleted fuel go offline uncontrolled. This pattern provides a programmable failsafe. |
| **Key Screens / UX Elements** | • **Heartbeat config**: "I will check in every X hours. If I miss a check-in, execute emergency plan." • **Emergency plan**: ordered list of actions — offline assemblies, unlink gates, withdraw remaining fuel. • **Delegation**: "If dead man's switch triggers, transfer OwnerCaps to Character_Y." • **Status**: last heartbeat timestamp, time until trigger. |
| **Structures Touched** | `NetworkNode` (offline + fuel withdraw), `Gate` (unlink + offline), `StorageUnit` (offline), `OwnerCap` (delegation transfer) |
| **Implementation** | Off-chain bot with custody of a delegated key (not the player's main key). Monitors heartbeat signals (on-chain event or off-chain ping). If timeout exceeded, submits emergency PTB: `nwn::offline()` + `gate::unlink_gates()` + `gate::offline()` etc. Requires the player to pre-authorize the bot's address via OwnerCap transfer or a delegation mechanism. |
| **Feasibility** | Low-Medium — the main blocker is secure key delegation. The hot-potato pattern in `network_node::offline()` means all connected assemblies must be offlined in the same PTB, which requires knowing the full dependency graph. |

---

## SUMMARY: PRIORITIZED OPPORTUNITIES

### Quick Wins (High feasibility, high player value — hackathon-ready)

| # | Pattern | Why |
|---|---------|-----|
| 1 | **Command Center Dashboard** | Read-only, massive QoL improvement, demonstrates data aggregation |
| 2 | **Killmail Intelligence Center** | Pure indexing, high engagement value, unique to EVE Frontier |
| 3 | **Gate Traffic Analytics** | Pure indexing, directly monetizable insight for gate operators |
| 4 | **Fuel Sentinel** | Simple polling + alerts, prevents the most common infrastructure failure |
| 5 | **Inventory Reconciler** | Read-only aggregation, essential for any corp with > 3 SSUs |

### Medium-Term (Require new extension contracts)

| # | Pattern | Why |
|---|---------|-----|
| 6 | **SSU Marketplace** | Creates the economy layer EVE Frontier is missing |
| 7 | **Corp Access Manager** | Unlocks organized play — the most-requested access control feature |
| 8 | **Gate Policy Engine** | Makes gate monetization viable without custom code per rule |
| 9 | **Escrow Trade Protocol** | Trustless trading is table-stakes for a blockchain economy |
| 10 | **Alliance Gate Network** | Enables large-scale cooperation — EVE's core social dynamic |

### Ambitious (Significant engineering + design)

| # | Pattern | Why |
|---|---------|-----|
| 11 | **Trust & Reputation Ledger** | Profound social impact but hard to design fairly |
| 12 | **Structure Vulnerability Monitor** | High value but requires multi-source data fusion |
| 13 | **Logistics Planner** | Complex graph algorithms + access checking |
| 14 | **Dead Man's Switch** | Key delegation is an unsolved problem in the current access model |

---

## HACKATHON RECOMMENDATION

**Build Pattern 6 (Gate Policy Engine) + Pattern 1 (Command Center) as a combined project.**

Rationale:
- The policy engine is the highest-leverage new contract — it makes gate extension authoring accessible to non-developers (the "vibe coding" of gate rules).
- The command center dashboards the policy engine's effects and provides immediate visual payoff.
- Together they demonstrate both "write" (deploy policies) and "read" (monitor effects) on-chain interaction.
- The `ExtensionConfig` + dynamic-field pattern from the existing examples is the exact foundation needed.
- Killmail intelligence (Pattern 5) can be added as a dashboard tab with minimal extra effort (pure indexing).

**Addressable market in EVE Frontier:** every gate owner (infrastructure providers), every corp leader (operations management), every trader (route planning).
