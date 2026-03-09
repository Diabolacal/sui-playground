# Gate & Turret Access Control Integration with Cargo Bond (Atomic Courier) — Feasibility Report

**Retention:** Sandbox-only

> Derived from canonical source: `vendor/world-contracts/contracts/world/` Move modules at current HEAD  
> Date: 2026-03-02

---

## Table of Contents

1. [Gate Access Integration](#1-gate-access-integration)
2. [Time-Bounded Permits](#2-time-bounded-permits)
3. [AdminACL Requirements](#3-adminacl-requirements)
4. [Turret Integration](#4-turret-integration)
5. [The "Accept Job → Grant Access" PTB](#5-the-accept-job--grant-access-ptb)
6. [The "Job Complete/Expire → Revoke Access" Flow](#6-the-job-completeexpire--revoke-access-flow)
7. [Cross-Extension Composition Risks](#7-cross-extension-composition-risks)
8. [Overall Feasibility Verdict](#8-overall-feasibility-verdict)

---

## 1. Gate Access Integration

### Can an extension issue jump permits automatically?

**Yes.** This is the primary design intent of the gate extension pattern.

**What's required:**

| Requirement | Source |
|---|---|
| `Auth` witness type with `drop` ability | [gate.move L240](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — `issue_jump_permit<Auth: drop>` |
| Auth witness must be minted by the extension package | [config.move L87](../../../vendor/builder-scaffold/move-contracts/smart_gate/sources/config.move) — `public(package) fun x_auth(): XAuth` |
| Source gate must have `extension == Some(type_name::with_defining_ids<Auth>())` | [gate.move L248-249](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — asserts extension is Some |
| Destination gate must have the **same** `Auth` type from the **same** package | [gate.move L254-259](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — asserts destination extension matches source |
| Both `Gate` objects (shared, read-only refs) | [gate.move L241-242](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — `source_gate: &Gate, destination_gate: &Gate` |
| `Character` object (shared, read-only ref) | [gate.move L243](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — `character: &Character` |
| **No** AdminACL needed | Confirmed: `issue_jump_permit` does NOT call `verify_sponsor`. No `admin_acl` parameter. |
| **No** OwnerCap needed | Confirmed: No `OwnerCap<Gate>` parameter in signature. |

**Mechanism:** The Atomic Courier extension module defines its own `XAuth` type ([config.move L19-20](../../../experiments/atomic_courier_experiment/sources/config.move)), mints it via `public(package) fun x_auth()`, and passes it to `gate::issue_jump_permit<XAuth>()`. The `drop` ability means the witness is consumed in the call.

**The existing atomic courier experiment already has this pattern:** [config.move L31](../../../experiments/atomic_courier_experiment/sources/config.move) — `public(package) fun x_auth(): XAuth { XAuth {} }`.

### Can the Atomic Courier extension be authorized on gates AND SSUs simultaneously?

**Yes, with a critical constraint.** Both `Gate` and `StorageUnit` support exactly **one** extension at a time via `extension: Option<TypeName>`:

- Gate: [gate.move L82](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — `extension: Option<TypeName>`
- SSU: [storage_unit.move L76](../../../vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move) — `extension: Option<TypeName>`

Both use the same authorization pattern:
- `gate::authorize_extension<Auth: drop>(gate, owner_cap)` — [gate.move L119-121](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move)
- `storage_unit::authorize_extension<Auth: drop>(ssu, owner_cap)` — [storage_unit.move L91-96](../../../vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move)

**The same `XAuth` type from the same package** can be authorized on both a Gate and an SSU. The existing `corpse_gate_bounty.move` example demonstrates exactly this — it both operates on an SSU (`deposit_item<XAuth>`) and issues a gate jump permit (`issue_jump_permit<XAuth>`) in a single transaction: [corpse_gate_bounty.move L45-83](../../../vendor/builder-scaffold/move-contracts/smart_gate/sources/corpse_gate_bounty.move).

**Constraint:** Since each assembly supports only one extension, a gate/SSU can ONLY be controlled by the Atomic Courier extension OR by some other extension — not both simultaneously. The gate owner must explicitly choose to authorize the courier extension over any previous one. This is a `swap_or_fill` operation ([gate.move L121](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move)) — no event is emitted on replacement.

### Is cross-package extension composition possible?

**No.** Extension identity is determined by `type_name::with_defining_ids<Auth>()`, which includes the **defining package ID**. Two different packages produce different `TypeName` values even if the witness struct has the same name. Both gates in a linked pair must have the same extension type from the same package ([gate.move L254-259](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move)).

**Implication for Atomic Courier:** The courier extension must be a **single package** that contains all gate/SSU rule logic. It cannot delegate permit issuance to another package. The courier job system and the gate access logic MUST be in the same Move package.

---

## 2. Time-Bounded Permits

### Does JumpPermit have TTL/expiry fields?

**Yes.** `JumpPermit` has a built-in `expires_at_timestamp_ms` field:

```move
public struct JumpPermit has key, store {
    id: UID,
    character_id: ID,
    route_hash: vector<u8>,
    expires_at_timestamp_ms: u64,  // <-- built-in expiry
}
```
Source: [gate.move L86-92](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move)

Validation checks this against the Clock: [gate.move L710](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — `assert!(jump_permit.expires_at_timestamp_ms > clock.timestamp_ms(), EJumpPermitExpired)`

### Can the courier job deadline serve as implicit expiry?

**Yes, this is the recommended approach.** When issuing a permit on job acceptance, set `expires_at_timestamp_ms = job.deadline_ms`. This creates a natural linkage:

- Permit expires at the same time the job expires
- No separate revocation mechanism needed for time-bounding
- If the courier doesn't complete the job in time, the permit becomes unusable

The existing `tribe_permit.move` example shows the pattern: `expires_at_timestamp_ms = clock.timestamp_ms() + expiry_duration_ms` ([tribe_permit.move L76-77](../../../vendor/builder-scaffold/move-contracts/smart_gate/sources/tribe_permit.move)).

### Additional consideration: JumpPermit is single-use

**Critical:** The permit is **consumed (deleted)** on use ([gate.move L724-725](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move)). A courier needing multiple jumps (e.g., through gate A → B, then through gate B → C) requires **one permit per jump**. There is a TODO comment suggesting multi-use permits may be supported in the future ([gate.move L722-723](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move)), but currently permits are strictly single-use.

**Implication:** On job acceptance, the system should issue all route permits upfront (one per gate pair in the route), all with the same `expires_at_timestamp_ms = job.deadline_ms`. Alternatively, permits could be issued on-demand as the courier approaches each gate.

---

## 3. AdminACL Requirements

### Which operations need AdminACL?

| Operation | Needs AdminACL? | Source |
|---|---|---|
| `issue_jump_permit` | **No** | [gate.move L240-278](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — no `admin_acl` param |
| `jump` (no extension) | **Yes** | [gate.move L281-289](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — calls `admin_acl.verify_sponsor(ctx)` |
| `jump_with_permit` | **Yes** | [gate.move L294-305](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — calls `admin_acl.verify_sponsor(ctx)` |
| `link_gates` | **Yes** | [gate.move L172-176](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — calls `admin_acl.verify_sponsor(ctx)` |
| `authorize_extension` | **No** | [gate.move L119-121](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — only needs `OwnerCap<Gate>` |
| `anchor` (create gate) | **Yes** (implied) | [gate.move L424](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — uses `admin_acl` internally via `create_owner_cap_by_id` |
| SSU `deposit_item` | **No** (extension-path) | [storage_unit.move L174-185](../../../vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move) — uses `Auth` witness |
| SSU `withdraw_item` | **No** (extension-path) | [storage_unit.move L200-211](../../../vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move) — uses `Auth` witness |

**Key insight:** `issue_jump_permit` does NOT need AdminACL — this is a **major architectural advantage**. The courier system can issue permits without the courier being in any ACL. However, `jump_with_permit` DOES need AdminACL (the actual jump transaction must be sponsored). This is an EVE Frontier platform requirement, not something the extension controls.

### Can AdminACL entries be added/removed programmatically?

**Add: Yes, but requires GovernorCap.** `add_sponsor_to_acl` requires `&GovernorCap`: [access_control.move L198-203](../../../vendor/world-contracts/contracts/world/sources/access/access_control.move).

**Remove: No function exists.** There is **no** `remove_sponsor_from_acl` function in the current codebase. The comment at [access_control.move L9](../../../vendor/world-contracts/contracts/world/sources/access/access_control.move) says "Governor can add/remove sponsors" but only `add_sponsor_to_acl` is implemented. `remove_server_address` exists ([access_control.move L249-253](../../../vendor/world-contracts/contracts/world/sources/access/access_control.move)) but that's for the ServerAddressRegistry, not AdminACL.

**Implication:** Temporary ACL membership is NOT feasible with current world-contracts. You cannot add a courier to AdminACL on job acceptance and remove them on job completion — removal isn't possible programmatically.

### Is temporary ACL membership feasible?

**No, not with the current AdminACL design.** Even if removal existed, `add_sponsor_to_acl` requires `GovernorCap` (deployer-only singleton), making it unsuitable for per-job automation. The courier system cannot call this function — it would require the world deployer's cooperation.

**Workaround:** This is not actually a problem for the courier system. The courier does NOT need to be in AdminACL to receive or hold permits. AdminACL is only needed for `jump_with_permit`, and that's handled by the EVE Frontier game server's transaction sponsorship infrastructure, not by the extension. The game server (which operates as a sponsor) signs all jump transactions. The courier just needs a valid `JumpPermit`.

---

## 4. Turret Integration

(Updated 2026-03-02 after turret support confirmed in world-contracts v0.0.14.)

### Do turrets have extension/access control hooks?

**Yes.** Turret assembly exists in `turret.move` (678 lines) with the same `authorize_extension<Auth>` + `swap_or_fill` pattern as Gate. However, turrets control **targeting priority**, not allow/deny access.

### Can turret targeting rules be modified by an extension?

**Yes, but with a closed-world constraint.** The extension's `get_target_priority_list` function has a fixed 4-argument signature: `(turret, character, candidates_bcs, receipt)`. It cannot access external objects, ExtensionConfig, or dynamic fields (no `uid()` accessor on Turret). Extensions are pure functions over candidate data.

### What's the turret assembly's access control model?

`OwnerCap<Turret>` follows the same pattern as `OwnerCap<Gate>`. Authorize extension, online/offline, and unanchor require owner capability. Default targeting applies tribe-based filtering: same-tribe non-aggressors excluded, different-tribe and aggressors receive priority boost.

### Turret Integration Verdict

**Not feasible for bond-aware targeting.** Turret extensions exist but the closed-world constraint prevents identity-specific policies. Default tribe-based targeting operates independently and requires no courier integration. ~~Previously labeled "Partially feasible" and recommended framing turret safe-passage as a "product vision statement backed by events" — since corrected: do not frame turret safe-passage as a product feature; it is architecturally blocked.~~

See [turret-contract-surface.md](turret-contract-surface.md) for full analysis.

---

## 5. The "Accept Job → Grant Access" PTB

### What would this transaction look like?

A single PTB when a courier calls `accept_job`, the extension simultaneously issues jump permits:

```
PTB Steps:
1. courier_escrow::accept_job(&mut job, collateral_coin, &clock, ctx)
   → Transitions job Posted → Active
   → Emits JobAcceptedEvent
   → Sends JobReceipt to courier

2. courier_extension::issue_route_permits(
       &job,              // read job to get deadline_ms for permit expiry
       &source_gate,      // gate A (read-only)
       &dest_gate,        // gate B (read-only)
       &character,        // courier's character (read-only)
       &clock,            // for current timestamp validation
       ctx
   )
   → Internally calls gate::issue_jump_permit<XAuth>(
       source_gate, dest_gate, character,
       config::x_auth(),       // witness
       job.deadline_ms,        // expires when job expires
       ctx
   )
   → JumpPermit transferred to character.character_address()
```

### How many objects need to be passed?

| Object | Kind | Mutable? |
|---|---|---|
| `CourierJob` | Shared | Yes (state transition) |
| `Coin<SUI>` (collateral) | Owned | Yes (consumed) |
| `Clock` | System | No |
| `ExtensionConfig` | Shared | No |
| Source `Gate` | Shared | No |
| Destination `Gate` | Shared | No |
| `Character` (courier) | Shared | No |

**Total: 7 objects.** Only 1 is mutably shared (`CourierJob`), minimizing contention. The `Coin<SUI>` is owned and consumed. All remaining objects are read-only shared references.

For multi-hop routes (N gate pairs), add 2 shared read-only Gate objects per additional hop. The PTB stays well within the 1000 command limit.

### Is it realistic in a single PTB?

**Yes.** This is well within PTB limits:
- ~3–5 Move calls (accept_job + 1 permit issuance per gate pair)
- 7+ shared objects but only 1 mutably touched (CourierJob)
- Well under the 1000 command limit
- Object count scales linearly with route hops

The `corpse_gate_bounty.move` example already demonstrates a comparable multi-operation PTB (SSU withdraw + SSU deposit + gate permit issuance in one call): [corpse_gate_bounty.move L45-83](../../../vendor/builder-scaffold/move-contracts/smart_gate/sources/corpse_gate_bounty.move).

### What permissions must the job creator pre-configure?

1. **Authorize the courier extension on all route gates:** The job creator must call `gate::authorize_extension<atomic_courier::XAuth>(gate, owner_cap)` for every gate in the route. This requires the creator to own (via Character) the `OwnerCap<Gate>` for each gate.

2. **Both gates in each linked pair must have the same extension:** [gate.move L254-259](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) — the extension checks both sides match.

3. **Gates must be linked and online:** `jump_internal` checks both gates are online and linked ([gate.move L700-703](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move)).

4. **No AdminACL setup needed for permit issuance.** The creator does NOT need to add the courier to any ACL. Permits are issued by the extension, not by ACL membership.

**Critical constraint:** The job creator can only authorize the courier extension on gates **they own** (via OwnerCap). If the route passes through gates owned by other players, those players must independently authorize the same extension. This is a significant coordination challenge.

---

## 6. The "Job Complete/Expire → Revoke Access" Flow

### How would access revocation work?

**Primary mechanism: Natural expiry.** JumpPermits have `expires_at_timestamp_ms`, and validation enforces this via `clock.timestamp_ms()` comparison ([gate.move L710](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move)). Setting permit expiry to `job.deadline_ms` means:

- **Job completes before deadline:** Unused permits naturally expire at job deadline. No active revocation needed — permits just become useless.
- **Job expires:** Permits expire simultaneously. Anyone calling `expire_job` on the courier escrow also implicitly invalidates all route permits.
- **Job cancelled (Posted state only):** No permits exist yet since acceptance hasn't occurred.

**Secondary mechanism (active revocation): Extension swap.** The gate owner could call `authorize_extension<SomeOtherAuth>()` to replace the courier extension with a different one. This would invalidate all outstanding permits from the courier extension because `jump_with_permit` → `validate_jump_permit` checks the extension type. However, this is **destructive** — it disables ALL couriers using that extension on that gate, not just one specific courier.

**There is no per-permit revocation mechanism.** Permits are owned objects transferred to the character's wallet. The issuer cannot recall or delete them once transferred.

### Can it be automated or does it require manual trigger?

**Natural expiry is fully automated** — no trigger needed. The Clock-based check in `validate_jump_permit` handles it.

**Active extension swap is manual** — requires the gate owner to submit a transaction with their `OwnerCap<Gate>`.

### What happens if access ISN'T revoked (fail-safe)?

**Permits self-expire.** The time-bound design provides a fail-safe:
- If `expires_at_timestamp_ms = job.deadline_ms`, the courier can only use permits until the job deadline
- Even if the job is completed early and the courier retains unused permits, they expire at the job deadline
- There is NO way for a permit to be used after `expires_at_timestamp_ms` — the on-chain validation enforces this

**Remaining risk:** Between job completion and permit expiry, the courier could still jump through gates using remaining unused permits. This window could be narrowed by setting a shorter `expires_at_timestamp_ms` (e.g., `deadline_ms - buffer`), but it cannot be eliminated without a per-permit revocation mechanism.

**Also:** Permits are **single-use** ([gate.move L724-725](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move)). Once used, they're deleted. A courier with 3 route permits can make at most 3 jumps total.

---

## 7. Cross-Extension Composition Risks

### Can one package's extension authorize operations on another package's assemblies?

**No.** Extension authorization is per-package via `type_name::with_defining_ids<Auth>()`:

- `issue_jump_permit` checks that **both** gates have the calling package's Auth type ([gate.move L248-259](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move))
- SSU operations (`deposit_item`, `withdraw_item`) similarly check the extension type ([storage_unit.move L183-184](../../../vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move))

A package can only operate on assemblies where its own `XAuth` type has been authorized. Package A cannot issue permits for gates authorized with Package B's extension.

### Package upgrade implications

`type_name::with_defining_ids<Auth>()` returns the **defining package ID** (the original package where the type was first published). From SUI docs, this means:

- **Upgrades are safe:** A package upgrade creates a new package ID, but types retain their original defining package ID. An upgraded courier extension would still produce the same `TypeName` for `XAuth`.
- **Republishing is NOT safe:** If the extension is published as a new package (not upgraded), all gates must be re-authorized with the new `XAuth` type.

### Namespace collision risks

**Low.** Each package has a unique ID on-chain. Even if two packages define `XAuth`, their `TypeName` values differ because of the package ID component. There is no collision risk.

### Single extension slot constraint

**This is the most significant composition risk.** Each gate/SSU has exactly one `extension: Option<TypeName>` slot ([gate.move L82](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move)). If a gate already has a different extension (e.g., a tribe-gating extension), authorizing the courier extension **replaces** it. There is no way to have two extensions active simultaneously.

**Design consequence:** The courier extension must either:
1. **Be the sole extension** on sponsored-route gates (job creator dedicates gates to courier traffic)
2. **Incorporate other gating rules** within its own logic (compose rules within one package)
3. **Use a meta-extension pattern** — a single extension package that dispatches to multiple rule sets via dynamic fields (increases complexity significantly)

---

## 8. Overall Feasibility Verdict

### Fully viable in hackathon scope (1-2 days)?

**Partially.** Gate access integration via permit issuance is viable. Turret integration is out of scope (closed-world constraint). The single-extension-slot constraint creates UX friction but is not a blocker for a demo.

### What's viable?

| Feature | Viable? | Effort | Notes |
|---|---|---|---|
| Issue permits on job acceptance | **Yes** | ~4h | Extend `courier_escrow` or add new module in same package |
| Time-bound permits to job deadline | **Yes** | ~1h | Pass `job.deadline_ms` as `expires_at_timestamp_ms` |
| Single-hop route permits | **Yes** | ~2h | One gate pair per job |
| Multi-hop route permits | **Stretch** | ~4h | Multiple `issue_jump_permit` calls in one PTB |
| Turret whitelist integration | **Not feasible** (bond-aware) / **Default** (tribe-based) | 0h | Tribe-based targeting is default behavior; no integration needed. ~~Previously "Partially feasible, ~4h" — since corrected.~~ |
| Per-courier ACL management | **No** | N/A | No `remove_sponsor_from_acl`; GovernorCap-only add |
| Active permit revocation | **No** | N/A | No mechanism in world-contracts |

### What should be deferred to Phase 2?

1. **Turret integration** — turret extensions exist (v0.0.14) but closed-world constraint prevents bond-aware targeting. Default tribe-based targeting operates independently; no integration work needed or possible. ~~Previously listed as deferred to Phase 2 — since corrected: out of scope, not deferred.~~
2. **Multi-hop routing** — viable but adds complexity; single-hop demo is sufficient
3. **Active revocation** — time-bound expiry is sufficient; true revocation would require world-contracts changes or a custom permit wrapper
4. **Cross-player gate authorization** — coordinating extension authorization across gates owned by different players is a UX/governance problem, not a technical blocker
5. **Meta-extension composition** — combining courier gating rules with other extension types in a single package

### What can be credibly mocked?

1. ~~**Turret "safe passage"**~~ — **Out of scope.** ~~Previously recommended product vision copy: "Active courier bonds influence turret targeting via tribe-aligned priority rules." This is factually incorrect — courier bonds have zero influence on turret targeting. Tribe membership affects targeting independently of bond status.~~ Note that tribe-based turret targeting is the default behavior in EVE Frontier's world-contracts. Couriers who share the gate owner's tribe benefit from this automatically — no bond dependency or integration is involved.
2. **Multi-hop routing** — Demo with single-hop but describe multi-hop in the product vision. The PTB structure scales naturally.
3. **Active revocation** — Describe as "future enhancement: instant revocation via permit burn" but note that time-bound expiry provides the primary fail-safe today.
4. **Cross-player gate federation** — Describe a governance model where allied gate owners pre-authorize the courier extension, enabling a shared transit network. This is technically possible today (each owner calls `authorize_extension`) but the coordination UX doesn't exist.

### Recommended approach for the product vision document

**Implement (for hackathon submission):**
- Combine `courier_escrow` and gate permit issuance into a single package sharing one `XAuth` witness
- On `accept_job`: issue a `JumpPermit` with `expires_at_timestamp_ms = job.deadline_ms` for the specified gate pair
- On `complete_job`: no active revocation needed — permits expire naturally
- Demo flow: Post job → Courier accepts (gets receipt + jump permit) → Courier uses permit to jump → Courier completes delivery → Economic settlement

**Describe (in product vision, not implemented):**
- Multi-hop route permit bundles
- Cross-player gate federation / transit treaties
- Active permit revocation for early termination
- Meta-extension pattern for composing courier rules with other gate logic

**Explicit Non-Goals:**
- Turret safe-passage for non-tribe couriers — not feasible with current turret calling convention (see `turret-closed-world-clarified.md`)

**Key architectural claim to make in docs:**
> The Cargo Bond system leverages EVE Frontier's typed-witness extension pattern to programmatically issue time-bounded gate transit permits on job acceptance. Permits naturally expire at the job deadline, providing fail-safe access revocation without requiring active cleanup. The single-use permit model ensures couriers cannot stockpile transit rights beyond their active contract.

---

## Appendix: Key Source References

| File | Key Lines | What |
|---|---|---|
| [gate.move](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | L82 | `extension: Option<TypeName>` — single extension slot |
| [gate.move](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | L86-92 | `JumpPermit` struct with `expires_at_timestamp_ms` |
| [gate.move](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | L119-121 | `authorize_extension` — `swap_or_fill`, OwnerCap only |
| [gate.move](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | L240-278 | `issue_jump_permit` — Auth witness + both gates must match, NO AdminACL |
| [gate.move](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | L294-305 | `jump_with_permit` — requires AdminACL (verify_sponsor) |
| [gate.move](../../../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) | L706-725 | `validate_jump_permit` — expiry check, route hash, single-use delete |
| [access_control.move](../../../vendor/world-contracts/contracts/world/sources/access/access_control.move) | L153-161 | `verify_sponsor` — falls back to sender when no sponsor |
| [access_control.move](../../../vendor/world-contracts/contracts/world/sources/access/access_control.move) | L198-203 | `add_sponsor_to_acl` — GovernorCap required, no removal function |
| [storage_unit.move](../../../vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move) | L91-96 | SSU `authorize_extension` — same pattern as Gate |
| [config.move](../../../experiments/atomic_courier_experiment/sources/config.move) | L19-31 | Courier experiment already has `XAuth` + `public(package) x_auth()` |
| [courier_escrow.move](../../../experiments/atomic_courier_experiment/sources/courier_escrow.move) | L1-339 | Full job lifecycle: Post → Accept → Complete/Expire/Cancel |
| [tribe_permit.move](../../../vendor/builder-scaffold/move-contracts/smart_gate/sources/tribe_permit.move) | L58-80 | Reference: extension issuing permit with computed expiry |
| [corpse_gate_bounty.move](../../../vendor/builder-scaffold/move-contracts/smart_gate/sources/corpse_gate_bounty.move) | L45-83 | Reference: SSU + Gate operations in single function |
