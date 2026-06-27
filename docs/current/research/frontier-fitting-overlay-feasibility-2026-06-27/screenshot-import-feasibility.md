# Screenshot Import Feasibility — Fitting Tool (2026-06-27)

**Status:** Active research artifact (Workstream E). Assesses whether a user can import a fit by
screenshot/snip, and how. **Bottom line: keep screenshot import OUT of the MVP; it is a staged
follow-up, and it must never block the fitting tool.**

> Cross-reference: the *ideal* import path is not vision at all — it is reading a ship's fitted
> modules from the game API / chain by ship ID. Whether that is possible is the
> [`data-source-audit.md`](data-source-audit.md) question. If it is, prefer it over CV.

---

## 1. What a screenshot actually contains (and what's worth recovering)

A full fitting-screen screenshot (see [`operator-context.md` §5](operator-context.md)) has three
information regions, with very different recovery difficulty and value:

| Region | Content | Recovery difficulty | Value to a fit reconstruction |
|---|---|---|---|
| **Right pane — Power Management module list** | Every fitted module, by name, grouped by category, with online/offline + MW | **Low–Med** (structured text list, fixed layout) | **High** — this *is* the bill-of-materials of the fit |
| **Left pane — derived stats** | Volume/Mass/HP/Cap/Fuel/Powergrid numbers | Low (text) | Low — these are *outputs* we recompute; only useful as a **validation oracle** |
| **Center — ship grid silhouette** | Polyomino placement & rotation of each module | **High** (spatial CV) | Low for stats (placement barely affects stats); only needed for exact visual reproduction |

**Key insight:** the fit's *stats* are determined by **which modules are fitted + their online/offline
state + powergrid**, not by where each polyomino sits. So **reading the right-pane module list
reconstructs ~95% of a fit's meaning** without solving the hard spatial problem. That reframes
"screenshot import" from "computer-vision reconstruct the Tetris board" to "read a structured list" —
which is far more tractable.

## 2. Deterministic-CV plan (preferred over AI, per operator)

### Stage 1 — Module-list assist (the high-value, modest-risk path)
Goal: from a Power Management screenshot, pre-populate the fit with the correct **set and counts** of
modules (+ online/offline), then let the user correct.

Pipeline (all client-side, image never leaves the browser):
1. **Region crop by anchors.** The layout is fixed: detect the `POWER MANAGEMENT` tab and the
   powergrid bar to anchor scale, then crop the right pane. Use simple template matching on the
   stable UI chrome (tab label, bar) rather than absolute pixels, so it tolerates resolution changes.
2. **Row segmentation.** The module list is a vertical list of rows with consistent line height;
   detect rows by horizontal projection (row gaps are near-uniform background). Category headers
   (small-caps, brighter) segment groups.
3. **Name reading — dictionary-constrained OCR.** Run a **lightweight in-browser OCR**
   (Tesseract.js) on each row's name region, then **fuzzy-match against the known module catalog**
   (Levenshtein / token match). Because the candidate set is small and known (~tens of module
   names), constrained matching is robust even with mediocre OCR. This avoids any paid AI vision API.
4. **State read.** The online/offline toggle and the `0.1 MW` line are positional; detect the
   orange-vs-dim toggle by color threshold; the MW value is optional (we know it from the catalog).
5. **Aggregate → fit.** Count modules per type → produce a candidate fit; show a **manual-correction
   UI** (editable list with add/remove/±) before accepting.

**Why this is robust:** the only fragile step (OCR) is backstopped by a closed dictionary; everything
else is structural. Accuracy target: get the *set* right; let the human fix the long tail.

### Stage 2 — Spatial placement import (stretch / "full import")
Goal: also reconstruct *where* each module sits and its rotation, to redraw the exact board.
- **Approach:** grid detection (Hough/period estimation on the fine internal grid) → hull-mask
  registration → **template matching of the white-outlined module shapes** against the editor's own
  authored shape templates (which we already have, because the editor needs them — see
  [`fitting-model-and-rules.md`](fitting-model-and-rules.md)). The strong, unique white outlines make
  this *plausible* but not easy.
- **Reality check:** scale/rotation search × overlapping shapes × anti-aliasing makes this a genuine
  CV project with its own maintenance tail. Its payoff (exact placement) is low because placement
  doesn't drive stats. **Recommend deferring indefinitely** unless a clear user demand appears.

### Tech-stack choice
| Option | Verdict |
|---|---|
| **Browser-only OpenCV.js + Tesseract.js** | **Recommended.** No backend, no upload, privacy-preserving, zero per-call cost. Sufficient for Stage 1. |
| Backend Python (OpenCV/numpy) service | Avoid for MVP — adds hosting, upload, privacy surface; only consider if Stage 2 ever justifies it. |
| AI vision API (Claude/GPT vision) | **Optional fallback only.** Most robust for messy input but costs money, adds latency, and uploads the user's screenshot. Operator said avoid for MVP. Could be an opt-in "having trouble? try smart import" button later. |

## 3. The biggest risk: alpha UI churn
EVE Frontier is alpha; the **in-game fitting UI will change** (layout, fonts, colors, even the stat
set). Any import that depends on **pixel coordinates or exact chrome** has a **recurring maintenance
cost** every time CCP reskins the screen. This is the single strongest reason to (a) keep import out
of the MVP, (b) anchor on stable landmarks rather than absolute pixels, and (c) treat it as opt-in
assist with human correction — never a load-bearing dependency.

## 4. Manual-correction flow (required for any import)
Whatever the import accuracy, the result lands in an **editable review panel**: a list of detected
modules with confidence flags, inline add/remove/quantity controls, and a "looks right? apply"
confirm. The user is always in the loop; import is an accelerator, not an oracle.

## 5. Recommendation
- **MVP: no screenshot import.** Build the manual fitting editor first.
- **Week-1/month follow-up: Stage 1 module-list assist** (dictionary-constrained in-browser OCR) —
  this is where nearly all the import value is, at modest risk, fully client-side.
- **Stretch/deferred: Stage 2 spatial import** — reuse the editor's shape templates; only if demanded.
- **Prefer a non-CV import if it exists:** if the game API/chain exposes a ship's fitted modules by
  ship ID (pending [`data-source-audit.md`](data-source-audit.md)), an **"import by Creation ID"**
  is deterministic and strictly better than any screenshot path — make that the headline import story
  if the data supports it.

### Fastest kill test
Take the operator's 3 screenshots, hand-crop the right pane, and run Tesseract.js on the name column
once. If dictionary-constrained matching recovers the module names cleanly, Stage 1 is green. (~1–2h.)
