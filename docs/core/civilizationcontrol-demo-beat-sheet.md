# CivilizationControl — Demo Beat Sheet

**Retention:** Carry-forward

> Structured beat-by-beat demo plan for the CivilizationControl hackathon submission video.
> Structure: Control → Consequence → Revenue (single continuous loop)
> Sources: civilizationcontrol-product-vision.md, civilizationcontrol-hackathon-emotional-objective.md, civcontrol-independent-audit.md §6, civilizationcontrol-voice-and-narrative.md
> Last updated: 2026-02-18

---

## Narrative Spine

One pilot's journey through the operator's frontier:

> **Set gate policy → Hostile denied → Ally tolled → Ally buys at TradePost → Revenue from both flows visible in Signal Feed**

This is one uninterrupted loop: **Control → Consequence → Revenue.** Every beat flows into the next. No feature tourism. No screen-hopping. One operator, one frontier, one governance story.

---

## Voice & Terminology Rules

All narration and on-screen labels use canonical terminology per the [Voice & Narrative Guide](../strategy/civilizationcontrol-voice-and-narrative.md):

| Use | Do Not Use |
|---|---|
| Command Overview | Dashboard |
| Signal Feed | Activity / Notifications / Log |
| Structures / Gates / Trade Posts | Objects / Items / Smart Assemblies |
| Configuration | Settings |
| Operator | User / Admin |
| Deploy | Submit / Save |
| Fault | Error |
| Online / Offline | Active / Inactive |
| Signals | Notifications |

**Narration tone:** Steady, unhurried, measured. The narrator describes governance decisions and outcomes — not button clicks and UI features. Present what exists with full confidence. No hedging, no apology, no celebration.

### If We Only Show Five Overlays…

These are the five non-negotiable proof moments. If time or stability forces cuts, every other overlay is expendable — these are not. Each maps to a ★ Tier A row in the [Claim → Proof Matrix](civilizationcontrol-claim-proof-matrix.md):

1. **Policy deploy tx** (Beat 3) — proves governance was written on-chain.
2. **Hostile denied tx** (Beat 4) — proves the policy enforced denial.
3. **Ally tolled tx + balance delta** (Beat 5) — proves revenue flowed to operator.
4. **Trade buy tx + balance deltas** (Beat 6) — proves atomic commerce settlement.
5. **Aggregate revenue in Command Overview** (Beat 7) — proves the system produces visible value.

---

## Primary Demo Variant: 3 Minutes (Full Loop)

### Beat 1 — The Problem (0:00–0:25)

**Timing:** 25 seconds

**Narration:**
> "This is what managing gates on EVE Frontier looks like today."

*[Screen: terminal with raw `sui client ptb` commands scrolling — the 13-step gate lifecycle. Dense, technical, unreadable.]*

> "Twenty commands to configure one gate policy. No visibility. No monitoring. No way to see who's jumping through your territory or what they're paying."

*[Quick cut: error message from a failed PTB. Discord screenshot: "is the gate down?" message.]*

> "The on-chain primitives are powerful. The operator experience doesn't exist."

**On-screen action:** Raw CLI footage, error messages, Discord coordination screenshots.

**Evidence overlay:** None (this is the "before" state).

**Purpose:** Establish pain. Make the viewer feel the gap between what the chain can do and what an operator can actually do.

---

### Beat 2 — The Reveal: Command Overview (0:25–0:50)

**Timing:** 25 seconds

**Narration:**
> "CivilizationControl changes that."

*[Cut to: Command Overview loading. Clean UI. Structure sidebar populates — gates, trade posts, NWNs. Status indicators resolve to green.]*

> "Every structure you own. Status. Links. Revenue. One view."

*[Camera slowly pans across the Command Overview: structure registry on the left, aggregate stats (total structures, total revenue, active policies), Signal Feed scrolling on the right.]*

*[Hold for 2 seconds on the full view. Let it breathe.]*

**On-screen action:** Command Overview fully populated with operator's structures.

**Evidence overlay:** Package ID badge in corner: `[submission-package-ID]`

**Purpose:** Emotional pivot. The "before" was pain; the "after" is calm authority. The operator's frontier is under command.

**Three-Second Check (per emotional objective §5):**
- What am I governing? — Policies visible in structure cards ✓
- What is under my authority? — Structure registry with ownership ✓
- What is producing value? — Revenue counter ✓
- What is at risk? — Fuel/status indicators ✓
- What am I building? — Structure count ✓

---

### Beat 3 — Control: Set Gate Policy (0:50–1:20)

**Timing:** 30 seconds

**Narration:**
> "You decide who passes through your gates and what they pay."

*[Click into a gate. Policy panel opens. Two rule types visible: Tribe Filter and Toll.]*

> "Tribe filter: only Tribe 7 pilots pass. Toll: 5 SUI per jump. Both rules, composing on the same gate."

*[Operator selects Tribe 7 from dropdown. Sets toll to 5 SUI. Clicks "Deploy Policy."]*

> "One action. Policy deployed on-chain."

*[Confirmation appears: "Policy deployed. 2 rules active on Gate North-3."]*

*[Hold for 2 seconds.]*

**On-screen action:** Rule configuration UI → Deploy Policy → confirmation message.

**Evidence overlay required:**
- Tx digest of policy deployment: `[TBD-digest]`
- Gate object showing `extension: Some(TypeName)` after deployment
- Before/after: gate had no rules → gate now has TribeRule + TollRule dynamic fields

**Purpose:** Demonstrate the core value proposition — governance through UI, not CLI. One click replaces 8+ commands.

---

### Beat 4 — Consequence A: Hostile Denied (1:20–1:45)

**Timing:** 25 seconds

**Narration:**
> "A hostile pilot — wrong tribe — attempts to jump."

*[Signal Feed updates: new entry appears. Red indicator. "Jump denied. Tribe mismatch. Pilot [address]. Gate North-3."]*

> "Blocked. No passage. No appeal. On-chain enforcement."

*[Hold on the denied entry for 2 seconds.]*

**On-screen action:** Signal Feed shows denied jump event with red status badge.

**Evidence overlay required:**
- Tx digest of the denied attempt: `[TBD-digest]` (or sandbox reference: MoveAbort ETribeMismatch code 0)
- Event detail: tribe_id mismatch highlighted
- Pilot address visible (shortened)

**Purpose:** First consequence of the policy. The operator set a rule; the chain enforced it. Governance → denial.

---

### Beat 5 — Consequence B: Ally Tolled (1:45–2:10)

**Timing:** 25 seconds

**Narration:**
> "An ally — matching tribe — jumps through. Toll paid: 5 SUI."

*[Signal Feed updates: new entry. Green indicator. "Jump completed. Toll: 5 SUI. Pilot [address]. Gate North-3."]*

> "Tribe matches. Payment transfers to the operator's address. Passage granted. One atomic transaction."

*[Revenue counter in the Command Overview ticks up by 5 SUI.]*

**On-screen action:** Signal Feed shows permitted jump + toll payment. Revenue counter increments.

**Evidence overlay required:**
- Tx digest of the tolled jump: `[TBD-digest]`
- Custom `TollCollectedEvent` from extension (NOT `AccessGrant` — that is a sandbox mock, not a world-contracts event; see [read-path validation](../architecture/read-path-architecture-validation.md) §2.4)
- Balance delta: operator address +5 SUI
- `JumpEvent` confirmation (world-contracts)

**Purpose:** Second consequence. Same policy, different outcome. The gate discriminates by tribe and collects revenue. Control → Consequence → Revenue in one beat.

---

### Beat 6 — Commerce: Ally Buys at TradePost (2:10–2:40)

**Timing:** 30 seconds

**Narration:**
> "The same pilot lands at a Trade Post on the other side of the gate."

*[Switch to Trade Post view. SSU storefront: fuel rods, ammo, repair paste — each with prices.]*

> "Fuel rod. 30 SUI. One click."

*[Buyer selects fuel rod listing. Clicks Buy. Transaction confirmation: "Trade settled. Fuel Rod acquired for 30 SUI."]*

> "Atomic settlement. Payment to the seller. Item to the buyer. No counterparty risk. No coordination."

*[Signal Feed updates: "Trade settled. Fuel Rod. 30 SUI. Buyer: [address]."]*

*[Revenue counter ticks up again.]*

**On-screen action:** TradePost browse → Buy → confirmation → Signal Feed update → revenue increment.

**Evidence overlay required:**
- Tx digest of the buy: `[TBD-digest]` (or sandbox reference: `3GtyTmJmLZxLQ3sqcuGTwoEm566Ts87c8Kedqjfh1NJ2`)
- ItemPurchased event
- Balance deltas: buyer −30 SUI, seller +30 SUI
- Listing state: `is_active: true` → `is_active: false`

**Purpose:** Complete the economic loop. Gate toll drove foot traffic. Commerce captured the demand. The operator profits from both sides.

---

### Beat 7 — The System: Revenue Visible (2:40–3:00)

**Timing:** 20 seconds

**Narration:**
> "Toll revenue from the gate. Trade revenue from the storefront. Both visible. Both on-chain. Both under your command."

*[Pull back to Command Overview. Full view: gates with green status, trade posts with active listings, Signal Feed scrolling with jumps and transactions.]*

> "Your gates. Your rules. Your revenue."

*[Hold for 3 seconds on the full Command Overview. Let the system speak.]*

*[Title card: "CivilizationControl — The Frontier Control Room"]*

**On-screen action:** Full Command Overview showing complete infrastructure state.

**Evidence overlay required:**
- Aggregate revenue total visible in Command Overview
- Structure count badge
- Signal Feed showing mixed jump + trade events

**Purpose:** Close the loop. Pull back from the individual beats to the system view. The operator's frontier is under command. Governance produced consequence. Consequence produced revenue. The system works.

---

## Fallback Demo Variant: GateControl-Only (2 Minutes)

Use this variant if TradePost UI is not ready at demo recording time. Covers GateControl end-to-end with the same Control → Consequence → Revenue structure, omitting commerce.

### Fallback Beat 1 — The Problem (0:00–0:20)

**Timing:** 20 seconds

**Narration:**
> "Managing gate policy on EVE Frontier today requires raw CLI commands. No visibility. No monitoring."

*[Screen: raw `sui client ptb` output, error messages.]*

> "The primitives exist. The control layer doesn't."

**Evidence overlay:** None.

---

### Fallback Beat 2 — The Reveal (0:20–0:40)

**Timing:** 20 seconds

**Narration:**
> "CivilizationControl is the command layer."

*[Command Overview loads. Gates visible with status indicators.]*

> "Every gate. Status. Policy. Revenue. One view."

**Evidence overlay:** Package ID badge.

---

### Fallback Beat 3 — Set Gate Policy (0:40–1:05)

**Timing:** 25 seconds

**Narration:**
> "Two rules on one gate: tribe filter and toll. Deploy."

*[Operator configures tribe filter + toll → "Deploy Policy" → confirmation.]*

**Evidence overlay required:**
- Tx digest: `[TBD-digest]`
- Gate object with extension + dynamic field rules

---

### Fallback Beat 4 — Hostile Denied (1:05–1:25)

**Timing:** 20 seconds

**Narration:**
> "Hostile pilot. Wrong tribe. Blocked on-chain."

*[Signal Feed: denied jump, red indicator.]*

**Evidence overlay required:**
- Tx digest: `[TBD-digest]`
- MoveAbort ETribeMismatch event

---

### Fallback Beat 5 — Ally Tolled + Revenue (1:25–1:50)

**Timing:** 25 seconds

**Narration:**
> "Ally pilot. Tribe matches. Toll paid: 5 SUI. Passage granted."

*[Signal Feed: permitted jump, green indicator. Revenue counter increments.]*

> "Revenue flows to the operator. On-chain settlement. Real-time visibility."

**Evidence overlay required:**
- Tx digest: `[TBD-digest]`
- Balance delta: operator +5 SUI
- AccessGrant event

---

### Fallback Beat 6 — Close (1:50–2:00)

**Timing:** 10 seconds

**Narration:**
> "Your gates. Your rules. Your revenue. CivilizationControl."

*[Full Command Overview. Hold 3 seconds.]*

*[Title card.]*

**Evidence overlay required:**
- Revenue total in Command Overview
- Signal Feed with mixed deny + toll events

---

## Optional ZK Accent Segment (30 seconds, insert before closing beat if stable)

If ZK GatePass is integrated and stable, insert this 30-second segment before the closing beat in the primary variant (between Beat 6 and Beat 7, adjusting timing to stay within 3:30 max):

**Narration:**
> "And for private passage — zero-knowledge gate access. The pilot proves membership without revealing identity. The proof verifies on-chain. The gate opens."

*[Signal Feed: "ZK pass verified. Proof valid. Gate North-5." Green indicator with a distinctive ZK badge.]*

> "Groth16 verification on Sui. Under a thousand MIST in gas. Privacy-preserving governance."

**Evidence overlay required:**
- Tx digest: `AkEBgfdpGxHDNXVJ6HBAKFooWnD6F47gcYAzPnCbahQq` (or submission equivalent)
- VerificationResult event: `is_valid: true`
- Gas callout: ~1,009,880 MIST
- Circuit stats badge: "Merkle depth 10, 2,430 constraints, 128-byte proof"

---

## Evidence Capture Checklist (Pre-Recording)

Before pressing record, confirm every required artifact is captured and accessible for overlay:

| Beat | Required Artifact | Captured? |
|---|---|---|
| Beat 3 | Policy deployment tx digest | ☐ |
| Beat 3 | Gate object state (before/after extension + dynamic fields) | ☐ |
| Beat 4 | Denied jump tx digest + error event | ☐ |
| Beat 5 | Tolled jump tx digest + AccessGrant event | ☐ |
| Beat 5 | Operator balance delta (+toll amount) | ☐ |
| Beat 6 | Buy tx digest + ItemPurchased event | ☐ |
| Beat 6 | Buyer/seller balance deltas | ☐ |
| Beat 6 | Listing state before/after (is_active) | ☐ |
| Beat 7 | Aggregate revenue total screenshot | ☐ |
| ZK (opt) | ZK verify tx digest + VerificationResult event | ☐ |
| All | Package ID(s) for submission chain | ☐ |
| All | Account addresses (operator, hostile pilot, ally pilot) | ☐ |

---

## Timing Summary

| Variant | Duration | Beats | Features Covered |
|---|---|---|---|
| **Primary** | 3:00 | 7 | GateControl + TradePost |
| **Primary + ZK** | 3:30 | 8 | GateControl + TradePost + ZK accent |
| **Fallback (GateControl-only)** | 2:00 | 6 | GateControl only |

---

## Narration Anti-Patterns (Avoid)

Per the [Voice & Narrative Guide §7](../strategy/civilizationcontrol-voice-and-narrative.md):

- **No feature tourism.** Don't click through every screen. Show less. Show it well.
- **No technical narration.** Don't say "this calls `issue_jump_permit` with a typed witness." Say "the gate enforces the policy on-chain."
- **No apology.** Don't say "this is just a prototype." Present what exists with full confidence.
- **No speed.** If the demo feels rushed, cut scope. Never speed up narration to fit features.
- **No celebration.** No "Congratulations!" or "Success!" Confirmations are stated with finality: "Policy deployed."
- **No hedging.** No "something may have gone wrong." Faults are facts.

---

## References

- [Product Vision — Demo Narrative](../strategy/civilizationcontrol-product-vision.md)
- [Hackathon Emotional Objective](../strategy/civilizationcontrol-hackathon-emotional-objective.md)
- [Independent Audit §6](../research/civcontrol-independent-audit.md)
- [Voice & Narrative Guide](../strategy/civilizationcontrol-voice-and-narrative.md)
- [Claim → Proof Matrix](civilizationcontrol-claim-proof-matrix.md)
