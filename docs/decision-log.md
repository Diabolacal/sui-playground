# Decision Log

**Retention:** Carry-forward

Non-trivial technical and strategic decisions, newest first. See [operations/DECISIONS_TEMPLATE.md](operations/DECISIONS_TEMPLATE.md) for entry format.

---

## 2026-02-16 — Gate Lifecycle Documentation Reconciliation

- **Goal:** Post-rehearsal documentation reconciliation — fix known issues, propagate rehearsal status, verify and document single-extension constraint.
- **Decision:** Corrected runbook validation year (2025→2026). Added sponsored tx smoke test section to runbook. Verified single-extension constraint in `gate.move` and `storage_unit.move` source (`extension: Option<TypeName>`, `swap_or_fill`). Documented design consequence (all rule types must share one `Auth` witness type per gate/SSU). Updated roadmap risk register and remaining validation items to reflect rehearsal completion. Added rehearsal reference to strategy memo.
- **Files:** docs/operations/gate-lifecycle-runbook.md, docs/core/march-11-reimplementation-checklist.md, docs/strategy/hackathon-portfolio-roadmap.md, docs/strategy/civilizationcontrol-strategy-memo.md, docs/decision-log.md
- **Diff:** +45 / -8
- **Risk:** Low — documentation only
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Verified from source:** Single extension constraint (`Option<TypeName>` on Gate L73, StorageUnit L67), `swap_or_fill` behavior (gate.move L117), `with_defining_ids` usage (gate.move L117, L227), `verify_sponsor` public function signature (access_control.move L158)
- **Follow-ups:** None

## 2026-02-16 — Full Gate Lifecycle Rehearsal Completed

- **Goal:** Execute the complete 13-step gate lifecycle on local Sui devnet using world-contracts. Produce reproducible runbook and update Day-1 checklist with corrections.
- **Decision:** All 13 steps executed successfully: publish → AdminCap → governance → fuel/energy/gate config → Character → NetworkNode → fuel deposit → NWN online → anchor 2 gates → link gates (distance proof) → gates online → publish test extension → authorize extension → issue jump permit → jump with permit. 20 successful transactions total.
- **Files:** docs/operations/gate-lifecycle-runbook.md (NEW), docs/core/march-11-reimplementation-checklist.md (UPDATED with corrections), sandbox/validation/step2.sh–step13.sh, sandbox/validation/generate_distance_proof.mjs, sandbox/validation/derive_server_address.mjs
- **Diff:** +600 / -20 (runbook + scripts + checklist corrections)
- **Risk:** Low — sandbox validation; no production code
- **Gates:** typecheck N/A  build ✅ (Move packages published)  smoke: 20 devnet txs all SUCCESS
- **Key corrections discovered:**
  - Module `world::access` (NOT `world::access_control`)
  - PTB type args use inline `<Type>` syntax, NOT `--type-args`
  - `vector<u8>` uses `vector[0xHH,...]` format
  - Self-sponsorship does NOT work — must use different address
  - Extension packages need `[environments]` section + `Pub.local.toml`
- **Follow-ups:** None — runbook is carry-forward ready

## 2026-03-11 — ZK GatePass: Membership Circuit Implemented & Module Extracted

- **Goal:** Complete remaining ZK implementation: design Merkle membership circuit, extract standalone `zk_gate` module, validate on devnet
- **Decision:** All ZK kill gates passed. Membership circuit (depth 10, Poseidon(2), 2,430 constraints) implemented in Circom, compiled, trusted setup complete, proof generated and verified off-chain. Standalone `zk_gate` Move module extracted and published on local devnet. On-chain tests: valid proof verified, invalid proof rejected, dynamic config + gate composition working.
- **Files:** sandbox/validation/zk_membership/ (circuit, serializer, input generator), sandbox/validation/zk_gate/ (Move module), docs/operations/zk-gatepass-feasibility-report.md (§2.2 updated), docs/operations/shortlist-viability-validation-report.md (membership addendum), docs/strategy/hackathon-portfolio-roadmap.md (status updated), docs/strategy/civilizationcontrol-strategy-memo.md (status updated)
- **Diff:** +350 / -30 (circuit + Move module + doc updates)
- **Risk:** Low — sandbox validation; no production code
- **Gates:** typecheck N/A  build ✅ (Move build -e local)  smoke: 4 devnet tx all SUCCESS
- **Follow-ups:** World-contracts integration (Character, AdminACL, sponsored tx) during hackathon

## 2026-03-11 — ZK GatePass Upgraded to GREEN (Devnet Validated)

- **Goal:** Validate ZK Groth16 verification and ZK+gate composition on local devnet (tests 8–10)
- **Context:** Sandbox addendum capturing devnet evidence for ZK GatePass. Standalone Groth16 verify, negative test, and ZK-to-gate composition (ZKAuth witness consumed by `Auth: drop` generic) all confirmed working in single-PTB transactions.
- **Decision:** GREEN — ZK GatePass is fully validated. Prior composition gap (depth-0 constraint) is resolved. Membership circuit design + package extraction remain as March 11 implementation tasks.
- **Files:** docs/operations/shortlist-viability-validation-report.md (tests 8–10 added), docs/operations/zk-gatepass-feasibility-report.md (§2.1 evidence table added), sandbox/validation/zk_gatepass_validation/ (Move packages)
- **Diff:** +120 / -5
- **Risk:** Low — validation only; no production code
- **Gates:** typecheck N/A  build N/A  smoke: devnet tx digests verified
- **Follow-ups:** ~~Design membership circuit, extract `zk_gate` package from PoC wrapper, sponsored transaction integration~~ DONE (see entry above)

## 2026-02-16 — ZK GatePass Feasibility Validation Complete

- **Goal:** Determine if ZK-verified gate access (Groth16 membership proof) is feasible as a GateControl rule type within CivilizationControl
- **Context:** Four-subagent research sprint: ZK PoC audit, GateControl integration analysis, devnet feasibility assessment, kill-switch/fallback design. No hackathon code produced.
- **Decision:** YELLOW-GREEN — architecturally feasible, pursue on March 11 with disciplined kill checkpoints. Both primitives (Groth16 on Sui, gate extension witness) proven independently. Critical gap: composing them in single transaction (depth-0 constraint). Two-step fallback (P1) available if single-tx fails. Maximum 28-hour ZK budget (25% of sprint). *(Upgraded to GREEN on 2026-03-11 — see entry above.)*
- **Alternatives considered:** (1) Off-chain proof + signature relay — rejected, not trustless, judges see through it; (2) ZK as standalone entry — already ruled out in portfolio strategy; (3) Skip ZK entirely — rejected, +0.50 score uplift justifies bounded 28-hour risk
- **Files:** docs/operations/zk-gatepass-feasibility-report.md (new), docs/architecture/zk-killswitch-fallback-analysis.md (new), docs/operations/shortlist-viability-validation-plan.md (updated), docs/operations/shortlist-viability-validation-report.md (updated), docs/README.md (updated)
- **Diff:** +550 / -5
- **Risk:** Medium — bounded by kill criteria (Day 1: circuit compile, Day 2: on-chain verify, Day 3 AM: gate integration). *(All composition gates passed on 2026-03-11; membership circuit remains the primary implementation gate.)*
- **Gates:** typecheck N/A  build N/A  smoke N/A (research + docs only)
- **Follow-ups:** Execute Tests 11-13 on March 11; resolve package naming conflict; design membership circuit

## 2026-02-16 — Hackathon Portfolio Strategy Finalized

- **Goal:** Multi-entry submission strategy targeting Best Entry + 3 bonus categories
- **Context:** 28 ideas scored against 8 judging criteria; devnet validation completed 7/7 GREEN; adversarial strategy review reconciled into Track A flagship + Track C sprints model
- **Decision:** Four-track portfolio — Track A: CivilizationControl (flagship), Track C: Fortune Gate (Weirdest), Salvage Protocol (Creative), Corpse Toll Road (Utility), Track D: Loot Crate (conditional wildcard). ZK Gate Pass integrated into CC, not standalone. TribeMint demoted to stretch.
- **Alternatives considered:** (1) Single flagship-only — rejected, leaves bonus prizes uncontested; (2) ZK as standalone entry — rejected, weak standalone score (6.31), stronger as CC differentiator; (3) TribeMint as Track C — rejected, high integration cost with marginal judging score uplift
- **Files:** docs/strategy/hackathon-portfolio-roadmap.md (new)
- **Diff:** +620 / -0
- **Risk:** Medium — ZK integration complexity mitigated by graceful degradation to tribe+toll rules
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Follow-ups:** Verify multi-submission rules pre-March 1; storyboard all demos pre-March 11; no production code until March 11
