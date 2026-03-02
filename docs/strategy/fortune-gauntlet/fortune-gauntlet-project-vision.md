# Fortune Gauntlet — Project Vision

**Retention:** Carry-forward

---

## 1. Executive Summary

Fortune Gauntlet is a sequential gate-race extension for EVE Frontier where players sprint through a series of checkpoint gates — but passage at each checkpoint is probabilistic. An on-chain VRF roll (`sui::random`) determines whether a player is granted a jump permit (90%) or denied and hit with an escalating cooldown (10%). On-chain timestamps serve as the verifiable referee. The concept targets the **Weirdest Idea** prize category as a sprint-grade entry, buildable in ~1.5 days.

**Working title origin:** "Fortune" (VRF randomness from Fortune Gate, ID 26) + "Gauntlet" (sequential multi-gate race from Wildcard Concept #6).

---

## 2. Player-Facing Pitch

You enter the Gauntlet — three gates, one path, no guarantees. At each checkpoint, the chain rolls the dice. Pass, and you jump instantly. Fail, and you wait, watching your cooldown tick down while others race ahead. Every outcome is verifiable on-chain. The fastest ship doesn't always win. Luck, timing, and nerve decide who clears the Gauntlet first.

---

## 3. Core Loop

```
Player arrives at Checkpoint 1 (Gate A)
  │
  ├─ Calls try_issue_permit (entry fun, takes &Random)
  │
  ├─ VRF rolls: 90% SUCCESS → JumpPermit issued → player jumps → Checkpoint 2
  │
  └─ VRF rolls: 10% DENIAL → cooldown set (15s × denial_count)
       │                       CheckpointDeniedEvent emitted
       │
       └─ Wait for cooldown → retry try_issue_permit → ...
                                │
                                └─ (loop until success)
  
Checkpoint 2 (Gate B) → same loop
Checkpoint 3 (Gate C) → same loop → RaceCompletedEvent

On-chain record: sequence of CheckpointPassed / CheckpointDenied events
                 with timestamps → verifiable race timeline
```

**Sequence enforcement:** Per-player `PlayerProgress` dynamic field on ExtensionConfig tracks `last_checkpoint`. The extension rejects out-of-order attempts.

**Escalating consequence:** Each denial at the same checkpoint increases cooldown duration (`base_cooldown × denial_count`). First denial: 15 seconds. Second: 30 seconds. Third: 45 seconds. This prevents trivial retry-spam while creating real tension.

---

## 4. Why Sui / Why Frontier

| Question | Answer |
|----------|--------|
| **Why blockchain at all?** | The chain is the referee. VRF randomness is verifiable — no trusted server, no "rigged" accusations. Timestamps are consensus-validated. Race results are permanently on-chain. |
| **Why Sui specifically?** | `sui::random` provides native VRF with MEV-resistance (seed rotates per epoch, committed before tx execution). Dynamic fields allow per-player state on shared objects. Sub-second finality keeps the race fast. |
| **Why EVE Frontier?** | Gates are real in-world infrastructure. Jump permits are a first-class game primitive. The "dangerous passage through space" theme is native to EVE. This isn't a synthetic minigame — it uses the actual travel system with added stakes. |

---

## 5. On-Chain Surfaces Used

| Primitive | Usage | Source |
|-----------|-------|--------|
| `sui::random::Random` | VRF roll at each checkpoint to determine pass/deny | Sui framework (address `0x8`) |
| `gate::issue_jump_permit<Auth>` | Issue time-bounded jump permit on success | world-contracts `gate.move` |
| `gate::jump_with_permit` | Player executes the jump (consumes permit) | world-contracts `gate.move` |
| `sui::clock::Clock` | Current timestamps for permit expiry, cooldown enforcement, race windows | Sui framework |
| Dynamic fields on `ExtensionConfig` | Per-gate checkpoint config (`GateCheckpointKey`), per-player progress (`PlayerProgressKey`), global race config (`RaceConfigKey`) | builder-scaffold pattern |
| Custom events | `CheckpointPassedEvent`, `CheckpointDeniedEvent`, `RaceCompletedEvent` | Extension module |
| `ExtensionConfig` + `AdminCap` + `XAuth` | Standard extension singleton, admin capability, witness type | builder-scaffold pattern |

**Key constraint:** `sui::random` requires the consuming function to be `entry`, not `public`. This is compatible because `issue_jump_permit` transfers internally (no return value needed). The `try_issue_permit` entry function is the sole PTB command for permit requests.

---

## 6. Consequence Model

### Primary: Escalating Cooldown (implemented)

On denial, a `cooldown_until_ms` timestamp is written to the player's `PlayerProgress` dynamic field. The cooldown escalates with repeated denials at the same checkpoint:

| Denial # | Cooldown | Cumulative wait (worst case) |
|:--------:|:--------:|:----------------------------:|
| 1st | 15 seconds | 15s |
| 2nd | 30 seconds | 45s |
| 3rd | 45 seconds | 90s |

The extension checks `clock.timestamp_ms() >= cooldown_until_ms` before allowing retry.

### Secondary: Denial Events (future-proof)

Every denial emits a `GauntletDenialEvent` containing `character_id`, `gate_id`, `checkpoint_number`, `roll`, and `timestamp_ms`. These events are permanent on-chain records consumable by future systems (turret targeting, reputation scoring, leaderboards).

### Stretch: Turret Integration (conditional — 🔮 future)

If turret assemblies become available in world-contracts:
- A `marked_for_turrets: bool` field in `PlayerProgress` activates after N denials
- Turret systems consume the mark to target the player temporarily
- Game-knowledge note: turrets take ~30 seconds to lock small ships, creating a "run the gauntlet" skill check on top of the RNG

**Turrets are NOT a dependency.** The cooldown model stands alone. Turret integration is framed as a future extension, not a current feature.

### Tuning Knobs

| Parameter | Default | Range | Location |
|-----------|:-------:|:-----:|----------|
| `success_threshold` | 90 (= 10% denial) | 85–95 | Per-gate `GateCheckpoint` DF |
| `cooldown_base_ms` | 15,000 (15s) | 10,000–30,000 | Per-gate `GateCheckpoint` DF |
| `permit_expiry_ms` | 60,000 (60s) | 30,000–120,000 | Per-gate `GateCheckpoint` DF |
| `total_checkpoints` | 3 | 2–5 | `RaceConfig` DF |
| `race_end_ms` | start + 10 min | configurable | `RaceConfig` DF |

All parameters are admin-configurable via DF writes — no redeployment needed.

---

## 7. Demo Plan (2–3 minutes)

### Beat Sheet

| Time | Beat | What's shown | On-chain proof |
|------|------|-------------|----------------|
| 0:00–0:20 | **Setup** | Show 3 linked gates on map. Explain: "Three checkpoints. 90% chance you pass. 10% you wait." | Config tx digest showing `GateCheckpoint` DFs |
| 0:20–0:50 | **Clean checkpoint** | Player attempts Checkpoint 1. VRF rolls success. Permit issued. Player jumps. | `CheckpointPassedEvent` with roll value + timestamp |
| 0:50–1:20 | **Denial moment** | Player attempts Checkpoint 2. VRF rolls denial (~10% chance). Cooldown timer shown. "You rolled a 7. 15 seconds." | `CheckpointDeniedEvent` with roll, cooldown timestamp |
| 1:20–1:40 | **Retry + success** | Cooldown expires. Player retries. VRF rolls success. Player jumps. | Second `CheckpointPassedEvent` on same gate |
| 1:40–2:10 | **Final checkpoint** | Player attempts Checkpoint 3. Success. `RaceCompletedEvent` emitted. | Full event timeline: 3 passed, 1 denied, verifiable timestamps |
| 2:10–2:30 | **Proof moment** | Show on-chain event log. "Every roll, every timestamp, every outcome — verifiable. The chain is the referee." | Transaction explorer showing event sequence |

### Demo Requirements

- 3 gates linked in sequence (owned by demo character)
- Extension published + configured with checkpoint roles
- AdminACL sponsor operational for `jump_with_permit`
- At least 2 demo runs recorded (1 clean, 1 with denial)
- Event indexer or explorer for proof moment

### Demo Fallback

If `sui::random` is unavailable: run as deterministic Gauntlet (sequential race without VRF). The race mechanic and time pressure remain compelling; only the randomness layer is lost. Demo pivots from "VRF obstacle course" to "on-chain checkpoint race."

---

## 8. MVP Boundaries

### In Scope (MVP)

- Single Move extension package with `try_issue_permit` entry function
- 3 checkpoint gates with per-gate DF configuration
- Per-player `PlayerProgress` tracking with sequential enforcement
- Escalating cooldown on denial
- Custom events for all outcomes
- Admin scripts (TS): configure gates, set race params, reset state
- Player scripts (TS): attempt checkpoint, jump with permit
- Recorded demo video (2–3 minutes)

### Explicit Non-Goals

- **No turret integration** — proxy cooldown only; turret events are emitted but not consumed
- **No frontend UI** — CLI/script-driven; no web app, no CSS slot-machine animation
- **No leaderboard** — events support one, but building an indexer + UI is out of scope
- **No prize escrow** — the original Gauntlet concept included `Coin<EVE>` escrow for winners; MVP omits this to reduce complexity
- **No multi-race concurrency** — one race config active at a time
- **No in-game browser integration** — wallet signing happens via CLI tooling
- **No cross-package composability** — `entry` function constraint means `try_issue_permit` cannot be chained in PTBs with other extension calls

---

## 9. Risks & Kill Criteria

| # | Risk | Severity | Kill? | Mitigation |
|---|------|:--------:|:-----:|------------|
| 1 | `sui::random` unavailable on hackathon test server | High | Soft | Fall back to deterministic Gauntlet — still viable for Most Creative |
| 2 | Cannot link 3+ owned gates in test environment | Medium | Soft | Reduce to 2 checkpoints (minimum viable) |
| 3 | `jump_with_permit` sponsor infra not operational | High | Hard | Kills ALL gate extensions, not just Fortune Gauntlet — shared portfolio risk |
| 4 | Combined scope exceeds 2-day sprint budget | Medium | Soft | Drop VRF → deterministic Gauntlet, or drop sequence → single Fortune Gate |
| 5 | Randomness MEV (players observe roll, abort to retry) | Low | No | Sui `Random` is designed to prevent this; verify on March 11 |
| 6 | DF contention on shared ExtensionConfig | Low | No | Acceptable for demo (<100 players); architect partition if scaling |
| 7 | Extension slot conflict with CivilizationControl | Medium | No | Use separate gates — Fortune Gauntlet gates are distinct from CC toll gates |

### Graceful Degradation Path

```
Fortune Gauntlet (full)
  │ if sui::random unavailable
  ▼
Deterministic Gauntlet (race without VRF)
  │ if multi-gate linking fails
  ▼
Fortune Gate (single probabilistic gate)
  │ if all gate extensions fail
  ▼
No entry in this category
```

Each degradation level is a strict subset of the one above — no wasted work.
