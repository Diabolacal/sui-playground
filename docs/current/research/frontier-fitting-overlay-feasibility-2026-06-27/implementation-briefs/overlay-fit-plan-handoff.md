# Implementation Brief — Overlay Fit-Plan Handoff

**Status:** Brief for a future build pass (not built here). The flagship native integration between the
fitting tool and the EF-Map overlay. **Do after the Fitting MVP ships; needs the generic-payload
foundation first.** Detail in [`../overlay-helper-audit.md`](../overlay-helper-audit.md).

## Goal
From the fitting web app, "Install This Fit" → the in-game overlay shows an **in-cockpit checklist**
("install these modules"), a **powergrid bar**, and a **fuel-runway** reminder; the player ticks
modules off as they install them.

## Prerequisite (Phase A — generic foundation)
1. **Capability handshake:** helper sends `capability_hello` on WS connect and in `/health`
   (`schema_version`, `capabilities[]`). Web sends only supported cards.
2. **Re-add a generic text-card renderer** (`overlay_card`) — the prior `hud_hints` renderer was removed
   at `overlay_renderer.cpp:1057`. Smallest C++ change; unlocks pushing any card as text.
3. Add `overlay_cards[]` parsing to the schema (v5), backward-compatible (helper already ignores unknown
   fields).

## Phase B — the `fit_plan` card
- **Wire payload** (Cycle-6-correct — powergrid/online/hardpoints, *not* EVE-Online hi/mid/low slots):
  see [`../overlay-helper-audit.md` §4.3](../overlay-helper-audit.md). Fields: `ship_name`,
  `powergrid_used_mw`/`powergrid_total_mw`, `fuel_units`/`fuel_runway_min`, `modules[]`
  (`group`, `name`, `qty`, `state`, `online`, `powergrid_mw`, `hardpoint`).
- **Renderer** (`overlay_renderer.cpp`, ~200 lines): a `FIT PLAN — Root` card with a powergrid bar, a
  fuel-runway line, and modules grouped by category with a checkbox per row.
- **Backchannel:** a checkbox tick emits a `CustomJson` event (id 1000, existing infra)
  `{"action":"module_checked","card_id":...,"module":...,"state":"installed"}`; the web app updates the
  fit state and re-POSTs to `/overlay/state`. At 100% the card auto-expires (`ttl_ms`/dismiss).

## Transport (unchanged, existing)
`POST http://127.0.0.1:38765/overlay/state` (or `ef-overlay://overlay-state?payload=`). No new
endpoints.

## Acceptance / smoke
- Push a fit → card renders with correct powergrid/fuel and grouped modules.
- Tick a module in-overlay → web app receives the event and reflects `installed`.
- Old helper (no `fit_plan` capability) → web degrades to a plain `overlay_card` text summary.
- Payload stays well under the 64 KiB shared-memory ceiling (omit unchanged fields, short keys).

## Constraints / risks
- Privacy line holds: web→helper push + user-checked items only; no memory reads/automation.
- Each C++ change needs an MSIX rebuild + Store resubmission (1–3 day cert) → **batch** Phase A with the
  visual refresh ([`overlay-visual-refresh.md`](overlay-visual-refresh.md)); existing Store build stays
  live if review fails.
- Keep all game-specific data web-side; the helper only renders generic cards.
