# Demo Evidence Appendix — Beat-to-Script Mapping

**Retention:** Carry-forward

> Operational appendix mapping every demo beat that references a tx digest, CLI command, failed PTB, balance delta, lifecycle execution, trade settlement, or policy deployment to its executable source.
>
> Companion to: [civilizationcontrol-demo-beat-sheet.md](../core/civilizationcontrol-demo-beat-sheet.md)
> Cross-reference: [civilizationcontrol-claim-proof-matrix.md](../core/civilizationcontrol-claim-proof-matrix.md)
> Last updated: 2026-02-19

---

## Script Inventory Summary

| Domain | Key Scripts | Location |
|---|---|---|
| Gate lifecycle (full) | `gate_lifecycle_rehearsal.sh` (1308 lines), `gate_lifecycle_steps.sh` (613 lines) | `sandbox/validation/` |
| Gate lifecycle (individual) | `step2.sh` – `step13.sh` (12 scripts) | `sandbox/validation/` |
| Trade / SSU | `ssu_trade_test.sh` (459 lines) | `sandbox/validation/` |
| ZK GatePass | `publish_zk.sh`, `zk_proof_gen.sh` | `sandbox/validation/` |
| ZK Membership | `generate_test_input.js`, `serialize_membership_for_sui.js` | `sandbox/validation/zk_membership/` |
| Distance proof | `generate_distance_proof.mjs` / `.js` | `sandbox/validation/` |
| Server address derivation | `derive_server_address.mjs` | `sandbox/validation/` |
| Object parsing | `extract_objects.py`, `parse_step.py` | `sandbox/validation/` |
| EVE Vault signing | `App.tsx` (signing smoke test) | `sandbox/evevault-signing-smoke/` |
| Runbook (embedded CLI) | `gate-lifecycle-runbook.md` (all 16 steps with PTB syntax) | `docs/operations/` |

---

## Appendix A — Primary Demo Variant (3 Minutes)

### Beat 1 — Raw CLI Contrast (0:00–0:25)

**What the beat shows:** Raw `sui client ptb` commands, dense terminal output, a failed PTB error, Discord coordination screenshot.

| Field | Value |
|---|---|
| **Script** | `sandbox/validation/gate_lifecycle_rehearsal.sh` (replays full 13-step lifecycle) |
| **Command** | `cd sandbox/validation && bash gate_lifecycle_rehearsal.sh` |
| **Expected Output** | 17+ tx digests scrolling in terminal, dense PTB text, object IDs |
| **Capture Method** | Terminal screen recording of the script running (first 30s of output). Alternatively, paste raw PTB commands from `docs/operations/gate-lifecycle-runbook.md` Steps 8–13 into terminal and let them scroll. |
| **Failed PTB capture** | Run any step with a deliberate bad parameter (e.g., wrong object ID in `step13.sh`) to produce `MoveAbort` or `InvalidInput` error on screen. |
| **Script exists?** | YES — `gate_lifecycle_rehearsal.sh` and all `step*.sh` exist and produce terminal output |

**Gap:** No dedicated "intentional failure demo" script. The failed PTB screenshot can be produced by running any step with a wrong object ID — trivial to capture ad hoc. **Low priority — no script required.**

---

### Beat 2 — The Reveal: Command Overview (0:25–0:50)

**What the beat shows:** CivilizationControl UI loading — Command Overview with structures, status, Strategic Network Map, Signal Feed.

| Field | Value |
|---|---|
| **Script** | N/A — UI demo, no CLI script |
| **Command** | Start frontend dev server: `cd <frontend-dir> && npm run dev` |
| **Expected Output** | Command Overview UI fully rendered with operator's structures |
| **Capture Method** | Screen recording of the running web application |
| **Package ID overlay** | From world publish: `sandbox/validation/publish_world.sh` output or submission chain publish |
| **Script exists?** | NO — **frontend application not yet built** |

**Gap:** TODO — Frontend application required. This is the primary hackathon deliverable, not a rehearsal script gap. The Package ID to overlay comes from the world-contracts publish step (scripted).

---

### Beat 3 — Control: Set Gate Policy (0:50–1:20)

**What the beat shows:** Operator configures tribe filter + toll → clicks "Deploy Policy" → tx digest of policy deployment → gate object showing extension + dynamic fields.

**Evidence artifacts:**

**(a) Extension deployment + authorization (CLI equivalent):**

| Field | Value |
|---|---|
| **Script** | `sandbox/validation/step11.sh` (publishes extension, authorizes on both gates) |
| **Command** | `cd sandbox/validation && bash step11.sh` |
| **Expected Output** | Extension package ID + 2 authorize tx digests |
| **Prior evidence** | Gate A authorize: `2miDiePXprTSj1Hfso88fHnwTUrE8ZbgaTVCiRLHF75x`, Gate B: `FPDV7Ur72fhEGfdVSi6kkTRyjntKfjidU23tcHYDZcS2` |
| **Capture Method** | Tx digest overlay from terminal output. Gate object state: `sui client object <gate-id> --json` showing `extension: Some(TypeName)` |
| **Script exists?** | YES — `step11.sh` (full publish+auth), `step11cd.sh` (auth-only) |

**(b) Gate object state before/after:**

| Field | Value |
|---|---|
| **Command** | `sui client object $GATE_A_ID --json` (run before and after step11) |
| **Expected Output** | Before: `extension: None`. After: `extension: Some({package}::module::AuthType)` + dynamic fields for rules |
| **Capture Method** | Terminal output diff or explorer screenshot |

**Gap:** The sandbox test extension (`test_gate_ext`) is a minimal pass-through. The submission extension (tribe filter + toll composing) does not yet have a deploy script. **TODO — Submission extension deploy script required** (must publish the production CivilizationControl extension and authorize on gates). The PTB pattern is identical to `step11.sh` — only the Move package and type parameter change.

---

### Beat 4 — Consequence A: Hostile Denied (1:20–1:45)

**What the beat shows:** Wrong-tribe pilot attempts jump → blocked → MoveAbort with ETribeMismatch → Signal Feed shows denied event.

| Field | Value |
|---|---|
| **Script** | **NONE — TODO** |
| **Command (expected)** | `sui client ptb --move-call $WORLD_PKG::gate::jump --args $CHARACTER_B $GATE_A @$SPONSOR_BYTES --gas-budget 50000000` (PLAYER_B with wrong tribe, no permit → abort) |
| **Expected Output** | `MoveAbort` in `(extension_module::tribe_permit, 0)` = ETribeMismatch. Failed tx recorded on-chain. |
| **Prior evidence** | Claim-proof matrix references devnet checkpoint ~6500 (sandbox). Digest: `[TBD-digest]` for submission. |
| **Capture Method** | Terminal error output showing `MoveAbort` + abort code. Explorer view of failed tx if available. |
| **Script exists?** | NO |

**Gap: TODO — Hostile denial rehearsal script required.** Must:
1. Use a second address (PLAYER_B) with a tribe that doesn't match the gate's tribe filter.
2. Attempt `gate::jump` (without permit) or `gate::jump_with_permit` with a wrong-tribe permit.
3. Capture the `MoveAbort` code and failed tx digest.
4. Pattern: similar to `step13.sh` but with PLAYER_B who fails the tribe check.

---

### Beat 5 — Consequence B: Ally Tolled (1:45–2:10)

**What the beat shows:** Matching-tribe pilot jumps → toll paid (5 SUI) → `TollCollectedEvent` → operator balance +5 SUI → Signal Feed green entry.

**Evidence artifacts:**

**(a) Jump with permit (basic lifecycle — scripted):**

| Field | Value |
|---|---|
| **Script** | `sandbox/validation/step12.sh` (issue permit) + `sandbox/validation/step13.sh` (jump with permit) |
| **Command** | `cd sandbox/validation && bash step12.sh && bash step13.sh` |
| **Expected Output** | JumpPermit ID + Jump tx digest + `JumpEvent` emitted |
| **Prior evidence** | Permit: `HTAR5Hmsj8LsFfzuunDJxNBEk2amHisCi95nzsMLetRa`, Jump: `CzjEQmyRnKmUuCCLyEn8SmVVFogG4mmp6iZMPtvrXGs6` |
| **Script exists?** | YES — basic jump lifecycle fully scripted |

**(b) Toll collection + balance delta (toll extension — not yet integrated):**

| Field | Value |
|---|---|
| **Script** | **NONE for integrated toll flow — TODO** |
| **Move source** | `sandbox/validation/gate_toll_validation/sources/gate_toll.move` (standalone toll logic, 241 lines) |
| **Expected Output** | `TollCollectedEvent` with `{payer, collector, amount}` + balance delta |
| **Balance capture** | `sui client gas $OPERATOR_ADDRESS` before and after jump |
| **Prior evidence** | Standalone gate_toll tests passed on devnet (claim-proof matrix: checkpoint ~6260). Digest: `[TBD-digest]` for submission. |
| **Script exists?** | PARTIALLY — toll Move module exists but no integrated rehearsal script |

**Gap: TODO — Toll collection rehearsal script required.** Must:
1. Publish the toll extension (or submission extension with toll rule).
2. Authorize on gate.
3. Issue permit to matching-tribe pilot (includes toll payment in PTB via `--split-coins`).
4. Execute jump → capture `TollCollectedEvent` + balance delta.
5. Pattern: combine `step11.sh` (deploy) + `step12.sh` (permit) + `step13.sh` (jump) with toll-aware extension.

---

### Beat 6 — Commerce: Ally Buys at TradePost (2:10–2:40)

**What the beat shows:** Buyer selects fuel rod listing → Buy → atomic settlement → `TradeSettledEvent` → buyer gets item, seller gets payment → Signal Feed update.

| Field | Value |
|---|---|
| **Script** | `sandbox/validation/ssu_trade_test.sh` (459 lines — full SSU-backed trade lifecycle) |
| **Command** | `cd sandbox/validation && bash ssu_trade_test.sh` |
| **Expected Output** | 6+ tx digests: publish, setup_storefront, authorize_ext, stock_item, list_item, buy. Events: `ItemListed`, `ItemSold`/`ItemPurchased`. Balance deltas for buyer and seller. |
| **Prior evidence** | Full results in `sandbox/validation/ssu_trade_results.txt` (167 lines). Key digests: Publish `49KABHpbQJ1sDmkHvYdUTr9S8JWgjpgwu152Nmz1Qg7z`, Buy `42Uc2VqSGuHx9rYqBRNFJ3gUhgDpGmY76mjtVDM6usvw`. Seller +5 SUI, Buyer −5 SUI confirmed. |
| **Capture Method** | Terminal output from script run. Explorer tx view for buy digest. Balance comparison: `sui client gas $SELLER` / `sui client gas $BUYER` before and after. |
| **Script exists?** | YES — fully scripted with prior evidence |

**Move sources:**
- `sandbox/validation/trade_post_validation/sources/trade_post.move` (206 lines — cross-address atomic buy)
- `sandbox/validation/trade_post_validation/sources/ssu_trade.move` (237 lines — SSU-backed storefront)
- `sandbox/validation/trade_post_validation/sources/mock_ssu.move` (207 lines — mock SSU for standalone testing)

**Gap:** Script uses mock SSU (standalone). Submission on hackathon test server requires targeting real world-contracts SSU. **TODO — Submission trade script required** (same PTB pattern, different package addresses and world-contracts SSU objects). The Move logic is validated; only the target objects change.

---

### Beat 7 — The System: Revenue Visible (2:40–3:00)

**What the beat shows:** Pull back to full Command Overview — aggregate revenue, structure counts, Signal Feed with mixed jump + trade events.

| Field | Value |
|---|---|
| **Script** | N/A — UI screenshot/recording |
| **Command** | Navigate to Command Overview in running frontend |
| **Expected Output** | Aggregate revenue total (toll + trade), structure count badge, Signal Feed with deny + toll + trade events |
| **Capture Method** | Screen recording of the fully populated Command Overview |
| **Script exists?** | N/A — UI-only beat, no rehearsal script needed |

**Gap:** Depends on frontend application (Beat 2 gap). Revenue aggregation is a read-path operation — `sui client object` queries or indexer events. No separate script needed; the UI computes this from on-chain data at display time.

---

## Appendix B — Optional ZK Accent Segment (30 seconds)

**What the beat shows:** ZK gate pass — pilot proves membership without revealing identity → Groth16 verifies on-chain → gate opens.

**(a) Basic Groth16 verification:**

| Field | Value |
|---|---|
| **Script** | `sandbox/validation/publish_zk.sh` (publish package) + CLI call to `groth16_test::verify_multiplier_proof` |
| **Command** | `cd sandbox/validation && bash publish_zk.sh` then `sui client call --package $ZK_PKG --module groth16_test --function verify_multiplier_proof --gas-budget 50000000` |
| **Expected Output** | `VerificationResult` event: `is_valid: true`. Gas: ~1,009,880 MIST. |
| **Prior evidence** | Digest: `AkEBgfdpGxHDNXVJ6HBAKFooWnD6F47gcYAzPnCbahQq` |
| **Capture Method** | Terminal output showing event data + gas cost. Explorer tx view. |
| **Script exists?** | YES — publish scripted, call documented |

**(b) ZK + gate witness composition:**

| Field | Value |
|---|---|
| **Script** | CLI call to `zk_gate_compose::verify_and_issue_auth` + `zk_gate_compose::consume_auth` |
| **Command** | (see `sandbox/validation/zk_gatepass_validation/sources/zk_gate_compose.move` for entry functions) |
| **Expected Output** | `CompositionResult` event: `zk_verified: true, auth_consumed: true` |
| **Prior evidence** | Digest: `EXM4RgMvYBba3RGFen6Ds8vtNthnaZvfsMP9BeEeDdik` |
| **Script exists?** | PARTIALLY — Move module exists, no wrapper shell script for one-command execution |

**(c) Membership circuit (Merkle proof):**

| Field | Value |
|---|---|
| **Script** | `sandbox/validation/zk_membership/generate_test_input.js` (build Merkle tree + proof inputs) + `sandbox/validation/zk_membership/serialize_membership_for_sui.js` (convert to Sui format) |
| **Command** | `cd sandbox/validation/zk_membership && node generate_test_input.js && node serialize_membership_for_sui.js` |
| **Expected Output** | `input.json`, `tree_info.json`, hex vectors for Move constants |
| **Prior evidence** | Package: `0xc0af245bb364485749ccc8dae4cfd86b3af4fea6b2aa54b9a7970dbae322ea00` |
| **Script exists?** | YES — proof generation scripted. On-chain verification: call documented in feasibility report. |

**Gap:** No single end-to-end ZK accent rehearsal script. **Low priority** — individual steps are scripted, and the ZK accent is optional. Can be composed from existing scripts during rehearsal.

---

## Appendix C — Fallback Demo Variant (GateControl-Only, 2 Minutes)

All fallback beats map to the same scripts as their primary counterparts. Cross-reference:

| Fallback Beat | Primary Beat | Script Reference |
|---|---|---|
| Fallback Beat 1 — The Problem | Beat 1 | `gate_lifecycle_rehearsal.sh` (same) |
| Fallback Beat 2 — The Reveal | Beat 2 | Frontend app (same gap) |
| Fallback Beat 3 — Set Gate Policy | Beat 3 | `step11.sh` / `step11cd.sh` (same) |
| Fallback Beat 4 — Hostile Denied | Beat 4 | **TODO — same gap** |
| Fallback Beat 5 — Ally Tolled + Revenue | Beat 5 | `step12.sh` + `step13.sh` (basic); toll gap same |
| Fallback Beat 6 — Close | Beat 7 | Frontend app (same gap) |

No additional scripts required for the fallback variant beyond what the primary variant needs.

---

## Appendix D — Gap Analysis Summary

### Scripts Fully Executable (No Gaps)

| Beat | Script | Status |
|---|---|---|
| Beat 1 — Raw CLI Contrast | `gate_lifecycle_rehearsal.sh`, all `step*.sh` | READY — produces all raw terminal output needed |
| Beat 6 — Ally Buys (mock SSU) | `ssu_trade_test.sh` | READY — full lifecycle with mock SSU, all tx digests captured |
| ZK Accent — Groth16 | `publish_zk.sh` + CLI call | READY — prior evidence available |
| ZK Accent — Membership | `generate_test_input.js` + `serialize_membership_for_sui.js` | READY — proof generation scripted |

### Gaps Requiring New Scripts

| Priority | Beat | Gap | Required Script | Effort |
|---|---|---|---|---|
| **HIGH** | Beat 4 — Hostile Denied | No script produces a denied jump with `MoveAbort` | `hostile_jump_denied.sh` — attempt jump with wrong-tribe character, capture abort code | ~30 lines, pattern from `step13.sh` |
| **HIGH** | Beat 5 — Ally Tolled (toll collection) | Toll extension not integrated in rehearsal flow | `toll_jump_rehearsal.sh` — deploy toll extension, issue permit with toll, jump, capture `TollCollectedEvent` + balance delta | ~80 lines, composes `step11.sh` + `step12.sh` + `step13.sh` with toll extension |
| **MEDIUM** | Beat 3 — Policy Deploy (submission extension) | Test extension (`test_gate_ext`) is pass-through; submission needs tribe+toll extension | `deploy_policy.sh` — publish production extension + authorize on gate | ~50 lines, pattern from `step11.sh` |
| **MEDIUM** | Beat 6 — Ally Buys (world-contracts SSU) | Script targets mock SSU; submission needs real world-contracts SSU | `submission_trade_test.sh` — same PTB pattern, real SSU objects | ~80 lines, refactor of `ssu_trade_test.sh` |
| **LOW** | ZK Accent — end-to-end | Individual steps scripted but no single-command rehearsal | `zk_accent_rehearsal.sh` — compose existing scripts | ~40 lines |

### Gaps That Are Not Script Gaps

| Beat | Gap | Nature |
|---|---|---|
| Beat 2 — Command Overview | Frontend application not built | **Hackathon deliverable** — not a rehearsal script gap |
| Beat 7 — Revenue Visible | Depends on frontend | Same as above |
| All beats — Submission chain | Sandbox digests are proof-of-pattern; submission digests TBD | **Pre-recording task** — re-run scripts on hackathon test server |

---

## Appendix E — Supporting Utilities Reference

These utilities are called by the main scripts and rarely need independent execution:

| Utility | Called By | Purpose |
|---|---|---|
| `generate_distance_proof.mjs` / `.js` | `step9.sh`, `gate_lifecycle_*.sh` | BCS-serialized Ed25519 distance proof for `gate::link_gates` |
| `derive_server_address.mjs` | `step3.sh`, `gate_lifecycle_*.sh` | Derives Sui address from Ed25519 private key for server registration |
| `extract_objects.py` | `gate_lifecycle_steps.sh` | Parses `sui client` JSON output for object IDs and types |
| `parse_step.py` | Various step scripts | Quick object-by-type lookup from tx output |
| `serialize_for_sui.js` | ZK scripts | Converts snarkjs Groth16 proof to Sui arkworks compressed format |
| `check_crypto.js`, `check_blake2.mjs` | Manual diagnostics | Verify Node.js crypto support (not part of demo flow) |

---

## Appendix F — Evidence Capture Quick Reference

For each evidence type referenced in the beat sheet:

| Evidence Type | Capture Command | Output |
|---|---|---|
| Tx digest | Included in script output (grep for `Digest:` or `_DIGEST:`) | Base58 string (e.g., `CzjEQmyRnKmUuCCLyEn8SmVVFogG4mmp6iZMPtvrXGs6`) |
| MoveAbort code | Visible in failed tx output (`effects.status.error`) | Module + function + abort code (e.g., `MoveAbort(_, 0)`) |
| Object state | `sui client object $OBJECT_ID --json` | JSON with fields, type, owner |
| Balance delta | `sui client gas $ADDRESS` before and after tx | MIST balance comparison |
| Events | `sui client events --tx-digest $DIGEST` or included in tx output | Event type + parsed fields |
| Explorer view | `https://<explorer>/txblock/$DIGEST` | Browser screenshot |
| Package ID | Included in publish script output (`PACKAGE_ID:`) | `0x...` hex string |
