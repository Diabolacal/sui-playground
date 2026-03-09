# Pre-Template Compliance Audit — 2026-03-09

**Retention:** Prep-only

> Structured compliance audit of the sui-playground repository performed March 9, 2026 — two days before the hackathon start date (March 11). This audit verifies the repo reads as planning-only / sandbox-only, remains clearly separated from any eventual submission repo, and does not contain wording, artifacts, or structure that could create ambiguity under hackathon rules.

---

## Governance Snapshot

| Property | Value |
|----------|-------|
| **Audit date** | 2026-03-09 |
| **Auditor** | Copilot agent (automated, multi-sub-agent) |
| **Prior audit** | `docs/operations/compliance-audit-2026-02-24.md` (SAFE WITH CLARIFICATIONS) |
| **Hackathon start** | 2026-03-11 |
| **Submission deadline** | 2026-03-31 23:59 UTC |
| **Repo purpose** | Private pre-hackathon planning/sandbox workspace |
| **Repo contains production Entry code?** | **No** |
| **Overall verdict** | **SAFE WITH CLARIFICATIONS** (see §Findings) |

---

## Compliance Boundary Model

The same boundary logic from the prior audit applies, drawn from `docs/research/hackathon-event-rules-digest.md` (Section 5) and `.github/copilot-instructions.md`:

| Category | Permitted Pre-Start? | Notes |
|----------|---------------------|-------|
| Planning (ideation, design, architecture, wireframes) | ✅ YES | |
| Learning & tooling (Sui/Move study, vendor code reading, CI/CD setup) | ✅ YES | |
| Assumption validation (devnet sandbox testing of vendor patterns) | ✅ YES | |
| Pattern documentation (validated workflows, pitfalls, reimplementation checklists) | ✅ YES | |
| Demo planning (beat sheets, narration specs, evidence registries) | ✅ YES | |
| UX architecture & strategy docs | ✅ YES | |
| Production Entry code (submission repo implementation) | ❌ NO | Must begin on or after March 11 |
| Submission repo creation | ❌ NO | Must begin on or after March 11 |
| On-chain deployment for submission | ❌ NO | Must begin on or after March 11 |

---

## Carry-Forward Artifact Audit

**Scope:** All documents listed in `docs/core/CARRY_FORWARD_INDEX.md`.

### Summary

- **25 of ~30 listed carry-forward docs audited clean** — proper retention headers, planning disclaimers, conditional/future tense, no production code claims.
- **Core docs** (`spec.md`, `implementation-plan.md`, `validation.md`, `day1-checklist.md`, etc.) all include `PRE-HACKATHON PROVISIONAL PLAN` headers and explicit "zero production code exists" assertions.
- **Demo and proof docs** correctly mark submission-phase evidence as `[TBD-digest]` with sandbox artifacts labeled `(sandbox)`.

### Issues Found

| ID | Finding | Severity | Files |
|----|---------|----------|-------|
| **CF-1** | CARRY_FORWARD_INDEX lists two strategy files at wrong paths | **HIGH** | `docs/core/CARRY_FORWARD_INDEX.md` |
| **CF-2** | PTB docs listed as carry-forward in index but headers say `Prep-only` | **MEDIUM** | 5 files in `docs/ptb/` |
| **CF-3** | Demo evidence appendix has future-dated "Last updated: 2026-03-11" | **MEDIUM** | `docs/operations/demo-evidence-appendix.md` |

**CF-1 detail:** The index lists `docs/strategy/hackathon-portfolio-roadmap.md` and `docs/strategy/marketing-plan.md`, but both files actually reside at `docs/strategy/_shared/hackathon-portfolio-roadmap.md` and `docs/strategy/_shared/marketing-plan.md`. The other four strategy paths in the index (`civilization-control/` subdirectory entries and two direct `docs/strategy/` entries) were verified — `civilizationcontrol-strategy-memo.md` and `civilizationcontrol-product-vision.md` also need path verification as the sub-agent flagged them but the actual location may be under `civilization-control/`.

**CF-2 detail:** Five PTB pattern library documents (`README.md`, `ptb-patterns.md`, `proof-extraction-moveabort.md`, `atomic-settlement-skeleton.md`, `governance-admin-skeletons.md`) are listed in the carry-forward index under "PTB Pattern Library" but their file headers declare `**Retention:** Prep-only`. This creates a classification mismatch — either the headers need updating to `Carry-forward` or the index should remove them.

**CF-3 detail:** `docs/operations/demo-evidence-appendix.md` line 7 states `> Last updated: 2026-03-11`. Today is March 9 — this date is in the future. Creates ambiguity about whether draft work was done during the hackathon period.

---

## Sandbox Code Assessment

**Scope:** All code in `sandbox/` and `experiments/` directories.

### Summary

- **All sandbox code is compliant.** No "production-ready" language detected, no production package names, all addresses are `0x0` placeholders.
- **Prior finding F1 (2026-02-24 audit) confirmed resolved:** `sandbox/validation/zk_gate/sources/zk_gate.move` no longer contains "PRODUCTION-READY" — it now reads "Sandbox validation — pre-hackathon devnet testing only."
- **All sandbox subdirectories have disclaimers:** `sandbox/validation/README.md` has explicit "⚠️ NON-SUBMISSION CODE — DO NOT copy any code from this directory to the hackathon submission repo." `experiments/atomic_courier_experiment/` has "This is NOT a production module" in both Move module headers.

### Verification

| Directory | Files | Disclaimer | "production-ready" found? | Compliance |
|-----------|-------|------------|--------------------------|------------|
| `sandbox/evevault-signing-smoke/` | 9 | ✅ README | No | ✅ SAFE |
| `sandbox/minimal-extension-test/` | 3 | ✅ Module header | No | ✅ SAFE |
| `sandbox/posture-switch-validation/` | 39 | ✅ Linked doc | No | ✅ SAFE |
| `sandbox/validation/` | 45+ | ✅ README (strong) | No | ✅ SAFE |
| `experiments/atomic_courier_experiment/` | 26 | ✅ Report + modules | No | ✅ SAFE |

---

## Date / Timeline Consistency Audit

**Scope:** All non-archived docs scanned for temporal ambiguity.

### Findings

| ID | Finding | Severity | File | Exact Quote |
|----|---------|----------|------|-------------|
| **T-1** | "shipped as a single published Move extension package" | **HIGH** | `docs/core/spec.md` L34 | "Two core modules shipped as a single published Move extension package:" |
| **T-2** | "describes a system that already works" | **MEDIUM** | `docs/demo/narration-direction-spec.md` L71 | "The narrator describes a system that already works." |
| **T-3** | "can be shipped with high polish" | **MEDIUM** | `docs/strategy/civilization-control/civilizationcontrol-strategy-memo.md` L43 | "Two tightly integrated modules can be shipped with high polish within the hackathon timeline" |
| **T-4** | "no custom turret extension is deployed" passive voice | **MEDIUM** | `docs/core/spec.md` L46, L76 | "no custom turret extension is deployed" |
| **T-5** | "The system works" in archived beat sheet | **LOW** | `docs/archive/civilizationcontrol-demo-beat-sheet.v1.md` L317 | "The system works." |
| **T-6** | "production baseline" for narration | **LOW** | `docs/demo/narration-direction-spec.md` L16 | "confirmed as the production baseline for all CivilizationControl demo narration" |
| **T-7** | Future-dated demo evidence appendix | **MEDIUM** | `docs/operations/demo-evidence-appendix.md` L7 | "Last updated: 2026-03-11" |

**T-1 detail:** This is the single most concerning temporal issue. The system specification — the lead carry-forward document — uses past-tense "shipped" to describe a system that has not been built. The document's own preamble says "Status: Pre-hackathon — zero production code exists" (L21), creating an internal contradiction. A reviewer reading L34 in isolation could interpret it as: "The system has been shipped and published."

**T-2 detail:** Demo narration guidance tells narrators to present "a system that already works." While this is correct as a performance direction (the demo should present a working demo), the sentence structure is ambiguous — it could be read as a claim about current state rather than guidance on delivery tone.

**T-3 detail:** "can be shipped" is future-conditional, which is largely acceptable in a planning context. Included for completeness.

**T-4 detail:** "no custom turret extension is deployed" uses passive voice that could read as "not yet deployed" rather than "not being built." Surrounding context clarifies intent but the phrasing itself is ambiguous.

**T-5, T-6:** Low severity. T-5 is in an archived document. T-6 is contextually clear ("demo narration") but the word "production" in a pre-hackathon doc is suboptimal.

### Impact Assessment

None of these constitute production code or Entry development. They are wording/clarity issues in planning documents. However, **T-1** (spec.md "shipped") and **T-7** (future-dated appendix) are the most likely to attract organizer scrutiny if the documents are inspected.

---

## Submission Repo Separation Check

### Separation Mechanisms Found

| Mechanism | Location | Status |
|-----------|----------|--------|
| README.md "What this repo is NOT: Not the hackathon submission repo" | Root README | ✅ Active |
| "Not pre-start code" assertion | Root README | ✅ Active |
| CARRY_FORWARD_INDEX explicit exclusion list | `docs/core/CARRY_FORWARD_INDEX.md` | ✅ Active |
| `sandbox/validation/README.md` "DO NOT COPY" warning | `sandbox/validation/` | ✅ Active |
| Day-1 checklist "verify hackathon coding period has started" gate | `docs/core/day1-checklist.md` | ✅ Active |
| Core doc PRE-HACKATHON PROVISIONAL PLAN headers | 11 core docs | ✅ Active |
| AGENTS.md "private training sandbox" assertion | Root AGENTS.md | ✅ Active |
| Commit history: docs-only prefix convention | Git log | ✅ Active |
| Retention classification system (4-tier) | All 80+ docs | ✅ Active |

### Contradictions or Weaknesses

No contradictory statements found. Separation is multi-layered and consistent. The prior audit's finding that separation is "explicit and multi-layered" remains accurate.

---

## Template Contamination Risk Check

**Question:** If this repo were naively copied into a submission repo today, what would go wrong?

### Risks Identified

| ID | Risk | Severity | Files Affected |
|----|------|----------|----------------|
| **TC-1** | Absolute Windows paths in validation docs | **MEDIUM** | `docs/validation/ssu-extension-e2e-validation.md`, `docs/validation/localnet-validation-backlog.md` |
| **TC-2** | AGENTS.md + copilot-instructions.md contain sui-playground-specific rules | **MEDIUM** | `AGENTS.md`, `.github/copilot-instructions.md` |
| **TC-3** | llms.txt describes "multi-project planning workspace" | **LOW** | `llms.txt` |
| **TC-4** | README.md says "Not the hackathon submission repo" | **LOW** | `README.md` |
| **TC-5** | .gitmodules pulls 5 submodules (not all needed) | **LOW** | `.gitmodules` |
| **TC-6** | docs/research/, docs/archive/, docs/analysis/ would be inherited | **LOW** | Multiple directories |

**TC-1 detail:** Two validation docs contain `c:\dev\sui-playground` absolute paths. These docs are NOT carry-forward (validation/ is excluded from the index), so contamination risk is low — but if copied by mistake, paths would break.

**TC-2 detail:** Both AGENTS.md and `.github/copilot-instructions.md` contain sections titled "Workspace-Specific Rules (sui-playground sandbox)" and "Sui Local Devnet" that reference this sandbox specifically. These files ARE intended to carry forward but need updates for the submission context. The `hackathon-bootstrap-checklist.md` covers this partially but could be more explicit.

**TC-3, TC-4:** These files describe the current repo's identity. They need to be rewritten for a submission repo but this is expected and documented in the bootstrap checklist.

**TC-5:** The bootstrap checklist already handles submodule cleanup — re-adds only needed submodules selectively.

**TC-6:** CARRY_FORWARD_INDEX explicitly excludes research/, archive/, analysis/ — contamination only occurs if the index is ignored.

### Mitigation Assessment

The `hackathon-bootstrap-checklist.md` covers most contamination vectors. The CARRY_FORWARD_INDEX provides a definitive allow-list. The primary gap is that AGENTS.md and copilot-instructions.md need section-level updates that are not yet itemized in the bootstrap checklist as specific steps.

---

## Findings Register

### HIGH Severity

| ID | Finding | Impact | Recommended Action |
|----|---------|--------|--------------------|
| **F-1** | `docs/core/spec.md` L34: "shipped as a single published Move extension package" uses past-tense completion language | A reviewer could interpret this as the system already being built and deployed | Change "shipped as" → "designed as" or "to be implemented as" |
| **F-2** | CARRY_FORWARD_INDEX lists two strategy files at wrong paths (`docs/strategy/hackathon-portfolio-roadmap.md` and `docs/strategy/marketing-plan.md` — actual paths are under `docs/strategy/_shared/`) | March 11 operators following the index will get wrong paths, potentially missing these docs | Fix paths in CARRY_FORWARD_INDEX.md |

### MEDIUM Severity

| ID | Finding | Impact | Recommended Action |
|----|---------|--------|--------------------|
| **F-3** | `docs/operations/demo-evidence-appendix.md` L7: "Last updated: 2026-03-11" is a future date | Creates ambiguity about whether content was drafted during the hackathon period | Change to actual last-edit date or "TBD (to be finalized March 11+)" |
| **F-4** | 5 PTB docs have `Retention: Prep-only` headers but are listed as carry-forward in the index | Classification mismatch — operators may skip them or carry confusing headers into submission repo | Update PTB doc headers to `Carry-forward` or remove from index |
| **F-5** | `docs/demo/narration-direction-spec.md` L71: "The narrator describes a system that already works" | Could be misread as a claim about current state rather than performance guidance | Reframe: "The narrator should present the system as if it already works" |
| **F-6** | `docs/strategy/civilization-control/civilizationcontrol-strategy-memo.md` L43: "can be shipped with high polish" | Marginal — "can be" is conditional, but "shipped" in a pre-hackathon doc is suboptimal | Rephrase: "are planned to ship with high polish" |
| **F-7** | `docs/core/spec.md` L46, L76: "no custom turret extension is deployed" passive voice | Could read as "not yet deployed" rather than "not being built" | Rephrase to active: "CivilizationControl does not implement a custom turret extension" |
| **F-8** | AGENTS.md and copilot-instructions.md contain sui-playground-specific sections that need updates before template use | Agents in submission repo would reference nonexistent docs and describe the repo as "planning only" | Add explicit update steps to bootstrap checklist |

### LOW Severity

| ID | Finding | Impact | Recommended Action |
|----|---------|--------|--------------------|
| **F-9** | Absolute Windows paths in 2 validation docs (`c:\dev\sui-playground`) | Only affects non-carry-forward docs; minimal contamination risk | Replace with relative paths when convenient |
| **F-10** | `docs/demo/narration-direction-spec.md` L16: "production baseline" for narration | Contextually clear but "production" is suboptimal word choice pre-hackathon | Consider changing to "demo baseline" |
| **F-11** | Archived beat sheet v1 L317: "The system works" | In `/archive/`, low risk | No action needed — archive status is sufficient |
| **F-12** | llms.txt, README.md, GITHUB-COPILOT.md describe repo as "planning workspace" | Expected — these need rewriting for submission but this is a known template-prep step | Address during bootstrap |

---

## Overall Compliance Rating

### **SAFE WITH CLARIFICATIONS**

**Rationale:**
- **No production Entry code exists** in this repository. All code is in `sandbox/` or `experiments/` and is clearly labeled as validation/test artifacts.
- **No hackathon rule violations detected.** The repository contains planning, research, architecture, strategy, demo planning, and sandbox validation — all of which are permitted pre-start activities.
- **Separation mechanisms are multi-layered and consistent.** README, AGENTS.md, CARRY_FORWARD_INDEX, sandbox READMEs, core doc banners, retention system, commit history — all assert planning-only status.
- **Two HIGH findings require attention before template-prep:** The spec.md "shipped" language (F-1) could attract organizer scrutiny, and the wrong paths in CARRY_FORWARD_INDEX (F-2) would cause operational errors on March 11.
- **Several MEDIUM findings should be addressed but are not blocking.** The future-dated appendix (F-3), PTB classification mismatch (F-4), and narration phrasing (F-5) are ambiguity issues, not rule violations.

### Comparison to Prior Audit (2026-02-24)

| Dimension | 2026-02-24 | 2026-03-09 | Delta |
|-----------|-----------|-----------|-------|
| Prior HIGH findings (F1: production-ready, F2: future-dated) | 2 found, 2 fixed | Both confirmed fixed | ✅ Improved |
| New HIGH findings | — | 2 (spec.md language, index paths) | ⚠️ New issues |
| MEDIUM findings | 0 open | 6 open | ⚠️ Expanded scope caught more |
| Sandbox code compliance | Clean | Clean | ✅ Stable |
| Separation mechanisms | Multi-layered | Multi-layered | ✅ Stable |
| Retention classifications | All present | All present (1 mismatch set) | ⚠️ PTB mismatch |
| Template readiness | Not assessed | Assessed — MEDIUM risk → LOW with fixes | New dimension |

---

## Recommendations

### Before March 11 (Blocking for clean template-prep)

1. **Fix F-1:** Change `docs/core/spec.md` L34 from "shipped as" to "designed as" or "to be implemented as".
2. **Fix F-2:** Update `docs/core/CARRY_FORWARD_INDEX.md` strategy file paths to include `_shared/` subdirectory.
3. **Fix F-3:** Change `docs/operations/demo-evidence-appendix.md` L7 from "2026-03-11" to actual last-edit date or "TBD".
4. **Resolve F-4:** Decide whether PTB docs are Carry-forward or Prep-only, then align headers with the index.

### Before March 11 (Recommended but not blocking)

5. **Fix F-5:** Reframe narration spec "describes a system that already works" → "should present the system as if it already works".
6. **Fix F-7:** Rephrase spec.md turret language from passive "is deployed" to active "does not implement".
7. **Fix F-8:** Add explicit AGENTS.md/copilot-instructions.md update steps to `hackathon-bootstrap-checklist.md`.

### Nice-to-fix (no urgency)

8. Fix F-9 absolute paths in validation docs.
9. Fix F-6 strategy memo "shipped" phrasing.
10. Fix F-10 "production baseline" → "demo baseline" in narration spec.

---

## Explicit Statement

This audit confirms that the `sui-playground` repository, as of March 9, 2026:

- **Contains no production Entry code.** All code resides in `sandbox/` and `experiments/` directories and is explicitly marked as validation/test artifacts.
- **Contains no hackathon rule violations.** All content falls within the permitted pre-start categories of planning, research, architecture, strategy, demo planning, and sandbox validation.
- **Maintains clear separation** from any future submission repository through multiple overlapping mechanisms (README, AGENTS.md, CARRY_FORWARD_INDEX, retention system, sandbox warnings, commit conventions).
- **Has wording issues** (2 HIGH, 6 MEDIUM) that should be addressed before template-prep to prevent ambiguity, but none constitute actual compliance violations.

---

## Actions Taken

The following compliance fixes were applied on 2026-03-09 in a focused remediation pass:

| ID | Fix | File(s) |
|----|-----|---------|
| F-1 | Changed "shipped as" → "designed as" | `docs/core/spec.md` |
| F-2 | Fixed 4 wrong strategy file paths (added `civilization-control/` and `_shared/` subdirectories) | `docs/core/CARRY_FORWARD_INDEX.md` |
| F-3 | Changed "Last updated: 2026-03-11" → "2026-03-09 (pre-hackathon; will be finalized during hackathon execution)" | `docs/operations/demo-evidence-appendix.md` |
| F-4 | Updated 5 PTB doc headers from `Prep-only` → `Carry-forward` (aligned with index intent) | `docs/ptb/*.md` (5 files) |
| F-5 | Reframed "describes a system that already works" → "should present the system as if it already works" | `docs/demo/narration-direction-spec.md`, `docs/strategy/civilization-control/civilizationcontrol-voice-and-narrative.md` |
| F-6 | Changed "can be shipped" → "are planned to ship" | `docs/strategy/civilization-control/civilizationcontrol-strategy-memo.md` |
| F-7 | Changed "no custom turret extension is deployed" → active voice ("does not implement" / "will not be built") | `docs/core/spec.md` (2 locations) |
| F-8 | Added "Update Workspace-Scoped Files for Submission Context" section before Final Verification | `docs/operations/hackathon-bootstrap-checklist.md` |
| F-10 | Changed "production baseline" → "demo baseline" | `docs/demo/narration-direction-spec.md` |
