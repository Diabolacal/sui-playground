# Turret API → Project Semantics Translation & Mismatch Analysis

**Retention:** Prep-only

> **Date:** 2026-03-02  
> **Inputs:** `vendor/world-contracts` turret.move (v0.0.14, 678 lines), extension_examples/turret.move, spec.md, implementation plan, cargo-bond product vision, fortune-gauntlet project vision, fortune-gauntlet feasibility, gate-turret-courier-access feasibility report  
> **Method:** Direct code inspection with line-level citations + project document comparison

---

## Critical Finding: Turret Extension Closed-World Constraint

**Before project-specific analysis, one architectural fact dominates all three projects.**

The turret extension function `get_target_priority_list` has a **fixed signature** dictated by the game's calling convention:

```move
public fun get_target_priority_list(
    turret: &Turret,              // read-only turret reference
    owner_character: &Character,   // turret owner's character
    target_candidate_list: vector<u8>,  // BCS of vector<TargetCandidate>
    receipt: OnlineReceipt,        // hot-potato proving online
): vector<u8>                      // BCS of vector<ReturnTargetPriorityList>
```

Source: [turret.move L254-264](../../vendor/world-contracts/contracts/world/sources/assemblies/turret.move) (default), [extension_examples/turret.move L49-55](../../vendor/world-contracts/contracts/extension_examples/sources/turret.move) (extension).

**The game constructs this call. The extension cannot add parameters.** This means:

| Can access | Cannot access |
|---|---|
| `TargetCandidate` fields (item_id, type_id, group_id, character_id, character_tribe, hp/shield/armor ratios, is_aggressor, priority_weight, behaviour_change) | External shared objects (ExtensionConfig, CivControlConfig, bond objects) |
| Owner character data (tribe via `character::tribe()`, address) | Dynamic fields on ANY external object |
| Turret view functions (status, location, type_id, extension type) | Custom extension state stored elsewhere |
| Turret ID (via `object::id(turret)`) | Turret UID for DF read/write (no `uid()` accessor — confirmed via code grep) |

**No UID accessor exists on Turret** — `df::borrow(&turret.id, key)` is impossible from external packages because `Turret.id` is a private field and no `public fun uid(&Turret): &UID` is provided.

**Consequence:** Turret extensions are **pure functions over the candidate list + owner character + turret metadata**. They cannot consult policy databases, bond records, gauntlet state, config singletons, or any other on-chain object not in the fixed argument list.

---

## 1. CivilizationControl

### Turret Role in CC

Per spec.md §1.1, CivilizationControl ships two modules: GateControl and TradePost. Turrets are not listed in the MVP scope. The implementation plan (civilizationcontrol-implementation-plan.md) does not mention turrets in any of its 45 atomic steps. The spec does not reference turret assemblies.

**Intended role (from task brief):** Turrets treated as the same enforcement layer as gates. Configuration hidden in demo. Presets apply to gates + turrets together. Turret is "silently aligned" with gate policy.

### How to Express "Gate Policy Equivalence"

CC has two gate policies in MVP:

| Gate Policy | What It Does | Turret Equivalent? |
|---|---|---|
| **Tribe Filter** | Allow only characters matching `tribe_id` | **Already the default behavior.** Default turret logic at [turret.move L631-650](../../vendor/world-contracts/contracts/world/sources/assemblies/turret.move): same tribe as owner AND not aggressor → excluded from priority list. Non-tribe → entered weight boost (+1000). Aggressors → attack weight boost (+10000). |
| **Coin Toll** | Charge SUI per jump, allow anyone who pays | **No turret equivalent.** Turret has no coin payment mechanism. Extension cannot read gate toll-payment status (closed-world constraint). A toll-payer who is NOT in the owner's tribe will still be targeted at default priority. |

**Key insight:** For the `tribe_only` preset, no custom turret extension is needed. The default turret behavior already deprioritizes tribe members — which is exactly what "gate allows tribe, turret ignores tribe" means.

### Implementation Approach

**Option A (Recommended — Zero turret code):** Don't write a turret extension. Use the default turret targeting behavior, which already tribe-filters correctly. When a preset is "tribe_only," the gate extension enforces tribe membership for permits, and the default turret automatically deprioritizes tribe members. They're already aligned.

**Option B (If explicit control needed):** Define `TurretAuth` in the CC package alongside `GateAuth`. Write a minimal `get_target_priority_list` that mirrors default behavior with one adjustment: return an EMPTY list (don't shoot anyone) when in "safe mode." But this only works for tribe-based filtering — the extension can't read the CC config to know WHICH mode is active (closed-world constraint).

**Option C (Theoretical — not recommended):** Pre-compute targeting rules and write them as DFs on the turret object. This requires a `uid()` accessor on Turret, which does not exist. **Not viable with current world-contracts.**

**Recommended approach: Option A.** The default turret behavior is the CC turret policy for tribe_only. The demo narrative is: "Turrets are silently aligned. When you set tribe-only on your gates, turrets automatically protect your tribe." This is true — it's just the default behavior, not custom logic.

### Demo Narrative

"Configuration exists but is not surfaced in demo" is accurate. The turret has no separate configuration UI because the default behavior is the desired behavior. Demo copy:

> "Your turrets recognize your tribe. Non-tribe ships entering your perimeter are engaged automatically. This is not a separate configuration — it's how your sovereignty operates."

This is factually correct: the default turret logic deprioritizes same-tribe, prioritizes non-tribe and aggressors.

### Mismatches

| Desired UX (CC) | Contract Reality | Mismatch Type | Resolution |
|---|---|---|---|
| Turrets align with gate policy presets | Default turret aligns with tribe_only; no alignment possible for coin_toll or allow/block list | **Design Adaptation** | Accept: tribe_only coverage is sufficient for MVP. Document that toll-based turret policy requires future world-contracts changes (UID accessor or extended calling convention). |
| Single preset controls gates + turrets together | Gate preset writes to CivControlConfig DF. Turret can't read CivControlConfig. | **Design Adaptation** | Don't expose turret as a separate config surface. Describe alignment as inherent. If CC later adds non-tribe policies (allow list, toll), turret alignment will be incomplete. |
| Extension registers on turret for CC-branded targeting | Default behavior is identical; registering is unnecessary overhead + occupies extension slot | **Non-Issue** | Skip turret extension entirely. Preserve the turret's extension slot for future uses. |
| Custom turret events branded as CC events | No CC turret extension → no custom events | **Non-Issue (demo)** | Default `PriorityListUpdatedEvent` exists. For demo purposes, the absence of CC-branded turret events is acceptable. |
| Coin toll payers should not be targeted | Extension can't read toll-payment status; toll-payers in a different tribe WILL be targeted | **Blocker for non-tribe policies** | Document as known limitation. For tribe_only demo, this mismatch does not surface. For future coin-toll-only mode (anyone who pays gets safe passage + no turret aggression), this is unresolvable without world-contracts changes. |

---

## 2. CargoBond (Atomic Courier)

### Turret Role

Per cargo-bond-product-vision.md §7 _(original text, since corrected):_ "Turret Integration — Deferred (Phase 2). No turret assembly contract exists in the current world-contracts codebase."

**Status:** The product vision has been updated. Turrets exist in v0.0.14. Deferral rationale changed from "absent" to "closed-world constraint blocks bond-state access." See [turret-closed-world-clarified.md](../architecture/turret-closed-world-clarified.md).

**Intended role (from task brief):** "Accept Job" greenlights route gates AND sets turret policy. Turret extension deprioritizes couriers with active bonds (weight=0).

### Translation: Bond-Based Deprioritization

The CargoBond UX wants: "A courier with an active bond is safe from the client's turrets along the route."

In turret terms: the extension would need to:
1. Receive a `TargetCandidate` with `character_id` matching the bonded courier
2. Look up the courier's bond status (is there an active `CourierJob` for this character?)
3. If bonded: return `priority_weight = 0` (or exclude from list)
4. If not bonded: apply default targeting logic

**Step 2 is impossible.** The turret extension cannot access `CourierJob` objects, `ExtensionConfig`, or any external state. It receives only the candidate list and owner character. The `character_id` field is a `u32` — it identifies the candidate but provides no way to look up bond status.

### Can the Turret Extension Read Bond Data?

**No.** The `get_target_priority_list` function receives only:
- `turret: &Turret` — no UID accessor, no DF access
- `owner_character: &Character` — turret owner's character
- `target_candidate_list: vector<u8>` — BCS of candidates
- `receipt: OnlineReceipt` — hot potato

The `ExtensionConfig` or `CourierJob` shared objects are NOT in the argument list. The game calls with a fixed signature. The extension cannot request additional objects.

### Alternative Approaches

| Approach | Viable? | Why / Why Not |
|---|---|---|
| Turret extension reads DFs on turret itself | **No** | No `uid()` accessor on Turret. Can't call `df::borrow`. |
| Pre-compute "safe list" and write to turret DFs at accept_job time | **No** | Same UID problem. Even if you could write DFs to the turret during `accept_job`, you can't read them during targeting. |
| Use `character_tribe` as proxy (same tribe = bonded courier) | **Weak** | Only works if courier is in the same tribe as the client. Cross-tribe couriers (the primary use case) would still be targeted. |
| Custom turret behavior based on `type_id` or `group_id` | **No** | Bond status is per-character, not per-ship-type. Ship type doesn't indicate courier role. |
| Off-chain turret coordination (game server API) | **Outside scope** | Would require game server to interpret bond events and adjust turret targeting. Not a smart contract solution. |

### Implementation Approach

**Bond-based turret safe passage is NOT implementable** with the current turret extension architecture. The closed-world constraint prevents any form of dynamic character-specific policy beyond what's derivable from the fixed TargetCandidate fields.

**Recommendation:** Maintain the existing product vision position — turret integration is deferred. Update the rationale from "no turret contract exists" to "turret extension calling convention does not support external state access." The product narrative changes from "future integration pending contract availability" to "future integration pending world-contracts extension calling convention expansion."

**Demo narrative:** Same as existing product vision: "Active courier bonds automatically whitelist the courier through the client's defensive perimeter" — described as a product vision statement, NOT a current implementation claim. Add a footnote:

> "Turret safe passage requires the game's turret targeting call to support extension-defined shared objects (e.g., ExtensionConfig with bond status). The current calling convention passes only candidate attributes and owner character."

### Mismatches

| Desired UX (CargoBond) | Contract Reality | Mismatch Type | Resolution |
|---|---|---|---|
| "Accept Job" greenlights route turrets for courier | Extension can't access bond data during targeting | **Blocker** | Defer turret integration. Gates (via JumpPermit) remain the sole access control mechanism. |
| Turret deprioritizes bonded couriers (weight=0) | Extension can't determine bond status from TargetCandidate fields | **Blocker** | No workaround with current calling convention. |
| Same PTB batch: accept_bond + authorize_turret | Turret extension authorization is possible but useless without state access | **Non-Issue** | Skip turret authorization entirely. Don't occupy the turret's extension slot. |
| Turret recognizes active bonds without manual config | The only per-character signal is `character_tribe` (too coarse) | **Design Adaptation** | If all couriers are same-tribe: tribe-based filtering works as proxy. Otherwise: not viable. |
| Time-bounded turret safe passage (expires with job deadline) | No turret permit system, no expiry on targeting priority | **Fundamental Gap** | Gates have time-bounded permits. Turrets have no equivalent. Even if bond-based deprioritization worked, there's no automatic revocation mechanism tied to job lifecycle. |

---

## 3. Fortune Gauntlet

### Turret Role

Per fortune-gauntlet-project-vision.md §6: Turret integration is a "Stretch" goal, conditional on turret assembly availability. The feasibility analysis (fortune-gauntlet-feasibility.md §3) proposes a `marked_for_turrets: bool` field in `PlayerProgress` DF, with turret systems consuming the mark to target the player.

**Intended role (from task brief):** On denial, turrets fire at the denied player. "Consequence" = high priority_weight for players who failed a gauntlet challenge.

### What "Denied" Means in Chain Terms

The Fortune Gauntlet denial flow:
1. Player calls `try_issue_permit` (entry function with `&Random`)
2. VRF roll fails (10% chance)
3. Extension writes `cooldown_until_ms` and increments `denial_count` in `PlayerProgress` DF on `ExtensionConfig`
4. Emits `CheckpointDeniedEvent`
5. Player is NOT issued a JumpPermit

**"Denied" is NOT a MoveAbort.** The transaction succeeds — it just doesn't issue a permit. The denial is expressed as:
- DF state change (cooldown set, denial count incremented)
- Event emission (CheckpointDeniedEvent)
- Absence of JumpPermit

There is no "denied" signal visible to the turret extension. The turret operates in a separate calling context with no access to the `ExtensionConfig` where `PlayerProgress` is stored.

### Translation: Gauntlet Failure → High Priority Weight

The desired mechanic: player fails gauntlet → turret targets them with high priority.

This requires the turret extension to:
1. Receive a `TargetCandidate` with the failed player's `character_id`
2. Check whether this `character_id` has `marked_for_turrets == true` in `PlayerProgress` DF
3. If marked: return high `priority_weight` (e.g., 50000)
4. If not marked: apply normal targeting

**Step 2 is impossible.** Same closed-world constraint as CargoBond. The turret extension cannot access `ExtensionConfig` or any external state.

### Can Gauntlet State Reach the Turret?

| Mechanism | Viable? | Why / Why Not |
|---|---|---|
| Turret extension reads `ExtensionConfig` DF | **No** | Not in function signature. Game doesn't pass it. |
| Turret extension reads `PlayerProgress` from turret DFs | **No** | No `uid()` accessor on Turret. |
| Write `marked_for_turrets` to the turret's DFs during `try_issue_permit` | **No, twice** | (a) `try_issue_permit` doesn't receive `&mut Turret` — it's a gate extension function. (b) Even if it did, the turret is a DIFFERENT assembly; the gate extension can't mutate it. |
| `is_aggressor` flag on TargetCandidate as proxy | **Weak** | `is_aggressor` is set by the game engine based on combat actions, not extension logic. A gauntlet-denied player is not necessarily an aggressor. |
| Cross-extension event consumption | **No** | Events are off-chain indexable but not on-chain consumable. The turret extension cannot read events emitted by the gate extension. |
| Off-chain game server interprets denial events → adjusts turret behavior | **Outside scope** | Requires game server integration, not a smart contract solution. |

### Observability

The Fortune Gauntlet feasibility doc proposes emitting `GauntletDenialEvent` with `denial_type: u8` including `2 = turret_mark`. This event IS emittable and IS indexable. But:

- The turret extension **cannot consume** this event on-chain
- An off-chain system (game server, frontend, indexer) COULD consume it, but this is outside the extension's on-chain mechanics
- `PriorityListUpdatedEvent` from the default turret path shows the candidate list, but the priority values will be based on default tribe/aggressor rules — not gauntlet state

### Implementation Approach

**Gauntlet-triggered turret targeting is NOT implementable** with the current turret extension architecture. The closed-world constraint prevents any form of cross-extension state sharing between gate and turret.

**Recommended approach:** Maintain the existing feasibility analysis position: turret integration is a "🔮 Future" item. The proxy consequence mechanisms (escalating cooldown, deny list, events for future consumption) stand on their own. Update the rationale:

Previous rationale _(original text, since corrected)_ (fortune-gauntlet-feasibility.md §3): "No turret/weapon/combat assemblies exist."  
**Updated rationale (applied):** "Turret assemblies now exist (v0.0.14), but the extension calling convention prevents access to external state. The turret can't read gauntlet progress (`PlayerProgress` DF on `ExtensionConfig`). Cross-extension state sharing between gate and turret systems is not supported." See [turret-closed-world-clarified.md](../architecture/turret-closed-world-clarified.md).

**The consequence model shifts:**

| Layer | Old Design (pre-turret) | New Design (turret exists but constrained) |
|---|---|---|
| Primary | Escalating cooldown (DF) | Escalating cooldown (DF) — unchanged |
| Secondary | Denial events (future turret consumption) | Denial events (off-chain consumption only) |
| Stretch | `marked_for_turrets` field | **Not viable on-chain.** Reframe as off-chain game integration opportunity. |

### What "Real Consequences" Means

Fortune Gauntlet wants "real consequences." Available consequence mechanisms:

| Mechanism | Severity | On-Chain? | Notes |
|---|---|---|---|
| **Escalating cooldown** | Medium | Yes | 15s × denial_count. Blocks retry. Provable via DF read. |
| **Permanent deny** | High | Yes | After N denials, `denied: true` in PlayerProgress. Must be admin-reset. |
| **Priority target** via default turret behavior | Low | Sort of | If the player attacks the turret's base (becoming an aggressor), default rules boost their priority by +10000. But this requires the player to ATTACK, not just fail a gauntlet. |
| **Custom turret targeting** | High (desired) | **No** | Blocked by closed-world constraint. |

**The closest mechanism to "real consequences" is the escalating cooldown + permanent deny combination.** This is already in the feasibility analysis and doesn't require turret integration.

### Mismatches

| Desired UX (Fortune Gauntlet) | Contract Reality | Mismatch Type | Resolution |
|---|---|---|---|
| Gauntlet denial → turret fires at player | Turret can't read gauntlet state | **Blocker** | Drop turret consequence from implementable scope. Cooldown is the primary consequence. Turret targeting is narrative-only. |
| `marked_for_turrets: bool` consumed by turret extension | Turret extension can't access ExtensionConfig DFs | **Blocker** | Remove `marked_for_turrets` from implementation (keep as narrative future-state). Emit `GauntletDenialEvent` for off-chain consumption instead. |
| High priority_weight for denied players | Extension returns priority based only on TargetCandidate fields (tribe, aggressor, etc.) | **Fundamental Gap** | No character-specific priority boosting possible. The only character-level signal is tribe membership. |
| Visible consequence (ship destruction) | Turret targeting is game-engine-driven; extension influences priority, not firing | **Design Adaptation** | Even if turret targeting worked, it's "higher chance of being targeted" not "guaranteed fire." This is inherent to the priority model. |
| "The chain fired at you because you failed" | Chain produces priority list; game decides whether/when to fire | **Non-Issue (expected)** | The priority model is indirect by design. This is how turrets work in EVE Frontier — it's not a bug. |
| Denial event triggers turret aggression | Events are off-chain only; turret extension can't consume events | **Fundamental Gap** | Events remain useful for frontend display, leaderboards, and potential future game server integration. Not usable for on-chain turret logic. |

---

## Summary: Cross-Project Mismatch Matrix

### Root Cause

All three projects share the same root constraint: **the turret extension `get_target_priority_list` function receives a fixed argument set from the game engine, with no mechanism to access external state (shared objects, dynamic fields, or events).**

This is not a bug — it's a design choice in the game engine's calling convention. The turret extension is designed for **stateless targeting logic** (decisions based purely on candidate attributes and owner identity), not **stateful policy enforcement** (decisions based on external relationships like bonds, policies, or game states).

### Per-Project Impact

| Project | Desired Turret Role | Achievable? | Severity | Recommended Path |
|---|---|---|---|---|
| **CivilizationControl** | Tribe-aligned turret targeting | **Partially — via default behavior** | Low | Don't write a turret extension. Default tribe deprioritization IS the CC tribe_only policy. Coin-toll alignment is not possible. |
| **CargoBond** | Bond-based safe passage | **No** | Medium | Defer turret integration. Document as product vision, not implementation. Gate permits remain sole access control. |
| **Fortune Gauntlet** | Failure-triggered targeting | **No** | Medium | Drop turret consequence from implementable scope. Cooldown + deny + events are sufficient for demo. |

### Mismatch Classification

| # | Mismatch | Projects Affected | Type | Resolution |
|---|---|---|---|---|
| M1 | Turret extension can't access external shared objects | All three | **Architectural Constraint** | Accept. No workaround without world-contracts changes (new UID accessor or extended calling convention). |
| M2 | No per-character policy beyond tribe membership | CargoBond, Fortune Gauntlet | **Blocker for character-specific rules** | Character-specific targeting (bond status, gauntlet marks) is impossible. Only tribe-level and ship-type-level rules work. |
| M3 | No turret-side coin/payment mechanism | CivilizationControl | **Fundamental Gap** | Turrets are weapons, not toll booths. Gate toll-payers who are non-tribe will still be targeted. Accept as inherent to the turret model. |
| M4 | No cross-extension state sharing (gate ↔ turret) | All three | **Architectural Constraint** | Gate and turret extensions are isolated. A gate event/state cannot influence turret behavior on-chain. Off-chain coordination (game server) is the only bridge. |
| M5 | No turret permit/pass system (unlike gate JumpPermit) | CargoBond | **Fundamental Gap** | Gates have explicit access tokens (JumpPermit). Turrets have only priority weighting. There is no "turret safe-passage token." |
| M6 | Default turret behavior matches CC tribe_only preset | CivilizationControl | **Non-Issue (beneficial)** | The default IS the desired behavior for the primary use case. No custom extension needed. |
| M7 | `marked_for_turrets` field is unreadable by turret extension | Fortune Gauntlet | **Blocker** | Remove from implementation plan. Keep the DF field for potential off-chain/future use, but don't claim on-chain turret integration. |
| M8 | Priority weight influence is probabilistic, not deterministic | Fortune Gauntlet | **Design Adaptation** | Higher weight = shot first, but turrets still need line-of-sight, range, and weapon cycle time. "Consequence" is increased danger, not guaranteed destruction. This is inherent to EVE Frontier's combat model. |

### World-Contracts Changes That Would Resolve These

If CCP/EVE Frontier updated the turret calling convention, these mismatches could be resolved:

1. **`uid()` accessor on Turret** → enables DF reads from the turret object → extensions could store and read per-turret config
2. **Extended `get_target_priority_list` signature** → include `&ExtensionConfig` or a generic shared object slot → extensions could read policy data
3. **Turret-side event consumption** → allow extensions to query recent events → cross-extension coordination possible

None of these are within the hackathon builder's control. They are game engine / world-contracts team decisions.

---

## Doc Updates Required

Based on this analysis, the following existing docs contained outdated turret assessments. **All updates in this table were applied on 2026-03-02.** Canonical reference: [turret-closed-world-clarified.md](../architecture/turret-closed-world-clarified.md).

| Document | Original Statement | Update Applied |
|---|---|---|
| [gate-turret-courier-access-feasibility.md §4](../architecture/gate-turret-courier-access-feasibility.md) | "No turret assembly exists in the current world-contracts codebase" | Updated: "Turrets exist but extension calling convention prevents external state access." |
| [cargo-bond-product-vision.md §7](../strategy/cargo-bond/cargo-bond-product-vision.md) | "Deferred (Phase 2) -- no on-chain turret assembly exists" | Updated: turrets exist, bond-based deprioritization blocked by closed-world constraint. |
| [fortune-gauntlet-feasibility.md §3](../analysis/fortune-gauntlet-feasibility.md) | "No turret/weapon/combat assemblies exist" | Updated: turrets exist, proxy consequences remain correct approach. |
| [fortune-gauntlet-project-vision.md §6](../strategy/fortune-gauntlet/fortune-gauntlet-project-vision.md) | "If turret assemblies become available..." | Updated: turrets available but can't read gauntlet state. "Turrets are NOT a dependency" remains correct. |
| [spec.md](../core/spec.md) | Does not mention turrets | No update needed for MVP. |

---

## Appendix: Turret Extension Calling Convention (Evidence)

### Default function (world::turret)

```move
// turret.move L254-277
public fun get_target_priority_list(
    turret: &Turret,
    owner_character: &Character,
    target_candidate_list: vector<u8>,
    receipt: OnlineReceipt,
): vector<u8> {
    assert!(receipt.turret_id() == object::id(turret), EInvalidOnlineReceipt);
    assert!(option::is_none(&turret.extension), EExtensionConfigured);
    // ... default targeting logic
}
```

Note: `assert!(option::is_none(&turret.extension), EExtensionConfigured)` — the default function ABORTS if an extension is configured. When an extension is present, the game calls the extension's version instead.

### Extension function (extension_examples::turret)

```move
// extension_examples/turret.move L49-63
public fun get_target_priority_list(
    turret: &Turret,
    _: &Character,
    target_candidate_list: vector<u8>,
    receipt: OnlineReceipt,
): vector<u8> {
    assert!(receipt.turret_id() == object::id(turret), EInvalidOnlineReceipt);
    let _ = turret::unpack_candidate_list(target_candidate_list);
    // ... extension targeting logic
    turret::destroy_online_receipt(receipt, TurretAuth {});
    // ... return BCS bytes
}
```

Signatures are identical. The game uses a fixed calling convention.

### Default targeting rules (for reference)

From [turret.move L626-650](../../vendor/world-contracts/contracts/world/sources/assemblies/turret.move):

```
effective_weight_and_excluded(candidate, owner_character):
  - Same tribe + NOT aggressor → EXCLUDED (weight irrelevant)
  - STOPPED_ATTACK → EXCLUDED
  - STARTED_ATTACK → weight + 10000
  - ENTERED + (different tribe OR aggressor) → weight + 1000
  - UNSPECIFIED → weight unchanged
```

Constants: `STARTED_ATTACK_WEIGHT_INCREMENT = 10000`, `ENTERED_WEIGHT_INCREMENT = 1000` ([turret.move L55-56](../../vendor/world-contracts/contracts/world/sources/assemblies/turret.move)).

### TargetCandidate fields available to extensions

| Field | Type | Useful For |
|---|---|---|
| `item_id` | `u64` | Ship/NPC identifier (not character) |
| `type_id` | `u64` | Ship type (for type-specialized turrets) |
| `group_id` | `u64` | Ship group (Shuttle=31, Corvette=237, Frigate=25, etc.) |
| `character_id` | `u32` | Pilot identifier (0 for NPCs) |
| `character_tribe` | `u32` | Pilot's tribe (0 for NPCs) |
| `hp_ratio` | `u64` | Structure HP % remaining (0-100) |
| `shield_ratio` | `u64` | Shield HP % remaining (0-100) |
| `armor_ratio` | `u64` | Armor HP % remaining (0-100) |
| `is_aggressor` | `bool` | Currently attacking anything on grid |
| `priority_weight` | `u64` | Initial weight assigned by game |
| `behaviour_change` | `BehaviourChangeReason` | Why targeting was recalculated |

Of these, only `character_tribe` enables tribe-based policy (matching CC's tribe_only). The remaining fields enable ship-type and combat-status based rules — useful for turret optimization, but not for identity/policy-based access control.
