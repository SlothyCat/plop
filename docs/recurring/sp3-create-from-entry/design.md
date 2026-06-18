# Recurring Payments — SP3 Design

Status: Approved (brainstorm complete) · Date: 2026-06-18

Companion to `requirements.md`. The create action, the Entry wiring + disclosure, the
summary helper, testing, and scope.

## Architecture

```
plop/
  Data/
    RecurringActions.swift     (NEW: create(from:in:calendar:) → rule + first occurrence)
  Logic/
    RecurringCopy.swift        (NEW pure: recurringSummary(interval:date:calendar:) -> String)
  Views/Entry/
    EntryView.swift            (confirm() branch + recurring-confirm dialog + specific chip)
```

One PR. Reuses SP1 (`RecurringRule`) and the SP2 engine (unchanged — it just keeps
generating from the rule SP3 creates).

## `RecurringActions.swift`

```swift
import Foundation
import SwiftData

/// Ledger mutations for recurring rules (mirrors TransactionActions).
enum RecurringActions {
    /// Creates a rule from a recurring draft and inserts its first occurrence
    /// (the entered transaction). anchorDay = the entry date's day-of-month;
    /// lastGeneratedDate = the entry date so SP2 resumes from the next occurrence.
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
> `draft.recurrence` is guaranteed ≠ `.none` on this path (EntryView only calls it for
> recurring new entries). The first occurrence's `date` keeps the entered date/time;
> `lastGeneratedDate` is start-of-day to align with the schedule's normalized dates.

## `RecurringCopy.swift` (pure)

```swift
/// Human summary of a rule's cadence for the chip + disclosure, e.g.
/// "monthly on the 18th", "weekly on Thursdays", "daily", "yearly on Jun 18".
func recurringSummary(interval: RecurrenceInterval, date: Date,
                      calendar: Calendar = .current) -> String
```
- monthly → "monthly on the {ordinal day}" (e.g. "18th").
- weekly → "weekly on {weekday plural}" (e.g. "Thursdays").
- daily → "daily".
- yearly → "yearly on {Mon d}" (e.g. "Jun 18").
- none → "" (defensive).
Uses `DateFormatter`/ordinal formatting with the supplied calendar; pure + tested.

## `EntryView` changes

- **Chip:** the existing `if recurrence != .none { … "Repeats \(recurrence.rawValue)" }`
  becomes `Text("Repeats \(recurringSummary(interval: recurrence, date: date))")`.
- **Confirm flow:** `confirm()` today builds a draft and adds/updates. New behavior:
  - `editing == nil && recurrence != .none` → set `@State showingRecurringConfirm = true`
    (don't save yet).
  - The confirm dialog (`.confirmationDialog`/`.alert`) shows
    `"This repeats \(recurringSummary(...)) until you stop it."` with **Create**
    (calls `performSave()`) and **Cancel**.
  - All other cases (one-off new, or any edit) call `performSave()` directly.
- **`performSave()`** (extracted from today's `confirm` body):
  - `editing` set → `TransactionActions.update(tx, with: draft)` (unchanged).
  - new + recurring → `RecurringActions.create(from: draft, in: modelContext)`.
  - new + one-off → `TransactionActions.add(draft, in: modelContext)` (unchanged).
  - then `dismiss()`.

Edit mode is intentionally untouched (series editing is SP4).

## Testing

- `RecurringActionsTests` (in-memory container):
  - `create` makes a rule with `interval`, `startDate == draft.date`, `anchorDay ==`
    entry day-of-month, amount/type/note/category copied, `isActive == true`.
  - first occurrence inserted + linked (`rule.occurrences.count == 1`,
    `tx.rule === rule`, `recurrence == interval`, `date == draft.date`).
  - `lastGeneratedDate == startOfDay(draft.date)`.
  - **no double-create:** after `create`, `RecurringGenerator.generate(now: same day)`
    returns 0.
- `RecurringCopyTests` (pure, fixed calendar): each interval's summary string
  (monthly ordinal, weekly weekday plural, daily, yearly, none→"").
- `EntryView` chip + dialog via `#Preview` + simulator (no view unit tests).

## Out of scope (restated)

Manage/stop, edit-series, edit-one-vs-series, turning an existing tx into a series,
global default billing day. SP3 is create-from-Entry only; the edit path is unchanged.
