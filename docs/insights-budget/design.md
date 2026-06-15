# Insights Budget Mode — Design

Status: Approved (brainstorm complete) · Date: 2026-06-15

Companion to `requirements.md`. Architecture, the aggregation Logic (PR1), the UI
(PR2), the consumption donut, tap-to-edit, edge states, testing, and slicing.

## Architecture

```
plop/
  Logic/
    BudgetProgress.swift        (PR1: pure budget aggregation — multiplier, rows, totals, donut)
    SpendAggregation.swift      (existing: spendByCategory, donutSlices — reused)
    Budget.swift                (existing: parseBudgetAmount, keys, BudgetMode — reused)
  Views/Insights/
    InsightsContainer.swift     (PR2: + @Query categories, read budget @AppStorage, pass down)
    InsightsView.swift          (PR2: + mode toggle, branch donut/center/subhead/legend)
    BudgetLegend.swift          (PR2: budget-mode legend rows + bars; tappable)
    CategoryBudgetSheet.swift   (PR2: inline single-category budget editor)
    DonutChart.swift            (existing: reused with budget slices + budget center)
```

Two PRs: **PR1** = `BudgetProgress.swift` + tests (no visible change). **PR2** =
all the Views work.

## PR1 — `BudgetProgress.swift` (pure, tested)

```swift
import Foundation

/// Monthly budgets scale by this for the period. Insights is month/year only.
func periodBudgetMultiplier(_ period: PeriodFilter) -> Int {
    period == .year ? 12 : 1
}

/// One legend row in budget mode: a category's spend against its (scaled) budget.
struct CategoryBudgetProgress: Identifiable, Equatable {
    let id: String          // category name, or uncategorizedSpendID
    let name: String
    let colorHex: String
    let spent: Decimal
    let budget: Decimal     // already × multiplier; 0 when unbudgeted
    var hasBudget: Bool { budget > 0 }
    var isOver: Bool { budget > 0 && spent > budget }
    /// Fraction of this row's budget consumed (0 when unbudgeted).
    var fraction: Double {
        guard budget > 0 else { return 0 }
        return NSDecimalNumber(decimal: spent).doubleValue
             / NSDecimalNumber(decimal: budget).doubleValue
    }
}

/// The fully-computed budget view-model for a period.
struct BudgetSummary: Equatable {
    let rows: [CategoryBudgetProgress]
    let totalBudget: Decimal
    let spentBudgeted: Decimal
    var remaining: Decimal { totalBudget - spentBudgeted }
    var isOver: Bool { remaining < 0 }
}
```

Builder (signature; body specified in the plan):

```swift
/// Assembles the budget summary from spend + categories for the active flavour.
/// - general: rows = all spend; totalBudget = generalBudget × mult; spentBudgeted = total spent.
/// - category: rows = all categories (each with its spend); budgeted ones show
///   progress, unbudgeted render as "Set budget"; totalBudget = Σ budgeted;
///   spentBudgeted = Σ spent of budgeted. Uncategorized spend is omitted (it has
///   no category to budget).
func budgetSummary(spend: [CategorySpend],
                   categories: [ExpenseCategory],
                   mode: BudgetMode,
                   generalBudget: String,
                   period: PeriodFilter) -> BudgetSummary
```

Consumption donut — arcs are spend as a fraction of `totalBudget`, cumulative,
clamped so an over-budget ring fills to a full circle (over-ness is shown by the
center, not by overflowing arcs):

```swift
/// Donut slices for budget mode: each contributing row's spent ÷ totalBudget,
/// cumulative, clamped to [0, 1]. Empty when totalBudget == 0.
func budgetDonutSlices(_ summary: BudgetSummary, gap: Double = 0.012) -> [DonutSlice]
```

> Reuse `DonutSlice` / `Color(hex:)` / the existing `DonutChart`. Breakdown mode
> keeps calling `spendByCategory` + `donutSlices` unchanged.

## PR2 — UI

### `InsightsContainer.swift`
Add `@Query(sort: \ExpenseCategory.name) private var categories` and the budget
`@AppStorage` reads (`budgetModeKey`, `generalBudgetKey`); pass `categories`,
`budgetMode`, `generalBudget` into `InsightsView` alongside `transactions`.

### `InsightsView.swift`
- New `@State private var mode: InsightsMode = .breakdown` (`enum InsightsMode { case breakdown, budget }`).
- Full-width segmented `Breakdown | Budget` under the header.
- **Breakdown branch:** existing donut + `SpendLegend` (unchanged).
- **Budget branch:** compute `budgetSummary(...)`; feed `budgetDonutSlices` +
  a center showing `formattedMoney(abs(remaining))`, caption `LEFT`/`OVER`,
  sub `of {totalBudget}`; subhead `{spent} spent of {total} budget`; then
  `BudgetLegend(summary:)`.
- Donut `animationKey` includes the mode + period + flavour so it replays on any
  switch (matches existing replay behavior).

### `BudgetLegend.swift`
Row per `CategoryBudgetProgress`: color dot, name; right side `spent / budget`
(or just `spent` in general flavour) and the `% used` / `% · over` / `Set budget`
caption; a `BudgetBar` (progress, charcoal when over). Rows are `Button`s that
open `CategoryBudgetSheet` for that category (category flavour only; general rows
are not tappable). Reads `@AppStorage(currencyCodeKey)` for formatting.

### `CategoryBudgetSheet.swift`
A small sheet: category header, one amount field (currency symbol prefix,
`.decimalPad`), Save / Cancel. Save writes `cat.budget = parseBudgetAmount(field)`
via `modelContext`. Empty = 0 (clears the budget). Mirrors `BudgetView`'s field.

### Empty state
Budget mode with `totalBudget == 0`: faint empty ring + "Set a budget to track
your progress." In category flavour the legend still lists tappable "Set budget"
rows; in general flavour the prompt notes budgets are set in Settings.

## Currency reactivity
All money renders through `formattedMoney` / `currencySymbol` reading
`@AppStorage(currencyCodeKey)`, so the Currency picker updates Insights too.

## Testing

PR1 — `BudgetProgressTests` (XCTest, TDD):
- `periodBudgetMultiplier`: month → 1, year → 12.
- `budgetSummary` general: totalBudget = amount × mult; spentBudgeted = total spent.
- `budgetSummary` category: totals over budgeted only; unbudgeted-with-spend rows
  present with `hasBudget == false`; year ×12 applied.
- `CategoryBudgetProgress`: `fraction`, `isOver`, `hasBudget` (incl. budget 0).
- `remaining` / `isOver` (under, exact, over).
- `budgetDonutSlices`: fractions vs totalBudget; clamps when over; empty when
  totalBudget == 0.

PR2 — views via `#Preview` + simulator (breakdown/budget × month/year, over,
no-budget, general vs category). No view unit tests, per convention.

## Slicing summary
- **PR1** `feature/insights-budget-logic`: `BudgetProgress.swift` + tests.
- **PR2** `feature/insights-budget-ui`: container/view wiring, toggle, budget
  donut + center + subhead, `BudgetLegend`, `CategoryBudgetSheet`, empty state.
