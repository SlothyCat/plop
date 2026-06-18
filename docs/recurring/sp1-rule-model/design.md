# Recurring Payments — SP1 Design

Status: Approved (brainstorm complete) · Date: 2026-06-18

Companion to `requirements.md`. The model + migration, the anchor semantics, the
pure schedule core, testing, and what SP1 deliberately omits.

## Architecture

```
plop/
  Models/
    RecurringRule.swift     (NEW @Model: template + schedule state)
    Transaction.swift       (+ var rule: RecurringRule?)
  Logic/
    RecurringSchedule.swift (PURE: dueOccurrences(...) + anchor helpers)
```

One PR: model + additive migration + the pure schedule logic + tests. No engine,
no UI, no trigger.

## `RecurringRule.swift`

```swift
import Foundation
import SwiftData

/// A recurring-payment template + its scheduling state. Generated occurrences are
/// normal Transactions linked via `occurrences` (inverse: Transaction.rule).
@Model
final class RecurringRule {
    var amount: Decimal               // always positive; sign derived from `type`
    var type: TransactionType
    var note: String
    var interval: RecurrenceInterval  // never .none for a rule
    var anchorDay: Int                // day-of-month for .monthly; derived/ignored otherwise
    var startDate: Date
    var lastGeneratedDate: Date?      // nil until first generation (SP2)
    var isActive: Bool = true
    var createdAt: Date

    // Deleting a category nullifies the link (rule keeps running, "Uncategorized").
    @Relationship(deleteRule: .nullify)
    var category: ExpenseCategory?

    // Deleting/stopping a rule keeps its past occurrences (link nullified).
    // Inverse is inferred from Transaction.rule — declared on this side only to
    // avoid the SwiftData metadata-cycle trap.
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

`Transaction.swift` gains one stored property (additive):
```swift
    var rule: RecurringRule?
```
(Placed alongside `category`; no initializer change needed — it defaults to nil. The
existing `recurrence` field stays as-is for SP1.)

> SwiftData gotchas honored: non-optional `Decimal`; the inverse relationship is
> declared only on `RecurringRule.occurrences` (not on both sides); `RecurringRule`
> is a fresh, uniquely-named model. Migration is additive (new model + new optional
> property), so it's a lightweight automatic migration.

## `RecurringSchedule.swift` (pure core)

```swift
/// Occurrence dates due strictly after `lastGenerated` (or from the first occurrence
/// when nil) and on/before `asOf`, for the rule's interval + anchor. Pure. Returns
/// all due dates in ascending order (SP2 applies any catch-up cap and inserts).
func dueOccurrences(interval: RecurrenceInterval,
                    anchorDay: Int,
                    startDate: Date,
                    lastGenerated: Date?,
                    asOf: Date,
                    calendar: Calendar) -> [Date]
```

Internal helpers (also pure, individually testable):
- `firstOccurrence(interval:anchorDay:startDate:calendar:) -> Date` — the sequence's
  first date (monthly: first `anchorDay`-date ≥ startDate, clamped; others: startDate).
- `nextOccurrence(after:interval:anchorDay:calendar:) -> Date` — steps one interval,
  re-applying the anchor/clamp.

Algorithm: start at `firstOccurrence` (or the step after `lastGenerated`), then repeat
`nextOccurrence` collecting dates `≤ asOf`, skipping any `≤ lastGenerated`. All date
math uses the injected `calendar` (so tests pin UTC) and normalizes to the start-of-
day to avoid time-of-day drift; `interval == .none` returns `[]` defensively.

Clamping: monthly/yearly use `calendar.range(of: .day, in: .month, for:)` to cap the
day (e.g. anchor 31 in Feb → 28/29); leap Feb 29 yearly → Feb 28 in non-leap years.

## Testing

`RecurringScheduleTests` (XCTest, fixed `Calendar(identifier: .gregorian)` with UTC):
- **monthly clamp:** anchor 31, start Jan 31 → Jan 31, Feb 28, Mar 31, Apr 30…
- **monthly normal:** anchor 5 → the 5th each month; first ≥ startDate.
- **daily / weekly:** correct stride; weekly preserves the start weekday.
- **yearly leap:** start Feb 29 2024 → Feb 28 2025, Feb 28 2026, Feb 29 2028.
- **catch-up:** `lastGenerated` a year before `asOf` → every missed date, ascending.
- **dedup boundary:** a date exactly equal to `lastGenerated` is excluded.
- **nil lastGenerated:** sequence from the first occurrence.
- **asOf before first occurrence:** `[]`.
- **interval .none:** `[]`.

Model wiring (the relationship + additive migration) is validated by the suite
building/running against an in-memory container — no dedicated model unit test beyond
that; the schedule logic is the tested surface.

## Out of scope (restated)

No generation, no `lastGeneratedDate` advancement, no foreground trigger, no Entry or
Manage UI, no change to `Transaction.recurrence` behavior. SP2 consumes
`dueOccurrences` to insert and advance; SP3/SP4 add the UI.
