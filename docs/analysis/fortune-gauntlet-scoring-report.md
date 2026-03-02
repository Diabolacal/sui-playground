# Fortune Gauntlet — Combined Concept Scoring Report

**Retention:** Prep-only

> **Date:** 2026-03-02  
> **Inputs:** hackathon-ideas-grounded-v3-judged.md (8-criterion rubric), wildcard-sprint-analysis.md (Gauntlet scores), hackathon-event-rules-digest.md (prize categories), fortune-gauntlet-feasibility.md (technical validation)  
> **Method:** Rubric-aligned scoring with comparative analysis against standalone variants

---

## 1. Concept Description

**Fortune Gauntlet** = Fortune Gate (VRF probabilistic permit issuance) + The Gauntlet (sequential multi-gate checkpoint race).

- 3–5 checkpoint gates linked in sequence
- At each checkpoint: `entry fun try_issue_permit` rolls `sui::random` VRF
- ~90% success / ~10% denial rate per checkpoint (configurable per gate via DF)
- Denial → DF-based cooldown (escalating with denial count) + `CheckpointDeniedEvent`
- Success → `issue_jump_permit` issued + `CheckpointPassedEvent`
- On-chain timestamps (`Clock`) serve as verifiable referee
- Per-player progress tracked via `PlayerProgress` dynamic field on `ExtensionConfig`
- Global race window (`RaceConfig`) enforces start/end times
- Single Move package, ~200–300 LoC, using standard builder-scaffold extension pattern
- Targets sprint/stretch track (bonus prize, not flagship)

---

## 2. Internal 8-Criterion Rubric Scoring

| # | Criterion | Score | Reasoning |
|---|-----------|:-----:|-----------|
| 1 | **Concept & Feasibility** | **7** | Coherent concept — gate race with danger/randomness. Feasibility fully validated (see feasibility doc). Not solving a "felt pain point" but creating a novel competitive mechanic. Prototype confidence: high. |
| 2 | **Mod Design** | **7** | Clean single-package architecture. Per-gate DF config makes checkpoints reusable/reconfigurable. Standard ExtensionConfig/AdminCap/XAuth pattern. Narrower than GateControl (single-purpose: races) but well-composed internally. |
| 3 | **Concept Implementation** | **7** | All components validated: `entry` function for `sui::random`, DF-based player state, `Clock` time mechanics, custom events. 200–300 LoC is achievable in 1–2 days. `jump_with_permit` sponsor dependency is shared by all gate extensions — not specific to this concept. |
| 4 | **Player Utility** | **5** | Creates an entertainment/competition experience, not an operational tool. Players race for fun and bragging rights, but this doesn't change how they survive, trade, or coordinate. Niche utility within the broader Frontier context. |
| 5 | **Frontier Relevance & Vibe** | **6** | Uses real gate infrastructure, connects to EVE's "dangerous space" ethos. Randomness-as-danger echoes jump uncertainty. However, a gate race feels more like a minigame overlaid on Frontier rather than an emergent extension of its core economic/territorial loops. Not born from playing EVE Frontier — born from gamifying its infrastructure. |
| 6 | **Creativity & Originality** | **7** | Novel intersection: `sui::random` VRF + gate traversal + on-chain referee. Nobody else will build probabilistic checkpoint racing. "The chain is the referee" is a clean "why blockchain?" answer. Not as paradigm-shifting as JumpPermit tradability or Sui storage-rebate-as-salvage, but solidly original. |
| 7 | **UX & Usability** | **6** | Race concept is universally understood ("get through all checkpoints before time runs out"). However, actual UX involves wallet signing at each checkpoint, `jump_with_permit` requires sponsored tx with dual-sign, and no in-game browser integration for Sui wallet. Spectator experience (watching events) could be good with an indexer UI. |
| 8 | **Visual Presentation & Demo** | **8** | Strongest dimension. A race is inherently dramatic: timer ticking, random rolls, success/denial tension, escalating cooldowns, final checkpoint triumph. Demo narrative writes itself: "attempt → denied → cooldown → retry → success → next checkpoint → race complete!" On-chain events provide verifiable proof. The 2–3 minute video format is ideal for this kind of sequential drama. |

### Player Vote

| Score | Reasoning |
|:-----:|-----------|
| **7** | A VRF-powered gate race is visually engaging and immediately comprehensible. "Random chance × speed run × blockchain proof" is shareable. Clip-worthy denial moments + triumphant completions. Not as universally viral as Flappy Frontier (PVote 9) but significantly better than infrastructure tools (PVote 3–5). |

### Composite Calculation

```
Judge Average = mean(7, 7, 7, 5, 6, 7, 6, 8) = 53 / 8 = 6.625

Weighted Total = (6.625 × 0.75) + (7 × 0.25)
               = 4.969 + 1.750
               = 6.72
```

**Fortune Gauntlet Weighted Score: 6.72**

---

## 3. FAQ 4-Area Scoring

The Deep Surge FAQ summarizes judging as four areas (condensed view of the 8-criterion framework):

| Area | Score | Reasoning |
|------|:-----:|-----------|
| **Utility** | **5** | Creates a competitive entertainment mechanic — non-trivial (real on-chain state, verifiable outcomes) but niche. Does not materially change how players survive, coordinate, or trade. |
| **Technical Implementation** | **8** | Showcases `sui::random` VRF (marquee Sui primitive), DF-based per-player state management, `Clock` time mechanics, custom events, standard extension pattern. Clean architecture with clear separation of config/logic/events. The `entry` function constraint is handled elegantly. |
| **Creativity** | **8** | Nobody has built a probabilistic checkpoint race on any blockchain. On-chain timestamps as a self-enforcing referee is an elegant "why blockchain?" story. The intersection of VRF + gate infrastructure + competitive racing is genuinely novel. |
| **Frontier Integration** | **6** | Uses real Gate assemblies, JumpPermit system, and extension hooks. Connects to the world-contracts hook surface. However, this is a game-within-a-game rather than extending Frontier's core economic/territorial loop. A race through gates is fun but doesn't deepen alliance dynamics, trade, or territorial control. |

**FAQ Composite: 6.75** (simple average)

---

## 4. Comparative Analysis

### Fortune Gauntlet vs Standalone Fortune Gate (ID 26)

| Criterion | Fortune Gate | Fortune Gauntlet | Delta |
|-----------|:-----------:|:----------------:|:-----:|
| Concept | 6 | **7** | +1 |
| Mod Design | 6 | **7** | +1 |
| Implementation | 5 | **7** | +2 |
| Player Utility | 4 | **5** | +1 |
| Frontier Vibe | 5 | **6** | +1 |
| Creativity | 6 | **7** | +1 |
| UX | 6 | **6** | 0 |
| Demo | 6 | **8** | +2 |
| Player Vote | 5 | **7** | +2 |
| **Weighted** | **5.38** | **6.72** | **+1.34** |

**Strengths (+) vs Fortune Gate:**
- (+) Sequential progression transforms a single random gate into a structured competition with narrative arc
- (+) Per-player DF state tracking adds genuine Mod Design depth (configurable, reusable)
- (+) Dramatically stronger demo — a race has pacing, tension, and resolution; a single random gate is "flip a coin"
- (+) Higher player vote appeal — competition + spectator experience vs. novelty gimmick
- (+) Feasibility validated in depth (Fortune Gate was scored Yellow with less analysis)

**Weaknesses (-) vs Fortune Gate:**
- (-) Higher complexity — more LoC, more DFs, more admin setup
- (-) Still shares Fortune Gate's core weakness: narrow player utility
- (-) `entry` function constraint adds a technical nuance that must be explained

### Fortune Gauntlet vs Standalone Gauntlet (Wildcard Concept 6)

The wildcard used a different 5-axis rubric. Converting:

| Wildcard Axis | Gauntlet Score | Fortune Gauntlet Equivalent | Delta |
|---------------|:-:|:-:|:-:|
| Tech Impressive | 7 | 8 (adds `sui::random` VRF) | +1 |
| Feasibility | 7 | 7 (adds `entry` constraint complexity) | 0 |
| Uniqueness | 8 | 8 (VRF adds novelty but doesn't fundamentally change uniqueness) | 0 |
| Judge Alignment | 8 | 7 (randomness may feel "gambling-adjacent" to some judges) | -1 |
| Demo Clarity | 9 | 9 (denial/retry adds drama; race remains the core show) | 0 |
| **Composite** | **7.8** | **~7.8** | **~0** |

**Strengths (+) vs Standalone Gauntlet:**
- (+) `sui::random` VRF is a marquee Sui primitive — demonstrates a capability most entries won't use
- (+) Probabilistic denial adds tension and replayability — the race outcome isn't purely deterministic
- (+) Cooldown escalation creates strategic depth (risk management per checkpoint)
- (+) Stronger "Weirdest Idea" positioning — randomness makes it more meme-worthy
- (+) "On-chain slot machine meets obstacle course" is a stickier pitch than "on-chain race"

**Weaknesses (-) vs Standalone Gauntlet:**
- (-) Randomness may alienate judges who see it as "gambling" rather than "game design"
- (-) `entry` function constraint prevents PTB composability for the permit issuance step
- (-) Higher complexity for marginal improvement — the race mechanic is already strong without VRF
- (-) Risk of scope creep: tuning denial rates, cooldowns, and escalation adds design surface area

### Three-Way Summary

| Metric | Fortune Gate (ID 26) | Gauntlet (Wildcard) | **Fortune Gauntlet** |
|--------|:---:|:---:|:---:|
| Internal Weighted Score | 5.38 | ~6.6* | **6.72** |
| FAQ Composite | ~5.0 | ~6.5 | **6.75** |
| Best Prize Fit | Weirdest Idea | Most Creative / Weirdest | **Weirdest Idea** |
| Build Complexity | Low–Medium | Medium | **Medium** |
| Demo Energy | Low | High | **High** |

*\*Gauntlet wildcard score (7.8) was on a different rubric. Approximate 8-criterion conversion: Con 7, Mod 6, Imp 7, Ply 5, Vib 6, Cre 7, UX 6, Demo 8, PVote 7 → Weighted ~6.6.*

---

## 5. Prize Category Analysis

| Prize | Fit | Win Probability | Reasoning |
|-------|:---:|:-:|-----------|
| **1st Place** ($25K) | ⬜ Weak | ~3% | Sprint project cannot compete with full-suite flagship entries (CivilizationControl, etc.) on Mod Design and breadth |
| **2nd Place** ($12.5K) | ⬜ Weak | ~5% | Same as above — scope is too narrow for top-3 all-around |
| **3rd Place** ($7.5K) | 🔲 Marginal | ~8% | Possible if execution is exceptionally polished and competition is thin |
| **Most Utility** ($6K) | ⬜ Weak | ~5% | Entertainment mechanic, not operational utility. Loses to Storefront, Policy Engine, etc. |
| **Best Technical** ($6K) | 🔲 Decent | ~15% | `sui::random` VRF + DF state + extension pattern is clean. But "Best Technical" rewards architecture and scalability — single-purpose racing is narrower than system-level entries |
| **Most Creative** ($6K) | ✅ Strong | ~25% | Novel intersection of VRF + gate racing + on-chain referee. The randomness layer elevates it above a pure race. Faces competition from concepts like Salvage Protocol and ZK GatePass |
| **Weirdest Idea** ($6K) | ✅✅ **Best Fit** | ~35–40% | "VRF slot-machine obstacle course through space gates" is inherently weird, visual, and meme-worthy. Fortune Gate (ID 26) was already ranked #1 for Weirdest Idea in the V3 doc — the Gauntlet version is strictly superior on every axis |
| **Best Live Integration** ($6K) | 🔲 Marginal | ~10% | Requires Stillness deployment + multiple linked gates + real players. Achievable but setup overhead is high |

### Recommended Prize Target

**Primary: Weirdest Idea ($6K)**

The Fortune Gauntlet is the strongest Weirdest Idea candidate because:
1. "Random chance space gate obstacle course" is immediately weird and memorable
2. Denial moments are clip-worthy — "you rolled a 7, cooldown 30 seconds, better luck next time"
3. The demo has natural visual comedy (failed attempts) and drama (final checkpoint success)
4. Fortune Gate was already #1 for Weirdest in V3 — the Gauntlet doubles down on that strength
5. Competition for Weirdest is thinner than for Best Technical or Most Creative

**Secondary: Most Creative ($6K)**

If Weirdest Idea attracts a stronger competitor (e.g., something deeply meme-viral), the concept has a credible Most Creative fallback via the "on-chain VRF referee" angle.

---

## 6. Kill Criteria

Any of these is a hard stop for the combined concept:

| # | Kill Criterion | How to Detect | Mitigation |
|---|---------------|---------------|------------|
| 1 | **`sui::random` unavailable or unstable on hackathon test server** | Test `entry fun` with `&Random` on March 11 devnet | Fall back to deterministic Gauntlet (remove VRF, keep race) → still viable but loses Weirdest Idea edge |
| 2 | **Cannot link 3+ gates owned by same character in test environment** | Attempt `link_gates` for 3 gate pairs on devnet | Reduce to 2 checkpoints (minimum viable) or use unlinked gates with permit-only tracking |
| 3 | **`jump_with_permit` sponsor infrastructure not operational** | Test dual-sign sponsored tx flow on March 11 | This kills ALL gate extension entries, not just Fortune Gauntlet. Shared risk. |
| 4 | **DF per-player state creates unresolvable shared object contention** | Load test with >5 concurrent players on devnet | For demo scope (<10 players), extremely unlikely. Only relevant at scale |
| 5 | **Combined scope exceeds sprint time budget (>2 days Move + scripts)** | Sprint planning + velocity estimate | Drop VRF (fall back to deterministic Gauntlet) or drop sequential progression (fall back to single Fortune Gate) |
| 6 | **Randomness MEV — players can observe roll and abort** | Verify Sui `Random` security model against current docs | Sui's `Random` is designed to prevent this (seed rotates per epoch, committed before tx execution). Verify on March 11 |

---

## 7. Tuning Guidance

### Denial Rate (5–15% Range)

| Rate | Effect | Recommendation |
|:----:|--------|---------------|
| 5% | Minimal tension. Most players clear all checkpoints on first try. Race is essentially deterministic. | Too low — loses the "Fortune" identity. |
| **8–10%** | **Sweet spot for 3 checkpoints.** ~73% chance of clearing all 3 without any denial (0.9² × 0.92 ≈ 0.73). Most players experience 0–1 denial — enough for drama without frustration. | **Recommended for demo.** |
| 12% | Noticeable tension. ~68% clean-run probability for 3 checkpoints. Some players hit 2+ denials — could feel punishing. | Viable if cooldown is short (10–15 seconds). |
| 15% | High variance. ~61% clean-run probability for 3 checkpoints. Significant frustration risk. Race outcome feels "random" rather than "skilled." | Too high for demo — judges may see 2+ denials in a 3-minute video. |

**Recommended: 10% denial rate (success_threshold = 90)** with 15-second base cooldown escalating by denial count.

### Probability Table (at 10% denial per checkpoint)

| Checkpoints | P(clean run) | P(exactly 1 denial) | P(2+ denials) | Expected denials |
|:-----------:|:------------:|:-------------------:|:-------------:|:----------------:|
| 3 | 72.9% | 24.3% | 2.8% | 0.30 |
| 4 | 65.6% | 29.2% | 5.2% | 0.40 |
| 5 | 59.0% | 32.8% | 8.2% | 0.50 |

### Checkpoint Count (How Many Gates?)

| Count | Pros | Cons | Verdict |
|:-----:|------|------|---------|
| 2 | Trivial to set up. Minimal DF overhead. | Too short — feels like "two coin flips," not a gauntlet. No narrative arc. | ❌ Too few |
| **3** | **Clean narrative arc (start → middle → end). ~73% clean-run at 10% denial. Setup: 13 PTB commands. Demo fits 2–3 minutes.** | Slightly simple — may not feel like a "gauntlet." | **✅ Recommended for demo** |
| 4 | Adds depth. ~66% clean-run creates more drama. | Setup overhead increases. Demo may feel long if player hits multiple denials. | ✅ Viable stretch |
| 5 | Maximum drama. "Five gates, one shot." | ~59% clean-run at 10% — nearly half of demo runs will have denials. Setup overhead: 21 PTB commands. Risk of demo running over time. | ⚠️ Only if time permits |

**Recommended: 3 checkpoints** for the demo, with code supporting up to 5 via configuration.

---

## 8. Positioning Assessment

### Is the combined concept better positioned than either standalone?

**vs Fortune Gate alone: Yes, significantly.**

Fortune Gate (5.38) is a novelty gimmick — "random gate, funny if denied." It has no progression, no competition, and no narrative. The Gauntlet structure transforms it into a competitive experience with pacing, tension, and resolution. The +1.34 weighted score improvement is driven almost entirely by Demo (+2) and Player Vote (+2) gains, which are the dimensions that matter most for Weirdest Idea and player engagement.

**vs Standalone Gauntlet: Marginal improvement, with tradeoffs.**

The Gauntlet (7.8 wildcard) is already a strong concept. Adding VRF randomness provides:
- A marquee Sui primitive demonstration (`sui::random`)
- The "Fortune" branding and meme-worthy denial moments
- Stronger Weirdest Idea positioning

But it also adds:
- `entry` function constraint complexity
- Design surface area (denial rates, cooldowns, escalation)
- A thin "gambling" perception risk

**Net assessment:** The combined concept is **modestly superior** to the standalone Gauntlet for Weirdest Idea targeting (+5–10% win probability) and **dramatically superior** to Fortune Gate alone (+1.34 weighted, different category entirely).

### Final Recommendation

**Build Fortune Gauntlet as a sprint/stretch entry targeting Weirdest Idea ($6K).**

The concept offers the best risk-adjusted return of the three variants:
- It's a clear #1 for the Weirdest Idea category (the only category where it's a frontrunner)
- The demo is inherently entertaining and fits the 2–3 minute video format perfectly
- Technical complexity is medium — achievable in 1–2 sprint days
- Kill criteria are shared with all gate extensions (sponsor dependency) or easily mitigated (VRF fallback)
- The code supports CivilizationControl's stretch goals: the `try_issue_permit` pattern with `sui::random` can be extracted into the LootDrop module if needed

**Do not position this as a flagship entry.** Its narrow utility (5/10) and moderate Frontier vibe (6/10) make it uncompetitive for 1st–3rd place. Play to its weird strength.

---

## Appendix: Score Comparison Table

| Criterion | Fortune Gate (ID 26) | Fortune Gauntlet | Gauntlet (Wildcard)* | CivilizationControl Suite |
|-----------|:---:|:---:|:---:|:---:|
| Concept | 6 | 7 | 7 | 9 |
| Mod Design | 6 | 7 | 6 | 10 |
| Implementation | 5 | 7 | 7 | 8 |
| Player Utility | 4 | 5 | 5 | 9 |
| Frontier Vibe | 5 | 6 | 6 | 9 |
| Creativity | 6 | 7 | 7 | 7 |
| UX | 6 | 6 | 6 | 8 |
| Demo | 6 | 8 | 8 | 9 |
| Judge Average | 5.50 | 6.63 | 6.50 | 8.63 |
| Player Vote | 5 | 7 | 7 | 6 |
| **Weighted** | **5.38** | **6.72** | **~6.44** | **7.97** |
| Prize Target | Weirdest | **Weirdest** | Most Creative | 1st Place |

*\*Gauntlet approximate conversion from 5-axis wildcard rubric to 8-criterion rubric.*
