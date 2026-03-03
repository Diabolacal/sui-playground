# CivilizationControl — Demo Beat Sheet v2

**Retention:** Carry-forward

> Competitive demo blueprint for the CivilizationControl hackathon submission video.
> Arc: Pain → Power → Policy → Denial → Revenue → Defense Mode → Commerce → Command
> Target duration: **3:00** (hard ceiling 3:15)
> Sources: v1 beat sheet, product vision, emotional objective, voice guide, claim-proof matrix, posture-switch validation, judging criteria digest
> Last updated: 2026-03-03

---

## Narrative Spine

> A frontier operator wakes up to chaos. By the end of this demo, every gate, turret, and trade post is under sovereign command — policy enforced, hostiles denied, revenue flowing, and the entire network locked down in one click.

**Arc:** Pain → Power → Policy → Denial → Revenue → Defense Mode → Commerce → Command

This is not a feature tour. It is three minutes of escalating authority. Each beat raises the stakes. The climax is Defense Mode — one action, infrastructure-wide state change, chain-enforced. Everything that follows proves the system pays for itself.

---

## Voice Rules

| Use | Never Use |
|---|---|
| Command Overview | Dashboard |
| Signal Feed | Notifications / Activity Log |
| Structures | Objects / Smart Assemblies |
| Operator | User / Admin |
| Deploy | Save / Submit |
| Posture | Mode / Setting |
| Denied | Rejected / Failed |

**Tone:** Mission control. Measured confidence. No hedging, no celebration, no jargon. The narrator describes outcomes, not mechanics. Every sentence earns its time.

---

## Five Non-Negotiable Proof Moments

If stability forces cuts, protect these five. Everything else is expendable.

| # | Proof Moment | Beat | What It Proves |
|---|---|---|---|
| 1 | Policy deploy tx digest | Beat 3 | Governance written on-chain in one action |
| 2 | Hostile denied — MoveAbort visible | Beat 4 | Chain enforcement. No appeal. |
| 3 | Toll collected — balance delta | Beat 5 | Revenue flows to operator atomically |
| 4 | Defense Mode — single tx digest containing posture + turrets | Beat 6 | Infrastructure-wide state change, one click |
| 5 | Trade settlement — buyer/seller balances | Beat 7 | Atomic commerce, no trust required |

---

## Transaction Latency Protocol

- Narrator stays ~2 seconds ahead of UI. Describe intent as the tx confirms, not after.
- If confirmation >3 seconds: continue narration. Never pause mid-sentence.
- If confirmation >5 seconds: hold on Signal Feed (always has prior entries). Retake the beat.
- Proof overlays appear ONLY after confirmation resolves on-screen. Never overlay an unresolved digest.

---

## Beats

### Beat 1 — Pain (0:00–0:18)

**Duration:** 18 seconds

**Spoken narration:**
> "You run twelve gates across three systems on EVE Frontier. Last night, two went offline. Nobody told you. Hostiles used the gap. Your pilots died hauling fuel through territory you thought you controlled."

*[Screen: black background. White text fades in, one line at a time, matching narration cadence. No terminal. No UI. Just the words.]*

> "Today, configuring one gate policy takes thirteen CLI commands. You have twelve gates."

*[Beat. Text: "156 commands. No visibility. No alerts. No control."]*

**On-screen:** Stark text-on-black. Optionally: a single raw CLI error screenshot flashes for 1 second before cutting to black again.

**Evidence:** None. This is the "before."

**Purpose:** Visceral, specific pain. Not abstract ("20 commands") — personal ("your pilots died"). The viewer must feel the gap before seeing the solution.

---

### Beat 2 — Power Reveal (0:18–0:38)

**Duration:** 20 seconds

**Spoken narration:**
> "CivilizationControl."

*[Hard cut from black to the Command Overview, fully loaded. Structures resolve — gates, turrets, trade posts, network nodes. Status indicators light green. Posture reads "Open for Business." Signal Feed scrolls with recent events.]*

*[Hold 2 seconds. Let the interface breathe.]*

> "Every structure you own. Every gate, turret, trade post, and network node. Status, policy, revenue — one sovereign view."

*[Camera moves slowly across the Command Overview: structure registry left, aggregate metrics center, Signal Feed right.]*

**On-screen:** Command Overview, fully populated. Package ID badge in corner.

**Evidence:** Package ID overlay: `[submission-package-ID]`

**Purpose:** Emotional pivot. Black despair → calm authority. The operator's frontier is under command. This is not a tool reveal — it is a power reveal.

**Three-Second Check:**
- What am I governing? Policies visible ✓
- What is under my authority? Structure registry ✓
- What is producing value? Revenue counter ✓
- What is at risk? Status indicators ✓

---

### Beat 3 — Policy (0:38–1:00)

**Duration:** 22 seconds

**Spoken narration:**
> "You decide who crosses and what they pay."

*[Click into a gate. Policy panel opens. Two rule slots: Tribe Filter and Toll.]*

> "Tribe filter: only Tribe 7. Toll: five SUI per jump."

*[Operator selects Tribe 7. Sets toll to 5 SUI. Clicks "Deploy Policy."]*

> "One action. Two rules. Deployed on-chain."

*[Confirmation: "Policy deployed. 2 rules active." Signal Feed updates.]*

**On-screen:** Gate detail → policy configuration → deploy → confirmation.

**Evidence overlay (post-production):**
- Tx digest of policy deployment
- Gate object showing `extension: Some(TypeName)` + 2 dynamic field rules

**Purpose:** Core value — governance through interface, not CLI. One click replaces 8+ commands. No jargon about typed witnesses or dynamic fields.

---

### Beat 4 — Denial (1:00–1:18)

**Duration:** 18 seconds

**Spoken narration:**
> "A hostile pilot — wrong tribe — tries to jump."

*[Signal Feed: new entry, red badge. "Jump denied. Tribe mismatch. Gate North-3."]*

*[Hold on the red entry for 2 seconds.]*

> "Denied. The chain enforced it. No override. No appeal."

**On-screen:** Signal Feed with denied entry. Red indicator.

**Evidence overlay (post-production):**
- Failed tx digest (stored on-chain, verifiable on any Sui explorer)
- MoveAbort code: `(tribe_permit, 0)` — ETribeMismatch
- Shortened pilot address

**Purpose:** First consequence. Policy → enforcement. The viewer sees that governance has teeth. The word "denied" lands with finality.

**Technical note:** MoveAbort reverts all effects including events. Detection is via wallet adapter failure response (`effects.status: "failure"`). No indexer needed.

---

### Beat 5 — Revenue (1:18–1:38)

**Duration:** 20 seconds

**Spoken narration:**
> "An ally — right tribe — jumps through. Toll collected: five SUI."

*[Signal Feed: new entry, green badge. "Jump completed. Toll: 5 SUI. Gate North-3."]*

> "Payment transfers to the operator. Atomic. Irrevocable."

*[Revenue counter in Command Overview ticks up.]*

> "The gate pays for itself."

**On-screen:** Signal Feed with toll entry. Revenue counter increments visibly.

**Evidence overlay (post-production):**
- Tx digest of tolled jump
- `TollCollectedEvent` (CC extension event)
- `JumpEvent` (world-contracts event)
- Balance delta: operator +5 SUI

**Purpose:** Same policy, opposite outcome. The gate discriminates and generates revenue. "The gate pays for itself" — six words that reframe infrastructure as an asset, not a cost.

**Precondition note:** `jump_with_permit` requires AdminACL-authorized sponsor co-signature (or sender in AdminACL). Ensure sponsor address enrolled before this beat.

---

### Beat 6 — Defense Mode (1:38–2:05)

**Duration:** 27 seconds. This is the climax. Give it room.

**Spoken narration:**
> "Threat inbound."

*[Pause. 1 second.]*

> "One click."

*[Operator clicks "Defense Mode."]*

*[Posture indicator shifts: "Open for Business" → "Defense Mode." Gate link lines shift green → amber. Turret icons flip grey → active. All indicators update in a wave across the Command Overview.]*

> "Gates lock to tribe-only. Turrets come online. Every structure responds. One transaction."

*[Signal Feed floods with posture events: "Posture: Defense Mode." "Turret Alpha: ONLINE." "Turret Bravo: ONLINE." Gate status updates.]*

*[Hold 3 seconds on the transformed Command Overview. Let the state change settle visually.]*

**On-screen:** The full Command Overview transforming — posture indicator, gate colors, turret states, Signal Feed cascade. This must feel like flipping a switch on an entire network.

**Evidence overlay (post-production):**
- **Single tx digest** containing all posture changes (validated: single PTB, ~2.3s latency)
- `PostureChangedEvent`: `old_mode: BUSINESS → new_mode: DEFENSE`
- Turret `StatusChangedEvent` × N (one per turret): `action: ONLINE`
- Before/after state summary: turrets OFFLINE→ONLINE, gates open→tribe-locked, toll removed

**Purpose:** The hammer moment. Everything the demo has built — policy, enforcement, revenue — now escalates to infrastructure-wide command. One human decision, one on-chain transaction, every structure responds. This is the "command layer" claim made undeniable.

**Technical reality (validated):** Single PTB contains 7–9 Move calls: `set_posture` + `set_tribe_config` + `clear_toll_config` + N × (`borrow_owner_cap<Turret>` → `turret::online` → `return_owner_cap`). Confirmed on localnet: both BUSINESS→DEFENSE and DEFENSE→BUSINESS pass. ~250ms on-chain execution. See [posture-switch validation](../sandbox/posture-switch-localnet-validation.md).

**Preconditions:** ≥1 turret anchored + offline, connected to online/fueled NetworkNode. Gates in "Open for Business" (tribe+toll). OwnerCap<Turret> accessible via character borrow. Energy reservation available.

---

### Beat 7 — Commerce (2:05–2:30)

**Duration:** 25 seconds

**Spoken narration:**
> "On the other side of the gate — a trade post."

*[Switch to Trade Post view. Storefront: fuel rods, ammo, repair paste. Prices listed.]*

> "Fuel rod. Thirty SUI."

*[Buyer clicks. Transaction confirms: "Trade settled. Fuel rod acquired."]*

> "Payment to the seller. Item to the buyer. One transaction, no trust required."

*[Signal Feed: "Trade settled. Fuel Rod. 30 SUI." Revenue counter ticks up again.]*

**On-screen:** Trade Post storefront → Buy → confirmation → Signal Feed + revenue update.

**Evidence overlay (post-production):**
- Tx digest of buy
- `TradeSettledEvent` (CC extension event)
- Balance deltas: buyer −30 SUI, seller +30 SUI
- Listing state: `is_active: true → false`

**Purpose:** Close the economic loop. Gate toll drove traffic. Commerce captured demand. The operator profits from both sides. Infrastructure → governance → revenue.

---

### Beat 8 — Command (2:30–2:50)

**Duration:** 20 seconds

**Spoken narration:**
> "Toll revenue from the gate. Trade revenue from the storefront. Turrets standing watch. Every structure reporting. All on-chain. All sovereign."

*[Pull back to full Command Overview. Signal Feed scrolling. Revenue totals visible. Posture: Defense Mode. Turrets: ONLINE. Gates: tribe-locked.]*

*[Hold 3 seconds on the full system view.]*

> "Your frontier. Your rules. Your revenue."

**On-screen:** Complete Command Overview — the operator's entire infrastructure under command.

**Evidence overlay (post-production):**
- Aggregate revenue total visible in UI
- Structure count + status summary
- Signal Feed showing mixed events (deny, toll, trade, posture)

---

### Beat 9 — Close (2:50–3:00)

**Duration:** 10 seconds

*[Title card fades in over the Command Overview:]*

> **"CivilizationControl — The command layer for frontier infrastructure."**

*[Hold 5 seconds. No narration. Let the tagline land.]*

**On-screen:** Title card. Clean. Final.

---

## Timing Summary

| Beat | Name | Start | End | Duration |
|---|---|---|---|---|
| 1 | Pain | 0:00 | 0:18 | 18s |
| 2 | Power Reveal | 0:18 | 0:38 | 20s |
| 3 | Policy | 0:38 | 1:00 | 22s |
| 4 | Denial | 1:00 | 1:18 | 18s |
| 5 | Revenue | 1:18 | 1:38 | 20s |
| 6 | Defense Mode | 1:38 | 2:05 | 27s |
| 7 | Commerce | 2:05 | 2:30 | 25s |
| 8 | Command | 2:30 | 2:50 | 20s |
| 9 | Close | 2:50 | 3:00 | 10s |
| **Total** | | | | **3:00** |

---

## Proof Moments Registry

Every major claim has a corresponding on-chain evidence moment.

| Beat | Claim | Evidence Artifact | Overlay Format |
|---|---|---|---|
| 3 — Policy | Governance deployed in one action | Tx digest + gate object with extension + 2 DF rules | Digest badge + before/after state |
| 4 — Denial | Hostile blocked by chain enforcement | Failed tx digest + MoveAbort `(tribe_permit, 0)` | Red overlay: digest + abort code |
| 5 — Revenue | Toll revenue flows to operator atomically | Tx digest + `TollCollectedEvent` + balance delta (+5 SUI) | Green overlay: digest + balance |
| 6 — Defense Mode | Infrastructure-wide state change, single tx | Single tx digest + `PostureChangedEvent` + N × `StatusChangedEvent` | Digest badge + before/after state matrix |
| 7 — Commerce | Atomic settlement, no counterparty risk | Tx digest + `TradeSettledEvent` + buyer/seller balance deltas | Digest badge + balance comparison |
| 8 — Command | System produces visible, aggregate value | Revenue totals in Command Overview + Signal Feed | UI screenshot (live) |

---

## Pre-Flight Checklist

Complete every item before pressing record. Incomplete items = retake risk.

### Environment

| # | Check | Status |
|---|---|---|
| 1 | Sui CLI connected to submission chain (or local devnet) | ☐ |
| 2 | `sui client active-env` returns expected environment | ☐ |
| 3 | World-contracts package ID recorded | ☐ |
| 4 | CC extension package published and package ID recorded | ☐ |
| 5 | Operator wallet connected to frontend | ☐ |

### Structures & State

| # | Check | Status |
|---|---|---|
| 6 | ≥2 gates online, linked, NO current extension (clean baseline) | ☐ |
| 7 | ≥1 trade post (SSU) online, authorized, ≥1 item listed | ☐ |
| 8 | ≥2 turrets anchored, connected to NetworkNode, status: OFFLINE | ☐ |
| 9 | ≥1 NetworkNode online, fueled, producing energy | ☐ |
| 10 | Fuel efficiency set for turret fuel type (AdminACL) | ☐ |
| 11 | Posture baseline: "Open for Business" (tribe+toll active on gates) | ☐ |

### Accounts

| # | Check | Status |
|---|---|---|
| 12 | Operator address funded (gas for all demo txs) | ☐ |
| 13 | Hostile pilot: character exists, tribe ≠ filter value, funded | ☐ |
| 14 | Ally pilot: character exists, tribe = filter value, funded ≥40 SUI | ☐ |
| 15 | Sponsor address enrolled in AdminACL (for jump txs) | ☐ |
| 16 | All account addresses shortened for overlay display | ☐ |

### Recording

| # | Check | Status |
|---|---|---|
| 17 | Browser: no bookmarks, history, autofill, other tabs visible | ☐ |
| 18 | Terminal history cleared (no unrelated commands visible) | ☐ |
| 19 | Beat 1 text-on-black assets prepared | ☐ |
| 20 | Post-production overlay templates ready (digest badge, balance delta, event) | ☐ |
| 21 | Narration script printed / teleprompter ready | ☐ |
| 22 | Screen resolution set (1920×1080 recommended for video) | ☐ |

---

## Failure Fallbacks

If a proof moment fails during recording, do NOT derail. Use these alternatives.

| Beat | Failure | Fallback |
|---|---|---|
| 3 — Policy | Deploy tx doesn't confirm in 5s | Retake. If persistent: pre-record the deploy, stitch in post. Signal Feed entry is fallback evidence. |
| 4 — Denial | Hostile jump doesn't produce clean MoveAbort | Show wallet error response ("transaction failed") + describe abort code verbally. Overlay can use a pre-captured digest from rehearsal. |
| 5 — Revenue | Revenue counter doesn't visibly tick | Narrate the toll collection. Show Signal Feed entry as primary evidence. Balance delta overlay in post-production using explorer data. |
| 6 — Defense Mode | Single PTB fails (gas budget / contention) | Fall back to Strategy B: separate policy tx + per-turret txs (~3 seconds total). Still fast, still impressive. Note: "orchestrated in under 3 seconds." Overlay shows multiple digests grouped. |
| 6 — Defense Mode | Turret `online()` aborts (already online or NWN not producing) | Pre-check all turret states + NWN energy before recording. If abort during take, restart from Beat 6 with corrected state. |
| 7 — Commerce | Trade tx fails | Pre-record a trade tx and stitch. Signal Feed entry for the recorded tx is fallback evidence. |
| Any | Explorer/wallet unresponsive | All proof overlays can be added in post-production from pre-captured data. Continue narration. |

---

## Fallback Variant: GateControl-Only (2:00)

If Trade Post UI is not ready, compress to this variant. Same emotional arc, no commerce beat.

| Beat | Name | Time | Duration |
|---|---|---|---|
| 1 | Pain | 0:00–0:15 | 15s |
| 2 | Power Reveal | 0:15–0:30 | 15s |
| 3 | Policy | 0:30–0:50 | 20s |
| 4 | Denial | 0:50–1:05 | 15s |
| 5 | Revenue | 1:05–1:25 | 20s |
| 6 | Defense Mode | 1:25–1:45 | 20s |
| 7 | Command + Close | 1:45–2:00 | 15s |

**Trigger:** Switch to fallback if Trade Post tx fails repeatedly, or TradePost UI is not stable at recording time. Record Beats 1–2 first (reusable across variants).

---

## Appendix A: What Changed vs v1

- **Opening rewritten:** Replaced generic "20 commands" + terminal scroll with specific human scenario (pilots dying, fuel haulers lost, 13×12=156 commands math). Text-on-black instead of terminal footage — forces emotional engagement, not technical recognition.
- **Beat structure compressed:** 8 named beats + close (v1: 7 beats + variants + optional accents). Tighter flow, no feature tourism.
- **Defense Mode elevated to climax:** Moved from Beat 5b (a sub-beat, half-hidden) to Beat 6 — the peak of the arc. Given 27 seconds (was 15). Now the single loudest moment.
- **Revenue beat verbalized:** Added "The gate pays for itself" — a one-line reframe of infrastructure as asset. v1 showed revenue updating silently.
- **Denial language hardened:** "Denied. The chain enforced it. No override. No appeal." replaces softer "Blocked. No passage. No appeal. On-chain enforcement."
- **Timing tightened:** 3:00 flat (v1: 3:10). Cut optional ZK accent and preset switching accent from the primary flow — these can supplement but don't compete for the main 3 minutes.
- **Failure fallbacks formalized:** Full table mapping each beat to a concrete fallback action. v1 had a general "fallback variant" but no per-beat failure protocol.
- **Pre-flight checklist expanded:** 22 items covering environment, structure state, accounts, and recording setup. v1 had a partial evidence capture checklist.
- **Tagline sharpened:** "The command layer for frontier infrastructure" replaces "The Frontier Control Room."
- **Beat 1 removes Discord screenshot:** The text-on-black format is more emotionally controlled than mixing terminal footage + Discord screenshots + error messages.

## Appendix B: Why This Improves Judging Outcomes

- **Concept & Feasibility:** Opening pain is now a concrete scenario judges can feel ("your pilots died"), not an abstract complaint about CLI complexity. The feasibility claim lands harder because the problem is visceral.
- **Visual Presentation & Demo:** Defense Mode as a dedicated climax beat (27s, full visual transformation) gives judges one unforgettable moment instead of spreading impact across sub-beats. Text-on-black opening is a deliberate cinematic choice that signals production quality.
- **Player Utility:** "The gate pays for itself" reframes CivilizationControl from a convenience tool to an economic engine. Judges evaluating player utility will hear a revenue argument, not just a UX argument.
- **Mod Design:** Single PTB posture switch (validated, with tx digest) proves system-level design, not feature-level. Judges see architecture thinking.
- **Proof discipline:** Five non-negotiable proof moments mapped to specific on-chain artifacts. Judges never have to wonder "is this real?" — every claim has a deterministic evidence anchor.
- **Compression at 3:00:** Respects judges' time. Every second is earned. No padding, no optional accents diluting the core arc. The fallback variant ensures delivery even under instability.
- **EVE Frontier Relevance & Vibe:** The narrative is explicitly frontier governance — tribes, territory, hostiles, turrets. Not generic blockchain UX. Judges evaluating "vibe" hear the right language throughout.
- **UX & Usability:** "One click" appears three times organically (deploy policy, buy item, Defense Mode) — each proving a different facet of usability without ever explicitly saying "our UX is good."

---

## Do Not Show During Recording

- Private keys, seed phrases, mnemonics, `.env` files, keystore contents
- Full wallet addresses (use shortened: `0x1a2b…3c4d`)
- Browser bookmarks, history, autofill, other tabs
- Local file paths, terminal history from unrelated sessions
- Devnet reset warnings, chain genesis messages
- Move function names, PTB details, dynamic field terminology — in narration or visible UI

---

## Demo Account Roles

| Role | Description | Address |
|---|---|---|
| **Operator** | Owns structures. Receives all revenue. Signs policy + posture txs. | `[TBD]` |
| **Hostile Pilot** | Character with tribe ≠ filter value. Must be denied at gate. | `[TBD]` |
| **Ally Pilot / Buyer** | Character with tribe = filter value. Jumps gate (tolled), buys at trade post. | `[TBD]` |
| **Sponsor** | AdminACL-authorized co-signer for jump txs (if sponsored tx path). | `[TBD]` |

---

## Recommended Recording Order

1. Prepare all overlay templates + Beat 1 text assets
2. Run full tx rehearsal: capture all proof digests, balances, events for overlays
3. Record live UI: Beat 2 → 3 → 4 → 5 → 6 → 7 → 8 (continuous if possible)
4. Record Beat 1 (text-on-black, separate)
5. Record Beat 9 (title card, separate)
6. Assemble in editor: Beat 1 → 2–8 (live) → 9. Add proof overlays in post.

---

## References

- [Demo Beat Sheet v1](civilizationcontrol-demo-beat-sheet.md)
- [Claim → Proof Matrix](civilizationcontrol-claim-proof-matrix.md)
- [Posture-Switch Localnet Validation](../sandbox/posture-switch-localnet-validation.md)
- [Product Vision](../strategy/civilization-control/civilizationcontrol-product-vision.md)
- [Hackathon Emotional Objective](../strategy/civilization-control/civilizationcontrol-hackathon-emotional-objective.md)
- [Voice & Narrative Guide](../strategy/civilization-control/civilizationcontrol-voice-and-narrative.md)
- [Hackathon Rules Digest](../research/hackathon-event-rules-digest.md)
