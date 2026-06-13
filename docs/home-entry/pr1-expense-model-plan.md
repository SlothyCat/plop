# PR1 — Expense Model Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the non-UI foundation of the plop expense tracker — SwiftData models, a pure (unit-tested) logic layer, a centralized write path, and once-ever category seeding.

**Architecture:** SwiftData `@Model` classes for `Transaction`/`Category` with a nullify relationship; business logic lives in pure free functions (no SwiftUI/`ModelContext`) so it is unit-testable; all writes funnel through a `TransactionActions` helper. No UI in this PR (the template `ContentView` becomes a placeholder so `main` keeps building).

**Tech Stack:** Swift, SwiftUI, SwiftData, XCTest. iOS 18+. Xcode project uses synchronized folders (new files auto-included; no `pbxproj` edits).

---

## Conventions for this plan

- **Branch:** `feature/expense-model`. Do NOT use git worktrees (breaks the open Xcode project) — work in the current checkout.
- **Commits:** small, present-tense, one logical change. Append the repo trailer
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>` to every commit (omitted from the snippets below for brevity).
- **Test command (single test):**
  ```bash
  xcodebuild test -project plop/plop.xcodeproj -scheme plop \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:plopTests/CLASS/METHOD
  ```
- **Build command:**
  ```bash
  xcodebuild build -project plop/plop.xcodeproj -scheme plop \
    -destination 'platform=iOS Simulator,name=iPhone 16'
  ```
- All new source files live under `plop/plop/...`; all tests under `plop/plopTests/...`.

## File Structure

Created in this PR:
- `plop/plop/Models/TransactionType.swift` — expense/income enum.
- `plop/plop/Models/RecurrenceInterval.swift` — recurrence enum (stored, inert).
- `plop/plop/Models/Category.swift` — `@Model` Category + nullify relationship.
- `plop/plop/Models/Transaction.swift` — `@Model` Transaction.
- `plop/plop/Logic/TransactionAggregation.swift` — `signedAmount`, `netTotal`, `DayGroup`, `groupByDay`.
- `plop/plop/Logic/PeriodFilter.swift` — week/month/year date ranges.
- `plop/plop/Logic/Formatting.swift` — `formattedMoney`, `dayLabel`.
- `plop/plop/Data/TransactionDraft.swift` — value type for form fields.
- `plop/plop/Data/TransactionActions.swift` — add/update/delete.
- `plop/plop/Seed/DefaultData.swift` — default categories + once-ever seeding.
- `plop/plopTests/TestSupport.swift` — in-memory container + date helpers.
- `plop/plopTests/TransactionAggregationTests.swift`
- `plop/plopTests/PeriodFilterTests.swift`
- `plop/plopTests/FormattingTests.swift`
- `plop/plopTests/TransactionActionsTests.swift`
- `plop/plopTests/DefaultDataTests.swift`

Modified / removed:
- Modify `plop/plop/plopApp.swift` — register `Transaction`/`Category`.
- Modify `plop/plop/ContentView.swift` — placeholder; later wires seeding.
- Delete `plop/plop/Item.swift` — template model, replaced.
- Delete `plop/plopTests/plopTests.swift` — empty template stubs, replaced by real tests.

---

### Task 1: Branch, enums, models, container, build green

**Files:**
- Create: `plop/plop/Models/TransactionType.swift`, `plop/plop/Models/RecurrenceInterval.swift`, `plop/plop/Models/Category.swift`, `plop/plop/Models/Transaction.swift`
- Modify: `plop/plop/plopApp.swift`, `plop/plop/ContentView.swift`
- Delete: `plop/plop/Item.swift`

- [ ] **Step 1: Create the branch**

```bash
git checkout -b feature/expense-model
```

- [ ] **Step 2: Create the two enums**

`plop/plop/Models/TransactionType.swift`:
```swift
import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case expense
    case income
}
```

`plop/plop/Models/RecurrenceInterval.swift`:
```swift
import Foundation

/// Stored on a transaction now; the generation engine arrives in Feature 2.
enum RecurrenceInterval: String, Codable, CaseIterable {
    case none
    case daily
    case weekly
    case monthly
    case yearly
}
```

- [ ] **Step 3: Create the `Category` model**

`plop/plop/Models/Category.swift`:
```swift
import Foundation
import SwiftData

@Model
final class Category {
    var name: String
    var symbolName: String      // SF Symbol, e.g. "fork.knife"
    var colorHex: String        // e.g. "#FFEBCC"
    var budget: Decimal?        // unused now; Budget feature fills it later

    // Deleting a Category nullifies its transactions' link → they show "Uncategorized".
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction] = []

    init(name: String, symbolName: String, colorHex: String, budget: Decimal? = nil) {
        self.name = name
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.budget = budget
    }
}
```

- [ ] **Step 4: Create the `Transaction` model**

`plop/plop/Models/Transaction.swift`:
```swift
import Foundation
import SwiftData

@Model
final class Transaction {
    var amount: Decimal           // always positive; sign derived from `type`
    var type: TransactionType
    var date: Date                // spend date + time
    var note: String
    var recurrence: RecurrenceInterval
    var createdAt: Date           // stable sort tiebreaker
    var category: Category?

    init(amount: Decimal,
         type: TransactionType,
         date: Date,
         note: String = "",
         recurrence: RecurrenceInterval = .none,
         category: Category? = nil) {
        self.amount = amount
        self.type = type
        self.date = date
        self.note = note
        self.recurrence = recurrence
        self.createdAt = .now
        self.category = category
    }
}
```

- [ ] **Step 5: Register the models in `plopApp.swift`**

Replace the entire contents of `plop/plop/plopApp.swift`:
```swift
import SwiftUI
import SwiftData

@main
struct plopApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

- [ ] **Step 6: Replace `ContentView` with a placeholder and delete `Item`**

Replace the entire contents of `plop/plop/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        // Placeholder until the Home + Entry UI lands in PR2.
        Text("plop")
    }
}

#Preview {
    ContentView()
}
```

Then delete the template model:
```bash
git rm plop/plop/Item.swift
```

- [ ] **Step 7: Build to verify everything compiles**

Run:
```bash
xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 8: Commit**

```bash
git add plop/plop/Models plop/plop/plopApp.swift plop/plop/ContentView.swift
git commit -m "Add Transaction and Category SwiftData models"
```

---

### Task 2: `signedAmount`

**Files:**
- Create: `plop/plopTests/TransactionAggregationTests.swift`
- Create: `plop/plop/Logic/TransactionAggregation.swift`

- [ ] **Step 1: Write the failing test**

`plop/plopTests/TransactionAggregationTests.swift`:
```swift
import XCTest
@testable import plop

final class TransactionAggregationTests: XCTestCase {
    func test_signedAmount_expenseIsNegative() {
        let tx = Transaction(amount: Decimal(10), type: .expense, date: .now)
        XCTAssertEqual(signedAmount(tx), Decimal(-10))
    }

    func test_signedAmount_incomeIsPositive() {
        let tx = Transaction(amount: Decimal(10), type: .income, date: .now)
        XCTAssertEqual(signedAmount(tx), Decimal(10))
    }
}
```

- [ ] **Step 2: Run to verify it fails**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:plopTests/TransactionAggregationTests/test_signedAmount_expenseIsNegative
```
Expected: FAIL — `cannot find 'signedAmount' in scope`.

- [ ] **Step 3: Write minimal implementation**

`plop/plop/Logic/TransactionAggregation.swift`:
```swift
import Foundation

/// Signed value of a transaction: income positive, expense negative.
func signedAmount(_ tx: Transaction) -> Decimal {
    switch tx.type {
    case .income:  return tx.amount
    case .expense: return -tx.amount
    }
}
```

- [ ] **Step 4: Run to verify it passes**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:plopTests/TransactionAggregationTests
```
Expected: PASS (both tests).

- [ ] **Step 5: Commit**

```bash
git add plop/plop/Logic/TransactionAggregation.swift plop/plopTests/TransactionAggregationTests.swift
git commit -m "Add signedAmount aggregation helper"
```

---

### Task 3: `netTotal`

**Files:**
- Modify: `plop/plopTests/TransactionAggregationTests.swift`
- Modify: `plop/plop/Logic/TransactionAggregation.swift`

- [ ] **Step 1: Add the failing tests**

Add these two methods inside `TransactionAggregationTests` (before the closing brace):
```swift
    func test_netTotal_mixedSum() {
        let txs = [
            Transaction(amount: Decimal(100), type: .income,  date: .now),
            Transaction(amount: Decimal(30),  type: .expense, date: .now),
            Transaction(amount: Decimal(20),  type: .expense, date: .now),
        ]
        XCTAssertEqual(netTotal(of: txs), Decimal(50))
    }

    func test_netTotal_emptyIsZero() {
        XCTAssertEqual(netTotal(of: []), Decimal(0))
    }
```

- [ ] **Step 2: Run to verify it fails**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:plopTests/TransactionAggregationTests/test_netTotal_mixedSum
```
Expected: FAIL — `cannot find 'netTotal' in scope`.

- [ ] **Step 3: Write minimal implementation**

Append to `plop/plop/Logic/TransactionAggregation.swift`:
```swift
/// Signed sum over a set of transactions. Empty → 0.
func netTotal(of txs: [Transaction]) -> Decimal {
    txs.reduce(Decimal(0)) { $0 + signedAmount($1) }
}
```

- [ ] **Step 4: Run to verify it passes**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:plopTests/TransactionAggregationTests
```
Expected: PASS (all four tests).

- [ ] **Step 5: Commit**

```bash
git add plop/plop/Logic/TransactionAggregation.swift plop/plopTests/TransactionAggregationTests.swift
git commit -m "Add netTotal aggregation helper"
```

---

### Task 4: `PeriodFilter` date ranges

**Files:**
- Create: `plop/plopTests/TestSupport.swift`
- Create: `plop/plopTests/PeriodFilterTests.swift`
- Create: `plop/plop/Logic/PeriodFilter.swift`

- [ ] **Step 1: Create shared test helpers**

`plop/plopTests/TestSupport.swift`:
```swift
import Foundation
import SwiftData
@testable import plop

/// Deterministic calendar for tests: UTC, POSIX locale, Monday-start by default.
func fixedCalendar(firstWeekday: Int = 2) -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    cal.locale = Locale(identifier: "en_US_POSIX")
    cal.firstWeekday = firstWeekday   // 2 = Monday
    return cal
}

func makeDate(_ year: Int, _ month: Int, _ day: Int,
              _ hour: Int = 0, _ minute: Int = 0,
              calendar: Calendar) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day,
                                       hour: hour, minute: minute))!
}

/// Fresh in-memory SwiftData context for data-layer tests.
@MainActor
func makeInMemoryContext() throws -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Transaction.self, Category.self,
                                       configurations: config)
    return container.mainContext
}
```

- [ ] **Step 2: Write the failing tests**

`plop/plopTests/PeriodFilterTests.swift`:
```swift
import XCTest
@testable import plop

final class PeriodFilterTests: XCTestCase {
    func test_month_coversWholeMonth() {
        let cal = fixedCalendar()
        let anchor = makeDate(2026, 5, 15, 12, 0, calendar: cal)
        let range = PeriodFilter.month.range(containing: anchor, calendar: cal)
        XCTAssertEqual(range.lowerBound, makeDate(2026, 5, 1, calendar: cal))
        let june1 = makeDate(2026, 6, 1, calendar: cal)
        XCTAssertEqual(range.upperBound, june1.addingTimeInterval(-1))
    }

    func test_year_coversWholeYear() {
        let cal = fixedCalendar()
        let anchor = makeDate(2026, 7, 4, calendar: cal)
        let range = PeriodFilter.year.range(containing: anchor, calendar: cal)
        XCTAssertEqual(range.lowerBound, makeDate(2026, 1, 1, calendar: cal))
        let nextYear = makeDate(2027, 1, 1, calendar: cal)
        XCTAssertEqual(range.upperBound, nextYear.addingTimeInterval(-1))
    }

    func test_week_isSevenDaysStartingMonday() {
        let cal = fixedCalendar(firstWeekday: 2)
        let anchor = makeDate(2026, 5, 30, 12, 0, calendar: cal)
        let range = PeriodFilter.week.range(containing: anchor, calendar: cal)
        XCTAssertTrue(range.contains(anchor))
        XCTAssertEqual(cal.component(.weekday, from: range.lowerBound), 2) // Monday
        let days = cal.dateComponents([.day], from: range.lowerBound,
                                      to: range.upperBound).day
        XCTAssertEqual(days, 6) // 6 whole days + remainder seconds = inclusive 7-day span
    }
}
```

- [ ] **Step 3: Run to verify it fails**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:plopTests/PeriodFilterTests/test_month_coversWholeMonth
```
Expected: FAIL — `cannot find 'PeriodFilter' in scope`.

- [ ] **Step 4: Write minimal implementation**

`plop/plop/Logic/PeriodFilter.swift`:
```swift
import Foundation

enum PeriodFilter: CaseIterable {
    case week, month, year

    /// Inclusive date range of the period containing `date`, per the given calendar.
    func range(containing date: Date, calendar: Calendar) -> ClosedRange<Date> {
        let component: Calendar.Component
        switch self {
        case .week:  component = .weekOfYear
        case .month: component = .month
        case .year:  component = .year
        }
        let interval = calendar.dateInterval(of: component, for: date)!
        // dateInterval.end is exclusive (start of next period); make it inclusive.
        return interval.start...interval.end.addingTimeInterval(-1)
    }
}
```

- [ ] **Step 5: Run to verify it passes, then commit**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:plopTests/PeriodFilterTests
```
Expected: PASS (all three).

```bash
git add plop/plop/Logic/PeriodFilter.swift plop/plopTests/PeriodFilterTests.swift plop/plopTests/TestSupport.swift
git commit -m "Add PeriodFilter date ranges"
```

---

### Task 5: `groupByDay`

**Files:**
- Modify: `plop/plopTests/TransactionAggregationTests.swift`
- Modify: `plop/plop/Logic/TransactionAggregation.swift`

- [ ] **Step 1: Add the failing test**

Add inside `TransactionAggregationTests`:
```swift
    func test_groupByDay_groupsSortsAndSubtotals() {
        let cal = fixedCalendar()
        let early = makeDate(2026, 5, 29, 13, 0, calendar: cal)
        let late  = makeDate(2026, 5, 29, 22, 0, calendar: cal)
        let other = makeDate(2026, 5, 26, 11, 0, calendar: cal)
        let txs = [
            Transaction(amount: Decimal(5),   type: .expense, date: early),
            Transaction(amount: Decimal(612), type: .expense, date: late),
            Transaction(amount: Decimal(4),   type: .expense, date: other),
        ]

        let groups = groupByDay(txs, calendar: cal)

        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0].date, cal.startOfDay(for: late))   // newest day first
        XCTAssertEqual(groups[1].date, cal.startOfDay(for: other))
        XCTAssertEqual(groups[0].transactions.first?.date, late)    // newest time first
        XCTAssertEqual(groups[0].subtotal, Decimal(-617))           // -(5 + 612)
    }
```

- [ ] **Step 2: Run to verify it fails**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:plopTests/TransactionAggregationTests/test_groupByDay_groupsSortsAndSubtotals
```
Expected: FAIL — `cannot find 'groupByDay'` / `cannot find 'DayGroup'`.

- [ ] **Step 3: Write minimal implementation**

Append to `plop/plop/Logic/TransactionAggregation.swift`:
```swift
struct DayGroup {
    let date: Date              // start of day
    let transactions: [Transaction]
    let subtotal: Decimal
}

/// Group transactions by local calendar day, newest day first; within a day
/// newest time first, tiebroken by createdAt.
func groupByDay(_ txs: [Transaction], calendar: Calendar) -> [DayGroup] {
    let grouped = Dictionary(grouping: txs) { calendar.startOfDay(for: $0.date) }
    return grouped.keys.sorted(by: >).map { day in
        let rows = grouped[day]!.sorted {
            if $0.date != $1.date { return $0.date > $1.date }
            return $0.createdAt > $1.createdAt
        }
        return DayGroup(date: day, transactions: rows, subtotal: netTotal(of: rows))
    }
}
```

- [ ] **Step 4: Run to verify it passes, then commit**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:plopTests/TransactionAggregationTests
```
Expected: PASS (all aggregation tests).

```bash
git add plop/plop/Logic/TransactionAggregation.swift plop/plopTests/TransactionAggregationTests.swift
git commit -m "Add groupByDay aggregation helper"
```

---

### Task 6: Formatting (`formattedMoney`, `dayLabel`)

**Files:**
- Create: `plop/plopTests/FormattingTests.swift`
- Create: `plop/plop/Logic/Formatting.swift`

- [ ] **Step 1: Write the failing tests**

`plop/plopTests/FormattingTests.swift`:
```swift
import XCTest
@testable import plop

final class FormattingTests: XCTestCase {
    private let enUS = Locale(identifier: "en_US")

    func test_money_unsignedNegativeShowsMinus() {
        XCTAssertEqual(formattedMoney(Decimal(-612), signed: false, locale: enUS), "-$612.00")
    }

    func test_money_signedPositiveShowsPlus() {
        XCTAssertEqual(formattedMoney(Decimal(1200), signed: true, locale: enUS), "+$1,200.00")
    }

    func test_dayLabel_todayAndYesterday() {
        let cal = fixedCalendar()
        let today = makeDate(2026, 5, 30, 9, 0, calendar: cal)
        XCTAssertEqual(dayLabel(for: makeDate(2026, 5, 30, 1, 0, calendar: cal),
                                relativeTo: today, calendar: cal), "TODAY")
        XCTAssertEqual(dayLabel(for: makeDate(2026, 5, 29, 1, 0, calendar: cal),
                                relativeTo: today, calendar: cal), "YESTERDAY")
    }

    func test_dayLabel_olderDateUsesWeekdayFormat() {
        let cal = fixedCalendar()
        let today = makeDate(2026, 5, 30, 9, 0, calendar: cal)
        let label = dayLabel(for: makeDate(2026, 5, 26, 1, 0, calendar: cal),
                             relativeTo: today, calendar: cal)
        XCTAssertTrue(label.hasSuffix("26 MAY"), "got \(label)")
        XCTAssertTrue(label.contains(", "))
    }
}
```

- [ ] **Step 2: Run to verify it fails**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:plopTests/FormattingTests/test_money_unsignedNegativeShowsMinus
```
Expected: FAIL — `cannot find 'formattedMoney' in scope`.

- [ ] **Step 3: Write minimal implementation**

`plop/plop/Logic/Formatting.swift`:
```swift
import Foundation

/// Currency string for an already-signed amount. `signed: true` forces an explicit
/// +/− prefix (transaction rows); otherwise only negatives get a leading "-".
func formattedMoney(_ amount: Decimal, signed: Bool = false, locale: Locale = .current) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = locale
    let magnitude = NSDecimalNumber(decimal: abs(amount))
    let body = formatter.string(from: magnitude) ?? "\(abs(amount))"
    if signed { return (amount < 0 ? "-" : "+") + body }
    return amount < 0 ? "-" + body : body
}

/// Day-group header: "TODAY" / "YESTERDAY" / "FRI, 29 MAY".
func dayLabel(for date: Date, relativeTo today: Date, calendar: Calendar) -> String {
    let startOfDate = calendar.startOfDay(for: date)
    let startOfToday = calendar.startOfDay(for: today)
    let days = calendar.dateComponents([.day], from: startOfDate, to: startOfToday).day ?? 0
    if days == 0 { return "TODAY" }
    if days == 1 { return "YESTERDAY" }
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = calendar.locale ?? .current
    formatter.timeZone = calendar.timeZone
    formatter.dateFormat = "EEE, d MMM"
    return formatter.string(from: date).uppercased()
}
```

- [ ] **Step 4: Run to verify it passes, then commit**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:plopTests/FormattingTests
```
Expected: PASS (all four).

```bash
git add plop/plop/Logic/Formatting.swift plop/plopTests/FormattingTests.swift
git commit -m "Add money and day-label formatting helpers"
```

---

### Task 7: `TransactionDraft` + `TransactionActions`

**Files:**
- Create: `plop/plop/Data/TransactionDraft.swift`
- Create: `plop/plopTests/TransactionActionsTests.swift`
- Create: `plop/plop/Data/TransactionActions.swift`

- [ ] **Step 1: Create the draft value type**

`plop/plop/Data/TransactionDraft.swift`:
```swift
import Foundation

/// Plain carrier of Entry's form fields, handed to TransactionActions.
struct TransactionDraft {
    var amount: Decimal
    var type: TransactionType
    var date: Date
    var note: String
    var recurrence: RecurrenceInterval
    var category: Category?

    init(amount: Decimal,
         type: TransactionType,
         date: Date,
         note: String = "",
         recurrence: RecurrenceInterval = .none,
         category: Category? = nil) {
        self.amount = amount
        self.type = type
        self.date = date
        self.note = note
        self.recurrence = recurrence
        self.category = category
    }
}
```

- [ ] **Step 2: Write the failing tests**

`plop/plopTests/TransactionActionsTests.swift`:
```swift
import XCTest
import SwiftData
@testable import plop

@MainActor
final class TransactionActionsTests: XCTestCase {
    func test_add_insertsTransactionWithFields() throws {
        let ctx = try makeInMemoryContext()
        let draft = TransactionDraft(amount: Decimal(12), type: .expense,
                                     date: .now, note: "Lunch")
        TransactionActions.add(draft, in: ctx)
        try ctx.save()

        let all = try ctx.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.amount, Decimal(12))
        XCTAssertEqual(all.first?.type, .expense)
        XCTAssertEqual(all.first?.note, "Lunch")
    }

    func test_add_setsCategoryRelationship() throws {
        let ctx = try makeInMemoryContext()
        let cat = Category(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC")
        ctx.insert(cat)
        let draft = TransactionDraft(amount: Decimal(5), type: .expense,
                                     date: .now, category: cat)
        TransactionActions.add(draft, in: ctx)
        try ctx.save()

        let all = try ctx.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(all.first?.category?.name, "Food")
    }

    func test_update_mutatesFields() throws {
        let ctx = try makeInMemoryContext()
        let tx = Transaction(amount: Decimal(5), type: .expense, date: .now)
        ctx.insert(tx)
        let draft = TransactionDraft(amount: Decimal(9), type: .income,
                                     date: tx.date, note: "Refund")
        TransactionActions.update(tx, with: draft)
        try ctx.save()

        XCTAssertEqual(tx.amount, Decimal(9))
        XCTAssertEqual(tx.type, .income)
        XCTAssertEqual(tx.note, "Refund")
    }

    func test_delete_removesTransaction() throws {
        let ctx = try makeInMemoryContext()
        let tx = Transaction(amount: Decimal(5), type: .expense, date: .now)
        ctx.insert(tx)
        try ctx.save()
        TransactionActions.delete(tx, in: ctx)
        try ctx.save()

        let all = try ctx.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(all.count, 0)
    }

    func test_deletingCategory_nullifiesLink() throws {
        let ctx = try makeInMemoryContext()
        let cat = Category(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC")
        ctx.insert(cat)
        let tx = Transaction(amount: Decimal(5), type: .expense, date: .now, category: cat)
        ctx.insert(tx)
        try ctx.save()

        ctx.delete(cat)
        try ctx.save()

        let all = try ctx.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(all.count, 1)
        XCTAssertNil(all.first?.category)
    }
}
```

- [ ] **Step 3: Run to verify it fails**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:plopTests/TransactionActionsTests/test_add_insertsTransactionWithFields
```
Expected: FAIL — `cannot find 'TransactionActions' in scope`.

- [ ] **Step 4: Write minimal implementation**

`plop/plop/Data/TransactionActions.swift`:
```swift
import Foundation
import SwiftData

/// The single locus for ledger mutations. Reads stay as @Query in views.
enum TransactionActions {
    static func add(_ draft: TransactionDraft, in context: ModelContext) {
        let tx = Transaction(amount: draft.amount,
                             type: draft.type,
                             date: draft.date,
                             note: draft.note,
                             recurrence: draft.recurrence,
                             category: draft.category)
        context.insert(tx)
    }

    static func update(_ tx: Transaction, with draft: TransactionDraft) {
        tx.amount = draft.amount
        tx.type = draft.type
        tx.date = draft.date
        tx.note = draft.note
        tx.recurrence = draft.recurrence
        tx.category = draft.category
    }

    static func delete(_ tx: Transaction, in context: ModelContext) {
        context.delete(tx)
    }
}
```

- [ ] **Step 5: Run to verify it passes, then commit**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:plopTests/TransactionActionsTests
```
Expected: PASS (all five).

```bash
git add plop/plop/Data/TransactionDraft.swift plop/plop/Data/TransactionActions.swift plop/plopTests/TransactionActionsTests.swift
git commit -m "Add TransactionDraft and centralized TransactionActions"
```

---

### Task 8: Once-ever default-category seeding

**Files:**
- Create: `plop/plopTests/DefaultDataTests.swift`
- Create: `plop/plop/Seed/DefaultData.swift`

- [ ] **Step 1: Write the failing tests**

`plop/plopTests/DefaultDataTests.swift`:
```swift
import XCTest
import SwiftData
@testable import plop

@MainActor
final class DefaultDataTests: XCTestCase {
    private func ephemeralDefaults() -> UserDefaults {
        UserDefaults(suiteName: "test-\(UUID().uuidString)")!
    }

    func test_seedIfNeeded_insertsDefaultsWhenFlagUnset() throws {
        let ctx = try makeInMemoryContext()
        let defaults = ephemeralDefaults()

        let didSeed = DefaultData.seedIfNeeded(in: ctx, defaults: defaults)
        try ctx.save()

        XCTAssertTrue(didSeed)
        let cats = try ctx.fetch(FetchDescriptor<Category>())
        XCTAssertEqual(cats.count, DefaultData.defaultCategorySpecs.count)
    }

    func test_seedIfNeeded_doesNotReseedWhenFlagSet() throws {
        let ctx = try makeInMemoryContext()
        let defaults = ephemeralDefaults()
        defaults.set(true, forKey: DefaultData.seededFlagKey)

        let didSeed = DefaultData.seedIfNeeded(in: ctx, defaults: defaults)
        try ctx.save()

        XCTAssertFalse(didSeed)
        let cats = try ctx.fetch(FetchDescriptor<Category>())
        XCTAssertEqual(cats.count, 0)
    }
}
```

- [ ] **Step 2: Run to verify it fails**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:plopTests/DefaultDataTests/test_seedIfNeeded_insertsDefaultsWhenFlagUnset
```
Expected: FAIL — `cannot find 'DefaultData' in scope`.

- [ ] **Step 3: Write minimal implementation**

`plop/plop/Seed/DefaultData.swift`:
```swift
import Foundation
import SwiftData

/// First-run starter categories, seeded exactly once (guarded by a persisted flag,
/// NOT a table-empty check — so deleting all categories later never re-seeds).
enum DefaultData {
    static let seededFlagKey = "didSeedDefaultCategories"

    static let defaultCategorySpecs: [(name: String, symbol: String, color: String)] = [
        ("Food",          "fork.knife",    "#FFEBCC"),
        ("Transport",     "car.fill",      "#BFDDF0"),
        ("Shopping",      "bag.fill",      "#8CC0EB"),
        ("Bills",         "doc.text.fill", "#FFF9D2"),
        ("Entertainment", "play.tv.fill",  "#BFDDF0"),
    ]

    /// Returns true if it seeded on this call.
    @discardableResult
    static func seedIfNeeded(in context: ModelContext,
                             defaults: UserDefaults = .standard) -> Bool {
        guard !defaults.bool(forKey: seededFlagKey) else { return false }
        for spec in defaultCategorySpecs {
            context.insert(Category(name: spec.name,
                                    symbolName: spec.symbol,
                                    colorHex: spec.color))
        }
        defaults.set(true, forKey: seededFlagKey)
        return true
    }
}
```

- [ ] **Step 4: Run to verify it passes, then commit**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:plopTests/DefaultDataTests
```
Expected: PASS (both).

```bash
git add plop/plop/Seed/DefaultData.swift plop/plopTests/DefaultDataTests.swift
git commit -m "Add once-ever default category seeding"
```

---

### Task 9: Wire seeding into launch, remove template test, full green, open PR

**Files:**
- Modify: `plop/plop/ContentView.swift`
- Delete: `plop/plopTests/plopTests.swift`

- [ ] **Step 1: Wire seeding into the placeholder view**

Replace the entire contents of `plop/plop/ContentView.swift`:
```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        // Placeholder until the Home + Entry UI lands in PR2.
        Text("plop")
            .task {
                DefaultData.seedIfNeeded(in: modelContext)
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
```

- [ ] **Step 2: Remove the empty template test file**

```bash
git rm plop/plopTests/plopTests.swift
```

- [ ] **Step 3: Run the full test target**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:plopTests
```
Expected: PASS — all tests across all five test classes; `** TEST SUCCEEDED **`.

- [ ] **Step 4: Lint check (matches CI)**

Run:
```bash
swiftlint lint
```
Expected: no errors (warnings acceptable). If `empty_xctest_method` warnings remain, confirm `plopTests.swift` was removed.

- [ ] **Step 5: Commit, push, open PR**

```bash
git add plop/plop/ContentView.swift
git commit -m "Wire first-run seeding and drop template test"
git push -u origin feature/expense-model
```
Then open a PR `feature/expense-model` → `main` via the GitHub web UI (the `gh` CLI is not installed on this machine). CI will run SwiftLint + the `plopTests` target. Confirm both checks pass before requesting review.

---

## Self-review notes

- **Spec coverage:** models (T1), `signedAmount`/`netTotal`/`groupByDay` (T2,3,5), `PeriodFilter` (T4), formatting (T6), `TransactionActions`/`TransactionDraft` (T7), once-ever seeding (T8), container registration (T1), launch wiring (T9). No UI — matches PR1 scope.
- **Determinism:** money/date tests pin `Locale`/`Calendar`/timezone; the week test asserts structure (Monday start + 7-day span) rather than an unverifiable weekday-name.
- **Type consistency:** `signedAmount`, `netTotal`, `DayGroup`, `groupByDay`, `PeriodFilter.range`, `formattedMoney`, `dayLabel`, `TransactionDraft`, `TransactionActions.{add,update,delete}`, `DefaultData.{seededFlagKey,defaultCategorySpecs,seedIfNeeded}` are referenced with identical signatures across tasks and tests.
- **main stays green:** the `Item` removal is paired with `plopApp`/`ContentView` updates in the same task (T1).
