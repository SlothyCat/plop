# Home + Entry — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-13 · Feature 1 of the app build.

## Purpose

Deliver the first usable slice of plop: a **Home** screen that lists transactions
with a period filter and net total, and an **Entry** screen to add/edit/delete a
transaction. This establishes the core data model, the app's routing skeleton, and
the add → list loop that every later feature builds on.

Design source of truth: `design_handoff_plop/README.md` and the prototype under
`design_handoff_plop/app/` (esp. `home.jsx`, `entry.jsx`, `store.jsx`, `theme.jsx`).

## In scope

- SwiftData model: `Transaction`, `Category`, supporting enums.
- Pure, unit-tested logic: period filtering, aggregation (net total, day-grouping),
  formatting (money, day labels).
- Centralized write path (`TransactionActions`) for add/update/delete.
- First-run seeding of a small default category set.
- App shell: custom tab bar with Home wired + **Insights/Settings as stub screens**,
  and a center "+" that opens Entry.
- Home screen: top filter, net-total header, day-grouped list, empty state.
- Entry screen: amount keypad, Expense/Income segment, category picker, note,
  date/time ("When") sheet, recurrence picker (stored but inert), save/delete.

## Out of scope (deferred to later features)

- **Recurrence engine** (auto-generating future transactions) → Feature 2. The
  `recurrence` field is captured now but does nothing yet.
- **Category management** (add/edit/delete categories) → Settings feature. Entry's
  "New category" affordance is hidden for now.
- **Currency picker** → Settings. We default to device locale currency.
- **Theme toggle / dark mode** → Settings. Build light theme first.
- Insights tab, Settings tab contents, Google Sheets export, modal dialogs.

## Key decisions (with rationale)

1. **Category is a SwiftData relationship**, not a denormalized name string.
   `Transaction.category: Category?`. Renames propagate; color/icon/budget live in
   one place. Delete rule = **nullify** → a removed category leaves the transaction
   as "Uncategorized" (matches the design's fallback).
2. **Amount stored as `Decimal`, always positive**; sign derived from `type`
   (income +, expense −). Never `Double` (floating-point corrupts money).
3. **Money formatting uses the device locale currency** (`Locale.current`), no FX
   conversion. The explicit picker comes with Settings.
4. **Category icon = SF Symbol name + color hex** for now; emoji + full icon picking
   arrive with category management. Model stays forward-compatible.
5. **Dates use real `Date` + locale `Calendar`** (no hardcoded "today"). Periods and
   day-grouping respect the user's week-start and timezone.
6. **First-run seeding is once-ever**, guarded by a persisted flag — NOT an
   "is the table empty?" check (so deleting all categories later never re-seeds).
7. **Logical decoupling, not network-style**: business logic lives in a pure,
   testable `Logic/` layer; views use `@Query`/`ModelContext` directly (idiomatic
   SwiftData). Writes funnel through `TransactionActions` (single locus of mutation)
   — a tasteful middle ground, not a full repository abstraction (YAGNI).
8. **Full routing skeleton now, screens stubbed.** Build the real tab bar with
   Insights/Settings placeholders so future features drop in with zero re-routing.

## Behavioral requirements & edge cases

- **Validation:** Save enabled only when `amount > 0`. Category optional (saves as
  Uncategorized). Note optional. Type defaults to Expense.
- **Keypad:** blocks a second decimal point; clamps fraction digits to the active
  currency's precision (0-decimal currencies like JPY accept no `.`); guards against
  layout-breaking digit counts.
- **Period filter:** Week / Month / Year, default **Month**, relative to now via the
  locale `Calendar`. Re-filters the list, the net total, and the period pill.
- **Grouping:** by local calendar day, newest day first; within a day newest time
  first, tiebroken by `createdAt`. Each day card shows a date label + day subtotal.
  Days are separated by the dated cards themselves (no hairline rule between groups).
- **Empty state:** "No transactions {period}." when the filtered list is empty.
- **Uncategorized:** `category == nil` renders as "Uncategorized" with a neutral tile.
- **Recurrence:** selecting an interval stores it and shows the repeat icon/chip; no
  generation occurs.

## Default seed categories

Starter set (icons/colors are touch-up-able post-implementation):

| Category | SF Symbol | Color |
|---|---|---|
| Food | `fork.knife` | `#FFEBCC` |
| Transport | `car.fill` | `#BFDDF0` |
| Shopping | `bag.fill` | `#8CC0EB` |
| Bills | `doc.text.fill` | `#FFF9D2` |
| Entertainment | `play.tv.fill` | `#BFDDF0` |

## Success criteria

- Launch on a fresh install → Home shows empty state + seeded categories available.
- Tap "+" → add an expense via keypad → it appears in Home, grouped by day, with the
  net total and period pill updated, no manual refresh.
- Tap a row → edit it or delete it; Home reflects the change.
- Switching Week/Month/Year re-filters list, total, and pill correctly.
- Net total math is correct for mixed income/expense.
- All pure logic + the write path + seeding are unit-tested (green in CI); views are
  validated via `#Preview` and the simulator.
