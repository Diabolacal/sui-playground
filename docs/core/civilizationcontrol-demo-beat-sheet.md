# CivilizationControl — Demo Beat Sheet

**Retention:** Carry-forward

> Structured beat-by-beat demo plan for the CivilizationControl hackathon submission video.
> Structure: Control → Consequence → Revenue (single continuous loop)
> Sources: civilizationcontrol-product-vision.md, civilizationcontrol-hackathon-emotional-objective.md, civcontrol-independent-audit.md §6, civilizationcontrol-voice-and-narrative.md
> Last updated: 2026-02-19

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

## Transaction Latency Handling

- **Confirmation >5 seconds:** Continue narration over the wait. Never pause mid-sentence. If confirmation hasn't arrived by the end of the current narration line, hold on the UI (the spinner or pending state is acceptable for 2–3 seconds of dead air max).
- **Proof overlays:** Only insert after tx confirmation is visible on-screen. Never overlay a digest that hasn't resolved.
- **Dead air prevention:** If a tx is slow during a live capture, cut to a pre-recorded proof overlay or hold on the Signal Feed (which always has prior entries to show). Re-take the beat if the gap is >5 seconds.
- **Narration pacing:** The narrator should be ~2 seconds ahead of the UI action. Describe intent ("Policy deployed on-chain") as the tx is confirming, not after.

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

**Preconditions:**
- Pre-recorded terminal session with `gate_lifecycle_rehearsal.sh` output (or raw `step*.sh` commands)
- Discord screenshot prepared ("is the gate down?" message)
- Failed PTB error screenshot prepared

**Capture mode:** Pre-recorded CLI insert + static screenshot overlays.

---

### Beat 2 — The Reveal: Command Overview (0:25–0:50)

**Timing:** 25 seconds

**Narration:**
> "CivilizationControl changes that."

*[Cut to: Command Overview loading. Clean UI. Structure sidebar populates — gates, trade posts, NWNs. Status indicators resolve to green. *(If Strategic Network Map is implemented:)* Strategic Network Map renders — system nodes with structure badges, gate link lines connecting them.]*

> "Every structure you own. Status. Links. Revenue. One view."

*[Camera slowly pans across the Command Overview: structure registry on the left, aggregate stats (total structures, total revenue, active policies), Signal Feed scrolling on the right. *(If Strategic Network Map ready:)* Strategic Network Map showing gate link topology (top). *(If EF-Map Cosmic Context ready:)* EF-Map panel shows territory in the universe.]*

*[Hold for 2 seconds on the full view. Let it breathe.]*

**On-screen action:** Command Overview fully populated with operator's structures. *(If Strategic Network Map available:)* Strategic Network Map shows governance topology — system nodes, link lines, status colors. *(If EF-Map panel available:)* EF-Map panel shows territory in the universe. *(Minimum:)* Structure list with status indicators and aggregate metrics.

**Evidence overlay:** Package ID badge in corner: `[submission-package-ID]`

**Purpose:** Emotional pivot. The "before" was pain; the "after" is calm authority. The operator's frontier is under command.

**Three-Second Check (per emotional objective §5):**
- What am I governing? — Policies visible in structure cards ✓
- What is under my authority? — Structure registry with ownership ✓
- What is producing value? — Revenue counter ✓
- What is at risk? — Fuel/status indicators ✓
- What am I building? — Structure count ✓

**Preconditions:** Frontend running + connected to submission chain. Operator wallet connected. ≥3 structures online (2 gates + 1 trade post). Package ID known for overlay.

**Capture mode:** Live UI recording.

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

**Preconditions:** Gate online + linked, NO current extension (clean state). Operator has gas for publish + authorize. Extension package ready. Tribe 7 configured in dropdown.

**Capture mode:** Live UI recording. Proof overlay (tx digest + gate object diff) in post.

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
- Tx digest of the denied attempt: `[TBD-digest]` — failed tx IS stored on-chain and verifiable on any Sui explorer
- MoveAbort code: `(extension_module::tribe_permit, 0)` = ETribeMismatch — deterministic, distinguishable from other abort reasons
- Pilot address visible (shortened)
- **Mechanism:** Wallet adapter returns failure response synchronously — `effects.status: "failure"`, `effects.status.error` contains module + abort code. Dashboard parses this to display "Jump denied. Tribe mismatch." No indexer or event subscription needed. **Note:** MoveAbort reverts ALL effects including events — no on-chain events from denied jumps. Detection relies entirely on the wallet adapter failure response or explorer tx status.

**Purpose:** First consequence of the policy. The operator set a rule; the chain enforced it. Governance → denial.

**Preconditions:** Gate has tribe filter active (Beat 3). Hostile pilot funded with gas, character exists with tribe ≠ 7, no valid JumpPermit.

**Capture mode:** Live UI recording (Signal Feed). Proof overlay (tx digest + MoveAbort) in post.

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
- `TollCollectedEvent` (our extension event — NOT a world-contracts event)
- `JumpEvent` confirmation (world-contracts)

**Purpose:** Second consequence. Same policy, different outcome. The gate discriminates by tribe and collects revenue. Control → Consequence → Revenue in one beat.

**Preconditions:** Gate has tribe filter + toll active (Beat 3). Ally pilot funded ≥10 SUI, character tribe = 7. Operator balance noted before jump. **Sponsorship:** `jump_with_permit` requires AdminACL-authorized sponsor co-signature (or sender in AdminACL). Ensure sponsor address is enrolled before this beat.

**Capture mode:** Live UI recording (Signal Feed + revenue counter). Proof overlay (tx digest + balance delta + events) in post.

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
- `TradeSettledEvent` (our extension event — NOT a world-contracts event; replaces sandbox mock `ItemPurchased`)
- Balance deltas: buyer −30 SUI, seller +30 SUI
- Listing state: `is_active: true` → `is_active: false`

**Purpose:** Complete the economic loop. Gate toll drove foot traffic. Commerce captured the demand. The operator profits from both sides.

**Preconditions:** SSU Trade Post deployed + authorized + online. ≥1 item listed (e.g., Fuel Rod at 30 SUI). Buyer funded ≥35 SUI. Seller balance noted.

**Capture mode:** Live UI recording (TradePost + Signal Feed). Proof overlay (tx digest + balance deltas + listing state) in post.

---

### Beat 7 — The System: Revenue Visible (2:40–3:00)

**Timing:** 20 seconds

**Narration:**
> "Toll revenue from the gate. Trade revenue from the storefront. Both visible. Both on-chain. Both under your command."

*[Pull back to Command Overview. Full view: Signal Feed scrolling with jumps and transactions. *(If Strategic Network Map ready:)* Strategic Network Map showing gate topology with green link lines and active status nodes. Trade posts with active listings. *(If EF-Map ready:)* EF-Map cosmic context expanded — operator's territory highlighted in the starfield, colored link lines drawn between linked systems.]*

> "Your gates. Your rules. Your revenue."

*[Hold for 3 seconds on the full Command Overview with topology and cosmic context visible. Let the system speak.]*

*[Title card: "CivilizationControl — The Frontier Control Room"]*

**On-screen action:** Full Command Overview showing complete infrastructure state.

**Evidence overlay required:**
- Aggregate revenue total visible in Command Overview
- Structure count badge
- Signal Feed showing mixed jump + trade events

**Purpose:** Close the loop. Pull back from the individual beats to the system view. The operator's frontier is under command. Governance produced consequence. Consequence produced revenue. The system works.

**Preconditions:** All prior beats completed (Beats 3–6 txs confirmed). Command Overview reflects current state. Signal Feed populated.

**Capture mode:** Live UI recording (static hold). Title card in post.

---

## Fallback Demo Variant: GateControl-Only (2 Minutes)

Use this variant if TradePost UI is not ready at demo recording time. Covers GateControl end-to-end with the same Control → Consequence → Revenue structure, omitting commerce.

### Fallback Trigger Conditions

Switch from primary to fallback if: TradePost tx fails repeatedly on submission chain, explorer cannot render tx within 30s, wallet adapter disconnects (>2 retries), or primary variant exceeds 3:15 after two takes. Record Beats 1–2 first (reusable across variants).

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
- MoveAbort ETribeMismatch code (from wallet failure response)

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
- `TollCollectedEvent` (extension event)

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

## In-Game Demo Variant (Supplementary)

**Purpose:** Demonstrate live Frontier integration for "Best Live Frontier Integration" bonus (Stillness deployment).

**Context:** The in-game embedded browser provides a read-only view (no Sui wallet). This variant supplements the primary demo video with in-game footage showing CivilizationControl operating live within EVE Frontier.

### Capture Strategy

The in-game variant is NOT a standalone demo — it supplements the primary 3-minute loop captured in an external browser. In-game footage serves as evidence of live deployment.

| Capture Order | Content | What It Proves |
|--------------|---------|---------------|
| 1 | Navigate to a gate structure in-game → DApp loads in embedded browser | Live Frontier integration works |
| 2 | Command Overview visible in portrait format (~787×1198) | UI renders correctly in-game |
| 3 | Signal Feed shows recent gate events (from external browser demo beats) | Real-time data flows to in-game view |
| 4 | "Viewing Mode" badge visible | Context-appropriate UX (read-only acknowledged) |
| 5 | Navigate to Trade Post SSU → listings visible | SSU storefront accessible in-game |

### In-Game Viewport Note

The in-game browser renders at approximately 787×1198 portrait. Demo captures should ensure:
- Text is readable at this resolution
- Card layouts stack correctly (no table overflow)
- "Viewing Mode" badge is clearly visible
- "Open in Browser" link is prominent for write operations

### When to Include

Include in-game footage only if:
1. DApp is deployed to Cloudflare Pages (HTTPS)
2. Structure DApp URLs are configured in-game
3. Portrait layout validates at 787×1198 (Check 11 passed)
4. Stillness deployment has been live for ≥48 hours before submission

If any prerequisite fails, omit in-game footage entirely — the primary demo stands alone.

---

## Optional ZK Accent Segment (30 seconds, insert before closing beat if stable)

If ZK GatePass is integrated and stable, insert this 30-second segment before the closing beat in the primary variant (between Beat 6 and Beat 7, adjusting timing to stay within 3:30 max):

**Narration:**
> "And for private passage — zero-knowledge gate access. The pilot proves membership without revealing identity. The proof verifies on-chain. The gate opens."

*[Signal Feed: "ZK pass verified. Proof valid. Gate North-5." Green indicator with a distinctive ZK badge.]*

> "Groth16 verification on Sui. About a thousand MIST in gas. Privacy-preserving governance."

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
| Beat 4 | Denied jump tx digest + MoveAbort code (from wallet failure response, not events) | ☐ |
| Beat 5 | Tolled jump tx digest + `TollCollectedEvent` (extension event) | ☐ |
| Beat 5 | Operator balance delta (+toll amount) | ☐ |
| Beat 6 | Buy tx digest + `TradeSettledEvent` (extension event) | ☐ |
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

## Demo Account Roles

Role placeholders — populate with real addresses during pre-recording setup.

| Role | Description | Address |
|---|---|---|
| **Operator** | Owns structures. Receives toll + trade revenue. Signs policy txs. | `[TBD]` |
| **Hostile Pilot** | Wrong tribe (≠ filter value). Must be denied. | `[TBD]` |
| **Ally Pilot / Buyer** | Matching tribe. Jumps gate (tolled), buys at trade post. | `[TBD]` |
| **Trade Seller** | Stocks SSU. May be Operator or separate address. | `[TBD]` |
| **Sponsor** | Game server co-signer for sponsored txs. | `[TBD]` |

---

## Recommended Recording Order

Capture in this sequence for non-linear editing flexibility:

1. Pre-recording CLI terminal session (Beat 1 footage) + all proof overlay captures (run txs, screenshot digests/events/balances)
2. Live UI: Beat 2 (reveal) → Beat 3 (deploy) → Beat 4 (denied) → Beat 5 (tolled) → Beat 6 (buy) → Beat 7 (hold)
3. Title card + ZK accent (optional) captured separately

---

## Do Not Show During Recording

- Private keys, seed phrases, mnemonics, `.env` files, keystore contents
- Full wallet addresses (use shortened: `0x1a2b…3c4d`), mainnet balances
- Browser bookmarks, history, autofill, other tabs (email/chat/social)
- Local file paths, terminal history from unrelated sessions
- Devnet reset warnings, chain genesis messages

---

## References

- [Product Vision — Demo Narrative](../strategy/civilizationcontrol-product-vision.md)
- [Demo Evidence Appendix](../operations/demo-evidence-appendix.md)
- [Hackathon Emotional Objective](../strategy/civilizationcontrol-hackathon-emotional-objective.md)
- [Independent Audit §6](../research/civcontrol-independent-audit.md)
- [Voice & Narrative Guide](../strategy/civilizationcontrol-voice-and-narrative.md)
- [Claim → Proof Matrix](civilizationcontrol-claim-proof-matrix.md)