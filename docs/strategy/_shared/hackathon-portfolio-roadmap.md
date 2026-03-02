# Hackathon Portfolio Roadmap — Multi-Entry Submission Strategy

**Retention:** Carry-forward

> **Date:** 2026-02-28 (refreshed; Flappy Frontier + Atomic Courier + Gate Presets added)  
> **Status:** Pre-hackathon planning (code moratorium until March 11)  
> **Inputs:** Strategy memo, V3 judging analysis, feasibility reports, validation results, rules digest, prize category reverse-engineering, fast-sprint analysis, ZK feasibility report, narrative voice guide, emotional objective, UX architecture spec, Figma structural wireframe, atomic courier experiment (validated), in-game DApp surface analysis  
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
| **E — Sprint** | Flappy Frontier | Player Vote weapon + Weirdest backup | 1–2 | High |
| **F — Sprint** | Atomic Courier | Most Utility backup / Most Creative | 1–2 | Medium-High |

**Total entries: 4–6 (flagship + 3–5 sprints), with 1 optional wildcard.**

### Win Thesis (One Sentence)

CivilizationControl wins Best Entry by being the only system-level submission in a field of single-feature mods, while up to five surgical side entries snipe every remaining bonus category — guaranteeing at minimum $10k+ in prizes and maximizing expected value across the entire prize pool.

### Expected Value Analysis

| Scenario | Probability | Prize Value |
|----------|------------|-------------|
| CC wins 1st Best Entry + 3 bonus wins | 10% | $30,000 + tokens |
| CC wins 1st Best Entry + 2 bonus wins | 15% | $25,000 + tokens |
| CC wins 2nd/3rd + 2 bonus wins | 25% | $17,500–$20,000 |
| CC wins 1 bonus + 2–3 side bonus wins | 25% | $15,000–$20,000 |
| 2 bonus wins only (CC misses top 3) | 15% | $10,000 |
| 1 bonus win | 10% | $5,000 |

**Weighted expected value: ~$16,000–$19,000.** Expanded portfolio (Flappy + Courier) improves category coverage and player vote surface. This is a portfolio bet, not a single-entry gamble.

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
    │ • Gate Presets     │   │                  │   │                     │
    │   (enhancement)    │   │                  │   └─────────────────────┘
    │                    │   │                  │
    │ → Best Entry 1st   │   │ → Weirdest       │   ┌─────────────────────┐
    │ → Best Technical   │   │ → Most Creative  │   │  TRACK E + F        │
    │                    │   │ → Most Utility   │   │  Sprint Extensions  │
    └────────────────────┘   └──────────────────┘   │                     │
                                                    │ E: Flappy Frontier  │
    Track B (ZK Spike) → INTEGRATED into Track A    │ F: Atomic Courier   │
      (not standalone — cannibalization risk too     │ → Player Vote       │
       high)                                        │ → Most Utility bkup │
                                                    └─────────────────────┘
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
| ZK | **ZK Privacy Rule** — Groth16-verified gate access (Merkle membership proof) | Core differentiator | +1.5 est. | Green (all validated on local devnet; membership circuit implemented, standalone module published; to re-validate on hackathon test server March 11) |
| S1 | TribeMint — Faction `Coin<TribeToken>` | Stretch | 6.31 | Green |
| S2 | LootDrop — VRF loot crate via `sui::random` | Stretch | 7.53 | Yellow |
| S3 | **Gate Preset Switching** — Manual topology reconfiguration presets (A/B/C) | Enhancement (cuttable) | N/A (CivControl value-add) | Green |

### Why ZK Is Now Core (Not Track B)

The ZK feasibility analysis produced a clear recommendation: **integrate, don't separate.**

| Dimension | As Standalone Entry | As GateControl Rule Type |
|-----------|--------------------|-----------------------|
| Time cost | 22-38 hours (3-4 days) | 18-28 hours (saves wrapper overhead, shared devnet setup) |
| Prize target | Best Technical Implementation only | CivilizationControl targets Best Entry AND Best Technical |
| Demo impact | Separate 60s video | 30s segment inside 3-min flagship demo |
| Cannibalization | Severe — 29-57% of total dev capacity | Zero — built on same gate extension pattern |
| Working demo probability | 45-55% full | 50-60% (shared infrastructure reduces setup risk) |

**Decision: ZK is a GateControl rule type, not Track B.** The existing `eve-frontier-proximity-zk-poc` provides 60-70% of the work. The integration seam (circuit → Move verifier → gate extension) is buildable and the core composition (Groth16 verify + gate witness) has been validated on local devnet (sandbox). ZK is upside, not dependency.

### Differentiator

**No other hackathon entry will have ZK-verified game infrastructure access.** The combination of dynamic field rule composition + cross-address PTB trading + Groth16 verification demonstrates mastery of three distinct Sui primitive families. This is the widest technical footprint of any single entry.

### Remaining Validation (March 11 De-Risking)

> **ZK Note:** All ZK GatePass primitives validated on local devnet (sandbox). Membership circuit (depth 10, Poseidon(2), 2,430 constraints) implemented and on-chain verified. Standalone `zk_gate` module published. See [validation report](../../operations/shortlist-viability-validation-report.md) and [ZK feasibility report](../../operations/zk-gatepass-feasibility-report.md) §2.2. Remaining: world-contracts integration (Character, AdminACL, sponsored tx) — to re-validate on hackathon test server March 11.

> **Upstream reference code (2026-02-20 submodule refresh):** `vendor/builder-scaffold` now contains canonical gate extension reference implementations: `config.move` (ExtensionConfig + AdminCap + XAuth + DF helpers), `tribe_permit.move` (tribe-based access), `corpse_gate_bounty.move` (SSU+gate cross-assembly composition). Full TS script suite + utility library at `ts-scripts/`. Builder-documentation `gate/build.md` now provides end-to-end build guide. `deposit_item()` now merges quantities for same-type items (world-contracts commit 09c2ec2, confirmed at e508451) — simplifies TradePost re-stocking. EVE Vault Quasar sponsorship integration in progress but still stubbed *(Correction 2026-02-28: now functional — see breaking changes below)*. See [builder-docs-map](../../research/evefrontier-builder-docs-map.md) for details.
>
> **Breaking changes (2026-02-28 submodule refresh — world-contracts v0.0.13):** (1) Proximity proof REMOVED from all owner-path SSU functions — replaced by AdminACL `verify_sponsor`. Extension path unaffected. (2) `link_gates` now requires AdminACL param + authorized sponsored tx. (3) SDK migrated: `SuiClient` → `SuiJsonRpcClient` (`@mysten/sui/jsonRpc`). (4) `proof.ts` deleted from builder-scaffold (proximity proof generation removed). (5) New `Coin<EVE>` token (10B supply, 9 decimals) — potential coin toll currency. (6) New gate link/unlink events. (7) EVE Vault default chain switched devnet→testnet, sponsored tx API URL changed. No pattern-breaking changes for CivilizationControl — all validated extension/witness patterns remain intact. See [march-11 checklist](../../core/march-11-reimplementation-checklist.md) for updated deployment sequence.

| Item | Risk | Action | Time |
|------|------|--------|------|
| TradePost cross-address PTB on full world-contracts | Low (already validated) | Re-run validation with published world package | 2 hours |
| GateControl → `issue_jump_permit` → `jump_with_permit` integration | Low (validated) | ✅ Full 13-step gate lifecycle rehearsed on local devnet (2026-02-16). See [runbook](../../operations/gate-lifecycle-runbook.md) and [reimplementation checklist](../../core/march-11-reimplementation-checklist.md). | DONE |
| Sponsored transaction setup (AdminACL) | Low (validated) | ✅ Sponsor setup + sponsored `deposit_fuel` and `jump_with_permit` validated. `verify_sponsor` falls back to `ctx.sender()` when no sponsor is present — non-sponsored tx succeeds if sender is in AdminACL. See [runbook](../../operations/gate-lifecycle-runbook.md) Steps 6b, 13. | DONE |
| ZK circuit → Move Groth16 verification | Low (fully validated) | ✅ Membership circuit implemented & devnet-validated (sandbox) | DONE |
| Lux-to-SUI display conversion | Low (UX only) | Inspect game server behavior if accessible | 1 hour |

### Risk Register

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|------------|
| 1 | **Full gate lifecycle setup too complex** | Low (mitigated) | Medium (mitigated) | ✅ Full 13-step lifecycle rehearsed end-to-end on local devnet (2026-02-16). Reproducible [runbook](../../operations/gate-lifecycle-runbook.md) with 20 successful transactions. Setup is verbose but mechanical — no remaining unknowns. |
| 2 | **ZK integration fails** | Very Low | Low — GateControl still works without ZK | All primitives validated on local devnet (sandbox). Membership circuit implemented. Remaining risk is world-contracts integration only — to re-validate on hackathon test server March 11. |
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
| UX & Usability | 8.5 | Command Overview + policy composer + one-click buy. Figma wireframe and narrative framework complete — high execution confidence |
| Demo | 9 | Story arc: problem → control → commerce → ZK reveal |
| **Judge Average** | **8.81** | |
| Player Vote | 7.5 | TradePost (8) carries; ZK wow adds 0.5 |
| **Weighted Total** | **8.48** | Competitive for 1st place |

---

## 4. Track B — Technical Spike → INTEGRATED

**Decision: Track B does not exist as a separate track.**

The ZK feasibility analysis conclusively shows that ZK GatePass delivers higher expected value as an integrated GateControl rule type than as a standalone entry. See §3 for rationale.

The "Technical Spike" concept is preserved as the ZK Privacy Rule within Track A. If ZK integration hits kill criteria, Track A gracefully degrades to a two-rule-type gate policy engine + TradePost — still the strongest entry in the field.

### Kill Criteria (ZK within Track A)

> **Planned status checkpoint (March 11):** All ZK kill gates passed on local devnet (sandbox). On-chain Groth16 verification, ZK+gate composition, AND membership circuit (depth 10, Poseidon(2), 2,430 constraints) all validated. Standalone `zk_gate` module published on devnet. No remaining kill gates — ZK integration is implementation-ready. To re-validate on hackathon test server.

| Checkpoint | Deadline | Signal | Status |
|-----------|----------|--------|--------|
| Circuit compiles + generates valid proofs | End of Day 1 | If no, ZK is cut | **TO RE-VALIDATE** on hackathon test server (passed on local devnet) |
| Move Groth16 verifier accepts proof on devnet | End of Day 2 | If no after >4 hours debugging, cut | **TO RE-VALIDATE** on hackathon test server (passed on local devnet) |
| Full gate extension integration works | Mid-Day 3 | If no, fall back to CLI demo or cut entirely | **TO RE-VALIDATE** on hackathon test server (passed on local devnet) |

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
| **Concept** | Deploy the existing `corpse_gate_bounty.move` template (now under `smart_gate/`) with a web UI for configuration. Simplest, highest-certainty entry. **Updated 2026-02-20:** builder-scaffold now includes complete TS scripts for the corpse bounty flow (`ts-scripts/smart_gate/collect-corpse-bounty.ts`, `authorise-gate.ts`, `configure-rules.ts`) — further reduces build time. |
| **Sui Primitive** | Typed witness extension (simpler version of GateControl pattern) |
| **Build Time** | 6–8 hours LLM-assisted (lowest of all candidates) |
| **Demo Impact** | 8/10 — "Deposit a corpse. Gate opens. No corpse, no jump." Visceral, immediate, macabre humor. |
| **Meme Potential** | 7/10 — "Corpse toll" is memorable. Works for EVE's audience. |
| **Win Probability** | **50-60% for Most Utility.** It's the most directly useful single-feature mod. Every gate owner can immediately use it. Higher if targeting Best Live Integration (fewer competitors). |

**Kill Criteria:** Abandon if template code doesn't compile against current world-contracts within 2 hours (unlikely — it's the scaffold's own template). **Updated 2026-02-20:** Template confirmed working with pnpm scripts in scaffold. Full TS script suite available.

**Build Plan:**
1. Deploy `corpse_gate_bounty.move` (possibly with minor type_id configuration)
2. Minimal React UI: gate owner sets toll item type, jump attempt view shows success/failure (scaffold `dapps/` React starter with `@evefrontier/dapp-kit` available as base — **Updated 2026-02-20:** dApp starter now includes assembly info queries and wallet status components)
3. Record demo: corpse deposit → gate opens vs. no corpse → denied
4. **Stretch:** Deploy to Stillness (live server) for Best Live Integration targeting (post-submission bonus window)

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

## 6a. Track E — Flappy Frontier (Sprint)

**One-sentence pitch:** *"A Frontier-themed Flappy Bird with on-chain leaderboard and token-gated score submission — the player vote weapon."*

| Dimension | Detail |
|-----------|--------|
| **Target Prize** | Player Vote impact (25% of Best Entry) + Weirdest Idea backup |
| **Concept** | Simple in-game-friendly web game (Flappy Bird style, space-themed). Portrait layout fits in-game webview (787×1198px) and works identically in external browser. Free-play mode for anyone; pay 1 token to submit score to on-chain leaderboard. Weekly payout to top N (e.g., top 3) funded by submission fees. |
| **Sui Primitive** | On-chain leaderboard (dynamic fields or sorted table), `Coin<SUI>` payment, `Clock` for weekly epochs |
| **Build Time** | 10–16 hours LLM-assisted |
| **Demo Impact** | 8/10 — Immediately playable, visually distinct from governance entries. "Play the game, the blockchain keeps score." |
| **Meme Potential** | 9/10 — Shareable gameplay clips. "Flappy Frontier" is instantly memorable. Player vote pull: 9/10. |
| **In-Game Viability** | **Excellent.** Canvas 2D / WebGL supported in CEF webview. Mouse/keyboard input works. Portrait orientation natural for Flappy. DApp URL loadable from SSU. |
| **Win Probability** | Player vote impact: **High** (drives vote share for Best Entry). Standalone prize: **30-40%** for Weirdest backup if Fortune Gate is cut. |

**Wallet constraint:** No Sui wallet in-game (CEF doesn't support extensions). In-game = free-play only. Score submission + leaderboard viewing require external browser with EVE Vault or other Sui wallet. In-game shows "Open in Browser to submit score" CTA.

**Domain:** `flappyfrontier` — discoverability asset. Players can type the URL into any SSU's DApp URL field to load it in-game.

**Deliverables:**
1. Minimal Move package: `Leaderboard` (sorted, top-N stored on-chain), `Treasury` (submit fee collection + weekly payout)
2. Web UI: Canvas 2D game + wallet connect flow + leaderboard display
3. Demo plan: 30–60 seconds — play game → submit score → leaderboard updates → show treasury payout mechanism

**Kill Criteria:** Abandon if Canvas 2D game loop isn't playable within 6 hours. Fallback: static leaderboard-only page (no game, just score submission via CLI → web leaderboard display).

**Build Plan:**
1. Game engine: simple Canvas 2D loop (bird + pipes + score), ~200 LoC (4-6h)
2. Move package: `Leaderboard` + `Treasury` with submit/payout entry functions (3-4h)
3. Wallet integration + submit flow (2-3h)
4. Demo recording (1h)

**Why It Matters:** Player vote is 25% of Best Entry score. A fun, shareable mini-game drives more player votes than any governance dashboard. Flappy Frontier is the trojan horse that boosts CivilizationControl's total score while standing on its own as a complete Sui integration showcase.

---

## 6b. Track F — Atomic Courier (Sprint)

**One-sentence pitch:** *"Trustless delivery contracts — post a job, lock collateral, deliver or get slashed. Economic enforcement on-chain."*

| Dimension | Detail |
|-----------|--------|
| **Target Prize** | Most Utility (backup to C3) / Most Creative (backup to C2) |
| **Concept** | On-chain courier job protocol: creator posts job with SUI reward, courier accepts by locking collateral, completes delivery for reward or misses deadline and gets slashed. Full state machine with events. |
| **Sui Primitive** | `Balance<SUI>` escrow, `Clock` deadlines, shared object coordination, typed receipts |
| **Build Time** | 8–14 hours LLM-assisted (Move code 90% done from experiment) |
| **Demo Impact** | 7/10 — "Post. Accept. Deliver. Settle." Clear economic enforcement. Strongest when showing the slash scenario. |
| **Validated Scope** | **Core protocol 100% validated** on local devnet: post/accept/complete/expire/cancel with escrow + collateral + deadline + slashing. See `experiments/atomic_courier_experiment/FEASIBILITY-REPORT.md`. |
| **Win Probability** | **35-45%** for Most Utility or Most Creative. Novel protocol + proven code + clean demo. |

**What IS proven (local devnet):**
- Reward escrow (`Balance<SUI>`) — held in shared `CourierJob` object
- Collateral lock + slashing on deadline miss
- State machine: Posted → Active → Completed/Expired, Posted → Cancelled
- `JobReceipt` (owned proof of assignment)
- Events for all transitions (5 event types)
- Anyone-can-expire rule (third-party cleanup)
- Gas costs: ~0.005 SUI for full happy path

**What is NOT proven (out of MVP scope):**
- SSU ↔ in-game inventory bridge (game-server coordination)
- Gate jump runtime integration (AdminACL + sponsorship)
- Cross-extension composition in single PTB
- `Coin<EVE>` substitution (tests use SUI)
- Concurrent job handling
- Turret/gate allowlisting hooks

**Position as separate sprint project** — not merged into CivControl. Different domain (logistics vs. governance), different Sui primitives exercised, independent demo arc.

**Deliverables:**
1. Move package: `courier_escrow` (adapt from experiment — cleanup + production hardening)
2. Minimal web UI: post job form + job browser + accept/complete/expire actions + balance display
3. Demo plan: 60–90 seconds — post job → accept with collateral → complete delivery → settlement. Second scenario: deadline miss → collateral slashed.

**Kill Criteria:** Abandon if world-contracts integration for SSU triggers blocks clean escrow flow within 4 hours. Fallback: pure economic demo (no SSU item custody — just SUI escrow + deadline enforcement).

**Non-Goals (scope guardrails):**
- No SSU item custody simulation (economic enforcement only)
- No gate/turret integration (future enhancement, not MVP)
- No sponsored transactions (courier operations are direct-sign)
- No in-game functionality (external browser only for courier dApp)

---

## 7. Prize Category Mapping Matrix

| Prize | Primary Entry | Backup Entry | Competition Level | Our Strength | Win % |
|-------|--------------|-------------|-------------------|--------------|-------|
| **Best Entry 1st** | CivilizationControl | — | High (all entries eligible) | System-level design, ZK differentiator, strong demo | 15-20% |
| **Best Entry 2nd** | CivilizationControl | — | High | Same + player vote from Flappy Frontier | 20-25% |
| **Best Entry 3rd** | CivilizationControl | — | High | Same | 25-30% |
| **Best Technical** | CivilizationControl (ZK rule) | Loot Crate (Track D) | Medium (15-25 entries) | Groth16 + dynamic fields + PTB composition | 30-40% |
| **Most Utility** | Corpse Toll Road (C3) | Atomic Courier (Track F) | Medium (15-25 entries) | Working code, immediate player value | 40-50% |
| **Most Creative** | Salvage Protocol (C2) | Atomic Courier (Track F) | Low-Medium (10-15 entries) | Novel mechanism nobody else will attempt | 50-60% |
| **Weirdest Idea** | Fortune Gate (C1) | Flappy Frontier (Track E) | Low (5-10 entries) | Maximum commitment to the bit | 65-75% |
| **Best Live Integration** | Corpse Toll Road (C3 stretch) | Flappy Frontier (Track E) | Very Low (<5 entries) | Scaffold infrastructure + devnet experience | 40-60% (if Stillness accessible) |

### Prize Coverage

In the best case, we can win **5 prizes simultaneously** (Best Entry + Weirdest + Most Creative + Most Utility + Best Live Integration) because each is a separate entry.

In the worst case, we win **1 prize** (Weirdest Idea via Fortune Gate) — which is still $5,000 + $1,000 SUI for a half-day of work.

**The portfolio strategy ensures nonzero prize capture.** This is the key insight: a single flagship that misses the top 3 wins nothing. A portfolio that includes Fortune Gate wins *something* almost certainly. Adding Flappy Frontier improves player vote coverage for Best Entry (25% of score) and provides a Weirdest backup. Atomic Courier deepens Most Utility/Most Creative backup coverage with validated code.

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
| E (Flappy Frontier) | Low (Canvas 2D + simple Move) | Low (one game + one package) | Low (1-2 days) | Very Low (gameplay is inherently demo-ready) |
| F (Atomic Courier) | Very Low (Move code validated) | Low (economic-only MVP) | Low (1-2 days, Move 90% done) | Medium (economic, not visual) |

### Failure Cascade Analysis

| If This Fails... | Then... | Impact on Portfolio |
|-------------------|---------|-------------------|
| ZK integration fails | CC falls back to tribe + toll rules (still strong entry) | Low — CC still competitive |
| Gate Preset Switching fails | CC drops enhancement; core GateControl + TradePost unaffected | Very Low — optional accent |
| TradePost fails | CC pivots to Strategy A (solo GateControl) | Medium — weaker ModDesign score |
| Fortune Gate fails (`sui::random`) | Use tx hash pseudo-random fallback; or swap Flappy Frontier into Weirdest slot | Low — still weird enough |
| Salvage Protocol fails (`unanchor` blocked) | Deploy Atomic Courier or Dead Drop as Most Creative backup | Low — category still covered |
| Corpse Toll fails (template mismatch) | Atomic Courier absorbs Most Utility targeting | Low — covered |
| Flappy Frontier fails (Canvas issues) | Drop to static leaderboard; player vote still viable via other entries | Low — nice-to-have |
| Atomic Courier fails (world-contracts integration) | Pure economic demo (no SSU); or cut entirely | Very Low — backup entry |
| Multiple submissions disallowed | Fortune Gate becomes GateControl weird-rule; only CC submitted | Medium — lose bonus category snipes |

### Worst-Case Floor

Even in the worst failure cascade, we submit CivilizationControl (GateControl alone) with tribe filter + coin toll. This is a validated, working extension module. Weighted score: ~7.5. Competitive for top 5 in Best Entry, competitive for Best Technical Implementation or Most Utility.

**The portfolio never reaches zero.** The validation work already completed ensures a minimum viable submission exists today (structurally — code written after March 11). The Atomic Courier experiment provides an additional validated fallback: if all Track C entries fail, the courier economic protocol can be submitted as a standalone entry with proven code.

---

## 9. Development Cadence Strategy

### Phase 0: Pre-Hackathon (Now → March 10)

**Focus: De-risk everything that isn't code.**

| Action | Timeline | Status | Purpose |
|--------|----------|--------|---------|  
| ZK circuit design | Feb 20-25 | 🔲 TO RE-VALIDATE (March 11) | Membership circuit (depth 10, Poseidon(2), 2,430 constraints) implemented and validated on local devnet (sandbox); to re-validate on hackathon test server |
| Gate lifecycle rehearsal | Feb 15-16 | ✅ DONE (2026-02-16) | Full 13-step lifecycle, 20 txs, reproducible [runbook](../../operations/gate-lifecycle-runbook.md) |
| Narrative layer formalization | Feb 17 | ✅ DONE (2026-02-17) | [Voice & narrative guide](../civilization-control/civilizationcontrol-voice-and-narrative.md) + [emotional objective](../civilization-control/civilizationcontrol-hackathon-emotional-objective.md) + Narrative Impact Check |
| UX architecture specification | Feb 16-17 | ✅ DONE (2026-02-17) | Screen hierarchy, interaction flows, data models, [Figma-ready brief](../../ux/civilizationcontrol-ux-architecture-spec.md) |
| UX wireframes (CC flagship) | Feb 17 | ✅ DONE (2026-02-17) | Figma multi-screen structural wireframe (Command Nexus layout — structural only, no implementation) |
| Verify multi-submission rules | Before March 1 | Pending | If disallowed, restructure portfolio |
| Pre-hackathon unknowns de-risking | Feb 17-March 5 | In Progress | Character resolution, wallet adapter, RPC discovery — see §10 |
| Demo storyboards (all entries) | Feb 25-March 5 | Pending | Pre-plan every demo shot so execution is fast |
| Devnet environment validation | March 1-5 | Partial | Docker + local devnet confirmed; hackathon test server available from March 11 (primary build target); Stillness (live server) deferred to post-submission |
| UI wireframes (Track C entries) | March 1-10 | Pending | Simple layouts for Fortune Gate, Salvage Protocol, Corpse Toll Road |

### Phase 1: Core Sprint (March 11-17, Days 1-7)

| Day | Focus | Gate |
|-----|-------|------|
| 1 | GateControl Move module: tribe filter + coin toll. Full gate lifecycle on hackathon test server. | Gate online + extension authorized by EOD |
| 2 | GateControl: `issue_jump_permit` → `jump_with_permit` integration. ZK circuit compilation begins (parallel). | Working pass/fail scenarios on test server |
| 3 | TradePost Move module: listing CRUD + atomic buy. ZK: Move Groth16 verification on test server. | Cross-address atomic buy working |
| 4 | Command Overview shell: structure sidebar + GateControl policy panel + TradePost browse/buy. ZK: gate extension integration. | UI connected to on-chain state (test server) |
| 5 | Integration: shared Signal Feed, GateControl + TradePost in same control surface. ZK kill check. | Full CC demo rehearsal |
| 6 | Demo rehearsal #1. Record test takes. Fix visual issues. | Watchable 3-min draft video |
| 7 | Buffer / TribeMint stretch if demo is solid. | CC demo-stable = proceed to Phase 2 |

**Hard Rule: No Phase 2 until CC produces a watchable 3-minute demo video (draft quality).**

### Phase 2: Sprint Blitz (Days 8-12)

| Day | Project | Hours | Demo |
|-----|---------|-------|------|
| 8 AM | Corpse Toll Road (C3) | 4-6h | Record 60s demo by lunch |
| 8 PM | Fortune Gate (C1) | 4-6h | `sui::random` integration + slot animation |
| 9 | Fortune Gate (finish) + Salvage Protocol (C2 start) | 8-10h | Fortune Gate demo by noon |
| 10 | Salvage Protocol (finish) + Flappy Frontier (E start) | 8-10h | Salvage demo recorded |
| 11 | Flappy Frontier (finish game + Move package) | 8-10h | Game playable + leaderboard on devnet |
| 12 | Atomic Courier (F) — adapt experiment code + minimal UI | 8-10h | Courier demo recorded |

**Priority order if time runs short:** C3 → C1 → E → C2 → F → D. Flappy Frontier is prioritized over Salvage because player vote impact (25% of Best Entry) outweighs Most Creative category coverage.

### Phase 3: Polish & Submit (Days 13-14)

| Day | Focus |
|-----|-------|
| 13 | Re-record CC demo (final quality). Captions, annotations, B-roll. Record final demos for all side entries. Player-vote cutdowns (30-60s per entry). |
| 14 | Track D (Loot Crate) if all above are done. Otherwise: polish, README docs, repo cleanup. Submit all entries via Deepsurge. Cross-check repo hygiene. Verify GitHub visibility. |
| 14+ | **Post-submission:** Deploy to Stillness (live server) within 14 days for deployment bonus + player vote cultivation. |

### When to Pivot

| Signal | Action |
|--------|--------|
| TradePost cross-address fails on Day 3 | Pivot CC to Strategy A (solo GateControl + ZK). TradePost becomes separate side entry or cut. |
| ZK integration fails on Day 3 | Cut ZK. CC ships with tribe + toll rules. Still competitive. |
| CC not demo-stable by Day 7 | Cancel Phase 2 entirely. All remaining time goes to CC polish and demo. |
| Test server unavailable | Fall back to local devnet for build/test. Evidence quality equivalent; demo uses devnet digests. |
| Fortune Gate `sui::random` fails | Fallback to tx hash pseudo-random. Or swap Flappy Frontier into Weirdest slot. |
| Salvage Protocol `unanchor` blocked | Deploy Atomic Courier or Dead Drop as Most Creative backup. |
| Day 10 and only 2 sprints complete | Skip Tracks D, E, F. Submit what's ready. |
| Flappy game too slow in CEF | Strip to external-browser-only. Still works as player vote driver. |
| Atomic Courier world-contracts integration fails | Pure economic demo (SUI escrow only, no SSU). |

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

## 10. Pre-Hackathon Unknowns (As of 2026-02-17)

Targeted scan of remaining uncertainties that could affect Day 1 execution. Each unknown was researched against vendor source code and existing validation evidence. Only legitimate unknowns are listed — resolved items are omitted.

### 10.1 Character Resolution Flow — CRITICAL

**Problem:** Character is a shared object. There is no on-chain wallet→Character mapping. `suix_getOwnedObjects` on the wallet address does NOT return the Character. The entire structure discovery chain depends on knowing the Character ID first.

**Resolution options:**
1. **Event indexing** — query `CharacterCreatedEvent` (emits `character_address`) to build wallet→Character mapping. Requires historical event access on the target RPC.
2. **Deterministic ID computation** — `derived_object::claim(registry_id, character_key)`. Requires knowing ObjectRegistry UID + game_character_id + tenant string — may not be publicly documented.
3. **Game server API** — rely on CCP's server to provide the mapping. Availability uncertain.
4. **Manual fallback** — user pastes their Character ID. Functional but poor UX.

**MVP mitigation:** Manual Character ID input is already designed into the [UX architecture spec](../../ux/civilizationcontrol-ux-architecture-spec.md) §10b as the Day 1 path. Automatic resolution is an upgrade trigger (§12, Trigger 1).

**Pre-hackathon action:** On the hackathon test server (from March 11), attempt to query `CharacterCreatedEvent` events to verify event indexing viability. Investigate ObjectRegistry discoverability. *(Previously scoped to Stillness; test server provides equivalent RPC capabilities with lower competitive visibility risk.)*

### 10.2 EVE Vault Wallet Adapter Integration — LOW

**Finding:** EVE Vault implements the standard `@mysten/wallet-standard` interface (`sui:signTransaction`, `sui:signAndExecuteTransaction`, `sui:signPersonalMessage`). It registers via `registerWallet()` and is discoverable through `@mysten/dapp-kit`'s `WalletProvider`. Standard PTB signing from a browser is supported.

**Known constraints:**
- EVE Vault uses **zkLogin** addresses (Enoki-derived), not traditional keypairs. MaxEpoch expiry requires manual re-login during session — potential mid-demo interruption.
- Sponsored transaction signing through the zkLogin adapter is untested (standard Sui sponsorship involves `GasData` modification — unclear if this composes cleanly with zkLogin flow).

**Pre-hackathon action:** Build a minimal dApp that connects EVE Vault and signs a simple PTB. Test sponsored tx signing through EVE Vault specifically. Budget: 2-4 hours.

### 10.3 Sponsored Transaction — AdminACL Dependency — MEDIUM

**Finding:** `add_sponsor_to_acl()` requires `GovernorCap` — only the package deployer (CCP) can add sponsor addresses. A builder extension **cannot** register its own sponsor. There is no `remove_sponsor_from_acl` function.

**Impact on MVP:** Most CivilizationControl operations (online/offline, authorize extension, deploy policy, unlink gates, create listings) do NOT require sponsorship. Only jump and fuel deposit/withdraw require `verify_sponsor()`. On the hackathon test server, GovernorCap access may differ from Stillness — clarify with organizers.

**Mitigation:** Design the MVP around OwnerCap-only operations. Defer sponsored operations (jump demo, fuel deposit) to stretch or use local devnet / hackathon test server where GovernorCap may be available. The demo can show gate policy enforcement without requiring a live sponsored jump.

**Pre-hackathon action:** Clarify with CCP/hackathon organizers whether builder sponsor addresses can be registered in AdminACL during the hackathon.

### 10.4 RPC Object Discovery on Live Network — MEDIUM

**Finding:** The 4-step discovery chain (Character → OwnerCaps → authorized_object_id → structure data) is validated on local devnet. Steps 2-4 use standard `suix_getOwnedObjects` and `sui_getObject` — architecturally sound. Step 1 depends on Character resolution (§10.1).

**Unknowns:**
- `suix_getOwnedObjects` on a Character *object address* (transfer-to-object children) may behave differently on the hackathon test server than on local devnet.
- EVE Frontier may operate custom RPC middleware that filters non-game-client queries.
- Pagination behavior for Characters with many OwnerCaps is untested.

**Pre-hackathon action:** Once a Character ID is known on the hackathon test server (from March 11), run `suix_getOwnedObjects` on the Character's address to verify OwnerCap retrieval works.

### 10.5 Active Network Visualization — LOW (SCOPED)

**Finding:** Raw structure coordinates are NOT on-chain — only a 32-byte Poseidon2 hash (irreversible). A coordinate-based map is impossible from chain data alone.

**What IS available on-chain:** Gate link partners (`linked_gate_id`), NWN connected assemblies (`connected_assembly_ids`), online/offline status, fuel levels. These are sufficient for an abstract topology graph.

**Decision:** List-first control plane is confirmed as the correct approach. The "Active Network" visualization in CivilizationControl shows network topology (which structures are linked and their status), not spatial coordinates. This is already reflected in the UX architecture spec.

> **Update 2026-02-19:** Spatial layer architecture resolved. Hybrid model adopted: **Strategic Network Map** (CivControl-native SVG, ~150–200 LoC, ~2–3h build budget) renders governance topology from manual pins + on-chain state. **Cosmic Context Map** (EF-Map embed, ~10 LoC) provides universe grounding. SVG representation approach deferred to build phase. See [Spatial Embed Requirements](../../architecture/spatial-embed-requirements.md).

### Risk Summary

| Unknown | Risk | Blocks MVP? | Pre-Hackathon Action Required? |
|---------|------|-------------|-------------------------------|
| Character resolution | Critical | Yes (degraded with manual fallback) | Yes — event indexing test on hackathon test server (March 11+) |
| EVE Vault adapter | Low | Yes if broken | Yes — minimal PTB signing test |
| AdminACL sponsorship | Medium | No (MVP is OwnerCap-only) | Nice-to-have — clarify with organizers |
| RPC on live network | Medium | Partially (Step 1 dependent) | Yes — test with known Character on test server |
| Network visualization | Low | No | No — scoped to list-first + topology |

---

## 11. Pre-Hackathon Focus Plan (Next 20 Days: Feb 17 → March 9)

**Principle:** No hackathon code. No premature polish. Architecture stabilization, integration de-risking, demo narrative planning, and secondary project triage.

### Week 1 (Feb 17-23): Architecture Stabilization

| Day | Focus | Deliverable |
|-----|-------|-------------|
| 1-2 | **Character resolution research** — prepare event indexing queries for hackathon test server (available March 11); investigate ObjectRegistry discoverability against local devnet; document findings | Decision: which resolution path to implement on March 11 |
| 3 | **EVE Vault adapter test** — minimal @mysten/dapp-kit app, connect EVE Vault, sign a simple PTB | Pass/fail confirmation; document any friction |
| 4-5 | **RPC discovery validation** — with a known Character ID on local devnet, test full OwnerCap → structure discovery chain (confirm on test server from March 11) | Confirmed working or documented workaround |

### Week 2 (Feb 24-March 2): Integration De-Risking

| Day | Focus | Deliverable |
|-----|-------|-------------|
| 1-2 | **Sponsored tx through EVE Vault** — test GasData modification with zkLogin adapter; document MaxEpoch handling | Risk assessment: sponsored tx in demo feasible or not |
| 3 | **Multi-submission rule verification** — confirm with organizers that multiple entries from one team are allowed | Go/no-go for Track C portfolio strategy |
| 4-5 | **Demo storyboard drafting** — script all 4 entry demos per [voice guide](../civilization-control/civilizationcontrol-voice-and-narrative.md); apply Narrative Impact Check to each segment | Draft storyboards for CC, Fortune Gate, Salvage Protocol, Corpse Toll Road |

### Week 3 (March 3-9): Demo Narrative & Track C Triage

| Day | Focus | Deliverable |
|-----|-------|-------------|
| 1-2 | **CC demo storyboard finalization** — frame each segment through Active Network consequence lens; identify exact pre-deploy state needed; list every PTB in demo order | Production-ready demo script |
| 3 | **Track C viability triage** — re-evaluate Fortune Gate (`sui::random` calling convention), Salvage Protocol (`unanchor` access control), Corpse Toll Road (template freshness) against current world-contracts | Go/no-go per Track C candidate |
| 4-5 | **March 11 Day-1 prep** — Docker + devnet environment validation; hackathon test server connection details; pre-stage world-contracts publish scripts (local devnet only); character/gate/SSU setup sequence documented; dependency install list finalized | March 11 ready: test server connects, local devnet boots, first PTB succeeds within 30 minutes |

### Guardrails

- **No code that ships.** Research scripts, validation tests, and documentation only. All sandbox artifacts go in `sandbox/validation/` or `notes/`.
- **No scope creep.** TribeMint, LootDrop, and ZK world-contracts integration are March 11+ tasks. Do not start them.
- **No premature UI implementation.** Figma wireframes are structural — do not convert to React components until the hackathon starts.
- **Decision checkpoints.** If Character resolution or EVE Vault adapter tests fail, update the risk register and adjust the March 11 execution strategy before proceeding. Do not paper over blocking unknowns.
- **Track C decisions by March 5.** If multi-submission is disallowed, restructure immediately — do not defer.

### Exit Criteria (March 9)

By the end of pre-hackathon prep, the following must be true:

- [ ] Character resolution path decided (event indexing, deterministic ID, manual, or hybrid)
- [ ] EVE Vault PTB signing confirmed working (or fallback identified)
- [ ] RPC object discovery tested on hackathon test server (Stillness deferred to post-submission)
- [ ] Multi-submission rules confirmed (or portfolio restructured)
- [ ] All demo storyboards drafted with narrative voice applied
- [ ] Docker + local devnet environment boots cleanly in <5 minutes
- [ ] Hackathon test server connection details documented (RPC URL, faucet, admin tools)
- [ ] March 11 Day-1 checklist updated with corrections from pre-hackathon validation

---

## 12. March 11 Execution Strategy

### Hour 0: Environment Verification (30 min)

**Primary target: Hackathon Test Server** (available from March 11). Local devnet is a fallback for rapid iteration if test server is unavailable.

```bash
# Option A: Connect to hackathon test server (primary)
sui client new-env --alias testserver --rpc <TEST_SERVER_RPC_URL>
sui client switch --env testserver
sui client active-env  # → "testserver"
sui client gas         # → funded accounts (unlimited currency on test server)

# Option B: Local devnet fallback
cd vendor/builder-scaffold/docker
docker compose run --rm sui-local
sui client active-env  # → "local"
sui client gas         # → funded accounts
```

**Note:** On the hackathon test server, world-contracts are pre-published and structures can be admin-spawned. On local devnet, you must publish world-contracts yourself.

### Hour 0.5: Publish World Contracts (1-2 hours, local devnet only)

On the hackathon test server, world-contracts are already published — skip to GateControl. On local devnet:

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
| CivilizationControl | Dynamic fields, typed witness, Coin\<T\>, PTB composition, (Groth16), gate link/unlink (presets) | — |
| Fortune Gate | `sui::random` VRF | No |
| Salvage Protocol | Storage rebate economics, structure lifecycle | No |
| Corpse Toll Road | Typed witness (simpler), item deposit/withdraw | Partial (simpler GateControl) |
| Loot Crate (Track D) | `sui::random` + dynamic field loot tables | Overlaps Fortune Gate on VRF |
| Flappy Frontier (Track E) | On-chain leaderboard (dynamic fields), `Coin<SUI>` fee, `Clock` epochs | Minimal (different domain) |
| Atomic Courier (Track F) | `Balance<SUI>` escrow, `Clock` deadlines, shared objects, typed receipts | No (logistics vs. governance) |

**Diversity is high.** Judges seeing all four entries would recognize breadth across the Sui primitive surface.

---

## Appendix B: Demo Director's Notes

### CivilizationControl (3 min)

**Tone:** Confident, understated, authoritative. "We built the missing command layer." Narrative voice per [Voice & Narrative Guide](../civilization-control/civilizationcontrol-voice-and-narrative.md). The operator governs — every structure, policy, and revenue stream is a consequence of their decisions.

**Framing: Active Network as Consequence Layer.** The demo shows the operator's network of structures producing real outcomes: jumps governed, tolls collected, trades settled, revenue earned. Every screen moment reinforces: this infrastructure is under the operator's authority and generating value. See [emotional objective](../civilization-control/civilizationcontrol-hackathon-emotional-objective.md) §3.

| Segment | Duration | Visual | Audio |
|---------|----------|--------|-------|
| Hook | 0:00-0:10 | Terminal with raw CLI commands | "This is infrastructure management today." |
| Problem | 0:10-0:30 | Discord screenshots, error messages | "Tribe leaders are flying blind." |
| GateControl | 0:30-1:15 | Command Overview → gate detail → policy composer → tribe filter + toll deployed | "One extension. Composable rules. Configured from a browser." |
| TradePost | 1:15-1:50 | Storefront listings → atomic buy → revenue counter updates | "Trustless commerce at the frontier. Revenue flows back to you." |
| ZK moment | 1:50-2:20 | Proof generation → verification → gate opens | "The blockchain never learned who you were." |
| System reveal | 2:20-2:45 | Full Command Overview — structures online, Signal Feed scrolling, toll + trade revenue accumulating | "Your infrastructure. Your policies. Your revenue. One command layer." |
| Close | 2:45-3:00 | Logo + "CivilizationControl" | "The command layer the frontier needs." |

**The Moment:** The ZK proof verification → gate opens transition. 5 seconds of "Generating proof..." → "Verified" → access granted. Judges have never seen this in a game context.

**Revenue/Yield emphasis:** Revenue counters should be visible in at least two segments (TradePost buy and System reveal). The operator sees their infrastructure producing economic value in real time — this is the emotional anchor that separates CivilizationControl from a configuration tool.

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

### Flappy Frontier (60 sec)

**Tone:** Fun, accessible, "blockchain? what blockchain?"

| Segment | Duration | Visual |
|---------|----------|--------|
| Gameplay | 0:00-0:20 | Play the game — frontier-themed pipes, space background. Score climbing. |
| Submit | 0:20-0:35 | "Submit Score" → wallet signs → leaderboard updates on-chain |
| Leaderboard | 0:35-0:45 | Top 3 displayed. "Weekly payout from the treasury." |
| Tag | 0:45-0:55 | "Flappy Frontier. Play. Compete. Earn. On-chain." |

### Atomic Courier (60-90 sec)

**Tone:** Precise, economic, proof-of-enforcement.

| Segment | Duration | Visual |
|---------|----------|--------|
| Post Job | 0:00-0:15 | Creator posts job: 0.1 SUI reward, 0.08 SUI collateral required, 60s deadline |
| Accept | 0:15-0:30 | Courier accepts → collateral locked → JobReceipt issued |
| Deliver | 0:30-0:45 | Complete delivery → reward paid → collateral returned |
| Slash | 0:45-1:05 | Second scenario: deadline expires → collateral slashed to creator |
| Tag | 1:05-1:15 | "Atomic Courier. Deliver or pay the price. On-chain enforcement." |

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
- [ ] Stillness deployment (bonus — within 14 days post-submission close; primary build uses hackathon test server)

---

## Appendix D: Decision Log Reference

The portfolio strategy decision is recorded in [docs/decision-log.md](../../decision-log.md) under entry **2026-02-16 — Hackathon Portfolio Strategy Finalized**.
