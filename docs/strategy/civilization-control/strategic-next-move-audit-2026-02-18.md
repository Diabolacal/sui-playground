# Strategic Next-Move Audit — CivilizationControl (2026-02-18)

**Retention:** Carry-forward

- **Date:** 2026-02-18 (environment model to be confirmed March 11)
- **Window:** 3 weeks until March 11 coding start
- **Context:** Pre-hackathon execution bottleneck analysis

---

## Environment Model (Three-Tier)

| Environment | Availability | Purpose | Key Properties |
|---|---|---|---|
| **Local DevNet** | Pre-March 11 (now) | Pre-hackathon validation, pattern exploration, compile tests | Docker-based (`builder-scaffold`). GovernorCap available. Self-signed proofs. No world-contracts dependencies tested against live types. |
| **Hackathon Test Server** | From March 11 (hackathon start) | Primary build/test/evidence environment | Same world-contracts as Stillness. Real Move publishing, real tx digests. Admin-spawnable structures, unlimited currency. Shared among all builders (symmetric visibility). |
| **Stillness** | Always (live server) | Post-submission deployment bonus + player vote cultivation | Live player server — NOT a testnet. Real player usage. Deployment bonus requires Stillness deploy within 14 days post-submission close. |

**Critical correction:** Earlier versions of this document assumed a two-tier model (local devnet + Stillness). The hackathon test server — available from March 11 — changes the deployment strategy: it provides equivalent evidence quality to Stillness without competitive visibility risk, and the Stillness deployment bonus has a 14-day post-submission window.

---

## The Bottleneck

The bottleneck is **integration risk** — not documentation, not strategy, not ideation.

37 documents (~15,580 lines) have been written. Every strategic question is answered. Every architecture pattern is catalogued. Every judging criterion is mapped. The documentation is **saturated**. But the entire validation suite used **zero world-contracts dependencies** — every sandbox module had empty `[dependencies]`. The gap between "pattern validated on standalone mocks" and "extension compiles and executes against published world-contracts types" is the seam most likely to consume Day 1-2 and cascade into demo failure.

Three critical unknowns remain open from the portfolio roadmap §10:
1. Character resolution on hackathon test server (RED blocker — previously scoped to Stillness; test server provides equivalent validation)
2. EVE Vault adapter PTB signing (untested)
3. ~~Multi-submission rule (unconfirmed)~~ ✅ **RESOLVED (2026-03-02):** Deep Surge FAQ confirms multiple submissions allowed; each must be unique. Portfolio strategy validated.

These are **not documentation gaps**. They are **empirical unknowns that only testing can resolve.**

---

## STOP / CONTINUE / START

### STOP

- **Writing documentation.** Every category is at or beyond diminishing returns. The marginal value of any new pre-implementation document is zero or negative.
- **Narrative refinement.** Voice guide, emotional objective, label mapping table — all locked. Changing "Policy deployed" to "Policy enacted" is procrastination.
- **Architecture analysis.** 7 docs at ~4,750 lines. The team knows more about world-contracts than most people who wrote it. More analysis delays execution readiness.
- **Idea expansion.** Portfolio is locked at 4+1 entries from a 28-idea evaluation. Re-opening it wastes the analysis that locked it.
- **Cosmetic polish.** Reformatting tables and prettifying READMEs creates a false sense of progress.

### CONTINUE

- **Decision log updates** — these happen naturally during the targeted validation work below.
- **Monitoring world-contracts for upstream changes** — a single `git fetch` + diff review before March 11.

### START

- **Targeted integration de-risking** (the three actions below).
- **Demo rehearsal** — the script exists on paper but nobody has spoken it aloud or recorded a screen.
- **Intentional rest** — the biggest risk after 37 docs of continuous prep is burnout before the sprint.

---

## Top 3 Next Actions (Ranked)

### 1. Resolve the Three Empirical Unknowns

**Why it matters:** These are the only things that can invalidate the entire architecture on Day 1. Character resolution is flagged RED in the auth surface analysis. EVE Vault signing is untested. The multi-submission rule determines whether the portfolio strategy even works. No document can answer these — only experiments and a message to organizers.

**Specific outcome:**
- Confirm or refute Character event indexing on hackathon test server RPC (3-4 hours). Decision: event-based resolution vs. manual Character ID input. *(Note: test server is the primary target from March 11; Stillness testing is deferred to post-submission deployment phase.)*
- Build a 50-line HTML page: `@mysten/dapp-kit` → connect EVE Vault → sign a trivial PTB on test server (3-4 hours). Pass/fail.
- ~~Email/Discord organizers: "Can one team submit multiple entries?" (30 minutes). If no, restructure portfolio before March 11.~~ ✅ **RESOLVED (2026-03-02):** Deep Surge FAQ confirms yes.
- Compile a minimal Move package that imports `world::gate`, `world::character`, `world::storage_unit` against published world-contracts on local devnet (2-4 hours). Confirm `issue_jump_permit<TestAuth>()` is callable from a dependent package.

**What to avoid:** Turning these tests into full implementations. Each is a binary pass/fail — get the answer and stop. Delete throwaway code afterward.

### 2. Demo Dry Rehearsal

**Why it matters:** The demo is the submission. The beat sheet scripts 7 beats in 3 minutes with evidence overlays and timed narration. But a written script is not a delivered performance. Pacing problems, recording tool configuration, overlay placement, and the gap between "the tx takes 8 seconds" and "the script assumes 2 seconds" — these only emerge with a camera rolling. The independent audit's predicted failure mode is "polished UI with insufficient on-chain consequence evidence." A rehearsal tests both evidence sufficiency and demo delivery.

**Specific outcome:**
- OBS (or chosen tool) configured and tested — 30-second screen capture + voiceover (2 hours).
- Full 3-minute script read aloud 2-3 times with stopwatch. Identify which beats run long. Pre-mark cut points (3-4 hours across two sessions).
- Track C demo skeletons: 5-bullet narration outline for Fortune Gate, Salvage Protocol, Corpse Toll Road (1.5 hours).

**What to avoid:** Over-producing. No motion graphics, no custom title cards, no B-roll planning. Simple screen capture + voiceover is sufficient. Don't spend more than 6 hours total on demo rehearsal before March 11.

### 3. Environment Lock and Freshness Check

**Why it matters:** Docker devnet boot time, frontend dependency compatibility, and world-contracts API stability are Day-1 prerequisites that silently fail when unverified. The reimplementation checklist's assumptions A1-A8 are based on source analysis from Feb 16. Any post-Feb-16 commit to world-contracts could invalidate the pattern catalog. The hackathon test server (available March 11) is the primary build target — local devnet is for pre-hackathon validation only.

**Specific outcome:**
- `git -C vendor/world-contracts fetch origin` + diff review of `gate.move`, `storage_unit.move`, `access_control.move` (30 minutes). Note any signature changes vs. assumptions.
- Time Docker devnet cold start. Pre-pull image if >5 minutes (30 minutes). *(Local devnet remains useful for rapid iteration before test server access.)*
- Create and delete a throwaway Vite+React+TS project with `@mysten/dapp-kit` installed to verify npm compilation (30 minutes).
- Pin Node.js and pnpm versions (15 minutes).

**What to avoid:** Full IDE setup, CI/CD configuration, project templates with pre-configured component libraries — these cross into submission repo scaffolding.

---

## Minimal Extension Compile Test — Status: PASS (2026-02-18)

A minimal Move package (`sandbox/minimal-extension-test/`) was compiled against `vendor/world-contracts` (pinned at `eb1d627`, v0.0.11-4) using Sui CLI 1.66.1 inside the builder-scaffold Docker image. The package imports `world::gate`, `world::character`, and `world::storage_unit`, references public structs (`Gate`, `Character`, `StorageUnit`, `JumpPermit`), calls view functions, and type-checks `gate::issue_jump_permit<TestAuth>()` with a custom witness type. Build completed cleanly with no address mismatches, no visibility errors, and no missing capability errors. Cross-package extension compilation is confirmed viable.

---

## EVE Vault Signing Smoke Test — Status: SCAFFOLD READY (2026-02-18)

**Objective:** Confirm EVE Vault can connect via `@mysten/dapp-kit`, construct a trivial PTB, sign successfully, and return a valid signature object.

**Scaffold:** `sandbox/evevault-signing-smoke/` — Vite + React + TypeScript + `@mysten/dapp-kit` 1.0.3 + `@mysten/sui` 2.4.0.

**Toolchain verified:**
- Node: v22.19.0
- pnpm: 10.16.1
- @mysten/dapp-kit: 1.0.3 (latest)
- @mysten/sui: 2.4.0 (latest)
- TypeScript: 5.9.3
- Vite: 7.3.1

**Gates:**
- TypeScript typecheck: PASS
- Vite production build: PASS
- Manual browser test: PENDING (requires EVE Vault Chrome extension + FusionAuth OAuth)

**Architecture finding:** EVE Vault registers as `"Eve Vault"` via Sui Wallet Standard (`registerWallet(new EveVaultWallet())`). It uses zkLogin — signing requires FusionAuth OAuth + Enoki API key for address derivation. Detection is automatic via `@mysten/dapp-kit`'s `useWallets()` hook. No special adapter code needed beyond standard `useSignTransaction()`.

**Blocking requirement for manual test:** EVE Vault Chrome extension must be built from source (`vendor/evevault`) or installed from GitHub releases. Requires FusionAuth credentials (EVE Frontier auth server) and Enoki API key for zkLogin. These are not locally available in the sandbox environment.

**Stillness RPC:** Not yet tested. Scaffold defaults to localnet (`http://127.0.0.1:9000`). Initial validation will target the hackathon test server (available from March 11) rather than Stillness. Stillness deployment is deferred to the post-submission bonus window (14 days post-close).

**Next step:** Install EVE Vault extension in Chrome, run `pnpm dev` in the sandbox, and execute the manual 4-step test (detect → connect → sign → evaluate). Target the hackathon test server RPC once available (March 11). Update this section to PASS/PARTIAL/FAIL after manual test.

---

## Explicit Verdicts

| Question | Answer |
|----------|--------|
| Further strategic documentation useful? | **No.** Saturated. Negative ROI. |
| UI structural refinement useful? | **No.** The 1,010-line UX spec exceeds what can be built in 14 days. More detail risks premature commitment. |
| Recording a placeholder demo useful? | **Yes — but as rehearsal, not as an artifact.** Practice narration timing and recording tools. Don't try to produce a usable demo before the software exists. |
| Continuing deep research useful? | **No.** One targeted exception: check world-contracts for upstream changes and confirm the multi-submission rule. Everything else is answered. |

---

## Calendar Sketch

| Period | Focus | Hours |
|--------|-------|-------|
| **Feb 18-23** | Kill unknowns: multi-submission rule, Character resolution (target test server from March 11), EVE Vault adapter, extension compilation test | ~10-12 |
| **Feb 24-Mar 1** | Demo rehearsal + environment lock: OBS setup, narration practice, Docker timing, world-contracts freshness, frontend deps | ~8-10 |
| **Mar 2-9** | Final prep + **intentional rest**: Track C viability triage, Day-1 timeline mental walkthrough (target: test server as primary build environment), update carry-forward docs with findings. Then 4 days of genuine rest. | ~5-7 + rest |
| **Total** | | **~25 hours of work + 8 days of rest** |

The most counterintuitive recommendation: **do not work every day for 3 weeks.** The prep is mature. The biggest meta-risk now is arriving on March 11 exhausted from continuous analysis. ~25 hours of targeted de-risking, spread across the first two weeks, then rest.

---

## Single-Sentence Summary

The documentation is done; the strategy is locked; the only remaining high-leverage work before March 11 is **resolving three empirical unknowns that no document can answer**, **rehearsing the demo delivery**, and **then resting**.
