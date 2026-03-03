# Cargo Bond — Product Vision

**Retention:** Carry-forward

> **Date:** 2026-03-02
> **Status:** Pre-hackathon planning (code moratorium until March 11)
> **Track:** F (Sprint — 1–2 day build)
> **Target Prizes:** Most Utility (backup to Corpse Toll) / Most Creative (backup to Salvage Protocol)
> **On-chain package name:** Atomic Courier (`atomic_courier`)
> **Inputs:** Portfolio roadmap §6b, wildcard sprint analysis (winner), Atomic Courier experiment (validated escrow + devnet test results), gate-turret access feasibility report, hackathon rules digest

---

## 1. Executive Summary

Cargo Bond is the public-facing name for a decentralized courier escrow system built on EVE Frontier, implemented by the **Atomic Courier** Move package (`atomic_courier`). A player posts a delivery job — reward locked on-chain, collateral required. A courier accepts by staking collateral. Deliver on time: courier receives reward plus collateral refund. Fail or expire: collateral is slashed to the job creator.

No trusted backend. No admin intervention. No reputation system. The only trust mechanism is economic: locked funds and enforced deadlines.

The system runs as a shared-object state machine on Sui. The Atomic Courier package implements the full lifecycle — post, accept, complete, expire, cancel — with deterministic settlement in every path. Five events cover the entire lifecycle for frontend indexing. Gas cost per job: under 0.01 SUI end-to-end.

**Extended scope (conditional):** When a courier accepts a job, the system can issue a time-bounded gate transit permit through the job creator's gates — granting passage that expires automatically with the job deadline. This requires no AdminACL, no sponsorship, and no manual revocation. Gate permit issuance is validated as feasible. Turret integration is out of scope. Turret assemblies exist (v0.0.14, now v0.0.15) but the extension calling convention prevents access to bond state. See turret-contract-surface.md and turret-closed-world-clarified.md.

**Build budget:** 8–14 hours LLM-assisted.
**Kill criteria:** Abandon if world-contracts SSU integration blocks clean escrow within 4 hours. Fallback: pure economic demo (SUI escrow only, no SSU hooks).

---

## 2. Strategic Role in Hackathon Portfolio

Cargo Bond occupies three roles in the multi-entry portfolio:

1. **Prize category backup.** If Corpse Toll (Track C3) hits its kill criteria, Cargo Bond absorbs the Most Utility targeting. If Salvage Protocol (Track C2) fails due to `unanchor` limitations, Cargo Bond absorbs Most Creative. Both are realistic failure scenarios — Cargo Bond's escrow is already validated on devnet.

2. **Primitive diversity.** Cargo Bond exercises `Balance<SUI>` escrow, `Clock` deadlines, shared-object coordination, typed receipts, and extension-witness gate permits — primitives not used by CivilizationControl (dynamic fields, typed witnesses, Groth16) or Flappy Frontier (`sui::random`, leaderboard vectors). Judges seeing the full portfolio recognize breadth.

3. **Architectural composition argument.** The core pitch: five cross-object operations in a single PTB (withdraw item, issue gate permit, execute jump, deposit item, release payment). This level of atomic multi-object coordination is impractical on account-based chains, where each operation would be a separate transaction with failure risk between steps. The full 5-step composition is demonstrable in principle; the MVP focuses on escrow + permit issuance as the proven subset. It validates Sui's object model for real economic coordination, not just token mechanics.

**Build priority within portfolio:** C3 (Corpse Toll) → C1 (Fortune Gate) → E (Flappy Frontier) → C2 (Salvage) → **F (Cargo Bond)** → D (Loot Crate). Cargo Bond ranks 6th because its Move code is 90% complete from the experiment phase. Sprint risk is low.

**Hard dependency:** Cargo Bond begins only after CivilizationControl Phase 2 (TradePost integration) is watchable. No exceptions.

---

## 3. Problem Statement: Trust in Player Logistics

EVE Frontier has no trustless mechanism for player-to-player delivery contracts.

Today, if a player needs items moved from SSU A to SSU B — across hostile space, through gated systems, past defensive turrets — they have three options:

1. **Move it themselves.** Risky, time-consuming, and impossible if they lack gate access or combat capability.
2. **Trust another player.** Reputation-based, unenforceable. The courier can steal the cargo, ghost the contract, or demand renegotiation mid-route.
3. **Use a player corporation's internal logistics.** Requires organizational membership. Excludes solo players and cross-faction coordination.

All three options fail the same way: they rely on social trust in a universe designed around betrayal, sovereignty, and economic competition.

The missing primitive is an **enforceable delivery bond** — a mechanism where:
- The sender's reward is locked, not promised.
- The courier's collateral is staked, not verbal.
- Deadlines are enforced by the chain, not by argument.
- Settlement is deterministic in every outcome.

This is what Cargo Bond provides.

---

## 4. Product Vision

A player opens the Cargo Bond interface at cargo-bond.com. They connect their wallet.

The job board shows active delivery contracts: origin, destination, reward amount, collateral requirement, deadline. Each job is an on-chain shared object — no backend, no database, no intermediary.

The player has items at a remote SSU and needs them moved to their home station. They click "Create Job." They specify:
- **Origin SSU:** The location where items currently sit.
- **Destination SSU:** Where items must arrive.
- **Reward:** 0.5 SUI — paid to the courier on successful delivery.
- **Collateral Required:** 1.0 SUI — staked by the courier, refunded on completion, slashed on failure.
- **Deadline:** 48 hours from now.

The wallet signs. A `CourierJob` shared object appears on-chain. The reward is locked inside it. The job appears on the board. Anyone can see it.

A courier evaluates the job. The route is manageable. The reward covers fuel and risk. They click "Accept Job," staking 1.0 SUI as collateral. The chain records them as the assigned courier, issues a `JobReceipt` to their wallet, and — if the creator's gates are configured — issues a time-bounded gate transit permit valid until the job deadline.

The courier flies the route in-game. They withdraw items from the origin SSU, traverse gates (using the automatically issued permit), and deposit items at the destination SSU.

The creator verifies delivery and clicks "Confirm Delivery." The chain transfers 0.5 SUI reward to the courier and refunds the 1.0 SUI collateral. Job complete.

**Alternative outcome:** The courier disappears. The deadline passes. Anyone — the creator, a bot, a bystander — calls `expire_job`. The chain slashes the courier's 1.0 SUI collateral to the creator and returns the reward. The creator is compensated. The courier pays the price.

No dispute. No arbitration. No admin. Just math and deadlines.

---

## 5. Core Job Lifecycle

The `CourierJob` object progresses through a deterministic state machine:

```
                    ┌─────────────────────────────────────┐
                    │                                     ▼
post_job() ──► POSTED ──► accept_job() ──► ACTIVE ──► complete_job() ──► COMPLETED
                 │                           │
                 ▼                           ▼
            cancel_job()               expire_job()
                 │                     (after deadline)
                 ▼                           │
            CANCELLED                        ▼
                                          EXPIRED
```

### Entry Functions

| Function | Caller | Precondition | Settlement |
|----------|--------|--------------|------------|
| `post_job` | Creator | — | Creator escrows reward into shared `CourierJob` |
| `accept_job` | Any player | State = POSTED, before deadline | Courier escrows collateral, receives `JobReceipt` |
| `complete_job` | Creator only | State = ACTIVE | Courier receives reward + collateral refund |
| `expire_job` | Anyone | State = ACTIVE, clock ≥ deadline | Creator receives slashed collateral + reward return |
| `cancel_job` | Creator only | State = POSTED | Creator receives reward refund |

### Terminal States

Every path terminates. No funds can be locked permanently:
- **COMPLETED:** Courier paid, collateral returned. Job is inert.
- **EXPIRED:** Collateral slashed to creator, reward returned. Job is inert.
- **CANCELLED:** Reward returned to creator. No courier was ever assigned.

The `expire_job` function is callable by **anyone** after the deadline passes. This prevents deadlocked jobs and enables cleanup bots — no admin maintenance required.

### Objects

| Object | Abilities | Ownership | Purpose |
|--------|-----------|-----------|---------|
| `CourierJob` | `key` | Shared | Coordination point: holds escrow, state, participants |
| `JobReceipt` | `key`, `store` | Owned (courier) | Proof of assignment, potential delivery-confirmation token |

---

## 6. Escrow & Collateral Model

### Design Principles

1. **`Balance<SUI>` for escrow storage, not `Coin<SUI>`.** Coin lacks the `drop` ability, making `Option<Coin>` mutations problematic inside shared structs. Balance supports zero-initialization and clean split/join operations. This is the canonical Sui pattern for escrowed funds.

2. **Shared `CourierJob` for coordination.** A courier job is inherently a coordination point between parties who don't know each other at post time. Any potential courier needs read access to evaluate the job. Each job is an independent shared object — no contention between different jobs.

3. **Binary settlement in MVP.** Every job resolves to exactly one of: full reward payout, full collateral slash, or clean cancellation. No partial refunds, no graduated penalties, no dispute resolution. This is a deliberate simplification — clear for judges, unambiguous in demo.

### Escrow Flow

**Post:** Creator converts `Coin<SUI>` reward → `Balance<SUI>`, stored inside `CourierJob`. Collateral balance initialized to zero.

**Accept:** Courier converts `Coin<SUI>` collateral → `Balance<SUI>`, joined into `CourierJob`. Must meet `collateral_required` minimum.

**Complete:** Chain splits full reward balance → `Coin<SUI>` transferred to courier. Chain splits full collateral balance → `Coin<SUI>` transferred to courier.

**Expire:** Chain splits full collateral balance → `Coin<SUI>` transferred to creator. Chain splits full reward balance → `Coin<SUI>` returned to creator.

**Cancel:** Chain splits full reward balance → `Coin<SUI>` returned to creator.

### Validated Gas Costs

| Operation | Net Gas (SUI) |
|-----------|---------------|
| `post_job` | ~0.002–0.003 |
| `accept_job` | ~0.001–0.003 |
| `complete_job` | ~0.003 |
| `expire_job` | ~0.003 |
| `cancel_job` | ~0.002 |
| **Full happy path** | **~0.005** |
| **Full slash path** | **~0.009** |

All operations are O(1). No dynamic fields, no vectors, no loops. Gas costs do not scale with job count.

> **Note:** Gas figures were measured on local devnet (Sui v1.x) and may differ on the hackathon test server or mainnet. Relative cost ordering is expected to hold; absolute values should be re-validated after deployment.

### Known Simplifications (Accepted for MVP)

- **Surplus collateral is locked.** If a courier deposits more than required, the excess is locked in the job. Production fix: split exact required amount and return remainder. (~5 lines of code.)
- **No deadline validation on post.** A creator can post a job with an already-past deadline. Production fix: require `deadline_ms > clock.timestamp_ms()` in `post_job`.
- **No object cleanup.** Terminal-state jobs persist on-chain with zero balances. Production fix: add `delete_job` to destroy completed/expired/cancelled jobs and reclaim storage.
- **SUI-only.** EVE Frontier uses EVE tokens. Production would parameterize over `Coin<T>`.

---

## 7. Access Control Integration (Gate Transit Permits)

### Gate Transit Permits — Validated as Feasible

When a courier accepts a job, the system can issue a time-bounded gate transit permit through the job creator's gates. This transforms "Accept Job" from a simple economic operation into a coordinated access delegation event.

> **Qualification:** Gate permit feasibility is validated against current world-contracts source code (local vendor submodule). Final confirmation requires testing on the hackathon test server once available (March 11+).

**How it works:**

1. The job creator pre-authorizes the Atomic Courier extension on their gates (one-time setup per gate).
2. When a courier calls `accept_job`, the PTB includes an `issue_jump_permit` call using the extension's `XAuth` witness.
3. The permit's `expires_at_timestamp_ms` is set to the job's `deadline_ms` — natural time-bounding with zero revocation logic.
4. The courier uses the permit to traverse gates in-game via `jump_with_permit`.

**Why this works without AdminACL:**

`issue_jump_permit` requires only two things:
- The extension's Auth typed witness (Atomic Courier controls this via `public(package)` scoped `x_auth()`)
- Both gates in the route having the same extension authorized

It does **not** require AdminACL, OwnerCap, or sponsorship for the permit issuance itself. The courier calls it directly.

**Constraints:**

| Constraint | Impact | Mitigation |
|------------|--------|------------|
| Single extension slot per gate | Authorizing Atomic Courier replaces any existing extension | Creator accepts this tradeoff per-gate; document clearly |
| Single-use permits | Each jump consumes one permit | Issue one permit per gate pair in the route |
| Cross-player gates | Extension must be authorized by each gate's owner | MVP assumes creator owns all gates on the route |
| `jump_with_permit` needs AdminACL | The actual in-game jump requires game-server sponsorship | This is the game server's responsibility, not the extension's |

**MVP scope:** Single-hop routes (one gate pair) with creator-owned gates. Multi-hop and cross-player federation are Phase 2.

### Turret Integration — Out of Scope

Turret assemblies exist in world-contracts v0.0.14 (now v0.0.15), but turret extensions use a closed-world calling convention: the fixed 4-argument signature (`turret, character, candidates_bcs, receipt`) cannot access external objects such as `ExtensionConfig` or `CourierJob`. Bond-state lookups during targeting are architecturally blocked by this constraint.

> **v0.0.15 update (2026-03-03):** world-contracts updated to v0.0.15. Gate/turret modules unchanged. Key inventory changes: `withdraw_item` now takes `quantity: u32` + `ctx`, `deposit_item` validates `parent_id`, new `deposit_to_owned`. SSU-related courier operations should verify updated inventory signatures. See decision-log 2026-03-03.

**Recommendation:** Turret behavior is default (tribe-based filtering) and operates independently of the courier system. ~~Previously recommended framing turret integration as a "natural extension of the gate permit model" — since corrected: bond-aware turret targeting is not a natural extension of the gate pattern and requires turret calling convention changes.~~ Do not frame turret safe-passage as a product feature. See `docs/architecture/turret-closed-world-clarified.md` and `docs/architecture/turret-contract-surface.md` for full analysis.

> **Future:** If CCP/Stillness expands the turret interface to allow external state access, bond-aware turret targeting could be evaluated opportunistically.

### Automatic Revocation

Gate permits expire naturally via `expires_at_timestamp_ms`. No revocation transaction is needed. If a job completes before the deadline, the permit remains valid until the original deadline — this is acceptable because:
- The permit only grants passage, not cargo access or economic privileges.
- The time window is bounded by the job creator's chosen deadline.
- In the failure case (no revocation, courier still has transit permit), the impact is limited to unnecessary passage — not fund loss.

This is a **fail-safe** design: if the revocation mechanism doesn't fire, nothing economically harmful happens.

---

## 8. Sui Primitives Leveraged

| Primitive | Usage | Why It Matters |
|-----------|-------|----------------|
| **Shared objects** | `CourierJob` as coordination point between strangers | Enables permissionless marketplace without off-chain matching |
| **`Balance<SUI>`** | Escrow storage for reward and collateral | Canonical pattern for holding funds inside shared objects |
| **`Clock`** | Deadline enforcement for job expiry | Deterministic time without oracles; ~2s resolution |
| **Typed receipts** | `JobReceipt` as proof of courier assignment | Owned object proves job participation; potential delivery-confirmation token |
| **Events** | 5 lifecycle events for full job history | Frontend indexing without polling; event-driven architecture |
| **Extension witnesses** | `XAuth` for gate permit issuance | Programmatic access delegation without admin overhead |
| **PTB composition** | Multi-operation atomic transactions | Accept job + issue gate permit in single transaction |
| **Object transfer** | `public_transfer` for settlement payouts | Direct wallet-to-wallet fund delivery |

### Structural Sketch (Non-Binding)

```
CourierJob (shared, key)
├── id: UID
├── creator: address
├── courier: address
├── reward: Balance<SUI>
├── collateral: Balance<SUI>
├── collateral_required: u64
├── deadline_ms: u64
└── state: u8  (POSTED=0, ACTIVE=1, COMPLETED=2, EXPIRED=3, CANCELLED=4)

JobReceipt (owned, key + store)
├── id: UID
├── job_id: ID
└── courier: address
```

This is validated — the experiment's `courier_escrow.move` implements this structure with all five entry functions and five event types tested on local devnet.

---

## 9. Economic Model

### Pricing Parameters (MVP Defaults)

| Parameter | Default | Rationale |
|-----------|---------|-----------|
| Reward | Set by creator (e.g., 0.1–1.0 SUI) | Market-driven; creator prices the delivery |
| Collateral required | Set by creator (e.g., 1–5× reward) | Higher ratio = stronger courier commitment |
| Deadline | Set by creator (e.g., 1–48 hours) | Reflects route difficulty and urgency |
| Platform fee | 0% (MVP) | No treasury; full reward to courier |
| Gas per job lifecycle | < 0.01 SUI | Negligible relative to reward/collateral values |

### Incentive Alignment

**Creator's perspective:**
- Risk: reward is locked during the job's lifetime. If courier fails, reward is returned (creator loses only gas).
- Setting collateral > reward ensures the courier has more to lose than the creator has at risk.
- Setting a tight deadline creates urgency but may reduce the courier pool.

**Courier's perspective:**
- Risk: collateral is locked during transit. If delivery fails, collateral is slashed.
- Rational couriers accept only jobs where: (expected reward) > (collateral risk × failure probability) + (gas + time cost).
- A healthy market self-selects for competent couriers on challenging routes.

**Bystander's perspective:**
- Anyone can call `expire_job` after the deadline. This enables volunteer cleanup or economic bots that charge a micro-fee (future enhancement).

### No Tokens, No Securities

Cargo Bond creates no new token. It operates on SUI (or EVE tokens in production). No governance token, no revenue-share mechanism, no staking yield. This is critical for hackathon compliance — entries must not constitute securities (Event Rules §5).

---

## 10. Demo Scope

### Public Webpage: cargo-bond.com

Minimal web interface with wallet integration:

| Screen | Purpose |
|--------|---------|
| **Job Board** | List active `CourierJob` objects with status, reward, collateral, deadline countdown |
| **Create Job** | Form: reward amount, collateral required, deadline. Wallet signs `post_job` |
| **Job Detail** | Shows job state, participants, escrow balances, timeline |
| **Accept Job** | Courier stakes collateral. Wallet signs `accept_job` (+ optional `issue_jump_permit`) |
| **Confirm Delivery** | Creator confirms. Wallet signs `complete_job`. Settlement visible immediately |
| **Expire Job** | Anyone triggers after deadline. Wallet signs `expire_job`. Slash visible immediately |

**No UI design detail in this document.** Screen layout, component architecture, and interaction patterns are separate deliverables.

### Demo Script (60–90 seconds)

| Segment | Duration | Action |
|---------|----------|--------|
| **Context** | 0:00–0:10 | "Cargo Bond: trustless delivery contracts for EVE Frontier. No backend. No admin." |
| **Post Job** | 0:10–0:25 | Creator posts: 0.1 SUI reward, 0.2 SUI collateral required, 60-second deadline |
| **Accept** | 0:25–0:40 | Courier accepts → collateral locked → receipt issued → gate permit issued (if configured) |
| **Happy Path** | 0:40–0:55 | Creator confirms delivery → reward paid → collateral returned. Balances update in real time. |
| **Slash Scenario** | 0:55–1:10 | Second job: courier accepts, deadline expires. Anyone calls expire → collateral slashed. |
| **Tag** | 1:10–1:20 | "Deliver or pay the price. On-chain enforcement. No trust required." |

**Key demo moment:** The slash. Judges must see the courier lose collateral — this is the emotional proof that the system enforces consequences without intervention.

---

## 11. MVP Boundaries

### In Scope (Must Ship)

- [ ] Move package: `courier_escrow` (adapted from validated experiment)
- [ ] Entry functions: `post_job`, `accept_job`, `complete_job`, `expire_job`, `cancel_job`
- [ ] Events for all state transitions
- [ ] Web UI: job board, create job, accept job, confirm delivery, expire job
- [ ] Wallet integration (@mysten/dapp-kit)
- [ ] Two-scenario demo: happy path + slash

### Conditional (Ship If Time Allows)

- [ ] Gate permit issuance on `accept_job` (validated feasible, ~2 hours additional)
- [ ] Surplus collateral refund fix (~5 minutes)
- [ ] Deadline validation in `post_job` (~5 minutes)
- [ ] Job cleanup function (`delete_job`) (~15 minutes)
- [ ] Additional event fields (`deadline_ms`, `receipt_id` in `JobAcceptedEvent`)

### Out of Scope (Explicit Non-Goals)

- Turret integration (assemblies exist but extension calling convention blocks bond-state access)
- Multi-hop route permits (Phase 2)
- Cross-player gate federation (Phase 2)
- Dispute resolution / arbitration
- Partial collateral slashing / graduated penalties
- Platform fees / treasury
- `Coin<EVE>` parameterization (use SUI for hackathon)
- SSU item custody (economic enforcement only — chain cannot hold physical items during transit)
- Delivery proof via SSU extensions or proximity proofs (requires game server integration)
- Automated delivery confirmation (creator-confirms model in MVP)
- In-game map/route visualization

---

## 12. Risks & Tradeoffs

| Risk | Severity | Probability | Mitigation |
|------|----------|-------------|------------|
| **Creator-confirms delivery model** is too simplistic — courier delivers but creator refuses to confirm, forcing expiry | Medium | Medium | Documented as known limitation. Demo shows honest scenario. Production path: SSU deposit events, multi-party oracle, or timeout-based auto-completion. |
| **World-contracts SSU integration** blocks clean escrow | Medium | Low | Move code is standalone — no SSU dependency in core escrow. Fallback: pure economic demo (SUI escrow only). Kill criteria: 4-hour timeout. |
| **Single extension slot** means authorizing Atomic Courier replaces existing gate extensions | Medium | Low | Creator makes an explicit choice per gate. Documented in UI. Not a bug — a governance decision. |
| **Game-server dependency** for `jump_with_permit` (AdminACL + sponsorship) | High | High | Can be mocked in demo. Gate permit issuance is provable on-chain; actual in-game jump requires game server cooperation. |
| **Time pressure** — Track F is 6th in build priority | Low | Medium | Move code is 90% complete. Sprint is hardening + UI only. 8–14 hour estimate is conservative. |
| **No EVE token support** — demo uses SUI | Low | Low | Acceptable for hackathon. Coin type is trivially parameterizable post-submission. |
| **Surplus collateral bug** — excess collateral locked in job | Low | High (present in current code) | 5-line fix in `accept_job`. Will be addressed in sprint. |

### Honest Limitations

1. **The chain cannot enforce physical delivery.** Cargo Bond enforces economic incentives — locked funds and deadlines. The actual item movement happens in-game, outside the chain's visibility. The creator-confirms model is a trust assumption. This is documented, not hidden.

2. **The access control integration depends on gate owner cooperation.** The job creator must pre-authorize the extension on their gates. If they don't, the courier gets no gate permit. This is a coordination requirement, not a technical limitation.

3. **The demo uses short deadlines (60 seconds) for pacing.** Real gameplay would use 1–48 hour windows. The contract handles both.

---

## 13. Why Judges Should Care

### For "Most Utility" Judges

Cargo Bond solves a real coordination problem in multiplayer sandbox games: trustless logistics between strangers. The escrow pattern is generalizable — any two-party contract with economic stakes and deadlines (bounties, rental agreements, construction bonds) can reuse this state machine. Every player economy benefits from enforceable delivery contracts.

### For "Most Creative" Judges

The architectural pitch: **five cross-object operations in a single Programmable Transaction Block** — withdraw item from source SSU, issue gate transit permit, execute jump, deposit item at destination SSU, release payment. This level of atomic multi-object coordination is impractical on account-based chains, where each operation would require separate transactions with failure risk between steps. Sui's object model makes it atomic.

The full 5-step composition is demonstrable in principle and validated at the individual-operation level. The MVP ships the proven subset: escrow settlement + gate permit issuance in a single PTB. Even this reduced scope demonstrates multi-object coordination that account-based architectures cannot cleanly replicate.

### For "Best Technical" Judges

The Move package exercises shared-object consensus, `Balance<SUI>` escrow, `Clock` deadlines, typed receipt objects, extension witness authentication, and PTB composition — covering more of the Sui surface area than a typical DeFi contract. The code is tested on devnet with three complete scenarios (happy path, slash, cancel) and documented gas costs.

### The One-Line Pitch

"A decentralized shipping bond + automated access permit system. Deliver or pay the price. No backend. No admin. No trust required."

---

_Cross-references: [Portfolio Roadmap §6b](../_shared/hackathon-portfolio-roadmap.md), [Wildcard Sprint Analysis](../../ideas/wildcard-sprint-analysis.md), [Gate-Turret Access Feasibility](../../architecture/gate-turret-courier-access-feasibility.md), [In-Game DApp Surface](../../architecture/in-game-dapp-surface.md)_
