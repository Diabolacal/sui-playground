# Wildcard Sprint — High-Variance Innovation Exploration

**Retention:** Prep-only

---

## PHASE 1 — Capability Extraction Summaries

### A) World-Contracts Capability Surface

**Extension Hooks (programmable surfaces):**

| Assembly | Hook | Auth Required | Key Property |
|----------|------|---------------|-------------|
| Gate | `authorize_extension<Auth>` | OwnerCap only | swap_or_fill — silently replaces existing |
| Gate | `issue_jump_permit<Auth>` | Extension witness only — NO AdminACL | Player-callable, both gates must share extension type |
| Gate | `jump_with_permit` | AdminACL (sponsored) | Consumes permit, emits JumpEvent |
| SSU | `authorize_extension<Auth>` | OwnerCap only | Same swap_or_fill pattern |
| SSU | `deposit_item<Auth>` | Extension witness only — NO AdminACL | Extension-controlled deposits |
| SSU | `withdraw_item<Auth>` | Extension witness only — NO AdminACL | Extension-controlled withdrawals |

**Shared Objects (extension-readable state):**
- `AdminACL` — sponsor whitelist
- `Character` — tribe_id, character_address (faction identity)
- `Gate` — linked_gate_id, extension, status, location
- `StorageUnit` — extension, inventory_keys, status, location
- `Killmail` — killer/victim IDs, loss_type, solar_system_id, timestamp
- `GateConfig` / `EnergyConfig` / `FuelConfig` — global parameters
- `ObjectRegistry` — deterministic object ID derivation

**Events (indexable signals):**
- 27+ distinct event types across gate, SSU, inventory, energy, fuel, killmail, character
- ~~**Critical gap:** NO event emitted for `authorize_extension` changes~~ *(Correction 2026-03-04: v0.0.15 added `ExtensionAuthorizedEvent` on Gate, SSU, and Turret. No longer a gap.)*
- Rich signals: JumpEvent, ItemDepositedEvent, ItemWithdrawnEvent, KillmailCreatedEvent, FuelEvent

**Unusual Surfaces Most Builders Will Miss:**

1. **JumpPermit is tradable** (`key + store`, no `drop`) — can be wrapped, placed in DFs, transferred between players. NOT just single-use-and-forget.
2. **Killmail is a shared object** — extensions can take `&Killmail` as a parameter and read kill data for access decisions.
3. **SSU extension is a blank canvas** — scaffold has NO SSU extension impl. First-mover advantage.
4. **Cross-assembly composition is proven** — `corpse_gate_bounty` touches Gate + SSU + Character in one function call.
5. **OwnerCap delegation** — `transfer_owner_cap_with_receipt` enables hot-potato-enforced lending of structure ownership.
6. **Coin<EVE>** — standard Sui Coin, composable with any DeFi primitive. Native toll currency.
7. **Item has `store`** — can be wrapped, moved between objects, used as payment tokens.
8. **Metadata is owner-writable** — name/url/description can encode structured signals without protocol changes.

---

### B) Builder-Scaffold Pattern Analysis

**Demonstrated patterns:**
- ExtensionConfig (shared singleton) + AdminCap (owned) + XAuth (drop-only, `public(package)` mint)
- DF storage with typed key/value pairs (TribeConfigKey → TribeConfig)
- Hot-potato OwnerCap borrow/return cycle
- Cross-assembly Gate + SSU composition (corpse_gate_bounty)
- Sponsored transaction dual-sign flow
- Object ID derivation from BCS
- zkLogin integration

**Critical gaps = opportunity:**
- `storage_unit/` Move module is a **pure stub** (`public fun template() {}`)
- `tokens/` Move module is a **pure stub** 
- No SSU extension example exists
- No DF reads from client-side demonstrated
- No event subscription patterns
- AdminCap delegation, time-locks, rotation — all unexplored
- dApp UI is read-only (no transaction signing from React)

**Pushable patterns:**
- Single-condition permits → multi-conditional permits (tribe AND reputation AND cooldown)
- Static expiry → dynamic pricing/expiry based on on-chain state
- Single-assembly extensions → multi-assembly workflow chains
- ExtensionConfig as static config → ExtensionConfig as mutable protocol state

---

### C) Sui Technical Impressiveness Multipliers

| Primitive | Why It Impresses | World-Contracts Application |
|-----------|-----------------|---------------------------|
| **PTB multi-step atomic** | No other chain can do 5+ cross-object operations atomically | Toll → Permit → Jump → Deposit in ONE transaction |
| **Hot-potato enforcement** | Protocol-level guarantee of operation completion | OwnerCap borrow/return, receipt consumption |
| **Dynamic fields** | Upgradeable state without contract upgrade | ExtensionConfig with arbitrary typed rules |
| **Object capabilities** | Fine-grained access control via object ownership | OwnerCap, AdminCap, extension witness |
| **Shared objects** | Concurrent access to global state | Character, Gate, SSU, Killmail — all extension-readable |
| **Transfer-to-object (Receiving)** | Objects as children of objects | OwnerCap lives under Character |
| **Deterministic object IDs** | Pre-compute addresses from BCS | ObjectRegistry → off-chain coordination |
| **Coin splitting in PTB** | Payment composition without intermediaries | Coin<EVE> toll payments |
| **Events** | Rich indexable event stream | 27+ event types for off-chain reactivity |

**Judge-impact ranking:**
1. PTB atomic composition (unique to Sui, visually demonstrable)
2. Hot-potato protocol enforcement (elegant, chain-native)
3. Cross-object reads in single tx (Killmail + Gate in one PTB)
4. Dynamic fields as composable state layer

---

### D) Hackathon Judging Optimization Strategy

**Prize structure (max 1 prize per entry):**

| Prize | Value | Optimal Target Profile |
|-------|-------|----------------------|
| 1st Place | $25K + Fanfest | Strongest all-around: system design + demo + utility |
| 2nd Place | $12.5K | Strong concept, good demo, less polish |
| 3rd Place | $7.5K | Solid implementation, narrower scope |
| Most Utility | $6K | Changes player behavior. Measurable. |
| Best Technical | $6K | Clean architecture, smart system use. |
| Most Creative | $6K | Novel concept, clever reinterpretation. |
| Weirdest Idea | $6K | Meme-worthy. Surprising. Visual. |
| Best Live Integration | $6K | Deployed in Stillness. Working with real players. |

**What judges will see a lot of:**
- Gate access control (tribe-based, toll-based) — THE obvious extension
- SSU marketplace / trade interfaces — THE other obvious extension
- Dashboard/analytics overlays — low-effort, low-impact
- "Better UI for existing functions" — not differentiated
- Minor permission tweaks — boring

**What would differentiate:**
- Protocol-level innovation (new economic primitives)
- Cross-assembly composition (Gate + SSU + Items in one flow)
- Novel use of underexplored surfaces (Killmail, JumpPermit tradability, OwnerCap delegation)
- Sui-native patterns that couldn't exist on EVM (PTB composition, hot-potato)
- Emergent behavior (system creates dynamics the designer didn't explicitly code)

**Optimal strategy (for a wildcard project):**
- **Primary target:** Most Creative or Best Technical (less competition than 1st place)
- **Secondary:** Weirdest Idea (high EV if concept is strong enough)
- **Stretch:** 2nd/3rd Place if execution is clean
- **Demo strategy:** 2-3 minute recorded video showing on-chain transactions with narrative voiceover

---

## PHASE 2 — Six Wild but Grounded Concepts

---

### Concept 1: "PERMIT EXCHANGE" — On-Chain Route Futures Market

**Core Mechanic:** JumpPermit has `key + store` — it's a transferable, wrappable, non-copyable asset. Build a protocol where permits are issued by gate extensions, then listed/traded on a shared orderbook object. Route pricing becomes market-driven. Players speculate on route access.

**World-Contract Hooks:**
- `issue_jump_permit<Auth>` → mint permits (player-callable)
- JumpPermit `store` ability → place in DF-backed orderbook
- `jump_with_permit` → consume after purchase (sponsored)
- Coin<EVE> → payment for listed permits

**Sui Primitives Leveraged:**
- PTB: Issue permit + list on orderbook in one atomic tx
- PTB: Buy permit + jump in one atomic tx
- Dynamic fields: orderbook entries as typed DFs on shared object
- Hot-potato: could enforce buy-and-jump atomicity

**Why Technically Impressive:**
Nobody on any blockchain has built a futures market for travel permissions. JumpPermit's non-copyable, non-droppable nature makes it a perfect scarce tradable asset. The PTB composition (buy + jump atomic) is a "why Sui" moment.

**Why Unexpected:**
Every other team will build "gate access control." This treats gate access as a *financial instrument*. It's DeFi meets infrastructure.

**Demo Proof Moment:**
- Permit listed at price X on the orderbook
- Player B buys permit + jumps in ONE transaction
- Price discovery visible: popular routes cost more
- On-chain: permit transfer + consumption + JumpEvent in single PTB

**Complexity:** Medium-High — need orderbook contract + gate extension + UI
**Win Potential:** 8/10 — novel, technically impressive, but orderbook UX is complex

---

### Concept 2: "KILL TROPHY GATE" — Killmail-Gated Access

**Core Mechanic:** A gate extension that reads `&Killmail` shared objects as admission criteria. To pass through a gate, you must prove you killed a specific target (or any target in a specific system). "Only the worthy may pass."

**World-Contract Hooks:**
- `&Killmail` as function parameter (shared, readable by any contract)
- Killmail fields: killer_character_id, victim_character_id, solar_system_id, loss_type
- `issue_jump_permit<Auth>` → mint permit after killmail validation
- ExtensionConfig DF → store bounty targets / kill requirements

**Sui Primitives Leveraged:**
- Cross-object reads: Gate + Killmail in single PTB
- Dynamic fields: bounty target configuration
- Shared objects: Killmail as persistent queryable proof-of-kill

**Why Technically Impressive:**
Cross-object reads between unrelated shared objects in a single transaction. Gate access driven by combat records — not static config, but live game state. This couldn't work on EVM without oracles.

**Why Unexpected:**
Nobody will think to use Killmail as a gate condition. It crosses two completely separate game systems (combat + infrastructure) into one mechanic.

**Demo Proof Moment:**
- Gate is locked
- Player kills target → Killmail created on-chain
- Player presents Killmail to gate extension → permit issued
- Player jumps through → JumpEvent emitted
- "The kill was the key."

**Complexity:** Medium — gate extension + killmail reads + config
**Win Potential:** 7/10 — visceral concept, but narrow utility. Strong "Weirdest Idea" contender.

---

### Concept 3: "ATOMIC COURIER" — Trustless Delivery Bounties

**Core Mechanic:** A complete logistics protocol. Sender posts a delivery bounty (Coin<EVE> escrow + item type + destination SSU). Courier picks up items, delivers to destination SSU, and claims bounty — all verified on-chain. The killer feature: **pickup → jump → deliver → claim payment in ONE PTB.**

**World-Contract Hooks:**
- `withdraw_item<Auth>` → courier claims package from source SSU
- `issue_jump_permit<Auth>` → permit to travel the route  
- `jump_with_permit` → jump through gate
- `deposit_item<Auth>` → deliver to destination SSU

> **v0.0.15 update:** `deposit_item<Auth>` now validates `parent_id` — items can only return to their origin SSU. Cross-SSU delivery must use `deposit_to_owned<Auth>` instead.

- Coin<EVE> → escrow and payment
- ExtensionConfig DF → delivery contracts (source, dest, item type, reward)

**Sui Primitives Leveraged:**
- **PTB composition (the showpiece):** withdraw item + issue permit + jump + deposit item + release payment — 5 operations, 3 assembly types, 1 atomic transaction
- Dynamic fields: delivery contract storage
- Coin splitting: escrow + payment in PTB
- Cross-assembly: Gate + source SSU + destination SSU in one tx

**Why Technically Impressive:**
This is the ultimate PTB demonstration. Five cross-object operations across three assembly types in a single atomic transaction. On EVM, this would require multiple transactions, escrow contracts, and trust assumptions. On Sui, it's one PTB. Judges who understand blockchain will immediately see the architectural advantage.

**Why Unexpected:**
Everyone builds access control or marketplaces. Nobody builds logistics. This creates a new economic role (courier) and a new emergent behavior (trade routes valued by delivery demand).

**Demo Proof Moment:**
- Bounty posted: "Deliver 100 units of Type X to SSU-B. Reward: 50 EVE"
- Courier picks up from SSU-A
- ONE TRANSACTION: withdraw → permit → jump → deposit → payment
- On-chain proof: ItemWithdrawnEvent → JumpEvent → ItemDepositedEvent → Coin transfer
- "Five operations. One transaction. Zero trust."

**Complexity:** High — two SSU extensions + gate extension + escrow + UI
**Win Potential:** 9/10 — novel, technically explosive, creates real utility, perfect demo moment

---

### Concept 4: "DEAD DROP" — Encrypted SSU Escrow Protocol

**Core Mechanic:** Extension-controlled SSU deposit where items are "sealed" in escrow with on-chain conditions (time-lock, specific recipient, payment required, kill-proof). Only the intended recipient, meeting the conditions, can withdraw. Creates trustless item exchange, mystery boxes, time capsules, and espionage mechanics.

**World-Contract Hooks:**
- `deposit_item<Auth>` → seal items into escrow SSU

> **v0.0.15 update:** `deposit_item<Auth>` now validates `parent_id` — items can only return to origin SSU. Use `deposit_to_owned<Auth>` for cross-SSU escrow deposits.

- `withdraw_item<Auth>` → release items when conditions met
- ExtensionConfig DF → escrow conditions (recipient address, unlock time, required payment, required killmail)
- Character → validate recipient identity
- Coin<EVE> → conditional payment

**Sui Primitives Leveraged:**
- Dynamic fields: escrow conditions stored per-deposit as typed DFs
- Shared objects: SSU as escrow vault
- PTB composition: deposit + condition-setting in one tx; withdrawal + payment in one tx
- Object capabilities: extension witness gates both deposit and withdrawal

**Why Technically Impressive:**
SSU extensions are completely unexplored — no scaffold implementation exists. This is first-mover on a blank canvas. The conditional logic (time-lock, recipient-specific, payment-gated) demonstrates dynamic field composability.

**Why Unexpected:**
Nobody thinks of SSUs as escrow vaults. The "dead drop" framing — leave items where only the right person can find them — creates instant narrative intrigue.

**Demo Proof Moment:**
- Player A deposits item with condition: "Only Player B, after midnight, with 10 EVE payment"
- Player B attempts early → rejected
- Player B attempts after midnight with payment → item released
- "The package was waiting. It always was."

**Complexity:** Medium — SSU extension + DF conditions + simple UI
**Win Potential:** 7/10 — creative, technically sound. Strong "Most Creative" play.

---

### Concept 5: "TOLL ROAD COALITION" — Revenue-Sharing Gate Network

**Core Mechanic:** Gate owners pool their gates into a coalition via a shared on-chain treaty. All gates in the coalition use the same extension. Jump tolls (Coin<EVE>) are collected and split proportionally among coalition members. Joining/leaving the coalition is an on-chain act with economic consequences.

**World-Contract Hooks:**
- `authorize_extension<Auth>` → enroll gate in coalition
- `issue_jump_permit<Auth>` → toll-gated permits
- Coin<EVE> → toll collection and revenue splitting
- ExtensionConfig DF → coalition membership, revenue shares, toll schedule
- Character.tribe_id → optional tribe-based pricing

**Sui Primitives Leveraged:**
- Dynamic fields: coalition membership registry, per-gate revenue tracking
- Coin splitting in PTB: toll split N-ways in single transaction
- Shared objects: coalition config as shared coordination point
- PTB: pay toll + split revenue + issue permit atomically

**Why Technically Impressive:**
Multi-party revenue splitting in a single PTB. Coin<EVE> split N-ways to different addresses, all atomic. This is a DAO-like pattern without DAO overhead.

**Why Unexpected:**
Gate owners competing is obvious. Gate owners *cooperating* with automated revenue sharing is unexpected. It's a protocol for infrastructure politics.

**Demo Proof Moment:**
- 3 gate owners form coalition
- Player pays 30 EVE toll
- ONE TRANSACTION: 10 EVE to owner A, 10 EVE to owner B, 10 EVE to owner C + permit issued
- "The coalition earns together."

**Complexity:** Medium — gate extension + DF coalition state + Coin splitting
**Win Potential:** 6/10 — solid concept but less visceral than others. Good "Most Utility" play.

---

### Concept 6: "THE GAUNTLET" — Sequential Multi-Gate Challenge Race

**Core Mechanic:** A race through a sequence of gates. Extension issues time-stamped permits at each checkpoint. Player must collect permits at each gate in order, within a time window. First to complete the full sequence wins a prize (Coin<EVE> from escrow). Permits expire — creating time pressure.

**World-Contract Hooks:**
- `issue_jump_permit<Auth>` → checkpoint-stamped permits
- JumpPermit.expires_at_timestamp_ms → time pressure
- ExtensionConfig DF → race definition (gate sequence, time limit, prize pool)
- Coin<EVE> → prize escrow and distribution
- Gate location data → route visualization

**Sui Primitives Leveraged:**
- Timestamp-based urgency: permits expire, creating real-time pressure  
- PTB: claim permit + jump at each checkpoint
- Dynamic fields: race state (checkpoints, standings, completing times)
- Events: JumpEvent at each checkpoint → real-time race tracking via indexer
- Shared object: race definition as global state

**Why Technically Impressive:**
On-chain verifiable speedrun with cryptographic timestamps. The race is self-enforcing — the chain validates sequence and timing. No referee needed.

**Why Unexpected:**
Nobody thinks of gates as race checkpoints. It turns infrastructure into sport and creates a spectator experience (watch the events roll in).

**Demo Proof Moment:**
- Race defined: Gate A → Gate B → Gate C, 5 minutes
- Player starts at Gate A, gets timestamped permit
- Races through B, C — each checkpoint verified on-chain
- Final checkpoint: completion time recorded, prize released
- "The chain is the referee."

**Complexity:** Medium-High — gate extension + race state + timing + UI
**Win Potential:** 7/10 — exciting concept, great demo energy. Strong "Weirdest Idea" or "Most Creative."

---

## PHASE 3 — Ranked Top 3

### Ranking Criteria Matrix

| Concept | Tech Impressive | Feasibility (4 days) | Uniqueness | Judge Alignment | Demo Clarity | **Score** |
|---------|:-:|:-:|:-:|:-:|:-:|:-:|
| Atomic Courier | 10 | 6 | 10 | 9 | 10 | **9.0** |
| Permit Exchange | 8 | 7 | 9 | 8 | 7 | **7.8** |
| The Gauntlet | 7 | 7 | 8 | 8 | 9 | **7.8** |
| Kill Trophy Gate | 7 | 8 | 8 | 7 | 8 | **7.6** |
| Dead Drop | 7 | 8 | 7 | 7 | 7 | **7.2** |
| Toll Road Coalition | 6 | 8 | 6 | 7 | 7 | **6.8** |

---

### #1: ATOMIC COURIER — Trustless Delivery Bounties

**Why #1:** This is the only concept that demonstrates Sui's architectural advantage in a way that is *impossible on any other chain*. Five cross-object operations across three assembly types in ONE atomic PTB. The "FedEx but trustless" narrative is instantly comprehensible. It creates a new player role (courier), a new economic primitive (delivery bounties), and uses the most underexplored surface (SSU extensions). Hits "Best Technical Implementation" and "Most Creative" simultaneously.

**Risk:** Highest complexity. Requires two SSU extensions + gate extension + escrow logic. If the 5-operation PTB doesn't work cleanly, the entire demo collapses.

---

### #2: PERMIT EXCHANGE — Route Futures Market

**Why #2:** JumpPermit tradability is THE most underexplored surface in world-contracts. Nobody else will discover that JumpPermit has `store`. The concept is intellectually bold (financializing movement itself) and technically novel (orderbook for game-native non-fungible travel rights). The PTB buy+jump moment is a strong demo.

**Risk:** Orderbook UI is complex. Price discovery in a demo with limited liquidity is hard to make visceral. The concept may be too "financial" for judges who value player utility.

---

### #3: THE GAUNTLET — Sequential Multi-Gate Challenge Race

**Why #3:** The strongest *emotional* demo of all concepts. A race is universally exciting. On-chain timestamps as referee is an elegant "why blockchain?" story. The spectator experience (watching JumpEvents roll in) creates demo energy that other concepts lack. Technically simpler than Courier or Exchange, but the demo impact per complexity dollar is highest.

**Risk:** Requires multiple gates to be linked and configured — setup overhead. The race mechanic is exciting but narrow in player utility. More of a "Weirdest Idea" play than a "Best Technical." 

---

## PHASE 4 — Selected Winner

### ATOMIC COURIER — Trustless Delivery Bounties

**Why this beats 90% of submissions:**

1. **It's architecturally impossible on any other chain.** Five cross-object operations in one atomic transaction — this IS the Sui value proposition, demonstrated in gameplay. Judges from Mysten Labs will immediately recognize this.

2. **It uses the most underexplored capability surface.** SSU extensions have NO scaffold implementation. Every other team will build gate extensions. We build on the blank canvas.

3. **It creates a new economic role.** "Courier" doesn't exist in EVE Frontier today. We're not adding a feature — we're adding a *profession*.

4. **The demo moment is explosive.** "Five operations. Three assembly types. One transaction. Zero trust." This is a 15-second clip that wins a hackathon.

5. **It composes ALL the impressive primitives.** PTB composition + cross-assembly + Coin<EVE> + dynamic fields + hot-potato receipt + events. It's a showcase of Sui capabilities.

6. **It has real utility.** Players need to move items between locations. Today that requires manual coordination and trust. This makes it trustless and atomic.

7. **It targets multiple prize categories.** Primary: Best Technical Implementation. Secondary: Most Creative. Stretch: Most Utility (it genuinely changes player logistics).

---

### A) 3-Day Sprint Plan

#### Day 1: Contract Work (Move)

**Morning — Core Extension Contract:**
- [ ] Create `courier_extension/` Move package
- [ ] Implement ExtensionConfig + AdminCap + XAuth (copy scaffold pattern, `public(package)`)
- [ ] Define DF key/value types:
  - `DeliveryContractKey { contract_id: u64 }` → `DeliveryContract { sender: address, source_ssu_id: ID, dest_ssu_id: ID, item_type_id: u64, quantity: u32, reward_amount: u64, status: u8, courier: Option<address> }`
  - `CourierRegistryKey {}` → `CourierRegistry { active_contracts: vector<u64>, next_id: u64 }`

**Afternoon — Core Logic Functions:**
- [ ] `post_bounty()` — sender creates delivery contract + escrows Coin<EVE> into extension-held balance
  - Takes: `&mut ExtensionConfig, &AdminCap, source_ssu_id, dest_ssu_id, item_type_id, quantity, Coin<EVE>, ctx`
  - Stores: DeliveryContract as DF on ExtensionConfig
- [ ] `claim_bounty()` — courier accepts a delivery contract
  - Takes: `&mut ExtensionConfig, contract_id, &Character, ctx`
  - Validates: contract exists, status is OPEN, courier address recorded
- [ ] `complete_delivery()` — THE big function
  - Takes: `&mut ExtensionConfig, &mut StorageUnit (source), &mut StorageUnit (dest), &mut Gate (source), &mut Gate (dest), &mut Character, contract_id, admin_acl, clock, ctx`
  - Atomically: withdraw_item from source SSU → issue_jump_permit → jump_with_permit → deposit_item to dest SSU → release Coin<EVE> payment

  > **v0.0.15 update:** `deposit_item` `parent_id` validation blocks cross-SSU deposit. `complete_delivery()` must use `deposit_to_owned<Auth>` for destination SSU.
  - Emits: DeliveryCompletedEvent

**Evening — Testing & Iteration:**
- [ ] Build + fix errors
- [ ] Test on local devnet: deploy, post bounty, claim, complete
- [ ] Validate the 5-operation PTB works atomically

**Day 1 validation gate:** Contract compiles. Post/claim/complete cycle works on devnet.

#### Day 2: Integration + Client (TypeScript + React)

**Morning — TS Scripts:**
- [ ] `post-bounty.ts` — create delivery contract PTB
- [ ] `claim-bounty.ts` — accept delivery PTB
- [ ] `complete-delivery.ts` — THE showcase PTB (5 operations)
- [ ] `list-contracts.ts` — read active delivery contracts via devInspect

**Afternoon — Simple React DApp:**
- [ ] Delivery board: list open contracts (source, dest, item, reward)
- [ ] Post bounty form (sender flow)
- [ ] Claim bounty button (courier flow)
- [ ] Complete delivery button (courier flow — signs the big PTB)
- [ ] Transaction result display (show all events from the atomic tx)

**Evening — Polish:**
- [ ] Error handling, loading states
- [ ] Display contract status transitions
- [ ] Event parsing for completion proof

**Day 2 validation gate:** Full post → claim → deliver cycle from React dApp. PTB events visible.

#### Day 3: Demo Hardening

**Morning — Demo Script:**
- [ ] Write exact scenario: "Alice posts bounty. Bob claims it. Bob delivers in ONE transaction."
- [ ] Record 3 takes of the full flow
- [ ] Capture on-chain transaction explorer showing 5 events from single tx

**Afternoon — Video Production:**
- [ ] 2-3 minute demo video
- [ ] Architectural overlay: "What just happened in that transaction"
- [ ] PTB diagram showing the 5 operations
- [ ] Comparison slide: "On EVM: 5 transactions. On Sui: 1."

**Evening — Submission Prep:**
- [ ] Clean repo (README, architecture doc, setup instructions)
- [ ] Verify all code runs from fresh clone
- [ ] Submit to Deepsurge

---

### B) Architectural Risks

| Risk | Severity | Mitigation | Validate By |
|------|----------|-----------|-------------|
| **5-operation PTB may exceed gas budget** | High | Test early on devnet. Worst case: split into 2 PTBs (deliver + jump separate) | Day 1 evening |
| **SSU extension `deposit_item`/`withdraw_item` may require objects we can't access in test** | High | Use builder-scaffold test resources to create SSUs. If blocked: mock with simpler DF storage | Day 1 morning |

> **v0.0.15 update:** `deposit_item<Auth>` `parent_id` validation blocks cross-SSU deposit. Courier delivery must use `deposit_to_owned<Auth>` to deposit items into destination SSU.
| **Gate + SSU must both have matching extension type** | Medium | Deploy same `XAuth` type on both gate and SSU. Validate `authorize_extension` on both | Day 1 afternoon |
| **Coin<EVE> escrow requires holding balance in extension** | Medium | Use Coin<EVE> in a DF on ExtensionConfig, or use `Balance<EVE>` as DF value | Day 1 morning |
| **jump_with_permit requires AdminACL sponsorship** | Medium | Already understood. Use dual-sign pattern from scaffold. May need to separate jump from delivery PTB | Day 1 afternoon |
| **No real game data on devnet** | Low | Create mock characters, gates, SSUs via admin functions. Demo works with synthetic data | Day 1 morning |
| **Demo video timing** | Low | Script exactly. Record multiple takes. Edit for clarity | Day 3 |

**Earliest validation (Day 1 morning):**
1. Can we `authorize_extension<XAuth>` on BOTH a Gate AND an SSU from the same package?
2. Can we `withdraw_item<XAuth>` from one SSU and `deposit_item<XAuth>` to another in one PTB?
3. Does the gas budget support 5 cross-object operations?

If any of these fail, fallback plan:
- **Fallback A:** Drop the jump from the atomic PTB. Delivery = withdraw + deposit + payment (still 3 operations, still impressive).
- **Fallback B:** Pivot to Permit Exchange (Concept 2) — lower complexity, still novel.

---

### C) Why This Beats 90% of Submissions

**1. Most submissions will be gate-only.** The scaffold provides gate examples. Everyone will build gate access control with minor twists. We build on SSU extensions (blank canvas) with gate integration.

**2. Most submissions won't use Coin<EVE>.** The EVE token exists but nobody thinks to use it in toll/payment flows. We make it a core economic primitive.

**3. Most submissions will be single-assembly.** One gate, one extension, one operation. We compose three assembly types in one transaction.

**4. Most submissions won't have a clear "why Sui" moment.** Our demo literally shows something impossible on any other chain — 5 cross-object atomic operations.

**5. Most submissions will show a UI.** We show a protocol. The UI is secondary. The on-chain behavior IS the product.

**6. Most submissions will target "Best Entry."** We target "Best Technical Implementation" — a less-crowded category with a clear judging rubric (clean architecture, smart system use, scalability).

**7. The demo narrative is self-evident.** "Alice needs items moved. Bob is a courier. Bob delivers in one transaction. No trust required." Judges understand this in 10 seconds.

**8. It creates emergent behavior.** Once couriers exist, route pricing emerges. Dangerous routes cost more. Safe routes are cheap. We didn't code an economy — we enabled one.

---

## Appendix: Concept Comparison Matrix

| Dimension | Atomic Courier | Permit Exchange | The Gauntlet | Kill Trophy | Dead Drop | Toll Coalition |
|-----------|:-:|:-:|:-:|:-:|:-:|:-:|
| Uses SSU extension | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Uses Gate extension | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| Uses Coin<EVE> | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ |
| Uses Killmail | ❌ | ❌ | ❌ | ✅ | Optional | ❌ |
| Cross-assembly PTB | ✅ (3 types) | ❌ | ❌ | ❌ | ❌ | ❌ |
| New player role | ✅ (courier) | ✅ (trader) | ✅ (racer) | ❌ | ❌ | ❌ |
| Novel economic primitive | ✅ (delivery) | ✅ (route futures) | ✅ (race prize) | ❌ | ✅ (escrow) | ✅ (revenue share) |
| Demo clarity | 🟢 Instant | 🟡 Needs context | 🟢 Exciting | 🟢 Visceral | 🟡 Abstract | 🟡 Political |
| Build complexity | High | Medium-High | Medium | Medium | Medium | Medium |
| Prize target | Best Technical | Most Creative | Weirdest | Weirdest | Most Creative | Most Utility |
