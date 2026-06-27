# EVE Frontier Context — June 2026

**Status:** Active — current workspace doc (operator context snapshot, June 2026)
**Audience:** Agents planning new EVE Frontier work in this repo

This doc captures **operator-provided assumptions** about the current EVE Frontier development
cycle, as of June 2026. It exists so an agent starting fresh has a realistic picture of the
landscape before proposing or building anything.

> ⚠️ **These are operator assumptions captured June 2026 — revalidate before relying.**
> Verify every claim below against the **current** `vendor/world-contracts`, the latest
> `vendor/builder-documentation`, and official sources (`docs.evefrontier.com`, EVE Frontier
> community channels) before making any build decision. Cycles move; this snapshot will age.

---

## Operator assumptions (June 2026)

Treat each of these as *"operator context, June 2026; revalidate before relying."*

1. **EF-Map is already up to date elsewhere.** No EF-Map refresh work is needed from this repo.
2. **`world-contracts` are expected to stay mostly stable for ~the next three months** (i.e.,
   through roughly Q3 2026). Do not assume large breaking changes are imminent — but confirm by
   auditing the current submodule (see the [latest refresh note](operations/submodule-refresh-2026-06.md)).
3. **Limited scope this cycle for industry-management-style features.** Heavy industry/production
   management is probably not the most fertile ground right now.
4. **SSUs (Smart Storage Units) may be the main interesting surface.** This is where the operator
   sees the most open opportunity.
5. **Shared tribe storage for SSUs already exists** (built by someone else). **Do not duplicate it.**
6. **A marketplace already exists** (built by someone else). **Do not duplicate it** unless there is
   a *materially different* angle that clearly differentiates from the existing one.

### Implications for new work

- Favor **SSU-adjacent** ideas that are *not* shared-tribe-storage and *not* a generic marketplace.
- Look for gaps: novel SSU access policies, automation, inter-SSU flows, logistics/escrow,
  reputation, or player-experience layers — but only after confirming they are not already covered
  by the existing shared-storage and marketplace projects.
- Because `world-contracts` is expected to be stable near-term, designs validated now have a
  reasonable shelf life — but still pin to a specific commit and revalidate at build time.

---

## What changed upstream recently

The most recent vendor refresh + audit is recorded in
[`operations/submodule-refresh-2026-06.md`](operations/submodule-refresh-2026-06.md). Read it for
the concrete `world-contracts` delta (notably the breaking `inventory_key` discriminator on item
deposit/withdraw events, gate jump-permit improvements, and the Rift location-reveal feature) and
its impact on prior assumptions. **The audit supersedes the historical archive wherever they
disagree.**

---

## Next task pointer: weekend-project ideation

When the operator is ready, a future agent will use this context plus the vendor submodules and the
historical archive to propose a fun weekend EVE Frontier build. The full brief is at
[`future-research-briefs/weekend-project-ideation.md`](future-research-briefs/weekend-project-ideation.md).
That task is **not** to be performed as part of capturing this context.
