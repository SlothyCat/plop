# Set Budget — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-15

Lets the user set a monthly budget that Insights will later chart against. This
feature ships the **Settings side only**; the Insights **budget mode** (donut
spend-vs-budget, LEFT/OVER center, per-category bars) is a separate follow-up
that consumes the persistence contract defined here.

## User stories

- As a user, I can open Settings → Set budget and choose between a single
  **Total** monthly budget or **By category** budgets.
- In **Total** mode I enter one monthly amount.
- In **By category** mode I enter an amount per category; a footer shows the
  live **Total monthly budget** (the sum of the per-category amounts).
- My choice of mode and my amounts persist across launches.
- Amounts show the app's selected currency symbol and respect its decimal
  places (reactive to the Currency picker).

## In scope

- A pushed `BudgetView` from Settings (consistent with Currency / Manage
  categories — not a modal).
- Two modes: `general` (single total) and `category` (per-category, summed).
- Persistence: mode + general amount in `@AppStorage`; per-category amounts on
  the existing `ExpenseCategory.budget` SwiftData field.
- Pure, unit-tested Logic helpers for parsing, formatting, and summing budgets.
- A Settings row showing a short summary (the active budget total).

## Out of scope (deferred)

- **Insights budget mode** — the donut spend-vs-budget view, center LEFT/OVER,
  per-category progress bars, and `% used`. Follow-up feature; no consumer yet.
- **Period scaling** (year = monthly × 12) and per-category bar math — belong to
  the Insights feature; building them now would be speculative (YAGNI).
- Tapping Insights legend rows to edit budgets.
- Currency conversion (amounts are never converted — design constraint).

## Key decisions (with rationale)

1. **Settings-only scope.** Matches how `docs/roadmap.md` and
   `docs/insights/requirements.md` already split it: breakdown ships
   independent of budgets; budget mode is a follow-up "once Set budget exists."
2. **Both modes.** Per the design handoff; the active mode is what Insights will
   chart against, so supporting both now avoids rework later.
3. **Hybrid persistence.** Per-category budgets stay on the SwiftData model
   (the field already exists); the general amount + mode go in `@AppStorage` —
   mirrors Currency (`@AppStorage`) + Categories (SwiftData).
4. **Category total is derived, never stored.** The category-mode total is
   always `sum(category.budget)`; storing it too would create two sources of
   truth that can drift.
4a. **Modes are mutually exclusive, bridged by the sum.** Saving By category sets
   the general total to the category sum; saving Total clears all per-category
   budgets. Chosen over proportional rescaling (surprising, fractional) and over
   fully independent stores (the two could silently disagree).
5. **Pushed view, not a dialog.** The handoff calls it a "dialog," but the app's
   actual PREFERENCES rows (Currency, Manage categories) push — consistency wins.
