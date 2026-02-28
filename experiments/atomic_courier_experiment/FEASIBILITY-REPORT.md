# Atomic Courier Experiment — Feasibility Report

**Retention:** Sandbox-only

## Verdict: FEASIBLE ✓ (Extended)

Phase 1 proved single-PTB atomic SSU-to-SSU item transfer with coin payment.
Phase 2 extends this with a **full economic contract**: collateral escrow, reward escrow, deadline-based expiry, state machine transitions, and dispute-free settlement.

All paths validated on local Sui devnet (Sui CLI 1.66.2, chain ID `cdda0001`).

---

## Critical Domain Constraint — Game ↔ Chain Boundary

In the real EVE Frontier game:
- **Withdrawing** an item from an SSU removes it on-chain and materializes it in the player's in-game inventory.
- **Depositing** into an SSU consumes the in-game item and re-materializes it on-chain.

**Therefore:**
- The chain **cannot "hold"** a physical item during transit — the courier carries it in-game.
- The chain **CAN** enforce economic incentives and authorization rules.

This experiment models "cargo custody" as an **on-chain job receipt / claim token**, not as a real SSU item persisting during transit. Where SSU withdraw/deposit would be used in production, they act as **pickup/dropoff triggers**, not continuous custody.

---

## Phase 2 — Courier Escrow State Machine

### State Diagram

```
  post_job()         accept_job()         complete_job()
  [Creator] ──────► POSTED ──────────► ACTIVE ──────────► COMPLETED
                      │                   │
                      │ cancel_job()       │ expire_job()
                      ▼                   ▼
                   CANCELLED           EXPIRED
```

### Objects

| Object | Type | Key Properties |
|--------|------|---------------|
| `CourierJob` | Shared | creator, courier (optional), reward (Balance<SUI>), collateral (Balance<SUI>), collateral_required, deadline_ms, state |
| `JobReceipt` | Owned (courier) | job_id, courier address — proof of assignment |

### Entry Functions

| Function | Auth | Transitions | Settlement |
|----------|------|-------------|------------|
| `post_job` | Creator (sender) | → Posted | Creator escrows reward |
| `accept_job` | Any (becomes courier) | Posted → Active | Courier escrows collateral; receives JobReceipt |
| `cancel_job` | Creator only | Posted → Cancelled | Reward returned to creator |
| `complete_job` | Creator only | Active → Completed | Courier receives reward + collateral back |
| `expire_job` | Anyone | Active → Expired | Creator receives slashed collateral + reward back |

### Settlement Rules

**On completion (delivery confirmed):**
- Courier receives escrowed reward
- Courier receives escrowed collateral back (full return)

**On expiry (deadline passed, delivery not confirmed):**
- Creator receives courier's collateral (full slash)
- Creator receives their reward back

**On cancellation (before any courier accepts):**
- Creator receives their reward back

---

## Test Results

### Test 01 — Post → Accept → Complete (Happy Path) ✓

| Step | Operation | Result | Gas (net MIST) |
|------|-----------|--------|----------------|
| 1 | Post Job (reward=0.05 SUI, collateral_req=0.1 SUI) | ✓ | 1,908,960 |
| 2 | Accept Job (courier deposits 0.1 SUI collateral) | ✓ | -778,628 (rebate!) |
| 3 | Complete Job (creator confirms delivery) | ✓ | 3,007,084 |

**Balance deltas:**
- Creator: -54,916,044 MIST (= -reward - gas)
- Courier: +50,778,628 MIST (= +reward - accept gas)

### Test 02 — Post → Accept → Expire (Slashing) ✓

| Step | Operation | Result | Gas (net MIST) |
|------|-----------|--------|----------------|
| 1 | Post Job (reward=0.03 SUI, collateral_req=0.08 SUI, deadline=+15s) | ✓ | 2,887,080 |
| 2 | Accept Job | ✓ | 3,133,852 |
| 3 | Wait for chain clock to pass deadline | ✓ | — |
| 4 | Expire Job (called by creator) | ✓ | 3,007,084 |

**Balance deltas:**
- Creator: +74,105,836 MIST (= +slashed_collateral - gas)
- Courier: -83,133,852 MIST (= -collateral - gas)

### Test 03 — Post → Cancel (Before Accept) ✓

| Step | Operation | Result | Gas (net MIST) |
|------|-----------|--------|----------------|
| 1 | Post Job (reward=0.025 SUI) | ✓ | 930,840 |
| 2 | Cancel Job | ✓ | 2,016,652 |

**Balance delta:**
- Creator: -2,947,492 MIST (= gas only; reward returned)

---

## Gas Analysis Summary

| Operation | Net Gas (MIST) | Net Gas (SUI) |
|-----------|----------------|---------------|
| post_job | ~1.9–2.9M | ~0.002–0.003 |
| accept_job | ~1.2–3.1M | ~0.001–0.003 |
| complete_job | ~3.0M | ~0.003 |
| expire_job | ~3.0M | ~0.003 |
| cancel_job | ~2.0M | ~0.002 |
| **Full happy path** | **~5.1M** | **~0.005** |
| **Full expire path** | **~9.0M** | **~0.009** |

---

## Architectural Decisions

1. **Balance<SUI> over Coin<SUI> for escrow storage.** Coin doesn't have `drop` ability, making Option<Coin> mutations impossible. Balance allows zero-value initialization and clean split/join operations.

2. **Shared CourierJob object.** Any potential courier needs read access to evaluate the job; making it shared enables this. The tradeoff is consensus latency on mutations, but for a job coordination object this is acceptable.

3. **Creator-confirms-delivery model.** In this minimal probe, the creator (job poster) confirms delivery. In production, delivery proof could come from an SSU deposit event, an extension witness, or a multi-party oracle.

4. **Anyone-can-expire rule.** After the deadline, anyone can trigger expiry. This prevents deadlocked jobs and enables third-party cleanup bots.

5. **Chain clock for deadlines.** On local devnet, the `sui::clock::Clock` object progresses with validator checkpoints (~2 second resolution), not wall-clock time. Test scripts poll the chain clock to detect deadline passage.

---

## What Remains Untestable Until March 11

1. **Game-native jump integration.** `jump_with_permit` requires AdminACL + sponsorship in the real game world. The courier's physical transit happens in-game, not on-chain.

2. **SSU ↔ in-game inventory bridge.** Real `withdraw_item` and `deposit_item` require game-server coordination. Our Phase 1 test uses the raw on-chain SSU calls, which work on localnet but don't model the game-server handshake.

3. **Cross-extension composition.** Combining courier escrow with gate extension (toll + jump) in a single PTB requires the deployed game world with all assemblies configured.

4. **EVE coin (Coin<EVE>).** The real game uses EVE tokens for tolls and payments. Localnet only has SUI.

5. **Multi-party delivery proof.** Production might use SSU deposit events, oracle attestations, or proximity proofs as delivery triggers instead of creator confirmation.

---

## Files

| File | Purpose |
|------|---------|
| `sources/courier_escrow.move` | Economic contract: escrow, collateral, deadline, state machine |
| `sources/atomic_transfer.move` | Phase 1: SSU-to-SSU atomic transfer test |
| `sources/config.move` | Extension pattern (ExtensionConfig + AdminCap + XAuth) |
| `scripts/utils.ts` | Shared test utilities (RPC, signing, balance, chain time) |
| `scripts/01_post_accept_complete.ts` | Happy path test |
| `scripts/02_post_accept_expire.ts` | Expiry + collateral slashing test |
| `scripts/03_cancel_before_accept.ts` | Cancellation test |
| `phase3-reseed-and-test.ts` | Phase 1 atomic transfer test (prior work) |

---

## Environment

- **Network:** Local Sui devnet (Docker, `http://127.0.0.1:9000`)
- **Sui CLI:** 1.66.2-a9a6825eaf62
- **Chain ID:** cdda0001
- **Package:** `0xec1e614ee9c83a2aeb72fe1250590f345b56e2503d68d39e13a78f031cd17d26`
- **Published via:** `test-publish --with-unpublished-dependencies`
