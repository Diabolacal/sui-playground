# Product / UX Spec — Frontier Fitting Tool (2026-06-27)

**Status:** Active research artifact (Workstream D). The MVP product and UI for a web-based EVE
Frontier ship-fitting tool. Reads with [`fitting-model-and-rules.md`](fitting-model-and-rules.md)
(engine), [`ef-map-integration-plan.md`](ef-map-integration-plan.md) (where it lives / what it
reuses), and [`screenshot-import-feasibility.md`](screenshot-import-feasibility.md) (import, post-MVP).

> **Home (from Workstream F):** a **standalone web app** (e.g. `fit.ef-map.com`, its own Cloudflare
> Pages project) that **reuses EF-Map's public data assets, CSS tokens, and short-link service** —
> *not* a panel inside EF-Map's ~18k-line app. Hybrid by data, standalone by deployment.

---

## 1. Product in one line
**A fast, shareable, browser-based ship planner for EVE Frontier** — lay out modules on the Root
hull's grid, manage power, see live ship stats, and share the fit as a link or a card, *before* you
spend materials building it in-game.

### Target users
- **Theorycrafters** ("EFT warriors") who enjoy optimizing fits outside the game.
- **New/returning Cycle 6 players** trying to understand the single-hull fitting system.
- **Tribes** sharing recommended fits and "build this" plans in Discord.

### Why now
The fitting system is new and simple (one hull, one weapon, a clean module set) — small enough to
model fully today, and **first-mover** before the ecosystem gets complex. (See
[`operator-context.md` §2](operator-context.md).)

## 2. MVP scope (what ships first)
1. **Single hull (Root)** loaded from a versioned catalog.
2. **Module palette** → **grid editor** with drag / drop / rotate / collision / hull-mask validity.
3. **Hardpoint mounting** for exterior modules (thrusters, cutting laser, scanner).
4. **Power management:** online/offline toggles + powergrid budget bar.
5. **Live stats pane** reproducing the in-game left panel (additive stats exact; velocity/inertia/warp
   shown as **"estimated"** until calibrated — honest, still useful).
6. **Save / load / share** a fit via URL fit-code (and optional `ef-map.com/s/<id>` short link).
7. **Fit card** export (PNG) for Discord.

**Non-goals for MVP:** screenshot import (post-MVP, [`screenshot-import-feasibility.md`](screenshot-import-feasibility.md));
multiple hulls (none exist yet); on-chain/wallet anything; overlay push (fast follow, not MVP);
account system (fits live in URL/localStorage).

## 3. Screen layout — mirror the game, improve the planning
A three-column layout that is **familiar to anyone who has seen the in-game screen**, then adds
planning affordances the game lacks (compare, share, what-if).

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  ROOTFIT     [ LAYOUT ]  [ POWER ]  [ FUEL ]            Fit: "Hauler v2"  �myfits │  top tabs mirror game
├───────────────┬──────────────────────────────────────┬─────────────────────────┤
│  SHIP STATS   │            GRID EDITOR               │   MODULE PALETTE         │
│ (left pane)   │  (center: hull sections + grid)      │  (right pane)            │
│               │                                      │                          │
│ STRUCTURE     │   ┌──┐        ┌────────┐             │  search ____             │
│  Volume  1,000│   │  │spine   │ body   │             │  ▸ Command & Comms       │
│  Mass  21.0M  │   └──┘        └────────┘             │  ▸ Weapons               │
│  HP   2100/2100  ┌─────┐  ┌──┐  ┌─────┐              │  ▸ Engineering           │
│  Inventory 0/288 │L-wing│ pods │R-wing│              │    · Power Generator     │
│  Conductance .6  └─────┘  └──┘  └─────┘              │    · Fuel Bay   [2×10]    │
│ PROPULSION    │   (drag a module here; ghost shows   │    · Capacitor  [1×2]    │
│  Inertia 0.2x │    valid=green / invalid=red; R=rot) │  ▸ Storage & Crafting    │
│  Max Vel 360  │                                      │    · Cargo Container[2×3] │
│ FUEL & ENERGY │   Powergrid ▓▓░░░░░░ 0.7 / 15.0 MW   │    · Mini Printer        │
│  Fuel  296/2500                                      │  drag onto grid ↑         │
│  Capacitor 200│   [ Fit code: rXf… ]  [Share] [Card] │  (greyed if won't fit)    │
└───────────────┴──────────────────────────────────────┴─────────────────────────┘
```

### 3.1 Top tabs (mirror the game)
`LAYOUT` (= Install Modules), `POWER` (= Power Management), `FUEL`. MVP focuses on `LAYOUT` + `POWER`;
`FUEL` shows the fuel-runway readout (capacity ÷ rate → minutes of burn). Plain-text tabs with an
underline on the active one, matching the in-game treatment.

### 3.2 Left — Ship Stats pane
Reproduces the in-game groups exactly (Structure / Propulsion / Fuel & Energy), right-aligned value
columns, monospace numerics. Each stat row shows a **delta-on-hover**: hovering a palette/placed
module previews how that module changes each stat (the planning superpower the game lacks). Estimated
stats get a subtle `~` and a tooltip ("formula not yet calibrated — see methodology").

### 3.3 Center — Grid editor
- Renders the hull as its **sections** (spine, body, wings, pods) composing one grid; empty cells
  hairline-outlined, the hull mask boundary in the amber accent.
- **Drag** a module from the palette → a **ghost** follows the cursor snapped to cells; **green** when
  placement is valid, **red** when it overlaps or leaves the mask. **`R` rotates** 90° (no mirror).
- Placed modules render as filled polyominoes with the module icon; click to select, `Del` to remove,
  drag to move. Right-click → online/offline.
- **Hardpoints:** interior modules that provide hardpoints show small mount badges; exterior modules
  are assigned to a numbered slot (`Propulsion Engine #0..#5`, `Weapon Receiver #0`) via a compact
  hardpoint list below the grid (mirrors the in-game `HARDPOINT SLOTS`).
- **Powergrid bar** under the grid, `used / total MW`, turns amber→red on overflow.

### 3.4 Right — Module palette
- Grouped by the in-game categories; search box; each entry shows name, footprint size badge (e.g.
  `2×3`), and MW cost. Modules that **can't currently fit** (no room / no hardpoint / would overflow
  power) are greyed with a reason tooltip. Click-to-add (auto-place in first valid spot) or drag.

## 4. Share / export
- **Fit code in URL:** every edit updates `?fit=<code>` (see serialization in
  [`fitting-model-and-rules.md` §3.6](fitting-model-and-rules.md)); copy-link button. Opening a link
  rebuilds the exact fit. Works with zero backend.
- **Short link (optional):** `POST ef-map.com/api/create-share` → `ef-map.com/s/<id>` (reuses EF-Map's
  KV short-link service; needs a one-line Worker prefix allowance — see
  [`ef-map-integration-plan.md`](ef-map-integration-plan.md)).
- **Fit card (PNG):** a Discord-friendly card — hull name, module list grouped by category, key stats,
  powergrid used/total, fuel runway, and a small grid thumbnail. Reuse EF-Map's canvas build-sheet
  renderer pattern (`utils/blueprintBuildSheet*.ts`).
- **Build this fit:** a button that hands the fit's module **build inputs** to EF-Map's Blueprint
  Calculator (`?item=<typeID>&qty=<n>`) or runs the industry planner **inline** (the planner is pure
  TS with no React deps) — turning a fit into a shopping list. (Detail in the integration plan.)

## 5. Mobile / tablet
- **Tablet (landscape):** the 3-column layout holds; drag/drop works with touch; primary planning use.
- **Phone:** the grid editor is cramped for drag/drop, so phone is **view/share-first** — a fit opened
  on a phone shows the **stats + module list + fit card** (read-only), with editing possible but
  secondary (tap-to-place from a bottom sheet). Don't gate sharing on a desktop.
- Build with a responsive CSS grid; the editor uses pointer events (mouse+touch) from day one.

## 6. Visual direction (from the in-game screenshots)
Match the EVE Frontier fitting screen so the tool feels native (full token set in
[`overlay-visual-redesign.md`](overlay-visual-redesign.md), shared with the overlay):
- **Near-black** translucent surfaces; content floats on darkness with lots of negative space.
- **Hairline** rules in white at low opacity; a single **amber/orange accent** for active/selected/
  warnings and the hull boundary.
- **Compact, technical type:** a clean sans for labels, a **monospace for all numeric columns**;
  **small-caps section headers** (`STRUCTURE`, `PROPULSION`, `FUEL & ENERGY`).
- **Right-aligned value columns**, current/max rendered as `value / max` with a thin bar where the
  game shows one (HP, Fuel, Capacitor, Powergrid).
- **Restrained motion:** snap/placement feedback only; no decorative animation. High contrast,
  readable at 1440p and 4K. Reuse EF-Map's `App.css :root` tokens as the base palette.

## 7. What makes it better than the in-game screen (the reason to leave the game to use it)
1. **Plan without owning the modules** — build any fit from the full catalog, no inventory needed.
2. **Hover-deltas & compare** — see exactly what each module costs/adds; compare two fits side by side.
3. **Shareable** — a fit is a link and a card; tribes can standardize fits in Discord.
4. **Build-cost** — one click turns a fit into a materials shopping list via the Blueprint Calculator.
5. **Stable workspace** — name/save multiple fits; doesn't burn fuel while you think (the game does).
