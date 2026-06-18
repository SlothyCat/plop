# Recurring Payments SP2 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the generation engine that materializes due occurrences for active recurring rules, and trigger it on app launch/foreground. No UI.

**Architecture:** A `RecurringGenerator` that fetches active rules, uses SP1's `dueOccurrences` to insert one `Transaction` per due date, advances `lastGeneratedDate`, and saves — idempotently. Wired to `scenePhase == .active` on the main context.

**Tech Stack:** Swift, SwiftData, XCTest. iOS 18. No new deps.

Single PR on branch `feature/recurring-sp2` (off `main`, which has SP1).

---

## File structure

- **Create** `plop/plop/Logic/RecurringGenerator.swift` — the generator.
- **Create** `plop/plopTests/RecurringGeneratorTests.swift`.
- **Modify** `plop/plop/plopApp.swift` — `scenePhase` trigger on the scene.

### Verified existing context

- SP1 on `main`: `RecurringRule` (`amount/type/note/interval/anchorDay/startDate/lastGeneratedDate/isActive/category/occurrences`), `RecurringSchedule.dueOccurrences(interval:anchorDay:startDate:lastGenerated:asOf:calendar:)`, `Transaction.rule`.
- `Transaction(amount:type:date:note:recurrence:category:)` initializer.
- `makeInMemoryContainer()` registers `RecurringRule.self` (added in SP1).
- `plopApp` registers the schema and applies `.modelContainer(sharedModelContainer)` on the `WindowGroup`.

### Test / build commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests/RecurringGeneratorTests -parallel-testing-enabled NO 2>&1 | tail -30

xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'

swiftlint lint
```

> SourceKit false positives for new files are expected — the build/test run is the source of truth. Lines ≤ 120. **No `// swiftlint:disable`; do not edit `.swiftlint.yml`.**

---

## Task 1: RecurringGenerator + tests

**Files:**
- Create: `plop/plop/Logic/RecurringGenerator.swift`
- Create: `plop/plopTests/RecurringGeneratorTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/RecurringGeneratorTests.swift`:

```swift
import XCTest
import SwiftData
@testable import plop

@MainActor
final class RecurringGeneratorTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d))!
    }
    private func txCount(_ context: ModelContext) throws -> Int {
        try context.fetch(FetchDescriptor<Transaction>()).count
    }

    func test_generatesDueOccurrences_linksAndAdvances() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let rule = RecurringRule(amount: 15, type: .expense, note: "Netflix",
                                 interval: .monthly, anchorDay: 5, startDate: day(2026, 1, 5))
        context.insert(rule)

        let count = RecurringGenerator.generate(in: context, now: day(2026, 3, 10),
                                                calendar: utc)

        XCTAssertEqual(count, 3)                          // Jan 5, Feb 5, Mar 5
        XCTAssertEqual(try txCount(context), 3)
        XCTAssertEqual(rule.occurrences.count, 3)
        XCTAssertEqual(rule.lastGeneratedDate, day(2026, 3, 5))
    }

    func test_copiesRuleFields() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let food = ExpenseCategory(name: "Subs", symbolName: "tv", colorHex: "#FFF9D2")
        context.insert(food)
        let rule = RecurringRule(amount: 12, type: .expense, note: "Spotify",
                                 interval: .monthly, anchorDay: 1, startDate: day(2026, 1, 1),
                                 category: food)
        context.insert(rule)

        _ = RecurringGenerator.generate(in: context, now: day(2026, 1, 1), calendar: utc)

        let tx = try context.fetch(FetchDescriptor<Transaction>()).first
        XCTAssertEqual(tx?.amount, 12)
        XCTAssertEqual(tx?.type, .expense)
        XCTAssertEqual(tx?.note, "Spotify")
        XCTAssertEqual(tx?.category?.name, "Subs")
        XCTAssertEqual(tx?.recurrence, .monthly)
        XCTAssertEqual(tx?.date, day(2026, 1, 1))
    }

    func test_idempotent_secondRunInsertsNothing() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let rule = RecurringRule(amount: 9, type: .expense, note: "Gym",
                                 interval: .monthly, anchorDay: 1, startDate: day(2026, 1, 1))
        context.insert(rule)

        let first = RecurringGenerator.generate(in: context, now: day(2026, 3, 1), calendar: utc)
        let second = RecurringGenerator.generate(in: context, now: day(2026, 3, 1), calendar: utc)

        XCTAssertEqual(first, 3)
        XCTAssertEqual(second, 0)
        XCTAssertEqual(try txCount(context), 3)
    }

    func test_inactiveRule_skipped() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let rule = RecurringRule(amount: 9, type: .expense, note: "Old",
                                 interval: .monthly, anchorDay: 1, startDate: day(2026, 1, 1))
        rule.isActive = false
        context.insert(rule)

        let count = RecurringGenerator.generate(in: context, now: day(2026, 6, 1), calendar: utc)
        XCTAssertEqual(count, 0)
        XCTAssertEqual(try txCount(context), 0)
    }

    func test_nothingDue_noInsertNoAdvance() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let rule = RecurringRule(amount: 9, type: .expense, note: "Future",
                                 interval: .monthly, anchorDay: 5, startDate: day(2026, 6, 18))
        context.insert(rule)

        // now before the first occurrence (Jul 5)
        let count = RecurringGenerator.generate(in: context, now: day(2026, 6, 30), calendar: utc)
        XCTAssertEqual(count, 0)
        XCTAssertEqual(try txCount(context), 0)
        XCTAssertNil(rule.lastGeneratedDate)
    }
}
```

- [ ] **Step 2: Run the tests — confirm they FAIL to build** (`RecurringGenerator` undefined).

- [ ] **Step 3: Implement**

Create `plop/plop/Logic/RecurringGenerator.swift`:

```swift
import Foundation
import SwiftData

/// Materializes due occurrences for active recurring rules. Idempotent: advancing
/// each rule's `lastGeneratedDate` means repeated runs do nothing until a new
/// occurrence is due. Runs on the supplied (main) context.
enum RecurringGenerator {
    /// Inserts a Transaction for every occurrence due (per rule) on/before `now`,
    /// links it to its rule, advances `lastGeneratedDate`, and saves. Returns the
    /// number of transactions inserted.
    @discardableResult
    static func generate(in context: ModelContext, now: Date = .now,
                         calendar: Calendar = .current) -> Int {
        let active = FetchDescriptor<RecurringRule>(predicate: #Predicate { $0.isActive })
        let rules = (try? context.fetch(active)) ?? []

        var inserted = 0
        for rule in rules {
            let dates = RecurringSchedule.dueOccurrences(
                interval: rule.interval, anchorDay: rule.anchorDay, startDate: rule.startDate,
                lastGenerated: rule.lastGeneratedDate, asOf: now, calendar: calendar)
            for date in dates {
                let tx = Transaction(amount: rule.amount, type: rule.type, date: date,
                                     note: rule.note, recurrence: rule.interval,
                                     category: rule.category)
                tx.rule = rule
                context.insert(tx)
                inserted += 1
            }
            if let last = dates.last { rule.lastGeneratedDate = last }
        }
        if inserted > 0 { try? context.save() }
        return inserted
    }
}
```

- [ ] **Step 4: Run the tests — confirm PASS** (5 tests). Fix the implementation (not the tests) if any fail. If a bogus SwiftData crash appears, clean DerivedData + erase the sim (memory/xcode-build-sim-gotchas.md) before assuming a logic bug.

- [ ] **Step 5: SwiftLint** — no new violations; no disable comments; `.swiftlint.yml` unchanged.

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Logic/RecurringGenerator.swift plop/plopTests/RecurringGeneratorTests.swift
git commit -m "Add recurring generation engine (catch-up, idempotent)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: scenePhase trigger

**Files:**
- Modify: `plop/plop/plopApp.swift`

No unit test (app wiring — verified via build; the generator itself is tested in Task 1).

- [ ] **Step 1: Wire the trigger**

In `plop/plop/plopApp.swift`, add a `scenePhase` environment value and run the
generator when the scene becomes active. The `body` becomes:

```swift
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                RecurringGenerator.generate(in: sharedModelContainer.mainContext)
            }
        }
    }
```
(Leave `sharedModelContainer` and the schema unchanged. `@Environment(\.scenePhase)`
goes alongside the other properties on `plopApp`.)

- [ ] **Step 2: Verify the target builds**

Run `xcodebuild build …`. Expected `** BUILD SUCCEEDED **`.

> If Swift 6 concurrency flags `sharedModelContainer.mainContext` access inside the
> `onChange` closure (main-actor isolation), resolve WITHOUT a disable: the closure
> already runs on the main actor; if needed, wrap the call in `Task { @MainActor in … }`
> or read the context into a local first. Try the plain form first.

- [ ] **Step 3: SwiftLint** — no new violations.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/plopApp.swift
git commit -m "Run recurring generation on scene foreground

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
Expected: `** TEST SUCCEEDED **` — all prior + `RecurringGeneratorTests`.

- [ ] **Step 2: Lint** — `swiftlint lint` → no new violations; `.swiftlint.yml` unchanged.

- [ ] **Step 3: Simulator smoke check (optional, manual)**

Since no UI creates rules yet, this is optional: temporarily seed a `RecurringRule`
(e.g. in `SampleData`/a debug action), launch, and confirm occurrences appear in Home
and don't duplicate on backgrounding/foregrounding. Remove any temporary seed before
finishing. (The engine is covered by Task 1's tests; this just eyeballs the trigger.)

- [ ] **Step 4: Push + PR**

```bash
git push -u origin feature/recurring-sp2
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Recurring payments SP2: a generation engine that materializes due occurrences for
active rules (catch-up, idempotent) and a scenePhase .active trigger. Generated
occurrences are real transactions, so Home/Insights/budgets/export include them. No
UI yet — sets up SP3.

## Testing
All unit tests pass (5 new in RecurringGeneratorTests); SwiftLint clean.
```

---

## Self-review notes

- **Spec coverage:** `generate` fetches active rules, inserts due occurrences via
  `dueOccurrences`, copies fields incl. `recurrence = interval`, links `tx.rule`,
  advances `lastGeneratedDate`, saves (Task 1, tested: generate/copy/idempotent/
  inactive/nothing-due); `scenePhase .active` trigger on the main context (Task 2);
  generate-all catch-up (no cap). Out of scope (UI/Entry/manage) absent.
- **Type consistency:** `RecurringGenerator.generate(in:now:calendar:)` matches the
  tests; reuses `RecurringSchedule.dueOccurrences`, `RecurringRule`, `Transaction`
  initializer + `.rule` as defined in SP1.
- **No placeholders / no disables / config untouched.**
- **Idempotency** rests on `lastGeneratedDate` advancing + `dueOccurrences`'s
  exclusive lower bound — verified by `test_idempotent_secondRunInsertsNothing`.
