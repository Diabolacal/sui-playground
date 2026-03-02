# Fortune Gauntlet — Scoring Memo

**Retention:** Carry-forward

> **Date:** 2026-03-02
> **Status:** Concept synthesis complete — ready for sprint scheduling
> **Inputs:** hackathon-ideas-grounded-v3-judged.md, wildcard-sprint-analysis.md, hackathon-portfolio-roadmap.md, fortune-gauntlet-feasibility.md, fortune-gauntlet-scoring-report.md

---

## Summary

Fortune Gauntlet merges **Fortune Gate** (VRF-probabilistic permit issuance, ID 26) with **The Gauntlet** (sequential multi-gate checkpoint race, Wildcard #6) into a single sprint entry. Players race through 3 checkpoint gates in sequence; at each checkpoint, `sui::random` VRF rolls a 90/10 pass/deny probability. Denial triggers an escalating cooldown before retry. On-chain timestamps serve as verifiable referee. The concept targets **Weirdest Idea ($6K)** with an estimated 35–40% win probability — strictly superior to either standalone variant.

---

## 8-Criterion Internal Rubric

| # | Criterion | Score | Reasoning |
|---|-----------|:-----:|-----------|
| 1 | Concept | **7** | Coherent gate-race-with-danger loop. Feasibility fully validated. Not solving a "felt pain point" but creating a novel competitive mechanic. |
| 2 | Mod Design | **7** | Clean single-package architecture. Per-gate DF config makes checkpoints reusable. Standard ExtensionConfig/AdminCap/XAuth pattern. |
| 3 | Implementation | **7** | All components validated: `entry` function for `sui::random`, DF-based player state, `Clock` time mechanics, custom events. ~200–300 LoC. |
| 4 | Player Utility | **5** | Entertainment/competition experience. Doesn't change how players survive, trade, or coordinate. |
| 5 | Frontier Vibe | **6** | Uses real gate infrastructure, connects to "dangerous space" ethos. Feels more like a minigame than an emergent extension of core loops. |
| 6 | Creativity | **7** | Novel intersection: VRF + gate traversal + on-chain referee. Nobody else will build probabilistic checkpoint racing. |
| 7 | UX | **6** | Race concept is universally understood. Wallet-signing friction at each checkpoint. No in-game browser Sui wallet integration. |
| 8 | Demo | **8** | Strongest dimension. Timer, random rolls, denial tension, escalating cooldowns, final triumph — demo narrative writes itself. |
| — | Player Vote | **7** | Clip-worthy denial moments + triumphant completions. "Random chance × speed run × blockchain proof" is shareable. |

**Judge Average:** 6.63 | **Weighted Total:** 6.72

---

## FAQ 4-Area Summary

| Area | Score | Key Point |
|------|:-----:|-----------|
| Utility | **5** | Non-trivial on-chain state, but entertainment-only — no operational impact. |
| Technical | **8** | `sui::random` VRF, DF state, `Clock` time, extension pattern, custom events. |
| Creativity | **8** | No existing probabilistic checkpoint race on any chain. "Chain as referee" is clean. |
| Frontier Integration | **6** | Real gates + permits. Game-within-a-game rather than deepening core economic loops. |

**FAQ Composite:** 6.75

---

## Comparative Scores

| Variant | Weighted | Best Prize | Win Prob |
|---------|:--------:|------------|:--------:|
| Fortune Gate (standalone) | 5.38 | Weirdest Idea | ~65% |
| Gauntlet (standalone) | ~6.44 | Most Creative | ~20% |
| **Fortune Gauntlet** | **6.72** | **Weirdest Idea** | **~35–40%** |

Fortune Gauntlet is +1.34 over Fortune Gate alone (dramatic improvement on Demo +2, Player Vote +2) and ~+0.28 over standalone Gauntlet (VRF differentiation).

> **Note:** Fortune Gate standalone had a higher raw win probability for Weirdest (~65%) because the bar assumed a weaker concept competing. The combined concept is objectively stronger but enters a potentially stronger competitive field. Net: the combined concept is the better entry but win probability adjusts downward from Fortune Gate's original 65% estimate.

---

## Prize-Target Recommendation

**Primary: Weirdest Idea ($6K)** — 35–40% win probability. VRF slot-machine obstacle course through space gates is inherently weird, visual, and meme-worthy. Fortune Gate was already #1 for Weirdest in V3 rankings; the Gauntlet version is strictly superior on every axis.

**Secondary: Most Creative ($6K)** — ~25% fallback via "on-chain VRF referee" angle.

**Not competitive for 1st–3rd place.** Narrow utility (5/10) and moderate Frontier vibe (6/10) prevent it from competing with full-suite entries.

---

## Kill Criteria

| # | Criterion | Detection | Mitigation |
|---|-----------|-----------|------------|
| 1 | `sui::random` unavailable or unstable on hackathon test server | Test `entry fun` with `&Random` on March 11 devnet | Fall back to deterministic Gauntlet (remove VRF, keep race) |
| 2 | Cannot link 3+ gates owned by same character | Attempt `link_gates` on devnet | Reduce to 2 checkpoints or use unlinked gates with permit-only tracking |
| 3 | `jump_with_permit` sponsor infra not operational | Test dual-sign sponsored tx on March 11 | Kills ALL gate extension entries — shared risk, not Fortune Gauntlet-specific |
| 4 | Combined scope exceeds 2-day sprint budget | Sprint planning velocity at Day 8 | Drop VRF (deterministic Gauntlet) or drop sequence (single Fortune Gate) |
| 5 | Randomness MEV (players observe roll, abort tx) | Verify Sui `Random` security model on March 11 | Sui's `Random` is designed to prevent this; verify before shipping |

---

## Feasibility Notes

| Capability | Verdict | Detail |
|---|---|---|
| Probabilistic permit issuance via `sui::random` | ⚠️ Workaround | `entry` function constraint; compatible with extension pattern since `issue_jump_permit` has no return value |
| Checkpoint progress tracking | ✅ Now | Per-player `PlayerProgress` DF on ExtensionConfig + custom events (`CheckpointPassedEvent`, `CheckpointDeniedEvent`) |
| Consequence — turrets | 🔮 Future | Zero turret/combat code in world-contracts |
| Consequence — proxy (cooldown + deny list) | ⚠️ Workaround | DF-based `cooldown_until_ms` with escalating multiplier by `denial_count` |
| Multi-gate config | ✅ Now | Per-gate `GateCheckpointKey → GateCheckpoint` DFs. Setup: 4N+1 PTB commands |
| Time pressure via permit expiry | ✅ Now | `expires_at_timestamp_ms` + `Clock.timestamp_ms()` |

### Turrets Dependency — Truthfulness Statement

Turrets **do not exist** in current world-contracts. The consequence model uses DF-based cooldowns as a credible proxy. Events (`GauntletDenialEvent`) are emitted as a future-proof integration surface that turret systems could consume. The demo and vision doc frame turret integration as a stretch goal, not a dependency. No claims about turret availability should appear in the hackathon submission.

---

## Tuning Guidance

### Denial Rate

| Rate | P(clean run, 3 gates) | Assessment |
|:----:|:-----:|------------|
| 5% | 85.7% | Too low — loses "Fortune" identity |
| **10%** | **72.9%** | **Recommended.** ~0.3 expected denials per run. Most runs see 0–1 denial — enough drama without frustration. |
| 15% | 61.4% | Too punitive — nearly half of runs hit denials. Risk of bad demo experience. |

**Recommended: 10% denial rate** (`success_threshold = 90`) with 15-second base cooldown escalating by denial count.

### Checkpoint Count

| Count | P(clean run @10%) | Verdict |
|:-----:|:-:|---|
| 2 | 81% | Too few — "two coin flips," not a gauntlet |
| **3** | **73%** | **Recommended for demo.** Clean arc (start → middle → end). Fits 2–3 min video. |
| 4 | 66% | Viable stretch if time permits |
| 5 | 59% | Only if demo can absorb extra denials |

**Recommended: 3 checkpoints** for demo, code supports up to 5 via configuration.

---

## Build Estimate

| Component | Effort | Notes |
|-----------|--------|-------|
| Move package | 4–6 hours | ~200–300 LoC, standard extension pattern + `sui::random` |
| Admin config scripts (TS) | 2–3 hours | Gate authorization + checkpoint config + race config |
| Player-facing scripts (TS) | 2–3 hours | `try_issue_permit` call + `jump_with_permit` sponsored flow |
| Demo recording | 2–3 hours | 3 runs (clean, 1-denial, multi-denial), capture events |
| **Total** | **10–15 hours** | ~1.5 sprint days |

---

## Portfolio Impact

Fortune Gauntlet **replaces** Fortune Gate (Track C1) in the portfolio. It subsumes the same Weirdest Idea prize target with a stronger concept at moderate additional build cost (+4–6 hours over standalone Fortune Gate). The portfolio priority order remains unchanged: C3 → **C1 (now Fortune Gauntlet)** → E → C2 → F → D.

If at Day 8 sprint time is critically short: fall back to standalone Fortune Gate (original ~8 hours). The Fortune Gauntlet code is a strict superset — any partial progress on Fortune Gauntlet yields at minimum a functional Fortune Gate.
