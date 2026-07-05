# Haptic Feedback — Design

Status: Approved · Date: 2026-06-25

## Goal

Confirm valid, committed user actions with a short vibration, so the haptic acts as a
"that worked" indicator. One uniform haptic across all actions; no in-app toggle (rely on the
system setting).

## Decisions (approved)

1. **Uniform haptic** — every action fires the same `.success` notification haptic. No tiering
   by action type.
2. **No in-app opt-out** — `UINotificationFeedbackGenerator` automatically no-ops when the user
   disables iOS Settings → Sounds & Haptics → System Haptics, so no extra Settings UI is built.
3. **Central service, called imperatively** — a one-line `Haptics.success()` at each action's
   commit point (chosen over `.sensoryFeedback`, which needs a trigger value plumbed into views
   that often dismiss on the same tap).

## Component

**New file:** `plop/plop/Services/Haptics.swift`

```swift
import UIKit

/// Fires the system "success" haptic to confirm a committed user action. Respects
/// iOS Settings → Sounds & Haptics → System Haptics automatically (the generator
/// no-ops when the user has disabled haptics), so there is no in-app toggle.
enum Haptics {
    @MainActor static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
```

`@MainActor` because UIKit feedback generators must be used from the main thread; all call
sites are SwiftUI button actions / view state changes, which are already main-actor.

## Behavior rules

- **Fire only on a valid, committed action** — after any `guard`/validation passes. Never on
  Cancel, the top-right ×, a drag-dismiss, or a failed/invalid attempt.
- **Async actions fire on success completion only** (Export, Bug report) — not when the button
  is tapped — so a failed or cancelled attempt does not buzz like it succeeded.
- **Change-only actions guard for an actual change** (Currency, Theme) — re-selecting the
  already-active value does not fire.
- **Exactly one** haptic per committed action.

## Call sites

Each is a single `Haptics.success()` (or via `.onChange` for the state-driven Export case) at
the commit point. The implementation plan pins exact lines.

| # | Action | File · commit point |
|---|--------|---------------------|
| 1 | Add / save an entry | `Views/Entry/EntryView.swift` → `performSave()` (covers plain add, edit-update, and recurring-rule creation, which all route through it) |
| 2 | Set a category budget (Insights) | `Views/Insights/CategoryBudgetSheet.swift` → `save()` (after `category.budget = …`) |
| 3 | Set the budget (Settings) | `Views/Settings/BudgetView.swift` → `save()` |
| 4 | Change currency | `Views/Settings/CurrencyView.swift` → the row `Button` action, **only when `code != currencyCode`** |
| 5 | Set the theme | `Views/Settings/AppearanceSheet.swift` → the card `Button` action, **only when `mode.rawValue != themeModeRaw`** |
| 6 | Create / save a category | `Views/Settings/CategoryFormView.swift` → its save path (just before `close()`, after `onSave?(…)`) |
| 7 | Set the recurring interval (Entry) | `Views/Entry/RecurringSheet.swift` → the option `Button` action (alongside `recurrence = option.value; close()`) |
| 8 | Stop a recurring rule (Settings) | `Views/Settings/RecurringRulesSheet.swift` → the "Stop recurring" destructive confirmation `Button` |
| 9 | Report a bug | `Views/Settings/BugReportSheet.swift` → the Mail composer completion handler, **only when the result is `.sent`** |
| 10 | Export to Google Sheets | `Views/Settings/ExportSheet.swift` → fire when `service.phase` becomes `.success` (via `.onChange(of: service.phase)`), not on the Export tap |

> Note on recurring: the actual recurring-rule **creation** happens inside `performSave()` (site
> #1) when an entry has a recurrence, so it is already covered there. Site #7 confirms picking
> the interval in the Entry sheet; site #8 confirms stopping a rule from Settings. There is no
> separate "edit rule" screen.

## Testing

- **No unit tests.** `Haptics` is a thin hardware wrapper and changes no business logic; this
  follows the project convention (logic via XCTest, views/effects via preview + device). There
  is nothing deterministic to assert without injecting a fake generator, which is not warranted
  for a 3-line wrapper.
- **The simulator does not produce haptics** — verify on a **physical device**: each of the 10
  actions buzzes once on success; Cancel / × / drag-dismiss and a cancelled Mail compose or a
  failed export do **not** buzz; re-selecting the current currency/theme does **not** buzz.
- **No regressions** — the existing suite (181 tests) must still pass; `xcodebuild build`
  succeeds; SwiftLint stays at baseline (19 / 0 serious).

## Scope

**In:** one new `Haptics` service + the 10 one-line call-site additions above.

**Out:** any tiering of haptic styles; an in-app haptics toggle / Settings row; haptics on
navigation, tab switches, keypad presses, or non-committal taps; the data layer
(`Data/*Actions.swift`) — haptics stay in the view layer.

## Decomposition

Small and cohesive — a **single PR** on `feature/haptics` off `main`:
- Task 1: add `Haptics.swift`.
- Task 2: wire the synchronous sites (1–8).
- Task 3: wire the async/state sites (9 Bug report `.sent`, 10 Export `.success`).
- Task 4: verify (build, tests, lint) + device smoke check + PR.
