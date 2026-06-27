# Open Questions — Fitting Tool & Overlay Feasibility

**Status:** Active research artifact. Things to confirm before/while building. None block starting the
2-hour spike.

## Data (resolve via the extraction spike — [`implementation-briefs/fitting-data-extraction-spike.md`](implementation-briefs/fitting-data-extraction-spike.md))
1. **Root hull typeID?** Not in `blueprint_data_v5` or the extractor's known-ship list — likely
   unpublished. Needed for ship base stats.
2. **Module powergrid usage in dogma?** Does each module carry a powergrid-usage attribute that
   reproduces the in-game `0.1 MW` lines — or must we hand-author them?
3. **New Cycle 6 stats** (Conductance, Fuel Impulse, Fuel Rate, Inertia): are these named dogma
   attributes, **unnamed** new attribute IDs (the 10% path), or UI-only (hand-author)?
4. **Second fitting resource?** Only powergrid (MW) was visible — is there a CPU-like second budget?

## Geometry (the hand-authored gap)
5. **Footprint precision:** the rough sizes (Cargo ~2×3, Fuel Bay ~2×10, Capacitor ~1×2) need exact
   cell masks. Author from screenshots, then verify by single-module placement in-game. Is the operator
   able to capture a few extra screenshots (one module placed at a time) to calibrate?
6. **Hull mask:** the Root's grid is a union of fixed sections (spine/body/wings/pods). Confirm the
   exact cell layout — is a clean top-down grid screenshot available (the INTERIOR MODULES view)?
7. **Hardpoint binding:** is the `#0..#5` numbering meaningful (specific provider→slot), or just a count
   per type? MVP uses a type-count budget; confirm whether exact slot binding matters.

## Stat formulas (calibration)
8. Can the operator run **single-module delta tests** (add/remove one thruster/capacitor/fuel bay and
   record the stat change) so velocity/inertia/capacitor-recharge/fuel-rate formulas can be fit? This is
   how the "estimated" stats become exact.

## Product / home
9. **Name:** RootFit (recommended) vs Frontier Fitting / Shipwright / Frontier Drydock?
10. **Domain:** confirm `fit.ef-map.com` (own Pages project) is acceptable, and that reusing the EF-Map
    short-link service (an `r3|`-prefixed payload, zero EF-Map change) is fine.
11. **Asset-version cadence:** who watches for `blueprint_data_v6.json` so the tool doesn't break on the
    next schema bump? (EF-Map decision log / `versionInfo.json`.)

## Overlay
12. **Scope/sequencing:** ship the **generic payload + capability handshake + visual Phase 1** as one
    batched Store submission in parallel with the fitting MVP — or wait until the MVP is live and do the
    `fit_plan` handoff in one go? (Recommendation: batch the foundation + visual refresh now; do the
    `fit_plan` card after the MVP.)
13. **Store cadence tolerance:** comfortable with 1–3 day cert turnarounds per C++ change, batching to
    minimize submissions?

## Validation
14. **Community sentiment** (carried over from the prior pass): the web scan couldn't reach Discord —
    is there real appetite for an external fitting planner, and is anyone already building one? A quick
    community check before the weekend MVP would de-risk the product bet.
