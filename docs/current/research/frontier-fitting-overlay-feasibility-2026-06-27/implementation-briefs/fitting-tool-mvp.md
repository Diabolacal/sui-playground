# Implementation Brief — Frontier Fitting MVP

**Status:** Brief for a future build pass (not built here). Companion to
[`../recommended-next-build.md`](../recommended-next-build.md) — this is the engineering checklist.

## Goal
A standalone web app (`fit.ef-map.com`) to plan a Cycle 6 Root-hull fit: place modules on the grid,
manage power, see stats, share the fit.

## Stack
React + TypeScript + Vite, own Cloudflare Pages project. **No Three.js.** Pointer events (mouse+touch).
State in URL (`?fit=`) + `localStorage`. Optional Pages Worker only as a thin proxy if needed.

## Workplan
1. **Catalog assembly** (`/catalog/cycle6.json`, schema `fit-catalog/1`):
   - Fetch `https://ef-map.com/blueprint_data_v5.json`; pull the 16 `categoryName:"Module"` items
     (typeIDs 95302–95503, +81846) → name, mass, volume, recipe.
   - Merge **extraction-spike output** (module powergrid usage; Root hull base stats) — see
     [`fitting-data-extraction-spike.md`](fitting-data-extraction-spike.md).
   - **Hand-author**: footprint cells, `kind` (interior/exterior), `providesHardpoints`/
     `consumesHardpoint`, UI category, `passive`, with `confidence` flags. (Geometry from screenshots.)
2. **Engine** (pure TS, unit-tested) per [`../fitting-model-and-rules.md`](../fitting-model-and-rules.md):
   `engine/polyomino.ts` (rotate/normalize), `engine/placement.ts` (occupancy/collision/hull-mask),
   `engine/hardpoints.ts` (budget vs demand), `engine/power.ts` (online + powergrid), `engine/stats.ts`
   (additive fold + estimated formulas), `engine/serialize.ts` (`?fit=` code + share).
3. **UI** (3-column, [`../product-ux-spec.md`](../product-ux-spec.md)): left stats pane · center grid
   editor (drag/drop/ghost/`R` rotate/hardpoint list/powergrid bar) · right palette (grouped, search,
   fit/no-fit greying). Top tabs LAYOUT/POWER/FUEL.
4. **Share/export:** `?fit=` round-trip; `POST ef-map.com/api/create-share` (prefix `r3|`) → `/s/<id>`;
   PNG fit-card (mirror `blueprintBuildSheetRenderer.ts`).
5. **Build-this-fit:** vendor `lib/industry/*`; aggregate module recipes → shopping list inline.
6. **Theme:** copy EF-Map `App.css :root` tokens; small-caps headers; mono numeric columns.

## Acceptance / smoke
- Reproduce the operator's screenshot fit → additive stats (mass/inventory/fuel/capacitor/powergrid)
  match the in-game left pane.
- Property tests: no overlap; rotation involutive ×4; powergrid ≤ capacity; serialize↔deserialize id.
- Share code rebuilds the fit; `/s/<id>` resolves; cross-origin fetch + POST work from the standalone
  origin in a real browser.

## Definition of done (MVP)
Single Root hull, all 16 modules placeable with correct collision/hardpoint/power rules, additive stats
exact, velocity/inertia/warp shown "estimated," shareable link + fit-card, "build this fit" list.

## Out of scope
Screenshot import; multiple hulls; wallet/on-chain; overlay push; accounts.
