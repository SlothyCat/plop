# Export PR2 — SheetBuilder + ExportRange Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the pure transformation that turns local transactions + budgets into per-month spreadsheet value matrices (summary + budget + category breakdown + transaction rows), plus the range selector — no networking, no UI.

**Architecture:** Two pure files in `Logic/Export/`: `ExportRange` (which transactions/months a run covers) and `SheetBuilder` (`[Transaction]` → `[MonthSheet]`, each a `yyyy-MM` tab title + a 2-D `[[String]]` of cells). Reuses `PeriodFilter`, `activeBudgetTotal`, `TransactionType`, `ExpenseCategory`. Fully unit-tested with a fixed UTC calendar for determinism.

**Tech Stack:** Swift, Foundation, XCTest. iOS 18.

Branch: `feature/export-sheetbuilder`, off `feature/export` once PR1 merges (rebase onto `main` after). If PR1 is unmerged, branch off `feature/export` so PKCE/config are present (harmless here).

---

## File structure

- **Create** `plop/plop/Logic/Export/ExportRange.swift` — the range enum + `contains`.
- **Create** `plop/plop/Logic/Export/SheetBuilder.swift` — `MonthSheet` + `buildExportSheets` + private matrix/format helpers.
- **Create** `plop/plopTests/ExportRangeTests.swift`
- **Create** `plop/plopTests/SheetBuilderTests.swift`

### Verified existing symbols this builds on

- `PeriodFilter.month.range(containing:calendar:) -> ClosedRange<Date>` (`Logic/PeriodFilter.swift`).
- `activeBudgetTotal(mode:generalBudget:categories:) -> Decimal` and `BudgetMode` (`Logic/Budget.swift`).
- `TransactionType` (`.expense` / `.income`), `Transaction` (`amount: Decimal`, `type`, `date`, `note`, `createdAt`, `category: ExpenseCategory?`), `ExpenseCategory` (`name`, `budget: Decimal`).

### Test / build commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests/ExportRangeTests -only-testing:plopTests/SheetBuilderTests -parallel-testing-enabled NO 2>&1 | tail -25

swiftlint lint
```

> SourceKit false positives ("No such module 'XCTest'", "Cannot find X") are
> expected for new files — the xcodebuild run is the source of truth. Lines ≤ 120.

---

## Task 1: ExportRange

**Files:**
- Create: `plop/plop/Logic/Export/ExportRange.swift`
- Create: `plop/plopTests/ExportRangeTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/ExportRangeTests.swift`:

```swift
import XCTest
@testable import plop

final class ExportRangeTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    func test_thisMonth_includesSameMonthExcludesOthers() {
        let now = date(2026, 6, 15)
        let r = ExportRange.thisMonth
        XCTAssertTrue(r.contains(date(2026, 6, 1), now: now, calendar: utc))
        XCTAssertTrue(r.contains(date(2026, 6, 30), now: now, calendar: utc))
        XCTAssertFalse(r.contains(date(2026, 5, 31), now: now, calendar: utc))
        XCTAssertFalse(r.contains(date(2026, 7, 1), now: now, calendar: utc))
    }

    func test_dateRange_inclusiveBounds() {
        let r = ExportRange.dateRange(date(2026, 3, 1)...date(2026, 4, 30))
        let now = date(2026, 6, 15)
        XCTAssertTrue(r.contains(date(2026, 3, 1), now: now, calendar: utc))
        XCTAssertTrue(r.contains(date(2026, 4, 30), now: now, calendar: utc))
        XCTAssertFalse(r.contains(date(2026, 2, 28), now: now, calendar: utc))
        XCTAssertFalse(r.contains(date(2026, 5, 1), now: now, calendar: utc))
    }
}
```

- [ ] **Step 2: Run the tests — confirm they FAIL to build** (`ExportRange` undefined).

Run the test command (above).

- [ ] **Step 3: Implement**

Create `plop/plop/Logic/Export/ExportRange.swift`:

```swift
import Foundation

/// Which transactions an export run covers.
enum ExportRange: Equatable {
    case thisMonth
    case dateRange(ClosedRange<Date>)

    /// True if `date` falls in the range. `now`/`calendar` resolve `.thisMonth`.
    func contains(_ date: Date, now: Date, calendar: Calendar) -> Bool {
        switch self {
        case .thisMonth:
            return PeriodFilter.month.range(containing: now, calendar: calendar).contains(date)
        case .dateRange(let range):
            return range.contains(date)
        }
    }
}
```

- [ ] **Step 4: Run the tests — confirm PASS.**

- [ ] **Step 5: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Logic/Export/ExportRange.swift plop/plopTests/ExportRangeTests.swift
git commit -m "Add ExportRange selector and tests

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: SheetBuilder

**Files:**
- Create: `plop/plop/Logic/Export/SheetBuilder.swift`
- Create: `plop/plopTests/SheetBuilderTests.swift`

### Output layout (one month tab), exact row order

```
[ "<Month Year>" ]                         e.g. "June 2026"
[ "Total expense", "<num>" ]
[ "Total income",  "<num>" ]
[ "Net",           "<num>" ]               income − expense
[ "Total budget",  "<num>" ]               activeBudgetTotal(...)
[ "Budget left",   "<num>" ]               totalBudget − totalExpense
[ ]                                        blank row
[ "Spending by category" ]
[ "Category", "Spent", "Budget", "Left" ]
[ "<name>", "<spent>", "<budget|>", "<left|>" ]   one per category w/ expense; budget/left
                                                  blank when the category has no budget
[ ]                                        blank row
[ "Transactions" ]
[ "Date", "Category", "Note", "Type", "Amount (<CUR>)" ]
[ "<yyyy-MM-dd>", "<category>", "<note>", "Expense|Income", "<num>" ]   newest first
```

Numbers are RAW (no symbol, e.g. `"12.5"`, `"700"`) so Sheets can SUM. Dates are
`yyyy-MM-dd`. Category breakdown is **expenses only**, largest first (ties by name);
uncategorized expenses appear as "Uncategorized" (no budget). Transactions list
includes both expense and income, newest date first (tie: newer `createdAt`).

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/SheetBuilderTests.swift`:

```swift
import XCTest
@testable import plop

final class SheetBuilderTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }
    private func cat(_ name: String, budget: Decimal = 0) -> ExpenseCategory {
        ExpenseCategory(name: name, symbolName: "tag", colorHex: "#FFEBCC", budget: budget)
    }
    private func tx(_ amount: Decimal, _ type: TransactionType, _ date: Date,
                    note: String = "", category: ExpenseCategory? = nil) -> Transaction {
        Transaction(amount: amount, type: type, date: date, note: note, category: category)
    }

    private func build(_ txs: [Transaction], _ cats: [ExpenseCategory],
                       range: ExportRange = .dateRange(Date.distantPast...Date.distantFuture))
        -> [MonthSheet] {
        buildExportSheets(transactions: txs, categories: cats, range: range,
                          budgetMode: .category, generalBudget: "",
                          currencyCode: "USD", now: day(2026, 6, 15), calendar: utc)
    }

    func test_groupsByYearMonth_sortedWithTabTitles() {
        let food = cat("Food", budget: 400)
        let sheets = build([
            tx(10, .expense, day(2026, 5, 3), category: food),
            tx(20, .expense, day(2026, 6, 4), category: food),
            tx(30, .expense, day(2025, 12, 1), category: food)
        ], [food])
        XCTAssertEqual(sheets.map(\.tabTitle), ["2025-12", "2026-05", "2026-06"])
    }

    func test_monthSummary_totalsAndNet() {
        let food = cat("Food", budget: 400)
        let sheets = build([
            tx(100, .expense, day(2026, 6, 4), category: food),
            tx(300, .income, day(2026, 6, 5))
        ], [food])
        let june = sheets.first { $0.tabTitle == "2026-06" }!
        XCTAssertEqual(june.values[0], ["June 2026"])
        XCTAssertEqual(june.values[1], ["Total expense", "100"])
        XCTAssertEqual(june.values[2], ["Total income", "300"])
        XCTAssertEqual(june.values[3], ["Net", "200"])
        XCTAssertEqual(june.values[4], ["Total budget", "400"])
        XCTAssertEqual(june.values[5], ["Budget left", "300"])
    }

    func test_categoryBlock_budgetBlankWhenUnset_sortedDesc() {
        let food = cat("Food", budget: 400)
        let coffee = cat("Coffee")    // no budget
        let sheets = build([
            tx(120, .expense, day(2026, 6, 4), category: food),
            tx(50, .expense, day(2026, 6, 6), category: coffee)
        ], [food, coffee])
        let v = sheets[0].values
        let header = v.firstIndex(of: ["Category", "Spent", "Budget", "Left"])!
        XCTAssertEqual(v[header + 1], ["Food", "120", "400", "280"])
        XCTAssertEqual(v[header + 2], ["Coffee", "50", "", ""])
    }

    func test_transactionRows_isoDateTypeAndCurrencyHeader() {
        let food = cat("Food", budget: 400)
        let sheets = build([tx(12.5, .expense, day(2026, 6, 4), note: "Lunch", category: food)], [food])
        let v = sheets[0].values
        let h = v.firstIndex(of: ["Date", "Category", "Note", "Type", "Amount (USD)"])!
        XCTAssertEqual(v[h + 1], ["2026-06-04", "Food", "Lunch", "Expense", "12.5"])
    }

    func test_uncategorizedExpense_labelled() {
        let sheets = build([tx(9, .expense, day(2026, 6, 4))], [])
        let v = sheets[0].values
        XCTAssertTrue(v.contains(["Uncategorized", "9", "", ""]))
    }

    func test_rangeFiltersOutOfRange() {
        let food = cat("Food", budget: 400)
        let sheets = build([
            tx(10, .expense, day(2026, 6, 4), category: food),
            tx(99, .expense, day(2026, 1, 4), category: food)
        ], [food], range: .thisMonth)   // now = 2026-06-15
        XCTAssertEqual(sheets.map(\.tabTitle), ["2026-06"])
    }
}
```

- [ ] **Step 2: Run the tests — confirm they FAIL to build** (`MonthSheet` / `buildExportSheets` undefined).

- [ ] **Step 3: Implement**

Create `plop/plop/Logic/Export/SheetBuilder.swift`:

```swift
import Foundation

/// One month's tab: a `yyyy-MM` title and a 2-D array of cell strings.
struct MonthSheet: Equatable {
    let year: Int
    let month: Int
    let values: [[String]]

    var tabTitle: String { String(format: "%04d-%02d", year, month) }
}

/// Transactions (filtered by `range`) → one `MonthSheet` per month with data,
/// sorted oldest-first. Pure; `now`/`calendar` resolve the range and date strings.
func buildExportSheets(transactions: [Transaction],
                       categories: [ExpenseCategory],
                       range: ExportRange,
                       budgetMode: BudgetMode,
                       generalBudget: String,
                       currencyCode: String,
                       now: Date = .now,
                       calendar: Calendar = .current) -> [MonthSheet] {
    let inRange = transactions.filter { range.contains($0.date, now: now, calendar: calendar) }

    var groups: [DateComponents: [Transaction]] = [:]
    for tx in inRange {
        let key = calendar.dateComponents([.year, .month], from: tx.date)
        groups[key, default: []].append(tx)
    }

    let totalBudget = activeBudgetTotal(mode: budgetMode, generalBudget: generalBudget,
                                        categories: categories)
    let budgetByName = Dictionary(categories.map { ($0.name, $0.budget) },
                                  uniquingKeysWith: { a, _ in a })

    return groups.keys
        .sorted { ($0.year!, $0.month!) < ($1.year!, $1.month!) }
        .map { key in
            let year = key.year!, month = key.month!
            return MonthSheet(year: year, month: month,
                              values: monthMatrix(monthTxs: groups[key]!, year: year, month: month,
                                                  budgetByName: budgetByName, totalBudget: totalBudget,
                                                  currencyCode: currencyCode, calendar: calendar))
        }
}

// MARK: - matrix

private func monthMatrix(monthTxs: [Transaction], year: Int, month: Int,
                         budgetByName: [String: Decimal], totalBudget: Decimal,
                         currencyCode: String, calendar: Calendar) -> [[String]] {
    let totalExpense = monthTxs.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
    let totalIncome = monthTxs.filter { $0.type == .income }.reduce(Decimal(0)) { $0 + $1.amount }

    var spentByCat: [String: Decimal] = [:]
    for tx in monthTxs where tx.type == .expense {
        let name = tx.category?.name ?? "Uncategorized"
        spentByCat[name, default: 0] += tx.amount
    }
    let catRows = spentByCat.sorted {
        $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key
    }

    var rows: [[String]] = [
        [monthTitle(year: year, month: month, calendar: calendar)],
        ["Total expense", sheetNumber(totalExpense)],
        ["Total income", sheetNumber(totalIncome)],
        ["Net", sheetNumber(totalIncome - totalExpense)],
        ["Total budget", sheetNumber(totalBudget)],
        ["Budget left", sheetNumber(totalBudget - totalExpense)],
        [],
        ["Spending by category"],
        ["Category", "Spent", "Budget", "Left"]
    ]

    for (name, spent) in catRows {
        let budget = budgetByName[name] ?? 0
        if budget > 0 {
            rows.append([name, sheetNumber(spent), sheetNumber(budget), sheetNumber(budget - spent)])
        } else {
            rows.append([name, sheetNumber(spent), "", ""])
        }
    }

    rows.append([])
    rows.append(["Transactions"])
    rows.append(["Date", "Category", "Note", "Type", "Amount (\(currencyCode))"])

    let sorted = monthTxs.sorted {
        $0.date != $1.date ? $0.date > $1.date : $0.createdAt > $1.createdAt
    }
    for tx in sorted {
        rows.append([
            sheetDate(tx.date, calendar: calendar),
            tx.category?.name ?? "Uncategorized",
            tx.note,
            tx.type == .expense ? "Expense" : "Income",
            sheetNumber(tx.amount)
        ])
    }
    return rows
}

// MARK: - formatting (deterministic)

/// Plain numeric string (no symbol, no forced decimals): 12.5, 700, 0.
private func sheetNumber(_ value: Decimal) -> String {
    NSDecimalNumber(decimal: value).stringValue
}

private func sheetDate(_ date: Date, calendar: Calendar) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.calendar = calendar
    f.timeZone = calendar.timeZone
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
}

private func monthTitle(year: Int, month: Int, calendar: Calendar) -> String {
    var comps = DateComponents()
    comps.year = year; comps.month = month; comps.day = 1
    let date = calendar.date(from: comps)!
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.calendar = calendar
    f.timeZone = calendar.timeZone
    f.dateFormat = "LLLL yyyy"
    return f.string(from: date)
}
```

- [ ] **Step 4: Run the tests — confirm PASS.** Fix the implementation (not the tests) if any fail.

- [ ] **Step 5: SwiftLint** — `swiftlint lint` → no new violations from the two files.

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Logic/Export/SheetBuilder.swift plop/plopTests/SheetBuilderTests.swift
git commit -m "Add SheetBuilder: transactions + budgets to per-month matrices

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full test suite**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` — all prior + `ExportRangeTests` + `SheetBuilderTests`.

- [ ] **Step 2: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 3: Push + PR**

```bash
git push -u origin feature/export-sheetbuilder
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Add pure export transformation: ExportRange (This month / Date range) and
SheetBuilder, turning transactions + budgets into per-month value matrices
(summary, budget, category breakdown, transaction rows). No network/UI — sets up PR3.

## Testing
All unit tests pass (N new); SwiftLint clean.
```
(Replace `N` with the count of new tests.)

---

## Self-review notes

- **Spec coverage:** ExportRange This-month/Date-range (Task 1); per-month tab with
  totals/net, total-budget + budget-left, category breakdown with budget/left (blank
  when unset), transaction rows with ISO date + Type + currency-tagged RAW amounts,
  oldest-first month ordering with `yyyy-MM` titles (Task 2). Networking, folder/tab
  writes, and UI are later PRs — absent.
- **Type consistency:** `MonthSheet(year:month:values:)`/`tabTitle`,
  `buildExportSheets(transactions:categories:range:budgetMode:generalBudget:currencyCode:now:calendar:)`,
  and `ExportRange.contains(_:now:calendar:)` match across source and tests; reuses
  `activeBudgetTotal`, `PeriodFilter`, `TransactionType`, `ExpenseCategory` as defined.
- **Determinism:** all tests pass a fixed UTC `Calendar` and explicit `now`; date and
  month-title formatting use `en_US_POSIX` + the passed calendar's time zone, so no
  locale/timezone flakiness.
- **No placeholders:** every step has complete code.
