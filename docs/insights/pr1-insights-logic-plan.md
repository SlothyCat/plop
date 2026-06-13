# PR1 — Insights Aggregation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline, no worktrees — per CLAUDE.md) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build the pure aggregation layer for Insights — per-category spend and donut slice geometry — with unit tests. No UI.

**Architecture:** One new pure file `Logic/SpendAggregation.swift` (no SwiftUI, no ModelContext) operating on existing `Transaction`/`ExpenseCategory` models, mirroring the existing `Logic/` layer. Fully unit-tested; consumed by the Insights views in later PRs.

**Tech Stack:** Swift, SwiftData models (read-only), XCTest. iOS 18.

---

## Conventions
- **Branch:** `feature/insights-logic` off `main`. No git worktrees (CLAUDE.md).
- **Commits:** present-tense; append `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- **Run a test (local):**
  ```bash
  xcodebuild test -project plop/plop.xcodeproj -scheme plop \
    -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
    -parallel-testing-enabled NO -only-testing:plopTests/SpendAggregationTests/METHOD
  ```
- If a run fails with a bogus crash (EXC_BAD_ACCESS / "early unexpected exit"), it's
  likely stale state — see `memory/xcode-build-sim-gotchas.md` (clean DerivedData / erase sim).
- New code is internal (no access modifier) so `@testable import plop` sees it.

## File Structure
- Create `plop/plop/Logic/SpendAggregation.swift` — `CategorySpend`, `spendByCategory`,
  `totalSpent`, `DonutSlice`, `donutSlices`.
- Create `plop/plopTests/SpendAggregationTests.swift` — tests (reuses `TestSupport.swift`
  helpers `fixedCalendar`, `makeDate`, and `PeriodFilter`).

---

### Task 1: `CategorySpend` + `spendByCategory`

**Files:**
- Create: `plop/plopTests/SpendAggregationTests.swift`
- Create: `plop/plop/Logic/SpendAggregation.swift`

- [ ] **Step 1: Branch**
```bash
git checkout main && git pull --ff-only && git checkout -b feature/insights-logic
```

- [ ] **Step 2: Write the failing tests**

`plop/plopTests/SpendAggregationTests.swift`:
```swift
import XCTest
@testable import plop

final class SpendAggregationTests: XCTestCase {
    private let cal = fixedCalendar()
    private var monthRange: ClosedRange<Date> {
        PeriodFilter.month.range(containing: makeDate(2026, 5, 15, calendar: cal), calendar: cal)
    }
    private func cat(_ name: String, _ color: String) -> ExpenseCategory {
        ExpenseCategory(name: name, symbolName: "tag", colorHex: color)
    }

    func test_spendByCategory_sumsExpensesPerCategory_largestFirst() {
        let food = cat("Food", "#FFEBCC")
        let school = cat("School", "#8CC0EB")
        let txs = [
            Transaction(amount: 10, type: .expense, date: makeDate(2026, 5, 10, calendar: cal), category: food),
            Transaction(amount: 5,  type: .expense, date: makeDate(2026, 5, 11, calendar: cal), category: food),
            Transaction(amount: 30, type: .expense, date: makeDate(2026, 5, 12, calendar: cal), category: school),
        ]
        let result = spendByCategory(txs, in: monthRange)
        XCTAssertEqual(result.map(\.name), ["School", "Food"])   // largest first
        XCTAssertEqual(result.first?.amount, Decimal(30))
        XCTAssertEqual(result.last?.amount, Decimal(15))
    }

    func test_spendByCategory_excludesIncome() {
        let school = cat("School", "#8CC0EB")
        let txs = [
            Transaction(amount: 1000, type: .income,  date: makeDate(2026, 5, 5, calendar: cal), category: school),
            Transaction(amount: 20,   type: .expense, date: makeDate(2026, 5, 6, calendar: cal), category: school),
        ]
        let result = spendByCategory(txs, in: monthRange)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.amount, Decimal(20))
    }

    func test_spendByCategory_excludesOutOfRange() {
        let food = cat("Food", "#FFEBCC")
        let txs = [
            Transaction(amount: 20, type: .expense, date: makeDate(2026, 5, 6, calendar: cal), category: food),
            Transaction(amount: 99, type: .expense, date: makeDate(2026, 3, 1, calendar: cal), category: food),
        ]
        XCTAssertEqual(totalSpentMagnitude(spendByCategory(txs, in: monthRange)), Decimal(20))
    }

    func test_spendByCategory_bucketsUncategorized() {
        let txs = [
            Transaction(amount: 7, type: .expense, date: makeDate(2026, 5, 6, calendar: cal), category: nil),
        ]
        let result = spendByCategory(txs, in: monthRange)
        XCTAssertEqual(result.first?.id, "__uncategorized__")
        XCTAssertEqual(result.first?.name, "Uncategorized")
        XCTAssertEqual(result.first?.amount, Decimal(7))
    }

    // local helper for this task's range test (totalSpent arrives in Task 2)
    private func totalSpentMagnitude(_ s: [CategorySpend]) -> Decimal {
        s.reduce(Decimal(0)) { $0 + $1.amount }
    }
}
```

- [ ] **Step 3: Run to verify it fails**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO \
  -only-testing:plopTests/SpendAggregationTests/test_spendByCategory_sumsExpensesPerCategory_largestFirst
```
Expected: FAIL — `cannot find 'spendByCategory'` / `'CategorySpend'`.

- [ ] **Step 4: Write minimal implementation**

`plop/plop/Logic/SpendAggregation.swift`:
```swift
import Foundation

let uncategorizedSpendID = "__uncategorized__"
let uncategorizedSpendColor = "#C9CDD2"   // neutral gray

struct CategorySpend: Identifiable, Equatable {
    let id: String        // category name, or uncategorizedSpendID
    let name: String
    let colorHex: String
    let amount: Decimal
}

/// Expenses only, within `range`, summed per category, largest first
/// (ties broken by name for a stable order).
func spendByCategory(_ txs: [Transaction], in range: ClosedRange<Date>) -> [CategorySpend] {
    var bucket: [String: (name: String, color: String, amount: Decimal)] = [:]
    for tx in txs where tx.type == .expense && range.contains(tx.date) {
        let key = tx.category?.name ?? uncategorizedSpendID
        let name = tx.category?.name ?? "Uncategorized"
        let color = tx.category?.colorHex ?? uncategorizedSpendColor
        var entry = bucket[key] ?? (name, color, Decimal(0))
        entry.amount += tx.amount
        bucket[key] = entry
    }
    return bucket
        .map { CategorySpend(id: $0.key, name: $0.value.name, colorHex: $0.value.color, amount: $0.value.amount) }
        .sorted { $0.amount != $1.amount ? $0.amount > $1.amount : $0.name < $1.name }
}
```

- [ ] **Step 5: Run to verify it passes, then commit**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/SpendAggregationTests
```
Expected: PASS (4 tests).

```bash
git add plop/plop/Logic/SpendAggregation.swift plop/plopTests/SpendAggregationTests.swift
git commit -m "Add spendByCategory aggregation with tests"
```

---

### Task 2: `totalSpent`

**Files:**
- Modify: `plop/plopTests/SpendAggregationTests.swift`
- Modify: `plop/plop/Logic/SpendAggregation.swift`

- [ ] **Step 1: Add the failing tests**

Add inside `SpendAggregationTests` (and delete the temporary `totalSpentMagnitude`
helper, replacing its use in `test_spendByCategory_excludesOutOfRange` with `totalSpent`):
```swift
    func test_totalSpent_sumsAllSlices() {
        let spend = [
            CategorySpend(id: "a", name: "A", colorHex: "#000000", amount: 30),
            CategorySpend(id: "b", name: "B", colorHex: "#000000", amount: 12),
        ]
        XCTAssertEqual(totalSpent(spend), Decimal(42))
    }

    func test_totalSpent_emptyIsZero() {
        XCTAssertEqual(totalSpent([]), Decimal(0))
    }
```
Then in `test_spendByCategory_excludesOutOfRange`, change
`totalSpentMagnitude(spendByCategory(...))` to `totalSpent(spendByCategory(...))`
and remove the private `totalSpentMagnitude` method.

- [ ] **Step 2: Run to verify it fails**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/SpendAggregationTests/test_totalSpent_sumsAllSlices
```
Expected: FAIL — `cannot find 'totalSpent'`.

- [ ] **Step 3: Write minimal implementation**

Append to `plop/plop/Logic/SpendAggregation.swift`:
```swift
func totalSpent(_ spend: [CategorySpend]) -> Decimal {
    spend.reduce(Decimal(0)) { $0 + $1.amount }
}
```

- [ ] **Step 4: Run to verify it passes, then commit**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/SpendAggregationTests
```
Expected: PASS (6 tests).

```bash
git add plop/plop/Logic/SpendAggregation.swift plop/plopTests/SpendAggregationTests.swift
git commit -m "Add totalSpent helper"
```

---

### Task 3: `DonutSlice` + `donutSlices`, then green + PR

**Files:**
- Modify: `plop/plopTests/SpendAggregationTests.swift`
- Modify: `plop/plop/Logic/SpendAggregation.swift`

- [ ] **Step 1: Add the failing tests**

Add inside `SpendAggregationTests`:
```swift
    func test_donutSlices_emptyWhenNoSpend() {
        XCTAssertTrue(donutSlices(from: []).isEmpty)
    }

    func test_donutSlices_singleSliceSpansRingMinusGap() {
        let spend = [CategorySpend(id: "a", name: "A", colorHex: "#000000", amount: 10)]
        let slices = donutSlices(from: spend, gap: 0.02)
        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices[0].start, 0.01, accuracy: 0.0001)   // gap/2
        XCTAssertEqual(slices[0].end, 0.99, accuracy: 0.0001)     // 1 - gap/2
    }

    func test_donutSlices_cumulativeAndOrdered() {
        let spend = [
            CategorySpend(id: "a", name: "A", colorHex: "#000000", amount: 75),
            CategorySpend(id: "b", name: "B", colorHex: "#111111", amount: 25),
        ]
        let slices = donutSlices(from: spend, gap: 0.0)   // no gap → exact boundaries
        XCTAssertEqual(slices.map(\.id), ["a", "b"])
        XCTAssertEqual(slices[0].start, 0.0,  accuracy: 0.0001)
        XCTAssertEqual(slices[0].end,   0.75, accuracy: 0.0001)
        XCTAssertEqual(slices[1].start, 0.75, accuracy: 0.0001)
        XCTAssertEqual(slices[1].end,   1.0,  accuracy: 0.0001)
    }
```

- [ ] **Step 2: Run to verify it fails**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/SpendAggregationTests/test_donutSlices_emptyWhenNoSpend
```
Expected: FAIL — `cannot find 'donutSlices'` / `'DonutSlice'`.

- [ ] **Step 3: Write minimal implementation**

Append to `plop/plop/Logic/SpendAggregation.swift`:
```swift
struct DonutSlice: Identifiable, Equatable {
    let id: String
    let colorHex: String
    let start: Double   // fraction of the ring [0,1]
    let end: Double
}

/// Cumulative start/end ring fractions per slice, inset by `gap` between slices.
/// Tiny slices clamp to zero length (start == end) rather than going negative.
func donutSlices(from spend: [CategorySpend], gap: Double = 0.012) -> [DonutSlice] {
    let total = totalSpent(spend)
    guard total > 0 else { return [] }
    let totalDouble = NSDecimalNumber(decimal: total).doubleValue

    var cursor = 0.0
    var slices: [DonutSlice] = []
    for s in spend {
        let frac = NSDecimalNumber(decimal: s.amount).doubleValue / totalDouble
        let start = cursor + gap / 2
        let end = max(start, cursor + frac - gap / 2)
        slices.append(DonutSlice(id: s.id, colorHex: s.colorHex, start: start, end: end))
        cursor += frac
    }
    return slices
}
```

- [ ] **Step 4: Run the full SpendAggregation suite**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/SpendAggregationTests
```
Expected: PASS (9 tests).

- [ ] **Step 5: Run the WHOLE test target + lint**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests
swiftlint lint
```
Expected: all tests pass (existing 32 + 9 new = 41); no lint errors.

- [ ] **Step 6: Commit, push, open PR**

```bash
git add plop/plop/Logic/SpendAggregation.swift plop/plopTests/SpendAggregationTests.swift
git commit -m "Add donutSlices ring geometry"
git push -u origin feature/insights-logic
```
Then open a PR `feature/insights-logic` → `main` via the GitHub web UI (gh not installed).
Confirm CI (SwiftLint + plopTests) is green before requesting review.

---

## Self-review notes
- **Spec coverage:** `CategorySpend`/`spendByCategory` (expenses-only, grouping,
  largest-first, uncategorized bucket, range filter) — T1; `totalSpent` — T2;
  `DonutSlice`/`donutSlices` (empty, single, cumulative, gaps) — T3. No UI (correct for PR1).
- **Determinism:** sort ties broken by name; date tests use `fixedCalendar` + `PeriodFilter`.
- **Type consistency:** `CategorySpend(id:name:colorHex:amount:)`, `DonutSlice(id:colorHex:start:end:)`,
  `spendByCategory(_:in:)`, `totalSpent(_:)`, `donutSlices(from:gap:)` used identically across tasks.
- **Decimal vs Double:** money stays `Decimal`; ring fractions are `Double` (geometry only).
