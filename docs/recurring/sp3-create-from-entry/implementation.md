# Recurring Payments SP3 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a new Entry create a recurring rule (when its interval ≠ none), with a pre-save disclosure and a specific cadence chip. Create-only; editing/stop/series stay for SP4.

**Architecture:** A pure `recurringSummary` copy helper, a `RecurringActions.create` ledger action (rule + first occurrence), and an `EntryView` confirm split (`performSave` + a recurring confirmation dialog). Reuses SP1 model + SP2 engine unchanged.

**Tech Stack:** Swift, SwiftData, SwiftUI, XCTest. iOS 18. No new deps.

Single PR on branch `feature/recurring-sp3` (off `main`, which has SP1+SP2).

---

## File structure

- **Create** `plop/plop/Logic/RecurringCopy.swift` — pure `recurringSummary(...)`.
- **Create** `plop/plopTests/RecurringCopyTests.swift`.
- **Create** `plop/plop/Data/RecurringActions.swift` — `create(from:in:calendar:)`.
- **Create** `plop/plopTests/RecurringActionsTests.swift`.
- **Modify** `plop/plop/Views/Entry/EntryView.swift` — chip text, confirm split, dialog.

### Verified existing context

- `EntryView.confirm()` builds a `TransactionDraft(amount:type:date:note:recurrence:category:)` and calls `TransactionActions.add`/`.update`; has `@State private var recurrence`, `date`, `note`, `mode`, `input`, `selected`, `editing`, `modelContext`, `dismiss`.
- The chip: `if recurrence != .none { Button { recurOpen = true } label: { Label("Repeats \(recurrence.rawValue)", systemImage: "arrow.triangle.2.circlepath") … } }`.
- SP1 `RecurringRule(amount:type:note:interval:anchorDay:startDate:category:)`; SP2 `RecurringGenerator.generate(in:now:calendar:)`; `makeInMemoryContainer()` registers RecurringRule.

### Test / build commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests/RecurringCopyTests -only-testing:plopTests/RecurringActionsTests \
  -parallel-testing-enabled NO 2>&1 | tail -30

xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'

swiftlint lint
```

> SourceKit false positives expected. Lines ≤ 120. **No `// swiftlint:disable`; do not edit `.swiftlint.yml`.**

---

## Task 1: recurringSummary (pure copy)

**Files:**
- Create: `plop/plop/Logic/RecurringCopy.swift`
- Create: `plop/plopTests/RecurringCopyTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/RecurringCopyTests.swift`:

```swift
import XCTest
@testable import plop

final class RecurringCopyTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d))!
    }
    private func summary(_ i: RecurrenceInterval, _ d: Date) -> String {
        recurringSummary(interval: i, date: d, calendar: utc)
    }

    func test_none_isEmpty() {
        XCTAssertEqual(summary(.none, day(2026, 6, 18)), "")
    }

    func test_daily() {
        XCTAssertEqual(summary(.daily, day(2026, 6, 18)), "daily")
    }

    func test_weekly_usesWeekdayPlural() {
        // 2026-01-01 is a Thursday
        XCTAssertEqual(summary(.weekly, day(2026, 1, 1)), "weekly on Thursdays")
    }

    func test_monthly_usesOrdinalDay() {
        XCTAssertEqual(summary(.monthly, day(2026, 6, 18)), "monthly on the 18th")
        XCTAssertEqual(summary(.monthly, day(2026, 6, 1)), "monthly on the 1st")
        XCTAssertEqual(summary(.monthly, day(2026, 6, 2)), "monthly on the 2nd")
        XCTAssertEqual(summary(.monthly, day(2026, 6, 3)), "monthly on the 3rd")
    }

    func test_yearly_usesMonthDay() {
        XCTAssertEqual(summary(.yearly, day(2026, 6, 18)), "yearly on Jun 18")
    }
}
```

- [ ] **Step 2: Run the tests — confirm they FAIL to build.**

- [ ] **Step 3: Implement**

Create `plop/plop/Logic/RecurringCopy.swift`:

```swift
import Foundation

/// Human summary of a rule's cadence for the Entry chip + the save disclosure.
/// e.g. "monthly on the 18th", "weekly on Thursdays", "daily", "yearly on Jun 18".
/// Pure; uses the supplied calendar (en_US_POSIX for stable English).
func recurringSummary(interval: RecurrenceInterval, date: Date,
                      calendar: Calendar = .current) -> String {
    switch interval {
    case .none:
        return ""
    case .daily:
        return "daily"
    case .weekly:
        return "weekly on \(formatted(date, "EEEE", calendar))s"
    case .monthly:
        return "monthly on the \(ordinal(calendar.component(.day, from: date)))"
    case .yearly:
        return "yearly on \(formatted(date, "MMM d", calendar))"
    }
}

private func formatted(_ date: Date, _ pattern: String, _ calendar: Calendar) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = pattern
    return formatter.string(from: date)
}

private func ordinal(_ n: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
}
```

- [ ] **Step 4: Run the tests — confirm PASS** (5 tests). If `test_weekly` fails, the weekday for `day(2026,1,1)` under UTC is the source of truth — fix the implementation, not the test.

- [ ] **Step 5: SwiftLint** — no new violations; config untouched.

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Logic/RecurringCopy.swift plop/plopTests/RecurringCopyTests.swift
git commit -m "Add recurring cadence summary copy helper

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: RecurringActions.create

**Files:**
- Create: `plop/plop/Data/RecurringActions.swift`
- Create: `plop/plopTests/RecurringActionsTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/RecurringActionsTests.swift`:

```swift
import XCTest
import SwiftData
@testable import plop

@MainActor
final class RecurringActionsTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d))!
    }

    func test_create_buildsRuleAndFirstOccurrence() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let cat = ExpenseCategory(name: "Subs", symbolName: "tv", colorHex: "#FFF9D2")
        context.insert(cat)
        let draft = TransactionDraft(amount: 15, type: .expense, date: day(2026, 6, 18),
                                     note: "Netflix", recurrence: .monthly, category: cat)

        let rule = RecurringActions.create(from: draft, in: context, calendar: utc)

        XCTAssertEqual(rule.interval, .monthly)
        XCTAssertEqual(rule.anchorDay, 18)
        XCTAssertEqual(rule.startDate, day(2026, 6, 18))
        XCTAssertEqual(rule.amount, 15)
        XCTAssertEqual(rule.note, "Netflix")
        XCTAssertEqual(rule.category?.name, "Subs")
        XCTAssertTrue(rule.isActive)
        XCTAssertEqual(rule.lastGeneratedDate, day(2026, 6, 18))

        XCTAssertEqual(rule.occurrences.count, 1)
        let first = rule.occurrences.first
        XCTAssertEqual(first?.amount, 15)
        XCTAssertEqual(first?.recurrence, .monthly)
        XCTAssertEqual(first?.date, day(2026, 6, 18))
        XCTAssertEqual(first?.rule?.note, "Netflix")
    }

    func test_create_thenGenerateSameDay_noDoubleOccurrence() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let draft = TransactionDraft(amount: 9, type: .expense, date: day(2026, 6, 18),
                                     note: "Gym", recurrence: .monthly)
        _ = RecurringActions.create(from: draft, in: context, calendar: utc)

        let added = RecurringGenerator.generate(in: context, now: day(2026, 6, 18), calendar: utc)
        XCTAssertEqual(added, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Transaction>()).count, 1)
    }
}
```

- [ ] **Step 2: Run the tests — confirm they FAIL to build** (`RecurringActions` undefined).

- [ ] **Step 3: Implement**

Create `plop/plop/Data/RecurringActions.swift`:

```swift
import Foundation
import SwiftData

/// Ledger mutations for recurring rules (mirrors TransactionActions).
enum RecurringActions {
    /// Creates a rule from a recurring draft and inserts its first occurrence (the
    /// entered transaction). anchorDay = the entry date's day-of-month; lastGenerated
    /// = the entry date so the SP2 engine resumes from the next occurrence.
    @discardableResult
    static func create(from draft: TransactionDraft, in context: ModelContext,
                       calendar: Calendar = .current) -> RecurringRule {
        let anchorDay = calendar.component(.day, from: draft.date)
        let rule = RecurringRule(amount: draft.amount, type: draft.type, note: draft.note,
                                 interval: draft.recurrence, anchorDay: anchorDay,
                                 startDate: draft.date, category: draft.category)
        context.insert(rule)

        let first = Transaction(amount: draft.amount, type: draft.type, date: draft.date,
                                note: draft.note, recurrence: draft.recurrence,
                                category: draft.category)
        first.rule = rule
        context.insert(first)

        rule.lastGeneratedDate = calendar.startOfDay(for: draft.date)
        return rule
    }
}
```

- [ ] **Step 4: Run the tests — confirm PASS** (2 tests). Fix the implementation (not the tests) if needed. (Note: the test builds `draft.date` as start-of-day, so `lastGeneratedDate == draft.date`.)

- [ ] **Step 5: SwiftLint** — no new violations; config untouched.

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Data/RecurringActions.swift plop/plopTests/RecurringActionsTests.swift
git commit -m "Add RecurringActions.create (rule + first occurrence)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: EntryView — chip, confirm split, disclosure

**Files:**
- Modify: `plop/plop/Views/Entry/EntryView.swift`

No unit tests (SwiftUI view — verify = builds).

- [ ] **Step 1: Add state + split confirm + dialog**

READ `EntryView.swift`. Make these edits:

(a) Add a state property near the other `@State` flags (e.g. after `recurOpen`):
```swift
    @State private var showingRecurringConfirm = false
```

(b) Replace the existing `confirm()` method with a split version:
```swift
    private func confirm() {
        guard canSave else { return }
        if editing == nil && recurrence != .none {
            showingRecurringConfirm = true
        } else {
            performSave()
        }
    }

    private func performSave() {
        let draft = TransactionDraft(amount: input.value, type: mode, date: date,
                                     note: note.trimmingCharacters(in: .whitespaces),
                                     recurrence: recurrence, category: selected)
        if let tx = editing {
            TransactionActions.update(tx, with: draft)
        } else if draft.recurrence != .none {
            RecurringActions.create(from: draft, in: modelContext)
        } else {
            TransactionActions.add(draft, in: modelContext)
        }
        dismiss()
    }
```

(c) Add a confirmation dialog modifier alongside the existing `.sheet(...)` modifiers
on the body (e.g. right after the last `.sheet`):
```swift
        .confirmationDialog("Recurring payment", isPresented: $showingRecurringConfirm,
                            titleVisibility: .visible) {
            Button("Create") { performSave() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This repeats \(recurringSummary(interval: recurrence, date: date)) "
                 + "until you stop it.")
        }
```

(d) Update the recurring chip text to the specific summary. Find
`Label("Repeats \(recurrence.rawValue)", systemImage: "arrow.triangle.2.circlepath")`
and change the title to:
```swift
                    Label("Repeats \(recurringSummary(interval: recurrence, date: date))",
                          systemImage: "arrow.triangle.2.circlepath")
```

Change nothing else.

- [ ] **Step 2: Verify the target builds**

Run `xcodebuild build …`. Expected `** BUILD SUCCEEDED **`. (Ignore SourceKit squiggles; if a real error is in a file you didn't touch, STOP and report BLOCKED.)

- [ ] **Step 3: SwiftLint** — no new violations.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Entry/EntryView.swift
git commit -m "Create recurring rule from Entry with pre-save disclosure

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` — all prior + `RecurringCopyTests` + `RecurringActionsTests`.

- [ ] **Step 2: Lint** — `swiftlint lint` → no new violations; `.swiftlint.yml` unchanged.

- [ ] **Step 3: Simulator smoke check (manual)**

Entry → set amount + category, pick a date, open the Repeat sheet → Monthly. The chip
reads "Repeats monthly on the {day}". Tap the confirm key → dialog "This repeats
monthly on the {day} until you stop it." → **Create** saves; the transaction appears
in Home with the "Repeats" row. Re-open the app (foreground) → no duplicate of the
first occurrence; next month's would appear once due. One-off entries save with no
dialog; editing an existing transaction is unchanged (no dialog, edits just it).

- [ ] **Step 4: Push + PR**

```bash
git push -u origin feature/recurring-sp3
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Recurring payments SP3: a new Entry with a repeat interval now creates a RecurringRule
(+ first occurrence) with the entry date's day as the anchor, after a pre-save
disclosure; the chip shows the specific cadence. Create-only — edit/stop/series are SP4.

## Testing
All unit tests pass (7 new); SwiftLint clean. Entry flow sim-verified.
```

---

## Self-review notes

- **Spec coverage:** `recurringSummary` for chip + dialog (Task 1, tested);
  `RecurringActions.create` building rule + first occurrence with anchor = entry day,
  lastGenerated set, no double-create (Task 2, tested incl. the SP2 generate check);
  Entry confirm split + disclosure dialog + specific chip (Task 3). Create-only; edit
  path untouched. Manage/stop/series = SP4 — absent.
- **Type consistency:** `recurringSummary(interval:date:calendar:)` and
  `RecurringActions.create(from:in:calendar:)` match the tests and the EntryView call
  sites; reuses `TransactionDraft`, `RecurringRule`, `RecurringGenerator`,
  `TransactionActions` as defined.
- **No placeholders / no disables / config untouched.**
- **Edit path:** SP3 only changes the NEW-entry branch; `editing != nil` still routes
  to `TransactionActions.update`.
