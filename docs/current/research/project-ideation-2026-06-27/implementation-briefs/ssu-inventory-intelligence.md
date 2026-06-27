# Implementation Brief — SSU Inventory Intelligence (I-3)

**Status:** Active research artifact. **Score:** 30/40. **Horizon:** 1–2 months.
**Best fit to the operator's stated SSU focus (June 2026 context).**

> One-line: *A personal, read-only dashboard that shows everything you own across all your Smart
> Storage Units — per slot, with a deposit/withdraw audit timeline.*

## Why
The top SSU pain points converge across three workstreams (A, F, G): **no cross-SSU inventory view**
(items are dynamic-field-keyed per OwnerCap, so you must query each SSU), **no audit trail**, and
**opaque `type_id`s**. SSUs are the cycle's named focus surface, and v0.0.24's **`inventory_key`/V2
events** make per-slot reconstruction newly possible.

## Target users
Any player/corp running multiple SSUs; logistics-minded players; anyone who has ever asked "where are
my 2000 units of fuel?"

## Non-duplication (critical)
- **Not shared tribe storage** — a *personal, read-only view* of inventory you already own; no shared
  custody, no pooling (the excluded project is shared *custody*; this is *visibility*).
- **Not the marketplace** — no listings, no settlement.
- **Beyond EF-Map's SSU Finder** — that lists structures on the map; this gives the **per-slot
  contents + deposit/withdraw flow timeline** EF-Map doesn't.

## MVP scope
1. Input a wallet address (no signing). Resolve `PlayerProfile → Character → OwnerCaps → owned SSUs`
   (Subagent A; reuse CivilizationControl's `suiReader.ts` discovery pattern, Subagent E — revalidate
   vs v0.0.24).
2. For each SSU, reconstruct current contents: replay `ItemDepositedEventV2`/`ItemWithdrawnEventV2`
   keyed on `inventory_key` from `StorageUnitCreatedEvent` onward, and/or RPC-read the dynamic field
   by `inventory_key` (Subagent A — note contents are *not* enumerable from events alone).
3. Resolve `type_id → name/icon` via World API / `getDatahubGameInfo` (Subagent B; pairs with I-7).
4. Show: per-SSU contents, capacity (used vs max), and a unified "all my stuff" rollup.

## Data sources / contract interactions
- **Read-only** world-contracts v0.0.24: `inventory.move` V2 events, `storage_unit.move` views
  (`inventory`, `open_storage_key`, `has_open_storage`), `character.move` `PlayerProfile`,
  `access_control.move` OwnerCaps. No wallet/writes.
- Item metadata via World API.

## UI sketch
- Wallet input → "Your SSUs" grid (each card: name from metadata, fill %, top items).
- SSU detail: per-slot (hangar / open / per-character) contents + a chronological audit feed
  (deposited/withdrawn, by whom, when).
- "All holdings" view: aggregate of a `type_id` across all your SSUs ("you have 2,000 Fuel across 3 SSUs").

## Architecture
Indexer (Worker cron or local Node) building a per-SSU inventory projection in KV/D1/SQLite +
dynamic-field RPC reads for ground-truth; static SPA front end. Defensive handling of the temporary
`PlayerProfile` (Subagent A) and the v0.0.24 V2 event shape.

## Milestones
- **Spike (kill test):** confirm on the live server that (a) owned-SSU discovery via
  `PlayerProfile`+OwnerCaps works, and (b) V2 deposit/withdraw events fire with `inventory_key`.
- **Weeks 1–2:** single-SSU contents + capacity for one wallet.
- **Weeks 3–4:** cross-SSU rollup + audit timeline + name resolution.
- **Month 2:** capacity/fill alerts (push to helper/Discord), multi-character, obligation tracking
  (merge with I-9 async delivery).

## Risks & kill criteria
- Inventory not enumerable from events alone → must replay or RPC dynamic fields (more work).
- `PlayerProfile` is explicitly temporary (Subagent A) → wallet→character resolution may change; build
  defensively.
- Live SSU event emission unverified → kill test first.
- Must stay clearly *personal/read-only* to avoid drifting into shared-storage territory.

## Why build it
It's the strongest fit to the operator's stated SSU focus and a real, repeatedly-cited pain with no
existing tool — a genuine community utility that also exercises the v0.0.24 breaking change as a
fresh, needed contribution.
