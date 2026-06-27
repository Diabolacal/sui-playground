# Operator Context — Fitting Tool & Overlay Feasibility (2026-06-27)

**Status:** Active research artifact. Captures the operator's directives, corrections to the prior
ideation pass, and the screenshot-derived facts about the in-game fitting UI. Everything downstream
in this folder is written to honor this file.

> This supersedes the relevant parts of
> [`../project-ideation-2026-06-27/`](../project-ideation-2026-06-27/README.md). Where the earlier
> ideation ranked an idea highly that the operator has since deprioritized, **this file wins.**

---

## 1. Corrections that supersede the prior ideation docs

These are explicit operator instructions given for this pass. They override the earlier shortlist.

| Prior idea (ideation pass) | New standing | Reason given |
|---|---|---|
| **Rift Watch** | **OUT for now.** Stop recommending it. | Operator already knows rift events are **not currently emitting**. On a Luminaire call the apparent intent was that when rift events *do* emit, coordinates will likely be **obfuscated** like other location data — so the "plaintext coords" premise the prior pass leaned on is not reliable. |
| **Patch Witness / Frontier Changelog** (prior #1) | **Deprioritize.** Do not lead with it. | Does not excite the operator. |
| **Blueprint permalink / share cards** | **Investigate only if it connects to fitting or overlay context handoff.** | Over-scored previously; EF-Map already has panel/permalink/share behavior. Not a standalone priority. |
| **Encrypted tribe brief packs** | **EXCLUDE.** | Operator does not like it. |
| **SSU Inventory Intelligence** (as a new standalone) | **Not wanted as a standalone project.** | EF-Map already has SSU Finder / player search / intel-adjacent surfaces; a new SSU dashboard drifts into existing EF-Map work. |
| **Frontier Facts / GPT-MCP connector** | **Deprioritize.** | Technically plausible, not exciting. |
| **Discord deep-link bot** | **Deprioritize.** | Technically plausible, not exciting. |

**Still excluded from the prior pass (unchanged):** generic marketplace, shared tribe storage,
turret projects. See [`../project-ideation-2026-06-27/prior-art-and-exclusions.md`](../project-ideation-2026-06-27/prior-art-and-exclusions.md).

## 2. The primary task this pass: an EVE Frontier **fitting tool**

The operator is **actively interested** in a robust ship-fitting / planning tool, inspired by the old
**"EFT Warrior"** culture from EVE Online — players theorycrafting fits *outside* the game before
buying/building modules. EVE Frontier now has a new modular fitting UI; the operator wants to **get
in early** with a strong planning/sharing tool before the fitting ecosystem gets crowded.

- **"EFT Warrior" is a cultural analogy, not the product name.** Avoid naming it "EFT" (confusion with
  EVE Online; possible trademark friction). Candidate names to explore: **Frontier Fitting, RootFit,
  Frontier Fit Lab, Shipwright, Frontier Workshop, Frontier Drydock, Fit Bench.**
- Treat the fitting tool as the **primary** deliverable. The overlay/helper audit is **secondary but
  important**, especially where it integrates with the fitting tool.
- **This is research/spec only.** No product build, no deploy in this pass. Small local throwaway
  inspection scripts are allowed; commit research docs only.

## 3. Helper / Microsoft Store constraint (changed from the prior pass)

- The operator is **willing to modify the actual EF-Map overlay/helper C++ code and resubmit to the
  Microsoft Store.** **Do not over-penalize** ideas because they need helper changes.
- Store resubmission is **acceptable**; if a submission fails review, the **existing Store version
  stays live**, so the downside is bounded.
- **Architecture guidance (because the game is alpha and keeps changing):** product logic should live
  in **EF-Map / web / data schemas**; the helper should be a **robust, generic renderer/bridge** with
  **versioned payloads** and **capability negotiation** — ignore unknown fields, avoid hardcoding
  fast-changing game data in C++.

## 4. Hard constraints for this pass

- Do **not** modify EF-Map, CivilizationControl, or ef-map-overlay repos — **read only** (they were
  cloned read-only to a scratch dir for inspection).
- Do **not** deploy anything; no Store build/submission in this task.
- Write durable artifacts only in `sui-playground`; preserve unrelated local dirt; stage only
  intended docs.
- **Overlay privacy line stays hard:** local logs only, loopback only, user-initiated actions,
  clipboard/display/opt-in. No memory reads, no gameplay automation, no credential access, nothing
  beyond the existing overlay/helper ToS model.

---

## 5. Screenshot-derived facts: the in-game Cycle 6 fitting UI

The operator provided three screenshots of the current in-game fitting screen for the single Cycle 6
hull (label like **"Creation #2S-00N6"**; the hull family is **"Root"**). These are the ground-truth
observations the fitting model is built on. (Screenshots were **not committed** to the repo.)

### 5.1 Top-level structure
- **One current-cycle hull.** The fitting UI shows a single ship/hull this cycle.
- **Three top tabs:** `POWER MANAGEMENT`, `INSTALL MODULES`, `FUEL`. (Plus `Tutorial` top-left,
  `Chat` top-right — game chrome, not fitting.)
- The **center** shows a dark, bilaterally-symmetric ship silhouette composed of discrete **sections**
  (a top spine/antenna, a central body, left & right wings, and two lower pods/legs). Empty hull
  sections are drawn with **red/amber outlines**; placed modules are drawn with **strong white
  outlines** over a fine grid.

### 5.2 Left stats pane (derived ship stats — the "output" the tool must reproduce)
Grouped exactly as in-game:

| Group | Stat | Example value | Unit | Notes |
|---|---|---|---|---|
| **Structure** | Volume | 1,000 | m³ | hull volume |
| | Mass | 21,000,160 | kg | constant across the 3 shots → includes fitted modules |
| | HP | 2,100 / 2,100 | HP | current / max, orange bar |
| | Inventory | 0 / 288 | m³ | current / max cargo capacity (8 cargo containers → 288 m³) |
| | Conductance | 0.6 | k | thermal (relevant to the new star-heat hazard) |
| | Specific Heat | 2.5 | C | thermal |
| **Propulsion** | Inertia Modifier | 0.2 | × | multiplier |
| | Maximum Velocity | 360.00 | m/sec | |
| | Ship Warp Speed | 0 | c | 0 ⇒ no warp module fitted |
| **Fuel & Energy** | Fuel Tank | 296.1 / 2,500 | units | current / max; **decreased across the 3 shots (296.1 → 293.5 → 289.4)** because fuel burns live |
| | Fuel Rate | 5.25 | Units/min | |
| | Fuel Impulse | 8 | % | |
| | Capacitor Recharge | 2.4 | GJ/s | |
| | Capacitor | 200.0 / 200.0 | GJ | current / max |

### 5.3 POWER MANAGEMENT tab (right pane)
- A **powergrid budget bar** at the top, e.g. **`0.7 / 15.0 MW`** (used / total). Most modules were
  offline in the shot, hence low usage.
- Modules listed by **category group**, each with an **online/offline toggle** (orange square) and a
  **`Powergrid Usage`** line where applicable (commonly `0.1 MW`):
  - **Command & Communication:** Passive Gravity Scanner (0.1 MW), Command Pod (0.1 MW)
  - **Weapons:** Weapon Receiver (0.1 MW) → *Small Cutting Laser*
  - **Engineering:** Hull Repairer (0.1 MW), Power Generator, **Fuel Bay ×5**, **Capacitor ×2**
  - **Storage & Crafting:** Mini Printer (0.1 MW), **Cargo Container ×8**, Material Processor (0.1 MW)
- ⇒ Power management is a per-module **online/offline** state plus a **powergrid capacity constraint**.
  Some modules (Fuel Bay, Cargo Container, Capacitor) appear to have **no MW line** — likely passive
  (always-on / no powergrid draw).

### 5.4 INSTALL MODULES tab
Two sub-tabs: **INTERIOR MODULES** and **EXTERIOR MODULES**. In the operator's shots both showed
**"NO ITEMS FOUND IN INVENTORY"** in the palette (nothing to install because inventory was empty),
which confirms: **you install modules from your inventory** onto the ship.

- **EXTERIOR MODULES → `HARDPOINT SLOTS`** list (exterior modules mount onto interior-provided
  hardpoints; slots are **numbered per type**):
  - `Passive Gravity Scanner #0` — **EMPTY**
  - `Propulsion Engine #0..#5` — **EXTERNAL THRUSTER** (six thruster hardpoints, all filled)
  - `Weapon Receiver #0` — **SMALL CUTTING LASER**
- **INTERIOR MODULES** are the polyomino blocks placed into the hull grid; **some interior modules
  provide the hardpoints** that exterior modules attach to (e.g. an interior *Propulsion Engine*
  receiver exposes an *External Thruster* hardpoint; a *Weapon Receiver* exposes the *Small Cutting
  Laser* hardpoint).

### 5.5 The placement ("fitting") interaction — polyomino / Tetris grammar
From the operator's description of manipulating the UI:
- Modules occupy **grid shapes** (polyominoes) inside the hull's internal space.
- Modules can be **picked up, placed, and rotated in 90° increments**.
- **No mirroring** was observed.
- Goal: **fit as much as possible** into the available internal space while keeping good stats.
- Approximate observed footprints (rough, to be calibrated): Cargo Container ≈ 2×3 rectangle; Fuel Bay
  ≈ long/narrow (~2×10); Capacitor ≈ small (~1×2); Mini Printer & Material Processor = larger
  irregular shapes; Propulsion-engine / thruster receivers have unique shapes. **Each module shape is
  strongly white-outlined**, which makes later screenshot recognition plausible.

### 5.6 Future direction (design for it now, don't build it yet)
- The current ship's **wings/sections are fixed** this cycle.
- In future, CCP may allow **different wings/sections** with different internal space, mass, and stat
  effects. **The tool's data model should support interchangeable hull sections/wing layouts now**, so
  the single-hull MVP extends cleanly later.

---

## 6. What "good" looks like for this pass
A grounded verdict on (a) whether a web fitting tool is viable now and what the strongest MVP is;
(b) whether the data exists or must be hand-authored; (c) whether the fitting tool should live in
EF-Map, standalone, or hybrid; (d) whether/which overlay work should be coupled; and (e) the single
recommended next implementation task with a kill test. See [`README.md`](README.md) for the verdict
and [`ranked-recommendations.md`](ranked-recommendations.md) for the ranking.
