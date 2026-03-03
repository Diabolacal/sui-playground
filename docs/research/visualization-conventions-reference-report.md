# Visualization Conventions & Design Standards — Reference Report

**Retention:** Prep-only

Research report gathering authoritative reference points across topology visualization, icon/state layering, color semantics, tactical symbology, and Gestalt perceptual principles. Intended to inform CivilizationControl UI design decisions.

---

## 1. Network / Topology Visualization Conventions

### 1.1 ISA-101 — Human Machine Interfaces for Process Automation

- **Full title:** ANSI/ISA-101.01 — Human Machine Interfaces for Process Automation
- **Issuing body:** International Society of Automation (ISA), Committee ISA101
- **Summary:** ISA-101 establishes standards, recommended practices, and technical reports for human-machine interfaces in manufacturing and process automation. The committee scope covers *menu hierarchies, screen navigation conventions, graphics and color conventions, dynamic elements, and alarming conventions*. It defines a lifecycle model for HMI design, implementation, operation, and maintenance.
- **Key design principles:**
  - **Gray infrastructure:** Process piping, vessels, and static equipment should be rendered in neutral gray tones. Color is reserved exclusively for dynamic state information (alarms, deviations, mode changes). This prevents "color fatigue" and preserves color salience for actionable conditions.
  - **Layered information hierarchy:** Displays are organized in levels — Level 1 (plant overview / situational awareness), Level 2 (area overview), Level 3 (unit detail), Level 4 (diagnostic detail). Each level has a defined information density and interaction model.
  - **Minimal animation:** Movement and blinking are reserved for conditions requiring immediate attention. Gratuitous animation degrades operator performance.
  - **Consistent spatial mapping:** Process flow should map left-to-right or top-to-bottom, matching physical plant topology.
- **Authority basis:** ISA is the primary global standards body for industrial automation. ISA-101 is the only ANSI-accredited standard specifically addressing HMI graphics and display design for process industries. Referenced by OSHA, EPA, and major operating companies worldwide.
- **URL:** https://www.isa.org/standards-and-publications/isa-standards/isa-standards-committees/isa101

### 1.2 NUREG-0700 — Human-System Interface Design Review Guidelines

- **Full title:** NUREG-0700, Rev. 4 — Human-System Interface Design Review Guidelines
- **Issuing body:** U.S. Nuclear Regulatory Commission (NRC), Office of Nuclear Regulatory Research
- **Summary:** Comprehensive design review guidelines for human-system interfaces in nuclear power plant control rooms. Covers display design, controls, alarm systems, decision support, and computer-based procedures. Revision history spans from 1981 (Rev. 0) through Rev. 4, reflecting decades of human factors engineering research in safety-critical environments.
- **Key design principles:**
  - **Information hierarchy by safety significance:** Display prominence must correlate with safety importance. Critical safety parameters are always visible; less critical data is available on demand.
  - **Redundant coding:** Critical state information must never rely on a single perceptual channel (e.g., color alone). Combine color with shape, position, text labels, or pattern to ensure accessibility under degraded conditions (monochrome displays, colorblind operators, night vision).
  - **Minimal working memory load:** Displays should present information in formats that minimize the need for mental calculation or recall. Pre-computed trends, deviation indicators, and integrated displays reduce cognitive burden.
  - **Alarm integration with process displays:** Alarms must be contextually linked to the process parameters they monitor, not presented only as isolated lists.
- **Authority basis:** NUREG-0700 is the NRC's primary human factors engineering standard for nuclear facility design review. It incorporates findings from Three Mile Island, Chernobyl, and decades of nuclear industry operating experience. Required compliance for U.S. nuclear license applications.
- **URL:** https://www.nrc.gov/reading-rm/doc-collections/nuregs/staff/sr0700/

---

## 2. Icon / State Layering in Control Systems

### 2.1 High Performance HMI (Hollifield & Habibi)

- **Full title:** *The High Performance HMI Handbook* — Bill Hollifield, Eddie Habibi (PAS / Hexagon, 2010; 2nd ed.)
- **Summary:** Defines the "High Performance HMI" methodology for industrial process displays, drawing on ISA-101, EEMUA 191, and ASM Consortium research. The HP-HMI approach replaced legacy "P&ID mimic" displays (brightly colored, high visual density) with displays optimized for operator situational awareness and abnormal situation detection.
- **Key design principles:**
  - **Gray-scale infrastructure, color for deviation only:** The most impactful principle. All static process elements (pipes, vessels, equipment outlines) are rendered in gray scale. Color appears *only* when a process variable deviates from normal — typically as colored fill bars, indicator shapes, or border highlights on analog indicators. This creates an "at-a-glance" deviation detection: a healthy process screen appears predominantly gray; problems immediately draw attention through color emergence.
  - **Analog indicators over digital readouts:** Humans process spatial/analog representations (bar charts, deviation fills, trend sparklines) faster than reading numeric values. HP-HMI favors embedded analog indicators for key process variables.
  - **Four-level display hierarchy:** (1) Overview — entire plant status via embedded indicators only, no text clutter; (2) Area overview — process area with key analog indicators; (3) Unit control — detailed control interface for one unit; (4) Detail/diagnostic — full parameter access. Each level has a defined maximum number of elements and color budget.
  - **Alarm state layered onto base symbology:** Alarm conditions are indicated by color changes on the same elements already present in the display (e.g., a bar turning red, an indicator gaining a colored border) rather than by adding new overlay objects or pop-ups. The spatial position of the alarming element tells the operator *what* is alarming and *where* in the process.
  - **Situational awareness as primary design goal:** The display must answer three questions at a glance: (1) What is the current state? (2) Is it normal or abnormal? (3) What trend — improving, stable, or worsening?
- **Authority basis:** Bill Hollifield is co-founder of the PAS alarm management and HMI discipline (now Hexagon). The HP-HMI Handbook synthesizes ISA-101, EEMUA 191, and ASM Consortium research into a practitioner-oriented methodology adopted by BP, Shell, ExxonMobil, Dow Chemical, and others. The methodology is cited as "good industry practice" in ISA-101 itself.
- **ISBN:** 978-0-9778969-0-6

### 2.2 IEC 60073 — Coding Principles for Indicators and Actuators

- **Full title:** IEC 60073 — Basic and Safety Principles for Man-Machine Interface, Marking and Identification — Coding Principles for Indicators and Actuators
- **Issuing body:** International Electrotechnical Commission (IEC)
- **Summary:** Establishes international coding principles — color, shape, position, size, flashing — for indicators and actuators used in man-machine interfaces. Provides a framework for consistent meaning assignment across control systems, applicable to physical panels and computer-based displays alike.
- **Key design principles:**
  - **Standardized color assignments:** Red = danger/stop/fault/prohibited; Yellow/Amber = warning/caution/abnormal; Green = safe/normal/go/enabled; Blue = mandatory/compulsory action; White = no specific safety meaning (neutral/general status information).
  - **Coding dimensionality:** Color is one of multiple coding dimensions (color, shape, size, position, flashing rate, auditory). Safety-critical information must use at least two independent coding dimensions simultaneously (redundant coding).
  - **Flashing reserved for urgency:** Flashing/blinking is reserved for conditions requiring immediate operator action. Continuous illumination indicates steady states. Different flash rates can encode priority tiers, but no more than 2–3 rates should be used to avoid confusion.
  - **Position coding:** Spatial position is a valid and powerful coding mechanism. Consistent placement of similar controls/indicators across all displays reinforces operator muscle memory and reduces search time.
- **Authority basis:** IEC 60073 is the foundational international standard for color and coding in industrial human-machine interfaces. Referenced by ISA, CENELEC, and national standards bodies worldwide. Provides the color semantics baseline that ISA-101, IEC 62682, and EEMUA 191 all build upon.
- **URL:** https://webstore.iec.ch/en/publication/579

---

## 3. Color Semantics & Alarm Priority Conventions

### 3.1 ISA-18.2 / IEC 62682 — Management of Alarm Systems for the Process Industries

- **Full title:** ANSI/ISA-18.2-2009 / IEC 62682:2023 — Management of Alarm Systems for the Process Industries
- **Issuing body:** ISA (American standard) / IEC (international equivalent)
- **Summary:** Defines the alarm management lifecycle: philosophy, identification, rationalization, design, implementation, operation, maintenance, monitoring, and management of change. Provides the definitive framework for alarm prioritization and the relationship between priority, operator response time, and consequence severity.
- **Key design principles:**
  - **Priority matrix:** Alarm priority is determined by crossing *consequence severity* (safety, environmental, economic) with *available response time*. The standard defines priority categories (typically: Emergency, High, Medium, Low, and Diagnostic/Journal) with corresponding maximum acceptable alarm rates.
  - **Color-priority mapping (widely adopted convention):**
    - **Emergency / Critical:** Red — immediate operator action required, potential for loss of life or major environmental release
    - **High:** Orange or dark amber — prompt action required, significant consequence if missed
    - **Medium:** Yellow — timely action required, moderate consequence
    - **Low:** Cyan or light blue — awareness only, minor consequence
    - **Diagnostic / Journal:** White or gray — informational, no operator action expected
  - **Alarm rate targets:** The standard establishes target alarm rates: ≤6 alarms per operator per 10-minute period during upset; ≤1 alarm per 10 minutes during steady-state operation. Exceeding these rates constitutes "alarm flooding."
  - **Alarm shelving and suppression:** Temporary removal of alarms must be tracked, time-limited, and visible to the operator. Suppressed alarms should change visual presentation (e.g., dimmed, hatched, or outlined rather than filled).
- **Authority basis:** ISA-18.2 is the only ANSI-accredited standard for alarm management in process industries. IEC 62682 (its international equivalent) is aligned with EEMUA 191. Together they form the global regulatory baseline for alarm system design, referenced by OSHA PSM, EPA RMP, UK HSE, and Seveso III.
- **URL:** https://www.isa.org/products/ansi-isa-18-2-2016-management-of-alarm-systems-for

### 3.2 EEMUA 191 — Alarm Systems: A Guide to Design, Management and Procurement

- **Full title:** EEMUA Publication 191, Edition 4 (2024) — Alarm Systems: A Guide to Design, Management and Procurement
- **Issuing body:** Engineering Equipment and Materials Users Association (EEMUA), UK
- **ISBN:** 978-0-85931-243-1
- **Summary:** The globally accepted leading guide to alarm system design and management. First published in 1999, EEMUA 191 preceded and influenced both ISA-18.2 and IEC 62682. Developed by alarm system users from high-hazard industries with input from the UK Health and Safety Executive (HSE). Edition 4 (2024) adds guidance on alarm management for remote/unmanned sites.
- **Key design principles:**
  - **Alarm prioritization framework:** Three priority levels (High / Medium / Low) as the recommended baseline, with clear consequence-based definitions for each. Discourages proliferation of priority tiers beyond what operators can meaningfully distinguish.
  - **Benchmark alarm rates:** Steady-state: ≤1 alarm / 10 minutes (acceptable), 1–2 (manageable), >2 (overloaded). These benchmarks became the industry-standard performance metrics adopted globally.
  - **Alarm rationalization:** Every alarm must have a defined purpose, defined operator response, defined consequence of inaction, and defined time to respond. Alarms that fail this test should be removed or reclassified as events/alerts.
  - **Display integration:** Alarms must be visually integrated with process graphics, not isolated in separate alarm summary lists. The spatial context of the alarming parameter is essential for rapid diagnosis.
  - **Color discipline:** Reserve saturated colors strictly for deviation and alarm states. Use muted/gray for normal operations. This principle predates and directly influenced ISA-101's "gray infrastructure" convention.
- **Authority basis:** EEMUA 191 is acknowledged as good practice by the UK HSE, Norwegian Petroleum Safety Authority, and leading regulators globally. Both ISA-18.2 and IEC 62682 are explicitly aligned with EEMUA 191. The ASM Consortium (Honeywell-led, NIST-funded) contributed data. It is the de facto global alarm management reference.
- **URL:** https://www.eemua.org/Products/Publications/Digital/EEMUA-Publication-191.aspx

---

## 4. Tactical / Military Symbology

### 4.1 MIL-STD-2525 / NATO APP-6 — Joint Military Symbology

- **Full title:** MIL-STD-2525D — Joint Military Symbology (US); NATO APP-6(D) — Joint Military Symbology (NATO equivalent)
- **Issuing body:** U.S. Department of Defense / NATO Standardization Office
- **Summary:** Defines a comprehensive symbol system for representing military units, equipment, installations, activities, and tactical graphics on maps, overlays, and C4I displays. The system is compositional: symbols are constructed from a frame (geometric border), fill color, icon (role/function), and modifiers (text/graphic annotations). The current version (MIL-STD-2525D / APP-6D) covers ~8,000+ distinct symbols across all warfighting domains.
- **Key design principles:**
  - **Frame geometry encodes affiliation:** The shape of the outer border is the primary identifier of friend/foe status:
    - **Rectangle** (with concave top) = Friendly (blue fill)
    - **Diamond** = Hostile (red fill)
    - **Square** = Neutral (green fill)
    - **Quatrefoil** (four-lobed) = Unknown (yellow fill)
    - These shapes are perceptually distinct even without color, enabling use on monochrome or night-vision displays.
  - **Battle dimension encoded by frame variant:** Closed frame = ground/surface; open bottom = air/space; open top = subsurface; frame with tie = activity/installation. This encodes domain without requiring separate symbol sets.
  - **Operational status via line style:** Solid border = present/actual; dashed border = planned/anticipated/suspected. State change is encoded by line style modification rather than shape change, preserving visual continuity.
  - **Compositional symbol grammar (icon layer):** Inside the frame, pictographic icons represent specific unit types, equipment, or functions. Icons are assembled from elementary glyphs ("like ideograms in a writing system") that combine additively. A combined-arms task force icon is literally a composite of infantry + armor glyphs.
  - **Modifier fields for attribute layering:** Up to 37 defined modifier positions (labeled A through AK) surround the base symbol, providing: designator, higher formation, speed, direction of movement, date/time, combat effectiveness, staff comments, etc. These modifiers are optional and context-dependent — a clean display shows only frames+icons; a detailed display adds modifier fields progressively.
  - **Redundant encoding:** Shape and color encode the same information (affiliation) independently. This ensures readability under degraded conditions (monochrome printing, night vision goggles, colorblind operators). This is a deliberate design choice, not redundancy by accident.
  - **Echelon and mobility indicators:** Small graphic marks above or below the frame encode unit size (team → army group) and mobility type (wheeled, tracked, rail, etc.) without altering the base symbol.
- **Authority basis:** MIL-STD-2525 is the mandatory symbology standard for all U.S. military C4I systems. NATO APP-6 is its interoperable allied equivalent. Together they are used by 30+ NATO nations and many partner nations. The system has been refined through every major conflict since the Gulf War and represents the most mature, battle-tested visual encoding system for complex operational status.
- **URL:** https://en.wikipedia.org/wiki/NATO_Joint_Military_Symbology

---

## 5. Gestalt Principles in Schematic / Network Design

### 5.1 Gestalt Principles of Perceptual Organization

- **Foundational researchers:** Max Wertheimer, Kurt Koffka, Wolfgang Köhler (1920s, Berlin School)
- **Summary:** Gestalt psychology identifies the perceptual grouping laws by which humans automatically organize visual elements into coherent wholes. The master principle — the *Law of Prägnanz* — states that humans tend to perceive stimuli as regular, orderly, symmetrical, and simple. All other grouping laws are refinements of Prägnanz. These principles are not learned conventions but innate perceptual tendencies, making them universal design constraints.
- **Key principles with design application:**

  | Principle | Definition | Application to Control / Network UI |
  |---|---|---|
  | **Proximity** | Elements close to each other are perceived as a group. | Group related assets (gates, turrets, SSUs) spatially. Spacing between groups signals functional boundaries. |
  | **Similarity** | Elements sharing visual characteristics (color, shape, size) are perceived as related. | Use consistent icon shapes for same-type entities. Color similarity groups same-state assets across the display. |
  | **Closure** | The mind completes incomplete shapes into whole figures. | Dashed borders or partial outlines can define zones without heavy visual weight. Implied boundaries are lighter than explicit ones. |
  | **Continuity** | Elements aligned along a path are perceived as a continuous entity. | Route lines, connection paths, and jurisdiction boundaries should follow smooth curves. Abrupt directional changes break perceived continuity. |
  | **Common region** | Elements within a shared boundary are perceived as grouped. | Enclose related entities in subtle bounded regions (territory zones, governance domains). |
  | **Common fate** | Elements moving/changing together are perceived as a unit. | When posture switches, all affected elements should transition simultaneously — the synchronous state change reinforces that they are one governed system. |
  | **Figure/ground** | The visual field is automatically separated into foreground (figure) and background (ground). | Infrastructure (network topology, pipes, connections) is ground — rendered in low-contrast gray. Active entities and state changes are figure — rendered in saturated color against the neutral ground. **This principle is the perceptual basis for the "gray infrastructure" convention in ISA-101 and HP-HMI.** |
  | **Symmetry** | Symmetric elements are perceived as unified wholes around a center point. | Symmetric layout of control panels and dashboard tiles creates perceived order and reduces cognitive load. |
  | **Invariance** | Objects are recognized despite rotation, scaling, and distortion. | Icon designs should be recognizable at multiple zoom levels and orientations. Simple geometric primitives (circles, triangles, squares) maintain identity better than complex shapes. |

- **Authority basis:** Gestalt grouping principles are among the most replicated findings in perceptual psychology (Wagemans et al., 2012, *Psychological Bulletin*, 138(6), 1172–1217). They are explicitly referenced in ISA-101, NUREG-0700 (human factors engineering basis), and major UX design systems (Material Design, Apple HIG, IBM Carbon). The Interaction Design Foundation identifies them as foundational to all interface design.
- **URLs:**
  - https://en.wikipedia.org/wiki/Gestalt_psychology
  - https://ixdf.org/literature/topics/gestalt-principles

---

## Cross-Reference Matrix: Converging Principles

The following table shows where key design principles appear across multiple standards, demonstrating convergence rather than isolated opinion:

| Principle | ISA-101 | NUREG-0700 | HP-HMI | IEC 60073 | EEMUA 191 | MIL-STD-2525 | Gestalt |
|---|---|---|---|---|---|---|---|
| Gray/muted infrastructure, color for deviation only | ✅ | ✅ | ✅ (primary) | ✅ | ✅ | — | ✅ (figure/ground) |
| Redundant coding (color + shape) | ✅ | ✅ (mandatory) | ✅ | ✅ (mandatory) | — | ✅ (deliberate) | ✅ (similarity + invariance) |
| Hierarchical display levels (overview → detail) | ✅ (4 levels) | ✅ | ✅ (4 levels) | — | — | ✅ (echelon layering) | ✅ (Prägnanz / progressive disclosure) |
| Alarm priority → color mapping | ✅ | ✅ | ✅ | ✅ (R/Y/G/B) | ✅ (benchmark) | ✅ (affiliation) | — |
| Spatial consistency / position coding | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (modifier fields) | ✅ (proximity, continuity) |
| Compositional / layered symbology | — | — | ✅ (analog overlays) | — | — | ✅ (frame + icon + modifiers) | ✅ (closure, common region) |
| State via style change, not geometry change | — | ✅ | ✅ | ✅ (flash rates) | — | ✅ (solid vs. dashed) | ✅ (invariance) |
| Minimal visual complexity / information density limits | ✅ | ✅ | ✅ (element budgets) | — | ✅ (alarm rate limits) | — | ✅ (Prägnanz) |

---

## Summary: Five Universal Principles for CivilizationControl UI

Distilling across all seven references, five design principles emerge with near-universal support:

1. **Neutral ground, colored figure.** Infrastructure is gray; color means something has changed or needs attention. (ISA-101, HP-HMI, EEMUA 191, Gestalt figure/ground, NUREG-0700)

2. **Redundant encoding for critical state.** Never rely on color alone. Combine color with shape, border style, position, or text. (IEC 60073, NUREG-0700, MIL-STD-2525, Gestalt similarity + invariance)

3. **Compositional, layered symbols.** Build symbols from frame (type/affiliation) + icon (function) + modifiers (state/detail). Add layers progressively as detail is needed. (MIL-STD-2525, HP-HMI display hierarchy, Gestalt closure + common region)

4. **State change via attribute, not replacement.** When status changes, modify an attribute of the existing element (color fill, border style, indicator level) rather than swapping the entire symbol. Preserves spatial memory and reduces cognitive re-orientation. (MIL-STD-2525 solid→dashed, HP-HMI deviation fills, NUREG-0700, Gestalt invariance)

5. **Strict color semantics with priority ordering.** Red = critical/hostile; Amber/Orange = warning/high; Yellow = caution/medium; Green = normal/friendly; Blue = informational/mandatory; Gray = neutral/inactive. This mapping is consistent across IEC 60073, ISA-18.2, EEMUA 191, and MIL-STD-2525. Deviating from it violates global operator expectations.

---

## References (Consolidated)

| # | Standard / Source | Year | Issuing Body |
|---|---|---|---|
| 1 | ANSI/ISA-101.01 — Human Machine Interfaces for Process Automation | 2015 | ISA |
| 2 | NUREG-0700 Rev. 4 — Human-System Interface Design Review Guidelines | 2020 | U.S. NRC |
| 3 | *The High Performance HMI Handbook*, 2nd ed. | 2010 | Hollifield & Habibi (PAS/Hexagon) |
| 4 | IEC 60073 — Coding Principles for Indicators and Actuators | 2002 (+ amendments) | IEC |
| 5 | ANSI/ISA-18.2-2016 / IEC 62682:2023 — Management of Alarm Systems | 2016 / 2023 | ISA / IEC |
| 6 | EEMUA Publication 191, Ed. 4 — Alarm Systems Guide | 2024 | EEMUA |
| 7 | MIL-STD-2525D / NATO APP-6(D) — Joint Military Symbology | 2014 (+ changes) | US DoD / NATO |
| 8 | Gestalt psychology — Wertheimer, Koffka, Köhler | 1912–1935 | Berlin School |
| 9 | Wagemans et al. — "A century of Gestalt psychology in visual perception" | 2012 | *Psychological Bulletin* 138(6) |
| 10 | Interaction Design Foundation — Gestalt Principles topic page | 2024 | IxDF |
