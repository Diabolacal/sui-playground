# Implementation Brief — Overlay Visual Refresh (Phase 1)

**Status:** Brief for a future build pass (not built here). A ~1-day, low-risk C++ pass that makes the
overlay look like EVE Frontier instead of an ImGui debug window. Full plan + tokens in
[`../overlay-visual-redesign.md`](../overlay-visual-redesign.md). Can ride the same Store submission as
the overlay generic-payload work.

## Goal
Replace the default ImGui look (ProggyClean bitmap font + `StyleColorsDark()`) with an EVE-authentic
HUD: near-black translucent panels, orange accent + white hairlines, monospaced right-aligned numeric
columns, flat angular chrome, text tabs with an orange underline, DPI-correct on 1440p/4K.

## Changes (Phase 1 — no schema change)
| # | Change | File |
|---|---|---|
| P1 | Load **Roboto Condensed** (body) + **Roboto Mono** (numbers), embedded as C++ byte arrays | `overlay_hook.cpp:~517` (after `CreateContext()`) |
| P2 | Custom `ImGuiStyle`: `WindowRounding=0, FrameRounding=0, TabRounding=0, FrameBorderSize=1, WindowBorderSize=0, ScrollbarRounding=0` | `overlay_hook.cpp:517` |
| P3 | Swap color constants for the token set (orange `#FF6B00`, hairline white@0.18, label gray, online/offline) | `overlay_renderer.cpp:50-62` |
| P4 | **Unfocused alpha 0.36 → 0.55** (biggest readability win) | `overlay_renderer.cpp:51` |
| P5 | Single `kHairWhite` `Separator()` instead of triple `Spacing()` | multiple sites |
| P6 | Flat **bordered-text buttons** (no fill, orange label + 1px border) | `kButton*` |
| P7 | **DPI auto-detect** `GetDpiForWindow(g_hwnd)` → set `uiScale_` (96→1.0, 144→1.5, 192→2.0) + `ScaleAllSizes()` | `overlay_hook.cpp` post-init |
| P8 | Sparkline bg rust → near-black | `overlay_renderer.cpp:62` |

## Phase 2 (optional, +~1 day)
Manual text tab strip (`DrawList::AddText` + 2px orange underline) replacing `BeginTabBar`; UPPERCASE
section headers + hairline; right-aligned value columns via `SameLine()` + `SetCursorPosX`.

## Acceptance / smoke
- Overlay renders crisp at 1440p **and** 4K with no manual scaling.
- Panel readable when unfocused; tabs are text+underline; buttons are flat/bordered; numeric columns
  align (mono font).
- No per-frame animation added; render-thread cost unchanged.
- All interactive widgets (checkbox, sliders) still usable after `FrameBorderSize=1`.

## Risks
Font bundling in MSIX (embed as byte array, don't load from sandbox path); game may force a DPI context
(fallback `GetDpiForSystem()` / settings preset); Store cert re-sign (batch changes; old build stays
live on failure); font load is one-time in init (no anti-cheat timing concern).
