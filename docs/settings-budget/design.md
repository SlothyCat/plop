# Set Budget — Design

Status: Approved (brainstorm complete) · Date: 2026-06-15

Companion to `requirements.md`. Architecture, the persistence contract, the
Logic helpers, the view, currency reactivity, and testing.

## Architecture

```
plop/
  Logic/
    Budget.swift               (keys, BudgetMode, pure parse/format/sum helpers)
  Models/
    ExpenseCategory.swift       (existing `budget: Decimal` field — per-category store)
  Views/Settings/
    BudgetView.swift            (Total / By category, bound to @AppStorage + model)
    SettingsView.swift          (+ Set budget row showing the active total)
```

No new model, no Insights changes. One focused PR (no PR1/PR2 split — smaller
than the currency feature was).

## Persistence contract

This is the source of truth the Insights budget-mode feature will later read.

```
@AppStorage("budgetMode")    -> "general" | "category"   (default "category")
@AppStorage("generalBudget") -> Decimal-as-String        (default "")  // general-mode amount only
ExpenseCategory.budget       -> Decimal (0 = unset)       // per-category, already exists
```

- **Category-mode total is derived**, never stored: `categoryBudgetSum(categories)`.
- The two modes store independently — flipping the segmented control changes
  which is "active"; neither erases the other's data.
- `Decimal` is not `@AppStorage`-able, so `generalBudget` is stored as a string
  and parsed. No `Double` money — exact decimal precision is preserved.

## `Budget.swift`

```swift
import Foundation

let budgetModeKey = "budgetMode"
let generalBudgetKey = "generalBudget"

enum BudgetMode: String { case general, category }

/// Parses user text into a budget amount. Strips currency symbols / letters;
/// empty or unparseable -> 0 (meaning "no budget").
func parseBudgetAmount(_ text: String) -> Decimal {
    let filtered = text.filter { $0.isNumber || $0 == "." }
    return Decimal(string: filtered) ?? 0
}

/// Renders a stored amount back into the editable field (plain number, no symbol).
/// 0 -> "" so an unset budget shows the placeholder, not "0".
func formatBudgetAmount(_ value: Decimal) -> String {
    value == 0 ? "" : "\(value)"
}

/// Live "Total monthly budget" for By-category mode.
func categoryBudgetSum(_ categories: [ExpenseCategory]) -> Decimal {
    categories.reduce(0) { $0 + $1.budget }
}
```

Deferred to the Insights budget-mode feature (no consumer yet): period scaling
(year = monthly × 12) and per-category bar / `% used` math.

## `BudgetView.swift`

Pushed from Settings; mirrors `CurrencyView`'s shell (List, hidden scroll
background, `Palette.bg`, `.navigationTitle("Set budget")`).

- **Segmented toggle** `BudgetMode` bound to `@AppStorage(budgetModeKey)`
  ("Total" / "By category").
- **Total mode:** one large amount field, currency symbol prefix from
  `currencySymbol(currencyCode)`; bound to a `@State` string, parsed on save.
- **By category mode:** `@Query` categories; one row each (icon, name, amount
  field bound to a `@State [PersistentIdentifier: String]`); footer
  **"Total monthly budget"** = `formattedMoney(categoryBudgetSum(...))` recomputed
  live from the field values.
- **Save:**
  - general → `generalBudget = String` of parsed amount; `budgetMode = "general"`.
  - category → write each `category.budget = parseBudgetAmount(field)` via
    `modelContext`; `budgetMode = "category"`. Empty field -> 0 (no budget).
- Amount fields use `.keyboardType(.decimalPad)` and sanitize via
  `parseBudgetAmount` on commit.

### Settings row

```swift
NavigationLink {
    BudgetView()
} label: {
    HStack {
        Label("Set budget", systemImage: "chart.pie.fill")
        Spacer()
        Text(budgetSummary).foregroundStyle(.secondary)
    }
}
```

`budgetSummary` = the active total formatted via `formattedMoney(...)`:
general mode → the `generalBudget` amount; category mode →
`categoryBudgetSum(categories)`.

## Currency reactivity

`BudgetView` and the Settings row read `@AppStorage(currencyCodeKey)` and format
through `currencySymbol` / `formattedMoney`, so changing the Currency picker
updates symbols and decimal places here exactly like the money views.

## Testing

`BudgetTests` (XCTest, pure Logic — TDD):

- `parseBudgetAmount`: `""` → 0; `"12.50"` → 12.5; `"$1,200"`/letters stripped;
  garbage → 0.
- `formatBudgetAmount`: 0 → `""`; round-trips a non-zero Decimal.
- `categoryBudgetSum`: sums budgets; ignores 0 (unset); empty list → 0.
- `BudgetMode` raw values are `"general"` / `"category"`.

`BudgetView` is validated via `#Preview` + simulator (no view unit tests, per
convention). `main` must build; tests via `xcodebuild` iPhone 16; SwiftLint clean.
