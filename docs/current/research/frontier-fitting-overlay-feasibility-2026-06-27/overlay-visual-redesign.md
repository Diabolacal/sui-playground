# Overlay Visual Redesign Plan (2026-06-27)

**Status:** Active research artifact (Workstream G, visual half). A practical, phased plan to make the
EF-Map overlay look like EVE Frontier's in-game UI. Source: read-only audit of
`Diabolacal/ef-map-overlay` @ `8788a16` (Subagent G), file:line preserved. **No visual changes were
implemented** — this is a plan.

> **Headline:** The overlay currently renders with **ImGui's default `StyleColorsDark()` + the
> built-in ProggyClean bitmap font** — i.e. it looks like a debug window. Five small C++ changes
> (fonts, flat style tokens, brighter unfocused alpha, text-underline tabs, DPI auto-detect) move it
> most of the way to an EVE-authentic HUD in about **one day**, shippable in a single Store update.

---

## 1. Current visual state (evidence)
- **No custom style, no custom font.** `overlay_hook.cpp:517` calls only `ImGui::StyleColorsDark()`;
  no `AddFontFromFileTTF` → the **13px ProggyClean bitmap font**, scaled via `FontGlobalScale`
  (`overlay_renderer.cpp:637`) so it **blurs at >1×**. No monospaced numeric font.
- **Color tokens** live as constants in `overlay_renderer.cpp:50-62`: focused panel bg
  `rgba(0.035,0.035,0.035,0.72)`, **unfocused `…,0.36`** (nearly invisible), filled-orange tabs
  (`kTabActive ≈ rgba(1.0,0.42,0,0.99)`), filled-orange buttons (`kButtonBase`).
- **Rounded** buttons (`FrameRounding 2`) and a 6px rounded panel — not EVE's flat/angular look.
- **Only one hairline** (1px near-white accent at panel top, `:678-684`); sections separated by triple
  `ImGui::Spacing()` rather than rules → content runs together.
- **DPI: manual only** (`uiScale_` 0.75–1.5 in 0.25 steps, `overlay_renderer.hpp:108-111`); no
  `GetDpiForWindow`, no `ScaleAllSizes()` → unreadable on 4K until the user manually scales.

## 2. Target aesthetic (from the in-game screenshots)
Near-black translucent surfaces (~`rgba(8,8,10,0.85)`); a single **orange accent** (~`#FF6B00`) for
hairlines/active state; **thin white hairline** section dividers (~18% opacity); **muted-gray labels**
with **near-white, right-aligned, monospaced values**; **UPPERCASE small-caps section headers**
(`STRUCTURE`, `PROPULSION`, `FUEL & ENERGY`); **plain-text tabs with a thin orange underline** on the
active tab; minimal icons; **no window chrome**; **no animation**; high contrast.

## 3. Style guide (concrete tokens)
```
// backgrounds
kBgPanel      rgba(  8,  8, 10, 0.87)   kBgPanelDim  rgba( 8, 8,10, 0.55)  // (fix: was 0.36)
kBgGraphArea  rgba( 12, 12, 16, 1.00)
// accent + hairlines
kAccentOrange rgba(255,107,  0, 1.00)   kAccentHot   rgba(255,140,30,1.00)
kHairWhite    rgba(255,255,255,0.18)    kHairOrange  rgba(255,107, 0,0.80)
// type
kTextPrimary  rgba(220,222,226,0.96)    kTextLabel   rgba(130,138,148,1.0)
kTextHeader   rgba(165,170,178,1.00)    kTextWarn    rgba(255,190,60,1.0)
kOnline       rgba( 80,200,120,1.00)    kOffline     rgba(200, 60,60,1.0)
// flat bordered buttons + text-underline tabs + bars
kBtnFg orange / kBtnBorder orange@0.6 / kBtnFillHot orange@0.12
kTabTextActive near-white / kTabTextInactive label-gray / kTabUnderline orange (2px)
kBarFill orange@0.8 / kBarDanger red@0.9 (>80%) / kBarTrack white@0.08
```
**Typography:** body/labels **Roboto Condensed 13px** (or Barlow Condensed); numeric columns **Roboto
Mono 12px** (Consolas/Cascadia fallback); headers = body font UPPERCASE, +0.08em tracking. **Embed the
.ttf as a C++ byte array** to avoid MSIX path issues.
**ImGuiStyle at init:** `WindowRounding=0, FrameRounding=0, TabRounding=0, FrameBorderSize=1,
WindowBorderSize=0, ScrollbarSize=8, ScrollbarRounding=0`, `WindowPadding(10,8)`, `ItemSpacing(8,4)`,
`FramePadding(6,3)`.

## 4. Phased plan
### Phase 1 — low-risk polish (C++ only, no schema change; ~1 day; one Store update)
| # | Change | File |
|---|---|---|
| P1 | Load **Roboto Condensed + Roboto Mono** after `CreateContext()` | `overlay_hook.cpp:~517` |
| P2 | Replace `StyleColorsDark()` with custom `ImGuiStyle` (flat corners, 1px frame border) | `overlay_hook.cpp:517` |
| P3 | Swap color constants for the token set above | `overlay_renderer.cpp:50-62` |
| P4 | **Unfocused alpha 0.36 → 0.55** (one number; biggest readability win) | `overlay_renderer.cpp:51` |
| P5 | Replace triple `Spacing()` with a single `kHairWhite` `Separator()` | multiple sites |
| P6 | Flat **bordered-text buttons** (no fill, orange label + 1px border) | `kButton*` constants |
| P7 | **DPI auto-detect**: `GetDpiForWindow(g_hwnd)` → set `uiScale_` (96→1.0, 144→1.5, 192→2.0) | `overlay_hook.cpp` post-init |
| P8 | Sparkline bg rust → near-black `kBgGraphArea` | `overlay_renderer.cpp:62` |

### Phase 2 — tabs + section headers (ImGui-only; ~1 day)
- Draw the **tab strip manually** (`DrawList::AddText` + 2px orange underline on active) instead of
  `BeginTabBar` (removes the off-brand filled-orange tabs).
- Add **UPPERCASE section headers** + hairline before groups; **right-align value columns** via
  `SameLine()` + `SetCursorPosX(width - valueWidth)` (the EVE numeric-column look).

### Phase 3 — card/fit_plan renderer (needs schema v5; ~2–3 days incl. Store resubmit)
- Parse `overlay_cards[]`; generic card loop (`overlay_card`/`checklist`/`notification`/`session_card`);
  the **`fit_plan` widget** (powergrid bar + grouped module checklist) per
  [`overlay-helper-audit.md` §4.3](overlay-helper-audit.md). ~300 lines total.

### Phase 4 — edge polish
`ScaleAllSizes()` after DPI detect; clamp initial window into a safe zone (≥50px from edges); optional
separate window-opacity control. Avoid animation (EVE uses none; per-frame anim costs render-thread CPU).

## 5. Top 5 fixes (impact per hour)
1. **Load Roboto Condensed + Roboto Mono** (`overlay_hook.cpp:~517`) — turns a debug window into a
   technical HUD. (1–2 h)
2. **Unfocused alpha 0.36 → 0.55** (`overlay_renderer.cpp:51`) — the panel is nearly invisible when not
   hovered. (5 min)
3. **Text tabs + orange underline** (replace `kTab*` + `BeginTabBar`) — kills the most off-brand
   element. (3–4 h)
4. **Flat bordered buttons** (`kButtonBase` → zero-fill + `FrameBorderSize=1` orange border). (30 min)
5. **DPI auto-detect** (`GetDpiForWindow`) — fixes unreadable overlay on 1440p/4K with no user action.
   (1 h)

## 6. Risks
- **Font bundling in MSIX** → embed as byte array (imgui_club pattern), don't load from a sandbox path.
- **Game may force a DPI context** → fall back to `GetDpiForSystem()` or a settings preset.
- **`FrameBorderSize=1` affects checkboxes** → verify all interactive widgets after the style swap.
- **Store cert re-sign** (1–3 days) per C++ change → batch Phase 1 (+ overlay-helper Phase A) into one
  submission; existing Store build stays live if review fails.
- **Anti-cheat timing** → one-time font load in init is fine; avoid per-frame allocation/animation.

## 7. Relationship to the fitting tool
The fitting tool ships **first and independently** (web only). This overlay refresh is a **parallel,
optional** track. The two converge at the **`fit_plan` card** (Phase 3 here = Phase B in the helper
audit): the fitting web app pushes a fit, the polished overlay renders the in-cockpit checklist. Do
**not** block the fitting MVP on any overlay work.
