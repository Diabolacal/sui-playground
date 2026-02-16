# Hackathon Portfolio Roadmap — Multi-Entry Submission Strategy

**Retention:** Carry-forward

> **Date:** 2026-02-16  
> **Status:** Pre-hackathon planning (code moratorium until March 11)  
> **Inputs:** Strategy memo, V3 judging analysis, feasibility reports, validation results, rules digest, prize category reverse-engineering, fast-sprint analysis, ZK feasibility report  
> **Mode:** Competitive strategy — bold, decisive, kill-switch-aware

---

## 1. Executive Summary — Portfolio Thesis

**We are not entering a hackathon. We are running a prize campaign.**

The EVE Frontier hackathon has 8 prizes across 6 categories. One entry can win max 1 prize. The optimal strategy is not to build one great project — it is to **blanket the prize surface** with purpose-built entries, each targeting a specific prize category, while concentrating primary effort on the flagship.

### Portfolio Shape

| Track | Project | Target Prize | Days | Confidence |
|-------|---------|-------------|------|------------|
| **A — Flagship** | CivilizationControl (GateControl + TradePost + ZK rule) | Best Entry 1st + Best Technical Implementation | 12–14 | High |
| **B — Technical Spike** | ZK Privacy Rule (integrated into Track A) | *(folded into Track A)* | *(included)* | Medium-High |
| **C1 — Fast Sprint** | Fortune Gate | Weirdest Idea | 1 | Very High |
| **C2 — Fast Sprint** | Salvage Protocol | Most Creative | 1.5 | Medium-High |
| **C3 — Fast Sprint** | Corpse Toll Road | Most Utility / Best Live Integration | 0.5–1 | Very High |
| **D — Wildcard** | Loot Crate | Best Technical (backup) | 1.5 | Medium |

**Total entries: 4 (flagship + 3 sprints), with 1 optional wildcard.**

### Win Thesis (One Sentence)

CivilizationControl wins Best Entry by being the only system-level submission in a field of single-feature mods, while three surgical side entries snipe every remaining bonus category — guaranteeing at minimum $10k+ in prizes and maximizing expected value across the entire prize pool.

### Expected Value Analysis

| Scenario | Probability | Prize Value |
|----------|------------|-------------|
| CC wins 1st Best Entry + 2 bonus wins | 15% | $25,000 + tokens |
| CC wins 2nd/3rd + 2 bonus wins | 25% | $17,500–$20,000 |
| CC wins 1 bonus + 2 side bonus wins | 30% | $15,000 |
| 2 bonus wins only (CC misses top 3) | 20% | $10,000 |
| 1 bonus win | 10% | $5,000 |

**Weighted expected value: ~$15,000–$17,000.** This is a portfolio bet, not a single-entry gamble.

---

## 2. Portfolio Architecture Overview

```
                        ┌─────────────────────────────────┐
                        │    HACKATHON PRIZE SURFACE       │
                        │  8 prizes across 6 categories    │
                        └──────────────┬──────────────────┘
                                       │
              ┌────────────────────────┼────────────────────────┐
              │                        │                        │
    ┌─────────▼──────────┐   ┌────────▼────────┐   ┌──────────▼──────────┐
    │   TRACK A          │   │   TRACK C        │   │   TRACK D           │
    │   Flagship         │   │   Fast Sprints   │   │   Wildcard          │
    │                    │   │                  │   │   (conditional)     │
    │ CivilizationControl│   │ C1: Fortune Gate │   │ Loot Crate          │
    │ • GateControl      │   │ C2: Salvage Proto│   │ → Best Technical    │
    │ • TradePost        │   │ C3: Corpse Toll  │   │   (only if CC       │
    │ • ZK Privacy Rule  │   │                  │   │    doesn't need it) │
    │                    │   │                  │   │                     │
    │ → Best Entry 1st   │   │ → Weirdest       │   └─────────────────────┘
    │ → Best Technical   │   │ → Most Creative  │
    │                    │   │ → Most Utility   │
    └────────────────────┘   └──────────────────┘

    Track B (ZK Spike) → INTEGRATED into Track A as GateControl rule type
                          (not standalone — cannibalization risk too high)
```

### Why This Shape

1. **CivilizationControl is the only system-level entry.** V3 analysis confirms single-module entries cap at ~7-8 on ModDesign. A two-module integrated system with ZK privacy rule scores 9-10. In a field of ~30-60 entries, most will be single features.

2. **Side entries cost almost nothing.** Fortune Gate: 8-12 hours. Corpse Toll Road: 6-8 hours. These are built AFTER CC stabilizes and use DIFFERENT Sui primitives — no pattern collision, no context-switching overhead.

3. **The "one prize per entry" rule REWARDS multi-entry strategies.** If CC wins Best Entry, the three side entries are still eligible for all bonus prizes. If CC misses top 3, it can still win Best Technical Implementation while side entries sweep other bonuses.

4. **Least-contested categories are cheapest to snipe.** Best Live Integration: <5 serious competitors. Weirdest Idea: 5-10, many half-hearted. Most Creative: 10-15. These are low-cost, high-EV targets.

---

## 3. Track A — CivilizationControl (Flagship)

### Win Thesis

CivilizationControl wins Best Entry by being the only submission that demonstrates **system design** — two tightly integrated smart assembly extensions (gate + SSU) sharing auth, data model, and economic feedback loops, with a ZK privacy rule that no other entry will have. The recorded demo video tells a story arc from "you're blind" to "you control your frontier."

### Configuration: Modified Thesis (2+ZK)

Per the strategy memo's adversarial critique, TribeMint is **demoted to stretch**. The core submission is:

| Priority | Module | Status | Weighted Score | Risk |
|----------|--------|--------|----------------|------|
| 1 | **GateControl** — Composable gate policy engine (tribe filter, coin toll, time window) | Core | 7.97 | Green |
| 2 | **TradePost** — SSU storefront with atomic PTB escrow | Core | 7.91 | Green (validated) |
| ZK | **ZK Privacy Rule** — Groth16-verified gate access (Merkle membership proof) | Core differentiator | +1.5 est. | Green (composition validated 2026-03-11; membership circuit pending) |
| S1 | TribeMint — Faction `Coin<TribeToken>` | Stretch | 6.31 | Green |
| S2 | LootDrop — VRF loot crate via `sui::random` | Stretch | 7.53 | Yellow |

### Why ZK Is Now Core (Not Track B)

The ZK feasibility analysis produced a clear recommendation: **integrate, don't separate.**

| Dimension | As Standalone Entry | As GateControl Rule Type |
|-----------|--------------------|-----------------------|
| Time cost | 22-38 hours (3-4 days) | 18-28 hours (saves wrapper overhead, shared devnet setup) |
| Prize target | Best Technical Implementation only | CivilizationControl targets Best Entry AND Best Technical |
| Demo impact | Separate 60s video | 30s segment inside 3-min flagship demo |
| Cannibalization | Severe — 29-57% of total dev capacity | Zero — built on same gate extension pattern |
| Working demo probability | 45-55% full | 50-60% (shared infrastructure reduces setup risk) |

**Decision: ZK is a GateControl rule type, not Track B.** The existing `eve-frontier-proximity-zk-poc` provides 60-70% of the work. The integration seam (circuit → Move verifier → gate extension) is buildable and the core composition (Groth16 verify + gate witness) has been validated on devnet (addendum 2026-03-11). ZK is upside, not dependency.

### Differentiator

**No other hackathon entry will have ZK-verified game infrastructure access.** The combination of dynamic field rule composition + cross-address PTB trading + Groth16 verification demonstrates mastery of three distinct Sui primitive families. This is the widest technical footprint of any single entry.

### Remaining Validation (March 11 De-Risking)

> **ZK Note:** Groth16 on-chain verification and ZK+gate composition are now validated on local devnet (addendum 2026-03-11). See [validation report](../operations/shortlist-viability-validation-report.md) tests 8–10 and [ZK feasibility report](../operations/zk-gatepass-feasibility-report.md) §2.1. Membership circuit design and package extraction remain as implementation tasks.

| Item | Risk | Action | Time |
|------|------|--------|------|
| TradePost cross-address PTB on full world-contracts | Low (already validated) | Re-run validation with published world package | 2 hours |
| GateControl → `issue_jump_permit` → `jump_with_permit` integration | Medium | Full gate lifecycle on devnet (requires forged location proofs) | 4-8 hours |
| Sponsored transaction setup (AdminACL) | Medium | Self-register as sponsor on local devnet | 1-2 hours |
| ZK circuit → Move Groth16 verification | Low (composition validated) | Design membership circuit; on-chain verify already proven | 4-8 hours |
| Lux-to-SUI display conversion | Low (UX only) | Inspect game server behavior if accessible | 1 hour |

### Risk Register

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|------------|
| 1 | **Full gate lifecycle setup too complex** | Medium | High — GateControl demo needs working gates | Script setup chain (governor → admin → characters → NWN → gates → link → online). Test file `gate_tests.move` provides complete pattern. |
| 2 | **ZK integration fails** | Low | Low — GateControl still works without ZK | Composition validated on devnet (2026-03-11). Remaining risk is membership circuit design. Kill at Day 3 midpoint if circuit fails. |
| 3 | **Scope creep into TribeMint** | Medium | Medium | Hard rule: TribeMint starts only after full CC demo rehearsal passes. |
| 4 | **Demo video quality insufficient** | Low | High | Script, storyboard, and pre-deploy all state before recording. Multiple takes. Post-production captions. Budget 1 full day for demo. |
| 5 | **Multiple submissions disallowed** | Low | Critical | FAQ indicates yes. Verify with organizer before March 11. If NO: Fortune Gate becomes GateControl's weird-rule-type, pivoting to single-entry strategy. |

### Estimated Score

| Criterion (12.5% each) | Score | Notes |
|------------------------|-------|-------|
| Concept & Feasibility | 9 | Real pain point, proven prototype |
| Mod Design | 9.5 | Two-module integrated system + ZK composability |
| Concept Implementation | 8.5 | Full-stack: Move + web UI + ZK |
| Player Utility | 9 | Gate control + commerce = immediate value |
| Frontier Vibe | 9 | Gate governance + field commerce = peak EVE |
| Creativity | 8.5 | ZK privacy rule elevates from 7 → 8.5 |
| UX & Usability | 8.5 | Dashboard with policy builder, one-click buy |
| Demo | 9 | Story arc: problem → control → commerce → ZK reveal |
| **Judge Average** | **8.81** | |
| Player Vote | 7.5 | TradePost (8) carries; ZK wow adds 0.5 |
| **Weighted Total** | **8.48** | Competitive for 1st place |

---

## 4. Track B — Technical Spike → INTEGRATED

**Decision: Track B does not exist as a separate track.**

The ZK feasibility analysis conclusively shows that ZK Gate Pass delivers higher expected value as an integrated GateControl rule type than as a standalone entry. See §3 for rationale.

The "Technical Spike" concept is preserved as the ZK Privacy Rule within Track A. If ZK integration hits kill criteria, Track A gracefully degrades to a two-rule-type gate policy engine + TradePost — still the strongest entry in the field.

### Kill Criteria (ZK within Track A)

> **Status update (2026-03-11):** On-chain Groth16 verification and ZK+gate composition are validated (see [validation report](../operations/shortlist-viability-validation-report.md) tests 8–10). The checkpoints below for on-chain verify and gate integration are satisfied. Membership circuit design remains the primary kill gate.

| Checkpoint | Deadline | Signal | Status |
|-----------|----------|--------|--------|
| Circuit compiles + generates valid proofs | End of Day 1 | If no, ZK is cut | Pending (implementation task) |
| Move Groth16 verifier accepts proof on devnet | End of Day 2 | If no after >4 hours debugging, cut | **PASSED** (2026-03-11) |
| Full gate extension integration works | Mid-Day 3 | If no, fall back to CLI demo or cut entirely | **PASSED** (2026-03-11) |

---

## 5. Track C — Fast Sprint Candidates

### Strategic Frame

Side entries serve two purposes: (1) blanket remaining bonus categories CivilizationControl can't win, and (2) provide **psychological relief** from the flagship grind. Each sprint project uses a DIFFERENT Sui primitive than CivilizationControl, is buildable in ≤1.5 days, and produces a standalone recorded demo video.

**Critical constraint: side entries begin ONLY after CivilizationControl core is demo-stable.** Not code-complete — demo-stable. If CC can't produce a watchable 3-minute video, no sprints start.

---

### C1: Fortune Gate — Weirdest Idea

**One-sentence pitch:** *"A gate that plays dice with your journey — verifiably fair, dramatically unfair."*

| Dimension | Detail |
|-----------|--------|
| **Target Prize** | Weirdest Idea ($5,000 + $1,000 SUI) |
| **Concept** | Gate extension using `sui::random` VRF. 80% chance you jump, 20% you're stranded. Verifiable on-chain — nobody rigged it. |
| **Sui Primitive** | `sui::random` (different from all CC modules) |
| **Build Time** | 8–12 hours LLM-assisted |
| **Demo Impact** | 9/10 — Every demo viewing creates suspense. Record both outcomes. |
| **Meme Potential** | 9/10 — "Fortune Gate roulette" is the kind of phrase that spreads. Players share failure clips. |
| **Psychological Reward** | **Maximum.** After grinding on CC's multi-module architecture, Fortune Gate is a palate cleanser: one module, one entry function, one web page. The first test failure makes you laugh. |
| **Win Probability** | **70-80%.** No other entry will have a slot-machine gate. The concept is immediately understood, inherently funny, and produces a different outcome every demo viewing. Judges laugh, players vote. |

**Kill Criteria:** Abandon if `sui::random` integration doesn't produce verifiable randomness within 4 hours on local devnet. Fallback: pseudo-random via tx hash (weaker but still weird).

**Build Plan:**
1. Gate extension module: `sui::random` → `entry` function → outcome determination
2. Simple web UI: slot-machine animation (CSS only), outcome display
3. Record both 80% success AND 20% failure in demo video
4. Total: one afternoon

**Why It Wins Weirdest:** Commitment to the bit. The demo video IS the product — suspense, resolution, on-chain proof. The recorded format means you capture both outcomes. No other entry combines "functional smart contract" with "game show format."

---

### C2: Salvage Protocol — Most Creative

**One-sentence pitch:** *"Abandoned structures become loot — and Sui's own storage rebate pays the bounty."*

| Dimension | Detail |
|-----------|--------|
| **Target Prize** | Most Creative ($5,000 + $1,000 SUI) |
| **Concept** | Wrapper around structure lifecycle that turns `unanchor()` into a gameplay loop. Abandoned structures → claim salvage → Sui's storage rebate mechanism pays the bounty. |
| **Sui Primitive** | Storage rebate economics (unique — nobody will touch this) |
| **Build Time** | 10–14 hours LLM-assisted |
| **Demo Impact** | 7/10 — Intellectually striking. "Wait, the blockchain itself pays you?" The aha is conceptual, not visual. |
| **Meme Potential** | 6/10 — More "that's clever" than "holy shit." Appeals to judges more than casual players. |
| **Win Probability** | **60-70%.** V3 analysis ranks it #1 for Most Creative. The mechanism is genuinely novel — no other blockchain game has turned gas rebate economics into a gameplay reward. |

**Kill Criteria:** Abandon if `unanchor()` requires `AdminCap` and cannot be called by a builder extension. Check within first 2 hours. Fallback: wrap around custom structures deployed by the salvager (not world-contract structures) — still demonstrates the rebate concept.

**Build Plan:**
1. Research: confirm `unanchor()` access control (2 hours)
2. `SalvageBounty` module wrapping structure lifecycle (4-6 hours)
3. Web UI: "abandoned" structure list → claim button → wallet balance update (4-6 hours)
4. Demo: "Before: dead structure wasting chain storage. After: recycled, and you got paid."

**Why It Wins Most Creative:** Nobody else will think to make gas economics a game mechanic. The V3 document already flagged this as the most novel concept in the 28-idea pool. Deep understanding of Sui's economic model, not just its programming model.

---

### C3: Corpse Toll Road — Most Utility / Best Live Integration

**One-sentence pitch:** *"The first pay-with-loot gate in EVE Frontier — bring a corpse or walk."*

| Dimension | Detail |
|-----------|--------|
| **Target Prize** | Most Utility ($5,000 + $1,000 SUI) — or Best Live Frontier Integration if Stillness deployment is feasible |
| **Concept** | Deploy the existing `corpse_gate_bounty.move` template with a web UI for configuration. Simplest, highest-certainty entry. |
| **Sui Primitive** | Typed witness extension (simpler version of GateControl pattern) |
| **Build Time** | 6–8 hours LLM-assisted (lowest of all candidates) |
| **Demo Impact** | 8/10 — "Deposit a corpse. Gate opens. No corpse, no jump." Visceral, immediate, macabre humor. |
| **Meme Potential** | 7/10 — "Corpse toll" is memorable. Works for EVE's audience. |
| **Win Probability** | **50-60% for Most Utility.** It's the most directly useful single-feature mod. Every gate owner can immediately use it. Higher if targeting Best Live Integration (fewer competitors). |

**Kill Criteria:** Abandon if template code doesn't compile against current world-contracts within 2 hours (unlikely — it's the scaffold's own template).

**Build Plan:**
1. Deploy `corpse_gate_bounty.move` (possibly with minor type_id configuration)
2. Minimal React UI: gate owner sets toll item type, jump attempt view shows success/failure
3. Record demo: corpse deposit → gate opens vs. no corpse → denied
4. **Stretch:** Deploy to Stillness testnet for Best Live Integration targeting

**Overlap with CivilizationControl:** GateControl absorbs the item toll pattern. But Corpse Toll Road is a *different entry* — simpler, single-purpose, positioned as a utility mod, not a system. The code is distinct (dedicated module vs. dynamic field dispatch). Judges evaluate separately.

---

### C-Track Backup: Dead Drop

If either Fortune Gate or Salvage Protocol hits its kill criteria, Dead Drop (hash-keyed spy slots) serves as backup. Build time: 12-16 hours. Targets either Weirdest or Most Creative. The event-layer privacy leak is a known narrative weakness — deploy only if primary candidates fail.

---

## 6. Track D — Wildcard: Loot Crate (Conditional)

### When to Build

Loot Crate is deployed **only** if:
1. CivilizationControl core is demo-stable AND
2. All three Track C sprints are demo-complete AND
3. LootDrop was NOT built as CC's stretch module AND
4. There is still ≥1 day of development time remaining

### Why It Exists

- Targets Best Technical Implementation as a backup (if CC wins Best Entry instead)
- Exercises `sui::random` VRF + dynamic field loot tables + `Coin<SUI>` payment — three Sui primitives cleanly composed
- Universal gamer mechanic: "Crack the crate — Legendary or junk. Check the VRF proof on-chain."
- Player vote pull: 8/10

### Direction: Build or Cut

If CC ships with LootDrop as stretch module, do NOT submit Loot Crate separately (same mechanic, weaker version). The decision is made on Day 3 of the build sprint based on CC scope status.

**Kill Criteria:** If dynamic field loot tables + VRF integration exceeds 8 hours, cut to hardcoded 3-tier table or abandon entirely.

---

## 7. Prize Category Mapping Matrix

| Prize | Primary Entry | Backup Entry | Competition Level | Our Strength | Win % |
|-------|--------------|-------------|-------------------|--------------|-------|
| **Best Entry 1st** | CivilizationControl | — | High (all entries eligible) | System-level design, ZK differentiator, strong demo | 15-20% |
| **Best Entry 2nd** | CivilizationControl | — | High | Same | 20-25% |
| **Best Entry 3rd** | CivilizationControl | — | High | Same | 25-30% |
| **Best Technical** | CivilizationControl (ZK rule) | Loot Crate (Track D) | Medium (15-25 entries) | Groth16 + dynamic fields + PTB composition | 30-40% |
| **Most Utility** | Corpse Toll Road (C3) | CivilizationControl (if not winning Best Entry) | Medium (15-25 entries) | Working code, immediate player value | 35-45% |
| **Most Creative** | Salvage Protocol (C2) | Dead Drop (backup) | Low-Medium (10-15 entries) | Novel mechanism nobody else will attempt | 50-60% |
| **Weirdest Idea** | Fortune Gate (C1) | Dead Drop (backup) | Low (5-10 entries) | Maximum commitment to the bit | 65-75% |
| **Best Live Integration** | Corpse Toll Road (C3 stretch) | — | Very Low (<5 entries) | Scaffold infrastructure + devnet experience | 40-60% (if Stillness accessible) |

### Prize Coverage

In the best case, we can win **4 prizes simultaneously** (Best Entry + Weirdest + Most Creative + Most Utility) because each is a separate entry.

In the worst case, we win **1 prize** (Weirdest Idea via Fortune Gate) — which is still $5,000 + $1,000 SUI for a half-day of work.

**The portfolio strategy ensures nonzero prize capture.** This is the key insight: a single flagship that misses the top 3 wins nothing. A portfolio that includes Fortune Gate wins *something* almost certainly.

---

## 8. Risk Distribution Analysis

### Risk Profile by Track

| Track | Technical Risk | Scope Risk | Timeline Risk | Demo Risk |
|-------|--------------|-----------|--------------|----------|
| A (CC) | Medium (ZK integration) | Medium (3 modules if stretch ships) | Medium (12-14 day build) | Low (scripted, re-recordable) |
| C1 (Fortune Gate) | Low (`sui::random` is standard) | Very Low (one module) | Very Low (half-day) | Very Low (suspense is built-in) |
| C2 (Salvage) | Low-Medium (`unanchor` access) | Low (one module) | Low (1.5 days) | Medium (conceptual, not visual) |
| C3 (Corpse Toll) | Very Low (template exists) | Very Low (one module) | Very Low (half-day) | Low (clear before/after) |
| D (Loot Crate) | Low-Medium (`sui::random` entry constraint) | Low | Low (1.5 days) | Low (universal mechanic) |

### Failure Cascade Analysis

| If This Fails... | Then... | Impact on Portfolio |
|-------------------|---------|-------------------|
| ZK integration fails | CC falls back to tribe + toll rules (still strong entry) | Low — CC still competitive |
| TradePost fails | CC pivots to Strategy A (solo GateControl) | Medium — weaker ModDesign score |
| Fortune Gate fails (`sui::random`) | Use tx hash pseudo-random fallback | Low — still weird enough |
| Salvage Protocol fails (`unanchor` blocked) | Deploy Dead Drop as Most Creative backup | Low — category still covered |
| Corpse Toll fails (template mismatch) | CC absorbs Most Utility targeting | Low — covered |
| Multiple submissions disallowed | Fortune Gate becomes GateControl weird-rule; only CC submitted | Medium — lose bonus category snipes |

### Worst-Case Floor

Even in the worst failure cascade, we submit CivilizationControl (GateControl alone) with tribe filter + coin toll. This is a validated, working extension module. Weighted score: ~7.5. Competitive for top 5 in Best Entry, competitive for Best Technical Implementation or Most Utility.

**The portfolio never reaches zero.** The validation work already completed ensures a minimum viable submission exists today (structurally — code written after March 11).

---

## 9. Development Cadence Strategy

### Phase 0: Pre-Hackathon (Now → March 10)

**Focus: De-risk everything that isn't code.**

| Action | Timeline | Purpose |
|--------|----------|---------|
| Verify multi-submission rules | Before March 1 | If disallowed, restructure portfolio |
| ZK circuit design (on paper) | Feb 20-25 | Merkle membership proof circuit architecture |
| Demo storyboards (all entries) | Feb 25-March 5 | Pre-plan every demo shot so execution is fast |
| Devnet environment validation | March 1-5 | Ensure Docker + local devnet + build pipeline work |
| Gate lifecycle setup script (conceptual) | March 5-10 | Document exact PTB sequence for full gate setup |
| UI wireframes (all entries) | March 5-10 | Know exactly what to build when code starts |

### Phase 1: Core Sprint (March 11-17, Days 1-7)

| Day | Focus | Gate |
|-----|-------|------|
| 1 | GateControl Move module: tribe filter + coin toll. Full gate lifecycle on devnet. | Gate online + extension authorized by EOD |
| 2 | GateControl: `issue_jump_permit` → `jump_with_permit` integration. ZK circuit compilation begins (parallel). | Working pass/fail scenarios on devnet |
| 3 | TradePost Move module: listing CRUD + atomic buy. ZK: Move Groth16 verification on devnet. | Cross-address atomic buy working |
| 4 | Dashboard shell: structure sidebar + GateControl policy panel + TradePost browse/buy. ZK: gate extension integration. | UI connected to on-chain state |
| 5 | Integration: shared event feed, GateControl + TradePost in same dashboard. ZK kill check. | Full CC demo rehearsal |
| 6 | Demo rehearsal #1. Record test takes. Fix visual issues. | Watchable 3-min draft video |
| 7 | Buffer / TribeMint stretch if demo is solid. | CC demo-stable = proceed to Phase 2 |

**Hard Rule: No Phase 2 until CC produces a watchable 3-minute demo video (draft quality).**

### Phase 2: Sprint Blitz (Days 8-10)

| Day | Project | Hours | Demo |
|-----|---------|-------|------|
| 8 AM | Corpse Toll Road (C3) | 4-6h | Record 60s demo by lunch |
| 8 PM | Fortune Gate (C1) | 4-6h | `sui::random` integration + slot animation |
| 9 | Fortune Gate (finish) + Salvage Protocol (C2 start) | 8-10h | Fortune Gate demo by noon |
| 10 | Salvage Protocol (finish) | 6-8h | Record demo |

### Phase 3: Polish & Submit (Days 11-14)

| Day | Focus |
|-----|-------|
| 11 | Re-record CC demo (final quality). Captions, annotations, B-roll. |
| 12 | Record final demos for all side entries. Player-vote cutdowns (30-60s per entry). |
| 13 | Track D (Loot Crate) if all above are done. Otherwise: polish, README docs, repo cleanup. |
| 14 | Submit all entries via Deepsurge. Cross-check repo hygiene. Verify GitHub visibility. |

### When to Pivot

| Signal | Action |
|--------|--------|
| TradePost cross-address fails on Day 3 | Pivot CC to Strategy A (solo GateControl + ZK). TradePost becomes separate side entry or cut. |
| ZK integration fails on Day 3 | Cut ZK. CC ships with tribe + toll rules. Still competitive. |
| CC not demo-stable by Day 7 | Cancel Phase 2 entirely. All remaining time goes to CC polish and demo. |
| Fortune Gate `sui::random` fails | Fallback to tx hash pseudo-random. Still weird. |
| Salvage Protocol `unanchor` blocked | Deploy Dead Drop as Most Creative backup. |
| Day 10 and only 2 sprints complete | Skip Track D. Submit what's ready. |

### When to Sprint

Sprint mode activates when:
- A module is 80% done and 20% remains is UI polish or demo
- The current track's kill criteria have been passed
- The next track has been pre-designed (wireframe + Move module spec)

### When to Consolidate

Consolidation mode activates when:
- Multiple modules have compile errors simultaneously
- The demo rehearsal reveals narrative incoherence
- Scope creep is pulling attention across >2 workstreams

**In consolidation: freeze scope, fix what's broken, record what works.**

---

## 10. March 11 Execution Strategy

### Hour 0: Environment Verification (30 min)

```bash
# Start devnet
cd vendor/builder-scaffold/docker
docker compose run --rm sui-local

# Inside container
sui client active-env  # → "local"
sui client gas         # → funded accounts
sui move build -e local  # → verify toolchain
```

### Hour 0.5: Publish World Contracts (1-2 hours)

```bash
cd /workspace/world-contracts/contracts/world
sui client publish -e local --gas-budget 500000000 --json
# Capture: Package ID, GovernorCap, AdminACL, ObjectRegistry, etc.
```

Follow GateControl feasibility report §B for full setup chain:
1. Create AdminCap
2. Register server address (self-sign for devnet)
3. Add sponsor to ACL
4. Configure fuel + energy
5. Set gate max distance

### Hour 2: GateControl MVP (4-6 hours)

1. Create GateControl extension package
2. Implement `GateAuth` witness + `PolicyConfig` with dynamic field rules
3. Implement `TribeRule` (tribe_id matching)
4. Implement `CoinTollRule` (`Coin<SUI>` payment → treasury)
5. Test: tribe pass ✓, tribe fail ✗, toll paid ✓, toll insufficient ✗

### Hour 8: TradePost MVP (4-6 hours, parallel start if possible)

1. Create TradePost extension package
2. Implement `TradeAuth` witness + `Listing` dynamic fields
3. Implement `create_listing()`, `buy()` with atomic PTB escrow
4. Test: list ✓, buy ✓, ownership transfer verified

### Hour 14: ZK Integration (parallel workstream)

1. Design Merkle membership circuit (Circom)
2. Compile, generate trusted setup, produce test proof
3. Create `zkgate` wrapper module (resolves naming conflict)
4. Verify Groth16 proof on devnet via Move `sui::groth16`

### Priority Queue

If time runs short, cut in this order (last cut first):
1. ~~LootDrop~~ (stretch, not started yet)
2. ~~TribeMint~~ (stretch, not started yet)  
3. ~~ZK Privacy Rule~~ (differentiator but not core)
4. ~~Time window rule~~ (nice-to-have)
5. **TradePost** — HARD LINE. Do not cut.
6. **GateControl** — ABSOLUTE MINIMUM. Ship this or don't submit.

---

## Appendix A: Primitive Diversity Check

Each entry exercises different Sui capabilities, preventing pattern overlap and demonstrating ecosystem mastery:

| Entry | Primary Sui Primitive | Overlaps? |
|-------|-----------------------|-----------|
| CivilizationControl | Dynamic fields, typed witness, Coin\<T\>, PTB composition, (Groth16) | — |
| Fortune Gate | `sui::random` VRF | No |
| Salvage Protocol | Storage rebate economics, structure lifecycle | No |
| Corpse Toll Road | Typed witness (simpler), item deposit/withdraw | Partial (simpler GateControl) |
| Loot Crate (Track D) | `sui::random` + dynamic field loot tables | Overlaps Fortune Gate on VRF |

**Diversity is high.** Judges seeing all four entries would recognize breadth across the Sui primitive surface.

---

## Appendix B: Demo Director's Notes

### CivilizationControl (3 min)

**Tone:** Confident, understated, authoritative. "We built the missing control plane."

| Segment | Duration | Visual | Audio |
|---------|----------|--------|-------|
| Hook | 0:00-0:10 | Terminal with raw CLI commands | "This is infrastructure management today." |
| Problem | 0:10-0:30 | Discord screenshots, error messages | "Tribe leaders are flying blind." |
| GateControl | 0:30-1:15 | Dashboard → policy panel → tribe filter + toll | "One extension. Composable rules. Configured from a browser." |
| TradePost | 1:15-1:50 | Listings → atomic buy → item transfer | "Trustless commerce at the frontier." |
| ZK moment | 1:50-2:20 | Proof generation → verification → gate opens | "The blockchain never learned who you were." |
| System reveal | 2:20-2:45 | Full dashboard, event feed scrolling | "One system. One dashboard. One control plane." |
| Close | 2:45-3:00 | Logo + "CivilizationControl" + roadmap hint | "This is what the frontier needs." |

**The Moment:** The ZK proof verification → gate opens transition. 5 seconds of "Generating proof..." → "Verified" → access granted. Judges have never seen this in a game context.

### Fortune Gate (60-90 sec)

**Tone:** Playful, dramatic, tongue-in-cheek.

| Segment | Duration | Visual |
|---------|----------|--------|
| Setup | 0:00-0:10 | Character at gate. "Will you pass?" |
| Spin | 0:10-0:25 | Slot-machine animation. Suspense builds. |
| Success (80%) | 0:25-0:35 | Gate opens. "Lucky." |
| Reset + Spin | 0:35-0:50 | New character. Animation. |
| Failure (20%) | 0:50-1:00 | STRANDED. "The gate has spoken." |
| Tag | 1:00-1:10 | "Fortune Gate. Verifiably fair. Dramatically unfair." |

**Record multiple takes to capture both outcomes.** The recorded format makes this trivial.

### Salvage Protocol (60-90 sec)

**Tone:** Cool, intellectual, "look what I found."

| Segment | Duration | Visual |
|---------|----------|--------|
| Setup | 0:00-0:15 | Abandoned structure on dashboard. "Dead weight." |
| Claim | 0:15-0:30 | Click "Claim Salvage" → transaction executes |
| Rebate | 0:30-0:45 | Wallet balance increases. "Sui paid you to clean up." |
| Explain | 0:45-1:05 | Overlay: "Storage rebate = gameplay revenue" |
| Tag | 1:05-1:15 | "Salvage Protocol. The chain recycles itself." |

### Corpse Toll Road (60 sec)

**Tone:** Dark humor, matter-of-fact.

| Segment | Duration | Visual |
|---------|----------|--------|
| Approach | 0:00-0:10 | Character at gate. "Toll required." |
| Deposit | 0:10-0:25 | Deposit corpse → gate opens |
| Denied | 0:25-0:40 | No corpse → "Access denied" |
| Tag | 0:40-0:55 | "Corpse Toll Road. Bring a body or walk." |

---

## Appendix C: Entry Submission Checklist (Per Entry)

For each Deepsurge submission:

- [ ] GitHub repository (public, clean, original work)
- [ ] README with concept description, build instructions, architecture overview
- [ ] Demo video link (YouTube/Vimeo)
- [ ] Website link (if hosted frontend exists)
- [ ] No pre-March 11 code in git history
- [ ] No secrets, keys, or mnemonics in repo
- [ ] No third-party IP violations
- [ ] No security/equity/financial instrument characteristics
- [ ] Stillness deployment (bonus, if applicable — within 14 days post-close)

---

## Appendix D: Decision Log Reference

The portfolio strategy decision is recorded in [docs/decision-log.md](../decision-log.md) under entry **2026-02-16 — Hackathon Portfolio Strategy Finalized**.
