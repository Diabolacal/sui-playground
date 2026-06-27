# Recommended Next Build — Frontier Changelog ("What Changed")

**Status:** Active research artifact — implementation brief for the single most-recommended idea (I-1).
**Score:** 35/40. **Horizon:** weekend MVP → evergreen public tool.

> One-line: *A public, auto-generated changelog that diffs EVE Frontier's static game data between
> patches and cycles — so returning players, builders, and the curious can see exactly what changed.*

---

## Product name options
- **Frontier Changelog** (clear, generic-good)
- **Patch Witness** / **Frontier Patch Witness** (more characterful)
- **What Changed in the Frontier**
- **Sanctuary Diff** (cycle-specific; less evergreen)
- **EF Diff**

Recommended: **Frontier Changelog** as the product, with a punchy tagline ("the patch notes CCP didn't write").

## Problem statement
EVE Frontier resets/overhauls heavily each cycle. **Cycle 6 "Sanctuary" (live 2026-06-25)** wiped the
server and reworked ships, weapons, energy, and industry — and the community reaction skewed "very
negative early" because everyone had to relearn at once (Subagent G; mmorpg.com, shacknews CM
interview). Yet **no tool tells you what actually changed in the data.** EF-Map's "State of the
Frontier" reports *live activity* deltas only — it does not diff blueprints, recipes, facilities, or
modules between patches (Subagent C, verified). Returning players, builders, and content creators are
left to rediscover changes by trial and error.

## Target users
- **Returning/lapsed players** ("what changed since I last played?").
- **Builders/industrialists** ("which recipes/facilities moved; what can I still build?").
- **Content creators / explainers / tribe leaders** who write the guides this cycle demands.
- **The merely curious** who enjoy patch-notes-with-personality and share them.

## MVP scope (weekend)
1. Fetch two versions of EF-Map's public, no-auth industry dataset:
   `https://ef-map.com/blueprint_data_v5.json` (current) and the prior `…_v4.json` (both already exist
   in the EF-Map repo per Subagent C).
2. Diff `items`, `recipes`, `facilities`, `sourceMaterials`, `recipeFacilityMatrix`. **Bonus, near-free:**
   the v5 JSON already embeds a `cycle6Filter` block (`removedFacilities`, `removedProducts`,
   `orphanedBlueprints`) — surface it directly.
3. Render a clean, scannable "Cycle 6 changes" page: Added / Removed / Changed, grouped by category,
   each item linking to EF-Map (`/?...` or the blueprint calculator) for detail.
4. Generate an OG share image so the link unfurls nicely in Discord.

## Non-goals (MVP)
- **Not** a blueprint calculator or planner (that's EF-Map / EFCopilot / DaOpa — do not duplicate).
- **Not** a wiki (Pool Party Nodes / EVE Frontier Wiki exist).
- **Not** live-activity stats (that's EF-Map's State of the Frontier).
- No accounts, no wallet, no on-chain reads (MVP is pure static data).

## Data sources
| Source | URL | Auth | Use |
|--------|-----|------|-----|
| Industry dataset (current + prior) | `ef-map.com/blueprint_data_v{4,5}.json` | none (CDN) | core diff input; `cycle6Filter` block |
| Stargate edges | `ef-map.com/stargate_edges_cycle6.json` | none | (month-scale) universe/gate diff |
| Universe map DB | `ef-map.com/map_data_*.db` | none | (month-scale) system diff via sql.js |
| Item names/icons | World API REST / `getDatahubGameInfo` | none | enrich `type_id`s (pairs with I-7) |
| EF-Map deep links | `docs/embed.md` patterns | none | link each changed item back to EF-Map |

All MVP inputs are **public and unauthenticated** — no API key, no game/API change required.

## Contract interactions
**None for the MVP.** (Month-scale expansion may add an optional on-chain *assembly census* diff using
read-only `suix_queryEvents`, but that is explicitly out of the weekend scope and behind a kill test.)

## EF-Map / helper / overlay integration
- **Consumes** EF-Map's public static assets and **links back** into EF-Map (calculator/map) for every
  changed entity — pure synergy, no EF-Map change required.
- Could later be **adopted into** EF-Map's State of the Frontier, or kept standalone under a companion
  domain (I-23). Either is fine; they're the operator's own ecosystem.
- Optional later: a Discord webhook (pairs with I-6) that posts the changelog when a new dataset
  version appears.

## UI sketch (in words)
- **Hero:** "Frontier Changelog — Cycle 6: Sanctuary" with a one-line summary stat row ("X added · Y
  removed · Z changed").
- **Section tabs / anchors:** Modules · Blueprints/Recipes · Facilities · Materials.
- **Each entry:** name (resolved from `type_id`), a colored Added/Removed/Changed chip, a terse
  human sentence ("Assembler (88068) removed — ~115 modules no longer buildable"; "Mini Printer split
  into Deployable vs Onboard ('Emergency Printer')"), and a "view in EF-Map" link.
- **Personality:** small editorial captions for the headline changes (opt-in tone, never blocking the
  data).
- **Share:** a "copy link / share to Discord" button; the page is fully static and permalinkable.
- **Returning-player mode (month-scale):** a version picker ("I last played: [Cycle 5 ▾]") that diffs
  arbitrary version pairs.

## Architecture sketch
- **Simplest:** a static SPA (Vite/Astro) that fetches the two JSONs client-side and diffs in the
  browser. Host on Cloudflare Pages / Netlify / GitHub Pages.
- **OG images:** a tiny serverless function (Cloudflare Worker / Vercel OG) renders the share card.
- **Versioning (month-scale):** a Worker cron snapshots each new `blueprint_data_vN.json` into
  KV/R2 so arbitrary version pairs can be diffed and permalinked.
- **No backend state** required for the MVP.

## Milestones
- **2-hour spike:** fetch v4 + v5 JSON, compute and `console.log` the recipe/facility/module delta;
  confirm it's legible and interesting. (This *is* the kill test.)
- **Weekend MVP:** the changes page + OG card, deployed to a public URL.
- **Week 1 polish:** category grouping, `type_id` name resolution (I-7), EF-Map deep links, editorial
  captions for headline changes, mobile layout.
- **Month-scale:** version snapshotting + "since I last played" picker; extend to universe/gate diffs
  (map DB + stargate edges); optional Discord webhook; fold under the Frontier Companion domain.

## Validation / smoke plan
- Diff matches a manual spot-check of 5 known Cycle 6 changes (Assembler removal, Emergency Printer
  rename, the ~115 removed modules, an orphaned blueprint, a moved recipe).
- Every "view in EF-Map" link resolves to the right system/item.
- OG card renders in a Discord/embed preview.
- Page loads with no console errors; works with JS-only (static).

## Risks and kill criteria
| Risk | Mitigation / kill |
|------|-------------------|
| Dataset shape differs across versions | Defensive parsing; the spike validates v4↔v5 compatibility. **Kill if** v4/v5 aren't diffable. |
| Dependency on EF-Map's data | It's the operator's own public asset → synergy; version-pin and cache. |
| "Most useful only at patch time" | Returning-player mode + evergreen wipe cadence give recurring value. |
| Could be folded into EF-Map | Acceptable (same ecosystem); standalone share surface still has value. |
| `type_id` opacity | Resolve via World API / `getDatahubGameInfo` (I-7); fall back to raw IDs. |

## Why this is worth building
It is the **highest-scoring, lowest-risk, most timely** idea in the set: it fills a concrete,
verified gap; needs no wallet, no contract assumption, and no game/API change; ships as a simple
public page; is genuinely useful to a community mid-relearn *right now*; is fun and shareable; and it
earns its keep again at **every** future patch and wipe. It also seeds a durable public toolbox
(I-23) that the operator's EF-Map / helper / future tools can live under — converting a weekend build
into a long-running community asset.
