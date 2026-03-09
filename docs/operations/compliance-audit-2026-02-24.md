# Hackathon Compliance Audit — 2026-02-24

**Retention:** Prep-only (superseded by compliance-audit-2026-03-09.md)

> Governance snapshot — structured compliance audit of the sui-playground planning repository against EVE Frontier hackathon rules.
> Audit date: 2026-02-24
> Auditor: AI compliance pass (4 structured sub-passes)
> Current date at audit: February 24, 2026 — Hackathon building phase starts March 11, 2026

---

## 1. Rule Interpreter — Compliance Boundary Model

### Governing Statement (organizer, direct quote):
> "The Hackathon 'Building phase' starts at 11th March and ends 31 March. You can absolutely brainstorm ideas, form teams, plan things etc until that time."

### Hackathon Rules Section 5 (binding):
> "Your Entry must be developed on or after the Hackathon start date"

### Compliance Boundary Definitions

| Category | Definition | Permitted Pre-March-11? |
|----------|-----------|------------------------|
| **Planning** | Research, ideation, architecture docs, design planning, strategy memos, UI wireframes, judging criteria analysis, team formation | **YES** |
| **Learning & Tooling** | Learning Sui/Move, reading vendor source, setting up dev environments, configuring CI/CD, reading CCP Materials | **YES** |
| **Assumption Validation** | Running vendor code on local devnet to verify API behavior, publishing vendor examples to validate signatures, confirming architectural feasibility | **YES** (sandbox activity, not "developing an Entry") |
| **Pattern Documentation** | Documenting validated patterns, writing reimplementation checklists, recording known pitfalls | **YES** (knowledge capture, not code production) |
| **Building** | Writing production code intended for the submission Entry, creating the submission repository, implementing application features | **NO** |
| **Submission-phase work** | Code development in the fresh submission repo, on-chain deployment targeting the submission, demo recording | **NO — March 11+ only** |

---

## 2. Carry-Forward Artifact Audit

### 2.1 Documents Scanned

| Document | Retention | Risk |
|----------|-----------|------|
| core/spec.md | Carry-forward | **LOW** |
| core/civilizationcontrol-implementation-plan.md | Carry-forward | **LOW** |
| core/validation.md | Carry-forward | **LOW** |
| core/day1-checklist.md | Carry-forward | **LOW** |
| core/memory.md | Carry-forward | **LOW** |
| core/march-11-reimplementation-checklist.md | Carry-forward | **LOW** |
| core/civilizationcontrol-claim-proof-matrix.md | Carry-forward | **LOW** |
| core/civilizationcontrol-demo-beat-sheet.md | Carry-forward | **LOW** |
| operations/gate-lifecycle-runbook.md | Carry-forward | **LOW** |
| operations/shortlist-viability-validation-report.md | Carry-forward | **LOW** |
| README.md (root) | N/A | **SAFE** |

### 2.2 Findings

**No production code found in carry-forward documents.** All documents contain:
- Architecture patterns and design diagrams
- Move function signature references (from vendor source, not original code)
- Step-by-step checklists for future execution
- Devnet validation evidence (tx digests from local testing)

**Positive guardrails present in all carry-forward docs:**
- `PRE-HACKATHON PROVISIONAL PLAN` banner on every doc
- `"zero production code exists"` explicit statement in spec.md and implementation plan
- `"Must be re-audited against live world contracts"` disclaimer
- March-11-reimplementation-checklist explicitly states: *"a pattern reference and checklist — not code to copy"* and *"all sandbox code stays in sui-playground"*

### 2.3 Sandbox Code Assessment

**7 Move files exist** in sandbox/validation/:
- gate_toll_validation/sources/gate_toll.move — 241 lines, mock gate toll
- trade_post_validation/sources/ssu_trade.move — 237 lines, mock SSU trade
- trade_post_validation/sources/mock_ssu.move — mock storage unit
- trade_post_validation/sources/trade_post.move — basic trade post
- zk_gatepass_validation/sources/groth16_test.move — ZK test
- zk_gatepass_validation/sources/zk_gate_compose.move — ZK composition test
- zk_gate/sources/zk_gate.move — 246 lines, standalone ZK module

**All sandbox modules:**
- Are in `sandbox/` (not `src/`, not `contracts/`)
- Do NOT depend on world-contracts (they mock/simulate patterns)
- Have explicit `DO NOT COPY TO HACKATHON SUBMISSION` comments
- Have clear `SANDBOX CODE` labels

**One concerning phrase found** — see Finding F1 below.

---

## 3. Date & Devnet Context Audit

### 3.1 Critical Finding: Future-Dated Addenda

**Finding F2 (MEDIUM risk):** 20+ references to `2026-03-11` appear across documents committed before that date. Examples:

| Document | Phrasing | Issue |
|----------|----------|-------|
| shortlist-viability-validation-report.md | `Date: 2026-02-16 (ZK addendum: 2026-03-11)` | Future date with completion language |
| hackathon-portfolio-roadmap.md | `PASSED (2026-03-11)` | Implies test passed on a date that hasn't occurred |
| hackathon-portfolio-roadmap.md | `Status update (2026-03-11): All ZK kill gates passed` | Reads as if written on March 11 |
| zk-gatepass-feasibility-report.md | `ZK devnet addendum: 2026-03-11` | Temporal inconsistency |
| Various strategy docs | `environment model corrected 2026-03-11` | Implies editing occurred on that date |
| march-11-reimplementation-checklist.md | `environment model corrected 2026-03-11` | Same |

**Risk assessment:** These appear to be forward-looking planning annotations indicating *when* activities will be performed/re-validated. However, the language uses past tense ("PASSED", "validated", "implemented", "published") making them read as completed work. A reviewer examining this repo could reasonably ask: "How can something have PASSED on a date that hasn't happened?"

**Recommendation:** Minor wording adjustment needed. Change all `2026-03-11` addenda from completion language to planning language.

### 3.2 Devnet Transaction Digests

All tx digests in the validation report originate from **local Sui devnet** (Docker container). Evidence:
- Environment section clearly states: `Platform: Sui local devnet via Docker (vendor/builder-scaffold/docker)`
- No RPC URLs pointing to testnet/mainnet
- All object IDs and digests are from ephemeral local state
- The claim-proof-matrix explicitly separates sandbox digests from `[TBD-digest]` placeholders for submission artifacts

**Risk:** LOW. The devnet validation is clearly local sandbox testing, consistent with "learning Sui / setting up tooling."

### 3.3 Gate Lifecycle Runbook

Contains 17 transaction digests from a full 13-step gate lifecycle rehearsal on local devnet. This is the most detailed pre-start validation activity but is clearly:
- Local devnet only (no external server)
- Uses vendor code (world-contracts) not original code
- Documents operational knowledge (like a rehearsal)
- Explicitly labeled Carry-forward as operational reference, not code

**Risk:** LOW. Rehearsing vendor code deployment sequences is analogous to learning the platform.

---

## 4. Submission Repo Separation Check

### 4.1 Explicit Separation Statements Found

| Location | Statement |
|----------|-----------|
| README.md (root) | *"Not the hackathon submission repo. The submission repo will be created fresh on March 11, 2026 with a clean commit history. No Entry code lives here."* |
| README.md (root) | *"Not pre-start code. Per hackathon rules (Section 5), Entries must be developed on or after the start date."* |
| core/spec.md | *"Status: Pre-hackathon — zero production code exists"* |
| core/civilizationcontrol-implementation-plan.md | *"Status: Pre-hackathon planning — zero production code exists"* |
| sandbox/validation/README.md | *"DO NOT copy any code from this directory to the hackathon submission repo. Reimplement from scratch on March 11"* |
| core/validation.md | Pre-submission check: `git log --oneline --before="2026-03-11"` — Expected: 0 results |
| core/day1-checklist.md | Step 1 is literally "Verify hackathon coding period has started" with fallback "DO NOT create any code until start date confirmed" |
| Implementation plan S01 | *"Create fresh GitHub repo with no prior commits. First commit."* |

### 4.2 Retention Classification System

The repository implements a 4-tier retention system (Carry-forward / Prep-only / Sandbox-only / Archive) that explicitly classifies what transfers to the submission repo and what doesn't. This is a strong compliance signal.

### 4.3 No Accidental Mixing Detected

- No `src/` or `contracts/` directories exist at root (only `sandbox/` and `vendor/`)
- No `package.json` at root for a web application
- No React/TypeScript source files outside `sandbox/`
- Commit history prefixes are overwhelmingly `docs:` — not `feat:` or `fix:`

**Risk:** SAFE. Separation is explicit, multi-layered, and reinforced across documents.

---

## 5. Individual Findings Register

### F1: "production-ready" language in sandbox code (MEDIUM)

**Location:** sandbox/validation/zk_gate/sources/zk_gate.move line 4
**Text:** `/// production-ready module for GateControl integration`
**Issue:** A sandbox validation file describing itself as "production-ready" contradicts the "sandbox test code only" framing. This module (246 lines) is the most complete and closest to copy-paste-ready code in the repo.
**Recommendation:** Change comment to validation/sandbox language. The file does say "Sandbox validation — pre-hackathon devnet testing only" on line 18, which partially mitigates.

### F2: Future-dated addenda with completion language (MEDIUM)

See §3.1 above. 20+ instances of `2026-03-11` dates with past-tense language in documents committed before that date.

### F3: Implementation plan detail level (LOW — No action needed)

The implementation plan contains 45 steps with Move struct names, function signatures, and PTB patterns. This is extremely detailed planning. However:
- It contains no executable code blocks that compile
- All Move references are to vendor patterns, not original implementations
- The plan describes *what to build*, not *the built thing*
- This falls squarely within "brainstorm, plan, architect" per the organizer statement

### F4: Claim-proof matrix pre-populated with sandbox digests (LOW — No action needed)

The claim-proof-matrix pre-maps every demo claim to evidence. Sandbox tx digests are clearly labeled as "(sandbox)" with `[TBD-digest]` for submission artifacts. The document intro states: *"sandbox digests below are proof-of-pattern, not submission artifacts."*

---

## 6. Overall Compliance Rating

### SAFE WITH CLARIFICATIONS

Two findings require minor wording adjustments before carry-forward:

| Finding | Severity | Action |
|---------|----------|--------|
| **F1:** "production-ready" in zk_gate.move comment | MEDIUM | Change to "validation module" language |
| **F2:** Future-dated addenda (2026-03-11) with completion language | MEDIUM | Rewrite as forward-looking ("to verify on March 11") or remove dates |

No HIGH-risk findings. No production code found. No embargo violation detected.

---

## 7. Recommendations

1. Fix F1 and F2 before March 11. Both are minor wording changes but remove the two interpretive ambiguities a reviewer could flag.
2. No artifacts need to be excluded from carry-forward. All carry-forward documents are planning artifacts with appropriate guardrails.
3. Commit history is safe. 30+ commits are `docs:` prefixed. Sandbox validation commits are clearly labeled. No commits suggest application development.
4. The sandbox/ directory and its Move code should NOT be carried forward. The sandbox/validation/README.md already prohibits this. Verify this is enforced on March 11.

---

## 8. Explicit Statement

> Based on all available evidence, a reasonable organizer would interpret this repository as planning only.
>
> The repository contains research, architecture documentation, strategy analysis, sandbox validation of vendor code on local devnet, and implementation planning — all activities explicitly permitted by the organizer statement ("brainstorm ideas, form teams, plan things"). No production Entry code exists. The separation between this planning repo and the future submission repo is stated in 8+ locations across different documents. The retention classification system, "DO NOT COPY" warnings, and "PRE-HACKATHON PROVISIONAL PLAN" banners demonstrate active compliance awareness.
>
> The two MEDIUM-severity findings (F1: "production-ready" comment, F2: future-dated completion language) are cosmetic ambiguities that should be clarified but do not constitute embargo violations.

---

## Actions Taken (Post-Audit)

- **F1 FIXED:** Changed "production-ready module" to "standalone validation module... Sandbox only — not submission code" in `sandbox/validation/zk_gate/sources/zk_gate.move`
- **F2 FIXED:** Reframed all 2026-03-11 future-dated addenda across 16 files as forward-looking validation checkpoints (e.g., "to re-validate on hackathon test server March 11"). Decision-log entries marked `(PLANNED)`. Kill criteria changed from `PASSED (2026-03-11)` to `TO RE-VALIDATE on hackathon test server (passed on local devnet)`. Factual date references ("Hackathon starts: 2026-03-11") preserved as-is.
- No production code present
- No embargo violations detected
