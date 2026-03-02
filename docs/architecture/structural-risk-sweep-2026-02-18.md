# CivilizationControl — Structural Risk Sweep

**Retention:** Carry-forward

> **Date:** 2026-02-18 (revised 2026-02-18 — sponsor risk reclassification)
> **Type:** Adversarial pre-mortem. Six parallel audit tracks. Evidence-based.
> **Scope:** All on-chain, off-chain, UX, wallet, in-game integration, and operational surfaces
> **Method:** Phase 0 (system map) → Phase 1 (6 parallel subagent audits) → Phase 2 (synthesis) → Phase 3 (this report)
> **Revision:** AdminACL sponsor risk downgraded from CRITICAL to HIGH (environment-dependent). Probability model added. Pre-March escalation replaced with Day-1 validation protocol. See §6 Addendum.

---

## 1. Executive Summary (5 Bullets)

1. **~~REVISED~~ Sponsored transaction access on the hackathon test server is environment-dependent, not a confirmed blocker.** `jump_with_permit()` requires `AdminACL.verify_sponsor(ctx)`. The high-probability scenario (~65%) is that the test server auto-sponsors builder transactions through CCP infrastructure — matching the Stillness production model. Validate Day 1, minute 1. Worst-case fallback (Stillness deployment window April 1–14) exists. Reclassified from CRITICAL to **HIGH (environment-dependent)**. See §6 Addendum.
2. **Partial-quantity withdrawal is impossible** in current world-contracts. `withdraw_item<Auth>()` returns the entire `Item` stack for a `type_id`. No `split_item` exists. TradePost listings must sell full stacks or the extension must implement withdraw→split→redeposit logic using `deposit_item<Auth>`.
3. **EVE Vault's sponsored transaction feature is a hardcoded stub** returning mock data ("0x1234567890"). The `evefrontier:sponsoredTransaction` method depends on an unimplemented "quasar" backend. Jump operations must use `signTransaction` + manual server co-sign, or CLI fallback.

> **Update 2026-02-28:** EVE Vault sponsored transactions are now functional (commit 687d432). Sign-and-execute works via `window.postMessage` relay. API URL changed to `/${assemblyType}/${action}` format. Default chain switched to testnet. Risk #3 below is superseded.

4. **Extension Move code is the prerequisite for 3 of 5 non-negotiable demo proof moments** (Beats 5, 6, 7). `TollCollectedEvent` and `TradeSettledEvent` don't exist anywhere — they must be emitted by custom extension code that hasn't been written yet. No fallback exists.
5. **~~The multi-entry portfolio strategy ($15–17k expected value) rests on an unconfirmed assumption.~~** ✅ **RESOLVED (2026-03-02):** Deep Surge FAQ confirms multiple submissions are allowed; each project must be unique. Portfolio strategy validated.

---

## 2. System Dependency Graph

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        HACKATHON TEST SERVER                           │
│  ┌──────────────────────┐  ┌─────────────────────────────────────┐     │
│  │ world-contracts pkg   │  │ AdminACL (shared obj)               │     │
│  │ (pre-published by CCP)│  │  authorized_sponsors: Table<addr>  │     │
│  │ GovernorCap: CCP-held │  │  [REQUIRES GovernorCap to modify]  │     │
│  └──────┬───────────────┘  └──────────────┬──────────────────────┘     │
│         │                                  │                            │
│         ▼                                  ▼                            │
│  ┌─────────────────────┐  ┌──────────────────────────────────────┐     │
│  │ GateControl ext pkg  │  │ jump_with_permit() ← verify_sponsor │     │
│  │ (builder-deployed)   │  │ deposit_fuel()     ← verify_sponsor │     │
│  │ - GateAuth witness   │  │ online()           ← NO sponsor     │     │
│  │ - TribeRule (DF)     │  │ authorize_ext()    ← NO sponsor     │     │
│  │ - TollRule (DF)      │  │ withdraw_item<A>() ← NO sponsor  ✓  │     │
│  │ - TollCollectedEvent │  │ deposit_item<A>()  ← NO sponsor  ✓  │     │
│  └──────┬───────────────┘  └──────────────────────────────────────┘     │
│         │                                                               │
│         ▼                                                               │
│  ┌─────────────────────┐  ┌──────────────────────────────────────┐     │
│  │ TradePost ext pkg    │  │ Listing (shared obj / DF on config) │     │
│  │ (builder-deployed)   │  │ - seller, ssu_id, type_id, price   │     │
│  │ - TradeAuth witness  │  │ - is_active: bool                   │     │
│  │ - buy() function     │  │ TradeSettledEvent (custom emission) │     │
│  │ - list() function    │  └──────────────────────────────────────┘     │
│  └──────────────────────┘                                               │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                        BROWSER / UI LAYER                              │
│  ┌─────────────────────┐  ┌──────────────────────────────────────┐     │
│  │ EVE Vault (zkLogin)  │  │ @mysten/dapp-kit                    │     │
│  │ - sui:devnet + testnet│ │ - useWallets(), useSignTx()         │     │
│  │ - NO localnet chain  │  │ - signAndExecuteTransaction()       │     │
│  │ - sponsoredTx: STUB  │  │ - Transaction builder (PTB)         │     │
│  └──────┬───────────────┘  └──────────────┬──────────────────────┘     │
│         │                                  │                            │
│         ▼                                  ▼                            │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │ CivilizationControl Dashboard (React + TypeScript)          │      │
│  │  ┌───────────────┐  ┌────────────────┐  ┌──────────────┐   │      │
│  │  │ Command        │  │ Signal Feed    │  │ Gate Detail   │  │      │
│  │  │ Overview       │  │ (10s polling)  │  │ Policy Panel  │  │      │
│  │  └───────┬───────┘  └───────┬────────┘  └──────┬───────┘  │      │
│  │          │                   │                   │          │      │
│  │          ▼                   ▼                   ▼          │      │
│  │  suix_getOwnedObjects  suix_queryEvents   signTransaction  │      │
│  │  sui_multiGetObjects   (MoveEventType)    (write ops)      │      │
│  └──────────────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────────────┘

DATA FLOW:
  Wallet → Character ID (OFF-CHAIN resolution) → OwnerCaps (RPC) → Structure IDs → Object state
  Write: UI → PTB construction → wallet sign → RPC execute → event emission → poll → Signal Feed
  Revenue: TollCollectedEvent + TradeSettledEvent → client-side sum → Command Overview metric
```

### Interface Boundaries (Where Assumptions Hide)

| Interface | Components | Key Assumption | Status |
|-----------|-----------|----------------|--------|
| **I1** | Extension → `jump_with_permit` | Sponsor in AdminACL | **UNVALIDATED on test server** |
| **I2** | Wallet → Character ID | Off-chain resolution works | **UNVALIDATED** (manual fallback designed) |
| **I3** | Extension event → Signal Feed | Custom events queryable by package ID | **PROVEN** (standard Sui feature) |
| **I4** | `withdraw_item<Auth>` → `buy()` | Full-stack withdrawal acceptable | **DESIGN CONSTRAINT** (no partial withdraw) |
| **I5** | EVE Vault → PTB signing | Wallet connects to test server chain | **UNVALIDATED** (only devnet+testnet chains listed) |
| **I6** | Distance proof → `link_gates` | Self-signed proofs work on test server | **UNVALIDATED** (only proven on local devnet) |
| **I7** | SSU dApp URL → in-game browser | `Metadata.url` loads iframe | **UNDOCUMENTED** (all dApp pages //TODO) |

---

## 3. Top 5 Risks Ranked

| # | Risk | Severity | Evidence | Why It Matters | Mitigation |
|---|------|----------|----------|---------------|------------|
| **1** | **AdminACL sponsor access on test server** — `jump_with_permit()` requires tx sponsor in AdminACL; access model depends on test server environment configuration | **HIGH** *(revised from CRITICAL — see §6)* | [gate.move](vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — `jump` and `jump_with_permit` both call `verify_sponsor`. [access_control.move](vendor/world-contracts/contracts/world/sources/access/access_control.move) — `add_sponsor_to_acl` requires GovernorCap. High probability (~65%) that test server auto-sponsors like Stillness. | GateControl demo Beats 3–5 depend on sponsored jump execution. If Branch A (auto-sponsor) holds, this is a non-issue. If Branch C (no access), fallback to Stillness deployment window (April 1–14) or local devnet. Expected cost: ~15 min Day-1 validation. | **Day 1 (minute 1):** Execute 60-min Sponsor Validation Protocol (§6). **Fallback chain:** Test server auto-sponsor → Stillness silent deploy → local devnet demo capture. No pre-March organizer escalation needed — validate empirically. |
| **2** | **Partial-quantity withdrawal impossible** — `withdraw_item<Auth>()` returns full Item stack; no `split_item` or `partial_withdraw` exists | **HIGH** | [inventory.move L269–L290](vendor/world-contracts/contracts/world/sources/primitives/inventory.move#L269-L290) — `withdraw_item` removes entire entry from VecMap. `burn_items` (L328–L370) supports partial quantity but destroys the item (chain→game bridge), doesn't return it. `Item` creation is `public(package)` only (L101–L113) — extensions cannot mint Items. | TradePost listings CANNOT sell partial quantities. If an SSU has 100 ammo under type_id=5, a buyer who wants 10 gets all 100. This breaks the marketplace UX for stackable items. The "buy 1 fuel rod" demo moment requires either single-quantity Items or the extension to implement withdraw→manual-quantity-adjustment→redeposit (which is impossible because `Item` fields are not publicly mutable and creation is `public(package)`). | **MVP:** Design listings around full-stack sales only. Stock SSU with pre-split single-quantity items (1 fuel rod per type_id slot, using different `item_id`s). **Limitation:** Each SSU inventory is a `VecMap<u64, Item>` keyed by `type_id` — multiple items of the same `type_id` merge. Separate `item_id` values with different `type_id` values are needed. Confirm `type_id` uniqueness constraints on test server. **Post-hack:** Propose `split_item` function to world-contracts maintainers. |
| **3** | **EVE Vault sponsored tx is a stub** — `evefrontier:sponsoredTransaction` returns hardcoded mock data | **HIGH** | [vendor/evevault](vendor/evevault) source — `sponsoredTransaction` implementation depends on unbuilt "quasar" backend service | For any operation requiring `verify_sponsor` (jumps, fuel), the EVE Vault wallet cannot construct proper sponsored transactions. Must use `signTransaction` + server-side co-signing, or fall back to Sui CLI for demo capture. | **Day 1:** Test EVE Vault `signTransaction` (unsigned tx export) on test server. If it works, build a minimal Node.js co-signer script that adds the sponsor signature. **Demo fallback:** Use Sui CLI for sponsored operations (`sui client ptb --gas-sponsor`) and EVE Vault only for non-sponsored operations (TradePost buy, extension deploy). |
| **4** | **Character resolution has no validated path** — Character is a shared object; no on-chain wallet→Character mapping exists | **HIGH** | [authenticated-user-surface-analysis.md §1.3](docs/architecture/authenticated-user-surface-analysis.md#L87-L118) — "Critical gap at Step 1." [read-path-architecture-validation.md §1.1](docs/architecture/read-path-architecture-validation.md#L24-L60) — 4 resolution options, Option D (manual paste) is the only guaranteed fallback | Without Character ID, the dashboard cannot enumerate OwnerCaps → cannot show structures → Command Overview is empty. Manual paste is poor UX for demo. Event indexing (`CharacterCreatedEvent`) is the best automated option but depends on test server RPC supporting historical event queries. | **Day 1 (first 30 min):** Run `suix_queryEvents({ MoveEventType: "...::character::CharacterCreatedEvent" })` on test server. If it returns results, build event-based resolver. If not, implement manual Character ID input with a clear UX prompt. **Demo:** Pre-resolve Character ID before recording; paste is invisible to viewer. |
| **5** | **~~Multi-entry portfolio strategy unconfirmed~~** | ~~**MEDIUM**~~ ✅ **RESOLVED** | [hackathon-event-rules-digest.md](docs/research/hackathon-event-rules-digest.md) — Deep Surge FAQ confirms multiple submissions allowed (2026-03-02) | ~~If multi-entry is prohibited, the entire portfolio strategy (Track A–D) collapses to a single entry.~~ Multi-entry confirmed. Portfolio strategy proceeds as planned. | N/A — resolved. |

> **Update 2026-02-28:** Risk #3 (EVE Vault sponsored tx stub) is superseded — sign-and-execute now functional via `window.postMessage` relay (commit 687d432). API URL changed to `/${assemblyType}/${action}` with `X-Tenant` header.

---

## 4. The #1 Blind Spot (Deep Dive)

### What It Is

**AdminACL sponsor access on the hackathon test server is unvalidated but likely auto-provisioned.**

> **Revision note (2026-02-18):** Original analysis modeled the test server as "raw chain + builder" — a worst-case framing that ignored the high probability that CCP operates the test server identically to Stillness (managed game infrastructure with server-side sponsorship). The risk remains real but the probability distribution favors auto-sponsorship. See §6 for the full probability model.

The CivilizationControl demo's core narrative — "Control → Consequence → Revenue" — depends on executing `jump_with_permit()` to show gate policy enforcement. This function calls `admin_acl.verify_sponsor(ctx)`, which asserts that the transaction's gas sponsor address is present in `AdminACL.authorized_sponsors`. Adding an address to this table requires `GovernorCap`, which is a singleton created at world-contracts package publication time and held by the deployer (CCP/organizers).

On local devnet, this was invisible: the builder publishes the world package, receives GovernorCap, and self-administers everything. On the hackathon test server, the world package is pre-published by CCP. The builder does NOT hold GovernorCap.

### Why We Missed It

Three factors created the blind spot:

1. **Local devnet masking:** All 17 sandbox transaction digests used a self-administered devnet where the builder held GovernorCap. The sponsorship setup (Pattern 7 in the reimplementation checklist) was rehearsed successfully — but only because GovernorCap was available. The checklist even notes "On the hackathon test server, AdminACL access depends on organizer configuration — verify early" but treats it as a verification step, not a potential blocker.

2. **Asymmetric impact between modules:** TradePost's `withdraw_item<Auth>()` and `deposit_item<Auth>()` do NOT call `verify_sponsor()`. Only world-contracts core operations (jumps, fuel, item bridging) require sponsorship. This means TradePost works regardless — but GateControl's jump demonstration does not. The validation effort disproportionately validated the sponsor-free path (TradePost) while treating the sponsored path (GateControl jumps) as "proven on devnet."

3. **Documentation treated sponsorship as gas abstraction, not access control.** Every document discusses sponsorship in terms of "gas should be abstracted from the player experience" — framing it as a UX concern. But `verify_sponsor` is actually an **access control enforcement** — it's the game's way of ensuring only authorized game clients can trigger gameplay operations. On Stillness, the game server is the sponsor. On the test server, the question is: who sponsors builder-triggered operations?

### Evidence

| Source | Location | What It Says |
|--------|----------|-------------|
| `gate.move` jump_with_permit | [gate.move L279](vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | `admin_acl.verify_sponsor(ctx);` — called before ANY jump |
| `access_control.move` verify_sponsor | [access_control.move L158–L162](vendor/world-contracts/contracts/world/sources/access/access_control.move) | `assert!(option::is_some(&sponsor), ENoSponsor); assert!(table::contains(&admin_acl.authorized_sponsors, *option::borrow(&sponsor)), EUnauthorizedSponsor);` |
| `access_control.move` add_sponsor | [access_control.move L200–L205](vendor/world-contracts/contracts/world/sources/access/access_control.move) | `add_sponsor_to_acl(admin_acl, governor_cap, sponsor_addr)` — requires `&GovernorCap` |
| Reimplementation checklist E5–E7 | [march-11-reimplementation-checklist.md L118–L120](docs/core/march-11-reimplementation-checklist.md) | E5: "Hackathon test server available from March 11 with same world-contracts as Stillness" E6: "Test server provides admin-spawnable structures and unlimited currency" E7: "Test server world-contracts package IDs are discoverable" — all marked "verify" with no fallback |
| Pattern 7 note | [march-11-reimplementation-checklist.md L358](docs/core/march-11-reimplementation-checklist.md) | "On the hackathon test server, AdminACL access depends on organizer configuration — verify early." |
| Strategic next-move audit | [strategic-next-move-audit-2026-02-18.md L56](docs/strategy/strategic-next-move-audit-2026-02-18.md) | Lists "Character resolution on hackathon test server" as RED blocker but does NOT list AdminACL sponsor access as a separate risk |
| `deposit_item<Auth>` / `withdraw_item<Auth>` | [storage_unit.move L174–L225](vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L174-L225) | NO `verify_sponsor` call — TradePost is sponsor-free |

### Failure Mode (What Breaks in Demo / In-World)

**If the builder cannot add a sponsor address to AdminACL on the test server:**

| Demo Beat | Depends On | Status | Impact |
|-----------|-----------|--------|--------|
| Beat 3: Deploy Policy | `authorize_extension` (no sponsor needed) | ✅ Works | Policy deploys fine |
| Beat 4: Hostile Denied | `jump_with_permit` → `verify_sponsor` | ❌ **BLOCKED** | Cannot demonstrate denial — the jump tx fails at `verify_sponsor` before reaching extension code, not at tribe filter |
| Beat 5: Ally Tolled | `jump_with_permit` → `verify_sponsor` | ❌ **BLOCKED** | Cannot demonstrate toll collection — same failure point |
| Beat 6: Trade Buy | `withdraw_item<Auth>` (no sponsor needed) | ✅ Works | Trade works independently |
| Beat 7: Revenue Summary | Aggregation of toll + trade events | ⚠️ **DEGRADED** | Only trade revenue visible; toll revenue = 0 |

**The "Control → Consequence → Revenue" narrative spine breaks at "Consequence."** The operator can set policy (Control) and collect trade revenue (Revenue), but the policy consequences (denial, tolling) are undemonstrable. This undermines the emotional pivot point of the demo — "the chain enforced your rule" — which is the single most distinctive claim of CivilizationControl.

The fallback demo variant (GateControl-only, 2 minutes) is **even more affected** since it has no TradePost to fall back on.

### Minimal MVP Mitigation (Revised)

> **Original recommendation (4-question organizer escalation) replaced with Day-1 empirical validation.** Rationale: the probability model (§6) shows ~65% likelihood of auto-sponsorship. Pre-March escalation consumes social capital for a question that answers itself in the first 15 minutes of Day 1. Organizer inquiry is still warranted for S1 (multi-entry) and E6 (admin-spawned structures) if those remain unresolved through other channels.

**Day-1 Sponsor Validation Protocol (60 minutes, minute 1):**

See §6 for the full protocol. Summary:
1. Connect to test server → query AdminACL object → inspect `authorized_sponsors` table
2. Attempt a sponsored PTB using EVE Vault or Sui CLI
3. If sponsored tx succeeds → Branch A confirmed → proceed with standard workflow
4. If `EUnauthorizedSponsor` → attempt server-routed tx path (dapp-kit `sponsoredTransaction`)
5. If all paths fail → activate fallback chain (Stillness silent deploy → local devnet)

**Fallback chain (ordered by preference):**
1. **Stillness deployment** (April 1–14 post-submission window) — real production environment, strongest demo evidence
2. **Stillness silent deploy** (pre-submission) — deploy extension without surfacing UI URL; capture demo evidence on real infrastructure
3. **Local devnet** — self-administered GovernorCap; proven workflow; weaker evidence but complete demo loop

### Post-Hack Hardening Option

- Request CCP to expose a "builder sponsor registration" API or admin tool for the test server
- Alternatively, propose a world-contracts enhancement: `register_builder_sponsor(admin_cap, sponsor_addr)` that uses AdminCap instead of GovernorCap for builder-level sponsor registration
- For Stillness deployment: the game server IS the sponsor — this issue is test-server-specific

### Validation Plan (How We Prove It's Resolved)

> **Revised:** Organizer message removed as Step 1. Empirical Day-1 validation is primary. See §6 for full protocol.

| Step | Method | Success Criteria |
|------|--------|------------------|
| 1 | Connect to test server (Day 1, minute 1) | `sui client active-env` → test server chain |
| 2 | Query AdminACL object | Identify `authorized_sponsors` table contents |
| 3 | Attempt sponsored PTB via dapp-kit or CLI | tx succeeds without `EUnauthorizedSponsor` |
| 4 | Execute `jump_with_permit` | JumpEvent emitted + permit consumed |
| 5 | If Step 3 fails → activate fallback chain | Stillness or local devnet confirmed within 60 min |
| 6 | Record GateControl beats | Beats 3–5 captured with real tx digests on resolved environment |

---

## 5. Assumptions Ledger

### On-Chain Mechanics

| # | Assumption | Status | Evidence | Day-1 Action |
|---|-----------|--------|----------|-------------|
| A1 | `authorize_extension<Auth>()` accepts custom witness with `drop` | **PROVEN** | Devnet validated; source-confirmed `gate.move` | Compile test on fresh world-contracts |
| A2 | `issue_jump_permit<Auth>()` callable from external packages | **PROVEN** | Devnet validated + minimal compile test PASS | Compile test |
| A3 | `withdraw_item<Auth>()` does NOT require OwnerCap | **PROVEN** | Source-confirmed: no OwnerCap param in signature ([storage_unit.move L200–L225](vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move#L200)) | — |
| A4 | `Item` struct has `key, store` abilities | **PROVEN** | Source-confirmed: [inventory.move L46–L54](vendor/world-contracts/contracts/world/sources/primitives/inventory.move#L46) | — |
| A5 | `jump_with_permit()` requires `verify_sponsor(ctx)` | **PROVEN** | Source-confirmed: [gate.move L279](vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | — |
| A6 | Dynamic fields on shared objects work for config stores | **PROVEN** | Standard Sui primitive; devnet validated | — |
| A7 | `Coin<SUI>` transfer works via `transfer::public_transfer` | **PROVEN** | Standard Sui primitive; devnet validated | — |
| A8 | Single extension type per gate/SSU | **PROVEN** | Source-confirmed: `Option<TypeName>` field | — |
| A9 | Extension functions (`deposit_item<Auth>`, `withdraw_item<Auth>`) do NOT require sponsor | **PROVEN** | Source-confirmed: no `verify_sponsor` call in either function | — |
| A10 | `withdraw_item<Auth>` returns full Item (no partial withdraw) | **PROVEN** | Source-confirmed: [inventory.move L269–L290](vendor/world-contracts/contracts/world/sources/primitives/inventory.move#L269) | Design around full-stack listings |
| A11 | `deposit_item<Auth>` merges quantities for existing type_id | **PROVEN** | Source-confirmed: [inventory.move L225–L267](vendor/world-contracts/contracts/world/sources/primitives/inventory.move#L225) (v0.0.12; confirmed unchanged in v0.0.13) | — |
| A12 | `withdraw_item<Auth>` does NOT check `is_online()` | **PROVEN** | Source-confirmed: no `status.is_online()` assertion in extension withdraw path | Extension should add own check |
| A13 | `verify_distance` has no deadline check | **PROVEN** | Source-confirmed: [location.move L140–L157](vendor/world-contracts/contracts/world/sources/primitives/location.move#L140) — no clock param, no deadline field in DistanceProofMessage | Distance proofs are reusable |

### Environmental Assumptions

| # | Assumption | Status | Evidence | Day-1 Action |
|---|-----------|--------|----------|-------------|
| E1 | world-contracts repo structure unchanged | **NEEDS VALIDATION** | Last checked: v0.0.12 @ 09c2ec2 (Feb 18) | `git fetch`, diff gate.move + storage_unit.move |
| E2 | builder-scaffold Docker devnet works | **PROVEN** | Validated Feb 16, 17, 18 | Cold-start timing check |
| E3 | Sui CLI `--gas-sponsor` flag works on PTB | **PROVEN** | Devnet validated with digests | — |
| E4 | Local devnet faucet works | **PROVEN** | Used in all sandbox validation | — |
| E5 | Hackathon test server available March 11 | **UNPROVEN** | Stated in hackathon announcement | Connect on Day 1 |
| E6 | Test server provides admin-spawnable structures | **UNPROVEN** | No evidence for or against | **Ask organizers pre-March-11** |
| E7 | Test server package IDs discoverable | **UNPROVEN** | Logical assumption (pre-published means queryable) | Query on Day 1 |
| E8 | Test server AdminACL allows builder sponsor addresses | **UNPROVEN — HIGH** *(revised from CRITICAL; see §6 probability model)* | No direct evidence, but high-probability inference from Stillness architecture: server-side auto-sponsorship is the expected model. GovernorCap required only if builders must self-register. | **Day-1 validation protocol (§6, 15 min)** |
| E9 | EVE Vault connects to test server chain | **UNPROVEN** | Wallet lists `sui:devnet` + `sui:testnet` only | Test on Day 1; fallback to Sui Wallet |
| E10 | `CharacterCreatedEvent` queryable on test server | **UNPROVEN** | Works on devnet; depends on test server event retention | Validate in first 30 min |
| E11 | `suix_getOwnedObjects` on object address works on test server | **UNPROVEN** | Works on devnet; OwnerCap discovery depends on this | Validate in first 30 min |

### Strategy Assumptions

| # | Assumption | Status | Evidence | Action |
|---|-----------|--------|----------|--------|
| S1 | Multi-entry allowed per team | **UNPROVEN** | Rules silent on multi-entry; prohibit multi-team | Ask organizers |
| S2 | Recorded demo (not live) | **PROVEN** | Deepsurge submission form has video link field | — |
| S3 | Demo is 2–5 minutes | **UNPROVEN** | No stated limit; 3 min designed as default | Check for length guidance |
| S4 | Test server evidence is valid for submission | **UNPROVEN** | No statement requiring Stillness-specific evidence | Ask organizers or assume yes |
| S5 | `Coin<SUI>` is the settlement token (not a custom EVE token) | **UNPROVEN** | world-contracts has only `// TODO` for EVE token; all examples use SUI | Check test server for `Coin<EVE>` types |

> **Update 2026-02-28:** world-contracts is now v0.0.13 @ e508451 (was v0.0.12 @ 09c2ec2 at time of this sweep). Key changes affecting assumptions above: (1) `Coin<EVE>` now exists (10B supply, 9 decimals) — S5 settlement token assumption needs re-evaluation; (2) `GateLinkedEvent`/`GateUnlinkedEvent` now emitted on link/unlink; (3) AdminACL refactor complete with universal `verify_sponsor(ctx)` (already reflected in this sweep's findings).

---

## Appendix: Subagent Audit Cross-Reference

All 58 findings from 6 parallel audit tracks are consolidated in [sweep-audit-artifacts-2026-02-18.md](sweep-audit-artifacts-2026-02-18.md).

| Audit | Focus | Key Findings Referenced In This Report |
|-------|-------|---------------------------------------|
| **A** | On-chain enforcement & permissions | A10 (partial withdraw), A12 (no online check), extension auth safety |
| **B** | Trade settlement & coin flow | A9 (no sponsor on extension), S5 (Coin<SUI> vs EVE), overpayment handling |
| **C** | UI read-model & event schema | Character resolution (E10, E11), custom event dependency, demo setup tx count |
| **D** | Wallet / TX / failure modes | EVE Vault sponsor stub, chain ID restriction (E9), zkLogin stability |
| **E** | In-game integration & SSU | dApp documentation gap, distance proof reusability (A13), proximity-free extension path |
| **F** | Hackathon operational constraints | E8 (AdminACL access, reclassified), S1 (multi-entry), GovernorCap dependency |

---

*Analysis performed: 2026-02-18. All file references are relative to the `sui-playground` workspace root.*
*Revised 2026-02-18: Sponsor risk reclassified (CRITICAL → HIGH). Probability model added (§6). Pre-March escalation replaced with Day-1 validation protocol.*
*Next action: Day-1 Sponsor Validation Protocol (§6, 15–60 min on test server connect).*

---

## 6. Addendum: Sponsor Risk Reclassification (2026-02-18)

### Reason for Revision

The original analysis modeled the hackathon test server as a "raw chain + builder" environment — implicitly assuming builders would need to self-register sponsor addresses using GovernorCap. This was the adversarially correct framing for the initial sweep but over-weighted the CRITICAL classification by ignoring the most probable environment model.

**Key correction:** The hackathon test server is almost certainly a managed game-chain environment operated by CCP, not a raw devnet. On Stillness (live production), the CCP game server acts as the gas sponsor for all gameplay transactions. AdminACL is preconfigured with the server's sponsor address. Builders' transactions routed through official infrastructure (dapp-kit, EVE Vault) are automatically sponsored. This is the standard model for managed blockchain games and mirrors how the Ethereum-era EVE Frontier operated.

There is no signal that the test server would diverge from this model. 

### Probability Model

| Branch | Description | Probability | Impact on GateControl Demo | Expected Cost |
|--------|------------|-------------|---------------------------|---------------|
| **A** | Test server auto-sponsors like Stillness. CCP game server is the sponsor. AdminACL is preconfigured. Builder txs routed through dapp-kit/EVE Vault are automatically sponsored. | **~65%** | **No impact.** Standard workflow. | 0 hours |
| **B** | Sponsor exists but requires a specific wallet path (e.g., must use EVE Vault `sponsoredTransaction` feature, or transactions must be routed through a specific RPC endpoint/relayer). Not auto-magic but documented or discoverable. | **~25%** | **Moderate.** 1–3 hours to discover correct path and adapt PTB construction. | 2 hours |
| **C** | No sponsor access for builders. AdminACL does not include any address accessible to builders. GovernorCap delegation unavailable. | **~10%** | **High.** GateControl jump demo blocked on test server. Fallback required. | 4–8 hours (environment switch) |

**Reasoning for estimates:**

- **Branch A (~65%):** This is the standard model for managed game chains. CCP operates the world-contracts package, game server, and RPC infrastructure as an integrated stack. The hackathon test server exists to let builders test extensions in a realistic environment — which requires working sponsorship. Denying sponsorship would make the test server useless for any operation touching `verify_sponsor` (jumps, fuel, item bridging), defeating its purpose. The Ethereum-era EVE Frontier operated this way. No signal contradicts this.

- **Branch B (~25%):** Possible if CCP provides sponsorship through a specific integration path (e.g., their `sponsoredTransaction` wallet feature routes through a server that co-signs) rather than auto-sponsoring all transactions. In this case, the mechanism exists but requires discovering the correct invocation pattern. The EVE Vault stub suggests this feature is planned but incomplete — it may be functional on the test server even if the stub exists in the open-source wallet code.

- **Branch C (~10%):** Only applies if: (a) the test server is a bare Sui devnet with world-contracts published but no game server running, OR (b) CCP intentionally restricts sponsored operations to their own game client. This contradicts the stated purpose of the hackathon (builders creating extensions that interact with game infrastructure). The existence of `extension_examples/` in world-contracts, the builder-scaffold tooling, and the dapp-kit SDK all imply CCP intends builders to execute sponsored operations.

### Expected Value Analysis

| Metric | Value |
|--------|-------|
| Expected time cost | 0.65 × 0h + 0.25 × 2h + 0.10 × 6h = **1.1 hours** |
| Original CRITICAL framing implied | 100% × Branch C = 6–8 hours minimum |
| Pre-March organizer inquiry value | Low — answers itself empirically in <15 min on Day 1 |
| Social capital cost of pre-March inquiry | Non-zero — consumes one of few organizer interactions |

The expected cost of ~1 hour does not justify CRITICAL classification or pre-March escalation. The risk is real but environment-dependent and self-resolving on Day 1.

### Revised Severity

**CRITICAL → HIGH (environment-dependent; validate Day 1)**

The risk remains in the Top 5 because Branch C, while unlikely, would require significant fallback effort. But the expected-value framing correctly identifies this as a Day-1 validation task, not a pre-March blocker.

### Day-1 Sponsor Validation Protocol (60 minutes)

Execute immediately upon test server access:

**Phase 1 — Discover (15 min)**
```
# 1. Connect to test server
sui client active-env                    # Verify env name
sui client active-address                # Note builder address

# 2. Find AdminACL object
sui client objects --json | findstr "AdminACL"
# OR: query by type
# suix_getOwnedObjects with StructType filter for "::access_control::AdminACL"

# 3. Inspect AdminACL state
sui client object <ADMIN_ACL_ID> --json
# Look for: authorized_sponsors table contents
# If table is non-empty → auto-sponsorship likely active
```

**Phase 2 — Test (15 min)**
```
# 4. Attempt a simple sponsored operation
# Option A: Use EVE Vault / dapp-kit sponsored tx path
# Option B: Use Sui CLI with --gas-sponsor if a known sponsor address exists
# Option C: Try a jump_with_permit call and observe the error

# Success: tx executes → Branch A confirmed → proceed
# EUnauthorizedSponsor: sponsor exists but builder not in ACL → try Branch B paths
# ENoSponsor: no sponsor in tx context → test server may not auto-sponsor
```

**Phase 3 — Adapt or Fallback (30 min, only if Phase 2 fails)**
```
# If Branch B suspected:
# - Test EVE Vault sponsoredTransaction on test server (may work even if stub in OSS code)
# - Check test server RPC for relayer/proxy endpoint
# - Check Discord/docs for builder sponsor registration

# If Branch C confirmed:
# - Activate fallback: Stillness silent deploy (preferred) or local devnet
# - Redirect GateControl demo to fallback environment
# - Continue TradePost on test server (sponsor-free)
```

**Decision point:** If Phase 2 succeeds, mark E8 as PROVEN and continue. If Phase 3 exhausts options, switch to Stillness fallback and note the constraint in submission materials.

### Stillness Fallback Detail

Even in the worst case (Branch C, ~10%), CivilizationControl is not blocked:

1. **Stillness deployment window** (April 1–14, post-submission): Deploy extension on live production. Record demo evidence on real game infrastructure. This is actually *stronger* evidence than test server.
2. **Stillness silent deploy** (pre-submission): Deploy extension package to Stillness without surfacing the UI URL publicly. Capture demo evidence. Extension code is on-chain but undiscoverable without the dApp URL.
3. **Local devnet** (last resort): Self-administered GovernorCap. Complete demo loop. Weaker evidence but functionally complete.

The existence of multiple fallback environments means Branch C is a *schedule risk* (4–8 hours of environment switching), not an *architectural impossibility*. No code changes required for any fallback — only environment configuration.
