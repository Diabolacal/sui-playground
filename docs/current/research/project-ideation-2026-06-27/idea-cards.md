# Idea Cards — EVE Frontier Project Ideation (2026-06-27)

**Status:** Active research artifact. 26 evidence-cited candidate projects.

**Scoring rubric (each 0–5, total /40):** `Use` community usefulness · `Fun` fun/weirdness/memorability ·
`Wknd` buildable this weekend · `Diff` differentiation from existing tools · `Cyc` fit with Cycle 6 ·
`Syn` EF-Map/helper synergy · `WC` world-contracts leverage · `Maint` maintenance-burden inverse (5 = low burden).
Ranking and bucket lists are in [`ranked-shortlist.md`](ranked-shortlist.md). Exclusions in
[`prior-art-and-exclusions.md`](prior-art-and-exclusions.md).

> **Evidence keys:** A=world-contracts · B=builder docs/scaffold · C=EF-Map · D=overlay · E=CivilizationControl ·
> F=archive · G=community. All on-chain claims are at world-contracts `d1929fa` (v0.0.24); all such ideas
> require a **live-emission kill test** before relying on the event.

---

### I-1 · Frontier Changelog ("What Changed") — ★ recommended
**Pitch:** A public, auto-generated changelog that diffs EVE Frontier's static game data between patches/cycles — "what blueprints, recipes, facilities and modules changed" — with a returning-player "what changed since I left" lens.
**Value:** The Cycle 6 wipe forced everyone to relearn; press reports "very negative early discourse" (G). No tool does this — EF-Map's State of the Frontier diffs *live activity* only, not static data (C).
**Why fun/distinctive:** Patch notes with personality ("RIP Assembler 88068", "Emergency Printer is just a Mini Printer in a trenchcoat", "~115 modules vanished"). Shareable diff cards for Discord.
**Uses:** Web-only, no-chain. Consumes EF-Map public assets `blueprint_data_v5.json` (incl. embedded `cycle6Filter`) + successive versions; optionally the map SQLite DB and `stargate_edges_cycle6.json` (C).
**Non-duplication:** Not the calculator, not the map, not a wiki. State of the Frontier explicitly doesn't cover static-data deltas (C). Complements EF-Map; could be adopted back later.
**Weekend MVP:** Fetch v4 + v5 `blueprint_data`, diff items/recipes/facilities, render a clean "Cycle 6 changes" page + OG share image.
**One-month:** Versioned snapshots, arbitrary range "since I left" picker, per-category sections, RSS/Discord webhook on new patches, deep-links into EF-Map calculator/map for each changed item.
**Two-month:** Extend to diff the universe map (system/gate deltas between `map_data` versions) and an on-chain assembly census over time → a full "Frontier patch witness."
**Risks:** Dependency on EF-Map data shape (operator's own project → low risk, but version it). Most valuable at patch time (mitigated by returning-player + evergreen wipe cadence).
**Kill test:** Diff v4→v5 `blueprint_data` in an afternoon; if the delta is legible and interesting, proceed. (Near-zero — data is on the CDN now.)
**Shape:** Static SPA (Vite) or a tiny Worker that caches dataset versions; pure client diff; OG image via a serverless function.
**Score:** Use5 Fun4 Wknd5 Diff5 Cyc5 Syn5 WC1 Maint5 = **35/40**

---

### I-2 · Rift Watch — "where's the action right now"
**Pitch:** A live public map of rifts the moment a gameplay server broadcasts their plaintext location, so miners and PvPers can see where Crude is being pulled and contested.
**Value:** Rifts are the **economic heart of Cycle 6** (Crude→Fuel) (G); the contract literally added plaintext location reveal "to enable PvP interference" (A).
**Why fun/distinctive:** A live "go here, something's happening" feed is inherently dramatic and GIF-able. No tool exists.
**Uses:** world-contracts read-only (`RiftLocationBroadcastEvent`, rift.move:38-46/99-132) (A); embeds EF-Map map via deep link to the rift's system (C). No wallet.
**Non-duplication:** EF-Map shows structures/systems, not a live rift PvP feed. Undocumented surface (B).
**Weekend MVP:** Subscribe to the event via `suix_queryEvents`, list "rifts broadcasting now" with system + coords + age; link each to `ef-map.com/?system=`.
**One-month:** Map render of active rifts, history/replay, "rift just lit up in system X" notifications, tribe/region filters.
**Two-month:** Fuse with revealed gates/SSUs/killmails for a "frontier activity heatmap"; alerting service.
**Risks:** **Core assumption unverified** — does the live Stillness server emit this event, how often, with usable data? (A flags it as server/sponsor-emitted.) High payoff if yes; fizzles if rifts rarely broadcast.
**Kill test:** Point a Sui RPC `suix_queryEvents` at the live rift module for ~1 hour; confirm events fire with parseable coords. **Do this before committing.**
**Shape:** Small indexer (Worker cron or local) → KV/SQLite → static map SPA embedding EF-Map.
**Score:** Use4 Fun5 Wknd2 Diff5 Cyc5 Syn4 WC5 Maint3 = **33/40** (−unverified-assumption flag)

---

### I-3 · SSU Inventory Intelligence — "where's my stuff"
**Pitch:** A personal, read-only cross-SSU inventory dashboard: aggregate everything you own across all your Smart Storage Units, per-slot, with a deposit/withdraw audit timeline.
**Value:** Top SSU pain (A, F, G): no cross-SSU view, no audit trail, capacity blindness — items scatter and you must query each SSU. SSU is the operator's named focus.
**Why fun/distinctive:** Turns the opaque DF-keyed mess into a clean "your holdings" view; the per-slot *flow* timeline is genuinely new.
**Uses:** world-contracts read (`ItemDepositedEventV2`/`ItemWithdrawnEventV2` + `inventory_key`, inventory.move:139-169; `StorageUnitCreatedEvent`; `PlayerProfile` wallet→character) (A); `getDatahubGameInfo`/World API for item names (B). No wallet (wallet address as input).
**Non-duplication:** **Not shared tribe storage** — a personal read-only *view*, no shared custody. EF-Map's SSU Finder lists structures; it doesn't give per-slot inventory flow (C).
**Weekend MVP:** Given a wallet, resolve character → owned SSUs → replay V2 events → show current contents + capacity per SSU.
**One-month:** Audit timeline, capacity/fill alerts, type-flow analytics, multi-character.
**Two-month:** Push capacity alerts to the helper/Discord; obligation tracking (see I-9).
**Risks:** Inventory not enumerable from events alone — must replay V2 from creation or RPC dynamic fields (A); `PlayerProfile` temporary (A); live SSU event emission unverified; must stay clearly *personal*, not shared.
**Kill test:** Confirm V2 events fire on live server for a known SSU and that owned-SSU discovery via `PlayerProfile`+OwnerCaps works.
**Shape:** Indexer (Worker/local) + dynamic-field RPC reads + static SPA; reuse CivilizationControl's `suiReader.ts` discovery pattern (E, revalidate vs v0.0.24).
**Score:** Use5 Fun2 Wknd2 Diff5 Cyc5 Syn3 WC5 Maint3 = **30/40**

---

### I-4 · Blueprint Build Permalink + Share Cards
**Pitch:** Shareable URLs and Discord OG cards for a manufacturing plan — the share surface EF-Map's Blueprint Calculator lacks.
**Value:** The calculator has PNG export but **no URL state / no permalink** (verified, C). Players want to share "here's the build" links.
**Why fun/distinctive:** One link → a rich preview card in Discord with materials/facilities. Frictionless sharing.
**Uses:** Web-only; consumes `blueprint_data_v5.json` (C). No chain, no wallet.
**Non-duplication:** Not the calculator engine — a permalink + card layer over the same public data. Fills a documented gap.
**Weekend MVP:** `?item=<id>&facilities=…&owned=…` URL state → renders a plan + OG image.
**One-month:** Plan comparison links, "copy build", embed widget, optional contribution of the param scheme back to EF-Map.
**Risks:** Could be absorbed into EF-Map (fine — synergy). Blueprint space is crowded; the *share* niche is the differentiator.
**Kill test:** Re-derive a plan from `blueprint_data_v5.json` matching EF-Map's output for one item.
**Shape:** Static SPA + serverless OG-image function.
**Score:** Use4 Fun3 Wknd5 Diff3 Cyc4 Syn5 WC1 Maint5 = **30/40**

---

### I-5 · "Frontier Facts" GPT Action / MCP Connector
**Pitch:** A hosted MCP server / GPT action that answers EVE Frontier route, system, and build questions by linking to EF-Map — turning assistants into Frontier-aware helpers.
**Value:** New/returning players ask the same questions; AI assistants currently can't answer with live links. EF-Map's `llms.txt` **explicitly requests** linking to it (C).
**Why fun/distinctive:** "Ask ChatGPT/Claude how to get from A to B" → it returns an EF-Map route link. AI-era, novel, nobody's built it.
**Uses:** Web-only; wraps `llms-full.txt` + `/ai-facts` + EF-Map deep-link patterns (C). No chain.
**Non-duplication:** Not a chatbot rebuild of EF-Map — a thin connector exposing its public data contract to assistants.
**Weekend MVP:** MCP server with tools: `route(from,to)`, `system(name)`, `build(item)` → returns EF-Map URLs + facts.
**One-month:** Publish as a ChatGPT GPT + an MCP server in registries; add blueprint/diff facts (pairs with I-1).
**Risks:** Audience skews to AI users; value depends on EF-Map URL stability (stable, documented).
**Kill test:** Stand up an MCP server returning a correct `/?from=&to=` link for one query.
**Shape:** Tiny Node/TS MCP server (or Cloudflare Worker) over public assets.
**Score:** Use4 Fun3 Wknd5 Diff5 Cyc3 Syn5 WC1 Maint4 = **30/40**

---

### I-6 · Discord Bot for EF-Map Deep Links
**Pitch:** A Discord bot: `!route A B`, `!system X`, `!build Item` → posts EF-Map deep links / embeds inline.
**Value:** Frontier coordination happens in Discord; EF-Map has a documented `DISCORD_INTEGRATION_PLAN.md` and appetite but **no shipped bot** (C).
**Why fun/distinctive:** Meets players where they already are; instant utility per message.
**Uses:** Web-only; public EF-Map URL patterns + (optionally) `blueprint_data_v5.json` (C). No chain.
**Non-duplication:** Not a map/route rebuild — a chat front-door to EF-Map's existing URLs.
**Weekend MVP:** Slash commands generating `/?from=&to=`, `/?q=`, and (with I-1/I-4) build/diff links.
**One-month:** Rich embeds, autocomplete from system catalog, per-guild defaults, share-link creation via `/api/create-share`.
**Risks:** Needs hosting + bot token; low maintenance otherwise.
**Kill test:** A bot that turns `!route Jita Amarr` into a working link in 2 hours.
**Shape:** discord.js/Serverless bot.
**Score:** Use4 Fun3 Wknd5 Diff4 Cyc3 Syn5 WC1 Maint4 = **29/40**

---

### I-7 · `type_id → name/icon` Decoder (shared glue)
**Pitch:** A tiny public service + embeddable widget that resolves opaque EVE Frontier `type_id`/`item_id` numbers into names and icons.
**Value:** Item types are opaque integers on-chain (A); "what is item 42?" is a recurring confusion (F, G). Every other read-tool needs this.
**Why fun/distinctive:** Small, high-leverage glue everyone reuses; the unglamorous primitive that makes other tools possible.
**Uses:** World API REST + `getDatahubGameInfo(typeId)` (B); a thin cache. No wallet. No chain writes.
**Non-duplication:** Not a marketplace/DB browser — a focused resolver/API + widget.
**Weekend MVP:** Cache the World API item DB; expose `GET /type/:id` → `{name, icon, category}` + a copy-paste `<ef-item id=…>` widget.
**One-month:** Bulk endpoint, autocomplete, npm package, used by I-1/I-3.
**Risks:** Depends on World API availability (official, blessed). Possibly partly solved by `getDatahubGameInfo` already — position as a cached/edge convenience layer.
**Kill test:** Resolve 10 known `type_id`s via World API.
**Shape:** Cloudflare Worker + KV cache.
**Score:** Use4 Fun2 Wknd5 Diff4 Cyc4 Syn3 WC2 Maint4 = **28/40**

---

### I-8 · Dormant-Gate-Aware Route / Chokepoint Companion
**Pitch:** A companion that finds routes minimizing dormant Cycle 6 stargates and visualizes chokepoints, then hands off to EF-Map.
**Value:** EF-Map's route planner **does not yet avoid dormant gates** (explicit known gap, C); Cycle 6 made gates dormant-by-default (G).
**Why fun/distinctive:** Solves a fresh, concrete Cycle 6 routing problem nobody covers.
**Uses:** EF-Map `/api/stargate-status` (signed-in) + public `stargate_edges_cycle6.json`; handoff via `/?from=&to=` or `/api/create-share` (C). No wallet for the core.
**Non-duplication:** Not the route planner — a status-aware pre-filter + chokepoint view that defers actual routing/render to EF-Map.
**Weekend MVP:** Pull edges + status, compute "fewest dormant" path between two systems, output an EF-Map link.
**One-month:** Coverage map (which gates have no reports), chokepoint heatmap, alerts.
**Risks:** Needs API access (origin/key); dormant-status data quality depends on player reporting.
**Kill test:** Fetch `stargate_edges_cycle6.json` + status sample and compute one corridor.
**Shape:** Worker + small SPA embedding EF-Map.
**Score:** Use4 Fun2 Wknd3 Diff4 Cyc5 Syn5 WC2 Maint3 = **28/40**

---

### I-9 · Async Delivery / Obligation Tracker (corp coordination, no shared custody)
**Pitch:** "Did the haul I owed you actually land in your SSU?" — a read-only tracker of `deposit_to_owned` async deliveries between players.
**Value:** Single-ship logistics makes the courier role central; players coordinate deliveries with no confirmation today (F, G). Coordinates obligations **without** any shared storage pool.
**Why fun/distinctive:** A trust/receipt layer for player-to-player hauling — a social primitive, not a marketplace.
**Uses:** world-contracts read (`ItemDepositedEventV2` with `inventory_key`/`character_id`, deposit-to-owned path) (A, F). No wallet to *watch*; optional wallet to *record* an obligation.
**Non-duplication:** Not the marketplace (no listings/settlement), not shared storage (no pooled custody) — a delivery-confirmation ledger.
**Weekend MVP:** Watch deposit events to a recipient's SSU; show "expected vs landed" against manually entered obligations.
**One-month:** Shareable obligation links, multi-party, helper/Discord "delivery landed" pings.
**Two-month:** Optional on-chain escrow/receipt object (becomes a builder project).
**Risks:** Event emission unverified; matching deliveries to obligations is heuristic without on-chain memo.
**Kill test:** Confirm `deposit_to_owned` emits a V2 event identifying recipient + item on live server.
**Shape:** Indexer + SPA; reuse CivilizationControl event-folding (E).
**Score:** Use4 Fun3 Wknd2 Diff5 Cyc5 Syn2 WC5 Maint3 = **29/40**

---

### I-10 · "Forgot to Refuel" Runway Tracker (humor + utility)
**Pitch:** A multi-assembly fuel-runway view for your own structures with a self-deprecating "hall of shame" for near-dark-outs.
**Value:** Fuel-going-dark is called the "#1 avoidable disaster" (F); fuel powers everything in Cycle 6 (G).
**Why fun/distinctive:** The joke (hall of shame) makes a real safety tool sticky and shareable.
**Uses:** world-contracts read (`FuelEvent`, `need_update` view, `NetworkNodeCreatedEvent`) (A). No wallet.
**Non-duplication:** Eve Node Tracker bot does **single-node fuel alerts** (G) — differentiate as a **multi-assembly runway** view + humor layer, not per-node alerting.
**Weekend MVP:** Given your structures, compute time-to-empty from fuel events; rank by urgency.
**One-month:** Helper/Discord pings, "hall of shame" leaderboard (opt-in), region rollups.
**Risks:** Fuel accounting has an acknowledged contract bug/TODO (A) → runway is approximate; overlaps the incumbent bot's niche.
**Kill test:** Compute a plausible runway for one NWN from `FuelEvent` history.
**Shape:** Indexer + SPA.
**Score:** Use3 Fun5 Wknd3 Diff3 Cyc4 Syn3 WC4 Maint3 = **28/40**

---

### I-11 · SSU Metadata Graffiti / Station Logbook
**Pitch:** Let visitors leave short on-chain messages on an SSU (owner-writable metadata or a capped ring-buffer) — a station guestbook / notice board.
**Value:** Pure community fun; a social texture layer the chain can carry.
**Why fun/distinctive:** "Leave your mark" on a station; memorials, jokes, bounty notes.
**Uses:** world-contracts write (`MetadataChangedEvent`/`update_metadata_*` on SSU; or a small DF ring-buffer extension) (A, F). Wallet required.
**Non-duplication:** Remix of the archived Gate Graffiti Wall to SSU metadata; not storage, not marketplace.
**Weekend MVP:** Read + display an SSU's metadata "wall"; (write needs an extension + wallet).
**One-month:** A small Move extension for capped messages + a viewer.
**Risks:** Object-size limits (ring-buffer prune); write path needs wallet + the owner to authorize; moderation/abuse.
**Kill test:** Confirm `update_metadata_*` works on an SSU on localnet/v0.0.24.
**Shape:** Move extension + viewer SPA.
**Score:** Use2 Fun5 Wknd3 Diff4 Cyc3 Syn2 WC4 Maint3 = **26/40**

---

### I-12 · Multi-Build "Shopping List" Aggregator
**Pitch:** Plan N targets at once and aggregate total source materials + facility time across a whole production batch.
**Value:** EF-Map's calculator plans **one target at a time** (C); fleets/corps build in batches.
**Uses:** Web-only; `blueprint_data_v5.json` recipe graph (C). No chain.
**Non-duplication:** Not the single-target calculator — a batch aggregator over the same public data.
**Weekend MVP:** Sum the recipe trees for a list of {item, qty}; output total materials + a checklist.
**One-month:** Owned-inventory subtraction, facility-time scheduling, shareable list (pairs with I-4).
**Risks:** Must match EF-Map's recipe semantics; could be folded into EF-Map.
**Kill test:** Aggregate two targets and reconcile against running EF-Map twice.
**Shape:** Static SPA reusing the recipe graph.
**Score:** Use4 Fun2 Wknd4 Diff3 Cyc4 Syn5 WC1 Maint4 = **27/40**

---

### I-13 · Facility-Coverage "What Can I Build Here?"
**Pitch:** Given the facilities at a system/base, show exactly what's buildable — the inverse of EF-Map's buildable filter, oriented around a real base.
**Value:** Cycle 6's facility/printer changes (Emergency vs Mini Printer; Assembler removed) confuse builders (C, G).
**Uses:** `recipeFacilityMatrix` + facility set from `blueprint_data_v5.json`; optionally `/api/structure-snapshot` for a system's real assemblies (C). No wallet.
**Non-duplication:** EF-Map's buildable filter is item-first ("which BPs can my facilities build"); this is location-first ("at THIS base, what's possible").
**Weekend MVP:** Pick facilities → list buildable items.
**One-month:** Auto-detect a base's facilities via snapshot API; gap suggestions ("add facility X to unlock Y").
**Risks:** Facility typeID disambiguation (deployable vs onboard) must be handled (C).
**Kill test:** Reproduce buildable set for one facility combo.
**Shape:** Static SPA + optional API read.
**Score:** Use3 Fun2 Wknd4 Diff3 Cyc4 Syn4 WC2 Maint4 = **26/40**

---

### I-14 · Blueprint Dependency-Graph Explorer
**Pitch:** An interactive recipe-tree/graph visualizer for learning how anything is made.
**Value:** Teaching/onboarding aid; EF-Map renders *plans*, not the full dependency web (C).
**Uses:** Web-only; `blueprint_data_v5.json` (`blueprintIDs`, classifications) (C). No chain.
**Non-duplication:** Different UX (explore the web) vs the calculator (compute a plan).
**Weekend MVP:** Force-directed graph of one item's full dependency tree.
**One-month:** Search, classification filters, "rawest inputs" highlighting, embed.
**Risks:** Could be folded into EF-Map; deep trees need layout care.
**Kill test:** Render one deep item's graph from the JSON.
**Shape:** Static SPA (d3/three).
**Score:** Use3 Fun3 Wknd3 Diff3 Cyc3 Syn4 WC1 Maint4 = **24/40**

---

### I-15 · Market/ISK Cost Overlay for Builds
**Pitch:** Rank build plans by real cost using community price feeds — the economic axis EF-Map's calculator explicitly omits.
**Value:** Calculator ranks by material **volume, not ISK** (explicit gap, C).
**Uses:** Web-only; `blueprint_data_v5.json` + a price source. No chain.
**Non-duplication:** Adds an economic ranking layer the calculator lacks.
**Weekend MVP:** Map source materials → manual/seed prices → cost-ranked plans.
**Risks:** **No on-chain price oracle / trade history** (G); needs a community price feed that may not exist (data-dependency risk). Marketplace exists but its price data may not be public.
**Kill test:** Find a usable price source; if none, the idea is blocked.
**Shape:** SPA + price ingestion.
**Score:** Use4 Fun2 Wknd2 Diff4 Cyc3 Syn4 WC1 Maint2 = **22/40**

---

### I-16 · Jump-Permit Lifecycle Dashboard
**Pitch:** Track outstanding jump permits with live expiry countdowns and which extension issued them.
**Value:** New `JumpPermitIssuedEvent` (#140) carries `expires_at_timestamp_ms`/`extension_type` (A); nobody surfaces permit lifecycles.
**Uses:** world-contracts read (gate.move:138-149) (A). No wallet.
**Non-duplication:** EF-Map shows gates/links, not permits.
**Weekend MVP:** List issued permits + countdown.
**Risks:** Niche audience (gate-extension users); event emission/volume unverified; gates de-emphasized vs SSU this cycle.
**Kill test:** Confirm the event fires on live server.
**Shape:** Indexer + SPA.
**Score:** Use3 Fun2 Wknd3 Diff4 Cyc3 Syn3 WC4 Maint3 = **25/40**

---

### I-17 · In-Game Objective / Mission Markers (helper)
**Pitch:** Push "go to X, do Y" checklists into the in-game overlay that advance as you jump — for tutorials, hauling runs, tribe ops.
**Value:** New players need guided steps post-wipe (G); the overlay already auto-advances routes (D).
**Why fun/distinctive:** Native in-game guidance without alt-tabbing.
**Uses:** Helper (`hud_hints[]`/`highlighted_systems[]` schema fields, currently unused) + EF-Map web to author/push (D). No chain.
**Non-duplication:** The overlay does *routes*; objective checklists are a new use of existing schema.
**Weekend MVP (web-only):** Push hints to the existing schema and see if the renderer shows them.
**One-month:** Authoring UI in EF-Map; renderer polish (helper change → Store re-cert).
**Risks:** Nice rendering likely needs a C++ helper change + Microsoft Store re-certification (slow) (D); Windows-only.
**Kill test:** POST `hud_hints` to the helper and confirm display.
**Shape:** EF-Map web feature + optional overlay renderer update.
**Score:** Use4 Fun4 Wknd2 Diff4 Cyc4 Syn5 WC1 Maint2 = **26/40**

---

### I-18 · "Open in Game" Route/Context Handoff Button
**Pitch:** Any EF-Map share link or Discord-posted route gets an "open in overlay" button that pushes it straight to the in-game HUD.
**Value:** Removes alt-tabbing; makes shared routes feel native (D).
**Uses:** Helper deep-link `ef-overlay://overlay-state?...` (web-only against frozen contract) (D). No chain.
**Non-duplication:** Uses the existing protocol; not a new overlay.
**Weekend MVP:** Generate the deep-link URL from a route and wire a button.
**Risks:** Windows + helper installed; graceful no-op otherwise (use `/health` probe).
**Kill test:** Fire `ef-overlay://overlay-state` with a payload and confirm the HUD updates.
**Shape:** Web-only change consuming the documented protocol.
**Score:** Use4 Fun3 Wknd5 Diff3 Cyc3 Syn5 WC1 Maint4 = **28/40**

---

### I-19 · Session Recap / "Survivor Card" Generator
**Pitch:** Turn a player's log-parsed session (mined/refined/killed/fueled/jumps) into a shareable recap card.
**Value:** Helps the surge of new-player explainers/streamers this wiped cycle needs (G); the overlay already parses local logs + persists sessions (D).
**Why fun/distinctive:** "Crash Site Survivor — Day 1" cards; personal, shareable, meme-friendly.
**Uses:** Helper local session/telemetry JSON + a web card generator (D). No chain; local data stays local.
**Non-duplication:** EF-Map has *scouting* intel cards; a *personal session* recap is open (C, D).
**Weekend MVP:** Read `%LocalAppData%\EFOverlay\data` session JSON via the helper's `/session/*` GET; render a PNG card.
**One-month:** Templates, streamer overlay export, opt-in share gallery.
**Risks:** Windows/helper only; keep strictly local + opt-in (D privacy line).
**Kill test:** Generate a card from one real session file.
**Shape:** Web card generator over helper GETs.
**Score:** Use3 Fun4 Wknd3 Diff4 Cyc4 Syn4 WC1 Maint3 = **26/40**

---

### I-20 · "Am I Cooking?" Star-Heat Exposure Meter (speculative)
**Pitch:** A tongue-in-cheek thermal-exposure gauge for Cycle 6's signature new way to die (flying too close to a star).
**Value:** Star-heat is a verified, persistent new hazard (G); a "how cooked are you" gauge is both joke and safety tool.
**Why fun/distinctive:** Maximally memetic, tied to the cycle's defining mechanic.
**Uses:** Helper (would need heat/position from logs) + web — **speculative on data access**. No chain.
**Non-duplication:** Nothing covers heat.
**Weekend MVP:** Only if heat state is log-readable; else a static "heat rules" explainer.
**Risks:** **Speculative** — whether heat exposure is exposed to off-chain tools is unverified (G); may be impossible without memory reads (which are a hard no per D).
**Kill test:** Check whether game logs expose heat/proximity; if not, descope to an explainer.
**Shape:** Helper log parser + overlay gauge (if feasible).
**Score:** Use3 Fun5 Wknd2 Diff5 Cyc5 Syn3 WC1 Maint2 = **26/40**

---

### I-21 · SSU Dead Drop (conditional/anonymous pickup) — builder project
**Pitch:** Seal items into an SSU that only a party meeting a condition (secret, address, time) can withdraw — espionage-flavored escrow.
**Value:** A coordination primitive players lack (no escrow/atomic swap, F, G); strong "memorable demo" energy (Dead Drop was an archive favorite, F).
**Why fun/distinctive:** "The package was waiting. It always was."
**Uses:** world-contracts **write** — open-inventory custody (`deposit_to_open_inventory`/`withdraw_from_open_inventory`) + a witness-gated extension (A, F). Wallet required.
**Non-duplication:** Not the marketplace (no listings/price), not shared storage (conditional, not pooled).
**Weekend MVP:** N/A (contract project). Spike: prove open-inventory custody on localnet v0.0.24.
**One-month:** Move extension + minimal claim UI.
**Two-month:** Conditions (Poseidon secret, address, time), polish, audit.
**Risks:** Write/wallet adoption friction; revalidate open-inventory signatures/auth on v0.0.24; sponsorship.
**Kill test:** Confirm contract-controlled custody + conditional withdraw compiles/works on localnet.
**Shape:** Move extension + dapp-kit UI (reuse CivilizationControl PTB patterns, E).
**Score:** Use3 Fun5 Wknd1 Diff5 Cyc5 Syn1 WC5 Maint2 = **27/40**

---

### I-22 · VRF SSU Loot Dispenser — builder project
**Pitch:** Pay an entry fee, `sui::random` rolls a tier, the reward lands in your SSU's open inventory — "verifiably fair, dramatically unfair."
**Value:** Fun, demoable gambling/loot loop; remix of Fortune Gate + Loot Crate onto SSUs (F).
**Uses:** world-contracts **write** (`sui::random` `entry` fn + open-inventory deposit) (A, F). Wallet.
**Non-duplication:** Not a marketplace; a randomized dispenser.
**Weekend MVP:** N/A; spike `sui::random` + open-inventory deposit on localnet.
**One-month:** Extension + reveal UI.
**Risks:** Write/wallet; `sui::random` requires `entry` (F); economy/abuse design.
**Kill test:** Random roll → SSU deposit on localnet.
**Shape:** Move extension + UI.
**Score:** Use3 Fun5 Wknd1 Diff4 Cyc4 Syn1 WC5 Maint2 = **25/40**

---

### I-23 · Frontier Companion — public toolbox domain (umbrella)
**Pitch:** A domain-worthy landing site that ties EF-Map, the helper, the calculator, and these new micro-tools together with a coherent identity.
**Value:** Discoverability for the operator's ecosystem; a home for I-1/I-4/I-5/I-6 etc.; rewarded as a "domain-worthy public website."
**Uses:** Web-only; links + embeds (C). No chain.
**Non-duplication:** Not a dashboard restating EF-Map — a directory/launcher + the new tools.
**Weekend MVP:** A landing page + the first micro-tool (I-1) under it.
**One-month:** Add tools as they ship; shared design system.
**Risks:** Only as valuable as the tools it hosts; long-horizon framing.
**Kill test:** Ship the landing + one tool.
**Shape:** Static site (Astro/Vite).
**Score:** Use4 Fun3 Wknd3 Diff3 Cyc4 Syn5 WC1 Maint3 = **26/40**

---

### I-24 · Tribe-Ops "Push to All" Briefings (helper, opt-in)
**Pitch:** A tribe leader's EF-Map plan (route + objective markers) fans out to members who opted in, each rendered locally in their own overlay.
**Value:** Intel/plan sharing across a team is hard (F, G); the overlay can render pushed context per-pilot (D).
**Uses:** EF-Map web + helper WS/state path (web-only against frozen contract) (D). No chain.
**Non-duplication:** Not surveillance — pure fan-out of a plan members chose to receive (D privacy line).
**Weekend MVP:** Push a shared route to opted-in members' overlays.
**One-month:** Objective markers, channels, opt-in management.
**Risks:** Privacy (strictly opt-in, self-render); token/origin hardening (D).
**Kill test:** Push one plan to a second machine's overlay.
**Shape:** EF-Map web feature over existing bridge.
**Score:** Use3 Fun3 Wknd3 Diff4 Cyc3 Syn5 WC1 Maint3 = **25/40**

---

### I-25 · Gate-Status Contribution Dashboard / Leaderboard
**Pitch:** A public board of Cycle 6 stargate-status reporting coverage — % of edges reported, freshest/stalest corridors, top reporters.
**Value:** EF-Map collects reports but has no **public** coverage view (moderator-only admin) (C); encourages contribution.
**Uses:** EF-Map `/api/stargate-status` + `stargate_edges_cycle6.json` (C). No wallet.
**Non-duplication:** Complements EF-Map's in-app reporting with a public health/leaderboard surface.
**Weekend MVP:** Coverage % + stale-corridor list.
**Risks:** API access; report data quality.
**Kill test:** Compute coverage from the two sources.
**Shape:** Worker + SPA.
**Score:** Use3 Fun3 Wknd3 Diff3 Cyc4 Syn5 WC1 Maint3 = **25/40**

---

### I-26 · "Resolve Any Structure by ItemID" Inspector
**Pitch:** Paste an in-game ItemID + pick a server → see the structure's owner, status, location, metadata.
**Value:** Players see ItemIDs in-game but can't easily inspect a structure's on-chain state; a fast lookup utility.
**Uses:** `derive-object-id.ts` (compute Sui object ID off-chain) + GraphQL `getAssemblyWithOwner`/`getObjectWithJson` (B). No wallet.
**Non-duplication:** EF-Map's SSU/assembly browser is map-oriented; this is a direct ItemID→object inspector.
**Weekend MVP:** ItemID + tenant → derived object ID → fetch + display.
**Risks:** Needs registry IDs per server (public, in docs, B); overlaps EF-Map intel search somewhat.
**Kill test:** Resolve one known ItemID end-to-end.
**Shape:** Static SPA + GraphQL/RPC.
**Score:** Use3 Fun2 Wknd5 Diff3 Cyc3 Syn2 WC3 Maint4 = **25/40**

---

## Card index by score
35 I-1 · 33 I-2 · 30 I-3 · 30 I-4 · 30 I-5 · 29 I-6 · 29 I-9 · 28 I-7 · 28 I-8 · 28 I-10 · 28 I-18 ·
27 I-12 · 27 I-21 · 26 I-11 · 26 I-13 · 26 I-17 · 26 I-19 · 26 I-20 · 26 I-23 · 25 I-16 · 25 I-22 ·
25 I-24 · 25 I-25 · 25 I-26 · 24 I-14 · 22 I-15

See [`ranked-shortlist.md`](ranked-shortlist.md) for bucketed Top-5 lists and the recommended next build.
