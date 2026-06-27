# EVE Frontier Project Ideation — 2026-06-27

**Status:** Active research artifact (read-only ideation pass; nothing was built or deployed).
**Author:** Agent ideation pass run from `sui-playground`, branch
`research/eve-frontier-project-ideation-20260627`.

This folder is an **evidence-driven ideation pass** for new EVE Frontier projects worth building —
for fun, player usefulness, and community value (not a hackathon). It was produced by seven parallel
read-only research workstreams across the current `world-contracts` (v0.0.24), builder docs/scaffold,
**EF-Map**, the **EF-Map overlay/helper**, **CivilizationControl**, the `sui-playground` historical
archive, and the public web/community.

> **Caveats up front:** (1) On-chain ideas reference `world-contracts` `d1929fa` (v0.0.24) but **live
> event emission was not verified** — each carries a kill test. (2) Direct player sentiment
> (Discord/Reddit) was **not web-reachable**; pain points lean on press + repo analysis and should be
> revalidated with the community. Details in [`source-review.md`](source-review.md).

---

## Executive summary

- **The natural shape of an EVE Frontier community tool right now is a public, no-wallet, read-only
  web app.** The current contracts are overwhelmingly read-path (nearly all writes are
  sponsor-gated), and the officially-blessed path includes Sui GraphQL/events + a public World API +
  EF-Map's public data assets — so the highest-adoption tools need no wallet, no gas, and no game/API
  change. (Subagents A, B.)
- **EF-Map is large and current** (Cycle 6 cutover live 2026-06-25) — it already owns map, routing,
  the blueprint calculator, killboard, SSU finder, and intel search. So the opportunity is **building
  into its documented gaps**, not re-doing it. (Subagent C.)
- **The freshest surfaces** are the new on-chain ones with no tooling yet: **rifts** (plaintext
  location broadcast, the economic heart of Cycle 6), the **`inventory_key`/V2 SSU events**, and gate
  **jump-permit** events. (Subagents A, B.)
- **The current cycle ("Sanctuary") is a hard reset:** one "Root" hull + internal modules, a single
  cutting laser, a new **star-heat** hazard, a fuel economy fed by **Crude from rifts**, no docking/safe
  log-off, and a wiped server — so the community is mid-relearn. (Subagent G.)
- **Exclusions honored:** no shared tribe storage, no generic marketplace, no re-skins of
  CivilizationControl/GateControl/TradePost/ZK GatePass, no turret projects, no EF-Map
  map/route/calculator duplication. (Subagent E, F; [`prior-art-and-exclusions.md`](prior-art-and-exclusions.md).)
- **26 ideas** were generated and scored on an 8-axis rubric; the strongest cluster is **EF-Map-gap
  companions** (safe, public, weekend-scale) with **SSU intelligence** and **Rift Watch** as the
  bigger-horizon flagships.

## Recommended top idea

**Frontier Changelog ("What Changed")** — a public, auto-generated changelog that diffs EVE Frontier's
static game data between patches/cycles (blueprints, recipes, facilities, modules), with a
returning-player "what changed since I left" lens.

- **Why it wins:** highest score (35/40) and the **only** top idea with *no unverified contract
  assumption* — the data (`ef-map.com/blueprint_data_v5.json`, which already embeds a `cycle6Filter`
  delta block, plus the prior v4 version) is on a public CDN right now. It fills a verified gap
  (EF-Map's State of the Frontier diffs *live activity only*, never static data), helps a community
  mid-relearn, ships as a simple shareable public page, and earns value again at every future patch.
- **Weekend MVP:** diff v4→v5 `blueprint_data`, render a clean "Cycle 6 changes" page + Discord share
  card. Full brief: [`recommended-next-build.md`](recommended-next-build.md).
- **Build it first; kill-test Rift Watch in parallel.** If `RiftLocationBroadcastEvent` fires well on
  the live server, Rift Watch (I-2) is the higher-upside, more exciting build.

## Ranked shortlist (top 10)

| Rank | Idea | Type | Weekend? | Score |
|---:|---|---|---|---:|
| 1 | **Frontier Changelog ("What Changed")** | Web / EF-Map data | ✅ | 35 |
| 2 | Rift Watch (live rift map) | On-chain read + embed | ⚠️ after kill test | 33 |
| 3 | SSU Inventory Intelligence ("where's my stuff") | On-chain read | ⚠️ | 30 |
| 4 | Blueprint Permalink + Share Cards | Web / EF-Map data | ✅ | 30 |
| 5 | "Frontier Facts" GPT/MCP connector | Web / AI | ✅ | 30 |
| 6 | Discord bot for EF-Map deep links | Web | ✅ | 29 |
| 7 | Async delivery / obligation tracker | On-chain read | ⚠️ | 29 |
| 8 | `type_id → name/icon` decoder (glue) | Web | ✅ | 28 |
| 9 | Dormant-gate-aware route companion | Web + EF-Map API | ⚠️ | 28 |
| 10 | "Open in game" route handoff button | Helper (web-only) | ✅ | 28 |

Bucketed Top-5s (Weekend / Bigger / Weird-funny / Community-utility) and the full reasoning are in
[`ranked-shortlist.md`](ranked-shortlist.md).

## How to read the rest

| File | What's in it |
|------|--------------|
| [`source-review.md`](source-review.md) | What was inspected (repos, commits, URLs), key evidence per workstream, and gaps/limitations. |
| [`prior-art-and-exclusions.md`](prior-art-and-exclusions.md) | What already exists, the operator's exclusions (with remix verdicts), and the genuine white space. |
| [`opportunity-map.md`](opportunity-map.md) | Surface-by-surface matrix (SSU, gates, rifts, EF-Map data, helper, wallet, public web, funny). |
| [`idea-cards.md`](idea-cards.md) | 26 evidence-cited idea cards, each with value, evidence, MVP→month→2-month, risks, kill test, and score. |
| [`ranked-shortlist.md`](ranked-shortlist.md) | Transparent rubric ranking + bucketed Top-5 lists + the recommended next build. |
| [`recommended-next-build.md`](recommended-next-build.md) | Full implementation brief for the #1 pick (Frontier Changelog). |
| [`implementation-briefs/`](implementation-briefs/) | Briefs for the next picks: [Rift Watch](implementation-briefs/rift-watch.md), [SSU Inventory Intelligence](implementation-briefs/ssu-inventory-intelligence.md), [Blueprint Permalink](implementation-briefs/blueprint-permalink.md). |
| [`open-questions.md`](open-questions.md) | Decisions + kill tests for the operator to resolve before committing. |

## Important reminders for whoever builds from this
- **Revalidate every on-chain claim** against current `vendor/world-contracts` (v0.0.24) and run the
  per-idea **kill test** before relying on any event — the task penalizes unverified contract assumptions.
- **Revalidate community sentiment** directly (the web scan could not reach Discord/Reddit).
- **Stay beside** the existing shared-tribe-storage and marketplace projects; **build into** EF-Map's
  gaps rather than duplicating it.
- See the workspace [authority hierarchy](../../README.md#authority-hierarchy-source-of-truth):
  current vendor source and live behavior outrank any historical doc — including this one.
