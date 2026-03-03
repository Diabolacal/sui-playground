# Decision Log

**Retention:** Carry-forward

Non-trivial technical and strategic decisions, newest first. See [operations/DECISIONS_TEMPLATE.md](operations/DECISIONS_TEMPLATE.md) for entry format.

---

## 2026-03-13 — SSU Extension E2E Validation (TP-05): Cross-Package withdraw_item Against Real World-Contracts
- **Goal:** Validate that a cross-package extension witness (`TradeAuth has drop`) can call `withdraw_item<TradeAuth>()` on a real world-contracts `StorageUnit`, closing the last structural gap for TradePost.
- **Decision:** All 7 Move unit tests PASS against real world-contracts v0.0.15. Extension withdrawal, cross-player delivery, partial quantity, authorization enforcement, and full trade flow all confirmed.
- **Files:** `sandbox/validation/ssu_extension_test/` (Move harness: 3 files), `docs/validation/ssu-extension-e2e-validation.md` (report), `docs/validation/localnet-validation-backlog.md` (updated), `docs/analysis/must-work-claim-registry.md` (updated), `docs/README.md` (index)
- **Diff:** +700 / -30 (new harness + report, backlog/registry updates)
- **Risk:** Low (sandbox validation, no production code)
- **Gates:** typecheck N/A  build ✅  smoke ✅ (7/7 tests PASS)
- **Key findings:**
  - `withdraw_item<TradeAuth>(ssu, auth, type_id, quantity, ctx)` succeeds from non-owner address with authorized extension
  - `deposit_to_owned<TradeAuth>()` enables cross-player delivery (seller SSU → buyer SSU)
  - Partial quantity extraction confirmed (v0.0.15 `quantity: u32` param)
  - Wrong extension type (`FakeAuth`) aborts at runtime as expected
  - `parent_id` field correctly populated on minted items
  - Full trade flow: authorize → stock → withdraw → deliver → verify balances
  - **CLI workaround discovered:** `sui move test` with world-contracts dependency requires switching active env to one NOT in Move.toml `[environments]` (e.g., `testnet`) to avoid chain hash mismatch with vendor's `"0x0"` placeholder
- **Risks eliminated:** TP-05 (last remaining "NOW" structural gap from validation backlog). All 6 original "NOW" priority items now DONE.
- **Follow-ups:** Port TradePost SSU integration to hackathon submission repo on March 11.

## 2026-03-03 — Submodule Refresh: world-contracts v0.0.15 + builder-documentation b4178c6
- **Goal:** Update all vendor submodules to latest upstream commits, audit changes, assess CivilizationControl impact.
- **Decision:** Two submodules updated: world-contracts (v0.0.14 78854fe → v0.0.15 74d30c8) and builder-documentation (6b6fae8 → b4178c6). builder-scaffold, evevault, eve-frontier-proximity-zk-poc unchanged. v0.0.15 contains significant inventory refactor and SSU API changes. Gate/turret/access modules unchanged — core CC extension patterns intact. Breaking call-site changes documented.
- **Files:** `vendor/world-contracts` (submodule pin), `vendor/builder-documentation` (submodule pin), `docs/research/evefrontier-builder-docs-map.md`, `docs/core/march-11-reimplementation-checklist.md`, `docs/strategy/_shared/hackathon-portfolio-roadmap.md`, `docs/decision-log.md`
- **Diff:** submodule pins only; +~120 / -~30 across doc updates
- **Risk:** Medium — v0.0.15 has breaking API changes for TradePost call sites (withdraw_item signature, parent_id validation)
- **Gates:** typecheck N/A  build N/A (docs + submodule pins only)  smoke N/A
- **Key findings:**
  - **Inventory Item/ItemEntry split:** Coin/Balance analogy. `ItemEntry` (at-rest, lightweight) vs `Item` (in-transit, UID + parent_id). Deposit validates parent_id.
  - **`withdraw_item<Auth>` now takes `quantity: u32` + `ctx`:** Supports partial withdrawals. All TradePost call sites must update.
  - **`deposit_item<Auth>` validates `parent_id`:** Items can only deposit back to origin SSU. Cross-SSU delivery needs `deposit_to_owned<Auth>` or `transfer::public_transfer`.
  - **New `deposit_to_owned<Auth>`:** Extension pushes items into any player's owned inventory — enables async TradePost delivery pattern.
  - **AdminACL removed from owner-path SSU functions:** `deposit_by_owner`/`withdraw_by_owner` just need OwnerCap + sender check. Energy source updates also lost AdminACL.
  - **dapp-kit docs simplified:** `useSponsoredTransaction` removed, `useDAppKit()` from `@mysten/dapp-kit-react`. TypeDoc at `sui-docs.evefrontier.com`.
  - **EVE Vault browser extension docs populated:** Install guide, sign-in flow, screenshots.
  - **Gate, turret, access modules UNCHANGED.** All validated CC extension patterns remain intact.
- **CC Impact Assessment:** Medium. Extension-based gate control path unaffected. TradePost `withdraw_item<Auth>` call sites need `quantity` param added. `deposit_to_owned<Auth>` opens a new, potentially better TradePost delivery pattern. AdminACL removal from owner-path simplifies SSU owner operations. No re-validation needed for gate lifecycle — only TradePost call-site update on March 11.
- **Follow-ups:** Update posture-switch validation TS scripts with new withdraw_item quantity param if re-running. Re-verify TradePost pattern with v0.0.15 on March 11. Consider `deposit_to_owned<Auth>` as preferred TradePost buyer delivery mechanism.

## 2026-03-12 — Localnet Validation Sprint: Extension E2E + AdminACL + Compound DFs + Version Pinning
- **Goal:** Execute top-priority localnet validations from the Localnet Validation Backlog to de-risk March 11 hackathon build. Prove cross-package extension pattern, AdminACL self-enrollment, compound DF keys, and version pinning.
- **Decision:** All targeted validations PASS. Four major structural risks eliminated.
- **Files:** `sandbox/validation/extension_auth_test/` (Move harness), `sandbox/validation/compound_df_key_test/` (Move harness), `docs/validation/` (5 reports), `docs/README.md` (index updated)
- **Diff:** +800 / -0 (new validation harnesses + reports)
- **Risk:** Low (sandbox validation, no production code changes)
- **Gates:** typecheck N/A  build ✅  smoke ✅ (all claims pass on localnet)
- **Key findings:**
  - **Extension E2E (Priority 1):** Full bootstrap chain (Character → NetworkNode → Gate → authorize_extension → issue_jump_permit) executed on fresh localnet. Cross-package `XAuth has drop` witness accepted at both compile and runtime. JumpPermit created. DF config pattern works.
  - **AdminACL (Priority 4):** `add_sponsor_to_acl` + `verify_sponsor` sender fallback confirmed. Single-signer admin operations work without dual-sign.
  - **Compound DF Keys (Priority 2):** 6/6 Move unit tests pass. Per-gate compound keys (`TribeRuleKey { gate_id }`) produce independent DFs on shared config.
  - **Version Pinning (Priority 6):** All A1-A4 function signatures confirmed at commit `78854fed` (v0.0.14).
  - **Sui CLI v1.66.1 quirk:** `[environments]` section required in Move.toml. Workaround for vendor packages: `sui client test-publish --build-env local`.
  - **PowerShell 5.1 quirk:** String arguments lose quotes when passed to native commands. Workaround: `cmd /c` with doubled quotes.
- **Risks eliminated:** SR-1 (AdminACL enrollment), SR-2 (cross-package Auth), SR-3 (OwnerCap borrow/return), SR-4 (extension config DFs)
- **Follow-ups:** Port extension pattern to CivilizationControl repo on March 11. Re-verify against test-server world-contracts. Full GateControl E2E with toll+tribe on test server.

## 2026-03-11 — Posture-Switch Single-PTB Validation (Localnet)
- **Goal:** Validate that CivilizationControl Posture Presets (Open for Business ↔ Defense Mode) can be switched in a single PTB on Sui localnet, confirming the "one click" hypothesis.
- **Decision:** Strategy A (single PTB) confirmed working for both directions. Single PTB composes: `set_posture` + config DF mutations + per-turret borrow/toggle/return cycles. No need for Strategy B (multi-tx fallback). Documented prerequisites (fuel/energy chain, NetworkNode online, extension authorization) and BCS encoding constraints.
- **Files:** `sandbox/posture-switch-validation/` (Move + TS harness), `docs/sandbox/posture-switch-localnet-validation.md` (report), `docs/README.md` (index)
- **Diff:** +1600 / -0 (new files only)
- **Risk:** Low (sandbox validation, no production code)
- **Gates:** typecheck N/A  build ✅ (Move compiled)  smoke ✅ (localnet full-test ALL PASS)
- **Key findings:**
  - BUSINESS→DEFENSE: 1 tx, ~2.3s latency. DEFENSE→BUSINESS: 1 tx, ~2.8s latency.
  - Energy prerequisite chain required: `set_fuel_efficiency` → `deposit_fuel` → `network_node::online` → turret `online()`.
  - BCS encoding: `tx.pure.vector('u8', Array.from(...))` required for `vector<u8>` params.
  - `status::online()`/`offline()` abort if already in target state — pre-check mandatory.
  - OwnerCap→assembly mapping requires reading `authorized_object_id` field; discovery order unreliable.
- **Follow-ups:** Port to hackathon submission repo on March 11. Build UI wiring for posture toggle. Validate toll collection in extension.

## 2026-03-03 — TurretControl + Posture Presets Integrated into Product Vision & Demo
- **Goal:** Add turrets and posture presets (Open for Business / Defense Mode) to CivilizationControl planning docs. Audit turret state mechanics and toll implementation reality.
- **Context:** Turret audit confirmed `turret::online()`/`turret::offline()` are player-callable via OwnerCap<Turret>, no AdminACL needed. Batch toggle in single PTB is feasible. Toll audit confirmed: NO native toll/fee mechanism exists in world-contracts or builder-scaffold — toll is entirely CC extension code (~30-50 LoC, pending March 11 validation). Tribe filter exists and works. Two posture presets defined: "Open for Business" (broad access + toll, turrets offline) and "Defense Mode" (tribe-only, turrets online).
- **Decision:** (1) Added TurretControl subsection + Posture Presets subsection to product vision. (2) Inserted Beat 5b (Defense Mode posture shift) into demo beat sheet — 15 seconds, new proof moment (turret StatusChangedEvent). (3) Updated spec.md system boundaries table to include TurretControl module. (4) Updated MVP table: added TurretControl UI + Posture Presets as core deliverables. (5) Added Terminology section to product vision (TurretControl, Posture Preset, Online/Offline/Anchored). (6) Corrected toll claims: toll is CC extension capability, not native world-contracts. (7) Updated non-goals: explicit exclusions for custom turret targeting, anchor/unanchor, additional presets, scheduling.
- **Files:** docs/strategy/civilization-control/civilizationcontrol-product-vision.md, docs/core/civilizationcontrol-demo-beat-sheet.md, docs/core/spec.md, docs/decision-log.md
- **Diff:** +150 / -30 (across 3 docs)
- **Risk:** Low (docs only, no production code)
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Key findings:**
  - `turret::online()` / `turret::offline()`: OwnerCap<Turret> only, no AdminACL. Borrow/return pattern. State guards strict (abort if already in target state).
  - Multiple turrets batchable in single PTB (separate borrow/return per turret, shared NWN/EnergyConfig refs reused).
  - Events: `StatusChangedEvent` from `status.move` (shared primitive), action: ONLINE or OFFLINE. No turret-specific event.
  - Toll: NOT a world-contracts primitive. CC extension implements toll in `request_jump_permit` via `CoinTollRule` DF + `Coin<SUI>` transfer.
  - Tribe filter: exact match (`character.tribe() == tribe_cfg.tribe`). Single extension per gate. Multiple DFs on shared ExtensionConfig.
- **Assumptions pending March 11 sandbox validation:**
  - Single PTB for full posture switch (turret toggles + gate rule updates) — needs validation under real shared-object contention.
  - Toll implementation (Coin<SUI> transfer in CC extension) — functional design confirmed, code not yet written.
  - NetworkNode must be online before turret toggle — verify NWN state on test server.
- **Follow-ups:** Implement CC toll module (~30-50 LoC). Build posture preset UI wiring. Validate batch PTB on hackathon test server.

## 2026-03-02 — Turret Closed-World Constraint Clarification + Doc Reconciliation
- **Goal:** Convert first-pass turret architectural conclusions into code-backed, evidence-level reference. Reconcile all docs with clarified facts. Fix known inconsistencies (BehaviourChangeReason values, validation count).
- **Decision:** (1) Created canonical clarification doc with code-proven evidence: fixed 4-arg PTB signature, no uid() accessor, default targeting matrix (12 rows), CC alignment verdict, toll payer mismatch note, per-project feasibility (CC unnecessary, CB/FG structurally impossible). (2) Corrected validation checklist count from 38 to 45 across all references. (3) Marked historical quotes in turret-project-semantics-and-mismatches.md as "since corrected." (4) Added 3 new docs + 1 canonical reference to README index. (5) Corrected archived doc (hackathon-ideas-grounded.md) with strikethrough. (6) BehaviourChangeReason values confirmed correct in all live docs (UNSPECIFIED=0, ENTERED=1, STARTED_ATTACK=2, STOPPED_ATTACK=3).
- **Files:** docs/architecture/turret-closed-world-clarified.md (new canonical), docs/architecture/turret-contract-surface.md, docs/decision-log.md, docs/README.md, docs/analysis/turret-project-semantics-and-mismatches.md, docs/archive/ideas/hackathon-ideas-grounded.md
- **Diff:** +210 LoC (new doc) / ~30 LoC edits across 5 existing docs
- **Risk:** Low (documentation only)
- **Gates:** N/A (docs only)
- **Follow-ups:** Runtime-unverified items require March 11 test server: end-to-end targeting (D-01..D-09), event emission (O-01..O-02), lifecycle (L-01..L-06), extension auth (E-01..E-04).

## 2026-03-02 — Turret Documentation Propagation Across Hackathon Planning Docs
- **Goal:** Propagate turret API surface (world-contracts v0.0.14) across all planning docs. Verify contract behavior against prior assumptions. Produce validation checklist.
- **Decision:** (1) Created turret contract surface summary doc with full API reference. (2) Updated 15+ docs with false "no turret exists" claims. (3) Identified closed-world constraint: turret extensions receive fixed 4-arg signature from game engine, cannot access external state (no uid() accessor, no shared object params). (4) Default turret targeting matches CC tribe_only policy (same-tribe non-aggressors excluded). No custom turret extension needed for CC MVP. (5) CargoBond and Fortune Gauntlet turret integration blocked by closed-world constraint; deferral rationale updated from "absent" to "architecturally constrained." (6) Created validation checklist (45 test cases: 8 CLI-testable, 36 environment-blocked, 1 structurally impossible).
- **Files:** docs/architecture/turret-contract-surface.md (new), docs/operations/turret-localnet-validation-checklist.md (new), docs/analysis/turret-project-semantics-and-mismatches.md (new), docs/architecture/sui-playground-capabilities.md, docs/architecture/gate-turret-courier-access-feasibility.md, docs/architecture/policy-authoring-model-validation.md, docs/architecture/in-game-dapp-surface.md, docs/analysis/assumption-registry-and-demo-fragility-audit.md, docs/analysis/fortune-gauntlet-feasibility.md, docs/strategy/cargo-bond/cargo-bond-product-vision.md, docs/strategy/fortune-gauntlet/fortune-gauntlet-scoring-memo.md, docs/strategy/fortune-gauntlet/fortune-gauntlet-project-vision.md, docs/strategy/civilization-control/civilizationcontrol-strategy-memo.md, docs/core/spec.md, docs/core/day1-checklist.md, docs/operations/gate-lifecycle-runbook.md, docs/ptb/ (5 files), .github/instructions/move.instructions.md, docs/README.md
- **Diff:** ~+600 LoC new docs / ~+150 LoC edits across existing docs
- **Risk:** Low (documentation only, no code changes)
- **Gates:** N/A (docs only)
- **Follow-ups:** Execute validation checklist items P-01 through P-04 and A-01 through A-03 on localnet. Revalidate turret patterns on hackathon test server March 11.

---

## 2026-03-02 — Submodule Refresh (world-contracts v0.0.14, evevault a409496, builder-scaffold 572e2ca)
- **Goal:** Refresh all submodules to latest upstream; audit changes for CivilizationControl impact.
- **Decision:** Updated 3 of 5 submodules: world-contracts `e508451→78854fe` (v0.0.14, +2 commits: turret implementation + fuel refactor), evevault `687d432→a409496` (+2 commits: sponsored tx flow + build fix), builder-scaffold `6bc43a1→572e2ca` (+2 commits: dapp-kit published + build approvals). builder-documentation and proximity-zk-poc unchanged. **Key findings:** (1) Turret assembly fully implemented — same typed witness pattern as gate/SSU, no CC pattern impact. (2) `extension_examples/gate.move` deleted, replaced by `turret.move`. (3) EVE Vault sponsored tx now fully functional (server→sign→execute dual-phase with zkLogin). (4) `fuel::withdraw` now requires `type_id` param. (5) `@evefrontier/dapp-kit` published on npm. **No pattern-breaking changes for CivilizationControl.**
- **Files:** vendor/ (3 submodule pointers), docs/research/evefrontier-builder-docs-map.md, docs/core/march-11-reimplementation-checklist.md, docs/strategy/_shared/hackathon-portfolio-roadmap.md
- **Diff:** submodule pins + ~50 LoC doc updates
- **Risk:** Low — submodule refresh + docs only
- **Gates:** typecheck N/A build N/A smoke N/A (docs + submodule pins only)
- **Follow-ups:** Turret docs page may still be TODO on GitBook — check when refreshing docs. Re-validate all patterns on hackathon test server March 11.

---

## 2026-03-02 — Multi-Submission Rule Confirmed + Judging Criteria FAQ Reconciliation

- **Goal:** Resolve multi-submission ambiguity (Assumption A-86, Risk #5) and reconcile Deep Surge FAQ judging criteria with official T&C.
- **Decision:** (1) Deep Surge FAQ explicitly allows multiple submissions per team; each must be unique. Portfolio strategy validated — no pivot required. (2) FAQ summarizes judging as 4 areas (Utility, Technical Implementation, Creativity, Frontier Integration); this condenses the 8 official T&C criteria but does not contradict them. The 8-criterion framework remains authoritative for scoring and strategy. (3) All three portfolio entries (CivilizationControl, Flappy Frontier, Cargo Bond) map cleanly to the FAQ's 4 areas — no repositioning needed.
- **Files:** docs/research/hackathon-event-rules-digest.md, docs/strategy/_shared/hackathon-portfolio-roadmap.md, docs/strategy/_shared/marketing-plan.md, docs/strategy/civilization-control/strategic-next-move-audit-2026-02-18.md, docs/architecture/structural-risk-sweep-2026-02-18.md, docs/architecture/sweep-audit-artifacts-2026-02-18.md, docs/analysis/assumption-registry-and-demo-fragility-audit.md, docs/decision-log.md, .github/copilot-instructions.md, AGENTS.md
- **Diff:** ~+30 / -20 (clarifications, resolved flags, FAQ reconciliation note)
- **Risk:** Low — documentation only
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Follow-ups:** None — ambiguity fully resolved.

---

## 2026-03-01 — Atomic Courier Feasibility Confirmed (Local Devnet)

- **Goal:** Determine whether `withdraw_item + deposit_item + Coin<SUI> transfer` can execute atomically in a single PTB on Sui (world contracts).
- **Decision:** **FEASIBLE.** All three operations execute atomically in one transaction. Extension-based auth (`XAuth` witness) provides all needed authorization — no AdminACL or sponsorship required for the transfer path. Net gas cost ~0.002 SUI. 5 objects mutated (2 SSUs, 2 Inventories, 1 Coin).
- **Files:** `experiments/atomic_courier_experiment/` (Move sources, TS test script, feasibility report)
- **Diff:** ~600 LoC added (Move: ~120, TS: ~490, report: ~130)
- **Risk:** Low — sandbox experiment, not committed to hackathon repo
- **Gates:** typecheck N/A (Move), build ✅ (compiled + published), smoke ✅ (executed on local devnet)
- **Follow-ups:** Proceed with Atomic Courier as viable CivilizationControl mechanism. Test with EVE Token (not just SUI) if needed. Consider gate jump integration (requires AdminACL for `jump_with_permit`).

---

## 2026-02-28 — In-Game DApp Browser Surface Integration

- **Goal:** Integrate confirmed in-game embedded browser capabilities into CivilizationControl planning. Probe data (`capabilities.json`) captured from EVE Frontier's Chromium 122 CEF webview.
- **Decision:** In-game browser provides read-only surface (no Sui Wallet Standard — only EVM/EIP-6963). Portrait viewport 787×1198 is the hard layout constraint. Write operations require external browser with EVE Vault. Created canonical reference doc + updated 7 planning documents.
- **Files:** docs/architecture/in-game-dapp-surface.md (NEW), docs/ux/civilizationcontrol-ux-architecture-spec.md, docs/core/spec.md, docs/core/day1-checklist.md, docs/core/civilizationcontrol-demo-beat-sheet.md, docs/core/civilizationcontrol-implementation-plan.md, docs/research/hackathon-event-rules-digest.md, docs/README.md
- **Diff:** ~550 LoC added across 8 files (1 new + 7 updated)
- **Risk:** Low — planning docs only, no code changes
- **Gates:** N/A (documentation only)
- **Follow-ups:** Day-1 Check 11 validates in-game loading. EVE Vault in-game relay feasibility TBD (stretch).

---

## 2026-02-28 — Submodule Refresh + Breaking Changes Audit

- **Goal:** Update all git submodules to latest upstream, audit changes, update documentation with breaking change findings.
- **Decision:** Refreshed 4 submodules (builder-documentation c2628fd→6b6fae8, builder-scaffold 9edb532→6bc43a1, evevault ed238c2→687d432, world-contracts 09c2ec2→e508451). proximity-zk-poc unchanged.
- **Files:** vendor/* (4 submodule pointer updates), docs/research/evefrontier-builder-docs-map.md, docs/core/march-11-reimplementation-checklist.md, docs/strategy/hackathon-portfolio-roadmap.md, docs/decision-log.md
- **Diff:** 4 submodule pointer updates, ~80 LoC doc edits across 4 files
- **Risk:** Low — submodule pointer updates + docs only
- **Gates:** typecheck N/A  build N/A  smoke N/A (no code changes)
- **Key findings:** (1) world-contracts v0.0.13: proximity proof REMOVED from owner-path SSU functions (withdraw_by_owner, withdraw) — replaced by AdminACL verify_sponsor. Extension path unaffected. (2) link_gates now requires AdminACL param + authorized sponsored tx. (3) SDK migration: SuiClient → SuiJsonRpcClient (@mysten/sui/jsonRpc) across world-contracts + builder-scaffold. (4) New EVE token asset (Coin\<EVE\>, 10B supply, 9 decimals, AdminCap+EveTreasury). (5) New gate link/unlink events. (6) builder-scaffold: proof.ts deleted, corpse_gate_bounty updated to AdminACL. (7) EVE Vault: sign-and-execute now functional, default chain devnet→testnet, sponsored tx API URL changed with assemblyType param, 2-min timeout guard. (8) builder-documentation: minor Move docs URL fix. **No pattern-breaking changes for CivilizationControl** — all validated extension/witness patterns remain intact.
- **Follow-ups:** Re-validate deployment sequence on hackathon test server March 11 (step numbering changed due to AdminCap removal from setup chain). Consider EVE token as coin toll currency option.

## 2026-02-20 — Submodule Refresh + Docs Audit

- **Goal:** Update all git submodules to latest upstream, audit changes, update documentation indexes and impacted design docs.
- **Decision:** Refreshed 4 submodules (builder-documentation, builder-scaffold, evevault, world-contracts). proximity-zk-poc unchanged. Updated builder-docs-map with AdminCap→AdminACL alignment, gate build.md population, JSON-RPC removal, scaffold reference code. Updated hackathon-portfolio-roadmap and march-11-reimplementation-checklist with new upstream reference code notes. Updated stored memory facts.
- **Files:** vendor/* (submodule pointers), docs/research/evefrontier-builder-docs-map.md, docs/strategy/hackathon-portfolio-roadmap.md, docs/core/march-11-reimplementation-checklist.md, docs/decision-log.md, docs/operations/submodule-refresh-prompt.md (new)
- **Diff:** 4 submodule pointer updates, ~50 LoC doc edits across 3 files, +1 new operations doc
- **Risk:** Low — submodule pointer updates + docs only
- **Gates:** typecheck N/A  build N/A  smoke N/A (no code changes)
- **Key findings:** (1) world-contracts: inventory deposit_item() now merges same-type quantities (beneficial for TradePost). (2) builder-scaffold: complete smart_gate reference implementation with 3 Move modules + full TS script suite. (3) builder-documentation: Gate build.md fully populated; AdminCap→AdminACL naming alignment; JSON-RPC removed; SSU docs show AdminACL replacing proximity proof (code-docs discrepancy — our extension path unaffected). (4) evevault: SuiClient→SuiGrpcClient migration; Quasar sponsorship API endpoint found but still stubbed; chain support unchanged. (5) No breaking changes to Move function signatures across any submodule.

## 2026-02-19 — Validate GateControl Policy Authoring Model (UI-Driven Feasibility)

- **Goal:** Confirm whether players can configure enforcement rules (deny/allow/toll) via CivilizationControl UI without writing Move code. Determine whether policy is data-driven, requires user-authored Move, or a hybrid.
- **Decision:** **Model 2 — "Publish once, configure via data."** CivilizationControl team publishes ONE extension package; users configure rules via UI-constructed PTBs that write dynamic fields to a shared config object. End users never write or publish Move code. Per-gate differentiation via gate-ID-keyed compound DF keys.
- **Files:** docs/architecture/policy-authoring-model-validation.md (new), docs/core/march-11-reimplementation-checklist.md (added findings #8, assumptions A9–A11, Policy Lifecycle block), docs/README.md (index updated), docs/decision-log.md
- **Diff:** +220 LoC new doc, +18 LoC checklist updates, +1 line index
- **Risk:** Low — docs only, no code changes
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Key findings:** (1) Extension witness pattern requires a published Move module — but only once by the builder, not per-user. (2) ExtensionConfig + dynamic fields proven in extension_examples and builder-scaffold. (3) Per-gate DF keys and OwnerCap-gated config are design extrapolations — standard Sui patterns but unexercised. (4) EVE Vault wallet signs arbitrary PTBs. (5) No deauthorize_extension exists — extensions can be swapped but not removed. (6) Turret extension docs are //TODO stubs — pattern assumed same as gates.
- **Day-1 validation:** 5 items (per-gate DF keys, OwnerCap config auth, single-PTB deploy, SDK DF reads, turret extension field).

## 2026-02-19 — Harden Demo Beat Sheet for Production Execution

- **Goal:** Add structured production scaffolding to the demo beat sheet — preconditions, capture modes, latency handling, account roles, fallback triggers, recording order, safety rules — without altering narrative, timing, or emotional arc.
- **Decision:** Surgical additions to `civilizationcontrol-demo-beat-sheet.md`. 7 new subsections added (78 lines, 18.8% growth). No narrative text modified.
- **Files:** docs/core/civilizationcontrol-demo-beat-sheet.md, docs/decision-log.md
- **Diff:** +78 lines (all structural scaffolding)
- **Risk:** Low — docs only, no narrative changes
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)

## 2026-02-19 — Demo Evidence Mapping + Rehearsal Appendix

- **Goal:** Map every demo beat sheet artifact (tx digest, abort code, balance delta, policy deploy) to its executable script, expected output, capture method, and identify gaps.
- **Decision:** Created `docs/operations/demo-evidence-appendix.md` — operational appendix with per-beat evidence mapping (Appendixes A–F), script inventory table, and gap analysis.
- **Files:** docs/operations/demo-evidence-appendix.md (new), docs/README.md (index updated), docs/decision-log.md (this entry)
- **Diff:** +250 LoC new doc, +1 line index
- **Risk:** Low — docs only
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Key findings:** Beat 1 (CLI contrast), Beat 6 (trade buy with mock SSU), ZK accent — fully scripted. Beat 4 (hostile denied) and Beat 5 (toll collection) have no rehearsal scripts — marked TODO. Beat 3 (policy deploy) needs submission extension script. Beat 2/7 depend on frontend app (hackathon deliverable, not script gap).
- **Follow-ups:** Create `hostile_jump_denied.sh`, `toll_jump_rehearsal.sh`, and submission extension deploy script before demo recording.

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
- **Decision:** #1 risk is **AdminACL sponsor access on the hackathon test server** — `jump_with_permit()` requires `verify_sponsor(ctx)`, which requires GovernorCap (held by CCP) to add sponsor addresses. GateControl demo Beats 3–5 are BLOCKED without this. TradePost is unaffected (extension paths are sponsor-free). Mitigation: 4-question organizer message pre-March-11; local devnet fallback for demo recording if no access. Secondary risks: partial-quantity withdrawal impossible (full-stack only), EVE Vault sponsored tx is hardcoded stub *(Correction 2026-02-28: EVE Vault sponsored tx now functional — commit 687d432)*, Character resolution has no validated automated path, multi-entry portfolio strategy unconfirmed.
- **Files:** docs/architecture/structural-risk-sweep-2026-02-18.md (new), docs/README.md (index updated)
- **Diff:** +320 / -0
- **Risk:** Low — analysis only, no code changes
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Follow-ups:** Send organizer message (4 questions: AdminACL access, admin tools, structure spawning, ~~multi-entry~~ ✅ confirmed); Day-1 sponsor test on test server; prepare local devnet fallback demo environment

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
- **Decision:** Option A (browser-only direct reads) for hackathon demo; Option B (thin backend cache/proxy) for Stillness if >10 concurrent users. Key corrections: (1) Toll revenue tracking requires custom extension events (TollCollectedEvent) — generic Coin\<SUI\> transfers are ambiguous; (2) `AccessGrant` and `ItemPurchased` are sandbox mocks, NOT world-contracts events — extension code must emit equivalents; (3) Gate link/unlink and extension authorization emit NO events — must be detected via state polling; *(Correction 2026-02-28: gate link/unlink now emit `GateLinkedEvent`/`GateUnlinkedEvent` as of world-contracts v0.0.13 (commit e508451). Extension authorization still has no events.)* (4) Lux→EVE rate confirmed: 10,000 Lux = 1 EVE token; Lux→SUI depends on EVE/SUI exchange (undefined for MVP). *(Note: MoveAbort queryability was initially assessed as a gap here; corrected in the 2026-02-18 Denial Observability entry above.)*
- **Files:** docs/architecture/read-path-architecture-validation.md (new), docs/ux/civilizationcontrol-ux-architecture-spec.md (Appendix corrected), docs/core/civilizationcontrol-demo-beat-sheet.md (Beat 5 evidence corrected), docs/core/civilizationcontrol-claim-proof-matrix.md (AccessGrant→TollCollectedEvent), docs/architecture/authenticated-user-surface-analysis.md (cross-ref added), docs/README.md (index updated)
- **Diff:** +420 / -10
- **Risk:** Low — analysis + doc corrections, no code changes
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Follow-ups:** Day 1 validation on hackathon test server: CharacterCreatedEvent query, RPC OwnerCap discovery, GraphQL availability, event retention window

## 2026-03-11 (PLANNED) — Three-Environment Model Correction

- **Goal:** Correct the two-tier environment assumption (local devnet + Stillness) to a three-tier model by incorporating the dedicated hackathon test server available from March 11.
- **Decision (planned):** Update all strategic and planning documents to reflect three environments: (1) Local DevNet — Docker-based, pre-March 11 validation; (2) Hackathon Test Server — primary build/test/evidence environment from March 11, same world-contracts as Stillness, admin-spawnable structures, unlimited currency, shared among builders; (3) Stillness — live player server, deployment deferred to post-submission bonus window (14 days post-close). Revised launch strategy from "staged Stillness deployment" to "build privately on test server, submit with maximum novelty, deploy to Stillness post-submission."
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
  - Self-sponsorship does NOT work — must use different address *(Correction 2026-02-28: `verify_sponsor` falls back to `ctx.sender()` when no sponsor is present — non-sponsored txs succeed if sender is in AdminACL)*
  - Extension packages need `[environments]` section + `Pub.local.toml`
- **Follow-ups:** None — runbook is carry-forward ready

## 2026-03-11 (PLANNED) — ZK GatePass: Membership Circuit Implemented & Module Extracted

- **Goal:** Complete remaining ZK implementation: design Merkle membership circuit, extract standalone `zk_gate` module, validate on devnet
- **Decision (planned):** All ZK kill gates passed on local devnet (sandbox). Membership circuit (depth 10, Poseidon(2), 2,430 constraints) implemented in Circom, compiled, trusted setup complete, proof generated and verified off-chain. Standalone `zk_gate` Move module extracted and published on local devnet. On-chain tests: valid proof verified, invalid proof rejected, dynamic config + gate composition working. To re-validate on hackathon test server.
- **Files:** sandbox/validation/zk_membership/ (circuit, serializer, input generator), sandbox/validation/zk_gate/ (Move module), docs/operations/zk-gatepass-feasibility-report.md (§2.2 updated), docs/operations/shortlist-viability-validation-report.md (membership addendum), docs/strategy/hackathon-portfolio-roadmap.md (status updated), docs/strategy/civilizationcontrol-strategy-memo.md (status updated)
- **Diff:** +350 / -30 (circuit + Move module + doc updates)
- **Risk:** Low — sandbox validation; no production code
- **Gates:** typecheck N/A  build ✅ (Move build -e local)  smoke: 4 devnet tx all SUCCESS
- **Follow-ups:** World-contracts integration (Character, AdminACL, sponsored tx) during hackathon

## 2026-03-11 (PLANNED) — ZK GatePass Upgraded to GREEN (Devnet Validated)

- **Goal:** Validate ZK Groth16 verification and ZK+gate composition on local devnet (tests 8–10)
- **Context:** Sandbox addendum capturing devnet evidence for ZK GatePass. Standalone Groth16 verify, negative test, and ZK-to-gate composition (ZKAuth witness consumed by `Auth: drop` generic) all confirmed working in single-PTB transactions.
- **Decision:** GREEN — ZK GatePass is fully validated on local devnet (sandbox). Prior composition gap (depth-0 constraint) is resolved. Membership circuit design + package extraction remain as March 11 implementation tasks.
- **Files:** docs/operations/shortlist-viability-validation-report.md (tests 8–10 added), docs/operations/zk-gatepass-feasibility-report.md (§2.1 evidence table added), sandbox/validation/zk_gatepass_validation/ (Move packages)
- **Diff:** +120 / -5
- **Risk:** Low — validation only; no production code
- **Gates:** typecheck N/A  build N/A  smoke: devnet tx digests verified
- **Follow-ups:** ~~Design membership circuit, extract `zk_gate` package from PoC wrapper, sponsored transaction integration~~ DONE (see entry above)

## 2026-02-16 — ZK GatePass Feasibility Validation Complete

- **Goal:** Determine if ZK-verified gate access (Groth16 membership proof) is feasible as a GateControl rule type within CivilizationControl
- **Context:** Four-subagent research sprint: ZK PoC audit, GateControl integration analysis, devnet feasibility assessment, kill-switch/fallback design. No hackathon code produced.
- **Decision:** YELLOW-GREEN — architecturally feasible, pursue on March 11 with disciplined kill checkpoints. Both primitives (Groth16 on Sui, gate extension witness) proven independently. Critical gap: composing them in single transaction (depth-0 constraint). Two-step fallback (P1) available if single-tx fails. Maximum 28-hour ZK budget (25% of sprint). *(Upgraded to GREEN on local devnet — see entry above; to re-validate on hackathon test server March 11.)*
- **Alternatives considered:** (1) Off-chain proof + signature relay — rejected, not trustless, judges see through it; (2) ZK as standalone entry — already ruled out in portfolio strategy; (3) Skip ZK entirely — rejected, +0.50 score uplift justifies bounded 28-hour risk
- **Files:** docs/operations/zk-gatepass-feasibility-report.md (new), docs/architecture/zk-killswitch-fallback-analysis.md (new), docs/operations/shortlist-viability-validation-plan.md (updated), docs/operations/shortlist-viability-validation-report.md (updated), docs/README.md (updated)
- **Diff:** +550 / -5
- **Risk:** Medium — bounded by kill criteria (Day 1: circuit compile, Day 2: on-chain verify, Day 3 AM: gate integration). *(All composition gates passed on local devnet (sandbox); membership circuit remains the primary implementation gate for March 11.)*
- **Gates:** typecheck N/A  build N/A  smoke N/A (research + docs only)
- **Follow-ups:** Execute Tests 11-13 on March 11; resolve package naming conflict; design membership circuit

## 2026-02-16 — Hackathon Portfolio Strategy Finalized

- **Goal:** Multi-entry submission strategy targeting Best Entry + 3 bonus categories
- **Context:** 28 ideas scored against 8 judging criteria; devnet validation completed 7/7 GREEN; adversarial strategy review reconciled into Track A flagship + Track C sprints model
- **Decision:** Four-track portfolio — Track A: CivilizationControl (flagship), Track C: Fortune Gate (Weirdest), Salvage Protocol (Creative), Corpse Toll Road (Utility), Track D: Loot Crate (conditional wildcard). ZK GatePass integrated into CC, not standalone. TribeMint demoted to stretch.
- **Alternatives considered:** (1) Single flagship-only — rejected, leaves bonus prizes uncontested; (2) ZK as standalone entry — rejected, weak standalone score (6.31), stronger as CC differentiator; (3) TribeMint as Track C — rejected, high integration cost with marginal judging score uplift
- **Files:** docs/strategy/hackathon-portfolio-roadmap.md (new)
- **Diff:** +620 / -0
- **Risk:** Medium — ZK integration complexity mitigated by graceful degradation to tribe+toll rules
- **Gates:** typecheck N/A  build N/A  smoke N/A (docs only)
- **Follow-ups:** ~~Verify multi-submission rules pre-March 1~~ ✅ confirmed (FAQ 2026-03-02); storyboard all demos pre-March 11; no production code until March 11
