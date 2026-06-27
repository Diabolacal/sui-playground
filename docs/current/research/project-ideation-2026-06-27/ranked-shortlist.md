# Ranked Shortlist — EVE Frontier Project Ideation (2026-06-27)

**Status:** Active research artifact. Rankings use the 8-axis rubric in
[`idea-cards.md`](idea-cards.md) (each 0–5, total /40). Scoring rules from the task are applied as
modifiers (penalize duplication / turrets / unverified contract assumptions / operator-only value;
reward small public utility, fun, EF-Map synergy, current-cycle fit, demoability, no-API-wait).

---

## Overall top 10

| Rank | Idea | Type | Weekend? | Bigger potential? | Score | Why |
|---:|---|---|---|---|---:|---|
| 1 | **I-1 Frontier Changelog ("What Changed")** | Web / EF-Map data | ✅ | ✅ (patch witness) | 35 | Fills a real, documented gap (no static-data differ); zero unverified assumptions; timely (Cycle 6 relearning); public, shareable, demoable. |
| 2 | **I-2 Rift Watch (live rift map)** | On-chain read + EF-Map embed | ⚠️ (after kill test) | ✅ | 33 | Freshest on-chain surface, PvP-dramatic, on-theme (Crude/Fuel). **Gated by a live-emission kill test.** |
| 3 | I-3 SSU Inventory Intelligence | On-chain read | ⚠️ | ✅ | 30 | Best fit to the operator's SSU focus; real pain; needs an indexer + V2 events. |
| 4 | I-4 Blueprint Permalink + Share Cards | Web / EF-Map data | ✅ | ➖ | 30 | Fills the calculator's permalink gap; frictionless Discord sharing. |
| 5 | I-5 "Frontier Facts" GPT/MCP connector | Web / AI | ✅ | ✅ | 30 | Novel, AI-era, EF-Map's `llms.txt` asks for it; nobody's built it. |
| 6 | I-6 Discord bot for EF-Map deep links | Web | ✅ | ➖ | 29 | Meets players in Discord; appetite documented, nothing shipped. |
| 7 | I-9 Async delivery / obligation tracker | On-chain read | ⚠️ | ✅ | 29 | Corp coordination without shared storage/marketplace; single-ship logistics. |
| 8 | I-7 `type_id → name/icon` decoder | Web glue | ✅ | ➖ | 28 | High-leverage primitive other tools reuse. |
| 9 | I-8 Dormant-gate-aware route companion | Web + EF-Map API | ⚠️ | ✅ | 28 | Fills EF-Map's documented dormant-gate routing gap; very on-cycle. |
| 10 | I-18 "Open in game" route handoff button | Helper (web-only) | ✅ | ➖ | 28 | Makes shared routes feel native; uses the frozen helper contract. |

---

## Top 5 — Weekend ideas (ship in 1–3 days, low risk)

1. **I-1 Frontier Changelog** (35) — static diff of `blueprint_data` versions → "what changed" page + share cards.
2. **I-4 Blueprint Permalink + Share Cards** (30) — URL state + OG cards over the public industry dataset.
3. **I-5 "Frontier Facts" GPT/MCP connector** (30) — MCP server / GPT action over EF-Map's public deep links.
4. **I-6 Discord bot for EF-Map deep links** (29) — slash commands → EF-Map URLs/embeds.
5. **I-7 `type_id → name/icon` decoder** (28) — cached resolver + embeddable widget (glue for everything else).

*Honorable weekend mentions:* I-18 (open-in-game button), I-26 (resolve-by-ItemID inspector), I-12 (multi-build list).

## Top 5 — Bigger ideas (1–2 months)

1. **I-3 SSU Inventory Intelligence** (30) — cross-SSU "where's my stuff" + V2 `inventory_key` flow + audit feed.
2. **I-2 Rift Watch** (33) — live rift indexer + map (after the kill test); grows into a frontier activity heatmap.
3. **I-9 Async delivery / obligation tracker** (29) — delivery-confirmation ledger; can grow an on-chain receipt object.
4. **I-8 Dormant-gate-aware route / chokepoint companion** (28) — status-aware routing + coverage map.
5. **I-21 SSU Dead Drop** (27) — builder/Move project: conditional/anonymous pickup via open-inventory custody.

*Umbrella / long-horizon:* I-23 Frontier Companion toolbox domain (a home that ties the above together).

## Top 5 — Weird / funny (but actually buildable & used)

1. **I-2 Rift Watch** (33) — "go here, something's happening" PvP drama.
2. **I-10 "Forgot to Refuel" runway tracker** (28) — hall-of-shame + real fuel runway.
3. **I-20 "Am I Cooking?" star-heat meter** (26) — the cycle's signature death, as a gauge *(speculative on data)*.
4. **I-21 SSU Dead Drop** (27) — espionage-flavored conditional pickup.
5. **I-11 SSU Metadata Graffiti / station logbook** (26) — leave your mark on a station.

*Also fun:* I-19 "Crash Site Survivor" session card; I-22 VRF SSU loot dispenser.

## Top 5 — Community utility (genuinely helps other players)

1. **I-3 SSU Inventory Intelligence** (30) — solves the cross-SSU "where's my stuff" pain.
2. **I-1 Frontier Changelog** (35) — helps everyone relearn the wiped cycle.
3. **I-8 Dormant-gate-aware route companion** (28) — fixes a concrete Cycle 6 routing pain.
4. **I-7 `type_id → name/icon` decoder** (28) — glue every tool (and the community) benefits from.
5. **I-9 Async delivery / obligation tracker** (29) — corp coordination without shared storage.

---

## Recommended next build

**→ I-1 · Frontier Changelog ("What Changed").** Full brief in
[`recommended-next-build.md`](recommended-next-build.md).

**Why this one (and not the flashier Rift Watch):**
- It scores highest (35/40) and, uniquely among the top ideas, has **no unverified contract
  assumption** — the data (`blueprint_data_v5.json` with an embedded `cycle6Filter` delta block, plus
  the v4→v5 versions) is sitting on EF-Map's public CDN *right now*. The task explicitly penalizes
  ideas that depend on fragile/unverified assumptions; Rift Watch (I-2) and the SSU ideas (I-3, I-9)
  all hinge on whether a given event actually fires on the live server — a real risk that must be
  kill-tested first.
- It hits the most "reward" criteria at once: small public utility, EF-Map data used in a genuinely
  new way, helps current-cycle (Cycle 6) confusion, ships as a simple public page/domain, demoable
  with screenshots, buildable without waiting on any game/API change, and low maintenance.
- It's **timely**: the Cycle 6 cutover just happened (2026-06-25) and the community is mid-relearn —
  the value is highest right now, and the tool earns evergreen value every future patch/wipe.

**Two strong companions to build alongside or next:**
- **I-2 Rift Watch** — run its 1-hour kill test first; if `RiftLocationBroadcastEvent` fires well on
  the live server, this is the highest-upside, most exciting build. (Brief:
  [`implementation-briefs/rift-watch.md`](implementation-briefs/rift-watch.md).)
- **I-3 SSU Inventory Intelligence** — the best fit to the operator's stated SSU focus and the natural
  flagship for the "bigger project" horizon. (Brief:
  [`implementation-briefs/ssu-inventory-intelligence.md`](implementation-briefs/ssu-inventory-intelligence.md).)

**Packaging suggestion:** ship I-1 as the flagship under a small **Frontier Companion** domain (I-23),
then add I-4/I-5/I-6/I-7 as they're built — turning a weekend tool into a durable public toolbox.
