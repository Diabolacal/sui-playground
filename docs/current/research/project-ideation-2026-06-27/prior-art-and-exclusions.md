# Prior Art & Exclusions — EVE Frontier Project Ideation (2026-06-27)

**Status:** Active research artifact. Read alongside [`opportunity-map.md`](opportunity-map.md) and
[`idea-cards.md`](idea-cards.md).

This document records what already exists (so we don't duplicate it) and, for each exclusion, whether
a **materially different remix** is allowed. The operator's hard exclusions are honored throughout.

---

## Hard exclusions (operator-stated) — and remix verdicts

| Excluded as-is | Why excluded | Evidence | Remix possible? |
|---|---|---|---|
| **Shared tribe storage for SSUs** | Already built by someone else | operator context (`docs/current/eve-frontier-context-2026-06.md`) | **Only beside it, never as it.** A *personal* cross-SSU inventory **view** (read-only, no shared custody), or programmable per-condition access rules, are different primitives. Do not build a shared custody pool. |
| **Generic marketplace** | Already exists | operator context | **Only with a materially different angle.** Conditional/escrowed release, dead-drop, consignment-style pay-to-withdraw, or reputation are *not* an order-book marketplace. Avoid listings/price-discovery. |
| **CivilizationControl / GateControl / TradePost / ZK GatePass** | Shipped (prize-winning) | `Diabolacal/CivilizationControl` @ `ae05b1e` (gate_control.move, trade_post.move) | **Only as a remix of patterns**, not the products. Re-skinning the governance console, gate policy authoring, or SSU storefront is out. Reusing the OwnerCap-PTB / event-folding / sponsorship patterns into a *different* product is fine. |
| **Fortune Gauntlet / Cargo Bond / Atomic Courier / Shadow Broker** | Prior hackathon concepts | `docs/strategy/**`, `experiments/atomic_courier_experiment/` | **Remix only.** VRF→SSU loot, escrow→SSU dead-drop, Walrus+Seal→encrypted SSU manifests are differentiated descendants, not the originals. |
| **EF-Map map refresh / Cycle 6 data refresh / Blueprint Calculator base work** | Already done (Cycle 6 cutover live 2026-06-25) | `EF-Map` @ `b1cd69e`; `docs/plans/cycle-6-cutover-plan-2026-06-25.md` | **Build companions, not re-implementations.** Permalinks, share cards, diffs, multi-target aggregation, ISK overlays, dependency graphs are additive. Re-doing the map/route/calculator engine is out. |
| **Basic industry-management tools** | Limited cycle scope for heavy industry | operator context | Lightweight, awareness/onboarding-flavored industry *companions* are OK; full production managers are out. |
| **Turret projects** | "Turrets no longer in the game this cycle" | operator context | **Out.** See turret nuance below — even though the on-chain assembly persists, treat turret-facing player tools as excluded. |
| **Generic dashboards restating EF-Map / CivilizationControl** | No new value | — | Out. A dashboard must surface something neither tool shows (e.g. a static-data diff, a per-slot inventory flow, a live rift feed). |

### Turret nuance (important, from Subagent G)
There are **two** "turret" concepts and the exclusion applies to both for *player-facing tools*:
- **Ship-mounted turret weapons** were streamlined out of the Cycle 6 ship in favor of a single
  "cutting laser" (diverse weapons "to be reintroduced later") — verified via press
  (mmorpg.com, starzen.space).
- **The on-chain Smart Turret assembly** (`turret.move`) is **still present** in world-contracts
  v0.0.24 (+68 lines). So a *builder* could still write turret extensions — but per the operator's
  exclusion and the fact that turret weapons aren't in the live player loop this cycle, **we do not
  propose turret tools.** (Noted here only so a future agent doesn't "discover" the contract surface
  and assume it's fair game.)

---

## Existing community tools (independent of the operator) — do not duplicate

From Subagent G (with URLs in [`source-review.md`](source-review.md)):

| Tool | Covers | Implication |
|------|--------|-------------|
| **EF-Map** | 3D map, route/scout planner, Blueprint Calculator v5, Smart Assemblies panel, **Killboard**, **SSU Finder**, Intelligence search, Stargate Status Reporting, State of the Frontier, EF Helper overlay | The biggest footprint. Most "show X on a map / route / killboard / SSU browser" ideas are taken. **Build into its documented gaps.** |
| **EFCopilot** | Industry calculator (byproduct optimization), 3D map + routing, deep scan, killboard | Blueprint/industry + map + killboard crowded. |
| **DaOpa's Fansite** | Ship/module DB, recursive blueprint calc, materials production tree, "What Can I Make With This?" | Blueprint/material calculators crowded. |
| **EVE Frontier Toolbox (EFTB)** | Multi-hop jump route planner, fuel-cost calc, base-materials calc, Region Exit Finder | Jump/fuel calculators crowded. |
| **EVE Frontier Finder** | Distance/jump calculator | Distance calc taken. |
| **Eve Node Tracker (Discord bot)** | Link node, check fuel/uptime, **auto DM when fuel low** | **Fuel-low alerts already exist** (single-node). Differentiate hard or avoid. |
| **EVE Frontier Wiki / Pool Party Nodes** | Guides, FAQ, beginner content | Curated wikis exist; don't hand-maintain a competing wiki. |

### What this leaves genuinely open (the white space)
Cross-referencing all seven workstreams, the **uncovered** opportunities are:
- **Patch-to-patch static-data diffing** (no tool diffs blueprint/recipe/facility changes; EF-Map's
  State of the Frontier covers live activity only). ← strongest, lowest-risk gap.
- **Permalink / share surfaces** for the Blueprint Calculator (PNG export only today).
- **A live "where is the action" rift feed** exploiting the new plaintext `RiftLocationBroadcastEvent`
  (no tool; pending a live-emission kill test).
- **Personal cross-SSU inventory intelligence** built on the new `inventory_key`/V2 events
  (EF-Map's SSU Finder lists structures; it does not give you a per-slot "where's my stuff" flow view).
- **AI/Discord connectors** to EF-Map's public deep-link contract (appetite documented, nothing shipped).
- **Small glue primitives** — a `type_id → name/icon` decoder, a "resolve any structure by ItemID"
  inspector — that other tools can reuse.

---

## Prior ideas already considered / killed (from the sui-playground archive, Subagent F)

These were scored or killed in the March cycle. **All contract claims are ≤ v0.0.18 — revalidate.**

| Prior idea | March status | Current-cycle verdict |
|------------|--------------|------------------------|
| Killmail Intelligence / killboard | scored-low (ephemeral events) | **Now covered by EF-Map + EFCopilot** → out as a standalone. |
| Structure Insurance | **killed** (killmail had no public getters) | Revalidate killmail getters in v0.0.24; still risky. Out for now. |
| Corp Treasury Manager | **killed** (`OwnerCap` lacks `store`) | Structural Move fact; likely still true. Out. |
| Fuel Watch / Fuel Sentinel | scored-low | **Eve Node Tracker bot already does fuel alerts.** Differentiate (multi-assembly *runway*) or drop. |
| Dead Drop (espionage exchange) | planned/backup | **Strong remix** under SSU open-inventory custody (revalidate). |
| Time-Locked Vault | scored-low | **Viable remix** as Time-Locked SSU Release. |
| Logistics Router / Cargo Manifest | scored-low/planned | **Viable** as async delivery/obligation tracker (single ship makes courier role natural). |
| Gate Graffiti Wall | scored-low (250 KB limit) | Remix to SSU metadata logbook (ring-buffer). Fun, low-risk. |
| Salvage Protocol (storage-rebate) | "Most Creative" pick, not built | Verify `unanchor()` isn't AdminCap-only; otherwise novel. |
| ZK GatePass | **deferred, never built** | A *new* ZK-on-SSU idea isn't strict duplication, but it's explored ground — differentiate clearly. |

---

## Net guidance for the idea set
1. **Default to public, no-wallet, read-only** tools (max adoption; the contract surface is read-path).
2. **Sit beside** the shared-storage and marketplace projects — never re-implement them.
3. **Fill EF-Map's documented gaps**; don't redo its map/route/calculator.
4. **Penalize unverified contract assumptions** — anything depending on a live event firing must carry
   a kill test before it can be ranked #1.
5. **Reward** current-cycle relevance (Cycle 6 confusion, SSU focus, rifts/fuel economy), fun/memorable
   framing, and demoability.
