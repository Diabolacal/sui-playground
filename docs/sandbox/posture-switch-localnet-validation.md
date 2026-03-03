# Posture-Switch Localnet Validation Report

**Retention:** Sandbox-only

Validation of CivilizationControl "one-click" posture switching on Sui local devnet. This confirms that switching between **Open for Business** and **Defense Mode** (including gate policy + turret state toggle) is achievable in a **single PTB** (Programmable Transaction Block).

## Test Environment

| Component | Version / Detail |
|---|---|
| Sui CLI | v1.66.1 |
| Network | Local devnet (`sui start --with-faucet --force-regenesis`) |
| SDK | `@mysten/sui` ^1.24.0, Node.js v22 |
| World contracts | `vendor/world-contracts` v0.0.14 (combined publish with CC extension) |
| CC Extension | `cc_posture` (config.move + posture.move) — ExtensionConfig + posture DFs |

> **v0.0.15 update (2026-03-03):** world-contracts updated to v0.0.15. Gate/turret/access modules unchanged — posture-switch validation results remain valid. Key inventory changes: `withdraw_item` now takes `quantity: u32` + `ctx`, `deposit_item` validates `parent_id`, new `deposit_to_owned`. See decision-log 2026-03-03.

## Topology

Single-operator setup provisioned by `setup.ts`:

- **1 Character** (tribe=42, owned by admin address)
- **1 NetworkNode** (online, fueled, producing energy)
- **2 Gates** (both authorized with CC extension's `XAuth` witness)
- **2 Turrets** (connected to NetworkNode, initially OFFLINE)
- **Shared `ExtensionConfig`** with posture DFs (PostureConfig, TribeConfig, TollConfig)

## Test Results

### Round-Trip: BUSINESS → DEFENSE → BUSINESS

| Step | Expected State | Actual State | Strategy | TX Count | Latency | Pass |
|---|---|---|---|---|---|---|
| Baseline | BUSINESS, toll=yes, tribe=no, turrets=OFFLINE | ✅ Match | — | — | — | ✅ |
| BUSINESS → DEFENSE | DEFENSE, tribe=yes, toll=no, turrets=ONLINE | ✅ Match | **Single PTB** | **1** | 2255ms | ✅ |
| Verify DEFENSE | same | ✅ Match | — | — | — | ✅ |
| DEFENSE → BUSINESS | BUSINESS, toll=yes, tribe=no, turrets=OFFLINE | ✅ Match | **Single PTB** | **1** | 2754ms | ✅ |

### Latency Breakdown

Reported latencies include `~2000ms` for `waitForTransaction` (fullnode indexer sync). Actual on-chain execution time is **~250ms per PTB** based on digest-to-response timing.

## Single PTB Composition (Strategy A)

Each posture switch is a single PTB containing **7–9 Move calls** (depending on turret count):

### BUSINESS → DEFENSE (example)

1. `posture::set_posture(ext_config, admin_cap, DEFENSE=1)`
2. `posture::set_tribe_config(ext_config, admin_cap, tribe=42, expiry=300000ms)`
3. `posture::clear_toll_config(ext_config, admin_cap)`
4. `character::borrow_owner_cap<Turret>(character, receiving_ref_turret1)`
5. `turret::online(turret1, network_node, energy_config, owner_cap)`
6. `character::return_owner_cap<Turret>(character, owner_cap, receipt)`
7. Repeat 4–6 for turret2

### Key Patterns

- **OwnerCap borrow/return** (hot-potato): Each turret toggle requires a 3-call cycle (borrow → use → return). Multiple cycles compose in a single PTB without issue.
- **Dynamic field upsert**: `set_tribe_config` / `set_toll_config` use `add_or_set` pattern (check exists → remove + add, or just add). Safe to call regardless of prior state.
- **Clear functions**: Use `remove_if_exists` pattern — no abort if DF absent.
- **Status guards**: `turret::online()` aborts if already ONLINE; pre-check turret status off-chain and skip toggle if already in target state.

## Multi-TX Fallback (Strategy B)

Strategy B was implemented but **not needed** — Strategy A succeeded for both directions. The multi-tx approach splits into:

1. **Policy update TX**: set_posture + set/clear DFs
2. **Per-turret TXs**: One TX per turret toggle (borrow → toggle → return)

This would add ~250ms per additional TX but provides a fallback if single-PTB ever hits gas budget or object contention limits.

## Events Emitted

### PostureChangedEvent
```json
{"config_id": "0x2df8...", "old_mode": 0, "new_mode": 1}
```
Emitted by `posture::set_posture`. One event per switch.

### StatusChangedEvent
```json
{"action": {"variant": "ONLINE"}, "assembly_id": "0x0c5f...", "status": {"variant": "ONLINE"}}
```
Emitted by `status::online()` / `status::offline()`. One per turret toggle.

### Total Events per Posture Switch
- 1 `PostureChangedEvent`
- N `StatusChangedEvent` (N = number of turrets needing toggle)

## Prerequisites Discovered

The following setup steps are required before turret online/offline works:

1. **Fuel efficiency**: `fuel::set_fuel_efficiency(fuel_config, admin_acl, type_id, efficiency%)` — AdminACL auth
2. **Fuel deposit**: `network_node::deposit_fuel(nwn, admin_acl, owner_cap, type_id, volume, quantity, clock)` — AdminACL + OwnerCap auth
3. **NetworkNode online**: `network_node::online(nwn, owner_cap, clock)` — starts fuel burn, enables energy production
4. **Energy reservation**: `turret::online()` internally calls `energy::reserve_energy()` — requires NetworkNode to be producing energy (i.e., online and fueled)

Without steps 1–3, turret online aborts with `ENotProducingEnergy`.

## Known Constraints

| Constraint | Impact | Mitigation |
|---|---|---|
| Status guards abort on no-op | `online()` if already ONLINE aborts | Pre-check turret status off-chain, skip if already in target state |
| OwnerCap version sensitivity | `receivingRef` requires exact version/digest | Refresh cap versions before each PTB via `getObject()` |
| SharedObject version caching | SDK may cache stale versions between rapid TXs | `waitForTransaction()` after each TX, or add 1–2s delay |
| Gas coin version staleness | Rapid sequential TXs may hit stale gas coin | `waitForTransaction()` resolves this |
| Energy model prerequisite | Turrets need fueled+online NetworkNode | Setup script handles fuel + online in PTB2b |

## Conclusion

**One-click posture switching is confirmed feasible via single PTB.** The Move contract layer (world-contracts + cc_posture extension) composes cleanly:

- Gate policy update (posture mode + DFs) + turret state toggles fit in one PTB
- No AdminACL or GovernorCap needed for turret toggle — just OwnerCap
- No gas budget issues with 2 gates + 2 turrets + 3 DF mutations in one PTB
- Events provide full observability for UI feedback

### Files

| File | Purpose |
|---|---|
| `sandbox/posture-switch-validation/contracts/cc_posture/sources/config.move` | Extension config + XAuth witness |
| `sandbox/posture-switch-validation/contracts/cc_posture/sources/posture.move` | Posture DFs + events |
| `sandbox/posture-switch-validation/ts/src/setup.ts` | 5-PTB topology provisioning |
| `sandbox/posture-switch-validation/ts/src/posture-switch.ts` | Strategy A (single PTB) + Strategy B (multi-tx) |
| `sandbox/posture-switch-validation/ts/src/full-test.ts` | End-to-end orchestrator |
| `sandbox/posture-switch-validation/ts/src/utils.ts` | Shared utilities |
