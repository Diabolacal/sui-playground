# Hackathon Shortlist — Recommendations

**Retention:** Carry-forward

> **Companion to:** [hackathon-ideas-grounded-v3-judged.md](hackathon-ideas-grounded-v3-judged.md)
> **Date:** 2026-02-15

---

## Primary Recommendation: CivilizationControl

A unified infrastructure management dashboard for EVE Frontier. Three core modules sharing auth, UI, and data model — demonstrating "system design, not a one-off."

### Core Modules (Build These)

| # | Module | What It Does | Risk | Weighted Score |
|---|--------|-------------|------|----------------|
| 1 | **GateControl** | Composable gate policies — tribe filter, time window, item toll — configured from web dashboard. Single extension, multiple rules via dynamic fields. | Green | 7.97 |
| 2 | **TradePost** | SSU storefront — list items, browse/buy with atomic PTB escrow. Extends commerce beyond station hubs to player-deployed infrastructure. Supports SUI and faction currencies. | Yellow | 7.91 |
| 3 | **TribeMint** | Faction currency — `Coin<TribeToken>` flows through GateControl tolls and TradePost purchases. | Green | 6.31 |

### Stretch Module (If Time Permits)

| # | Module | What It Does | Risk | Weighted Score |
|---|--------|-------------|------|----------------|
| 4 | **LootDrop** | VRF loot crate via `sui::random` — gamified item distribution through TradePost SSUs. | Yellow | 7.53 |

### Why This Suite Wins

- **ModDesign 10/10:** Three interconnected modules with shared auth, shared data model, and economic feedback loops.
- **Frontier Vibe 9/10:** Gate control + field-deployable commerce + tribal economy = the pillars of EVE civilization.
- **Demo moment:** Buyer pays 25 ALPHA_COIN (faction currency) at the TradePost for a trophy — same ALPHA_COIN that's accepted as a gate toll. Three modules, one economy.
- **Player vote 7–8/10:** "Space shop" is instantly understood; faction currencies add identity/loyalty hooks.
- **Technical depth:** Dynamic field composition, PTB buy flow, Coin standard — demonstrates 3+ Sui primitives.

---

## Top Picks by Bonus Prize Category

### Most Utility
1. **SSU Storefront** — No field-deployable commerce exists. Every SSU owner is a potential shopkeeper.
2. **Gate Policy Engine** — Every gate owner benefits immediately.
3. **Corp Command Center** — Single pane of glass for all structures.

### Best Technical Implementation
1. **ZK GatePass** — Full ZK stack: circuit → browser proof → on-chain verification → game action.
2. **Gate Policy Engine** — Dynamic field rule dispatch within single-extension constraint.
3. **Energy Arbitrage Bot** — Hot-potato PTB chain demonstrating advanced transaction composition.

### Most Creative
1. **Salvage Protocol** — Uses Sui's gas rebate as a gameplay reward. Nobody else will think of this.
2. **ZK GatePass** — ZK proofs for game infrastructure. Unique category intersection.
3. **Dead Drop** — Spy gameplay on blockchain. Evocative concept despite privacy limitations.

### Weirdest Idea
1. **Fortune Gate** — Slot-machine gate. 80% you jump, 20% you're stranded. Clip-worthy.
2. **Gate Graffiti Wall** — Spray-paint on-chain messages at gates. Memeable.
3. **Proof-of-Presence Badge** — ZK "I Was There" NFTs. Niche but collectible.

### Best Live Frontier Integration
1. **Corpse Toll Road** — Working template code exists. Lowest barrier to Stillness deployment.
2. **Gate Policy Engine** — Deploy extension to real gate. Needs AdminACL + gate ownership.
3. **Faction Mint** — Coin creation is permissionless. Integration needs structure ownership.

---

## Decision Matrix: If You Only Have Time For...

| Time Budget | What to Build | Expected Composite |
|-------------|---------------|-------------------|
| **1 module** | GateControl (ID 1 + 8) standalone with toll + tribe filter | ~7.5 |
| **2 modules** | GateControl + TradePost | ~8.0 |
| **3 modules** | GateControl + TradePost + TribeMint (full CivilizationControl) | ~8.5+ (system bonus) |
| **3 + stretch** | Full CivilizationControl + LootDrop | ~8.8+ |
| **Going for creativity prize** | ZK GatePass (ID 5) standalone | ~7.2 (high variance) |
| **Going for weirdest** | Fortune Gate (ID 26) standalone | ~5.4 (fun, low score) |

---

## Risk Summary

| Module | Key Risk | Mitigation |
|--------|----------|------------|
| GateControl | None — template code exists, pattern validated | — |
| TradePost | Cross-address PTB item transfer unvalidated | Day-1 de-risk task on local devnet |
| TribeMint | None — Coin standard is well-documented | — |
| LootDrop | `sui::random` entry function constraint | Test calling convention early; fallback to hash-based pseudo-random |
| ZK GatePass | ~~Package-naming conflict + bridge complexity~~ Resolved — validated on local devnet (sandbox). Membership circuit design remains. | Wrapper module validated; see [ZK feasibility report](../operations/zk-gatepass-feasibility-report.md). To re-validate on hackathon test server March 11. |

---

## Implementation Priority Order

```
Day 1:  GateControl Move module + tribe filter rule type
        De-risk TradePost cross-address PTB transfer
Day 2:  GateControl toll rule type (absorbs Corpse Toll Road)
        TradePost Move module + listing CRUD
Day 3:  TribeMint Coin<T> module + gate toll integration
        Dashboard shell (shared UI with structure sidebar)
Day 4:  TradePost web UI (browse/buy flow)
        GateControl web UI (policy builder)
Day 5:  Integration: TribeMint currency in TradePost prices
        Event feed + revenue tracking
Day 6:  Polish, demo preparation, stretch (LootDrop if stable)
Day 7:  Demo video recording (primary) + final testing
```

> **Note:** Timeline assumes LLM-accelerated iteration. No human-time estimates — this is a capability-ordered priority list.

---

## Demo Strategy (Recorded Video)

> **Context:** The Deepsurge submission form requests a demo video link (e.g., YouTube). This confirms judges evaluate a pre-recorded video, not a live streamed demo. See [hackathon-event-rules-digest.md](../research/hackathon-event-rules-digest.md#submission-artifacts-observed-via-deepsurge-ui) for details.

### Recommended Video Length

- **Primary submission:** 2–4 minutes (target 3 minutes)
- **Player-vote cutdown:** 30–60 seconds (shareable highlight reel for social/voting)

### Video Structure (Primary)

| Segment | Duration | Content |
|---------|----------|---------|
| **Hook** | 0:00–0:15 | One-sentence problem statement + visual of the problem in-game |
| **Problem** | 0:15–0:40 | Show the current player pain point (no gate control, no field commerce) |
| **Capability Demo** | 0:40–2:20 | Screen-captured walkthrough of real on-chain functionality. Show actual transactions executing, not mockups |
| **Result** | 2:20–2:45 | Dashboard/event-feed view showing the system working end-to-end |
| **Why It Matters** | 2:45–3:00 | One-sentence value proposition + "CivilizationControl" branding |

### Player Vote Cutdown (30–60s)

- Open with the most dramatic moment (gate denial or atomic trade)
- Show 2–3 quick capability clips with text overlays
- End with the system dashboard view + project name
- Optimize for shareability: captions (many viewers watch muted), fast pacing, clear visuals

### Recording Discipline

- **Script the full flow** before recording — storyboard each segment
- **Pre-deploy all state** on devnet before hitting record (characters, items, balances)
- **Multiple takes are expected** — re-record any segment that stutters
- **Real transactions only** — do not fake or mock chain interactions
- **Post-production:** Add captions, subtle annotations for technical moments, trim dead time
- **B-roll:** Capture extra footage of dashboard, event feeds, and wallet confirmations for editing flexibility
