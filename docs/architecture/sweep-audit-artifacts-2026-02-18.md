# Structural Risk Sweep — Consolidated Audit Artifacts

**Retention:** Carry-forward

> **Date:** 2026-02-18
> **Purpose:** Consolidated working notes from 6 parallel subagent audit tracks that fed the [Structural Risk Sweep](structural-risk-sweep-2026-02-18.md). Findings are numbered per-audit and cross-referenced to the main report's Top 5 risks and assumptions ledger.
> **Total findings:** 58 across 6 audits (5 CRITICAL, 12 HIGH, 18 MEDIUM, 16 LOW, 7 confirmation/N/A)

---

## Audit A: On-Chain Enforcement & Permissions

**Focus:** Move function permissions, sponsorship requirements, partial-quantity handling, extension durability

| ID | Finding | Severity | Evidence Summary |
|----|---------|----------|-----------------|
| A-4.1a | `withdraw_item` returns FULL quantity (no partial) | **CRITICAL** | `inventory.items.remove(&type_id)` removes entire Item; no quantity parameter |
| A-4.1b | No `split_item` or `partial_withdraw` exists | **CRITICAL** | Grep returns zero results; `Item` constructor is `public(package)` only |
| A-2.2a | No `deauthorize_extension` function exists | MEDIUM | Owner can only replace extension by authorizing a new type |
| A-2.2b | Owner can replace extension at any time | MEDIUM | `authorize_extension` overwrites `Option<TypeName>` |
| A-6.3a | Both gates must have same extension type for permits | MEDIUM | `issue_jump_permit` checks `TypeName` equality on source/target |
| A-3.1a | Concurrent access handled by Sui consensus | LOW | Standard shared object behavior |
| A-6.1a | `withdraw_item<Auth>` has no online check | LOW | No `status.is_online()` assertion in extension withdraw path |
| A-1.3a | `jump_with_permit()` requires sponsor | Confirmed | `admin_acl.verify_sponsor(ctx)` present in function body |
| A-1.3b | Extension ops bypass `verify_sponsor` | Confirmed | No `verify_sponsor` call in `deposit_item<Auth>` / `withdraw_item<Auth>` |
| A-5.2a | Permits are single-use (consumed on jump) | Confirmed | `transfer::delete(permit)` after use |
| A-5.3a | Permits are character-bound | Confirmed | `permit.character_id` checked against caller |
| A-6.4a | Extension blocks default jump permanently | Desired | `jump()` aborts if extension registered; `jump_with_permit` required |

**Promoted to main report:** A-4.1a/4.1b → Risk #2 (partial-quantity withdrawal)

---

## Audit B: Trade Settlement & Coin Flow

**Focus:** Payment handling, currency compatibility, atomicity, listing lifecycle

| ID | Finding | Severity | Evidence Summary |
|----|---------|----------|-----------------|
| B-4 | `Coin<SUI>` may not match game economy token | **HIGH** | `world.move` L8: `// TODO: mint initial supply of eve tokens`; `init()` only creates GovernorCap |
| B-1 | Overpayment not handled in primary design doc | MEDIUM | No `coin::split` / refund logic designed for buy() |
| B-6b | Duplicate listings for same `type_id` not guarded | MEDIUM | No uniqueness constraint on listing creation |
| B-7 | No partial-quantity withdraw (design constraint) | MEDIUM | Same root as A-4.1a; affects listing granularity |
| B-2 | No fee mechanism; 100% to seller | LOW | Acceptable for MVP; fee can be added post-hack |
| B-3 | Extension functions don't require sponsorship | LOW (favorable) | Confirmed: TradePost is fully sponsor-free |
| B-6a/c/d/e | Listing cancel race / seller drains / stocking / offline | LOW | Edge cases manageable by extension design |
| B-5 | PTB atomicity confirmed | NONE | Standard Sui PTB guarantee |

**Promoted to main report:** B-4 informs S5 (assumptions ledger)

---

## Audit C: UI Read-Model & Event Schema

**Focus:** Character resolution, OwnerCap discovery, event schema gaps, demo data bootstrapping

| ID | Finding | Severity | Evidence Summary |
|----|---------|----------|-----------------|
| C-1 | Character resolution — manual ID paste is only guaranteed path | **HIGH** | No public wallet→Character function; `game_character_id` is `#[test_only]` |
| C-3 | 5 of 8 Signal Feed events don't exist in world-contracts | **HIGH** | `TollCollectedEvent`, `TradeSettledEvent`, link/unlink, extension-auth events missing |
| C-2 | OwnerCap discovery via object-address RPC unverified on live | MEDIUM | `suix_getOwnedObjects` with type filter — works on devnet, unverified on test server |
| C-6 | 20–24 setup transactions before populated Command Overview | MEDIUM | publish + spawn + fuel + online + authorize + config + stock |
| C-8 | `JumpEvent` missing tribe/toll fields | MEDIUM | Signal Feed must correlate with extension config to show tribe + toll |
| C-10 | `link_gates`/`authorize_extension` emit no events (silent) | MEDIUM | State changes require polling-based detection |
| C-4 | Revenue = 0 at cold start | LOW | Expected; UI must handle gracefully |
| C-5 | Polling at 10s reliable; subscription unverified | LOW | Acceptable for MVP |
| C-7 | Claim-proof matrix references stale mock events | LOW | Doc correction needed |
| C-9 | `StatusChangedEvent` lacks owner attribution | LOW | Must correlate with object ownership |

**Promoted to main report:** C-1 → Risk #4 (character resolution)

> **Update 2026-02-28:** C-10 is partially superseded — `link_gates`/`unlink_gates` now emit `GateLinkedEvent`/`GateUnlinkedEvent` (world-contracts v0.0.13 @ e508451). `authorize_extension` still emits no event.

---

## Audit D: Wallet / TX Parsing / Failure Modes

**Focus:** EVE Vault integration, sponsored tx construction, failure parsing, gas estimation, chain support

| ID | Finding | Severity | Evidence Summary |
|----|---------|----------|-----------------|
| D-1 | Sponsored tx in EVE Vault is a hardcoded stub | **HIGH** | `walletHandlers.ts` returns `digest: "0x1234567890"`; depends on non-existent "quasar" service |
| D-2 | Chain compatibility — wallet exposes only `sui:devnet`/`sui:testnet` | **HIGH** | `SuiWallet.ts` chains array has no localnet or custom chain |
| D-3 | Gas estimation blocks intentionally-failing tx (Beat 4) | MEDIUM | Dry-run may reject tx that's designed to fail; workaround: submit directly |
| D-4 | `Character.character_address` mismatch with zkLogin address | MEDIUM | zkLogin derives different address than game client may expect |
| D-5 | EVE Vault signing smoke test still PENDING | MEDIUM | Manual browser test not yet executed |
| D-6 | Enoki API downtime during demo | LOW | Unlikely; use pre-recorded fallback if needed |
| D-7 | zkLogin proof expiry mid-demo | LOW | Proof valid for epoch (~24h); demo is <30 min |

**Promoted to main report:** D-1 → Risk #3 (EVE Vault stub)

> **Update 2026-02-28:** D-1 is superseded — EVE Vault sponsored transactions are now functional (commit 687d432). Sign-and-execute works via `window.postMessage` relay. API URL changed to `/${assemblyType}/${action}` format with `X-Tenant` header. Default chain switched to testnet.

---

## Audit E: In-Game Integration & SSU/Structure Interaction

**Focus:** dApp embedding, fuel burn mechanics, proof requirements, structure deployment chain

| ID | Finding | Severity | Evidence Summary |
|----|---------|----------|-----------------|
| E-1.1 | All 4 dApp docs are `//TODO` stubs | **CRITICAL** | `vendor/builder-documentation/dapps/` — all 4 files contain only title + `//TODO` |
| E-3.1 | Test server admin tools unknown | **HIGH** | E5–E7 unverified; no documentation on test server provisioning |
| E-3.2 | 16-step deployment if no admin tools | **HIGH** | Full chain: publish → AdminCap → spawn × N → fuel → online → link → authorize |
| E-5.3a | Test server proof signing authority unknown | **HIGH** | Proofs require `ServerAddressRegistry` entry; signing key unknown |
| E-6.4 | Item bridging requires sponsorship (stocking bottleneck) | **HIGH** | `game_item_to_chain_inventory()` calls `verify_sponsor` |
| E-1.2 | SSU README has no dApp loading info | HIGH | No iframe/webview documentation |
| E-1.3 | `Metadata.url` exists but purpose undocumented | MEDIUM | Field present in struct; no setter or consumer documented |
| E-4.4 | Fuel depletion takes structures offline silently | MEDIUM | `fuel_amount == 0` → no event; must poll `is_online()` |
| E-7.4 | Config tables require AdminCap | MEDIUM | `config_set_value` requires AdminCap, not OwnerCap |
| E-5.2 | Proximity proofs have deadlines (extension path unaffected) | MEDIUM | `deadline_ms` in proximity proof; extension deposit/withdraw skip this |
| E-5.1 | `verify_distance` has no deadline (favorable) | LOW | No clock param, no deadline in DistanceProofMessage |
| E-2.3 | Scaffold dApp is standalone (no game embed) | LOW | Demonstrates external browser, not in-game loading |
| E-6.2 | `deposit_item<Auth>` needs NO proximity proof (favorable) | NONE | Extension deposit bypasses proximity checks |

**Promoted to main report:** E-1.1 referenced in executive summary; E-3.1/E-6.4 inform E5–E8 assumptions

---

## Audit F: Hackathon Operational Constraints

**Focus:** Multi-submission rules, test server assumptions, submission logistics, IP, package upgrades

| ID | Finding | Severity | Evidence Summary |
|----|---------|----------|-----------------|
| F-1 | ~~Multi-submission rule ambiguous~~ | ~~**CRITICAL**~~ ✅ **RESOLVED** | Deep Surge FAQ confirms multiple submissions allowed; each must be unique (2026-03-02) |
| F-5 | Sponsored tx access on test server | **HIGH** | `add_sponsor_to_acl()` requires GovernorCap; *(reclassified — see §6 of main report)* |
| F-7 | Admin-spawned structures assumption (E6) | **HIGH** | If no admin tools, 25–35 txs and 3–5 hours for infrastructure |
| F-2 | Test server vs Stillness chain identity unknown | MEDIUM | May be same chain or separate; affects data setup |
| F-8 | Package upgrade breaks extensions if redeployed | MEDIUM | `sui move publish` creates new package ID; extensions hardcode package |
| F-3 | Submission deadline and format | LOW | 31 March 2026 23:59 UTC; video + GitHub repo |
| F-4 | IP and code originality | LOW | Must be original work developed after start date |
| F-6 | Time zone and deadline mechanics | LOW | UTC deadline; standard |

**Promoted to main report:** F-1 → Risk #5 (multi-entry); F-5 → Risk #1 (sponsor access, reclassified)

---

## Aggregate Severity Distribution

| Severity | Count | % |
|----------|-------|---|
| CRITICAL | 5 | 9% |
| HIGH | 12 | 21% |
| MEDIUM | 18 | 31% |
| LOW | 16 | 28% |
| Confirmed / N/A | 7 | 12% |
| **Total** | **58** | |

---

## Cross-Reference: Findings → Main Report

| Main Report Section | Source Findings |
|---------------------|---------------|
| Risk #1 (AdminACL sponsor) | F-5, A-1.3a, D-1 |
| Risk #2 (Partial withdraw) | A-4.1a, A-4.1b, B-7 |
| Risk #3 (EVE Vault stub) | D-1, D-2 |
| Risk #4 (Character resolution) | C-1 |
| Risk #5 (Multi-entry) | F-1 |
| Executive Summary §4 (custom events) | C-3 |
| Assumption A9 (sponsor-free extensions) | A-1.3b, B-3 |
| Assumption A10 (full-stack withdraw) | A-4.1a |
| Assumption A12 (no online check) | A-6.1a |
| Assumption A13 (no deadline on verify_distance) | E-5.1 |
| Assumption E8 (AdminACL access) | F-5, E-3.1, E-6.4 |
| Assumption S5 (Coin<SUI> settlement) | B-4 |

---

*Consolidated: 2026-02-18. Source: 6 parallel subagent audits (A–F) totaling ~2,100 lines of working notes.*
*Canonical output: [structural-risk-sweep-2026-02-18.md](structural-risk-sweep-2026-02-18.md)*
