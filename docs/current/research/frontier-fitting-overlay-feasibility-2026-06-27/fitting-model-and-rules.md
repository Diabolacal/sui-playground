# Fitting Model & Rules — EVE Frontier Fitting Tool (2026-06-27)

**Status:** Active research artifact (Workstream C). A concrete, implementable data model and the core
algorithms for a polyomino ship-fitting engine, plus the **known unknowns** (formulas that must be
calibrated against the live game). Built from the screenshot grammar in
[`operator-context.md` §5](operator-context.md); data availability is assessed in
[`data-source-audit.md`](data-source-audit.md).

> **Design principle (alpha-resilient):** the engine is **data-driven**. All ship/module/footprint
> facts live in a **versioned JSON catalog**, never hardcoded in app logic. When the game changes, we
> edit data, not code. Footprints and stat formulas that we cannot extract yet are **hand-authored
> and calibrated** against in-game values, and flagged with a confidence field.

---

## 1. Core concepts (from the in-game grammar)

- A **hull** has an internal **grid** (square cells). The grid is the union of one or more **sections**
  (today fixed: spine, body, two wings, two pods; future: swappable).
- **Interior modules** are **polyominoes** placed into the grid; they can be **rotated in 90° steps**
  (4 orientations, **no mirroring**) and must not overlap or exceed the hull mask.
- Some interior modules **provide hardpoints** (e.g. a *Propulsion Engine* receiver → an *External
  Thruster* hardpoint; a *Weapon Receiver* → a *Cutting Laser* hardpoint).
- **Exterior modules** **consume hardpoints**; they are not placed on the grid, they **mount** to a
  provided hardpoint slot (numbered per type: `Propulsion Engine #0..#5`, `Weapon Receiver #0`, …).
- **Power management:** each module has an **online/offline** state and a **powergrid usage (MW)**;
  total online usage must fit the hull's **powergrid capacity** (e.g. 15.0 MW). Some modules are
  passive (no draw).
- **Derived ship stats** (Volume, Mass, HP, Inventory, Conductance, Specific Heat, Inertia, Max
  Velocity, Warp Speed, Fuel Tank, Fuel Rate, Fuel Impulse, Capacitor, Capacitor Recharge) are
  computed from the hull base + the fitted modules (+ online state).

## 2. Data model (TypeScript-flavored schema)

```ts
// ---------- Catalog (versioned, data-driven) ----------
interface Catalog {
  schemaVersion: string;            // e.g. "fit-catalog/1"
  gameVersion: string;              // e.g. "cycle6" / patch tag — for diffing & churn tracking
  cellSize: number;                 // grid cell edge in UI units (for rendering only)
  hulls: Hull[];
  modules: ModuleDef[];
  stats: StatDef[];                 // declares units, display order, aggregation rule per stat
}

interface Hull {
  id: string;                       // "root"
  name: string;                     // "Root"
  sections: HullSection[];          // composed grid; today fixed, future swappable
  base: Record<StatId, number>;     // base stat values before modules (e.g. baseMass, powergridMW)
  powergridCapacityMW: number;      // e.g. 15.0
  confidence: "extracted" | "authored" | "estimated";
}

interface HullSection {
  id: string;                       // "left-wing"
  origin: [number, number];         // section's offset within the global grid
  mask: Cell[];                     // cells this section contributes (relative to origin)
  base?: Partial<Record<StatId, number>>;  // section-level stat/mass contribution (future swap)
  swappable?: boolean;              // false this cycle; reserved for future wing variants
}

type Cell = [number, number];       // [col, row] integer grid coordinate

interface ModuleDef {
  typeId: number;                   // opaque game type id (see data-source-audit)
  name: string;                     // "Cargo Container"
  group: string;                    // "Storage & Crafting" (matches in-game category)
  kind: "interior" | "exterior";
  footprint: Cell[];                // polyomino cells in canonical orientation (interior only)
  allowedRotations?: 0|90|180|270[];// default [0,90,180,270]; some modules may be fixed
  providesHardpoints?: HardpointGrant[];  // interior modules that expose mounts
  consumesHardpoint?: HardpointType;      // exterior modules
  powergridUsageMW: number;         // 0 for passive
  passive: boolean;                 // true => always-on, not power-gated
  onlineable: boolean;              // can be toggled online/offline
  mass: number;                     // kg
  volume: number;                   // m3 (the module's own size, for build/inventory)
  modifiers: StatModifier[];        // how it changes ship stats when fitted/online
  maxFitted?: number;               // e.g. Command Pod limited to 1 (if such caps exist)
  confidence: "extracted" | "authored" | "estimated";
}

type HardpointType = "external_thruster" | "cutting_laser" | "gravity_scanner" | string;
interface HardpointGrant { type: HardpointType; count: number; }

interface StatModifier {
  stat: StatId;                     // "inventoryM3", "fuelCapacity", "maxVelocity", ...
  op: "add" | "mul" | "max" | "min";
  value: number;
  appliesWhen: "fitted" | "online"; // some effects only when powered
}

// ---------- A saved fit ----------
interface Fit {
  schemaVersion: string;            // "fit/1" — for share-code forward-compat
  catalogVersion: string;          // pins which catalog/gameVersion it was built against
  hullId: string;
  sectionLayout?: Record<string,string>; // slot->sectionVariantId (future; omit this cycle)
  placements: Placement[];          // interior modules on the grid
  mounts: Mount[];                  // exterior modules on hardpoints
  online: Record<string, boolean>;  // instanceId -> online
  meta?: { name?: string; author?: string; note?: string };
}

interface Placement { instanceId: string; typeId: number; origin: Cell; rotation: 0|90|180|270; }
interface Mount     { instanceId: string; typeId: number; hardpoint: { type: HardpointType; index: number }; }
```

## 3. Core algorithms

### 3.1 Polyomino rotation (no mirroring)
Rotate each footprint cell `(c, r)` by 90° clockwise: `(c, r) -> (r, -c)`, then **normalize** by
translating so the min col/row is 0. Precompute all allowed orientations once per module. Reflection
is **never** generated (matches "no mirroring observed").

### 3.2 Occupancy & collision
Maintain an occupancy set of grid cells. To place a module at `origin` with `rotation`:
1. Compute world cells = `orientation(rotation) + origin`.
2. **Hull-mask validity:** every world cell ∈ `hullMask` (union of section masks). Else invalid.
3. **Collision:** no world cell ∈ occupancy. Else invalid.
4. On commit, add cells to occupancy; on remove, subtract. O(cells-per-module); trivially fast.

### 3.3 Hardpoint validation
- Budget per type = Σ `providesHardpoints[type].count` over fitted **interior** modules.
- Demand per type = count of fitted **exterior** modules with `consumesHardpoint == type`.
- Valid iff `demand[type] ≤ budget[type]` for all types. (MVP uses a **type-count budget**; a later
  version can bind each mount to a specific provider instance/slot index, matching the numbered
  `#0..#5` UI.)

### 3.4 Online/offline + powergrid
- `usedMW = Σ powergridUsageMW for modules where online && !passive`.
- Valid iff `usedMW ≤ hull.powergridCapacityMW`.
- Toggling a module online is rejected if it would exceed capacity (UI surfaces the overflow, mirrors
  the in-game `used / total MW` bar).
- Passive modules (Fuel Bay, Cargo Container, Capacitor appeared to have no MW line) are always
  counted as fitted but never draw power.

### 3.5 Stat recomputation
For each declared `StatDef`, fold the hull base + all applicable `StatModifier`s in declared order:
```
value(stat) = base(stat)
for each fitted module, for each modifier on `stat` whose `appliesWhen` is satisfied:
    apply modifier.op (add/mul/max/min)
```
- **Mass** = hull base mass + Σ module mass (modules contribute mass whether online or not — matches
  constant 21,000,160 kg across the screenshots).
- **Inventory (m³)**, **Fuel Tank**, **Capacitor**, **HP** = base + Σ additive module contributions.
- **Max Velocity / Inertia / Warp / recharge / fuel rate** = **formula unknown** (see §5).
- Recompute is pure and cheap; run on every edit; memoize by fit hash.

### 3.6 Serialization & share codes
- Canonical form: `Fit` JSON.
- **Share code:** pack `(hullId, [typeId, originCol, originRow, rotation, online]...)` into a compact
  binary, base64url it, prefix with a 1-byte schema version → a short **"fit code"** embeddable in a
  URL (`?fit=...`) or pasted in Discord. Use a stable typeId→index table from the catalog to shrink it.
- Alternatively reuse EF-Map's `/api/create-share` short-link service (see
  [`ef-map-integration-plan.md`](ef-map-integration-plan.md)) so a fit becomes `ef-map.com/f/<id>`.
- **Forward-compat:** decoders ignore unknown trailing fields; the `catalogVersion` lets the UI warn
  "this fit was built on an older catalog" when the game data has since changed.

## 4. Future wing/section extensibility (design now, ship single-hull)
The hull is **already** modeled as a composition of `HullSection`s with per-section grid masks and
optional stat/mass contributions. To support future swappable wings:
- Mark sections `swappable: true` and add `sectionVariants` to the catalog.
- A fit records its chosen variant per swappable slot in `sectionLayout`.
- The placement engine is unchanged — it always operates on the **composed global mask**, so swapping
  a wing simply recomposes the mask and re-validates existing placements (flagging any now-invalid).
This means the single-hull MVP is a strict special case (one fixed section layout) of the general
model — no rework when CCP ships variant sections.

## 5. Known unknowns (must be calibrated against the live game)
These cannot be derived from screenshots alone; flag each as `estimated` until calibrated.

| Unknown | What we don't know | Calibration method |
|---|---|---|
| **Footprint shapes** | Exact cell masks per module (only rough sizes observed) | Author from the grid screenshots; refine by single-module placement in-game |
| **Max Velocity / Inertia formula** | How mass + thrusters → velocity/inertia | **Single-module delta testing:** add/remove one thruster in-game, record the stat delta; fit the curve |
| **Capacitor recharge / Fuel rate** | Aggregation across capacitors / fuel bays | Same delta-testing per module |
| **Conductance / Specific Heat** | How thermal stats aggregate (relevant to star-heat) | Delta-testing; may be hull-only |
| **Warp speed** | Requires a warp module not present in the sample fit | Observe once a warp module exists |
| **Adjacency bonuses** | Whether placement adjacency changes stats (none observed) | Assume **none** for MVP; revisit if deltas don't match |
| **Second fitting resource** | Whether there's a CPU-like resource besides powergrid (only MW observed) | Watch for a second budget bar in future patches |
| **Module caps / exclusivity** | Whether some modules are limited (e.g. one Command Pod) | Observe in-game; encode as `maxFitted` |

## 6. Verification protocol (how we know the engine is right)
1. **Oracle fits:** reproduce the operator's screenshot fit(s) exactly (same module set + online
   state) and assert the tool's derived stats match the in-game left pane within tolerance.
2. **Single-module deltas:** maintain a small calibration log — for each module, the measured stat
   delta from adding it — and unit-test the engine against that log.
3. **Regression on catalog bumps:** when the catalog's `gameVersion` changes, re-run the oracle fits;
   surface any stat that no longer matches (this doubles as a "what changed this patch" signal).
4. **Property tests:** placement never overlaps; rotation is involutive×4; powergrid never exceeds
   capacity in a valid fit; serialize→deserialize is identity.

## 7. What this means for the MVP
The **placement/collision/hardpoint/powergrid** layer is fully specifiable **today** from the
screenshots and is low-risk classic polyomino logic. The **stat formulas** are the genuine unknown —
but the MVP can ship with **additive stats correct** (mass, inventory, fuel, capacitor, HP, powergrid)
and **velocity/inertia/warp marked "estimated"** until calibrated, which is honest and still useful
for planning *what fits* and *what it costs to build*. See [`product-ux-spec.md`](product-ux-spec.md).
