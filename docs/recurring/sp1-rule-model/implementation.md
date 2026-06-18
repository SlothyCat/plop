# Recurring Payments SP1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the `RecurringRule` model (+ additive `Transaction.rule` migration) and a pure, fully-tested occurrence-date engine. No generation, no UI, no trigger.

**Architecture:** A pure `RecurringSchedule` (date math on primitives — no SwiftData) and a `RecurringRule` `@Model` linked to `Transaction` via an optional relationship. All `ModelContainer` schemas gain `RecurringRule.self`.

**Tech Stack:** Swift, Foundation, SwiftData, XCTest. iOS 18. No new deps.

Single PR on branch `feature/recurring-sp1` (off `main`).

---

## File structure

- **Create** `plop/plop/Logic/RecurringSchedule.swift` — pure occurrence-date math.
- **Create** `plop/plopTests/RecurringScheduleTests.swift`.
- **Create** `plop/plop/Models/RecurringRule.swift` — the `@Model`.
- **Modify** `plop/plop/Models/Transaction.swift` — add `var rule: RecurringRule?`.
- **Modify** schema registrations: `plopApp.swift`, `ContentView.swift` (#Preview), `Previews/SampleData.swift`, `plopTests/TestSupport.swift` — add `RecurringRule.self`.
- **Create** `plop/plopTests/RecurringRuleTests.swift` — relationship/migration smoke test.

### Verified existing context

- `RecurrenceInterval` enum: `.none/.daily/.weekly/.monthly/.yearly`.
- `Transaction` `@Model` (amount/type/date/note/recurrence/createdAt/category) — add one optional property; init unchanged (defaults nil).
- Containers register `for: Transaction.self, ExpenseCategory.self` in: `plopApp.swift` (Schema array), `ContentView.swift` (`modelContainer(for: [...], inMemory: true)`), `SampleData.previewContainer()`, `TestSupport.makeInMemoryContainer()`.
- SwiftData gotchas (memory): non-optional `Decimal`; declare an inverse relationship on ONE side only; clean+erase sim if a bogus crash appears.

### Test / build commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests/RecurringScheduleTests -only-testing:plopTests/RecurringRuleTests \
  -parallel-testing-enabled NO 2>&1 | tail -30

swiftlint lint
```

> SourceKit false positives for new files are expected — the build/test run is the source of truth. Lines ≤ 120. **No `// swiftlint:disable`; do not edit `.swiftlint.yml`.**

---

## Task 1: RecurringSchedule (pure date engine)

**Files:**
- Create: `plop/plop/Logic/RecurringSchedule.swift`
- Create: `plop/plopTests/RecurringScheduleTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/RecurringScheduleTests.swift`:

```swift
import XCTest
@testable import plop

final class RecurringScheduleTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d))!
    }
    private func due(_ interval: RecurrenceInterval, anchorDay: Int,
                     start: Date, lastGenerated: Date?, asOf: Date) -> [Date] {
        RecurringSchedule.dueOccurrences(interval: interval, anchorDay: anchorDay,
                                         startDate: start, lastGenerated: lastGenerated,
                                         asOf: asOf, calendar: utc)
    }

    func test_none_isEmpty() {
        XCTAssertTrue(due(.none, anchorDay: 1, start: day(2026, 1, 1),
                          lastGenerated: nil, asOf: day(2026, 12, 1)).isEmpty)
    }

    func test_monthly_normalAnchor() {
        let result = due(.monthly, anchorDay: 5, start: day(2026, 1, 3),
                         lastGenerated: nil, asOf: day(2026, 4, 10))
        XCTAssertEqual(result, [day(2026, 1, 5), day(2026, 2, 5),
                                day(2026, 3, 5), day(2026, 4, 5)])
    }

    func test_monthly_clampsToMonthEnd() {
        let result = due(.monthly, anchorDay: 31, start: day(2026, 1, 31),
                         lastGenerated: nil, asOf: day(2026, 4, 30))
        XCTAssertEqual(result, [day(2026, 1, 31), day(2026, 2, 28),
                                day(2026, 3, 31), day(2026, 4, 30)])
    }

    func test_monthly_firstOccurrenceAfterStart() {
        // start Jun 18, anchor 5 → first occurrence is Jul 5 (Jun 5 already passed)
        let result = due(.monthly, anchorDay: 5, start: day(2026, 6, 18),
                         lastGenerated: nil, asOf: day(2026, 8, 31))
        XCTAssertEqual(result, [day(2026, 7, 5), day(2026, 8, 5)])
    }

    func test_daily() {
        let result = due(.daily, anchorDay: 1, start: day(2026, 1, 1),
                         lastGenerated: nil, asOf: day(2026, 1, 4))
        XCTAssertEqual(result, [day(2026, 1, 1), day(2026, 1, 2),
                                day(2026, 1, 3), day(2026, 1, 4)])
    }

    func test_weekly_keepsWeekday() {
        let result = due(.weekly, anchorDay: 1, start: day(2026, 1, 1),
                         lastGenerated: nil, asOf: day(2026, 1, 22))
        XCTAssertEqual(result, [day(2026, 1, 1), day(2026, 1, 8),
                                day(2026, 1, 15), day(2026, 1, 22)])
    }

    func test_yearly_leapClamp() {
        let result = due(.yearly, anchorDay: 1, start: day(2024, 2, 29),
                         lastGenerated: nil, asOf: day(2028, 3, 1))
        XCTAssertEqual(result, [day(2024, 2, 29), day(2025, 2, 28),
                                day(2026, 2, 28), day(2027, 2, 28), day(2028, 2, 29)])
    }

    func test_lastGenerated_isExclusiveBoundary() {
        let result = due(.monthly, anchorDay: 5, start: day(2026, 1, 5),
                         lastGenerated: day(2026, 2, 5), asOf: day(2026, 4, 5))
        XCTAssertEqual(result, [day(2026, 3, 5), day(2026, 4, 5)])  // not Feb 5 again
    }

    func test_catchUp_yearGapDaily() {
        let result = due(.daily, anchorDay: 1, start: day(2025, 6, 18),
                         lastGenerated: day(2025, 6, 18), asOf: day(2026, 6, 18))
        XCTAssertEqual(result.count, 365)             // Jun 19 2025 … Jun 18 2026
        XCTAssertEqual(result.first, day(2025, 6, 19))
        XCTAssertEqual(result.last, day(2026, 6, 18))
    }

    func test_asOfBeforeFirstOccurrence_isEmpty() {
        let result = due(.monthly, anchorDay: 5, start: day(2026, 6, 18),
                         lastGenerated: nil, asOf: day(2026, 6, 30))
        XCTAssertTrue(result.isEmpty)                 // first is Jul 5
    }
}
```

- [ ] **Step 2: Run the tests — confirm they FAIL to build.**

- [ ] **Step 3: Implement**

Create `plop/plop/Logic/RecurringSchedule.swift`:

```swift
import Foundation

/// Pure occurrence-date math for recurring rules — no SwiftData, no side effects.
/// All results are start-of-day in the supplied calendar. The generation engine
/// (SP2) consumes `dueOccurrences` to insert occurrences and advance state.
enum RecurringSchedule {

    /// Occurrence dates due strictly after `lastGenerated` (or from the first
    /// occurrence when nil) and on/before `asOf`, ascending. Returns all (no cap).
    static func dueOccurrences(interval: RecurrenceInterval, anchorDay: Int,
                               startDate: Date, lastGenerated: Date?, asOf: Date,
                               calendar: Calendar) -> [Date] {
        guard interval != .none else { return [] }
        let cap = calendar.startOfDay(for: asOf)
        let after = lastGenerated.map { calendar.startOfDay(for: $0) }

        var result: [Date] = []
        var index = 0
        while true {
            let date = occurrence(index: index, interval: interval, anchorDay: anchorDay,
                                  startDate: startDate, calendar: calendar)
            if date > cap { break }
            if after == nil || date > after! { result.append(date) }
            index += 1
        }
        return result
    }

    /// The 0-based index-th occurrence of the sequence.
    static func occurrence(index: Int, interval: RecurrenceInterval, anchorDay: Int,
                           startDate: Date, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: startDate)
        switch interval {
        case .none:
            return start
        case .daily:
            return calendar.date(byAdding: .day, value: index, to: start)!
        case .weekly:
            return calendar.date(byAdding: .day, value: index * 7, to: start)!
        case .monthly:
            let first = firstMonthly(anchorDay: anchorDay, onOrAfter: start, calendar: calendar)
            var comps = calendar.dateComponents([.year, .month], from: first)
            comps.month = (comps.month ?? 1) + index
            return clampDay(anchorDay, inMonthOf: comps, calendar: calendar)
        case .yearly:
            let target = calendar.date(byAdding: .year, value: index, to: start)!
            let comps = calendar.dateComponents([.year, .month], from: target)
            return clampDay(calendar.component(.day, from: start), inMonthOf: comps,
                            calendar: calendar)
        }
    }

    // MARK: helpers

    /// First date on `anchorDay` (clamped to month length) that is >= `start`.
    private static func firstMonthly(anchorDay: Int, onOrAfter start: Date,
                                     calendar: Calendar) -> Date {
        let thisMonth = clampDay(anchorDay,
                                 inMonthOf: calendar.dateComponents([.year, .month], from: start),
                                 calendar: calendar)
        if thisMonth >= start { return thisMonth }
        let next = calendar.date(byAdding: .month, value: 1, to: start)!
        return clampDay(anchorDay,
                        inMonthOf: calendar.dateComponents([.year, .month], from: next),
                        calendar: calendar)
    }

    /// `day`, clamped to the length of the month in `monthComps` (year + month),
    /// as a start-of-day date. `monthComps.month` may be out of 1...12 — Calendar
    /// normalizes it into the correct year.
    private static func clampDay(_ day: Int, inMonthOf monthComps: DateComponents,
                                 calendar: Calendar) -> Date {
        var comps = DateComponents()
        comps.year = monthComps.year
        comps.month = monthComps.month
        comps.day = 1
        let monthStart = calendar.date(from: comps)!
        let length = calendar.range(of: .day, in: .month, for: monthStart)!.count
        comps.day = min(max(day, 1), length)
        return calendar.startOfDay(for: calendar.date(from: comps)!)
    }
}
```

- [ ] **Step 4: Run the tests — confirm PASS** (11 tests). Fix the implementation (not the tests) if any fail.

- [ ] **Step 5: SwiftLint** — `swiftlint lint` → no new violations; no disable comments; `.swiftlint.yml` unchanged.

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Logic/RecurringSchedule.swift plop/plopTests/RecurringScheduleTests.swift
git commit -m "Add pure recurring-occurrence schedule engine

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: RecurringRule model + migration

**Files:**
- Create: `plop/plop/Models/RecurringRule.swift`
- Modify: `plop/plop/Models/Transaction.swift`
- Modify: `plop/plop/plopApp.swift`, `plop/plop/ContentView.swift`, `plop/plop/Previews/SampleData.swift`, `plop/plopTests/TestSupport.swift`
- Create: `plop/plopTests/RecurringRuleTests.swift`

- [ ] **Step 1: Write the failing test**

Create `plop/plopTests/RecurringRuleTests.swift`:

```swift
import XCTest
import SwiftData
@testable import plop

@MainActor
final class RecurringRuleTests: XCTestCase {

    func test_rule_linksTransactionBothWays() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let rule = RecurringRule(amount: 15, type: .expense, note: "Netflix",
                                 interval: .monthly, anchorDay: 5, startDate: .now)
        context.insert(rule)

        let tx = Transaction(amount: 15, type: .expense, date: .now, note: "Netflix")
        tx.rule = rule
        context.insert(tx)
        try context.save()

        XCTAssertEqual(tx.rule?.note, "Netflix")
        XCTAssertEqual(rule.occurrences.count, 1)
        XCTAssertEqual(rule.occurrences.first?.amount, 15)
    }

    func test_deletingRule_keepsTransaction_nullifiesLink() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let rule = RecurringRule(amount: 9, type: .expense, note: "Gym",
                                 interval: .monthly, anchorDay: 1, startDate: .now)
        context.insert(rule)
        let tx = Transaction(amount: 9, type: .expense, date: .now, note: "Gym")
        tx.rule = rule
        context.insert(tx)
        try context.save()

        context.delete(rule)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(remaining.count, 1)          // occurrence kept
        XCTAssertNil(remaining.first?.rule)         // link nullified
    }
}
```

- [ ] **Step 2: Run the tests — confirm they FAIL to build** (`RecurringRule` undefined).

- [ ] **Step 3: Create the model**

Create `plop/plop/Models/RecurringRule.swift`:

```swift
import Foundation
import SwiftData

/// A recurring-payment template + scheduling state. Generated occurrences are normal
/// Transactions linked via `occurrences` (inverse: Transaction.rule). Generation and
/// UI arrive in later sub-projects.
@Model
final class RecurringRule {
    var amount: Decimal               // always positive; sign derived from `type`
    var type: TransactionType
    var note: String
    var interval: RecurrenceInterval  // never .none for a rule
    var anchorDay: Int                // day-of-month for .monthly; derived/ignored otherwise
    var startDate: Date
    var lastGeneratedDate: Date?      // nil until first generation (SP2)
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var category: ExpenseCategory?

    // Inverse inferred from Transaction.rule — declared on this side only to avoid
    // the SwiftData metadata-cycle trap. Nullify keeps occurrences when a rule goes.
    @Relationship(deleteRule: .nullify)
    var occurrences: [Transaction] = []

    init(amount: Decimal, type: TransactionType, note: String = "",
         interval: RecurrenceInterval, anchorDay: Int, startDate: Date,
         category: ExpenseCategory? = nil) {
        self.amount = amount
        self.type = type
        self.note = note
        self.interval = interval
        self.anchorDay = anchorDay
        self.startDate = startDate
        self.lastGeneratedDate = nil
        self.isActive = true
        self.createdAt = .now
        self.category = category
    }
}
```

- [ ] **Step 4: Add the relationship to Transaction**

In `plop/plop/Models/Transaction.swift`, add a stored property after `var category: ExpenseCategory?`:

```swift
    var rule: RecurringRule?      // set when this is a generated recurring occurrence
```
(Leave the initializer unchanged — `rule` defaults to nil.)

- [ ] **Step 5: Register RecurringRule in every container schema**

- `plop/plop/plopApp.swift` — in the `Schema([...])` array, add `RecurringRule.self`:
```swift
        let schema = Schema([
            Transaction.self,
            ExpenseCategory.self,
            RecurringRule.self,
        ])
```
- `plop/plop/ContentView.swift` — the `#Preview` modifier:
```swift
        .modelContainer(for: [Transaction.self, ExpenseCategory.self, RecurringRule.self],
                        inMemory: true)
```
- `plop/plop/Previews/SampleData.swift` — `previewContainer()`:
```swift
            let container = try ModelContainer(
                for: Transaction.self, ExpenseCategory.self, RecurringRule.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
```
- `plop/plopTests/TestSupport.swift` — `makeInMemoryContainer()`:
```swift
    return try ModelContainer(for: Transaction.self, ExpenseCategory.self, RecurringRule.self,
                              configurations: config)
```

- [ ] **Step 6: Run the tests — confirm PASS** (2 tests). Then run the full suite to confirm the additive migration didn't disturb existing model tests:
```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed|TEST (SUCCEEDED|FAILED)" | tail -2
```
> If a bogus SwiftData crash appears, clean DerivedData + erase the sim and retry (memory/xcode-build-sim-gotchas.md) before assuming a logic error.

- [ ] **Step 7: SwiftLint** — no new violations; no disable comments.

- [ ] **Step 8: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Models/RecurringRule.swift plop/plop/Models/Transaction.swift \
        plop/plop/plopApp.swift plop/plop/ContentView.swift \
        plop/plop/Previews/SampleData.swift plop/plopTests/TestSupport.swift \
        plop/plopTests/RecurringRuleTests.swift
git commit -m "Add RecurringRule model and Transaction.rule relationship

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` — all prior + `RecurringScheduleTests` + `RecurringRuleTests`.

- [ ] **Step 2: Lint** — `swiftlint lint` → no new violations; `.swiftlint.yml` unchanged.

- [ ] **Step 3: Push + PR**

```bash
git push -u origin feature/recurring-sp1
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Recurring payments SP1: add the RecurringRule model (+ additive Transaction.rule
relationship) and a pure, fully-tested occurrence-date engine (monthly clamp,
leap-year, catch-up, dedup). No generation/UI/trigger yet — sets up SP2.

## Testing
All unit tests pass (N new); SwiftLint clean. Additive SwiftData migration.
```
(Replace `N`.)

---

## Self-review notes

- **Spec coverage:** `RecurringRule` model + nullify relationship (Task 2);
  additive migration via schema registration in all 4 containers (Task 2);
  `dueOccurrences` with monthly clamp, leap-year yearly, daily/weekly, catch-up,
  exclusive `lastGenerated`, asOf-before-first, `.none` (Task 1, tested); legacy
  `recurrence` untouched. No generation/trigger/UI (SP2–SP4) — absent.
- **Type consistency:** `RecurringSchedule.dueOccurrences(interval:anchorDay:startDate:lastGenerated:asOf:calendar:)`
  + `occurrence(index:...)` match the tests; `RecurringRule(amount:type:note:interval:anchorDay:startDate:category:)`
  + `Transaction.rule` match the relationship tests; `makeInMemoryContainer` now
  registers `RecurringRule`.
- **No placeholders / no disables / config untouched.**
- **SwiftData care:** additive migration; inverse on one side; nullify keeps past
  occurrences; clean+erase if a bogus crash appears.
