# Handoff: plop — Personal Finance Tracker (iOS)

## Overview
**plop** is a friendly personal-finance / expense-tracking app for iOS. The name evokes the *plop* of a coin dropping into water — coins into savings. The prototype is a fully-interactive iOS app mockup with four areas: **Home** (transaction list + period filter), **Insights** (animated donut chart of spend / budget), an **Entry** sheet (add/edit a transaction, incl. recurring intervals), and **Settings** (export, budget, categories, currency, theme, bug report).

This package briefs a developer (via Claude Code) to recreate the design in a real codebase.

## About the Design Files
The files in this bundle are **design references created in HTML/React-via-Babel** — prototypes that show the intended look, motion, and behavior. They are **not production code to copy directly**. The task is to **recreate these designs in the target codebase's environment** using its established patterns and libraries.

For a native iOS build, **SwiftUI** is the natural target (the prototype deliberately mimics iOS conventions: squircle icons, segmented controls, bottom sheets, grouped settings lists, 44pt hit targets). If the team prefers cross-platform, React Native / Expo also maps cleanly. If no codebase exists yet, choose the most appropriate of those.

The prototype runs inside a 393 × 852 px iPhone frame (logical points ≈ iPhone 15/16).

## Fidelity
**High-fidelity.** Final colors, typography, spacing, iconography, and interaction/motion are all specified. Recreate the UI pixel-faithfully using the target platform's native components, matching the tokens below. The HTML uses inline-SVG line icons (SF-Symbols-style); on iOS prefer **SF Symbols** equivalents.

---

## Brand & Logo

### Name
**plop** — always lowercase. Tone: simple, cute, calm.

### App Icon (chosen direction "D" — wordmark coin)
- **Concept:** the wordmark "plop" on a warm cream pool; the **"o" reads as a coin** that has just dropped, with two concentric **ripple** ellipses beneath the word.
- **Background:** vertical gradient, top `#FFE9C2` → bottom `#FFD98C`.
- **Wordmark in icon:** font *Baloo 2* 800, fill `#5C9FD8` (sky-deep blue), letter-spacing −1, centered.
- **Ripples:** two stroked ellipses, color `#E9B765`, centered ~74% down, opacities 0.5 / 0.8.
- **Shape:** iOS squircle; corner radius = 22.37% of the icon side. Final asset provided as `plop-icon.svg` (1024×1024, exported via squircle clip-path).
- Master file: `plop-icon.svg`. All four explored directions live in `Plop Logo.html` (A coin+ripples, B minimal, C splash, D wordmark coin — **D is final**).

### Wordmark (for headers / splash / marketing)
- *Baloo 2* 800, color `#5C9FD8`, with the **"o" tinted gold `#E7AE52`** to echo the coin. Letter-spacing −2 at large sizes.

---

## Design Tokens

### Color — brand accents (identical in light & dark)
| Token | Hex | Use |
|---|---|---|
| accent | `#8CC0EB` | primary sky-blue (buttons, active states, selected tiles) |
| accentSoft | `#BFDDF0` | secondary tile |
| cream | `#FFEBCC` | warm tile |
| yellow | `#FFF9D2` | pale tile |
| tileInk | `#2A2A2A` | charcoal glyph on fixed pastel/accent tiles (never inverts) |

Logo-specific golds (not in the app token set, used only in branding): coin/face cream `#FFE3B0`, ripple gold `#E9B765` / `#E7AE52`, icon-bg `#FFE9C2`→`#FFD98C`, deep sky `#5C9FD8`.

### Color — Light theme
| Token | Hex | Use |
|---|---|---|
| bg | `#DCEBF7` | app background (baby blue) |
| pageBg | `#C7DCEE` | backdrop behind device |
| card | `#FFFFFF` | cards / sheets |
| field | `#FCFDFE` | inputs / inset wells |
| ink | `#2A2A2A` | text & icons (charcoal) |
| ink60 | `rgba(42,42,42,0.55)` | secondary text |
| ink40 | `rgba(42,42,42,0.38)` | tertiary text / placeholders |
| ink12 | `rgba(42,42,42,0.10)` | borders |
| hair | `rgba(42,42,42,0.08)` | hairline dividers |
| scrim | `rgba(42,42,42,0.32)` | modal scrim |

### Color — Dark theme
| Token | Hex |
|---|---|
| bg | `#121922` |
| pageBg | `#070B10` |
| card | `#1C2530` |
| field | `#232E3A` |
| ink | `#EAF1F7` |
| ink60 | `rgba(234,241,247,0.62)` |
| ink40 | `rgba(234,241,247,0.40)` |
| ink12 | `rgba(234,241,247,0.14)` |
| hair | `rgba(234,241,247,0.10)` |
| scrim | `rgba(0,0,0,0.5)` |

Theme has three modes in Settings: **Light**, **Dark**, **Automatic** (follow system).

### Typography
- **App UI:** system font stack `-apple-system, "SF Pro Text", system-ui` → on iOS use **SF Pro**.
- **Brand/wordmark only:** **Baloo 2** (Google Fonts), weight 800.
- Scale seen in prototype: screen title 26/700; net-total figure large (~48–56) 700; row primary 16–17/600; row secondary 13–15/400–500; section labels 12–13/600 uppercase with letter-spacing; dialog title ~20/700.

### Spacing, radius, shadow
- Screen horizontal padding: 18–22px. Card/group radius: 14–22px. Dialog radius: 26px. Tile radius: 10–13px. Pills/toggles: 999px.
- Icon hit targets: 42px circular buttons; respect 44pt minimum.
- Card shadow (light): soft, low-opacity charcoal, e.g. `0 1px 2px rgba(42,42,42,0.05)`; elevated sheets `0 -12px 40px rgba(42,42,42,0.18)`.
- Bottom sheets slide up with `cubic-bezier(0.32,0.72,0,1)` ~340ms; scrim fades 240ms.

---

## Screens / Views

### 1. Home (tab 1)
- **Purpose:** review transactions; see net total for a chosen period.
- **Layout:** top bar (right-aligned **Filter** button only — search was intentionally removed). Centered **Net total** block: label + period pill ("this week/month/year") + large signed amount. Below, a scrollable list grouped by day; each group has a date subhead.
- **Filter:** tapping the filter icon opens a small dropdown menu **Week / Month / Year** (active row checked). Selecting re-filters the list **and** the net total, and updates the pill. Period math is relative to "today".
- **Transaction row (`TxRow`):** left = category color tile w/ icon (38px, radius 11); middle = category name (16–17/600) + optional **small repeat icon** if recurring + note/time secondary line; right = signed amount (income positive, expense negative), tabular-nums. Tap a row → opens Entry in edit mode.
- **Empty state:** centered "No transactions {period}." 

### 2. Insights (tab 2)
- **Purpose:** visualize spending split, or spend-vs-budget.
- **Two modes** (currently switched by a build tweak `insightsView`): **breakdown** (donut of spend split, center = total spent) and **budget** (donut of spend vs budget, center shows **LEFT** / **OVER** vs total budget).
- **Period toggle:** "This Month" / "This Year" segmented control. Year multiplies budgets by a constant; both periods derive spend from the **same transactions** as Home (expenses only; income excluded).
- **Donut (`Donut`):** 216px, stroke width 30, gap between arcs. Arcs start at 12 o'clock (top) and sweep **clockwise**. Center shows the total / remaining figure + a caption.
- **Donut ANIMATION (important — get this right):**
  - On every (re)mount — i.e. each time you land on Insights — and on every period/mode change, the ring **redraws from zero**.
  - Sequence: the empty track **fades in first** (~360ms). Then colored arcs draw **strictly one at a time** at **constant angular speed** (linear easing; per-arc duration ∝ arc fraction; total sweep ~1100ms). An arc must not begin until the previous arc has fully finished.
  - Each arc (incl. its round line-cap "dot") must be **fully invisible (opacity 0) during its delay** — otherwise small arcs flash a colored dot at their start position before their turn. Implemented via the Web Animations API with opacity baked into the first keyframe + `fill: both`.
  - No retract/reverse animation. Implementation reference: `Donut` in `app/insights.jsx`.
- **Legend rows:** per category — color dot, name, amount; in budget mode show `spent / budget`, a progress bar, and `% used` / `% · over`; rows with no budget show "Set budget". In **general** budget mode rows show `% of budget` against the single total.

### 3. Entry (full-screen sheet — add & edit)
- **Purpose:** create or edit a transaction.
- **Header:** Close (×) left; **Expense / Income** segmented control center; right side has the **Recurring** button and, when editing, a **Delete** button.
- **Amount:** large numeric display with currency symbol; custom keypad at the bottom (digits, decimal, backspace). 
- **Recurring:** circular button (repeat icon); active = accent fill. Tapping opens a **bottom sheet "Repeat"** with options **One-time / Daily / Weekly / Monthly / Yearly** (each row: icon tile, label, sub-caption, check when selected). When an interval is set, a chip "Repeats {interval}" shows under the amount; the choice saves on the transaction (`recurring` field) and persists.
- **Category:** selectable chips/grid from the live category store; pick one.
- **Note:** expandable note field. **Date/Time:** a "When" bottom sheet (`DateTimeSheet`) to set date + time.
- **Save:** confirm (check) key writes the transaction.

### 4. Settings (tab 3)
Grouped iOS list:
- **DATA** → *Export to Google Sheets*.
- **PREFERENCES** → *Set budget*, *Manage categories*, *Currency*, *Theme*. (Categories were intentionally moved here from DATA.)
  - **Set budget** dialog: segmented **Total** vs **By category**.
    - *Total:* one big monthly amount input (general budget; categories ignored).
    - *By category:* an amount field per category that **live-sums into a "Total monthly budget"** shown at the bottom. Saving writes each category's budget and the summed total. Persisted in `budget_v1` as `{ mode, total }` (+ per-category budgets on each category).
  - **Manage categories:** add / edit / delete categories (name, icon from a registry, color, optional budget).
  - **Currency:** picker; mutates a live `CUR` token (symbol, decimal places) used app-wide. Persisted `currency_v1`.
  - **Theme:** Light / Dark / Automatic.
- **Report a bug** dialog: description textarea + **image upload** (native file picker, `accept="image/*"`) labeled "SCREENSHOT · OPTIONAL" — dashed "Add screenshot" button → shows a real thumbnail, filename, "Replace", and a remove (×). **Not** an auto-capture. Send disabled until a description is entered.

### Tab bar
- Three tabs (Home, Insights, Settings) with a context-aware **center button**: on Home it's **Add** (opens Entry); on other tabs it returns **Home**.

---

## Interactions & Behavior
- **Navigation:** tab switches are instant; Insights replays its donut draw on every entry.
- **Filter dropdown:** outside-click closes; selecting updates list + total + pill.
- **Bottom sheets** (Repeat, When): scrim + slide-up `cubic-bezier(0.32,0.72,0,1)` ~340ms.
- **Toggles/segments:** thumb slides 200ms; selected segment gets card bg + subtle shadow.
- **Recurring chip** appears/updates from the selected interval; tapping it reopens the sheet.
- **Reduced motion:** the donut should render fully-drawn (fail-open) when animations are disabled — never leave arcs stuck invisible.

## State Management
- **transactions** (`txs`): array; each `{ id, catName, amount, type:'expense'|'income', note, date:'YYYY-MM-DD', time:'HH:MM', recurring:null|'daily'|'weekly'|'monthly'|'yearly', ts }`. Persisted (localStorage key `txs_v3` in the prototype). Home groups by `date`; Insights derives per-category spend for this month (`YYYY-MM`) and this year (`YYYY`), expenses only.
- **categories** (`cats`): `{ id, name, icon (registry key), color, budget (number|null) }`. Persisted.
- **budget**: `{ mode:'general'|'category', total }` persisted `budget_v1`; category mode also stores per-category `budget`.
- **currency**: code → live `CUR` token, persisted `currency_v1`.
- **theme**: mode Light/Dark/Automatic; `applyTheme(isDark)` mutates live token object `T`, then re-render.
- **Derived:** net total (signed sum over period), spend-by-period maps, budget totals/remaining.

## Design Tokens recap → see "Design Tokens" above (colors, type, spacing, radius, shadow).

## Assets
- `plop-icon.svg` — final app icon (direction D), 1024×1024, squircle-clipped. Ship iOS sizes from this.
- `Plop Logo.html` — all explored icon directions + wordmark + lockup (reference).
- Icons in-app are inline SVG line icons (SF-Symbols-style) defined in `app/icons.jsx` — map to **SF Symbols** on iOS.
- Fonts: **Baloo 2** (brand, Google Fonts) for logo/wordmark only; **SF Pro / system** for all UI.

## Files (in this bundle)
- `README.md` — this document (self-sufficient spec).
- `Expense Tracker.html` — entry point that mounts the full app prototype.
- `app/` — prototype source split by concern:
  - `app.jsx` (root: tabs, dialogs, store wiring), `home.jsx`, `insights.jsx` (incl. donut animation), `entry.jsx` (incl. recurring sheet), `settings.jsx`, `dialogs.jsx` (export, categories, set-budget, bug, theme, currency), `store.jsx` (categories, transactions, budget, currency hooks), `theme.jsx` (tokens), `icons.jsx` (icon set).
- `logo/Plop Logo.html` — logo explorations. `logo/plop-icon.svg` — final icon.

## How to run the reference
Open `Expense Tracker.html` in a browser. It pulls React + Babel from CDN and mounts the `app/*.jsx` files. Use it to observe exact spacing, color, and especially the **Insights donut motion**, which is hard to convey in static specs.
