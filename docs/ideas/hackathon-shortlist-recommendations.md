# Hackathon Shortlist — Recommendations

> **Companion to:** [hackathon-ideas-grounded-v3-judged.md](hackathon-ideas-grounded-v3-judged.md)
> **Date:** 2026-02-15

---

## Primary Recommendation: CivilizationControl

A unified infrastructure control plane for EVE Frontier. Three core modules sharing auth, UI, and data model — demonstrating "system design, not a one-off."

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
1. **ZK Gate Pass** — Full ZK stack: circuit → browser proof → on-chain verification → game action.
2. **Gate Policy Engine** — Dynamic field rule dispatch within single-extension constraint.
3. **Energy Arbitrage Bot** — Hot-potato PTB chain demonstrating advanced transaction composition.

### Most Creative
1. **Salvage Protocol** — Uses Sui's gas rebate as a gameplay reward. Nobody else will think of this.
2. **ZK Gate Pass** — ZK proofs for game infrastructure. Unique category intersection.
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
| **Going for creativity prize** | ZK Gate Pass (ID 5) standalone | ~7.2 (high variance) |
| **Going for weirdest** | Fortune Gate (ID 26) standalone | ~5.4 (fun, low score) |

---

## Risk Summary

| Module | Key Risk | Mitigation |
|--------|----------|------------|
| GateControl | None — template code exists, pattern validated | — |
| TradePost | Cross-address PTB item transfer unvalidated | Day-1 de-risk task on local devnet |
| TribeMint | None — Coin standard is well-documented | — |
| LootDrop | `sui::random` entry function constraint | Test calling convention early; fallback to hash-based pseudo-random |
| ZK Gate Pass | Package-naming conflict + bridge complexity | Wrapper module; allocate 2 full days if pursuing |

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
Day 6:  Polish, demo rehearsal, stretch (LootDrop if stable)
Day 7:  Demo recording backup + live demo dry runs
```

> **Note:** Timeline assumes LLM-accelerated iteration. No human-time estimates — this is a capability-ordered priority list.
