# Overlay/Helper Technical Audit — Protocol, Generic Payloads, Fitting Integration (2026-06-27)

**Status:** Active research artifact (Workstream G, technical half). Source: read-only audit of
`Diabolacal/ef-map-overlay` @ `8788a16` (Feb 2026) via Subagent G, with file:line citations preserved.
Visual redesign is in [`overlay-visual-redesign.md`](overlay-visual-redesign.md).

> **Headline:** The overlay is a capable generic bridge that already renders web-pushed JSON over a
> stable local transport, but it has **no capability negotiation** and its "push arbitrary text" hook
> (`hud_hints`) was **removed in a legacy cleanup**. The right move is a **schema-v5 `overlay_cards[]`
> model + a `capability_hello` handshake**, with a **`fit_plan` card** as the flagship fitting
> integration. The operator's willingness to change C++ + resubmit to the Store makes this viable.

---

## 1. Architecture (3 processes)
```
Browser (ef-map.com / fit.ef-map.com)
  │  WS ws://127.0.0.1:38766  (primary push)   +   HTTP http://127.0.0.1:38765  (POST/GET, fallback/session)
  ▼
ef-overlay-helper.exe  (Windows tray, C++20)  ── reads %DOCUMENTS%\Frontier\logs\{ChatLogs,GameLogs}
  │  Shared memory  Local\EFOverlaySharedState (64 KiB)   +   Local\EFOverlayEventQueue (64×512 B ring)
  ▼
ef-overlay.dll  (injected into exefile.exe, DX12 + ImGui, polls shared mem ~60 Hz)
  ▼  EVE Frontier
```
Key files: `src/helper/helper_server.cpp` (HTTP), `src/helper/helper_websocket.cpp` (WS),
`src/shared/overlay_schema.hpp` (schema), `src/overlay/overlay_renderer.cpp` (ImGui),
`src/helper/protocol_registration.cpp` (deep link), `src/helper/log_parsers.*` (logs).

## 2. Current protocol (schema v4)
- **HTTP :38765** — `GET/POST /overlay/state`, `GET /health`, `GET /overlay/events?since=N`,
  `/telemetry/*`, `/session/*`, `/settings/follow`, `/settings/logs`, `/bookmarks/create`,
  `/pscan/data`, `POST /inject`. CORS includes `Access-Control-Allow-Private-Network: true` for Chrome
  PNA (`helper_server.cpp:783-789`).
- **WebSocket :38766** — broadcasts `overlay_state` (full state on every change + heartbeat),
  `event_batch` (overlay→browser events), `bookmark_add_request`. Sends current state on connect.
- **Deep link** — `ef-overlay://overlay-state?token=<secret>&payload=<url-encoded-json>` registered at
  `HKCU\Software\Classes\ef-overlay`; routes into the same `ingestOverlayState()` path as HTTP POST;
  launches the helper if not running.
- **`OverlayState` (v4, `overlay_schema.hpp:12`)** carries: `route[]`, `active_route_node_id`,
  `player_marker`, `highlighted_systems[]`, `hud_hints[]`, `camera_pose`, `pscan_data`, `telemetry`
  (combat/mining/history), session flags, `tribe_*`, `authenticated`, `heartbeat_ms`, `source_online`.
- **Bidirectional merge** (`helper_server.cpp:509-630`): log-watcher is authoritative for
  `player_marker`; the web app is authoritative for `route`, `pscan_data`, `tribe_*`, `authenticated`.
- **Events** (overlay→browser, ring buffer): ToggleVisibility, FollowModeToggled, WaypointAdvanced,
  HudHintDismissed, session/bookmark/pscan requests, and **`CustomJson` (id 1000, arbitrary JSON)** —
  the generic backchannel.

## 3. What's latent / unused (the opportunity)
- **`hud_hints[]`** and **`highlighted_systems[]`** are **parsed but NOT rendered** — the Overview-tab
  renderer for them was removed in "Phase 5 Legacy Cleanup" (`overlay_renderer.cpp:1057`). So the
  "push arbitrary text card" capability exists in the wire schema but draws nothing today.
- **P-SCAN tab** rendering code exists but the tab is **commented out** (`overlay_renderer.cpp:2159`).
- **`camera_pose`** (3D starmap) defined, not rendered.
- **No capability negotiation:** the helper advertises no schema version or feature set; the web app
  cannot tell what the installed helper can render. `/health` returns only uptime/ports/has_state.
- **`CustomJson` (1000)** is a ready-made generic event backchannel for overlay→web interactions.

## 4. Proposed durable architecture: capability negotiation + `overlay_cards[]` (schema v5)
The design goal (operator): **product logic in the web layer; the helper is a generic renderer with
versioned payloads + capability negotiation; unknown fields ignored** (nlohmann::json already ignores
unknown keys, confirmed).

### 4.1 Capability handshake
Helper → browser, on WS connect **and** in the `/health` body:
```json
{ "type": "capability_hello", "schema_version": 5, "helper_version": "1.1.0",
  "capabilities": ["overlay_card","checklist","route_context","system_context",
                   "session_card","notification","fit_plan"] }
```
The web app sends only cards the helper lists; older helpers (no `fit_plan`) gracefully get a text
`overlay_card` fallback. This is the single most important addition — it decouples web release cadence
from Store-cert cadence.

### 4.2 Generic card primitives (new top-level `overlay_cards[]`, existing fields unchanged)
`overlay_card` (titled label/value lines), `checklist` (grouped items w/ pending/done/warn states +
completion %), `route_context`, `system_context`, `session_card`, `notification` (info/warn/critical),
and the fitting specialization **`fit_plan`**. Each card has `id` (update-in-place), `card_type`,
`priority`, `ttl_ms`, `dismissible`. A single generic render loop handles the text-like cards;
`fit_plan` and `route_context` get dedicated widgets.

### 4.3 `fit_plan` card — adapted to **Cycle 6's actual fitting grammar**
> Subagent G's first draft mirrored EVE *Online* (high/mid/low slots, CPU "tf", power "GW"). **Cycle 6
> does not work that way.** The correct model (from [`operator-context.md` §5](operator-context.md)):
> **powergrid in MW**, per-module **online/offline**, **interior polyomino modules**, and **exterior
> modules mounted on numbered hardpoints** (`Propulsion Engine #0..#5`, `Weapon Receiver #0`). No
> CPU resource was observed.

```jsonc
{
  "id": "active-fit", "card_type": "fit_plan", "priority": 5,
  "ship_name": "Root  ·  \"Hauler v2\"",
  "powergrid_used_mw": 0.7, "powergrid_total_mw": 15.0,
  "fuel_units": 2500, "fuel_runway_min": 476,          // capacity ÷ rate
  "modules": [
    { "group": "Engineering", "name": "Power Generator", "qty": 1, "state": "pending", "online": true,  "powergrid_mw": 0.0 },
    { "group": "Engineering", "name": "Fuel Bay",        "qty": 5, "state": "pending", "online": true,  "powergrid_mw": 0.0 },
    { "group": "Storage",     "name": "Cargo Container",  "qty": 8, "state": "pending", "online": true,  "powergrid_mw": 0.0 },
    { "group": "Hardpoint",   "name": "External Thruster", "qty": 6, "state": "pending", "hardpoint": "Propulsion Engine" },
    { "group": "Hardpoint",   "name": "Small Cutting Laser","qty": 1, "state": "pending", "hardpoint": "Weapon Receiver" }
  ]
}
```
Rendered as a **`FIT PLAN — Root` card**: a **powergrid bar** (`PWR 0.7 / 15.0 MW`), a **fuel-runway**
line, and a **module checklist grouped by category** with a checkbox per row. As the player installs
each module in-game they tick it; the tick emits a `CustomJson` event
(`{"action":"module_checked","card_id":"active-fit","module":"Fuel Bay","state":"installed"}`); the web
app updates and re-POSTs. At 100% the card auto-expires. **This reuses the existing `POST /overlay/state`
+ `CustomJson` infrastructure — no new endpoints.**

## 5. Web-only vs needs-C++ matrix
| Capability | Web-only today | Needs C++ |
|---|:--:|:--:|
| POST a fit/route/text payload to the helper | ✅ (`/overlay/state`) | — |
| Render arbitrary pushed **text** | ❌ (renderer removed) | ✅ re-add generic `overlay_card` loop (small) |
| Capability handshake (`/health` + WS hello) | ❌ | ✅ small helper change |
| `overlay_cards[]` parse + generic cards | ❌ | ✅ ~100 lines |
| **`fit_plan` widget** (power bar + grouped checklist) | ❌ | ✅ ~200 lines |
| Module-tick backchannel | ✅ (`CustomJson` exists) | — (just wire it to the widget) |
| Re-enable P-SCAN tab | ❌ | ✅ 1-line uncomment (`:2159`) |
| DPI auto-detect | ❌ | ✅ `GetDpiForWindow` |
| Heartbeat / offline detection / route auto-advance | ✅ already shipped | — |

## 6. Fitting-tool integration — recommended path
- **Flagship:** the **`fit_plan` card** ("Install This Fit" → in-cockpit checklist + powergrid/fuel
  reminder). Single highest-value overlay integration; one C++ widget PR (~200 lines) covers it; the
  product logic (what's in the fit) stays entirely web-side.
- **Phase A (ship first, smallest C++):** re-add a **generic `overlay_card` text renderer** + the
  **capability handshake**. This unlocks pushing *any* card (fit summary, build reminder, route note)
  from the web as plain text, against a stable contract — and is the foundation everything else builds
  on.
- **Phase B:** add the **`fit_plan` widget** + module-tick backchannel (schema v5).
- **Privacy/ToS line stays hard:** local logs only, loopback only, user-initiated, display + clipboard.
  No memory reads, no automation — none of the above crosses that line (it's all web→helper push +
  user-checked items).

## 7. Risks
- **64 KiB shared-memory ceiling:** a big fit + route + telemetry can approach it — keep card payloads
  minimal (omit unchanged fields, short keys).
- **Store cert turnaround** (1–3 days) for any C++ change → **batch** Phase A + visual Phase 1 into one
  submission. If review fails, the existing Store build stays live (operator-accepted).
- **Schema drift:** version every payload; helper must ignore unknown fields (already true) and the web
  must honor `capability_hello` so a stale helper degrades gracefully rather than breaking.
- **Alpha churn:** keep all game-specific data (module names, footprints, stats) **out of C++** — the
  helper only renders generic cards; the web/data layer owns the churn.
