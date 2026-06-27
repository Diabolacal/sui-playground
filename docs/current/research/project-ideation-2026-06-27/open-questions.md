# Open Questions — for the operator to answer after reading

**Status:** Active research artifact. These determine which idea(s) to commit to and de-risk the top picks.

## Direction / scope
1. **Which horizon do you want next** — a ship-this-weekend public tool (lean I-1 Frontier Changelog),
   or a 1–2 month flagship (lean I-3 SSU Inventory Intelligence or, if its kill test passes, I-2 Rift Watch)?
2. **Standalone vs umbrella:** do you want the next tool to live under a new **Frontier Companion**
   domain (I-23) that future tools join, or as a one-off?
3. **How tightly coupled to EF-Map** are you comfortable being? Several top ideas consume EF-Map's
   public data/embed contract. That's synergy (your own ecosystem) but creates a versioning link.
4. **Build vs fold-in:** for the EF-Map-gap ideas (changelog, blueprint permalink, dormant-gate
   routing), would you rather ship them **into EF-Map** directly, or as separate companion tools?

## Evidence to confirm before building (kill tests)
5. **Rift events (I-2):** does the **live** Stillness server emit `RiftLocationBroadcastEvent` with
   parseable coords, often enough to be interesting? (1-hour `suix_queryEvents` test.)
6. **SSU events (I-3, I-9):** do `ItemDepositedEventV2`/`ItemWithdrawnEventV2` fire on the live server,
   and does owned-SSU discovery via `PlayerProfile`+OwnerCaps work on v0.0.24?
7. **Blueprint dataset (I-1, I-4):** is the prior `blueprint_data_v4.json` still retrievable (CDN or
   repo) so a v4→v5 diff is possible, and are the two versions structurally diffable?
8. **Star-heat data (I-20):** is heat/proximity exposed in the player's local game logs (helper-readable)
   — or is "Am I Cooking?" only feasible as a static explainer?

## Community / product validation (the biggest evidence gap)
9. **Sentiment:** the web scan could **not** reach Discord/Reddit/forums. Can you sanity-check the
   assumed pain points (Cycle 6 relearning, cross-SSU "where's my stuff", fuel-runway anxiety) against
   the actual community before we commit?
10. **Existing-tool overlap:** are any of the "open" gaps already being worked on by EFCopilot/DaOpa/EFTB
    or community devs you know of (esp. a blueprint differ or rift feed)?
11. **Marketplace & shared-storage specifics:** what exactly do the existing marketplace and
    shared-tribe-storage projects cover, so the SSU ideas (I-3/I-9) stay clearly *beside* them?

## Operating constraints
12. **Hosting/stack preference:** Cloudflare (Pages/Workers/KV) is the natural fit given EF-Map +
    CivilizationControl already use it — confirm, or state a preferred stack.
13. **Maintenance appetite:** indexer-backed ideas (I-2/I-3/I-9) need a running service; static ones
    (I-1/I-4/I-5/I-6) are near-zero maintenance. How much ongoing upkeep are you willing to carry?
14. **Wallet/contract appetite:** are you open to a *builder* (Move-extension + wallet) project this
    cycle (I-21/I-22), or do you want to stay read-only/no-wallet for maximum adoption?

## Recommended immediate next step
Run the **2-hour I-1 spike** (diff `blueprint_data_v4`→`v5`) and the **1-hour I-2 rift kill test** in
parallel. Those two cheap checks decide whether the safe pick (I-1) or the high-upside pick (I-2) leads.
