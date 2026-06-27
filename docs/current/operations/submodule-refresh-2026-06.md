# Submodule Refresh + Upstream-Delta Audit — 2026-06-27

**Status:** Active — current workspace doc (dated refresh note)
**Procedure:** [`../../operations/submodule-refresh-prompt.md`](../../operations/submodule-refresh-prompt.md)

All five `vendor/*` submodules were synced and refreshed to their upstream `main` HEAD on
2026-06-27. Four advanced; one was already at HEAD. Only parent-repo **gitlinks** changed — no
tracked file inside any submodule was modified, and no commits were created inside `vendor/*`.

> **Headline:** `world-contracts` advanced **v0.0.18 → v0.0.24** with one **breaking** change
> (`feat!` #155: `inventory_key` discriminator on item deposit/withdraw events) plus additive gate
> jump-permit improvements and a new Rift location-reveal module. Revalidate SSU/TradePost/inventory
> and gate/jump-permit assumptions in the historical archive before reuse.

## Summary table

| Submodule | Old SHA | New SHA | Upstream branch | Commits | Impact |
|---|---|---|---|---:|---|
| world-contracts | `8eb197e` (v0.0.18) | `d1929fa` (v0.0.24) | main | 12 | **High** |
| evevault | `a667394` (v0.0.5) | `aad5d10` (v0.0.12) | main | 62 | Medium |
| builder-scaffold | `a4fb8b0` | `ebc321a` (v0.0.2) | main | 3 | Medium |
| builder-documentation | `cf0f3ab` | `b4b943e` | main | 47 | Low–Medium |
| eve-frontier-proximity-zk-poc | `4078e70` | `4078e70` | main | 0 | None (already HEAD) |

Verification: `git status --short vendor` showed only gitlink (` M`) changes;
`git diff --submodule=log -- vendor/` confirmed the commit ranges above.

---

### world-contracts — `8eb197e` (v0.0.18) → `d1929fa` (v0.0.24) — **HIGH**

12 commits, +2889/−409 across 53 files. Edition `2024.beta`. Package name `world`.

**Notable changes (evidence-based):**

- **`feat!: add inventory_key discriminator to item deposit/withdraw events (#155)` — BREAKING.**
  Commit `92c0b46` adds `ItemDepositedEventV2` and `ItemWithdrawnEventV2` in
  `contracts/world/sources/primitives/inventory.move`, each with a new `inventory_key: ID` field
  identifying the specific dynamic-field slot written to. **All 7 emit sites in
  `storage_unit.move` now emit the V2 events** instead of the originals. Any indexer / read-path
  that subscribed to `ItemDepositedEvent` / `ItemWithdrawnEvent` will **miss deposits and
  withdrawals** until updated to the `…V2` types.
- **`feat(gate): jump permit improvements (#140)`** (commit `d63d40c`, gate.move +132). Adds an
  **emitted event** on permit issuance and an **additive return-value entry point** for
  `issue_jump_permit`, while keeping the original `issue_jump_permit` signature upgrade-safe (not a
  breaking change). Example extensions updated: `corpse_gate_bounty.move`, `tribe_permit.move`.
  New `ts-scripts/builder_extension/delete-jump-permit.ts` + `delete-jump-permit-extension.ts`.
- **`feat: reveal Rift location onchain when players begin mining (#166)`** (commit `fe5cd77`).
  New module `contracts/world/sources/rift/rift.move` (+140) with tests (+237). New gameplay-server
  surface for revealing a Rift's location on mining start.
- **`feat: qol functions (#137)`** (commit `0642c7b`) — additive quality-of-life helpers.
- **`feat: upgraded stillness package (#147)`** + `build: add upgraded package ids (#141)` +
  `chore: update Published.toml / Move.lock for testnet_stillness (#189)` — new published package
  IDs / upgrade plumbing for the stillness deployment.
- Additive touches across `turret.move` (+68), `killmail.move` (+51), `storage_unit.move` (+41),
  `metadata.move` (+28), `location.move` (+27), `access_control.move` (+11), plus substantial new
  tests (gate +292, rift +237, storage_unit +128, inventory +108, turret +82).

**Impact level: High** — one breaking event-shape change on the SSU/inventory hot path, plus a new
jump-permit event/return-value surface that prior gate docs predate.

**Impact on this workspace (historical assumptions to revalidate):**

- **SSU / TradePost / inventory (`docs/architecture/tradepost-*`, `docs/validation/ssu-extension-e2e-validation.md`,
  `docs/research/world-contracts-event-inventory.md`, `…-event-surface.md`):** the deposit/withdraw
  **event types changed** (`…V2` + `inventory_key`). Read-path/indexer designs and the event
  inventories that reference `ItemDepositedEvent`/`ItemWithdrawnEvent` are stale for v0.0.24.
  The `withdraw_item`/`deposit_item`/`deposit_to_owned` **function** signatures (the v0.0.15
  change documented in `.github/instructions/typescript-react.instructions.md`) appear unchanged by
  #155 — only the emitted events changed — but verify against source before relying.
- **GateControl / ZK GatePass / Cargo Bond (jump permits):** the original `issue_jump_permit`
  signature is preserved, so prior PTB shapes should still compile, **but** there is now a
  preferred event + return-value entry point. Gate/permit docs
  (`docs/architecture/gate-lifecycle-*`, `gate-turret-courier-access-feasibility.md`,
  `docs/operations/zk-gatepass-feasibility-report.md`) should note the additive surface.
- **CivilizationControl / TradePost / GateControl / Fortune Gauntlet / Shadow Broker:** no signature
  removals observed that would break their documented PTBs; the main revalidation item is the
  inventory **event** change for anything that observes SSU deposits/withdrawals.
- **Turret / killmail / metadata:** additive changes only (no removed functions observed in the
  stat); the turret closed-world constraint docs remain plausible but should be re-checked against
  the +68 turret delta.

---

### evevault — `a667394` (v0.0.5) → `aad5d10` (v0.0.12) — **MEDIUM**

62 commits. Wallet extension; tags advanced v0.0.5 → v0.0.12.

**Notable changes (from upstream commit log):**

- **`wallet-core` extraction** (`#110` implement wallet-core, `#118`/`#130` move functions to import
  from wallet-core, `#132` bump wallet-core to 0.0.4). Wallet logic is being factored into a shared
  `wallet-core` package — integration import paths likely changed.
- **`feat: migrate OAuth to PKCE, remove client secrets (#113)`** — OAuth now uses PKCE; client
  secrets removed. Affects any documented zkLogin/OAuth integration assumptions.
- **Security fixes:** `#127`/`#129` (keeper sender guard, gated logger, OAuth state), `#64` (patch
  four vault security vulnerabilities), zkLogin personal-message signature verification fix.
- **Localnet support:** encrypt localnet key (#97), approve localnet dapp txns (#100), migrate
  network/tenant state to context (#101), wallet hook layer + backend plumbing (#93/#94).
- **zkLogin robustness:** rotate ephemeral key on zkproof expiry (#88), refresh expiry from OIDC
  session (#78), nonce-for-zklogin on first login (#84), sponsored tx for utopia UAT (#63).

**Impact level: Medium** — the Sui Wallet Standard surface appears intact, but wallet integration
internals (wallet-core package, PKCE OAuth, localnet flows) changed materially. Any historical
EveVault integration notes should be re-derived from current source before reuse.

---

### builder-scaffold — `a4fb8b0` → `ebc321a` (v0.0.2) — **MEDIUM**

3 commits.

- **`feat: refactor to sync builder-scaffold to world-contracts v0.0.18 (#53)`** — templates aligned
  to the v0.0.18 world (note: world-contracts is now v0.0.24, so the scaffold trails by a few releases).
- **`feat: update move.toml to work against existing world (#54)`** — Move templates now build
  against an existing world deployment.
- **`update zklogin cli to sui v2 (#49)`** — the zkLogin CLI was updated for the Sui v2 SDK line.

**Impact level: Medium** — the devnet/zkLogin tooling and Move templates moved; the earlier
`smart_gate` → `smart_gate_extension` / `storage_unit` → `storage_unit_extension` rename remains the
canonical layout. Re-pull templates before scaffolding a new package.

---

### builder-documentation — `cf0f3ab` → `b4b943e` — **LOW–MEDIUM**

47 commits (mostly doc edits / PR merges).

- **Multitenancy:** "update evevault docs to include multitenancy (#64)".
- **World upgrade details:** `world-upgrade-details` branch merged — guidance on world package upgrades.
- **Wallets & identity:** "Update wallets-and-identity.md (#66)".
- **Sandbox access:** several `sandbox-access.md` updates (#58/#59).
- **MVR:** `feat/mvr` merged (#68); **dapp builder docs** additions (#55); one unused page removed (#67).

**Impact level: Low–Medium** — no contract behavior here, but the multitenancy, world-upgrade,
sandbox-access, and wallets-and-identity pages are the most useful for current SSU/wallet/deployment
context. Re-read these pages directly for any new build.

---

### eve-frontier-proximity-zk-poc — `4078e70` (unchanged) — **NONE**

Already at upstream HEAD; no new commits. Remains a **reference-only** Groth16 proximity PoC. No
feasibility drift for location/proximity-proof ideas from this submodule. (Note: world-contracts
#166 adds an *on-chain Rift location reveal* — a separate, unrelated location surface.)

---

## Follow-ups / docs needing annotation

- **High:** Re-run SSU/inventory validation (`docs/validation/ssu-extension-e2e-validation.md`) and
  update the event inventories (`docs/research/world-contracts-event-inventory.md`,
  `…-event-surface.md`, `docs/architecture/world-contracts-event-layer-audit.md`) for the
  `ItemDeposited/WithdrawnEventV2` + `inventory_key` change.
- **Medium:** Annotate gate/jump-permit docs with the additive #140 event + return-value entry point.
- **Medium:** Re-derive any EveVault integration notes against the `wallet-core` + PKCE OAuth refactor.
- **Low:** Note that `builder-scaffold` templates trail world-contracts (synced to v0.0.18, world now v0.0.24).
- These annotations are **not** all applied inline to every historical doc — the historical cluster is
  governed by the [archive index](../../archive/hackathon-2026/README.md) and the
  [authority hierarchy](../README.md#authority-hierarchy-source-of-truth), which already direct agents
  to revalidate against current `vendor/world-contracts`. The highest-signal stale claim (the
  inventory event change) is called out here and in the affected instruction files.
