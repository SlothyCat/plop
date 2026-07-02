# Recurring Payments — SP2 Design

Status: Approved (brainstorm complete) · Date: 2026-06-18

Companion to `requirements.md`. The generator, the generated occurrence, the trigger,
idempotency, testing, and what SP2 omits.

## Architecture

```
plop/
  Logic/
    RecurringGenerator.swift   (NEW: fetch active rules → insert due occurrences → advance state)
    RecurringSchedule.swift    (SP1: dueOccurrences — reused)
  plopApp.swift                (+ scenePhase .active → run the generator on the main context)
```

One PR: the generator + the scene trigger + tests. No UI.

## `RecurringGenerator.swift`

```swift
import Foundation
import SwiftData

/// Materializes due occurrences for active recurring rules. Idempotent: advancing
/// each rule's lastGeneratedDate means repeated runs do nothing until a new
/// occurrence is due. Runs on the supplied (main) context.
enum RecurringGenerator {
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

Notes:
- Fetches only `isActive` rules (a stopped rule generates nothing; SP4 sets the flag).
- `lastGeneratedDate` advances to the **last due date** when ≥1 generated; left
  unchanged when nothing is due (so the next run rescans the small remaining window).
- `dueOccurrences` already guards `.none` and applies the exclusive `lastGenerated`
  boundary, so no extra dedup is needed.

## The generated occurrence

`Transaction(amount: rule.amount, type: rule.type, date: <due, start-of-day>,
note: rule.note, recurrence: rule.interval, category: rule.category)` with
`tx.rule = rule`. Because it's an ordinary `Transaction`, Home/Insights/budgets/
export include it automatically; `recurrence = interval` drives the existing
"Repeats" label.

## Trigger (`plopApp.swift`)

```swift
@Environment(\.scenePhase) private var scenePhase
...
WindowGroup { ContentView() }
    .modelContainer(sharedModelContainer)
    .onChange(of: scenePhase) { _, phase in
        if phase == .active {
            RecurringGenerator.generate(in: sharedModelContainer.mainContext)
        }
    }
```
`scenePhase` becomes `.active` on launch and on every return to foreground, so one
hook covers both. The generator is synchronous and fast; repeated `.active` events
are no-ops thanks to idempotency. No `BGTaskScheduler`, no server.

## Idempotency / double-run

- Same-session foreground churn: each run advances `lastGeneratedDate`; the next
  `dueOccurrences(lastGenerated: last, asOf: now)` returns `[]` until a new date is
  due. No guard flag needed.
- Same-day reopen: nothing new is due, so 0 inserted.
- Clock moving backward: `asOf < lastGeneratedDate` yields `[]` — safe (no negative
  generation, no mutation).

## Testing

`RecurringGeneratorTests` (XCTest, `@MainActor`, in-memory container + injected
`now` and UTC calendar):
- **inserts due + links + advances:** seed a monthly rule (lastGenerated nil), run
  with `now` a few months later → N transactions, each `tx.rule === rule`,
  `rule.lastGeneratedDate == last due date`.
- **field copy:** generated tx has the rule's amount/type/note/category and
  `recurrence == rule.interval`.
- **idempotent:** a second `generate` with the same `now` returns 0 and adds no rows.
- **catch-up:** an old `lastGeneratedDate` → multiple inserts, ascending dates.
- **inactive skipped:** `isActive == false` rule → 0.
- **nothing due:** `now` before the next occurrence → 0, `lastGeneratedDate`
  unchanged.

## Out of scope (restated)

No UI; SP3 adds rule creation from Entry (+ disclosure, global default day); SP4 adds
manage/stop and edit-one-vs-series. SP2 only makes existing active rules produce
transactions on open.

:::voice[Reflection]
_The generation engine was the trickiest logic in the app. What made it hard, and how did you get it right?_
:::
