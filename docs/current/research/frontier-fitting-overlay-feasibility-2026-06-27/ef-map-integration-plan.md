# EF-Map Integration Plan — Fitting Tool (2026-06-27)

**Status:** Active research artifact (Workstream F). Where the fitting tool should live and exactly
what EF-Map assets it reuses. Source: read-only audit of `Diabolacal/EF-Map` @ `b1cd69e` (Subagent F),
with paths verified.

> **Recommendation: Hybrid standalone.** Ship the fitting tool as its **own Cloudflare Pages project**
> (e.g. `fit.ef-map.com`) that **reuses EF-Map's public data assets, short-link service, industry
> engine, and CSS tokens by reference/copy** — *not* as a panel inside EF-Map's ~18k-line `App.tsx`.

---

## 1. Why hybrid standalone (not a page inside EF-Map)

| Option | Verdict |
|---|---|
| **A — Page inside EF-Map** | **Rejected.** `App.tsx` is ~18,000 lines holding the whole Three.js scene + global state; the bundle carries Three.js, GLSL, sql.js WASM, and a Rust/WASM routing core. Adding a fitting panel couples fitting releases to the 3D-map deploy/regression surface, for **no benefit** — the data is reachable cross-origin anyway. |
| **B — Pure standalone** | Good, but needlessly re-solves share links and loses the `ef-map.com/s/<id>` link identity. |
| **C — Hybrid standalone** | **Recommended.** Own Vite build (no Three.js), own deploy cadence, own rollback — but **consumes EF-Map's public assets and share service**, so a fit is still an `ef-map.com/s/<id>` link and the build cost reuses EF-Map's industry engine. Coupling risk: **low** (only the data shapes + a one-line worker prefix). |

## 2. Reusable assets (verified paths)

| Asset | Path | How to reuse |
|---|---|---|
| **Blueprint/module data** | `eve-frontier-map/public/blueprint_data_v5.json` | **Fetch cross-origin** from `https://ef-map.com/blueprint_data_v5.json` (public CDN, no CORS gate, no API key) |
| **Industry type system** | `eve-frontier-map/src/lib/industry/types.ts` | **Copy** (pure TS, zero React deps) for `IndustryDataV5`, recipes, facilities |
| **Industry planner engine** | `eve-frontier-map/src/lib/industry/industryPlanner.ts` (+ `industryData.ts`, `industryPlanner.worker.ts`) | **Copy/vendor** to run the "build this fit" shopping-list inline (pure TS) |
| **Short-link service** | `POST https://ef-map.com/api/create-share` / `GET /api/get-share` (`_worker.js`) | **Call cross-origin** — no same-origin gate; returns `{id}` → `ef-map.com/s/<id>` |
| **Long-share encoder** | `eve-frontier-map/src/utils/share.ts` (`encodeShare`/`decodeShare`, LZ+base64, schema `r2|…`) | **Pattern to mirror** for the fit-code; or reuse directly |
| **Build-sheet PNG** | `eve-frontier-map/src/utils/blueprintBuildSheet.ts` + `…Renderer.ts` (canvas) | **Pattern to mirror** for the Discord fit-card |
| **CSS design tokens** | `eve-frontier-map/src/App.css` `:root` (lines ~55–98) + `index.css` utilities | **Copy** the token block (own its evolution) |
| **Ship base stats** | `eve-frontier-map/src/utils/shipData/shipData.ts` | **Copy** (hand-authored ship stats; extend for the Root hull) |

### CSS tokens to copy (representative)
`--accent: #ff4c26` (signature orange), `--bg-primary #0a0a0a`, `--bg-surface rgba(30,30,32,0.78)`,
`--text-primary #fff`, `--text-muted #9ca3af`, `--border-color rgba(255,255,255,0.1)`,
`--ef-dur-fast 120ms`. Also reusable utility classes: `.ef-primary-btn`, `.ef-scrollable`,
`.ef-copy-feedback`, `.ef-skeleton`, and a `data-worksafe` light-theme pattern.

## 3. Data-loading pattern
EF-Map fetches static assets as plain public GETs with no auth: `BlueprintCalculatorV5.tsx` does
`fetch('/blueprint_data_v5.json')`; the industry worker fetches it independently for its own cache.
**A standalone tool does the same cross-origin** (`fetch('https://ef-map.com/blueprint_data_v5.json')`).
Only the `/api/*` dynamic routes are origin/key-gated — the **static CDN assets and the share
endpoints are open**. (Verify CORS once in prod devtools; Pages CDN headers can differ from the worker.)

> **Versioning watch:** the asset URL is version-pinned (`…_v5.json`); a future patch may publish
> `_v6.json`. The tool should resolve the current filename via `versionInfo.json`/the EF-Map decision
> log, or pin and bump deliberately. This is the one real coupling to manage.

## 4. Share / permalink plan
1. **Fit code in URL** (no backend): every edit serializes the fit to `?fit=<code>` (see
   [`fitting-model-and-rules.md` §3.6](fitting-model-and-rules.md)).
2. **Short link** (shareable, reuses EF-Map KV): `POST https://ef-map.com/api/create-share` with the
   fit payload → `ef-map.com/s/<id>`. **Caveat:** the worker validates the payload prefix against
   `/^r\d+\|/` (`_worker.js` ~line 2227). So either (a) **use an `r3|` prefix** as "fitting schema v1"
   (works today, zero EF-Map change), or (b) coordinate a **one-line worker patch** to also accept
   `f\d+|`. Recommend **(a)** for the MVP to avoid any EF-Map change.

## 5. Build-plan tie-in (fit → shopping list)
Each fitted module's typeID is already in `blueprint_data_v5.json` `recipes`. Two handoff options:
- **Inline (recommended):** vendor the pure-TS `industryPlanner` + worker; compute a `PlannedRoute`
  per module and aggregate inputs into one shopping list rendered in-tool — no page transition, best UX.
- **Deep-link:** open `https://ef-map.com/blueprint-calculator?item=<typeID>&qty=<n>`. **But** the
  calculator (`BlueprintCalculatorV5.tsx`) currently has **no URL-param intake, no permalink, no
  `postMessage` listener** — it is local-state + `localStorage` only. The deep-link path needs a small
  EF-Map addition (parse `?item=&qty=` on mount). Prefer inline for the MVP; propose the param intake
  to EF-Map as a tiny, clean enhancement later.

## 6. postMessage / embed (optional, not core)
EF-Map's embed accepts `postMessage` (`ef-map-navigate|highlight|zoom|angle|enter-system|show-universe`,
`App.tsx` ~2057–2117, origin `*`, only when `embedMode`). A fitting tool could iframe-embed the map to
show *where* a fit operates, but this is **not** a build-plan channel and is not needed for the MVP.

## 7. How to avoid bloating EF-Map (rules)
1. **Don't import `BlueprintCalculatorV5`** (1,880-line React component in the map bundle) — copy only
   the pure-TS `lib/industry/*`.
2. **Don't pull in Three.js / routing workers / WASM** — fitting needs none of it.
3. **Don't co-deploy** in EF-Map's Pages project — separate project = separate build/rollback.
4. **Do fetch static assets cross-origin**; **do copy (not import) CSS tokens**; **do reuse the open
   share endpoints**.

## 8. Net architecture
```
fit.ef-map.com  (own Cloudflare Pages project, Vite + React, no Three.js)
  ├── fetch  https://ef-map.com/blueprint_data_v5.json     (module catalog: id/mass/vol/recipe)
  ├── vendor lib/industry/* (pure TS)                       (build-cost shopping list, inline)
  ├── catalog: hand-authored footprints + hardpoints + ship base stats (versioned JSON)
  ├── engine: polyomino placement + power + stats (this repo's fitting-model spec)
  ├── share:  ?fit=<code>  +  POST ef-map.com/api/create-share (r3| prefix) → ef-map.com/s/<id>
  └── (optional) push fit_plan to the desktop overlay  (see overlay-helper-audit.md)
```

## 9. Open questions
- Confirm static-asset CORS in production browser devtools.
- Decide `r3|` prefix vs a one-line worker patch for fit short-links.
- Decide whether to ask EF-Map for `?item=&qty=` intake on the calculator (nice-to-have, not MVP).
- Track the `blueprint_data` version-bump cadence so the tool doesn't break on `_v6.json`.
