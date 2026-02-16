# Decision Log

**Retention:** Carry-forward

Non-trivial technical and strategic decisions, newest first. See [operations/DECISIONS_TEMPLATE.md](operations/DECISIONS_TEMPLATE.md) for entry format.

---

## 2026-02-16 — ZK GatePass Feasibility Validation Complete

- **Goal:** Determine if ZK-verified gate access (Groth16 membership proof) is feasible as a GateControl rule type within CivilizationControl
- **Context:** Four-subagent research sprint: ZK PoC audit, GateControl integration analysis, devnet feasibility assessment, kill-switch/fallback design. No hackathon code produced.
- **Decision:** YELLOW-GREEN — architecturally feasible, pursue on March 11 with disciplined kill checkpoints. Both primitives (Groth16 on Sui, gate extension witness) proven independently. Critical gap: composing them in single transaction (depth-0 constraint). Two-step fallback (P1) available if single-tx fails. Maximum 28-hour ZK budget (25% of sprint).
- **Alternatives considered:** (1) Off-chain proof + signature relay — rejected, not trustless, judges see through it; (2) ZK as standalone entry — already ruled out in portfolio strategy; (3) Skip ZK entirely — rejected, +0.50 score uplift justifies bounded 28-hour risk
- **Files:** docs/operations/zk-gatepass-feasibility-report.md (new), docs/architecture/zk-killswitch-fallback-analysis.md (new), docs/operations/shortlist-viability-validation-plan.md (updated), docs/operations/shortlist-viability-validation-report.md (updated), docs/README.md (updated)
- **Diff:** +550 / -5
- **Risk:** Medium — bounded by kill criteria (Day 1: circuit compile, Day 2: on-chain verify, Day 3 AM: gate integration)
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
