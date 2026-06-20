# Design Fidelity Audit — current build vs `design_handoff_plop/screenshots/`

Date: 2026-06-20 · Reference: the 10 handoff screenshots. Severity: **P1** clear
divergence/bug · **P2** notable · **P3** minor/nice-to-have.

The dominant theme: in the handoff, **every Settings option is a bottom popup over a
blurred scrim**. We built 3 as pushed screens and the rest as plain (un-blurred)
sheets. That single presentation gap drives most P1s below.

---

## Screen-by-screen

### Settings — `settings.jpg`  ✅ mostly addressed (Cleanup A)
- Tiles, DATA/PREFERENCES/SUPPORT, "Version 1.0.0" footer — done in the restyle.
- Remaining: the **tab bar** (below) and the **manual version bump** to 1.0.0.

### Tab bar — (in `home/insight/settings.jpg`)  → Cleanup D
- **P1 color/material:** ours uses `.ultraThinMaterial` → reads **gray** on the
  baby-blue bg. Handoff is bright near-white (white ~74%) + strong blur/saturation.
- **P1 bottom padding:** ours floats with a big empty band (fixed `height: 92` +
  `ignoresSafeArea(.bottom)` adds the home-indicator inset as extra height). Handoff
  bar is flush; content sits low, the bottom ~34pt is the indicator zone.
- **P3 glyphs:** handoff Insights = vertical bars, Settings = sun-ish; ours `chart.bar`
  / `gearshape`. Center button correctly becomes a house when off-Home (matches).

### Home — `home.jpg`  ✅ close
- TxRow already matches: colored category tile, name (+ recurrence marker), note-or-
  time subtitle, signed amount (income green). Day group labels + subtotals match.
- **P3:** net-total shows a smaller **gray "$" prefix** before the big figure in the
  handoff; ours renders the symbol inline via `formattedMoney`. Minor.

### Insights — `insight.jpg`  ✅ close, one divergence
- Donut (LEFT/of total), spent-of-budget subhead pill, legend (dot · name · chevron ·
  `$spent / $budget` · % used · bar) all match our budget mode.
- **P2 divergence:** the handoff header has **only** the This Month/This Year toggle —
  **no Breakdown/Budget switch** (the prototype flips mode via a build flag). We added
  a Breakdown/Budget segmented control. Decision needed: keep ours (a real app needs a
  way to switch) vs match the handoff. **Recommend keep** (it's a necessary control);
  optionally restyle. Not a bug.

### Currency — `currency.jpg`  → Cleanup B + C
- **P1 presentation:** pushed screen → should be a **blurred popup**.
- **P1 flags:** handoff rows show a **flag** + code + full name; ours has code + symbol
  + name, no flag.
- **P2 selected style + Done:** selected row is a filled **blue** row with a check;
  there's a **Done** button. Ours uses a plain checkmark, no Done.

### Set budget — `budget.jpg`  → Cleanup B + C
- **P1 presentation:** pushed → **blurred popup**.
- **P2 chrome:** handoff has a target-icon header, Total/By-category segmented (match),
  category rows with a **colored tile + a `$ ___` input field**, a **"Total monthly
  budget"** summary row, and **Save budget / Cancel** buttons. Ours has the modes +
  fields + footer total but as a pushed `List` without the tiles/field chrome/buttons.

### Manage categories — `category.jpg`  → Cleanup B + C
- **P1 presentation:** pushed → **blurred popup** with a close (×).
- **P2 rows:** handoff rows = colored tile + name + **`$X/mo` subtitle** + an inline
  **trash** button; a primary **"+ Add category"** button at the bottom. Ours is a
  pushed List with swipe-to-delete + a "+" toolbar.

### New/Add category — `add_category.jpg`  → Cleanup B + C
- **P1 presentation:** pushed `Form` → **blurred popup**.
- **P2 missing controls:** handoff has an **Icons/Emoji** toggle, a **custom color**
  wheel (beyond the 4 swatches), and a **"MONTHLY BUDGET · OPTIONAL"** field. Ours has
  name + icon grid + 4 swatches only (no emoji, no custom color, no budget field).

### Export to Google Sheets — `export_google_sheets.jpg`  → Cleanup B
- Layout matches our `ExportSheet` (title, WHAT GETS EXPORTED, This month/Date range,
  Export, Cancel). **P1: just the blurred background** (system sheet → blur).

### Report a bug — `report_bug.jpg`  → Cleanup B
- Layout matches our `BugReportSheet` (WHAT HAPPENED, dashed Add screenshot, Send,
  Cancel). **P1: blurred background.** Behavior: keep **native Mail compose** (the
  prototype's inline "Send" is non-functional; Mail is the only real no-server
  delivery). No behavior change recommended.

### Theme / Appearance — `light_and_dark_theme.jpg`  → Cleanup B
- Matches our `AppearanceSheet` (Light/Dark/Automatic cards + Done). **P1: blurred
  background** only.

---

## Cross-cutting decision (gates Cleanup B)
**Blur fidelity:** the handoff blurs the *background behind* the popup. A system
`.sheet` doesn't — it dims+scales the presenter. Faithful blur needs a **custom
bottom-popup presentation** (ZStack: dimmed/blurred backdrop + a bottom card). Options:
1. Build one reusable `BlurPopup` container and route all dialogs through it (faithful;
   bigger change; also converts the 3 pushed screens cleanly).
2. Keep system `.sheet` + `.presentationBackground(.ultraThinMaterial)` (quick; blurs
   the *sheet*, not the background — only partially matches).
Recommend **(1)** for fidelity. To discuss in the Cleanup B brainstorm.

---

## Proposed workstreams & order

| # | Workstream | Covers | Size |
|---|---|---|---|
| A | Settings restyle | tiles, groups, version footer | ✅ done (in review) |
| D | **Tab bar fidelity** | material color, safe-area padding, glyphs | small |
| B | **Dialog presentation** | reusable blurred bottom-popup; convert Currency/Budget/Categories/AddCategory from pushed; blur Theme/Export/Bug/Recurring | large |
| C | **Per-dialog restyle** | currency flags+Done+selected; budget tiles/fields/buttons; categories tiles/$mo/trash/Add; add-category emoji+custom-color+budget field | medium (per-dialog PRs) |
| E | Polish | net-total "$" prefix; Insights mode-toggle decision | small |

**Recommended order:** D (quick, high-visibility) → B (unlocks the popup look) → C
(restyle each now-popup dialog) → E. Each runs the normal brainstorm → spec → plan loop.

## Open decisions to resolve as we go
- **B:** faithful custom blur popup vs native sheet + presentationBackground.
- **Currency/Budget/Categories:** confirm pushed → popup (handoff says popup; on iOS,
  pushed is arguably nicer for the long Currency list — worth a deliberate call).
- **Insights:** keep our Breakdown/Budget toggle (recommend) vs match handoff.
- **Add-category scope:** add emoji toggle + custom color + monthly-budget field, or
  defer some.
