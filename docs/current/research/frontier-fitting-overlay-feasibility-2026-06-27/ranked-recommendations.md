# Ranked Recommendations (2026-06-27)

**Status:** Active research artifact (Workstream H). A transparent ranking of concrete implementation
candidates across the fitting tool and the overlay, plus an explicit "what to build first."

## Scoring rubric (8 axes, 0–5 each, max 40)
| Axis | Meaning |
|---|---|
| **Exc** | Operator excitement / strategic fit (the fitting tool is the operator's stated priority) |
| **Use** | Community usefulness |
| **Feas** | Feasibility / buildability |
| **Data** | Data availability (is the data we need on hand?) |
| **Churn** | Alpha-churn resilience (survives the game changing) |
| **Syn** | EF-Map synergy (reuses existing assets/audience) |
| **Moat** | Helper/overlay moat (uniquely hard for others to copy — the native in-game loop) |
| **Maint** | Maintenance-burden **inverse** (5 = near-zero upkeep) |

## Ranked table (sorted by score)
| Rank | Candidate | Type | First build? | Exc | Use | Feas | Data | Churn | Syn | Moat | Maint | **Score** | Why |
|---:|---|---|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| 1 | **EF-Map integration layer** (cross-origin data fetch + share service + industry engine reuse) | Fitting (web) | ◑ MVP milestone 1 | 4 | 5 | 5 | 5 | 4 | 5 | 2 | 4 | **34** | Cheapest, highest-leverage; the catalog + shopping-list + share links come almost free |
| 2 | **Fitting data-extraction spike** (extend `extract_ships.py` to module dogma + Root hull) | Fitting (data) | ★ MVP milestone 0 | 4 | 3 | 5 | 5 | 4 | 5 | 2 | 5 | **33** | Pipeline exists; ~2–4h; unblocks powergrid + base stats; re-runnable each patch |
| 3 | **Generic overlay payload schema + capability handshake** (schema v5 + generic text-card renderer) | Overlay | parallel/after | 4 | 3 | 3 | 5 | 5 | 3 | 5 | 4 | **32** | The operator's stated architecture; biggest durable moat; churn-proof; needs C++/Store |
| 4 | **Overlay fit-plan handoff** (`fit_plan` card + module-tick backchannel) | Overlay+Fitting | after MVP | 4 | 4 | 3 | 4 | 4 | 4 | 5 | 3 | **31** | The unique in-cockpit "install this fit" loop; depends on #3 + the MVP |
| 5 | **Frontier Fitting MVP** (catalog + polyomino editor + power + stats + share) | Fitting (web) | ★ **the product** | 5 | 5 | 4 | 3 | 3 | 4 | 3 | 3 | **30** | The headline product the operator wants; scored as the full build (its enablers #1/#2 score higher because they're cheap slices) |
| 6 | **Overlay visual refresh — Phase 1** (fonts, flat style, DPI, alpha) | Overlay | parallel | 4 | 3 | 4 | 5 | 4 | 2 | 4 | 4 | **30** | ~1 day, one Store update; turns a debug window into an EVE-authentic HUD |
| 7 | **Overlay route/objective cards** (reuse generic cards for route context) | Overlay | after #3 | 3 | 3 | 4 | 4 | 4 | 3 | 3 | 4 | **28** | Low-risk reuse of the card model; modest excitement |
| 8 | **Build-plan cockpit checklist** (generic checklist card for any build/objective) | Overlay | after #3 | 3 | 3 | 3 | 4 | 4 | 4 | 4 | 3 | **28** | Generalizes the fit-plan loop to builds/objectives |
| 9 | **Overlay session recap card** (end-of-session summary) | Overlay | after #3 | 2 | 3 | 4 | 4 | 4 | 3 | 3 | 4 | **27** | Nice-to-have; modest pull |
| 10 | **Fitting catalog authoring** (footprints + hardpoints + interior/exterior + UI categories) | Fitting (data) | ◑ MVP milestone 1 | 3 | 3 | 4 | 1 | 2 | 3 | 2 | 3 | **21** | The hand-authored gap; bounded (~16–30 entries) but the dominant manual cost; churns with hull changes |
| 11 | **Screenshot import — Stage 1** (module-list assist, dictionary-OCR, in-browser) | Fitting (web) | post-MVP | 2 | 3 | 3 | 4 | 2 | 2 | 3 | 2 | **20** | Useful accelerator but operator deprioritized; alpha-UI-churn fragile; never block MVP on it |
| 12 | **Screenshot import — Stage 2** (full spatial CV reconstruction) | Fitting (web) | deferred | 2 | 2 | 2 | 2 | 1 | 2 | 2 | 2 | **15** | Genuine CV project, low payoff (placement ≠ stats); defer indefinitely |

(★ = recommended starting point · ◑ = a milestone *inside* the recommended first project)

## What to build first (the resolution)
**Build the Frontier Fitting MVP (#5) — it is the product the operator wants.** Candidates #1 and #2
score higher only because they are **cheap, certain slices** of that same MVP, and they are exactly how
you start it:

- **Milestone 0 = #2, the data-extraction spike** (~2–4h): run/extend `extract_ships.py` over the 16
  module typeIDs + the Root hull to confirm powergrid usage and base stats are in dogma. This is the
  single fastest way to de-risk the whole product (it answers "is this data-backed or hand-authored?").
- **Milestone 1 = #1 + #10, the EF-Map-integrated catalog**: fetch `blueprint_data_v5.json` cross-origin
  for module identity/mass/volume/recipe, hand-author footprints + hardpoints, assemble the versioned
  catalog.
- **Then the editor, power, stats, and share** complete the MVP.

**The overlay tracks (#3, #6) run in parallel and are optional** — they are the operator's secondary
interest and a durable moat, but **must not block the fitting MVP**. The right overlay first step is
**#3 (generic payload schema + capability handshake)** because it is the foundation for #4/#7/#8 and
encodes the alpha-resilient architecture the operator asked for; **#6 (visual Phase 1)** is a cheap,
high-polish parallel win that can ride the same Store submission.

## Sequencing summary
1. **Now:** Fitting MVP — spike (#2) → integrated catalog (#1/#10) → editor + power + stats + share (#5).
2. **Parallel (optional, batched into one Store submission):** overlay generic payload + capability
   handshake (#3) + visual Phase 1 (#6).
3. **After the MVP ships:** overlay fit-plan handoff (#4) — the flagship native integration.
4. **Later/stretch:** build-plan checklist (#8), route/session cards (#7/#9), screenshot import Stage 1
   (#11). **Defer** spatial screenshot import (#12).
