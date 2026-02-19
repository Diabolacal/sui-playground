# Decision Log

**Retention:** Carry-forward

Non-trivial technical and strategic decisions, newest first. See [operations/DECISIONS_TEMPLATE.md](operations/DECISIONS_TEMPLATE.md) for entry format.

---

## 2026-02-19 — Hybrid Spatial Architecture (EF-Map Context + Native SVG Control)

- **Goal:** Resolve the spatial layer architecture for CivilizationControl. Determine how the Command Overview presents spatial/topological information about the operator's gate network, trade posts, and NWNs.
- **Decision:** **Hybrid model adopted.** Two complementary layers: (1) **Strategic Network Map** — CivControl-native SVG topology (~150–200 LoC React component). Primary operational surface. Renders governance topology from manual spatial pins (§8) + on-chain state. System nodes with structure badges, gate link lines with status encoding. Clickable, reactive, expandable. (2) **Cosmic Context Map** — EF-Map embed iframe (~10 LoC). Secondary orientational layer. Highlights operator systems in EVE Frontier starfield. Draws colored link lines between linked systems (EF-Map capability being added). Read-only, collapsible, non-blocking. **Why embed-only rejected:** EF-Map supports 0 of 12 required visual primitives (no custom markers, no per-structure status, no governance labels, no event animation, no runtime state updates). Category mismatch, not feature gap. **Why native-only rejected:** Loses EVE Frontier cosmic grounding needed for hackathon judges. **Scope discipline:** No SVG implementation before March 11 (hackathon start). Representation approach (system-level nodes vs expandable clusters vs lens toggling) deferred to build phase.
- **Files:** docs/architecture/spatial-embed-requirements.md (updated: RESOLVED status, scope discipline, representation options, EF-Map link-line capability), docs/ux/civilizationcontrol-ux-architecture-spec.md (updated: §9 rewritten, stretch items 12/16/17 resolved, §13 topology placement, Trigger 2 forward-ref, interaction philosophy), docs/core/civilizationcontrol-demo-beat-sheet.md (updated: Beat 2 + Beat 7 spatial references), docs/strategy/civilizationcontrol-product-vision.md (forward-ref), docs/strategy/civilizationcontrol-strategy-memo.md (forward-ref), docs/strategy/hackathon-portfolio-roadmap.md (forward-ref), docs/architecture/authenticated-user-surface-analysis.md (forward-ref), docs/decision-log.md (this entry)
- **Diff:** ~+180 revised / -50 replaced = net +130 across 8 files
- **Risk:** Low — docs/architecture only, no code changes
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Follow-ups:** Finalize SVG representation approach during build phase (post-March 11). Confirm EF-Map colored link-line capability is available before hackathon. Test EF-Map embed iframe performance in demo recording environment.

## 2026-02-18 — Sponsor Risk Reclassification + Audit Consolidation

- **Goal:** Correct over-weighted AdminACL sponsor risk classification using expected-value reasoning. Consolidate 6 granular audit files into clean repo structure.
- **Decision:** AdminACL sponsor access reclassified from CRITICAL to **HIGH (environment-dependent)**. Probability model: ~65% auto-sponsor (Stillness model), ~25% specific wallet path, ~10% no access. Expected cost: ~1.1 hours Day-1 validation. Pre-March organizer escalation replaced with empirical Day-1 Sponsor Validation Protocol (60 min). Even worst-case has fallbacks: Stillness deployment window (April 1–14), silent pre-submission deploy, or local devnet. Six granular audit files (A–F, ~2,100 lines) consolidated into single `sweep-audit-artifacts-2026-02-18.md`. Rationale: sweep document is canonical output; audit files are working notes not individually referenceable.
- **Files:** docs/architecture/structural-risk-sweep-2026-02-18.md (revised: §1, §3, §4, §5 E8, new §6 addendum), docs/architecture/sweep-audit-artifacts-2026-02-18.md (new — consolidated), docs/architecture/audit-{a..f}-*.md (6 files deleted), docs/README.md (index updated), docs/decision-log.md (this entry)
- **Diff:** ~+250 revised / -2,100 deleted / +200 consolidated = net -1,650
- **Risk:** Low — analysis + doc hygiene, no code changes
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Follow-ups:** Execute Day-1 Sponsor Validation Protocol on test server connect (March 11)

## 2026-02-18 — Structural Risk Sweep (Adversarial Pre-Mortem)

- **Goal:** Find the #1 blind spot in CivilizationControl's architecture/implementation plan via adversarial review (6 parallel audit tracks, source code verification).
- **Decision:** #1 risk is **AdminACL sponsor access on the hackathon test server** — `jump_with_permit()` requires `verify_sponsor(ctx)`, which requires GovernorCap (held by CCP) to add sponsor addresses. GateControl demo Beats 3–5 are BLOCKED without this. TradePost is unaffected (extension paths are sponsor-free). Mitigation: 4-question organizer message pre-March-11; local devnet fallback for demo recording if no access. Secondary risks: partial-quantity withdrawal impossible (full-stack only), EVE Vault sponsored tx is hardcoded stub, Character resolution has no validated automated path, multi-entry portfolio strategy unconfirmed.
- **Files:** docs/architecture/structural-risk-sweep-2026-02-18.md (new), docs/README.md (index updated)
- **Diff:** +320 / -0
- **Risk:** Low — analysis only, no code changes
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Follow-ups:** Send organizer message (4 questions: AdminACL access, admin tools, structure spawning, multi-entry); Day-1 sponsor test on test server; prepare local devnet fallback demo environment

## 2026-02-18 — TradePost Buyer Journey Validation (PARTIAL PASS)

- **Goal:** Validate (or falsify) that the TradePost "buyer journey" (fly up → interact → browse listings → buy → receive items) is implementable with available EVE Frontier Sui/Move primitives, and that existing docs correctly describe write-path + read-path.
- **Decision:** PARTIAL PASS. Core on-chain mechanics (cross-address atomic buy, extension witness pattern, Coin<SUI> settlement, SSU inventory access) are VALIDATED on devnet with tx digests. Two critical unknowns remain: (1) How the game client presents a builder's dApp when a player interacts with an SSU — all builder-docs "Connecting In-Game" pages are `//TODO`; (2) Whether `Metadata.url` is the source for in-game dApp URL embedding. These must be tested on March 11 Hackathon Test Server (tests T1/T2 in checklist). TradePost remains in core MVP with explicit March 11 dependency gate. Doc corrections applied: demo beat sheet event names updated from sandbox mocks (`AccessGrant` → `TollCollectedEvent`, `ItemPurchased` → `TradeSettledEvent`).
- **Files:** docs/architecture/tradepost-buyer-journey-validation.md (new — verdict, minimal architecture, March 11 test checklist), docs/core/civilizationcontrol-demo-beat-sheet.md (5 event name corrections), docs/README.md (index updated)
- **Diff:** +250 / -8
- **Risk:** Low — analysis + doc corrections, no code changes
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Follow-ups:** March 11 tests T1–T4 (critical), T5–T8 (medium); partial-quantity withdraw design decision; builder channel inquiry re: SSU dApp URL configuration

## 2026-02-18 — Denial Observability Correction (MoveAbort IS Queryable)

- **Goal:** Determine whether Beat 4 ("Hostile Denied") can remain in the demo — i.e., whether a failed jump attempt produces observable on-chain evidence.
- **Decision:** Reverses the earlier "omit from MVP" recommendation. Failed Sui transactions ARE stored on-chain and queryable by digest. MoveAbort codes are deterministic: `(smart_gate::tribe_permit, 0)` = ETribeMismatch. For demo, the wallet adapter returns failure synchronously with tx digest + abort code — zero infrastructure required. Beat 4 remains exactly as written. In production, `suix_queryTransactionBlocks` with `FromAddress` filter + client-side failure filtering enables historical denial feeds.
- **Files:** docs/architecture/read-path-architecture-validation.md (§2.3 rewritten, §2.2/§5.2/§5.3/§6.2/§8 corrected), docs/core/civilizationcontrol-demo-beat-sheet.md (Beat 4 evidence overlay updated with exact mechanism), docs/core/civilizationcontrol-claim-proof-matrix.md (denial evidence row corrected)
- **Diff:** ~+40 / -25
- **Risk:** Low — doc corrections only, no code changes
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Follow-ups:** Verify `suix_queryTransactionBlocks` with `FromAddress` filter on hackathon test server; build abort-code→human-label mapping table in dashboard code

---

## 2026-02-18 — Read-Path Architecture Validation

- **Goal:** Validate CivilizationControl read-path assumptions — wallet→structures discovery, signal feed data sources, architecture options (browser-only vs backend), scale model.
- **Decision:** Option A (browser-only direct reads) for hackathon demo; Option B (thin backend cache/proxy) for Stillness if >10 concurrent users. Key corrections: (1) Toll revenue tracking requires custom extension events (TollCollectedEvent) — generic Coin\<SUI\> transfers are ambiguous; (2) `AccessGrant` and `ItemPurchased` are sandbox mocks, NOT world-contracts events — extension code must emit equivalents; (3) Gate link/unlink and extension authorization emit NO events — must be detected via state polling; (4) Lux→SUI exchange rate is undefined — default 1:1 for MVP. *(Note: MoveAbort queryability was initially assessed as a gap here; corrected in the 2026-02-18 Denial Observability entry above.)*
- **Files:** docs/architecture/read-path-architecture-validation.md (new), docs/ux/civilizationcontrol-ux-architecture-spec.md (Appendix corrected), docs/core/civilizationcontrol-demo-beat-sheet.md (Beat 5 evidence corrected), docs/core/civilizationcontrol-claim-proof-matrix.md (AccessGrant→TollCollectedEvent), docs/architecture/authenticated-user-surface-analysis.md (cross-ref added), docs/README.md (index updated)
- **Diff:** +420 / -10
- **Risk:** Low — analysis + doc corrections, no code changes
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Follow-ups:** Day 1 validation on hackathon test server: CharacterCreatedEvent query, RPC OwnerCap discovery, GraphQL availability, event retention window

## 2026-03-11 — Three-Environment Model Correction

- **Goal:** Correct the two-tier environment assumption (local devnet + Stillness) to a three-tier model by incorporating the dedicated hackathon test server available from March 11.
- **Decision:** Updated all strategic and planning documents to reflect three environments: (1) Local DevNet — Docker-based, pre-March 11 validation; (2) Hackathon Test Server — primary build/test/evidence environment from March 11, same world-contracts as Stillness, admin-spawnable structures, unlimited currency, shared among builders; (3) Stillness — live player server, deployment deferred to post-submission bonus window (14 days post-close). Revised launch strategy from "staged Stillness deployment" to "build privately on test server, submit with maximum novelty, deploy to Stillness post-submission."
- **Files:** docs/strategy/strategic-next-move-audit-2026-02-18.md, docs/strategy/hackathon-portfolio-roadmap.md, docs/strategy/civilizationcontrol-strategy-memo.md, docs/strategy/civilizationcontrol-product-vision.md, docs/core/march-11-reimplementation-checklist.md, docs/core/civilizationcontrol-claim-proof-matrix.md, docs/architecture/gatecontrol-feasibility-report.md, docs/ux/civilizationcontrol-ux-architecture-spec.md, docs/ideas/hackathon-ideas-grounded-v3-judged.md
- **Diff:** ~+80 / -40 (environment references updated, new environment model section added, hackathon test server as primary target, Stillness testnet misnomer corrected throughout)
- **Risk:** Low — documentation only, no code changes
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Key corrections:** (1) "Stillness testnet" → "Stillness (live server)" throughout — Stillness is NOT a testnet; (2) Character resolution, RPC discovery, EVE Vault tests retargeted to hackathon test server instead of Stillness; (3) March 11 execution strategy updated to target test server as Hour 0 primary environment; (4) Stillness deployment deferred to post-submission bonus window
- **Follow-ups:** Obtain hackathon test server RPC URL and connection details on March 11

---

## 2026-02-18 — EVE Vault Signing Smoke Test Scaffold

- **Goal:** Kill wallet integration uncertainty by building a minimal signing probe against EVE Vault via `@mysten/dapp-kit`.
- **Decision:** Created `sandbox/evevault-signing-smoke/` — Vite + React + TS + dapp-kit 1.0.3. Scaffold detects wallets via Sui Wallet Standard, connects to "Eve Vault", constructs an empty PTB, and calls `signTransaction()`. TypeScript typecheck and Vite build both pass. Manual browser test pending — EVE Vault is a Chrome extension requiring FusionAuth OAuth + Enoki zkLogin, which cannot be automated from terminal.
- **Files:** sandbox/evevault-signing-smoke/ (new project), docs/strategy/strategic-next-move-audit-2026-02-18.md
- **Diff:** +250 / -0 (new scaffold + doc update)
- **Risk:** Low — sandbox test only, no publishing, no chain mutation
- **Gates:** typecheck ✅ build ✅ smoke ⏳ (manual browser test pending)
- **Key finding:** EVE Vault registers as `"Eve Vault"` via wallet standard. Uses zkLogin — no raw private key, needs FusionAuth + Enoki. Standard dapp-kit hooks work without special adapter code.
- **Follow-ups:** Install EVE Vault extension, run manual 4-step browser test, update strategic audit to PASS/PARTIAL/FAIL.

---

## 2026-02-18 — Minimal Extension Compile Test Against world-contracts

- **Goal:** Eliminate Day-1 integration risk by confirming a dependent Move package can compile against `vendor/world-contracts` and reference `world::gate`, `world::character`, `world::storage_unit`.
- **Decision:** Created `sandbox/minimal-extension-test/` with a probe module that imports all three target modules, references public structs (Gate, Character, StorageUnit, JumpPermit), calls view functions, and type-checks `issue_jump_permit<TestAuth>()` with a custom witness. Compiled inside builder-scaffold Docker image (Sui CLI 1.66.1). Result: **PASS** — clean build, no visibility restrictions, no address mismatches.
- **Files:** sandbox/minimal-extension-test/Move.toml, sandbox/minimal-extension-test/sources/compile_probe.move
- **Diff:** +75 / -0 (new test package)
- **Risk:** Low — sandbox compile test only, no publishing, no chain interaction
- **Gates:** build ✅
- **Follow-ups:** None — unknown resolved. Extension development can proceed with confidence.

---

## 2026-02-18 — Upstream Submodule Sync + builder-documentation Added

- **Goal:** Controlled sync of all vendor submodules to latest upstream commits; add new `builder-documentation` submodule; assess impact on internal docs.
- **Decision:** Updated builder-scaffold (0e3bbb9a→c97989fb), evevault (654867e0→fe930dbc), world-contracts (aa15075a→eb1d627a). zk-proximity-poc unchanged. Added vendor/builder-documentation (3f3c1ab1) — the GitBook source repo for docs.evefrontier.com, now canonical local read source. Material impact detected: builder-scaffold renamed gate→smart_gate (4 docs affected). World-contracts API unchanged (fuel bug fix only). eVault changes internal only.
- **Files:** .gitmodules, vendor/builder-scaffold, vendor/evevault, vendor/world-contracts, vendor/builder-documentation (new)
- **Diff:** +7 / -3 (submodule pointers + .gitmodules)
- **Risk:** Low — submodule pointer updates only, no internal code changes
- **Gates:** typecheck N/A  build N/A  smoke N/A (submodule sync only)
- **Follow-ups:** Update sui-playground-capabilities.md scaffold paths (4 stale refs). Update evefrontier-builder-docs-map.md (6 new pages, submodule access path). Update copilot-instructions Official Documentation Reference Policy. Update hackathon-portfolio-roadmap.md Corpse Toll Road path (low priority).

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
