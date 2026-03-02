# Turret Closed-World Constraint: Clarified Reference

**Retention:** Carry-forward

> **Date:** 2026-03-02
> **Source:** `vendor/world-contracts/contracts/world/sources/assemblies/turret.move` (v0.0.14, 678 lines), `vendor/world-contracts/contracts/extension_examples/sources/turret.move` (65 lines), `vendor/world-contracts/ts-scripts/turret/get-priority-list.ts`
> **Method:** Direct code inspection with line-level citations. Evidence classified as **code-proven** or **runtime-unverified**.
> **Supersedes:** Turret sections in turret-contract-surface.md, turret-project-semantics-and-mismatches.md (which remain as supporting detail).

---

## 1. The Closed-World Constraint

Turret extensions are **stateless pure functions** over candidate data. The game engine constructs the targeting PTB with a fixed 4-argument signature. Extensions cannot receive additional objects, read dynamic fields, or access persistent configuration at targeting time.

### Enforcement layers

| Layer | What it enforces | Classification |
|-------|-----------------|----------------|
| **Game engine PTB** | Exactly 4 arguments passed to the extension function | **Code-proven** (TS reference at `ts-scripts/turret/get-priority-list.ts` L200-212) |
| **OnlineReceipt hot-potato** | Receipt must be consumed via `destroy_online_receipt<Auth>`, coupling the extension to the turret lifecycle | **Code-proven** (`turret.move` L135-140) |
| **No uid() accessor** | `Turret.id` field is private; no public function returns `&UID`, blocking all DF reads/writes | **Code-proven** (grep: zero `public fun uid` in `assemblies/`) |
| **Move type system** | Does NOT enforce the signature. An extension can define a 5th param and it compiles. | **Code-proven** (Move has no trait/interface system; packages are independent) |

**Summary:** Move allows extra parameters. The game engine rejects them at runtime (PTB arg count mismatch). The constraint is runtime-enforced, not compile-time.

---

## 2. Fixed 4-Argument Signature

### Default (world module)

```move
// turret.move L254-272
public fun get_target_priority_list(
    turret: &Turret,
    owner_character: &Character,
    target_candidate_list: vector<u8>,  // BCS of vector<TargetCandidate>
    receipt: OnlineReceipt,             // hot-potato from verify_online
): vector<u8>                           // BCS of vector<ReturnTargetPriorityList>
```

The default version aborts with `EExtensionConfigured` (code 7) if `turret.extension` is `Some`. The game engine must call the extension's version instead.

### Extension example

```move
// extension_examples/turret.move L44-63
public fun get_target_priority_list(
    turret: &Turret,
    _: &Character,
    target_candidate_list: vector<u8>,
    receipt: OnlineReceipt,
): vector<u8>
```

Identical 4-arg signature. The extension consumes the receipt via `turret::destroy_online_receipt(receipt, TurretAuth {})`.

### Game engine PTB construction

From `ts-scripts/turret/get-priority-list.ts` L196-213 (TypeScript reference implementation):

1. Calls `world::turret::verify_online(turret)` to obtain `OnlineReceipt`
2. Calls `<extension>::turret::get_target_priority_list(turret, character, candidates_bcs, receipt)` with exactly 4 arguments
3. Module name hardcoded as `"turret"`, function name hardcoded as `"get_target_priority_list"`
4. No parameter discovery mechanism. No extension object registry.

**Classification:** Code-proven. The TS reference is the only known documentation of the calling convention (official builder docs for turrets are `// TODO` stubs).

---

## 3. Why uid() Absence Blocks DF Reads/Writes

Dynamic field operations (`sui::dynamic_field::borrow`, `add`, `remove`) all require `&UID` or `&mut UID`. The Turret struct's `id: UID` field is private.

| Method | Works? | Why |
|--------|--------|-----|
| `object::id(turret)` | Returns `ID` (copyable value) | Not `&UID`; cannot call DF ops |
| `turret.uid()` | Does not exist | No public accessor |
| Extension writes DF at setup time | No | `authorize_extension` only stores TypeName; no `&mut UID` exposed |

The same limitation applies to Gate: no `uid()` accessor on Gate either. Gate extensions work around this by passing `&ExtensionConfig` (a separate shared object) into the function. Turret extensions cannot receive `&ExtensionConfig` because the game engine doesn't pass it.

**Classification:** Code-proven.

### Five blocked state-access paths

| Path | Mechanism | Blocked by |
|------|-----------|------------|
| DFs on Turret | `dynamic_field::borrow(&turret.id, ...)` | `Turret.id` private, no `uid()` |
| ExtensionConfig as param | `extension_config: &ExtensionConfig` | Game engine passes exactly 4 args |
| Module-level mutable state | Module globals | Sui Move has no module-level mutable state |
| Additional function params | 5th param for arbitrary data | Move compiles; game engine PTB rejects at runtime |
| Precomputed config on turret | Write DFs at setup, read at targeting | Write blocked (no `&mut UID`), read blocked (no `&UID`) |

---

## 4. Gate vs Turret Extension Asymmetry

This is the root cause of all per-project feasibility outcomes.

| Property | Gate Extension | Turret Extension |
|----------|---------------|-----------------|
| **PTB constructor** | Player (client-side) | Game engine (server-side) |
| **Function signature** | Arbitrary (extension author defines) | Fixed 4-arg |
| **Can pass shared objects** | Yes (player includes them) | No (game engine doesn't know about them) |
| **Stateful logic** | Yes (reads ExtensionConfig DFs, Coin objects, Clock, etc.) | No (pure function over candidate data) |
| **Example** | `tribe_permit.move` L55: `extension_config: &ExtensionConfig` | `extension turret.move` L49: no config param |

**Classification:** Code-proven. Gate extension signatures verified across `builder-scaffold/smart_gate/` and `extension_examples/`.

---

## 5. Default Targeting Behavior Matrix

Source: `turret.move` `effective_weight_and_excluded` (L632-653)

**Constants:** `STARTED_ATTACK_WEIGHT_INCREMENT = 10000`, `ENTERED_WEIGHT_INCREMENT = 1000`

**BehaviourChangeReason wire values:** UNSPECIFIED=0, ENTERED=1, STARTED_ATTACK=2, STOPPED_ATTACK=3

**Logic:**
- Step 1: `excluded = same_tribe && !is_aggressor` (base tribal exclusion)
- Step 2: Branch on reason (STOPPED_ATTACK forces `excluded = true`; STARTED_ATTACK adds +10000; ENTERED adds +1000 if `!same_tribe || is_aggressor`)

Let W = incoming `priority_weight`.

| # | Tribe | Aggressor | Reason | Included? | Weight |
|:-:|:-----:|:---------:|--------|:---------:|--------|
| 1 | same | no | ENTERED | **EXCLUDED** | n/a |
| 2 | same | no | STARTED_ATTACK | **EXCLUDED** | n/a |
| 3 | same | no | STOPPED_ATTACK | **EXCLUDED** | n/a |
| 4 | same | yes | ENTERED | **INCLUDED** | W + 1000 |
| 5 | same | yes | STARTED_ATTACK | **INCLUDED** | W + 10000 |
| 6 | same | yes | STOPPED_ATTACK | **EXCLUDED** | n/a |
| 7 | diff | no | ENTERED | **INCLUDED** | W + 1000 |
| 8 | diff | no | STARTED_ATTACK | **INCLUDED** | W + 10000 |
| 9 | diff | no | STOPPED_ATTACK | **EXCLUDED** | n/a |
| 10 | diff | yes | ENTERED | **INCLUDED** | W + 1000 |
| 11 | diff | yes | STARTED_ATTACK | **INCLUDED** | W + 10000 |
| 12 | diff | yes | STOPPED_ATTACK | **EXCLUDED** | n/a |

**Summary:** Default = **tribe_only + universal de-escalation**.
- Same-tribe non-aggressors: always excluded (rows 1-3)
- STOPPED_ATTACK: always excluded regardless of tribe/aggressor (rows 6, 9, 12)
- All other outsiders/aggressors: included with weight boosts

**Edge cases:**
- Weight=0 does NOT cause exclusion. Only the `excluded` flag matters. A target with weight=0 in the return list will be shot (lowest priority).
- UNSPECIFIED (wire value 0) falls through with no modification to weight or exclusion state.

**Classification:** Code-proven.

---

## 6. CivilizationControl Alignment Verdict

### tribe_only policy: EXACT MATCH

The CC gate extension's `tribe_only` preset allows same-tribe pilots and blocks outsiders. Default turret behavior excludes same-tribe non-aggressors (rows 1-3) and includes outsiders (rows 7-8, 10-11). These are complementary: gate allows tribe in, turret ignores tribe.

**No custom turret extension is needed for CC MVP.**

### Toll payer mismatch: STRUCTURAL GAP

A non-tribe pilot who pays the CC coin toll will pass through the gate (permitted by `CoinTollRule`). However, the default turret will still target that pilot because:
- The turret has no concept of toll payment
- The turret extension cannot access `CoinTollRule` state (closed-world constraint)
- `character_tribe` is the only tribal signal available in `TargetCandidate`

**Impact:** For tribe_only MVP, this gap does not materialize (toll payers are outsiders who accepted the risk). For future mixed policies (tribe + toll), this creates an inconsistency where the gate says "welcome" but the turret says "target."

**Classification:** Code-proven (constraint). Runtime-unverified (no game server to test toll payer flow end-to-end with turrets).

---

## 7. Per-Project Feasibility

### CivilizationControl

| Dimension | Assessment |
|-----------|------------|
| Classification | `unnecessary` for MVP |
| Custom extension? | No. Default behavior = tribe_only. |
| Confidence | **High** (code-proven) |
| Remaining risk | Non-tribe toll payer mismatch. No impact on tribe_only MVP. |

### CargoBond (Atomic Courier)

| Dimension | Assessment |
|-----------|------------|
| Classification | `structurally impossible` |
| What was wanted | Bonded couriers deprioritized/excluded by client turrets along delivery route |
| Why blocked | Extension cannot look up `CourierJob` bond state. Not in 4-arg signature, no UID for DF reads, no config parameter. |
| Workaround? | No on-chain workaround. Gate permits remain the sole route protection. |
| Confidence | **High** (code-proven) |

### Fortune Gauntlet

| Dimension | Assessment |
|-----------|------------|
| Classification | `structurally impossible` |
| What was wanted | Gauntlet denial marks player for elevated turret targeting (consequence layer) |
| Why blocked | Denial state (PlayerProgress DFs on ExtensionConfig) is unreachable from turret. Cross-extension state sharing not supported. |
| Workaround? | Partial: escalating cooldown, permanent deny, GauntletDenialEvent for off-chain indexing. |
| Confidence | **High** (code-proven) |

---

## 8. What Would Unlock This

Either of these world-contracts changes would unlock stateful turret extensions for all three projects:

| Change | Effect | Hackathon builder control? |
|--------|--------|---------------------------|
| Add `public fun uid(&Turret): &UID` | Extensions can read/write DFs on turret. Precomputed config at setup time becomes readable at targeting time. | No (requires world-contracts update by CCP) |
| Add `&ExtensionConfig` as 5th argument | Game engine passes the extension's shared config object. Extensions can read DFs on config. | No (requires game engine + world-contracts update) |

Neither change is within hackathon builder scope. The DF pattern already exists for gates and would transfer cleanly to turrets given either surface change.

---

## 9. Validation Status

Validation checklist: [turret-localnet-validation-checklist.md](../operations/turret-localnet-validation-checklist.md) (45 test cases)

| Classification | Count | What's needed |
|----------------|-------|---------------|
| EXECUTABLE NOW | 8 | Source review, compile checks, publish verification |
| ENVIRONMENT-BLOCKED | 36 | Game-engine-provisioned objects (ObjectRegistry, NetworkNode, Character, AdminACL, EnergyConfig) |
| STRUCTURALLY IMPOSSIBLE | 1 | A-05: bond/scoring in turret extension (closed-world constraint) |

**Runtime-unverified items** (require March 11 test server):
- End-to-end default targeting with live candidates (D-01 through D-09)
- PriorityListUpdatedEvent emission and content verification (O-01, O-02)
- Online/offline lifecycle with real EnergyConfig (L-01 through L-06)
- Extension authorization on live turret objects (E-01 through E-04)
