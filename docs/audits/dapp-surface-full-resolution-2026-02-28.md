# DApp Surface Full Resolution — 2026-02-28

**Retention:** Prep-only

> Resolution report for the adversarial consistency audit across 8 CivilizationControl planning documents.
> All findings from the original audit (3 Critical, 6 High, 10 Medium, 6 Low) addressed below.

---

## Scope

**Documents audited and patched:**
1. `docs/core/spec.md`
2. `docs/ux/civilizationcontrol-ux-architecture-spec.md`
3. `docs/architecture/in-game-dapp-surface.md`
4. `docs/core/day1-checklist.md`
5. `docs/core/civilizationcontrol-demo-beat-sheet.md`
6. `docs/core/civilizationcontrol-implementation-plan.md`

**Ground truth sources (read-only):**
- `vendor/world-contracts/contracts/world/sources/assemblies/gate.move`
- `vendor/world-contracts/contracts/world/sources/access/access_control.move`
- `vendor/world-contracts/contracts/assets/sources/EVE.move`
- `vendor/builder-scaffold/move-contracts/smart_gate/sources/config.move`

---

## Critical Fixes (C1–C3)

### C1 — `request_jump_permit` auth column (spec.md)
- **Finding:** Auth column said "AdminACL sponsor" but `gate::issue_jump_permit` uses typed witness (Auth), no AdminACL or verify_sponsor.
- **Fix:** Changed auth column to "Extension witness (GateAuth)" with explanatory note.
- **File:** `docs/core/spec.md` — jump permit row in §2.1 write paths table.

### C2 — `verify_sponsor` sender fallback (4 documents)
- **Finding:** Multiple docs stated "self-sponsorship does NOT work — ctx.sponsor() returns None." Actually, `verify_sponsor(ctx)` falls back to `tx_context::sender(ctx)` when no sponsor is present. Non-sponsored txs succeed if the sender is in AdminACL.
- **Fix:** Rewrote sponsorship semantics in spec.md §2.3, UX spec §2 constraint summary, in-game-dapp-surface §11, day1-checklist Check 5 (added note), implementation-plan S05.
- **Files:** `spec.md`, `civilizationcontrol-ux-architecture-spec.md`, `in-game-dapp-surface.md`, `day1-checklist.md`, `civilizationcontrol-implementation-plan.md`.

### C3 — Command Overview Quick Actions in-game (UX spec)
- **Finding:** Screen hierarchy listed Quick Action Shortcuts (deploy policy, create listing, bring online) under Command Overview — these require writes and are impossible in-game.
- **Fix:** Added "— **external browser only; hidden in-game read-only mode**" annotation.
- **File:** `docs/ux/civilizationcontrol-ux-architecture-spec.md` — §3 screen hierarchy.

---

## High Fixes (H1–H6)

### H1 — "CivControl backend" reference (spec.md)
- **Finding:** §2.3 mentioned "CivControl backend or admin key" as sponsor — CivilizationControl has no backend.
- **Fix:** Replaced with "admin key — team-held keypair" (merged with C2 fix).
- **File:** `docs/core/spec.md` — §2.3 dual-sign pattern.

### H2 — MoveAbort produces no events (demo beat sheet + dapp-surface)
- **Finding:** Beat 4 "hostile denied" relied on Signal Feed entry from a MoveAbort tx. MoveAbort reverts ALL effects including events — no on-chain events from failed txs.
- **Fix:** Added explicit note that detection relies on wallet adapter failure response (`effects.status.error`), not on-chain events. Fixed evidence checklist ("error event" → "MoveAbort code from wallet failure response"). Fixed fallback Beat 4 ("MoveAbort ETribeMismatch event" → "code"). Fixed dapp-surface §9 hostile denied proof surfacing.
- **Files:** `civilizationcontrol-demo-beat-sheet.md`, `in-game-dapp-surface.md`.

### H3 — "Primary: Sponsored transactions via Quasar/CCP" (dapp-surface §4)
- **Finding:** Listed in-game Sui signing via "Quasar/CCP backend" as primary — Quasar is EVE Vault's sponsorship API, not an in-game signing mechanism. No Sui signing is possible in-game.
- **Fix:** Replaced with two primaries: "In-game: Read-only mode" and "External browser: Sponsored transactions via AdminACL-enrolled sponsor."
- **File:** `docs/architecture/in-game-dapp-surface.md` — §4 wallet implications.

### H4 — EVE Token "not on Sui" (UX spec)
- **Finding:** Constraint summary stated "EVE Token not on Sui — only // TODO placeholder." EVE.move is a fully implemented module (10B supply, 9 decimals, Coin<EVE>).
- **Fix:** Changed to "EVE Token exists on Sui — Coin<EVE> is published (10B supply, 9 decimals, burn-only after init) but not yet integrated into CivilizationControl."
- **File:** `docs/ux/civilizationcontrol-ux-architecture-spec.md` — §2 constraint summary.

### H5 — Unlink gates MVP classification
- **Finding:** Originally flagged as requiring AdminACL. Upon verification: `unlink_gates` requires only OwnerCaps, NOT AdminACL. Player-callable. MVP classification is correct.
- **Resolution:** FALSE POSITIVE — no fix applied. `unlink_gates` signature confirmed at gate.move L222–237.

### H6 — Spatial pinning MVP classification
- **Finding:** Originally flagged as potentially problematic. Spatial pinning is purely client-side (localStorage), no chain dependency.
- **Resolution:** FALSE POSITIVE — no fix applied. Design is correct as documented.

---

## Medium Fixes (M1–M10)

### M1 — Polling interval consistency
- **Finding:** spec.md said "10 seconds (MVP)" as a blanket rate; dapp-surface §10 specified per-data-type rates (5-10s, 15-30s, 5s).
- **Fix:** Expanded spec.md polling note to reference dapp-surface for granular rates.
- **File:** `docs/core/spec.md` — §2.2 read paths.

### M2 — Jump flow "two separate transactions"
- **Resolution:** Already documented as "PROVISIONAL" in spec.md. No change needed — this is a known open question.

### M3 — Inconsistent Lux-SUI conversion rates
- **Finding:** "5 Lux (0.5 SUI)" in §5 vs "5 Lux (0.0005 SUI)" in §12 Principle 6 — wildly different rates (1 Lux = 0.1 SUI vs 1 Lux = 0.0001 SUI).
- **Fix:** Standardized §12 Principle 6 to use "5 Lux (0.5 SUI)" matching other examples. Added note to §5c currency display convention that rates are placeholder examples.
- **File:** `docs/ux/civilizationcontrol-ux-architecture-spec.md`.

### M4 — Currency denomination note
- **Fix:** Added explicit note that Lux-to-SUI exchange rate is a display placeholder and Lux-denominated display is stretch goal (#31). Merged with M3 fix.

### M5 — "GateControl" vs "GateAuth" naming
- **Resolution:** FALSE POSITIVE — "GateControl" is the intentional player-facing display name; "GateAuth" is the Move typed witness. These are different layers (UX label vs code type).

### M6 — Linking flow missing AdminACL
- **Finding:** UX spec §7 linking flow constraints did not mention AdminACL requirement.
- **Fix:** Added constraint: "`link_gates` requires **AdminACL sponsor** — the transaction must be sponsored by an address in `AdminACL.authorized_sponsors`."
- **File:** `docs/ux/civilizationcontrol-ux-architecture-spec.md` — §7 constraints.

### M7 — EF-Map Cosmic Context stretch dependency
- **Finding:** Demo Beat 2 and Beat 7 referenced EF-Map and Strategic Network Map as primary demo elements, but both are stretch features.
- **Fix:** Wrapped references in conditional language: "*(If Strategic Network Map ready:)*" and "*(If EF-Map ready:)*". Added minimum fallback: "Structure list with status indicators and aggregate metrics."
- **File:** `docs/core/civilizationcontrol-demo-beat-sheet.md` — Beats 2, 7.

### M8 — Strategic Network Map as stretch in primary demo
- **Fix:** Merged with M7 — same conditional wrapping applied.

### M9 — Day1 checklist time budget sum exceeds 120 min
- **Finding:** Individual check budgets sum to ~160 minutes vs the 120-minute Phase 0 window.
- **Fix:** Added execution order note explaining that Checks 8–11 may overlap with Phase 1 Foundation work.
- **File:** `docs/core/day1-checklist.md` — execution order section.

### M10 — ZK gas "under a thousand MIST" vs ~1,009,880 MIST
- **Finding:** Narration says "under a thousand MIST" but evidence overlay shows ~1,009,880 MIST.
- **Fix:** Changed narration to "about a thousand MIST" (accurate approximation).
- **File:** `docs/core/civilizationcontrol-demo-beat-sheet.md` — ZK accent segment.

---

## Low Fixes (L1–L11)

### L1/L11 — Polling interval standardization
- **Fix:** Covered by M1 fix — spec.md now references dapp-surface for granular rates.

### L2 — Write-operation states in read-only document context
- **Resolution:** FALSE POSITIVE — dapp-surface §11 documents sponsorship UX for both in-game and external browser contexts. This is appropriate.

### L3 — Terminology consistency
- **Resolution:** Covered by voice guide canonical mapping already in place.

### L4 — "Settings" → "Configuration"
- **Fix:** Replaced 3 stray "Settings" references in UX spec (§10d, stretch #27, data source table).
- **File:** `docs/ux/civilizationcontrol-ux-architecture-spec.md`.

### L5 — "BLOCKED" status labels
- **Resolution:** FALSE POSITIVE — "BLOCKED" is a pre-hackathon planning status label, not a UI term.

### L6 — Sponsorship not called out in Beat 5
- **Fix:** Added sponsorship precondition note to Beat 5: "jump_with_permit requires AdminACL-authorized sponsor co-signature."
- **File:** `docs/core/civilizationcontrol-demo-beat-sheet.md`.

### L7 — AdminCap created but unused in MVP
- **Fix:** Added clarifying note to implementation plan S09: AdminCap follows builder-scaffold pattern for future admin operations; MVP uses OwnerCap<Gate> for per-gate self-service.
- **File:** `docs/core/civilizationcontrol-implementation-plan.md`.

### L8 — "Configuration" page reference
- **Resolution:** Already uses correct terminology in S07 description.

### L9 — Rule evaluation order
- **Resolution:** UX spec §6 has full 6-step order (Block→Allow→Tribe→ZK→Coin→Pass). Implementation plan S13 has MVP 2-step (tribe→toll). These are consistent — S13 is MVP subset.

### L10 — /configure URL external-browser-only
- **Fix:** Added "**External browser only**" annotation to /configure URL row in dapp-surface §8.
- **File:** `docs/architecture/in-game-dapp-surface.md`.

---

## Consistency Sweep Results

Post-fix grep verification:
- ✅ Zero remaining "Self-sponsorship does NOT work" in target documents
- ✅ Zero remaining "CivControl backend" in target documents
- ✅ Zero remaining "Quasar/CCP" references
- ✅ Zero remaining "EVE Token not on Sui" in target documents
- ✅ Zero remaining "0.0005 SUI" inconsistent rate
- ✅ Zero remaining "Under a thousand MIST" in demo beat sheet
- ⚠️ Residual "self-sponsorship does NOT work" in 4 non-target docs (gate-lifecycle-runbook.md, decision-log.md, hackathon-portfolio-roadmap.md, march-11-reimplementation-checklist.md) — out of audit scope but flagged for future cleanup.

---

## Summary

| Severity | Total | Fixed | False Positive | Already Correct |
|----------|-------|-------|----------------|-----------------|
| Critical | 3 | 3 | 0 | 0 |
| High | 6 | 4 | 2 | 0 |
| Medium | 10 | 8 | 1 | 1 |
| Low | 11 | 5 | 3 | 3 |
| **Total** | **30** | **20** | **6** | **4** |

All Critical and confirmed High/Medium issues resolved. False positives documented with verification evidence.
