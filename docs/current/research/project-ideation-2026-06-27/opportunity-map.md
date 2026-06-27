# Opportunity Map — EVE Frontier Project Ideation (2026-06-27)

**Status:** Active research artifact. Surface-by-surface matrix of where new tools can live.

Buildability legend: 🟢 weekend · 🟡 1–4 weeks · 🔴 1–2 months+. Wallet legend: 🔓 no-wallet/read-only ·
🔐 wallet/write. Evidence is cited to the workstream reports in [`source-review.md`](source-review.md).

---

## 1. SSU / Inventory (on-chain)

- **Evidence:** `inventory.move` V2 events with `inventory_key` (#155); `storage_unit.move` open/owned/ephemeral inventories; opaque `type_id`; inventory not enumerable from events alone (A). SSU = the operator's named focus surface (June context). Pain: no cross-SSU view, no audit trail, opaque types (F, G).
- **Buildability:** 🟡–🔴 (needs an event indexer + dynamic-field RPC reads; `PlayerProfile` for wallet→character is temporary). 🔓 read-only feasible.
- **Risks:** breaking V2 event change; live-emission unverified; shared-tribe-storage already exists (must stay a *personal view*, not shared custody).
- **Angles:** Cross-SSU "where's my stuff" reconciler (personal, read-only); per-slot inventory **flow** timeline (V2 `inventory_key`); capacity/fill-rate sentinel; async delivery / obligation tracker (`deposit_to_owned`); dead-drop / time-locked / conditional release (write, builder project); `type_id → name/icon` decoder (glue).

## 2. Gates / Jump-permits (on-chain)

- **Evidence:** `JumpPermitIssuedEvent` (#140) with `expires_at_timestamp_ms`/`route_hash`/`extension_type`; `GateLinkedEvent`/`JumpEvent` graph + traffic (A). EF-Map already shows smart-gate links + Cycle 6 stargate status (C).
- **Buildability:** 🟡 (indexer). 🔓 read-only.
- **Risks:** EF-Map covers gate topology + status already; differentiate on **permits** (which EF-Map doesn't track) or **dormant-gate-aware routing** (EF-Map's documented gap).
- **Angles:** Jump-permit lifecycle dashboard (expiry countdowns); dormant-gate-aware route/chokepoint companion (EF-Map gap, handoff via deep link).

## 3. Rift / Location reveal (on-chain) — *freshest surface*

- **Evidence:** `RiftLocationBroadcastEvent` plaintext `solarsystem,x,y,z` at mining start, designed to spark PvP (A, rift.move); `LocationRevealedEvent` + `LocationRegistry` (A). Undocumented in builder docs (B). Rifts are the **economic heart of Cycle 6** (Crude→Fuel) (G).
- **Buildability:** 🟡 (event indexer + map render; can embed EF-Map). 🔓 read-only.
- **Risks:** **Core assumption unverified** — does the event fire on the live server, how often, with usable data? Needs a kill test. High payoff if yes.
- **Angles:** "Rift Watch" live contested-rift map / "where's the action right now"; rift-history story map; PvP-opportunity alerting.

## 4. EF-Map data & embed (off-chain, public)

- **Evidence:** public no-auth assets `blueprint_data_v5.json` (incl. `cycle6Filter` deltas), `stargate_edges_cycle6.json`, map SQLite DB; rich embed + deep-link + `postMessage` contract; `/api/create-share` (C). Documented gaps: no calculator permalink, no static-data differ, no ISK ranking, no dormant-gate routing, no Discord bot, no GPT/MCP connector (C).
- **Buildability:** 🟢–🟡 (static data + web page). 🔓 no-wallet.
- **Risks:** dependency on EF-Map's data shape (operator's own project → synergy, but versioning to watch). Could be folded back into EF-Map later.
- **Angles:** "What changed this patch" static-data differ ★; blueprint build permalink + share cards; multi-build shopping list; facility-coverage "what can I build here"; blueprint dependency-graph explorer; market/ISK cost overlay; Discord bot; "Frontier Facts" GPT/MCP connector; embeddable tribe widget.

## 5. EF-Map helper / overlay (desktop)

- **Evidence:** native overlay renders arbitrary web-pushed JSON (`hud_hints[]`/`highlighted_systems[]` unused); deep-link protocol; local bridge `:38765/:38766`; Microsoft Store distribution (D). Web-only changes ship against the frozen helper contract (fast); C++ changes need Store re-cert (slow).
- **Buildability:** 🟢 web-only seams · 🔴 helper-side changes. 🔓 (local only).
- **Risks:** Windows-only; overlay repo stale (Feb); **privacy line** — local logs only, no memory/automation.
- **Angles:** "Open in game" route/objective handoff from any web page/Discord; in-game mission/objective markers; local-first logbook export / session recap card; second-monitor live dashboard; tribe-ops "push to all" briefings (opt-in); helper-availability-aware web UX.

## 6. Wallet / EveVault (on-chain write)

- **Evidence:** sponsored tx (EVE-Vault-only); EVE Vault Chrome-only, manual install; in-game CEF browser has **no Sui wallet** (read-only in-game; writes need external browser) (B, E, F).
- **Buildability:** 🔴 (write paths gate adoption behind wallet + gas). 🔐 wallet.
- **Risks:** adoption friction; sponsorship complexity; revalidate against v0.0.24. CivilizationControl already owns the operator-governance write space.
- **Angles:** Only for *builder* projects that ship their own Move extension (SSU dead-drop, conditional release, VRF loot, composable access policy). Treat as 1–2 month, not weekend.

## 7. Public community websites (off-chain)

- **Evidence:** Cycle 6 wipe → mass relearning + new-player surge; "very negative early discourse"; onboarding/fuel/lens confusion (G). No tool diffs static data or curates "what changed" automatically (C, G).
- **Buildability:** 🟢–🟡. 🔓 no-wallet.
- **Risks:** wikis exist (don't hand-curate); must offer something automated/distinctive.
- **Angles:** "What changed this cycle/patch" relearning companion (data-driven); Frontier Companion toolbox domain (umbrella for operator's tools); "Frontier Facts" answer endpoint.

## 8. Purely funny / community / social tools

- **Evidence:** verified meme-shaped mechanics — star-heat death, fuel-dark "#1 avoidable disaster," "it's all one ship," crash-site spawns (G); owner-writable SSU metadata (A, F).
- **Buildability:** 🟢–🟡. mostly 🔓.
- **Risks:** some depend on whether heat/fitting data is exposed off-chain (speculative).
- **Angles:** "Am I Cooking?" star-heat meter (speculative); "Forgot to Refuel" hall-of-shame runway tracker; SSU metadata graffiti / station logbook; "It's all one ship" Root fitting-share card (speculative); Crash Site Survivor starter card.

---

## Cross-surface synthesis

| Theme | Best surfaces | Adoption | Risk |
|-------|---------------|----------|------|
| **No-wallet read-only** is the natural fit | 1,2,3,4,7,8 | Highest (no wallet/gas) | Low–Med (event emission for on-chain ones) |
| **EF-Map gaps** are the safest, most synergistic ground | 4 | High | **Lowest** (static CDN data, no unverified assumptions) |
| **Rifts** are the freshest/most exciting on-chain surface | 3 | High | Med-High (live-emission kill test) |
| **SSU intelligence** best fits the operator's stated focus | 1 | High | Med (indexer + V2 events + temporary PlayerProfile) |
| **Helper** uniquely enables in-game/native loops | 5 | Med (Windows + install) | Low (web-only) / High (C++ re-cert) |
| **Write/wallet** projects are 1–2 month builder efforts | 1,6 | Lower (wallet friction) | Med |

**The sweet spot** (high reward, low unverified risk, current-cycle, public, demoable) is **EF-Map-gap
companions (surface 4)** for the weekend horizon and **SSU inventory intelligence (surface 1)** /
**Rift Watch (surface 3, post-kill-test)** for the bigger horizon. See
[`ranked-shortlist.md`](ranked-shortlist.md).
