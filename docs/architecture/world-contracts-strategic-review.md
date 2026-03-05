# World Contracts Strategic Review

**Retention:** Carry-forward

**Date:** 2026-03-03
**Scope:** `vendor/world-contracts/` (v0.0.15) — read-only analysis
**Method:** Multi-subagent deep review (18 module files, 6000+ LOC, all extension examples and builder scaffold)

---

## Executive Summary

The world-contracts codebase is structurally sound for its core purpose: a capability-based assembly management system for EVE Frontier. The extension pattern (typed witness + OwnerCap + dynamic field config) is well-designed and validated end-to-end. However, six categories of improvement would materially benefit CivilizationControl and the broader builder ecosystem:

1. **Security fix** — `extension_examples::config::x_auth()` is `public` instead of `public(package)`, enabling witness forgery
2. **Event gaps** — `authorize_extension` and several other state transitions emit no events, creating observability blind spots at critical demo proof moments
3. **Read-path gaps** — Metadata getters and inventory query functions are `#[test_only]`, forcing builders to raw-parse object data
4. **API inconsistencies** — `extension_type()` returns `&Option<TypeName>` on Gate but aborts on Turret; naming divergences across modules
5. **Governance blind spots** — No `remove_sponsor_from_acl`, AdminACL not enumerable, no events for ACL changes
6. **Builder friction** — No bootstrap documentation, empty SSU scaffold, missing turret scaffold, builder-scaffold API divergence from current world-contracts

**Bottom line:** 4 SIMPLE changes and 3 EASY changes could be submitted today with high confidence. The HARD changes are architectural and should not be attempted pre-hackathon.

---

## Key Findings

### Critical (Blockers / Security)

| ID | Finding | Module | Evidence |
|----|---------|--------|----------|
| **S-01** | `extension_examples::config::x_auth()` is `public` — any package can forge the witness | [config.move#L23](../../../vendor/world-contracts/contracts/extension_examples/sources/config.move#L23) | Function declared `public fun x_auth(): XAuth` instead of `public(package)`. Builder-scaffold correctly uses `public(package)`. |
| **S-02** | No `remove_sponsor_from_acl` — ACL sponsor privileges are permanent and irrevocable | [access_control.move#L198](../../../vendor/world-contracts/contracts/world/sources/access/access_control.move#L198) | Comment says "Governor can add/remove sponsors" but remove function does not exist. Once enrolled, no on-chain revocation path. |
| **S-03** | Metadata view functions (`name`, `description`, `url`) are `#[test_only]` | [metadata.move#L97-L110](../../../vendor/world-contracts/contracts/world/sources/primitives/metadata.move#L97-L110) | Browsers cannot read assembly names/descriptions via `devInspectTransactionBlock`. Must raw-parse object data. |

### High (Demo-Impacting / Builder Friction)

| ID | Finding | Module | Evidence |
|----|---------|--------|----------|
| **H-01** | ~~`authorize_extension` emits no event~~ **RESOLVED** (PR #110 / commit 3cc9ffa) | [gate.move#L127-L147](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L127-L147) | `ExtensionAuthorizedEvent` now emitted for Gate, SSU, and Turret. Proof moment #1 has typed event evidence. |
| **H-02** | `extension_type()` aborts on Turret if no extension, returns `&Option` on Gate | [turret.move#L330](../../../vendor/world-contracts/contracts/world/sources/assemblies/turret.move#L330) vs [gate.move#L407](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L407) | API inconsistency — builder must defensively check `is_extension_configured()` on Turret but not Gate. |
| **H-03** | `item_quantity()` on Inventory is `#[test_only]` | [inventory.move#L476](../../../vendor/world-contracts/contracts/world/sources/primitives/inventory.move#L476) | SSU contents cannot be queried on-chain without raw object parsing. `contains_item()` is public but `item_quantity()` is not. |
| **H-04** | `connected_assemblies()` returns `vector<ID>` with no type info | [network_node.move#L160](../../../vendor/world-contracts/contracts/world/sources/network_node/network_node.move#L160) | Browsers must fetch each ID individually to determine if it's a Gate, Turret, or SSU. |
| **H-05** | No event for `add_sponsor_to_acl` | [access_control.move](../../../vendor/world-contracts/contracts/world/sources/access/access_control.move) | AdminACL membership changes are invisible to event subscribers. |
| **H-06** | Both gates must share same extension type for `issue_jump_permit` | [gate.move#L237-L242](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move#L237-L242) | Coordination dependency: gate pair owner must agree on extension. Undocumented beyond a `TODO` comment. |
| **H-07** | Builder-scaffold uses stale API signatures (pre-v0.0.15) | builder-scaffold `corpse_gate_bounty.move` | `withdraw_by_owner` still passes `AdminACL` parameter removed in v0.0.15. |
| **H-08** | `EExtensionNotAuthorized` covers 3+ failure modes with same abort code | [gate.move](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | Cannot distinguish "no extension", "wrong Auth type", or "destination missing extension" from abort code alone. |

### Medium (Improvement Opportunities)

| ID | Finding | Module | Evidence |
|----|---------|--------|----------|
| **M-01** | `ETypeIdEmtpy` typo in fuel.move | [fuel.move#L9](../../../vendor/world-contracts/contracts/world/sources/primitives/fuel.move#L9) | `Emtpy` → `Empty`. Shows in error traces. |
| **M-02** | SSU has no `extension_type()` view function | [storage_unit.move](../../../vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move) | Gate and Turret expose extension type; SSU does not. |
| **M-03** | NetworkNode `status()` is `#[test_only]` | [network_node.move](../../../vendor/world-contracts/contracts/world/sources/network_node/network_node.move) | `is_network_node_online` is public, but the raw status enum is not accessible. |
| **M-04** | OwnerCap has no public `authorized_object_id()` getter | [access_control.move](../../../vendor/world-contracts/contracts/world/sources/access/access_control.move) | Must raw-parse object data to map OwnerCap → Assembly. |
| **M-05** | `EGatesNotLinked` used for both "not linked" (jump) and "should not be linked" (unanchor) | [gate.move](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | Same error code, opposite semantics depending on context. |
| **M-06** | `EAssemblyInvalidStatus` is the only status error — no current-state context | [status.move](../../../vendor/world-contracts/contracts/world/sources/primitives/status.move) | Cannot distinguish "already online" from "already offline" from the abort code. |
| **M-07** | `is_network_node_online` naming inconsistent with `is_online` on other assemblies | [network_node.move](../../../vendor/world-contracts/contracts/world/sources/network_node/network_node.move) | All other assemblies use `is_online()`. NWN uses `is_network_node_online()`. |
| **M-08** | AdminACL is global, not scoped per function/assembly type | [access_control.move](../../../vendor/world-contracts/contracts/world/sources/access/access_control.move) | Single ACL controls all operations — enrollment grants full admin. |
| **M-09** | No `extension_type()` view or `is_extension_configured()` on SSU | [storage_unit.move](../../../vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move) | Cannot determine SSU extension state without raw object read. |

---

## Recommended Changes

### SIMPLE (Low risk, small diff, submittable today)

#### S-SIMPLE-01: Fix `x_auth()` visibility in extension_examples

- **Title:** Change `public fun x_auth()` to `public(package) fun x_auth()` in extension_examples
- **Description:** Single-word change in [extension_examples/sources/config.move#L23](../../../vendor/world-contracts/contracts/extension_examples/sources/config.move#L23). Prevents external packages from forging the witness.
- **CC benefit:** Reference examples that builders copy won't produce exploitable extensions.
- **Ecosystem benefit:** Every builder who starts from extension_examples gets the correct security pattern.
- **Risk:** None — builder-scaffold already uses `public(package)`. Existing deployments from examples would need redeployment.
- **Diff size:** ~1 line
- **Safe pre-hackathon:** YES

#### S-SIMPLE-02: Fix `ETypeIdEmtpy` typo in fuel.move

- **Title:** Correct `ETypeIdEmtpy` → `ETypeIdEmpty` in fuel.move
- **Description:** Typo fix at [fuel.move#L9](../../../vendor/world-contracts/contracts/world/sources/primitives/fuel.move#L9).
- **CC benefit:** Clean error traces during demo debugging.
- **Ecosystem benefit:** Professional codebase quality signal.
- **Risk:** None — string content only, no logic change.
- **Diff size:** 1 line
- **Safe pre-hackathon:** YES

#### S-SIMPLE-03: Make Turret `extension_type()` return `&Option<TypeName>` (match Gate API)

- **Title:** Harmonize `extension_type()` return type across assemblies
- **Description:** Change [turret.move#L330](../../../vendor/world-contracts/contracts/world/sources/assemblies/turret.move#L330) from `*option::borrow(&turret.extension)` to `&turret.extension`, returning `&Option<TypeName>` like Gate.
- **CC benefit:** Consistent API — no defensive checks needed per assembly type.
- **Ecosystem benefit:** Eliminates a common beginner trap (turret aborts unexpectedly when no extension set).
- **Risk:** Low — breaks callers that unwrap the return value directly. But `extension_type()` on Turret is rarely called by external code.
- **Diff size:** ~2 lines (function signature + body)
- **Safe pre-hackathon:** YES (minor breaking change, but safer API)

#### S-SIMPLE-04: Rename `is_network_node_online` → `is_online` on NetworkNode

- **Title:** Consistent `is_online()` naming across all assemblies
- **Description:** Rename at [network_node.move](../../../vendor/world-contracts/contracts/world/sources/network_node/network_node.move) to match Gate, Turret, SSU.
- **CC benefit:** Predictable API when iterating over mixed assembly types.
- **Ecosystem benefit:** Less mental overhead for new builders.
- **Risk:** Low — breaks callers using the old name. Search for call sites.
- **Diff size:** ~2 lines
- **Safe pre-hackathon:** YES (if call-site audit confirms low impact)

---

### EASY (Moderate but safe, submittable this week)

#### S-EASY-01: Add `ExtensionAuthorizedEvent` to all three assembly types — **IMPLEMENTED** (PR #110 / commit 3cc9ffa)

- **Title:** Emit event on `authorize_extension` for Gate, SSU, and Turret
- **Description:** `ExtensionAuthorizedEvent { assembly_id: ID, assembly_key: TenantItemId, extension_type: TypeName, previous_extension: Option<TypeName>, owner_cap_id: ID }` — emitted in `authorize_extension` for each assembly.
- **Actual fields:** 5 fields (added `assembly_key` and `owner_cap_id` beyond original proposal).
- **CC benefit:** Proof moment #1 ("Policy deploys on-chain") has typed event for UI subscription and demo proof cards. `previous_extension` field captures replacement.
- **Ecosystem benefit:** All builders can observe extension registration without polling.
- **Status:** Merged to world-contracts `main` — pinned in this repo at commit 3cc9ffa.

#### S-EASY-02: Promote Metadata, Inventory, and OwnerCap view functions from `#[test_only]` to public

- **Title:** Make read-path functions production-accessible
- **Description:**
  - [metadata.move#L97-L110](../../../vendor/world-contracts/contracts/world/sources/primitives/metadata.move#L97-L110): Remove `#[test_only]` from `name()`, `description()`, `url()`
  - [inventory.move#L476](../../../vendor/world-contracts/contracts/world/sources/primitives/inventory.move#L476): Remove `#[test_only]` from `item_quantity()`
  - [access_control.move](../../../vendor/world-contracts/contracts/world/sources/access/access_control.move): Add public `authorized_object_id()` getter for OwnerCap
- **CC benefit:** Browser-first polling works cleanly. SSU inventory readable. Assembly names displayable in topology UI.
- **Ecosystem benefit:** Every builder with a browser UI benefits. Eliminates raw object parsing requirement.
- **Risk:** Low — read-only functions, no state mutation. May expose internal field names (cosmetic concern only).
- **Diff size:** ~20 lines (remove test_only annotations + add OwnerCap getter)
- **Safe pre-hackathon:** YES

#### S-EASY-03: Add `extension_type()` and `is_extension_configured()` to StorageUnit

- **Title:** Parity read function for SSU extension state
- **Description:** Add view functions matching Gate and Turret patterns, returning `&Option<TypeName>` and `bool` respectively.
- **CC benefit:** TradePost extension state observable without raw object parsing.
- **Ecosystem benefit:** All three assembly types have identical extension query API.
- **Risk:** None — additive read-only functions.
- **Diff size:** ~8 lines
- **Safe pre-hackathon:** YES

---

### HARD (Architectural, defer to post-hackathon unless CCP prioritizes)

#### S-HARD-01: Add `remove_sponsor_from_acl`

- **Title:** ACL sponsor revocation
- **Description:** Add `remove_sponsor_from_acl(admin_acl: &mut AdminACL, governor_cap: &GovernorCap, address: address)` + event.
- **CC benefit:** Governance product that can't revoke admin access is fundamentally incomplete. Demo can show "grant + revoke" cycle.
- **Ecosystem benefit:** Security hygiene for all builders. Standard access-control expectation.
- **Risk:** Medium — requires GovernorCap auth. Must handle edge case of removing currently-executing sponsor mid-transaction. Should emit `SponsorRemovedEvent`.
- **Diff size:** ~15 lines
- **Safe pre-hackathon:** Probably YES but needs CCP coordination since GovernorCap is their object in production. EASY difficulty, HARD coordination.

#### S-HARD-02: Split `EExtensionNotAuthorized` into distinct error codes

- **Title:** Granular extension authorization errors
- **Description:** Replace single `EExtensionNotAuthorized` with:
  - `ENoExtensionConfigured` — assembly has no extension
  - `EExtensionTypeMismatch` — Auth type doesn't match registered extension  
  - `EDestinationExtensionMismatch` — destination gate has different extension type
- **CC benefit:** Demo proof cards can show exactly WHY a permit was denied. "Wrong extension" vs "no extension" vs "mismatched gates" are all different stories.
- **Ecosystem benefit:** Dramatically reduces debugging time for all extension builders.
- **Risk:** Low technically but changes abort code numbers, which may break existing error-handling code on the SDK/TS side.
- **Diff size:** ~25 lines across gate.move, storage_unit.move, turret.move
- **Safe pre-hackathon:** Probably YES if coordinated with CCP SDK team.

#### S-HARD-03: Add `SponsorAddedEvent` / `SponsorRemovedEvent` for AdminACL changes

- **Title:** Observable ACL mutations
- **Description:** Emit events on `add_sponsor_to_acl` (and `remove_sponsor_from_acl` if S-HARD-01 lands).
- **CC benefit:** Governance dashboard can subscribe to admin access changes. Critical for "calm authority" narrative — showing WHO has power.
- **Ecosystem benefit:** Auditability. Currently, AdminACL membership changes are invisible to event subscribers.
- **Risk:** Low — additive event emission.
- **Diff size:** ~10 lines
- **Safe pre-hackathon:** YES (but depends on CCP accepting the PR)

#### S-HARD-04: Assembly-typed `connected_assemblies` on NetworkNode

- **Title:** Return `(gates: vector<ID>, turrets: vector<ID>, ssus: vector<ID>)` from NetworkNode
- **Description:** Replace `vector<ID>` with typed vectors, or add parallel `connected_gates()`, `connected_turrets()`, `connected_ssus()` functions.
- **CC benefit:** Topology UI can render the object graph without per-ID type-check fetches.
- **Ecosystem benefit:** Every builder dashboard benefits from typed assembly enumeration.
- **Risk:** Medium — changes internal data structure. Would need to track assembly type on `connect`. Migration of existing NWN objects.
- **Diff size:** ~50-80 lines (new tracking + view functions + migration)
- **Safe pre-hackathon:** NO — data structure change, migration risk.

#### S-HARD-05: Scoped AdminACL (per-function or per-assembly-type)

- **Title:** Granular admin permissions
- **Description:** Replace single `Table<address, bool>` with `Table<address, vector<u8>>` or structured roles, allowing "gate admin only" vs "full admin" distinctions.
- **CC benefit:** Governance product can express role-based access. Critical for production but not demo-blocking.
- **Ecosystem benefit:** Security improvement — least-privilege principle.
- **Risk:** High — fundamental architecture change to access control. Breaks all existing AdminACL usage patterns.
- **Diff size:** 200+ lines
- **Safe pre-hackathon:** NO — too high risk for build week.

---

## Demo Impact Analysis

### CivilizationControl's 5 Proof Moments

| # | Proof Moment | Current Support | Impact of Recommended Changes |
|---|-------------|-----------------|-------------------------------|
| 1 | **Policy deploys on-chain** | Tx digest only — no typed event | **S-EASY-01** adds `ExtensionAuthorizedEvent` → proof card shows typed event with assembly ID and extension type. **HIGH IMPACT.** |
| 2 | **Hostile character denied at gate** | `MoveAbort` with generic `EExtensionNotAuthorized` | CC extension emits custom `PermitDeniedEvent`. **S-HARD-02** would make the abort code more expressive if abort path is preferred. **MEDIUM IMPACT.** |
| 3 | **Ally tolled + revenue collected** | No world-contracts support — fully CC extension | CC emits `TollCollectedEvent`. No world-contracts change needed. **NO IMPACT** (CC handles this). |
| 4 | **TradePost buy + item settlement** | `ItemDepositEvent` / `ItemWithdrawEvent` exist in inventory.move | Already sufficient. `deposit_to_owned` emits `ItemDepositEvent`. **ALREADY COVERED.** |
| 5 | **Revenue visible** | `suix_getBalance` for Coin<SUI> on extension address | Works for demo. No change needed. **ALREADY COVERED.** |

### Emotional Impact Amplifiers

| Change | Emotional Signal | Narrative Fit |
|--------|-----------------|---------------|
| `ExtensionAuthorizedEvent` (S-EASY-01) | "This is real governance — policy deployment is a first-class on-chain action" | Directly supports "calm authority" narrative. Proof card overlay. |
| Metadata view functions (S-EASY-02) | "This gate has a name and purpose — it's not an anonymous object ID" | Transforms topology UI from hex strings to readable labels. |
| Granular error codes (S-HARD-02) | "The system tells you exactly WHY you were denied, not just that you were denied" | Supports "consequence layer" — precision in denial messaging. |

---

## Risk Assessment

### Pre-Hackathon Submission Safety Matrix

| Change | Code Risk | Coordination Risk | Build Break Risk | Verdict |
|--------|-----------|-------------------|------------------|---------|
| S-SIMPLE-01 (x_auth visibility) | None | Low (examples package) | None | **SUBMIT TODAY** |
| S-SIMPLE-02 (typo fix) | None | None | None | **SUBMIT TODAY** |
| S-SIMPLE-03 (turret extension_type) | Low | Low (minor break) | Low | **SUBMIT TODAY** |
| S-SIMPLE-04 (is_online rename) | Low | Medium (call sites) | Low | **SUBMIT TODAY with call-site audit** |
| S-EASY-01 (extension events) | None | Low (additive) | None | **SUBMIT THIS WEEK** |
| S-EASY-02 (promote view fns) | None | Low (additive) | None | **SUBMIT THIS WEEK** |
| S-EASY-03 (SSU extension view) | None | None (additive) | None | **SUBMIT THIS WEEK** |
| S-HARD-01 (remove sponsor) | Low | High (GovernorCap) | Low | **DEFER unless CCP fast-tracks** |
| S-HARD-02 (granular errors) | Low | Medium (SDK impact) | Low | **SUBMIT if CCP agrees on code values** |
| S-HARD-03 (ACL events) | None | Low (additive) | None | **SUBMIT THIS WEEK** (reclassify as EASY) |
| S-HARD-04 (typed assemblies) | Medium | High (migration) | Medium | **DEFER to post-hackathon** |
| S-HARD-05 (scoped ACL) | High | High (architecture) | High | **DEFER to post-hackathon** |

### Dependency Chain

```
S-SIMPLE-01 ──→ no dependencies
S-SIMPLE-02 ──→ no dependencies  
S-SIMPLE-03 ──→ no dependencies (check turret extension callers)
S-SIMPLE-04 ──→ audit NWN call sites first
S-EASY-01   ──→ no dependencies
S-EASY-02   ──→ no dependencies
S-EASY-03   ──→ no dependencies
S-HARD-01   ──→ CCP GovernorCap coordination
S-HARD-02   ──→ S-HARD-01 is independent; SDK team alignment
S-HARD-03   ──→ S-HARD-01 (SponsorRemovedEvent depends on remove function)
```

---

## Competitive Lens

### Would these changes materially strengthen hackathon submission?

**YES — S-EASY-01 alone is the highest-leverage change.**

The `ExtensionAuthorizedEvent` transforms CC's first proof moment from "here's a transaction digest, trust me" to "here's a typed event with the extension name and assembly ID." This is the difference between a technical demo and a governance demo. The event becomes a UI card: "Policy `CivilizationControl::GateAuth` deployed on Gate `Sol-Gate-Alpha`."

### Would any change increase demo emotional impact?

**YES — S-EASY-02 (metadata view functions) has outsized emotional value.**

Currently, the topology UI must show raw hex object IDs. With public metadata getters, gates display as "Sol Gate Alpha" instead of `0x8a3f...`. This directly serves the 3-Second Check: governance topology is human-readable at a glance.

### Would any change improve proof-of-on-chain clarity?

**YES — S-HARD-02 (granular error codes) makes denial proof moments definitive.**

Instead of "Transaction failed: `EExtensionNotAuthorized`", the proof card says "Transaction failed: `EDestinationExtensionMismatch` — destination gate `0x7b2c...` has a different policy than source gate." This is governance speaking, not a generic error.

### Portfolio Project Benefits

| Change | CivilizationControl | CargoBond | Fortune Gauntlet | Flappy Frontier |
|--------|--------------------:|----------:|------------------:|----------------:|
| S-EASY-01 (events) | **HIGH** | Medium | Medium | Low |
| S-EASY-02 (read path) | **HIGH** | High | Medium | Low |
| S-EASY-03 (SSU view) | Medium | **HIGH** | Low | Low |
| S-HARD-02 (errors) | **HIGH** | Medium | High | Low |

---

## Final Recommendation

### Submit Today: YES (4 changes)

| Priority | Change | Effort | Impact |
|----------|--------|--------|--------|
| 1 | **S-SIMPLE-01**: Fix `x_auth()` `public` → `public(package)` | 5 min | Security fix |
| 2 | **S-SIMPLE-02**: Fix `ETypeIdEmtpy` typo | 2 min | Quality |
| 3 | **S-SIMPLE-03**: Harmonize `extension_type()` return type | 10 min | API consistency |
| 4 | **S-SIMPLE-04**: Rename `is_network_node_online` → `is_online` | 10 min | Naming consistency |

### Submit This Week: YES (3 changes)

| Priority | Change | Effort | Impact |
|----------|--------|--------|--------|
| 1 | **S-EASY-01**: `ExtensionAuthorizedEvent` on all assemblies | 30 min | Demo proof moment #1 |
| 2 | **S-EASY-02**: Promote `#[test_only]` view functions | 20 min | Browser-first read path |
| 3 | **S-EASY-03**: Add `extension_type()`/`is_extension_configured()` to SSU | 15 min | API parity |

### Defer: 3 changes

S-HARD-04, S-HARD-05 are post-hackathon. S-HARD-01/02/03 can go this week if CCP is responsive.

### Rationale

The SIMPLE changes are zero-risk quality improvements. The EASY changes are additive (new events, new view functions) with no behavioral impact on existing code. Together, they address the top 3 demo pain points: invisible policy deployment, unreadable object identifiers, and incomplete SSU query API. Total effort: ~90 minutes of implementation + test + PR. The competitive advantage is disproportionate to the effort.

---

## Appendix: Complete Event Inventory (Current State)

| Module | Event | Emitted On | Fields |
|--------|-------|------------|--------|
| status | `StatusChangedEvent` | online/offline any assembly | `assembly_id, old_status, new_status` |
| gate | `JumpEvent` | successful jump | `gate_id, character_id, destination_gate_id, timestamp_ms` |
| gate | `GateCreatedEvent` | anchor | `gate_id, network_node_id, type_id` |
| gate | `GatesLinkedEvent` | link_gates | `gate_a_id, gate_b_id` |
| gate | `GatesUnlinkedEvent` | unlink_gates | `gate_a_id, gate_b_id` |
| turret | `KillmailEvent` | turret kills character | `turret_id, victim_id, attacker_lists` |
| turret | `TurretCreatedEvent` | anchor | `turret_id, network_node_id, type_id` |
| inventory | `ItemDepositEvent` | deposit (all variants) | `storage_unit_id, owner_cap_id, type_id, quantity` |
| inventory | `ItemWithdrawEvent` | withdraw (all variants) | `storage_unit_id, owner_cap_id, type_id, quantity` |
| inventory | `ItemTransferEvent` | owner-to-owner transfer | `from_owner_cap_id, to_owner_cap_id, type_id, quantity` |
| inventory | `InventoryCreatedEvent` | new inventory DF | `storage_unit_id, owner_cap_id, max_capacity` |
| inventory | `ItemCreatedEvent` | item bridged from game | `type_id, quantity, volume` |
| network_node | `NetworkNodeCreatedEvent` | anchor | `network_node_id, type_id` |
| network_node | `AssemblyConnectedEvent` | connect assembly | `network_node_id, assembly_id` |
| energy | `EnergySourceCreatedEvent` | update_energy_source | `assembly_id, config fields` |
| fuel | `FuelDepositedEvent` | deposit_fuel | `network_node_id, type_id, quantity, volume` |
| fuel | `FuelBurnStartedEvent` | start burning | `network_node_id, burn_rate_ms` |
| fuel | `FuelBurnStoppedEvent` | stop burning | `network_node_id, remaining` |
| fuel | `FuelWithdrawnEvent` | withdraw_fuel | `network_node_id, type_id, quantity` |
| character | `CharacterCreatedEvent` | create_character | `character_id, address, tribe_id` |
| killmail | `KillMailCreatedEvent` | record kill | `victim_id, killer_id` |

### Missing Events (Gaps)

| Missing Event | Where It Should Fire | Impact |
|---------------|---------------------|--------|
| `ExtensionAuthorizedEvent` | `authorize_extension` (gate/ssu/turret) | **HIGH** — policy deployment invisible |
| `SponsorAddedEvent` | `add_sponsor_to_acl` | **MEDIUM** — ACL changes invisible |
| `TribeUpdatedEvent` | `update_tribe` | **LOW** — admin-only, not player-facing |
| `OwnerCapTransferredEvent` | `transfer_owner_cap*` | **LOW** — cap transfers invisible |
| `PermitIssuedEvent` / `PermitDeniedEvent` | `issue_jump_permit` / abort | **CC extension responsibility** — not world-contracts |

---

## Appendix: Builder Scaffold Divergence from v0.0.15

| Scaffold Pattern | v0.0.15 Reality | Impact |
|-----------------|-----------------|--------|
| `withdraw_by_owner(ssu, char, admin_acl, owner_cap, type_id, ctx)` | `withdraw_by_owner(ssu, char, owner_cap, type_id, quantity, ctx)` — no AdminACL, added `quantity: u32` | **Breaking** — scaffold code won't compile |
| `deposit_item(ssu, char, admin_acl, owner_cap, item, ctx)` | `deposit_item<Auth>(ssu, char, item, Auth{}, ctx)` — Auth witness, no AdminACL/OwnerCap | **Breaking** — signature completely different |
| No `deposit_to_owned` | New function for cross-player delivery | **Missing feature** — scaffold doesn't show async trade pattern |
