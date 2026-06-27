# Frontier Fitting Tool & Overlay Feasibility — 2026-06-27

**Status:** Active research artifact (read-only feasibility + product spec; nothing was built or
deployed). **Branch:** `research/frontier-fitting-overlay-feasibility-20260627`.

This folder answers: **can we build an EVE Frontier ship-fitting tool ("EFT Warrior" for Frontier),
and how should the EF-Map overlay/helper evolve to support it?** Produced from a read-only audit of the
operator's three in-game fitting screenshots plus `Diabolacal/EF-Map` (`b1cd69e`) and
`Diabolacal/ef-map-overlay` (`8788a16`), cloned read-only to scratch.

> Reads on top of, and is corrected by, the prior pass
> [`../project-ideation-2026-06-27/`](../project-ideation-2026-06-27/README.md). Operator corrections
> (Rift Watch out, Patch Witness/SSU-dashboard/Frontier-Facts deprioritized, etc.) are captured in
> [`operator-context.md`](operator-context.md) and **supersede** the earlier shortlist.

---

## Verdict

**Build the fitting tool. It is viable, the operator's priority is well-placed, and most of the data
is closer to hand than expected.** Ship it as a **standalone web app that reuses EF-Map's public data,
share service, and industry engine**. Treat the overlay refresh as a **valuable parallel track and a
durable moat — but never a blocker** for the fitting MVP.

### Fitting tool — feasibility at a glance
- **Data is partially free already:** EF-Map's public `blueprint_data_v5.json` carries **all 16 Cycle 6
  modules** (typeIDs 95302–95503) with name, mass, volume, category/group, **and build recipes** — so
  the module palette, mass total, and "build this fit" shopping list come almost for free.
- **The classic stats are extractable:** powergrid usage, HP, velocity, capacitor, warp, etc. live in
  the game's dogma layer and EF-Map already has the extractor (`tools/game-data-extractor/
  extract_ships.py`); one ~2–4h run over the module typeIDs unlocks them.
- **The real gap is geometry:** the **polyomino footprint shapes + interior/exterior + hardpoint
  metadata** are **not in any extractable data (~90% confidence)** — they must be **hand-authored** from
  the screenshots (bounded: ~16–30 entries, the same pattern EF-Map already uses for `shipData.ts`).
- **The engine is low-risk:** polyomino placement/rotation/collision/hull-mask + powergrid + additive
  stats are classic, fully specifiable today ([`fitting-model-and-rules.md`](fitting-model-and-rules.md)).
  The only genuine unknowns are the **non-additive stat formulas** (velocity/inertia/warp), which the
  MVP ships as **"estimated"** and calibrates later via single-module delta testing.

### Overlay — feasibility at a glance
- The overlay is a capable **generic JSON-rendering bridge** (HTTP :38765 / WS :38766 / `ef-overlay://`,
  schema v4) but has **no capability negotiation** and its "push arbitrary text" hook was removed in a
  cleanup. The durable fix is a **schema-v5 `overlay_cards[]` model + a `capability_hello` handshake**
  (product logic in web, helper stays generic — the operator's stated architecture).
- Visually it still uses **ImGui's default dark theme + the ProggyClean bitmap font** (looks like a
  debug window); **five small C++ changes** (fonts, flat style, brighter unfocused alpha, text-underline
  tabs, DPI auto-detect) get it most of the way to EVE-authentic in **~1 day / one Store update**.
- The flagship integration is a **`fit_plan` card**: push a fit → in-cockpit "install these modules"
  checklist + powergrid/fuel reminder, with the player ticking items off. Needs ~200 lines of C++; the
  operator's willingness to change the helper + resubmit to the Store makes it viable.

## Main recommendation
**Frontier Fitting MVP (working name "RootFit")** — full brief in
[`recommended-next-build.md`](recommended-next-build.md). Start with the **2-hour data-extraction
spike** (de-risks the whole thing), then build the EF-Map-integrated catalog + polyomino editor +
power + stats + share.

## Ranked candidates (top of the list — full table in [`ranked-recommendations.md`](ranked-recommendations.md))
| Rank | Candidate | Type | First build? | Score |
|---:|---|---|---|:--:|
| 1 | EF-Map integration layer (data/share/industry reuse) | Fitting | ◑ MVP milestone 1 | 34 |
| 2 | Fitting data-extraction spike | Fitting (data) | ★ MVP milestone 0 | 33 |
| 3 | Generic overlay payload schema + capability handshake | Overlay | parallel | 32 |
| 4 | Overlay fit-plan handoff (`fit_plan` card) | Overlay+Fitting | after MVP | 31 |
| 5 | **Frontier Fitting MVP** (the product) | Fitting | ★ **the product** | 30 |
| 6 | Overlay visual refresh — Phase 1 | Overlay | parallel | 30 |

(#1 and #2 outscore the MVP only because they are its cheap, certain first slices — see the ranking's
"what to build first.")

## Top risks
1. **Footprint shapes are not in data** (expected) → hand-author; bounded but the main manual cost.
2. **Live game is alpha** → the fitting UI/stats *will* change; mitigate with a **data-driven, versioned
   catalog** and a **generic overlay renderer** (no game data in C++).
3. **Stat formulas** (velocity/inertia/warp) not yet derivable → ship "estimated," calibrate later.
4. **Store cert turnaround** for overlay C++ changes → batch changes; existing build stays live on
   failure.

## How to read this folder
| File | What's in it |
|---|---|
| [`operator-context.md`](operator-context.md) | Operator corrections + the screenshot-derived fitting UI facts + the helper/Store constraint |
| [`data-source-audit.md`](data-source-audit.md) | What fitting data exists / is missing / is extractable; the footprint-shape verdict |
| [`fitting-model-and-rules.md`](fitting-model-and-rules.md) | Hull/grid/module schema, placement & power algorithms, stat formulas + known unknowns, serialization, future hull sections |
| [`product-ux-spec.md`](product-ux-spec.md) | MVP product, 3-column layout, palette/editor/stats/power, share & fit-card, mobile, visual direction |
| [`screenshot-import-feasibility.md`](screenshot-import-feasibility.md) | Deterministic-CV plan; staged (no-import → module-list assist → spatial); MVP verdict: out |
| [`ef-map-integration-plan.md`](ef-map-integration-plan.md) | Hybrid-standalone home; reusable assets; share/permalink; build-plan handoff; avoid bloat |
| [`overlay-helper-audit.md`](overlay-helper-audit.md) | Overlay protocol; generic `overlay_cards[]` + capability negotiation; `fit_plan` integration; web-only vs C++ |
| [`overlay-visual-redesign.md`](overlay-visual-redesign.md) | Current visual state; EVE-Frontier style tokens; phased redesign; top-5 fixes; risks |
| [`ranked-recommendations.md`](ranked-recommendations.md) | 12 candidates scored on an 8-axis rubric + explicit build order |
| [`recommended-next-build.md`](recommended-next-build.md) | Full implementation brief for the Frontier Fitting MVP |
| [`implementation-briefs/`](implementation-briefs/) | [Fitting MVP](implementation-briefs/fitting-tool-mvp.md) · [Data-extraction spike](implementation-briefs/fitting-data-extraction-spike.md) · [Overlay fit-plan handoff](implementation-briefs/overlay-fit-plan-handoff.md) · [Overlay visual refresh](implementation-briefs/overlay-visual-refresh.md) |
| [`open-questions.md`](open-questions.md) | What to confirm before/while building |

## Reminders for whoever builds from this
- **Run the extraction spike first** — it answers "data-backed vs hand-authored" in a couple of hours.
- **Keep the catalog data-driven and versioned** — the game is alpha; logic must not hardcode game data.
- **Don't bloat EF-Map** — fetch its assets cross-origin, vendor only the pure-TS industry engine, copy
  (don't import) CSS tokens; deploy standalone.
- **Don't block the fitting tool on the overlay.** Overlay work is the moat, not the gate.
- Authority hierarchy still applies: current vendor source + live game behavior outrank any doc here.
