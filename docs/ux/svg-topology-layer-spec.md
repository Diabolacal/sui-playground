# CivilizationControl — SVG Topology Layer Design Specification

**Retention:** Carry-forward

> Canonical design specification for the Strategic Network Map symbol grammar, state system, color doctrine, motion protocol, and layout rules.
> Sources: UX Architecture Spec §9, Spatial Embed Requirements, Demo Beat Sheet v2, Product Vision, Voice & Narrative Guide, Hackathon Emotional Objective.
> Validated against: ISA-101 HMI design principles, IEC 60073 color coding, MIL-STD-2525D/APP-6(D) symbology, EEMUA 191 alarm management, High Performance HMI (Hollifield/Habibi), Gestalt perceptual principles.
> Last updated: 2026-03-03

---

## Table of Contents

1. [Purpose & Scope](#1-purpose--scope)
2. [Symbol Grammar](#2-symbol-grammar)
3. [State System](#3-state-system)
4. [Color Semantics Doctrine](#4-color-semantics-doctrine)
5. [Motion Doctrine & Demo Timing](#5-motion-doctrine--demo-timing)
6. [Layout & Stacking Rules](#6-layout--stacking-rules)
7. [Export & Naming Conventions](#7-export--naming-conventions)
8. [Why This Is Not Arbitrary](#8-why-this-is-not-arbitrary)
9. [Do Not List](#9-do-not-list)
10. [Demo Beat Alignment Matrix](#10-demo-beat-alignment-matrix)
11. [Accessibility](#11-accessibility)
12. [References](#12-references)

---

## 1. Purpose & Scope

The Strategic Network Map is a **governance topology schematic** — not a star map, not a game HUD, not a spatial simulator. It renders an operator's owned infrastructure as a network graph where:

- **Nodes** represent structures (Network Nodes, Gates, Trade Posts)
- **Edges** represent gate links (passage corridors between linked gate pairs)
- **State overlays** encode runtime condition (online, offline, armed, Revenue event, etc.)
- **Layout** is operator-curated (manual spatial pins), not coordinate-derived

This spec defines the complete visual language for this schematic. All implementation must conform to this document. Where this spec and the UX Architecture Spec §9 overlap, this document is canonical for visual language; the UX spec remains canonical for interaction patterns and screen hierarchy.

### Design Thesis

Authority comes from **coherence and restraint**, not visual complexity. The schematic must read as a control surface — something an operator monitors and acts on — not a decoration. Every visual element must either (a) encode a discrete piece of governance state or (b) provide structural context for the network topology. Elements that do neither are excluded.

### Relationship to Other Spatial Layers

| Layer | Role | This Spec Covers |
|---|---|---|
| **Strategic Network Map** (SVG) | Primary operational governance topology | **YES** — all visual language defined here |
| **Cosmic Context Map** (EF-Map embed) | Secondary orientational grounding in EVE Frontier universe | **NO** — governed by EF-Map embed parameters; see [Spatial Embed Requirements](../architecture/spatial-embed-requirements.md) |

---

## 2. Symbol Grammar

### 2.1 Base Grid

All glyphs are designed on a **24×24 unit grid**. Stroke-based (outline), not filled. The 24-unit grid scales cleanly to display sizes: 24px (compact list), 32px (standard), 48px (detail/hover), 64px (hero/expanded).

Glyphs occupy the **center 20×20 units** of the grid, leaving 2 units of padding on each side for state overlays (halos, badges, pips).

### 2.2 Structure Glyphs

| Structure | Shape | Geometry (24×24 grid) | Semantic Rationale |
|---|---|---|---|
| **Network Node** | Hexagon outline + center core dot | Regular hexagon, vertices at 12 o'clock, inscribed in 18×18 area centered in grid. Core dot: 3-unit diameter, centered | Engineered anchor. Hexagons connote infrastructure hubs (cell networks, crystalline lattice, honeycomb routing). Six-fold symmetry implies structural stability + regularity. The core dot distinguishes from empty hexagon and gives the glyph a "reactor" or "power source" read. |
| **Gate** | Ring with aperture notch | Circle, 16-unit diameter, 2-unit stroke, centered. Two symmetric 15° notches at 3 o'clock and 9 o'clock positions (indicating passage axis) | Portal / passage point. The ring reads as a cross-section of a tunnel or wormhole. The aperture notches (small gaps in the stroke at the horizontal axis) shift the semantics from "generic node" to "passage" without adding complexity. At 24px the notches are subtle but perceptible; at 48px+ they become clearly directional. |
| **Turret** | Equilateral triangle (pointing outward) | Equilateral triangle, 16-unit side length, centered. Default orientation: apex pointing up (12 o'clock). When attached to a Network Node, apex rotates to point outward (radially away from the node center) | Directional defense / weapon projection. Triangles are universally associated with warning, directivity, and threat vectors. Outward orientation relative to the parent node communicates "defending this position." This mirrors NATO APP-6(D) where triangles in the icon set represent directional projection (air defense dome, artillery). |
| **Trade Post (SSU)** | Square outline with inner square | Outer square: 16×16 units, 2-unit stroke, centered. Inner square: 8×8 units, 1-unit stroke, centered (concentric) | Container / storage / commerce. Squares are the universal glyph for buildings, warehouses, and logistics nodes in network and SCADA diagrams. The inner square (box-in-box) adds the "inventory" semantic — something is stored inside. Visually distinct from all other glyphs at any size. |

### 2.3 Shape Distinctness Analysis

These four shapes were selected for **maximum perceptual separation** at small sizes, following Gestalt principles of similarity and prägnanz (simplicity):

| Pair | Distinguishing Feature | Min Legible Size |
|---|---|---|
| Hexagon vs. Circle (Gate ring) | Hexagon has 6 visible vertices breaking the circular silhouette; Gate ring has aperture gaps | 16px |
| Triangle vs. all others | Unique pointed silhouette; only glyph with a single apex | 12px |
| Square vs. Hexagon | 4 corners vs. 6 with wider profile; fundamentally different silhouette | 16px |
| Square vs. Circle | Corners vs. smooth curve; maximally different basic topology | 12px |

At 24px (minimum operational size), all four shapes are unambiguously distinguishable by silhouette alone, even without color. This passes the **monochrome legibility test** — a requirement derived from MIL-STD-2525D, which mandates that symbology remain interpretable on monochrome displays.

### 2.4 Glyph Rendering Rules

- **Stroke only.** Base glyphs are outlines. No fills on the glyph area itself in the neutral state. (State fills are applied as overlays — see §3.)
- **Neutral stroke color:** `--glyph-neutral` (muted mid-gray, e.g., `hsl(210, 8%, 55%)`). Not white (too bright), not dark gray (disappears on dark backgrounds).
- **Stroke width:** 2 units at the 24-unit grid scale. At rendering size, this equals ~2px at 24px display, ~2.67px at 32px, etc. Minimum rendered stroke: 1.5px.
- **No gradients.** No fills inside glyphs. No drop shadows on glyphs. No glow on glyphs in neutral state.
- **Corner radius:** 0 (sharp corners) for Square and Triangle. Hexagon vertices are sharp. Gate ring is smooth (circle).
- **Pixel alignment:** All coordinates snap to half-pixel boundaries at the target render size to prevent anti-aliasing blur.

### 2.5 Link Lines

Links connect **Gate-to-Gate pairs** (linked gates) and **Structure-to-NetworkNode** (anchor relationships).

| Link Type | Line Style (neutral) | Semantic |
|---|---|---|
| **Gate pair link** | Solid line, 2px, `--link-neutral` color | Active passage corridor between two linked gates |
| **Structure-to-Node anchor** | Dotted line, 1px, `--link-subdued` color | Structural dependency (gate/turret/SSU anchored to a network node) |

- Link lines connect center-to-center of the respective glyphs.
- Link lines route behind (z-order below) all glyphs and state overlays.
- No arrowheads on links in neutral state. Directional indicators are a P3 stretch feature (see [Spatial Embed Requirements §3](../architecture/spatial-embed-requirements.md)).

---

## 3. State System

### 3.1 Principle: State as Overlay, Not Mutation

The base glyph geometry **never changes** based on runtime state. State is communicated through a layered overlay system applied on top of the neutral glyph. This follows the High Performance HMI principle: **gray infrastructure, colored exceptions**. The operator's eye is drawn to deviations from neutral, not to a saturated baseline.

This is the same compositional pattern used in MIL-STD-2525D: the frame shape encodes *type* (battle dimension, affiliation), while fill color, modifiers, and text fields encode *state and context*. Changing state never changes the frame shape.

### 3.2 Overlay Channels

Six orthogonal visual channels are available for state encoding. An element may use multiple channels simultaneously (e.g., amber stroke + warning badge):

| Channel | Mechanism | Z-Order | Used For |
|---|---|---|---|
| **Stroke color override** | Glyph outline color changes from `--glyph-neutral` to a semantic color | Same as glyph | Primary state indicator (online, offline, armed, etc.) |
| **Outer halo** | Soft radial gradient or blurred ring, 4–6 units beyond glyph boundary | Behind glyph | Emphasis: Defense Mode (amber halo on turrets), selected state |
| **Badge** | Small (8×8 unit) labeled element, positioned at glyph corner (NE default) | Above glyph | Counts ("+3"), warnings ("!"), denied ("✕"), revenue ("$") |
| **Link line color/style** | Line color shifts from `--link-neutral` to semantic color; style may change (dashed) | Behind glyphs | Corridor state (healthy, degraded, Defense Mode restricted) |
| **Pulse animation** | Brief (200–400ms) radial expansion + fade from glyph center | Above halo, behind badge | Event notification: toll collected, hostile denied, trade settled |
| **Status pip** | 4-unit filled circle, positioned at glyph's 5 o'clock (bottom-right) | Above glyph, behind badge | Persistent micro-status: fuel level (green/amber/red fill) |

### 3.3 State Definitions

#### Structure-Level States

| State | Applies To | Stroke Override | Halo | Badge | Pip | Desc |
|---|---|---|---|---|---|---|
| **Neutral / Idle** | All | `--glyph-neutral` (default) | None | None | None | Base state. Structure exists, no active condition. |
| **Online / Healthy** | NWN, Gate, SSU | `--state-online` (muted teal) | None | None | None | Structure is online and operating normally. This is a *persistent* state, not an event. Uses muted teal rather than bright green to avoid visual noise — a healthy network should look calm, not agitated. |
| **Offline** | All | `--state-offline` (red) | None | None | None | Structure is offline or unreachable. Red stroke is reserved for conditions requiring operator attention. |
| **Fuel Low / Degraded** | NWN | `--state-warning` (amber) | None | `!` badge | Amber pip | NetworkNode fuel below threshold. Amber communicates "caution/action needed" without the urgency of red. |
| **Defense Mode Armed** | Turret | `--state-armed` (amber) | Amber halo | None (or turret count badge if collapsed) | None | Turret is online and in Defense Mode posture. Amber halo extends the turret's visual footprint to communicate "active defense perimeter." |
| **Defense Mode Restricted** | Gate | `--state-restricted` (amber) | None | Tribe badge (optional) | None | Gate is in tribe-only restriction. Amber stroke communicates "access controlled / restricted." |
| **Unlinked** | Gate | `--glyph-neutral` | None | "—" badge (muted) | None | Gate is not linked to a partner. Not an alarm — just a topological fact. |
| **Unconfigured** | Gate, SSU | `--glyph-neutral` | None | "○" badge (muted) | None | No extension authorized. Structure is "raw." |

#### Event States (Transient)

| Event | Applies To | Pulse Color | Badge Flash | Duration | Desc |
|---|---|---|---|---|---|
| **Denied** | Gate | `--event-denied` (red) | "✕" badge, red, 2s hold | 300ms pulse + 2s badge hold | Hostile blocked. Red pulse anchors the denial to a specific gate. |
| **Toll Collected** | Gate | `--event-revenue` (green) | "$" or "+N" badge, green, 1.5s hold | 200ms pulse + 1.5s badge hold | Revenue confirmation. Green pulse = economic value generated. |
| **Trade Settled** | SSU (TradePost) | `--event-revenue` (green) | "$" badge, green, 1.5s hold | 200ms pulse + 1.5s badge hold | Commerce confirmed. Same green pulse as toll — economic events share a visual class. |
| **Posture Changed** | All (cascade) | `--event-posture` (amber) | (handled by state transition, not badge) | 400–600ms cascade (see §5) | Infrastructure-wide posture shift. Not a single-element event — it's a propagating state transition. |

#### Link-Level States

| State | Line Color | Line Style | Desc |
|---|---|---|---|
| **Healthy** | `--link-healthy` (muted teal) | Solid, 2px | Both gates online, extension matched |
| **Degraded** | `--link-degraded` (amber) | Solid, 2px | One gate impaired (fuel low, offline, extension mismatch) |
| **Offline** | `--link-offline` (red) | Dashed, 2px | One or both gates offline — corridor non-functional |
| **Defense Mode** | `--link-defense` (amber) | Solid, 3px | Corridor under tribe-only restriction (Defense Mode posture) |
| **Unlinked** | `--link-unlinked` (dark gray) | Dotted, 1px | Structural anchor line only (not a live corridor) |

---

## 4. Color Semantics Doctrine

### 4.1 Semantic Palette

Colors are defined by **function**, not aesthetics. Each color token carries a single unambiguous meaning across all elements.

| Token | Semantic | Usage | Conventional Basis |
|---|---|---|---|
| `--glyph-neutral` | Baseline / no condition | Default glyph stroke, inactive elements | ISA-101: gray as the normal process state. "Gray infrastructure" principle — healthy equipment is unremarkable. |
| `--state-online` | Operating normally | Online stroke for NWN, Gate, SSU | Muted teal. Not bright green. Per ISA-101, green should not dominate the normal state — an all-green screen is visual noise. Teal distinguishes "healthy" from "economic event." |
| `--state-offline` | Hard stop / failure | Offline stroke, broken link | Red. IEC 60073: red = danger, immediate operator attention required. ISA-18.2: Priority 1 alarm. |
| `--state-warning` | Caution / degraded | Fuel low, degraded link | Amber/yellow. IEC 60073: yellow = caution, abnormal condition requiring awareness. ISA-18.2: Priority 2/3 alarm. |
| `--state-armed` | Posture: defense active | Turret halo, gate restriction | Amber. Same family as warning — Defense Mode is a deliberate operator action, not an alarm, but it represents "restricted / heightened readiness." Amber unifies all non-emergency deviations from passive operation. |
| `--state-restricted` | Access controlled | Gate in tribe-only mode | Amber. Same token as armed — restriction and defense are the same posture category. |
| `--event-revenue` | Economic confirmation | Toll collected, trade settled (pulse + badge) | Green. Reserved **exclusively** for confirmed economic events. ISA-18.2 inverts here by convention: green is not "normal," it's "value confirmed." This is a deliberate deviation — justified because CivilizationControl is a governance/revenue system, not a process plant. Revenue confirmation is the highest-value operator signal. |
| `--event-denied` | Hostile blocked | Denial event (pulse + badge) | Red. Same color as offline — both are "something went wrong or was stopped." Context (pulse vs. persistent stroke) disambiguates. |
| `--event-posture` | Infrastructure-wide transition | Defense Mode cascade animation | Amber. Matches the defense posture family. The cascade itself is the visual event — individual element transitions use their respective state colors. |
| `--link-neutral` | Passage corridor (idle) | Gate pair links at rest | Low-saturation gray. Links should be structurally visible but not attention-competing. |
| `--link-healthy` | Corridor operational | Both gates online | Muted teal. Matches `--state-online` for consistency. |
| `--link-defense` | Corridor restricted | Defense Mode active on corridor | Amber. Same defense family. |
| `--bg` | Canvas background | SVG background | Dark (`hsl(220, 15%, 8%)` or similar). The topology sits on a dark canvas — light glyphs on dark ground. This is the standard for NOC/SCADA control rooms (reduces eye strain, maximizes contrast for colored overlays). |

### 4.2 Color Hierarchy

When multiple states apply simultaneously, the highest-priority color wins the stroke:

1. **Red** (offline, denied) — highest priority
2. **Amber** (warning, armed, restricted, defense cascade)
3. **Muted teal** (online/healthy)
4. **Gray** (neutral/idle) — lowest priority

This matches ISA-18.2 alarm priority ordering: critical > high > medium > advisory.

### 4.3 Why Green Is Not "Online"

In traditional SCADA/process control, green means "normal / safe / no alarm." If every healthy structure were green, the topology would be a field of green dots — visually noisy and carrying zero information (the same failure mode ISA-101 was designed to prevent).

Instead:
- **Normal operation is gray/muted teal** — unremarkable by design. A calm network looks calm.
- **Green fires only for economic events** — toll collected, trade settled. These are the moments the operator cares about most. Green becomes a *reward signal*, not a baseline.
- **The eye is trained to notice green flashes** precisely because they are rare and meaningful.

This is a conscious deviation from IEC 60073 (where green = safe), justified by the domain: CivilizationControl is not monitoring a plant for safety. It is governing frontier infrastructure for revenue. The "safe state" is baseline gray. The "value state" is green.

### 4.4 Hex Value Guidelines

Exact hex values are implementation decisions, not doctrine. The spec constrains:

- All semantic colors must pass **WCAG AA contrast ratio** (≥4.5:1) against `--bg`.
- Amber and red must be distinguishable under deuteranopia simulation (protanopia and deuteranopia affect red-green, not red-amber).
- Green and teal must be distinguishable under tritanopia simulation.
- Badge text must pass WCAG AA against badge background.

Recommended starting points (to be validated in implementation):

| Token | Suggested HSL | Notes |
|---|---|---|
| `--bg` | `hsl(220, 15%, 8%)` | Near-black with cool undertone |
| `--glyph-neutral` | `hsl(210, 8%, 55%)` | Mid-gray, low saturation |
| `--state-online` | `hsl(175, 45%, 50%)` | Muted teal, not cyan-bright |
| `--state-offline` | `hsl(0, 75%, 55%)` | Saturated red, not pink |
| `--state-warning` | `hsl(38, 90%, 55%)` | Warm amber |
| `--state-armed` | `hsl(38, 90%, 55%)` | Same as warning (shared token) |
| `--event-revenue` | `hsl(145, 65%, 50%)` | Distinct green, not teal |
| `--event-denied` | `hsl(0, 75%, 55%)` | Same as offline (shared token) |
| `--link-neutral` | `hsl(210, 8%, 35%)` | Dark gray, recedes visually |

---

## 5. Motion Doctrine & Demo Timing

### 5.1 Governing Principle

Animation serves **information transfer**, not aesthetics. Every motion must answer a question the operator might ask: "What just changed?" or "What is transitioning?"

No elastic/bouncy easing. No spring physics. No overshoot. All motion uses **ease-out** (deceleration curve) or **linear** timing functions. The visual language is a control surface, not a game UI.

### 5.2 Timing Table

| Motion | Duration | Easing | Trigger | Justification |
|---|---|---|---|---|
| **Hover highlight** | 120ms | ease-out | Pointer enter/leave on any structure glyph | Immediate feedback. Fast enough to feel responsive, slow enough to avoid flicker. |
| **State transition** (single element) | 200–300ms | ease-out | Structure state change (online↔offline, armed↔disarmed) | Perceptible but not sluggish. ISA-101 recommends state changes complete within one visual fixation (~300ms). |
| **Event pulse** (toll, denied, trade) | 200ms expand + 200ms fade | ease-out expand, linear fade | Economic or denial event confirmation | Total 400ms visible. The pulse draws the eye to the source structure, then fades to avoid clutter. |
| **Badge appear** | 150ms | ease-out (scale 0→1) | Event or state triggering a badge | Badges pop in slightly faster than state transitions — they carry urgent contextual data. |
| **Badge hold** | 1.5–2s | n/a (static hold) | Post-appear persistence | Long enough for the operator to read the badge content. Revenue badges: 1.5s. Denied badges: 2s (denied events are higher-priority). |
| **Badge dismiss** | 200ms | ease-out (opacity 1→0) | Hold timer expires | Fade out, not snap out. |
| **Defense Mode cascade** | 400–600ms total | ease-out per hop, 80–120ms stagger between elements | Defense Mode posture switch | See §5.3 below. |
| **Link color transition** | 300ms | ease-out | Link state change | Matches single-element state transition timing. |

### 5.3 Defense Mode Cascade Protocol

The Defense Mode posture switch is the **climax visual event** of the demo (Beat 6, 30 seconds). It must communicate "infrastructure-wide state change, one operator action" with visual authority.

**Sequence:**

1. **Posture indicator** changes first (0ms): "Open for Business" → "Defense Mode" label transition in the UI (outside the SVG topology, handled by the shell).
2. **Gate link lines** transition (0–300ms): All gate pair links shift from `--link-healthy` (teal) to `--link-defense` (amber). Staggered by network distance from the "origin" node (the node nearest to the operator's last interaction), 80ms per hop. This creates a **wave propagation** effect — the amber spreads across the network like a signal traveling through corridors.
3. **Turret glyphs** transition (200–500ms): Each turret's stroke shifts to `--state-armed` (amber) and the outer halo appears. Staggered to follow the link wave — a turret transitions 80ms after its parent node's links have transitioned. Animation: stroke color fade (200ms) + halo fade-in (200ms, overlapping).
4. **Gate glyphs** transition (200–500ms): Gate strokes shift to `--state-restricted` (amber), concurrent with turret transitions.
5. **Total cascade duration:** 400–600ms from first visual change to last element settled. The entire network should be in Defense Mode visual state within 600ms.

**Justification for 400–600ms:**
- Below 400ms: transitions blur together, losing the "wave" readability. The cascade is indistinguishable from a simultaneous snap.
- Above 600ms: feels sluggish for a "one click" action. The demo requires 2 seconds of silence after the click (Beat Sheet v2); the visual must dominate within the first 600ms so the remaining 1.4s is the operator absorbing the result.
- The 80ms per-hop stagger creates 3–5 distinguishable wave frames at typical network sizes (3–6 nodes), which is within the visual system's temporal resolution for group motion (~10Hz = 100ms per frame perception).

**Reverse cascade (Defense → Business):** Same wave pattern, reversed colors (amber → teal/neutral). Same timing. Same origin-outward propagation.

### 5.4 Demo Latency Alignment

Per the Demo Beat Sheet's Transaction Latency Protocol:
- On-chain PTB execution: ~2–3 seconds
- Narrator stays ~2 seconds ahead of UI
- Post-click silence: 2 seconds

The cascade animation (400–600ms) begins **after the transaction confirms** (after the on-chain ~2.3s latency). The 2 seconds of narrator silence accommodate: confirmation wait (~2.3s) + cascade animation (~0.5s) + visual absorption (~1.5s before narration resumes). The cascade must be fully settled before "Gates locked. Turrets online. One transaction." is spoken.

---

## 6. Layout & Stacking Rules

### 6.1 Topology, Not Cartography

The Strategic Network Map renders an **abstract governance topology**. Positions are derived from operator-curated spatial pins (solar system assignments per UX Spec §8), NOT from on-chain coordinates or game-world positions.

- Unpinned structures appear in an "Unplaced" holding area (bottom or side of canvas).
- The topology is a **node-link diagram** (graph), not a map with a coordinate system.
- Operators may rearrange nodes (stretch: drag-to-reposition). Fixed positions assigned from pin data are the MVP default.

### 6.2 Network Node as Anchor

The Network Node is the gravitational center of each cluster. All other structures are positioned relative to their parent Network Node.

```
Layout hierarchy:
  System Region (from spatial pin — e.g., "Jita")
    └── Network Node (hexagon, center of cluster)
         ├── Gate (ring, positioned on cluster perimeter)
         ├── Gate (ring, positioned on cluster perimeter)
         ├── Turret (triangle, positioned radially outward)
         ├── Turret (triangle, positioned radially outward)
         └── Trade Post (square, positioned on cluster perimeter)
```

### 6.3 Cluster Layout Algorithm

All structures anchored to the same Network Node form a **cluster**. The cluster uses a radial layout:

- **Network Node** occupies the center.
- **Dependent structures** (Gates, Turrets, Trade Posts) are arranged at equal angular intervals on a circle of radius R around the center (R = ~3× the glyph size at current zoom, minimum 48 display units between glyph centers).
- **Ordering:** Gates first (12 o'clock, clockwise), then Trade Posts, then Turrets. This groups passage points together and places defensive elements on the perimeter.

### 6.4 Turret Stacking

Turrets are the most common structure to concentrate at a single node (up to 6 validated per NWN).

| Turret Count | Display Strategy |
|---|---|
| 1–3 | Individual turret glyphs positioned radially, equally spaced, on the outer ring of the cluster (outside the gate/SSU ring). Each apex points outward. |
| 4–6 | First 3 visible as individual glyphs. 4th+ collapsed into a single grouped glyph with a count badge: triangle with "+N" badge (e.g., "+3" for 6 total, since 3 are visible). |
| >6 | Unlikely per current game constraints. If encountered: 3 visible + "+N" badge for remainder. |

**Demo exception:** For the demo, all turrets may be forced to expanded (individual) display regardless of count, to maximize the visual impact of the Defense Mode cascade. This is a display-mode flag, not a layout change.

**Hover/click expansion:** Clicking the "+N" turret badge expands the collapsed group to show all individual turrets in an expanded ring. Click outside to re-collapse.

### 6.5 Gate Pair Link Routing

Links between gate pairs connect two gates that may be in different clusters (different systems). Link lines route as:

- **Same cluster:** Curved arc within the cluster boundary (rarely occurs — linked gates are typically in different systems).
- **Cross-cluster:** Straight line from gate center to gate center, routed behind all clusters (z-order: lowest).
- **Overlap avoidance:** If a link line passes behind a cluster it doesn't belong to, apply a subtle offset curve (quadratic bezier with control point offset perpendicular to the line). This prevents links from visually crossing unrelated nodes.

### 6.6 Multi-System Layout

When an operator owns structures in multiple solar systems:

- Each system is a **region** on the canvas, positioned according to a simple force-directed or grid layout (derived from pin data or auto-arranged).
- Region labels appear above each cluster: system name in `--glyph-neutral` color, small caps, 10px equivalent.
- Minimum spacing between region centers: 200 display units (ensures clusters don't overlap at standard zoom).
- "User-curated placement" disclosure visible in the canvas footer (per UX Spec §9a).

### 6.7 Z-Order Stack

From bottom (farthest) to top (nearest):

1. Canvas background (`--bg`)
2. Region labels (system names)
3. Cross-cluster link lines
4. Intra-cluster anchor lines (dotted, structure-to-NWN)
5. Structure glyphs (all types)
6. State halos (behind their glyph, but above other glyphs')
7. Event pulses
8. Badges
9. Tooltip / hover card (topmost)

---

## 7. Export & Naming Conventions

### 7.1 SVG Export Rules

- All topology glyphs are SVG `<path>`, `<circle>`, `<rect>`, or `<polygon>` elements — no raster images, no embedded fonts in glyph paths.
- Glyphs use CSS custom properties for color tokens (see §4). Theme switching changes custom property values, not SVG structure.
- All glyphs are designed at 24×24 viewBox. Export at: 24, 32, 48, 64 unit sizes.
- Stroke widths scale proportionally with viewBox.
- No embedded CSS animations in exported static SVGs. Animation is handled by the React rendering layer at runtime.

### 7.2 Naming Conventions

| Element | Naming Pattern | Example |
|---|---|---|
| **Structure glyph** | `Icon/<Type>/<Size>` | `Icon/Gate/24`, `Icon/NetworkNode/48` |
| **State variant** | `Icon/<Type>/<State>` | `Icon/Turret/Armed`, `Icon/Gate/Restricted` |
| **Badge** | `Badge/<Type>` | `Badge/Count`, `Badge/Denied`, `Badge/Revenue` |
| **Link** | `Link/<State>` | `Link/Healthy`, `Link/Defense`, `Link/Offline` |
| **Halo** | `Halo/<Type>` | `Halo/Armed`, `Halo/Selected` |
| **Pulse** | `Pulse/<Event>` | `Pulse/Revenue`, `Pulse/Denied` |

### 7.3 React Component Mapping

| SVG Element | React Component | Props |
|---|---|---|
| Structure glyph + overlays | `<StructureNode>` | `type`, `state`, `position`, `onClick` |
| Link line | `<LinkLine>` | `sourceId`, `targetId`, `state` |
| Badge | `<StatusBadge>` | `type`, `value`, `position` |
| Cluster | `<NodeCluster>` | `networkNodeId`, `children`, `position` |
| Canvas | `<TopologyCanvas>` | `regions`, `links`, `onNodeClick` |

---

## 8. Why This Is Not Arbitrary

### 8.1 Design Principles Grounding

This symbol grammar and state system are grounded in five convergent principles drawn from three distinct domains (industrial control, military symbology, perceptual psychology):

**Principle 1: Neutral Ground / Colored Figure** (ISA-101, Hollifield/Habibi "High Performance HMI")

The ISA-101 standard for Human-Machine Interfaces mandates that the normal operating state should be visually quiet — gray, muted, unremarkable. Color is reserved for deviations from normal. Bill Hollifield's "High Performance HMI" handbook (widely adopted in petrochemical, power, and water treatment facilities) codifies this as "dark backgrounds, gray piping, color only for abnormal states."

*Application:* Glyphs are gray outlines. Color appears only for state deviations (online teal, offline red, armed amber, revenue green). A healthy network looks calm. An abnormal condition demands attention through color contrast.

**Principle 2: Shape Encodes Type, Color Encodes State** (MIL-STD-2525D / NATO APP-6(D))

NATO's joint military symbology system uses frame shape to encode permanent classification (friendly = rectangle, hostile = diamond, neutral = square, unknown = quatrefoil) and fill color/modifiers to encode transient state (present = solid line, planned = dashed). Changing a unit's status never changes its frame shape.

*Application:* A Gate is always a ring. A Turret is always a triangle. State changes (armed/disarmed, online/offline) modify color overlays, halos, and badges — never the base geometry. An operator learns four shapes once and recognizes structure types instantly regardless of state.

**Principle 3: Redundant Encoding** (MIL-STD-2525D, IEC 60073, WCAG)

Military symbology mandates that shape and color provide redundant information — the system must be interpretable on monochrome displays. IEC 60073 similarly requires that color-coded indicators provide a secondary non-color signal (position, pattern, or label). WCAG accessibility guidelines require that information is not conveyed by color alone.

*Application:* Every state has *both* a color signal and a shape/badge signal. Offline = red stroke + structure type still identifiable. Armed = amber halo + triangle still readable as turret. Denied = red pulse + "✕" badge. Revenue = green pulse + "$" badge. A colorblind operator can still parse every state.

**Principle 4: Alarm Priority Hierarchy** (ISA-18.2, IEC 60073, EEMUA 191)

The ISA-18.2 alarm management standard and EEMUA Publication 191 establish a strict priority→color mapping: critical (red) > high (amber/yellow) > medium (blue) > advisory (white/gray). IEC 60073 establishes the same hierarchy for safety indicators: red (danger) > yellow (caution) > green (safe) > blue (mandatory action).

*Application:* Red > Amber > Teal > Gray in this spec. When states overlap, the highest-priority color wins. Offline (red) overrides armed (amber). Armed (amber) overrides online (teal). The operator always sees the most urgent condition.

**Principle 5: Gestalt Perceptual Grouping** (Wertheimer, Koffka, Köhler)

Gestalt principles of visual perception — proximity, similarity, closure, continuity, and prägnanz (tendency toward simplicity) — govern how humans parse visual scenes. Proximity groups nearby elements. Similarity groups elements with shared visual attributes. Prägnanz preferences simple, regular, symmetric forms over complex ones.

*Application:* Structures cluster around their parent Network Node (proximity = "these belong together"). All gates share ring shape and all turrets share triangle shape (similarity = "these are the same type"). Link lines provide continuity between clusters ("these systems are connected"). Each glyph is a simple geometric primitive (prägnanz = instantly parseable, no ambiguity). The hexagon's 6-fold symmetry makes it the most "prägnant" anchor shape — it reads as the most stable, structural element in any cluster.

### 8.2 What This Is Not

This grammar is not a creative exercise in "cool sci-fi icons." It is a **functional symbology** designed to survive:

1. Small rendering sizes (24px minimum)
2. Dense topologies (20+ structures, 10+ links)
3. Rapid state changes (multiple events per second during demo)
4. Colorblind operators (8% of males have red-green deficiency)
5. Non-expert viewers (hackathon judges watching a 3-minute video)

The shapes were chosen for perceptual distinctness, not aesthetics. The colors were chosen for alarm-priority ordering, not branding. The animations were chosen for information transfer speed, not visual flair.

**Authority comes from coherence** — four shapes, six overlay channels, five colors, one consistent compositional rule (state as overlay, not mutation) — **not from decorative complexity.**

---

## 9. Do Not List

These constraints have the same precedence as the affirmative rules above. Violation of any item is a design regression.

| # | Do Not | Rationale |
|---|---|---|
| 1 | **No starfield / space background textures** | The topology is a schematic, not a view out a cockpit window. Background texture competes with link lines and state overlays. |
| 2 | **No gradients inside glyphs** | Gradients add visual weight and ambiguity. Flat stroke glyphs have consistent legibility at all sizes. |
| 3 | **No HUD-style decorative elements** (scan lines, corner brackets, crosshairs, targeting reticles) | These read as "game UI" rather than "control surface." Judges must see governance, not entertainment. |
| 4 | **No glow/bloom in neutral state** | Glow is reserved for state overlays (halos, pulses). A glowing neutral state desensitizes the operator to deviations. |
| 5 | **No filled/solid glyphs in neutral state** | Fill is a state channel. Filling a neutral glyph removes the ability to use fill as a state signal. |
| 6 | **No inconsistent icon libraries** | All four structure glyphs must share the same visual weight, stroke width, corner treatment, and grid proportions. Mixing an icon-font gate with a hand-drawn turret breaks visual coherence. |
| 7 | **No elastic/spring/bounce animations** | These read as playful, not authoritative. Per ISA-101 and the Voice Guide: measured confidence, no theatrics. |
| 8 | **No animation on neutral-to-neutral** | If nothing changed, nothing moves. Animation without information content is visual noise. |
| 9 | **No color-only state encoding** | Every color state must have a redundant shape, badge, or pattern signal. (See §8.1, Principle 3.) |
| 10 | **No link arrows in MVP** | Directional traffic indicators are a P3 feature (Spatial Embed Requirements). Adding them prematurely clutters the topology at small zoom levels. |
| 11 | **No 3D/perspective rendering** | The topology is a 2D schematic. Perspective effects (vanishing point, foreshortening) add visual complexity without information content and break the schematic register. |
| 12 | **No custom cursor shapes** | Standard browser cursors. The topology is a React component, not a standalone application. |

---

## 10. Demo Beat Alignment Matrix

This matrix verifies that every demo beat's visual requirements are satisfiable by the spec's primitives:

| Beat | Name | Topology Visual Requirement | Spec Primitive | Satisfied |
|---|---|---|---|---|
| 1 | Pain | None (text-on-black) | n/a | ✓ (no topology visible) |
| 2 | Power Reveal | Full topology visible, structures resolved, status online, posture "Open for Business" | All glyphs in online/neutral state, links in healthy state, posture label (outside SVG) | ✓ |
| 3 | Policy | Gate highlighted during policy deploy, Signal Feed update | Hover highlight (120ms), post-deploy state transition to "configured" | ✓ |
| 4 | Denial | Red pulse on the gate where hostile was denied, "✕" badge | `Pulse/Denied` (300ms red) + `Badge/Denied` (2s hold) | ✓ |
| 5 | Revenue | Green pulse on the gate where toll collected, "$" badge | `Pulse/Revenue` (200ms green) + `Badge/Revenue` (1.5s hold) | ✓ |
| 6 | Defense Mode | **Full cascade:** posture indicator → link lines amber → turrets armed (halo) → gates restricted. Wave propagation 400–600ms. | Defense Mode cascade protocol (§5.3). All state transitions, link color shifts, turret halos, gate restriction strokes. | ✓ |
| 7 | Commerce | Green pulse on Trade Post where trade settled | `Pulse/Revenue` on Trade Post glyph + `Badge/Revenue` | ✓ |
| 8 | Command | Full topology visible, all states settled post-Defense Mode, revenue aggregates | Stable topology in Defense Mode state. All amber. Revenue badges cleared (or persistent count badge). | ✓ |
| 9 | Close | Title card overlays topology (or topology fades to black) | Opacity transition on `<TopologyCanvas>` (300ms fade-out) | ✓ |

All five non-negotiable proof moments (Proof Moments 1–5 from Beat Sheet v2) have corresponding visual anchors in the topology:

| Proof Moment | Visual Anchor |
|---|---|
| Policy deploy tx digest | Gate glyph state transition to "configured" |
| Hostile denied — MoveAbort visible | Red pulse + "✕" badge on specific gate |
| Toll collected — balance delta | Green pulse + "$" badge on specific gate |
| Defense Mode — single tx | Full cascade animation across all structures |
| Trade settlement — buyer/seller balances | Green pulse on Trade Post |

---

## 11. Accessibility

### 11.1 Color-Blind Safety

| Deficiency | Affected Pairs | Mitigation |
|---|---|---|
| **Deuteranopia / Protanopia** (red-green, ~8% males) | Red vs. green (offline vs. revenue event) | Badge provides redundant signal: "✕" vs. "$". Pulse location (gate vs. gate) + badge text disambiguate. Red and amber remain distinguishable under deutan simulation. |
| **Tritanopia** (blue-yellow, ~0.003%) | Teal vs. amber could converge | Badge and shape redundancy. Persistent states (stroke color) supplemented by pip or badge. |

### 11.2 Redundancy Matrix

Every state has at least two independent encoding channels:

| State | Channel 1 (Color) | Channel 2 (Shape/Text) |
|---|---|---|
| Online | Teal stroke | (baseline — no badge needed; absence of red/amber is the signal) |
| Offline | Red stroke | Badge: none required (shape unchanged; glyph still identifiable) |
| Fuel low | Amber stroke | `!` badge + amber pip |
| Armed (turret) | Amber stroke | Amber halo (outer ring — distinct geometry) |
| Restricted (gate) | Amber stroke | Tribe badge (optional text) |
| Denied event | Red pulse | "✕" badge |
| Revenue event | Green pulse | "$" or "+N" badge |
| Defense Mode cascade | Amber wave | All individual element transitions + posture label |

### 11.3 Screen Reader / Assistive Technology

The SVG topology is a visual control surface and is not the primary interaction pathway (the list view is). However:

- All structure nodes expose `aria-label` attributes: e.g., `aria-label="Gate North-3, Online, 2 rules active"`.
- The topology container has `role="img"` with an `aria-label` describing the current network state.
- Interactive elements (clickable nodes) have `role="button"` and keyboard focus support (`tabindex`).
- State change events announce via `aria-live="polite"` region: e.g., "Turret Alpha now online. Defense Mode active."

---

## 12. References

### Standards & Guidelines

| Reference | Issuing Body | Relevance |
|---|---|---|
| **ISA-101.01-2015** — Human Machine Interfaces for Process Automation Systems | International Society of Automation (ISA) | HMI design principles: gray baseline, color for exceptions, alarm color hierarchy, display hierarchy levels (L1–L4). Foundation for "gray infrastructure, colored deviations" principle. |
| **IEC 60073:2002** — Basic and safety principles for man-machine interface, marking and identification — Coding principles for indicators and actuators | International Electrotechnical Commission (IEC) | International color coding standard for indicators: Red = danger/emergency, Yellow = caution/abnormal, Green = safe/normal, Blue = mandatory action. Foundation for alarm priority color hierarchy. |
| **ISA-18.2-2016** — Management of Alarm Systems for the Process Industries | ISA | Alarm management: priority classification (critical → advisory), rationalization, color mapping by priority. Foundation for color hierarchy (red > amber > teal > gray). |
| **EEMUA Publication 191** (Edition 4, 2024) — Alarm Systems: A Guide to Design, Management and Procurement | Engineering Equipment and Materials Users Association | Industry benchmark for alarm system design. Complements ISA-18.2 with practical design guidance, including color usage, alarm prevalence targets, and HMI layout. Widely adopted in oil/gas, chemical, power generation. |
| **MIL-STD-2525D** — Joint Military Symbology | U.S. Department of Defense | Military map symbology: frame shape = classification (type/affiliation), fill/modifier = state. Foundation for "shape encodes type, color encodes state" principle and monochrome legibility requirement. |
| **NATO APP-6(D)** — NATO Joint Military Symbology | NATO Standardization Office | NATO equivalent of MIL-STD-2525D. Same compositional principles. Confirms the universality of shape-for-type, overlay-for-state across Western allied nations. |

### Design Literature

| Reference | Author(s) | Relevance |
|---|---|---|
| **The High Performance HMI Handbook** | Bill Hollifield, Eddie Habibi | Industry standard text on control room display design. Establishes "gray infrastructure" principle, advocates dark backgrounds, limited color palettes, progressive disclosure, and alarm-driven color. Widely adopted in process industries. ISA-101 was significantly influenced by this work. |
| **Gestalt Principles of Perception** | Max Wertheimer, Kurt Koffka, Wolfgang Köhler | Foundational perceptual psychology: proximity, similarity, closure, continuity, prägnanz. Directly applicable to node-link diagram legibility, cluster grouping, and glyph distinctness. |
| **NUREG-0700 Rev. 3** — Human-System Interface Design Review Guidelines | U.S. Nuclear Regulatory Commission | HMI guidelines for nuclear power plant control rooms. Establishes display hierarchy, alarm priority visualization, operator cognitive load management. Most conservative/rigorous HMI standard in existence — if it works for nuclear, it works for frontier governance. |

### Internal Documents

| Document | Path | Relevance |
|---|---|---|
| Demo Beat Sheet v2 | [docs/core/civilizationcontrol-demo-beat-sheet.md](../core/civilizationcontrol-demo-beat-sheet.md) | Narrative anchor: 5 proof moments, Defense Mode cascade timing, transaction latency protocol |
| Product Vision | [docs/strategy/civilization-control/civilizationcontrol-product-vision.md](../strategy/civilization-control/civilizationcontrol-product-vision.md) | "Command layer for frontier infrastructure" positioning, posture presets, revenue thesis |
| UX Architecture Spec §9 | [docs/ux/civilizationcontrol-ux-architecture-spec.md](civilizationcontrol-ux-architecture-spec.md) | Strategic Network Map interaction patterns, screen hierarchy, data sources |
| Spatial Embed Requirements | [docs/architecture/spatial-embed-requirements.md](../architecture/spatial-embed-requirements.md) | 12 visual primitive requirements, hybrid architecture decision, EF-Map limitations |
| Voice & Narrative Guide | [docs/strategy/civilization-control/civilizationcontrol-voice-and-narrative.md](../strategy/civilization-control/civilizationcontrol-voice-and-narrative.md) | Label conventions, emotional signal doctrine, Narrative Impact Check |
| Hackathon Emotional Objective | [docs/strategy/civilization-control/civilizationcontrol-hackathon-emotional-objective.md](../strategy/civilization-control/civilizationcontrol-hackathon-emotional-objective.md) | 3-Second Check, Five-Pillar Lens, calm authority requirement |

---

*End of specification.*
