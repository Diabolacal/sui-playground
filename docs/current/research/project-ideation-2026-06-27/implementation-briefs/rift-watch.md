# Implementation Brief — Rift Watch (I-2)

**Status:** Active research artifact. **Score:** 33/40. **Horizon:** 1-hour kill test → 1–4 weeks.
**Gating caveat:** depends on a live on-chain event firing — run the kill test before committing.

> One-line: *A live public map of where rifts are being broadcast right now, so miners and PvPers can
> see where the Crude (and the action) is.*

## Why
Rifts are the **economic heart of Cycle 6** — players buy Crude Mining Lenses with $EVE, extract Crude
Matter from rifts, and refine it into Fuel (Subagent G; whitepaper). The contract added a **plaintext
location broadcast** for rifts *specifically to enable PvP interference* (Subagent A,
`rift/rift.move:38-46`, `:99-132` — `RiftLocationBroadcastEvent` with `solarsystem,x,y,z,rift_key`).
Nobody has built a live rift feed, and it's undocumented in the builder docs (Subagent B) — wide open.

## Target users
PvP-minded players, gankers/defenders, miners deciding where to work, streamers ("watch the frontier
light up").

## Kill test (do this first — ~1 hour, zero build)
Point a Sui RPC at the live Stillness world package and poll `suix_queryEvents` for
`RiftLocationBroadcastEvent` (and `RiftSpawnedEvent`) for ~1 hour. Confirm: (a) events fire, (b) they
carry parseable `solarsystem/x/y/z`, (c) frequency is high enough to be interesting. **If they don't
fire / are rare / lack usable coords, descope** to a rift *history* explorer or shelve the idea.

## MVP scope (after kill test passes)
1. Indexer: subscribe to `RiftLocationBroadcastEvent`/`RiftSpawnedEvent`/`RiftDespawn` via
   `suix_queryEvents` (read-only, no wallet); store recent rifts (system, coords, age, status) in
   KV/SQLite.
2. Public page: "Rifts broadcasting now" — list + freshness, each linking to
   `ef-map.com/?system=<id>` (Subagent C deep-link contract).
3. Optional map: embed EF-Map (`/embed?system=…`) or plot in solar-system coordinate space (coords are
   `String`, parse for negatives — Subagent A caveat).

## Data sources / contract interactions
- **Read-only** world-contracts (v0.0.24 `d1929fa`): `rift.move` events. No writes, no wallet.
- Item/character enrichment via World API / `getDatahubGameInfo` (Subagent B) and
  `CharacterCreatedEvent`/metadata for names (Subagent A).
- EF-Map embed/deep links for the map render (Subagent C).

## Non-duplication
EF-Map shows structures/systems, not a *live rift PvP feed*. Not a killboard (EF-Map/EFCopilot have
those). Not the marketplace/shared-storage.

## Architecture
Cloudflare Worker cron (or a small local Node indexer) → KV/D1 → static SPA embedding EF-Map. Reuse
CivilizationControl's event-folding descriptor pattern (`eventParser.ts`, Subagent E) for decoding.

## Milestones
- **1-hour kill test** (above).
- **Week 1:** indexer + "broadcasting now" list + EF-Map links.
- **Weeks 2–4:** map render, history/replay, "rift lit up in system X" notifications, region/tribe filters.
- **Month+:** fuse with revealed gates/SSUs/killmails → a "frontier activity heatmap"; alerting service.

## Risks & kill criteria
- **Primary risk:** live emission/frequency (the kill test gates everything).
- Coords are strings (parse defensively); `type_id`s opaque (enrich off-chain).
- If rifts broadcast rarely, the "live" value collapses → pivot to history/story-map.

## Why it could be the best build
If the kill test passes, this is the highest-upside, most *exciting*, most on-theme, most GIF-able
tool in the set — a live "where's the action" map for the cycle's defining economic loop, on a
brand-new on-chain surface nobody else uses. It's #2 only because of the unverified-emission risk; a
passing kill test promotes it.
