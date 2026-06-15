# Insights Budget Mode — PR1 (Logic) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the pure budget-aggregation Logic that PR2's Insights budget-mode UI will render — no visible change yet.

**Architecture:** One new file `Logic/BudgetProgress.swift` with the period multiplier, a per-category progress row, a computed `BudgetSummary` view-model (general vs category flavours, year ×12), and a consumption-donut slice builder. All pure functions/structs, fully unit-tested. Reuses `CategorySpend`/`DonutSlice`/`totalSpent` from `SpendAggregation.swift` and `BudgetMode`/`parseBudgetAmount` from `Budget.swift`.

**Tech Stack:** Swift, Foundation, XCTest. iOS 18.

Single PR on branch `feature/insights-budget` (already rebased on `main`, which now contains the Set budget code).

---

## File structure

- **Create** `plop/plop/Logic/BudgetProgress.swift` — `periodBudgetMultiplier`, `CategoryBudgetProgress`, `BudgetSummary`, `budgetSummary(...)`, `budgetDonutSlices(...)`.
- **Create** `plop/plopTests/BudgetProgressTests.swift` — unit tests for all of the above.

> Refinement vs `design.md`: `BudgetSummary` carries an extra `donutRows` field (the slice source) alongside `rows` (the legend source). In the general flavour they're identical; in the category flavour `donutRows` is the budgeted subset. This keeps `budgetDonutSlices` a pure function of the summary (no need to pass `mode` again), matching the handoff's separate `donutSource`.

### Existing symbols this builds on (verified)

From `plop/plop/Logic/SpendAggregation.swift`:
```swift
let uncategorizedSpendID = "__uncategorized__"
struct CategorySpend: Identifiable, Equatable { let id: String; let name: String; let colorHex: String; let amount: Decimal }
func totalSpent(_ spend: [CategorySpend]) -> Decimal
struct DonutSlice: Identifiable, Equatable { let id: String; let colorHex: String; let start: Double; let end: Double }
```
From `plop/plop/Logic/Budget.swift`:
```swift
enum BudgetMode: String { case general, category }
func parseBudgetAmount(_ text: String) -> Decimal
```
From `plop/plop/Logic/PeriodFilter.swift`: `enum PeriodFilter { case week, month, year }`.
From `plop/plop/Models/ExpenseCategory.swift`: `ExpenseCategory` has `name: String`, `colorHex: String`, `budget: Decimal`.

### Test command (this repo)

```bash
# Just this class (fast while iterating):
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests/BudgetProgressTests -parallel-testing-enabled NO

# Whole suite:
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO
```

> SourceKit shows false "No such module 'XCTest'" / "Cannot find X in scope" for new same-module symbols. **xcodebuild is the source of truth** — trust `** TEST SUCCEEDED **`. (See `memory/xcode-build-sim-gotchas.md`.)

---

## Task 1: Period multiplier + CategoryBudgetProgress

**Files:**
- Create: `plop/plop/Logic/BudgetProgress.swift`
- Create: `plop/plopTests/BudgetProgressTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/BudgetProgressTests.swift`:

```swift
import XCTest
@testable import plop

final class BudgetProgressTests: XCTestCase {

    // MARK: periodBudgetMultiplier

    func test_multiplier_monthIsOne_yearIsTwelve() {
        XCTAssertEqual(periodBudgetMultiplier(.month), 1)
        XCTAssertEqual(periodBudgetMultiplier(.week), 1)
        XCTAssertEqual(periodBudgetMultiplier(.year), 12)
    }

    // MARK: CategoryBudgetProgress derived properties

    func test_progress_underBudget() {
        let row = CategoryBudgetProgress(id: "Food", name: "Food", colorHex: "#FFEBCC",
                                         spent: 75, budget: 100)
        XCTAssertTrue(row.hasBudget)
        XCTAssertFalse(row.isOver)
        XCTAssertEqual(row.fraction, 0.75, accuracy: 0.0001)
    }

    func test_progress_overBudget() {
        let row = CategoryBudgetProgress(id: "Rent", name: "Rent", colorHex: "#8CC0EB",
                                         spent: 120, budget: 100)
        XCTAssertTrue(row.isOver)
        XCTAssertEqual(row.fraction, 1.2, accuracy: 0.0001)
    }

    func test_progress_noBudget() {
        let row = CategoryBudgetProgress(id: "Subs", name: "Subs", colorHex: "#FFF9D2",
                                         spent: 30, budget: 0)
        XCTAssertFalse(row.hasBudget)
        XCTAssertFalse(row.isOver)
        XCTAssertEqual(row.fraction, 0, accuracy: 0.0001)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests/BudgetProgressTests -parallel-testing-enabled NO
```
Expected: BUILD FAILS — `periodBudgetMultiplier` and `CategoryBudgetProgress` are undefined.

- [ ] **Step 3: Write the implementation**

Create `plop/plop/Logic/BudgetProgress.swift`:

```swift
import Foundation

/// Monthly budgets scale by this for the period. Insights is month/year only;
/// anything that isn't a year stays monthly (×1).
func periodBudgetMultiplier(_ period: PeriodFilter) -> Int {
    period == .year ? 12 : 1
}

/// One legend row in budget mode: a category's spend against its (already scaled)
/// monthly budget. `budget == 0` means the category has no budget set.
struct CategoryBudgetProgress: Identifiable, Equatable {
    let id: String          // category name, or uncategorizedSpendID
    let name: String
    let colorHex: String
    let spent: Decimal
    let budget: Decimal     // already × period multiplier; 0 when unbudgeted

    var hasBudget: Bool { budget > 0 }
    var isOver: Bool { budget > 0 && spent > budget }

    /// Fraction of this row's budget consumed (0 when unbudgeted).
    var fraction: Double {
        guard budget > 0 else { return 0 }
        return NSDecimalNumber(decimal: spent).doubleValue
             / NSDecimalNumber(decimal: budget).doubleValue
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the Step 2 command. Expected: `** TEST SUCCEEDED **`, 3 tests green.

- [ ] **Step 5: Commit**

```bash
git add plop/plop/Logic/BudgetProgress.swift plop/plopTests/BudgetProgressTests.swift
git commit -m "Add budget period multiplier and progress row

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: BudgetSummary + builder

**Files:**
- Modify: `plop/plop/Logic/BudgetProgress.swift`
- Modify: `plop/plopTests/BudgetProgressTests.swift`

- [ ] **Step 1: Write the failing tests**

Append these tests inside `BudgetProgressTests` (before the closing brace):

```swift
    // MARK: budgetSummary — general flavour

    func test_summary_general_monthTotalsAndRows() {
        let spend = [
            CategorySpend(id: "Food", name: "Food", colorHex: "#FFEBCC", amount: 300),
            CategorySpend(id: "Subs", name: "Subs", colorHex: "#FFF9D2", amount: 120)
        ]
        let s = budgetSummary(spend: spend, categories: [], mode: .general,
                              generalBudget: "1000", period: .month)
        XCTAssertEqual(s.totalBudget, 1000)
        XCTAssertEqual(s.spentBudgeted, 420)
        XCTAssertEqual(s.remaining, 580)
        XCTAssertFalse(s.isOver)
        XCTAssertEqual(s.rows.count, 2)
        XCTAssertEqual(s.donutRows, s.rows)   // general: legend == donut source
    }

    func test_summary_general_yearScalesBudget() {
        let s = budgetSummary(spend: [], categories: [], mode: .general,
                              generalBudget: "1000", period: .year)
        XCTAssertEqual(s.totalBudget, 12000)
    }

    // MARK: budgetSummary — category flavour

    func test_summary_category_totalsOverBudgetedOnly() {
        let cats = [
            ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC", budget: 400),
            ExpenseCategory(name: "Rent", symbolName: "house", colorHex: "#8CC0EB", budget: 600),
            ExpenseCategory(name: "Subs", symbolName: "tv", colorHex: "#FFF9D2", budget: 0)
        ]
        let spend = [
            CategorySpend(id: "Rent", name: "Rent", colorHex: "#8CC0EB", amount: 700),
            CategorySpend(id: "Food", name: "Food", colorHex: "#FFEBCC", amount: 300)
        ]
        let s = budgetSummary(spend: spend, categories: cats, mode: .category,
                              generalBudget: "9999", period: .month)
        XCTAssertEqual(s.totalBudget, 1000)        // 400 + 600 (Subs has none)
        XCTAssertEqual(s.spentBudgeted, 1000)      // 700 + 300
        XCTAssertEqual(s.remaining, 0)
        XCTAssertEqual(s.rows.count, 3)            // all categories appear in the legend
        XCTAssertEqual(s.rows.first?.name, "Rent") // sorted by spent desc
        XCTAssertEqual(s.donutRows.count, 2)       // only budgeted categories
        XCTAssertFalse(s.rows.first(where: { $0.name == "Subs" })!.hasBudget)
    }

    func test_summary_category_yearScalesEachBudget() {
        let cats = [
            ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC", budget: 400)
        ]
        let s = budgetSummary(spend: [], categories: cats, mode: .category,
                              generalBudget: "0", period: .year)
        XCTAssertEqual(s.totalBudget, 4800)        // 400 × 12
    }

    func test_summary_category_omitsUncategorizedSpend() {
        let cats = [
            ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC", budget: 400)
        ]
        let spend = [
            CategorySpend(id: "Food", name: "Food", colorHex: "#FFEBCC", amount: 300),
            CategorySpend(id: uncategorizedSpendID, name: "Uncategorized",
                          colorHex: "#C9CDD2", amount: 999)
        ]
        let s = budgetSummary(spend: spend, categories: cats, mode: .category,
                              generalBudget: "0", period: .month)
        XCTAssertEqual(s.rows.count, 1)            // only the real category
        XCTAssertEqual(s.spentBudgeted, 300)       // uncategorized excluded
    }

    func test_summary_isOver_whenSpentExceedsBudget() {
        let s = budgetSummary(
            spend: [CategorySpend(id: "Food", name: "Food", colorHex: "#FFEBCC", amount: 150)],
            categories: [], mode: .general, generalBudget: "100", period: .month)
        XCTAssertEqual(s.remaining, -50)
        XCTAssertTrue(s.isOver)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the Task 1 Step 2 command. Expected: BUILD FAILS — `budgetSummary` and `BudgetSummary` are undefined.

- [ ] **Step 3: Write the implementation**

Append to `plop/plop/Logic/BudgetProgress.swift`:

```swift
/// The fully-computed budget view-model for a period and flavour.
struct BudgetSummary: Equatable {
    let rows: [CategoryBudgetProgress]        // legend rows
    let donutRows: [CategoryBudgetProgress]   // rows that draw donut arcs
    let totalBudget: Decimal
    let spentBudgeted: Decimal

    var remaining: Decimal { totalBudget - spentBudgeted }
    var isOver: Bool { remaining < 0 }
}

/// Assembles the budget summary from spend + categories for the active flavour.
/// - general: rows = all spend; totalBudget = generalBudget × mult; spentBudgeted = total spent.
/// - category: rows = all categories (each with its spend), sorted by spend desc;
///   donutRows = the budgeted subset; totalBudget = Σ budgeted; spentBudgeted = Σ
///   spent of budgeted. Uncategorized spend is omitted (no category to budget).
func budgetSummary(spend: [CategorySpend],
                   categories: [ExpenseCategory],
                   mode: BudgetMode,
                   generalBudget: String,
                   period: PeriodFilter) -> BudgetSummary {
    let mult = Decimal(periodBudgetMultiplier(period))

    switch mode {
    case .general:
        let rows = spend.map {
            CategoryBudgetProgress(id: $0.id, name: $0.name, colorHex: $0.colorHex,
                                   spent: $0.amount, budget: 0)
        }
        return BudgetSummary(rows: rows, donutRows: rows,
                             totalBudget: parseBudgetAmount(generalBudget) * mult,
                             spentBudgeted: totalSpent(spend))

    case .category:
        let spentByName = Dictionary(uniqueKeysWithValues:
            spend.filter { $0.id != uncategorizedSpendID }.map { ($0.name, $0.amount) })

        var rows = categories.map { cat in
            CategoryBudgetProgress(id: cat.name, name: cat.name, colorHex: cat.colorHex,
                                   spent: spentByName[cat.name] ?? 0,
                                   budget: cat.budget * mult)
        }
        rows.sort { $0.spent != $1.spent ? $0.spent > $1.spent : $0.name < $1.name }

        let donutRows = rows.filter { $0.hasBudget }
        return BudgetSummary(
            rows: rows,
            donutRows: donutRows,
            totalBudget: donutRows.reduce(Decimal(0)) { $0 + $1.budget },
            spentBudgeted: donutRows.reduce(Decimal(0)) { $0 + $1.spent })
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the Task 1 Step 2 command. Expected: `** TEST SUCCEEDED **`, all summary tests green.

- [ ] **Step 5: Commit**

```bash
git add plop/plop/Logic/BudgetProgress.swift plop/plopTests/BudgetProgressTests.swift
git commit -m "Add BudgetSummary and per-period budget builder

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Consumption donut slices

**Files:**
- Modify: `plop/plop/Logic/BudgetProgress.swift`
- Modify: `plop/plopTests/BudgetProgressTests.swift`

- [ ] **Step 1: Write the failing tests**

Append these tests inside `BudgetProgressTests` (before the closing brace):

```swift
    // MARK: budgetDonutSlices

    private func generalSummary(spentAmounts: [(String, Decimal)],
                                total: Decimal) -> BudgetSummary {
        let rows = spentAmounts.map {
            CategoryBudgetProgress(id: $0.0, name: $0.0, colorHex: "#FFEBCC",
                                   spent: $0.1, budget: 0)
        }
        return BudgetSummary(rows: rows, donutRows: rows,
                             totalBudget: total, spentBudgeted: totalSpentOf(rows))
    }

    private func totalSpentOf(_ rows: [CategoryBudgetProgress]) -> Decimal {
        rows.reduce(Decimal(0)) { $0 + $1.spent }
    }

    func test_donut_underBudget_fillsPartially() {
        let s = generalSummary(spentAmounts: [("Food", 300)], total: 1000)
        let slices = budgetDonutSlices(s, gap: 0)
        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices[0].end, 0.3, accuracy: 0.0001)   // 300 / 1000
    }

    func test_donut_overBudget_clampsToFullRing() {
        let s = generalSummary(spentAmounts: [("Food", 1500)], total: 1000)
        let slices = budgetDonutSlices(s, gap: 0)
        XCTAssertEqual(slices[0].end, 1.0, accuracy: 0.0001)   // clamped
    }

    func test_donut_emptyWhenNoBudget() {
        let s = generalSummary(spentAmounts: [("Food", 300)], total: 0)
        XCTAssertTrue(budgetDonutSlices(s).isEmpty)
    }

    func test_donut_multipleSlicesAreCumulative() {
        let s = generalSummary(spentAmounts: [("Food", 200), ("Subs", 300)], total: 1000)
        let slices = budgetDonutSlices(s, gap: 0)
        XCTAssertEqual(slices.count, 2)
        XCTAssertEqual(slices[0].end, 0.2, accuracy: 0.0001)
        XCTAssertEqual(slices[1].start, 0.2, accuracy: 0.0001)
        XCTAssertEqual(slices[1].end, 0.5, accuracy: 0.0001)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the Task 1 Step 2 command. Expected: BUILD FAILS — `budgetDonutSlices` is undefined.

- [ ] **Step 3: Write the implementation**

Append to `plop/plop/Logic/BudgetProgress.swift`:

```swift
/// Donut slices for budget mode: each `donutRows` entry's spent ÷ totalBudget,
/// cumulative, clamped to [0, 1] so an over-budget ring fills to a full circle
/// (over-ness is shown by the center caption, not by overflowing arcs).
/// Empty when totalBudget == 0.
func budgetDonutSlices(_ summary: BudgetSummary, gap: Double = 0.012) -> [DonutSlice] {
    let total = summary.totalBudget
    guard total > 0 else { return [] }
    let totalDouble = NSDecimalNumber(decimal: total).doubleValue

    var cursor = 0.0
    var slices: [DonutSlice] = []
    for row in summary.donutRows {
        let frac = NSDecimalNumber(decimal: row.spent).doubleValue / totalDouble
        let start = min(cursor + gap / 2, 1.0)
        let end = min(max(start, cursor + frac - gap / 2), 1.0)
        slices.append(DonutSlice(id: row.id, colorHex: row.colorHex, start: start, end: end))
        cursor += frac
    }
    return slices
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the Task 1 Step 2 command. Expected: `** TEST SUCCEEDED **`, all donut tests green.

- [ ] **Step 5: Commit**

```bash
git add plop/plop/Logic/BudgetProgress.swift plop/plopTests/BudgetProgressTests.swift
git commit -m "Add consumption-donut slice builder for budget mode

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Verify and open PR

**Files:** none (verification + PR).

- [ ] **Step 1: Run the full test suite**

```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO
```
Expected: `** TEST SUCCEEDED **` — all prior tests plus the new `BudgetProgressTests`.

- [ ] **Step 2: Lint**

```bash
swiftlint lint
```
Expected: no new violations from `BudgetProgress.swift` / `BudgetProgressTests.swift` (a pre-existing baseline of unrelated violations is acceptable).

- [ ] **Step 3: Push and open the PR**

```bash
git push -u origin feature/insights-budget
```

`gh` is not installed — open the PR via the printed GitHub web URL. Use the project PR-description format:

```markdown
## Summary
Add pure budget-aggregation Logic for Insights budget mode: period multiplier
(year ×12), per-category progress rows, a BudgetSummary (general/category
flavours), and consumption-donut slices. No UI yet — sets up PR2.

## Testing
All unit tests pass (N new in BudgetProgressTests); SwiftLint clean.
```
(Replace `N` with the actual count of new tests.)

---

## Self-review notes

- **Spec coverage (PR1 scope):** multiplier (Task 1), `CategoryBudgetProgress` with `fraction`/`isOver`/`hasBudget` (Task 1), `BudgetSummary` + general/category builder incl. year ×12 and uncategorized-omission (Task 2), `budgetDonutSlices` with over-clamp + empty (Task 3). PR2 UI items intentionally absent.
- **Type consistency:** `CategoryBudgetProgress(id:name:colorHex:spent:budget:)` and `BudgetSummary(rows:donutRows:totalBudget:spentBudgeted:)` initializers used identically across source and tests; `budgetSummary`/`budgetDonutSlices`/`periodBudgetMultiplier` signatures match every call site. Reused symbols (`CategorySpend`, `DonutSlice`, `totalSpent`, `uncategorizedSpendID`, `BudgetMode`, `parseBudgetAmount`, `PeriodFilter`, `ExpenseCategory`) match their existing definitions.
- **No placeholders:** every code step is complete and runnable.
- **Note for PR2:** `BudgetSummary.donutRows` is the slice source; the legend renders `rows`. PR2 computes per-row `% used`/`% of budget` at the view layer (general → spent ÷ totalBudget; category → row.fraction).
