# Source Review — EVE Frontier Project Ideation (2026-06-27)

**Status:** Active research artifact. Evidence base for the ideation pass.

This pass was run as seven parallel read-only workstreams (subagents A–G). Each was instructed not
to modify or commit in any repo. Findings below are cited with commit SHAs / file paths / URLs so the
operator can re-verify. Full per-workstream notes are preserved in the agent transcripts; condensed
notes live in the scratch folder used during the run.

## Repos & sources inspected

| # | Source | How accessed | Commit / version | Date state |
|---|--------|--------------|------------------|-----------|
| A | `vendor/world-contracts` (local submodule) | Read/Grep + read-only git | `d1929fa` (v0.0.24) | synced 2026-06-27 |
| B | `vendor/builder-documentation` | local submodule | `b4b943e` | current |
| B | `vendor/builder-scaffold` | local submodule | `ebc321a` (v0.0.2) | current |
| C | `Diabolacal/EF-Map` (private) | `gh repo clone --depth 150 --filter=blob:none` (read-only) | `b1cd69e` ("Blueprint Calculator: fix core-material planner Debris dead-end") | Jun 26 2026; **Cycle 6 cutover live 2026-06-25** |
| D | `Diabolacal/ef-map-overlay` (private) | `gh repo clone --depth 200` (read-only) | `8788a16` | last pushed 2026-02-05 (**stale vs web app**) |
| E | `C:\dev\CivilizationControl` (local; also public `Diabolacal/CivilizationControl`) | Read/Grep + git | `ae05b1e` (`master`) | last pushed 2026-06-01 |
| F | `sui-playground/docs/**` historical archive | Read/Grep | branch `research/eve-frontier-project-ideation-20260627` @ `1379544` | this repo |
| G | Web / official / press / community | WebSearch + WebFetch | n/a | 2026-06 |

## Key evidence by workstream

### A — world-contracts (v0.0.24, `d1929fa`)
- **Read-path dominant.** Nearly all writes are `AdminACL::verify_sponsor`-gated (gameplay-server only); the only player writes are `OwnerCap`-gated or require deploying your own extension Move package. → community tools are naturally **no-wallet read-only indexers/visualizers**.
- **New spatial surface:** `rift/rift.move` emits `RiftLocationBroadcastEvent` with **plaintext** `solarsystem,x,y,z` (rift.move:38-46, 99-132) when a gameplay server broadcasts a rift's location at mining start — explicitly to spark PvP. Plus `location.move` `LocationRevealedEvent` (86-96) + `LocationRegistry` `get_location()` (220-226).
- **Breaking inventory change (#155):** `ItemDepositedEventV2`/`ItemWithdrawnEventV2` add `inventory_key: ID` (inventory.move:139-169); all `storage_unit.move` emit sites now emit V2 (V1 still defined). Indexers on old types miss SSU activity.
- **Gate (#140):** new `JumpPermitIssuedEvent` (gate.move:138-149) with `expires_at_timestamp_ms`, `route_hash`, `extension_type`; additive `issue_jump_permit_with_id`.
- **Other read surfaces:** `KillmailCreatedEvent` (killmail.move:57-65), `StatusChangedEvent` (status.move), `FuelEvent`/energy events, `MetadataChangedEvent` (metadata.move:17-23), `CharacterCreatedEvent` + `PlayerProfile` (character.move), `OwnerCapTransferred` (access_control.move:68-73).
- **Caveats:** `type_id`/`item_id` are opaque `u64` (need off-chain catalog); coords are `String`; fuel accounting has acknowledged bug/TODO (fuel.move:297); `PlayerProfile` is explicitly temporary; inventory contents are **not** enumerable from events alone.
- `turret.move` is still implemented (+68 lines in v0.0.24) — see exclusions for the player-vs-contract nuance.

### B — builder docs + scaffold
- Official stack: Sui + Move + `@evefrontier/dapp-kit` (React) + EVE Vault wallet. Writes are gas-consuming or **sponsored (EVE-Vault-only)**.
- **Blessed no-wallet read path:** Sui GraphQL / gRPC / `suix_queryEvents`, plus a **public World API REST** (Stillness live + Utopia sandbox) and deterministic object-ID derivation.
- **Enablers in scaffold:** `ts-scripts/utils/derive-object-id.ts` (compute Sui object ID from in-game ItemID, no wallet); `ts-scripts/utils/dev-inspect.ts` (call Move view functions without signing); `dapps/` Vite+React+dapp-kit starter with `queries.ts` (8 GraphQL read helpers, incl. `getDatahubGameInfo(typeId)` for item names/icons — solves the opaque-`type_id` problem).
- **In-game DApp browser** loads URL-param pages (`?tenant=&itemId=`), enabling lightweight in-game microtools.
- **Docs lag contracts** on the inventory-V2, rift, killmail, and location-reveal surfaces — no official tooling exists for those.

### C — EF-Map (`b1cd69e`)
- Free community web app `https://ef-map.com` (React/Three.js 3D starmap; client-side routing; Cloudflare Pages+Worker+KV/R2; Primordium pg-indexer → Postgres → snapshot-exporter pushes Sui data into KV). **Cycle 6 cutover complete 2026-06-25** — data is current; do **not** propose a refresh.
- **Already ships:** 3D map, route planner, Blueprint Calculator v5, Smart Assemblies panel, Cycle 6 Stargate Status Reporting, **Killboard**, **SSU Finder**, Intelligence search, System Finder, Scout Reports, Log Parser, Leaderboards, State of the Frontier weekly report.
- **Documented gaps (build into these):** Blueprint Calculator has PNG export but **no URL/permalink/share state**; State of the Frontier diffs **live activity only — nothing diffs static blueprint/recipe/facility changes** (and `blueprint_data_v5.json` embeds a `cycle6Filter` block); calculator ranks by material **volume not ISK**; route planner **doesn't avoid dormant gates**; single-target only; no Discord bot (appetite documented); no GPT/MCP connector (llms.txt asks for it).
- **Public, no-auth integration seams:** `ef-map.com/blueprint_data_v5.json`, `stargate_edges_cycle6.json`, map SQLite DB, a full embed/deep-link + `postMessage` contract, and a `/api/create-share` short-link service.

### D — ef-map-overlay (`8788a16`, last pushed Feb 2026)
- **Native Windows C++/DX12+ImGui in-game overlay** (Microsoft Store ID `9NP71MBTF6GF`, MSIX, auto-update) bridged to EF-Map via localhost HTTP `:38765` / WS `:38766` + an `ef-overlay://` deep-link protocol.
- Already does: live in-game route display with auto-advance, follow-mode (recenters map from local chat logs), mining/combat telemetry, visited-systems, bookmarks, P-SCAN, tray notifications.
- **Latent:** renders **arbitrary JSON pushed by the web app** (`hud_hints[]`/`highlighted_systems[]` schema fields exist but are barely used) → many ideas are **web-only against the frozen helper contract** (fast) vs C++ rebuild + Store re-cert (slow).
- **Privacy line (hard):** parses the player's **own local logs only**, binds loopback; DLL injection is the sole ToS/anti-cheat exposure. Keep to display + clipboard + user-initiated; no memory reads, no automation, presence self-only.

### E — CivilizationControl (`ae05b1e`)
- Shipped, prize-winning governance dApp on Stillness; Move extension package + React 19 SPA. Targets world-contracts **v0.0.13–16** — **not migrated to v0.0.24** (revalidate before reuse).
- **Reusable building blocks** (file-cited): OwnerCap borrow/return PTB wrapper, batch-PTB, asset-discovery pipeline (`suiReader.ts`), transparent gas sponsorship (Cloudflare worker), event→digest folding (`eventParser.ts` EVENT_MAP), SVG topology map (`gameToWorld` + 24.5k-system catalog), off-chain spatial-pin privacy model, in-game CEF webview constraints doc (787×1198 portrait).

### F — historical archive
- The March cycle was **gate-centric**; June is **SSU-centric / single-ship / no-turrets**. This inverts the archive's value toward its **secondary SSU ideas** (dead-drop, escrow, courier, inventory intelligence).
- Many old kill-reasons are now obsolete (turret closed-world; AdminACL-sponsor demo blockers; single-extension-slot; character resolution — solved by `PlayerProfile`; no on-chain coords — partly solved by location reveal).
- Reusable **8-criterion + player-vote scoring rubric** and a documented SSU pain-point catalogue (`docs/research/player-value-ux-analysis.md`).

### G — community / web
- **Verified Cycle 6 "Sanctuary"** (wipe 2026-06-25; single "Root" hull + internal modules; single "cutting laser"; **star-heat hazard**; fuel economy LUX→lenses→**Crude from Rifts**→Fuel; no docking/safe-logoff; 5-day trial). Sources: evefrontier.com, mmorpg.com, geekmetaverse.com, starzen.space, whitepaper.evefrontier.com, docs.evefrontier.com.
- **Existing tools** (avoid): EFCopilot, DaOpa fansite, EFTB, EVE Frontier Finder, **Eve Node Tracker Discord bot** (already does fuel-low alerts), EVE Frontier Wiki, Pool Party Nodes.
- **Turret nuance:** ship turret *weapons* were streamlined out (cutting laser); the on-chain Smart Turret *assembly* persists in v0.0.24.

## Gaps / access limitations (carry into every downstream decision)

1. **No direct player sentiment.** WebSearch surfaced essentially no Reddit/Discord/forum threads (US-only index; community lives in non-indexed Discord). Pain points lean on press + EF-Map blog + the repo's contract-grounded analysis. **Revalidate sentiment with the live community before building.**
2. **Historical contract claims** in the sui-playground archive and CivilizationControl are pinned to ≤ v0.0.18 / v0.0.13–16. Re-verify any on-chain shape against current `vendor/world-contracts` (v0.0.24), especially the breaking `inventory_key`/V2 event change.
3. **Live-server emission unverified.** Whether `RiftLocationBroadcastEvent` / `LocationRevealedEvent` / killmail / SSU V2 events actually fire on the live Stillness server (and how often, with what data quality) was **not** verified — it requires a live RPC subscription. Any on-chain idea must pass that kill test first.
4. **EF-Map APIs are origin-gated** (X-API-Key, 120 req/min) since Dec 2025; static CDN assets (`blueprint_data_v5.json`, `stargate_edges_cycle6.json`, map DB) are the unrestricted surface.
5. **Overlay repo is stale (Feb 2026)** relative to the EF-Map web app (June 2026); the helper wire contract (schema v4) is a frozen substrate the web app is evolving past.
