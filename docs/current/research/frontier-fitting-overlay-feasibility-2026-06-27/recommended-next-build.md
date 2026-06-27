# Recommended Next Build — Frontier Fitting MVP (2026-06-27)

**Status:** Active research artifact. The single implementation task recommended out of this pass. This
is a **brief for a future build pass** — nothing here was built.

---

## Product name options
**RootFit** (recommended — ties to the "Root" hull, short, ownable) · Frontier Fitting · Frontier Fit
Lab · Shipwright · Frontier Drydock · Fit Bench. *Avoid "EFT"* (EVE Online confusion / trademark).

## One-line pitch
A fast, shareable, browser-based ship planner for EVE Frontier — lay out modules on the Root hull's
grid, manage power, see live ship stats, and share the fit as a link or a card, **before** you spend
materials building it in-game.

## Problem statement
Cycle 6's fitting is new (one hull, a polyomino module grid, powergrid + online/offline). Players who
loved theorycrafting "fits" outside the game in EVE Online have **no external planner** for Frontier
yet, and the in-game screen burns fuel while you think, needs you to *own* the modules, and can't
share a layout. First-mover opportunity before the ecosystem gets complex. (See
[`operator-context.md`](operator-context.md).)

## Target users
Theorycrafters; new/returning Cycle 6 players learning the fitting system; tribes standardizing and
sharing recommended fits in Discord.

## MVP scope
1. **Versioned module catalog** for the 16 Cycle 6 modules + the Root hull (data plan below).
2. **Grid editor:** drag/drop/rotate (90°, no mirror) polyomino placement with collision + hull-mask
   validity; numbered hardpoint mounting for exterior modules.
3. **Power management:** per-module online/offline + a powergrid budget bar (used/total MW).
4. **Live stats pane** reproducing the in-game left panel (additive stats exact; velocity/inertia/warp
   shown as **"estimated"** until calibrated).
5. **Save / load / share:** `?fit=<code>` URL + optional `ef-map.com/s/<id>` short link; PNG fit-card
   for Discord.
6. **"Build this fit"** shopping list via the reused EF-Map industry engine.

## Non-goals (MVP)
Screenshot import (post-MVP); multiple hulls (none exist); any wallet/on-chain/contract interaction
(none needed); overlay push (a fast follow, not MVP); accounts/login (fits live in URL/localStorage).

## Data sources (see [`data-source-audit.md`](data-source-audit.md))
| Need | Source | Status |
|---|---|---|
| Module identity, mass, volume, build recipe | `https://ef-map.com/blueprint_data_v5.json` (cross-origin fetch) | **on hand** (16 Module items, typeIDs 95302–95503) |
| Module powergrid usage + Root hull base stats (HP, velocity, powergrid, capacitor) | extend `tools/game-data-extractor/extract_ships.py` (Phobos/FSD dogma) | **one ~2–4h extraction run** |
| Module footprint shapes, interior/exterior flag, hardpoint types, UI category labels | **hand-authored** from screenshots into the catalog | author (~16–30 entries) |
| Some new Cycle 6 stats (conductance, fuel impulse) | hand-author/calibrate until found in dogma | calibrate |

**No contract interactions.** This is a read-only/no-wallet web tool. (On-chain fit import by Creation
ID is a *future* path if the data supports it — see screenshot-import doc.)

## Architecture (see [`ef-map-integration-plan.md`](ef-map-integration-plan.md))
- **Hybrid standalone:** own Cloudflare Pages project (`fit.ef-map.com`), Vite + React, **no Three.js**.
- **Engine:** the polyomino placement + power + stats model in
  [`fitting-model-and-rules.md`](fitting-model-and-rules.md) — pure, data-driven, versioned catalog.
- **Reuse from EF-Map:** cross-origin `blueprint_data_v5.json`; vendored pure-TS `lib/industry/*` for
  the shopping list; copied `App.css :root` tokens; `POST /api/create-share` (use an `r3|` prefix to
  pass the worker's `/^r\d+\|/` check — zero EF-Map change).

## EF-Map integration
Cross-origin data fetch + short-link reuse + "Build this fit" via the industry planner (inline). No
coupling to EF-Map's 3D bundle. Optional later: ask EF-Map to add `?item=&qty=` intake to the
Blueprint Calculator for a deep-link handoff.

## Helper/overlay integration (later, not MVP)
After the MVP, push a fit to the desktop overlay as a **`fit_plan` card** (in-cockpit "install these
modules" checklist + powergrid/fuel reminder) — see [`overlay-helper-audit.md` §4.3](overlay-helper-audit.md).
Requires the overlay generic-payload work; **do not block the MVP on it**.

## Milestones
- **2-hour spike (de-risk):** run the **module-dogma extraction** over the 16 module typeIDs + find the
  Root hull typeID; confirm whether powergrid usage + base stats are in dogma. In parallel, prototype
  the polyomino engine (rotate/collision/hull-mask) against a hand-authored 3-module catalog. Kill
  criteria below.
- **Weekend MVP:** catalog (data + hand-authored footprints) → grid editor (drag/drop/rotate/collision)
  → powergrid + online/offline → additive stats pane → `?fit=` share code. Single hull.
- **Week 1 polish:** hardpoint mounting UI, Discord fit-card PNG, "Build this fit" shopping list,
  EF-Map theme parity, mobile/tablet view, stat calibration against the operator's screenshot fit.
- **Month scale:** stat-formula calibration (velocity/inertia/warp via single-module delta testing),
  compare-two-fits, named saved fits, the overlay `fit_plan` handoff, and the screenshot module-list
  import (Stage 1). Design the catalog for future swappable hull sections (already modeled).

## Validation / smoke plan
- **Oracle test:** reproduce the operator's screenshot fit (same modules + online state); assert derived
  additive stats (mass, inventory, fuel, capacitor, powergrid) match the in-game left pane.
- **Property tests:** placement never overlaps; rotation involutive ×4; powergrid never exceeds capacity
  in a valid fit; serialize→deserialize identity.
- **Share round-trip:** `?fit=` code rebuilds the exact fit; `create-share` → `/s/<id>` resolves.
- **Cross-origin smoke:** confirm `blueprint_data_v5.json` fetch + `create-share` POST work from the
  standalone origin in a real browser.

## Risks & kill criteria
| Risk | Kill / mitigation |
|---|---|
| **Footprint shapes unobtainable from data** (90% likely) | *Expected* — hand-author from screenshots; bounded to ~16–30 entries. Not a kill; it's the plan. |
| **Module powergrid usage not in dogma** | If the spike finds no powergrid attribute, hand-author the `0.1 MW`-style values from the Power Management screenshot (small set). Not a kill. |
| **Stat formulas (velocity/inertia) won't calibrate** | Ship MVP with additive stats exact and velocity/inertia flagged "estimated." Honest and still useful. Not a kill. |
| **Alpha UI/stat churn** | Data-driven catalog + versioned `gameVersion`; re-run extraction per patch; engine logic unaffected. |
| **EF-Map asset URL bumps to `_v6`** | Resolve via `versionInfo.json`/decision log; pin + bump deliberately. |
| **Genuine kill:** the in-game fit turns out to be fully server-authoritative with no learnable client model AND no data is extractable AND screenshots are insufficient to author a usable catalog | Then the tool can't reproduce stats meaningfully → stop. (Considered very unlikely given the rich dogma layer + clear screenshots.) |

### Fastest kill test
The **2-hour spike**: (a) extract one module's + the Root hull's dogma map — is powergrid/base-stat data
there? (b) hand-author 3 module footprints and verify the polyomino engine places/rotates/collides
correctly. If (b) works (it will — classic logic) and (a) yields *either* dogma data *or* legible
screenshot values, the MVP is green.

## Exact files / repos likely touched (implementation phase — a NEW repo, not this one)
- **New repo** (e.g. `Diabolacal/rootfit` or a `fit.ef-map.com` Pages project): catalog JSON, engine
  (`engine/placement.ts`, `engine/power.ts`, `engine/stats.ts`, `engine/serialize.ts`), React UI
  (palette / grid editor / stats / power panes), share + fit-card, vendored `lib/industry/*`.
- **EF-Map (read-only here; tiny optional change later):** `tools/game-data-extractor/extract_ships.py`
  (extend to modules — run locally, commit results to the new repo's catalog, **not** to EF-Map);
  optionally `BlueprintCalculatorV5.tsx` `?item=&qty=` intake (separate, coordinated PR).
- **Overlay (later):** `src/shared/overlay_schema.hpp`, `src/overlay/overlay_renderer.cpp`,
  `src/helper/helper_server.cpp` for the `fit_plan` card + capability handshake.
- **This repo (`sui-playground`):** research docs only (this folder). No product code here.
