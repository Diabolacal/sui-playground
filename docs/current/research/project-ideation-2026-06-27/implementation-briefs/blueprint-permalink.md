# Implementation Brief — Blueprint Build Permalink + Share Cards (I-4)

**Status:** Active research artifact. **Score:** 30/40. **Horizon:** weekend.
**A second strong weekend option alongside the recommended I-1.**

> One-line: *Shareable URLs and Discord preview cards for a manufacturing plan — the share surface
> EF-Map's Blueprint Calculator doesn't have.*

## Why
EF-Map's Blueprint Calculator v5 has **PNG export but no URL state / no permalink / no share-ID**
(verified, Subagent C — `BlueprintCalculatorV5.tsx`). Players naturally want to send "here's the
build" links; today they can only post a static image. The map half of EF-Map *does* have rich deep
links — the calculator is the gap.

## Target users
Builders sharing plans in Discord/forums; tribe leaders distributing build orders; guide writers.

## Non-duplication
Not the calculator engine (EF-Map/EFCopilot/DaOpa cover planning) — a **permalink + share-card layer**
over the same public dataset. Fills a documented gap; could be adopted back into EF-Map.

## MVP scope (weekend)
1. Fetch `https://ef-map.com/blueprint_data_v5.json` (public, no auth).
2. Implement a URL state scheme, e.g. `?item=<typeId>&qty=<n>&facilities=<ids>&owned=<csv>&src=<opts>`.
3. Re-derive the plan from the dataset (match EF-Map's recipe semantics) and render it.
4. Generate an OG share image so the link unfurls in Discord.

## Data sources / contract interactions
- **Web-only, no chain, no wallet.** `blueprint_data_v5.json` is the single source.
- `type_id → name/icon` via World API / `getDatahubGameInfo` (Subagent B; pairs with I-7).

## UI sketch
- Paste/select an item + facilities → a plan view (materials, facility steps) identical in spirit to
  EF-Map's, plus a prominent **Copy share link** button.
- Opening a share link reconstructs the exact plan from the URL.
- "Open in EF-Map" deep link for the full interactive calculator.

## Architecture
Static SPA (Vite) + a serverless OG-image function (Cloudflare/Vercel OG). No backend state — all
state lives in the URL.

## Milestones
- **2-hour spike (kill test):** re-derive one item's plan from `blueprint_data_v5.json` and confirm it
  matches EF-Map's output.
- **Weekend MVP:** URL state + plan render + OG card, deployed.
- **Week 1:** plan comparison links, owned-inventory subtraction, "copy build", embed widget.
- **Later:** propose the `?item=` scheme to EF-Map for native adoption; merge with the multi-build
  aggregator (I-12) and the changelog (I-1) under a Frontier Companion domain (I-23).

## Risks & kill criteria
- Must faithfully match EF-Map's recipe/facility semantics (the spike validates this). **Kill if** the
  plan can't be reproduced from the public JSON.
- Could be absorbed into EF-Map (acceptable — same ecosystem).
- Blueprint space is crowded; the **share** niche is the differentiator — keep scope to permalinks +
  cards, not a competing planner.

## Why build it
Lowest-risk weekend build after I-1: pure public data, no wallet, fills a concrete verified gap, and
produces immediately shareable artifacts that drive their own distribution in Discord.
