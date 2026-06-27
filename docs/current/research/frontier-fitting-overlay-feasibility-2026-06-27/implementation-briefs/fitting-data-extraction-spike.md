# Implementation Brief — Fitting Data-Extraction Spike

**Status:** Brief for a future build pass (not built here). **This is milestone 0 of the Fitting MVP —
the fastest way to de-risk the whole product.** Effort: ~2–4 hours.

## Goal
Determine, from the actual game data, which fitting stats are available for Cycle 6 **modules** and the
**Root hull** — specifically **module powergrid usage** and the hull's **base stats** (HP, max velocity,
warp speed, capacitor, powergrid capacity, inertia, conductance, fuel rate/impulse).

## Why first
[`../data-source-audit.md`](../data-source-audit.md) shows module identity/mass/volume/recipe are
already free, the dogma layer *should* hold powergrid + base stats, and the footprint shapes are *not*
in data. This spike confirms the dogma half in one run, so the MVP knows exactly what it must
hand-author vs read.

## Steps
1. **Environment:** Python 3.12 (exact), EVE Frontier client installed, `code.ccp`/bin64 on path
   (prereqs already documented in EF-Map's `tools/game-data-extractor/`).
2. **Run the existing extractor** `tools/game-data-extractor/extract_ships.py` to confirm the FSD/dogma
   pipeline still loads on the current client (the repo documents 87/87 loaders @ 100% on May 2026).
3. **Extend it** to iterate the 16 module typeIDs (95302–95503, +81846) and **dump each module's full
   `typeDogma` attribute map** (attributeID→value), cross-referenced to `dogmaAttributes` names.
4. **Find the Root hull typeID** (not in `blueprint_data_v5` or the extractor's known-ship list; likely
   unpublished) and dump its full dogma map too.
5. **Look specifically for:** a per-module **powergrid-usage** attribute (reproduces the in-game
   `0.1 MW` lines); hull **powergrid capacity** (~15 MW), **HP** (~2100), **max velocity** (~360),
   **capacitor** (~200 GJ); and any new attribute names matching **conductance / inertia / fuel
   impulse / fuel rate**.

## Output
- A JSON dump (committed to the **new fitting repo's** `/catalog/`, *not* to EF-Map) keyed by typeID →
  named dogma attributes.
- A short note: which fitting stats are dogma-backed vs absent, and the resolved Root hull typeID.

## Kill / decision criteria
- **Green:** module powergrid + hull base stats are present (or cleanly derivable) → the stats pane and
  power management are **data-backed**.
- **Amber:** powergrid usage absent but small/legible in screenshots → **hand-author** the `0.1 MW`-style
  values (tiny set); proceed.
- **Red (unlikely):** the client no longer loads via Phobos *and* screenshots are insufficient → fall
  back to fully hand-authored stats from the in-game UI (still feasible for one hull + 16 modules).

## Constraints
Local-only inspection; do **not** commit extraction output or scripts into EF-Map; respect that the
client files are not redistributable.
