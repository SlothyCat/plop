# Recurring Payments — SP4 Design

Status: Approved (brainstorm complete) · Date: 2026-06-19

Companion to `requirements.md`. The cancel action, the sheet, the Settings row,
testing, and scope. Completes Feature 2.

## Architecture

```
plop/
  Data/
    RecurringActions.swift        (+ cancel(_:in:) — deletes the rule)
  Views/Settings/
    RecurringRulesSheet.swift     (NEW: list active rules + Cancel + empty state)
    SettingsView.swift            (+ "Recurring payments" row presenting the sheet)
```

One PR. Reuses SP1 model (`.nullify` occurrences), SP3 `recurringSummary`, and the
currency/`Palette` helpers.

## `RecurringActions.cancel`

```swift
/// Cancels a recurrence: removes the rule so nothing new generates. Past occurrences
/// remain (the occurrences relationship is .nullify — their `rule` link clears).
static func cancel(_ rule: RecurringRule, in context: ModelContext) {
    context.delete(rule)
}
```
No `isActive` flip, no occurrence deletion. The SP2 engine then has no rule to act on.

## `RecurringRulesSheet`

```swift
struct RecurringRulesSheet: View {
    @Query(sort: \RecurringRule.createdAt) private var rules: [RecurringRule]
    @Environment(\.modelContext) private var modelContext
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @State private var pendingCancel: RecurringRule?
    var onDone: () -> Void
    ...
}
```
- **Header:** "Recurring payments" + a short subtitle.
- **List:** one row per rule —
  - leading: the category color/icon tile if `rule.category` set, else a repeat glyph;
  - title: `rule.note` (fallback to the category name, else "Recurring payment");
  - subtitle: `recurringSummary(interval: rule.interval, date: rule.startDate)`
    ("monthly on the 18th"…);
  - trailing: `formattedMoney(rule.amount, currencyCode: currencyCode)`.
  - A trailing **swipe action** "Stop" (destructive) sets `pendingCancel = rule`.
- **Confirm:** `.confirmationDialog(..., isPresented:, presenting: pendingCancel)` →
  **Stop recurring** (`role: .destructive`, calls `RecurringActions.cancel`) and
  **Keep** (cancel). Message: "Future charges stop; past ones stay."
- **Empty state:** when `rules.isEmpty` — a centered "No recurring payments yet."
- **Done** button dismisses (`onDone()`); light theme, standard sheet detent.

(The Settings call site passes `onDone: { showingRecurring = false }`, matching the
Export/Appearance sheet pattern.)

## `SettingsView` row

In the `Section("Preferences")`, add (e.g. after Currency or Theme):
```swift
                    Button {
                        showingRecurring = true
                    } label: {
                        HStack {
                            Label("Recurring payments", systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
```
Plus `@State private var showingRecurring = false` and, alongside the other `.sheet`
modifiers on the `List`:
```swift
            .sheet(isPresented: $showingRecurring) {
                RecurringRulesSheet { showingRecurring = false }
            }
```

## Testing

- `RecurringActionsTests` (extend): `cancel` removes the rule (`fetch RecurringRule`
  empty) and **keeps its occurrence** (`fetch Transaction` still 1; that tx's `rule`
  is nil afterward).
- `RecurringRulesSheet` + the Settings row via `#Preview` + simulator (no view unit
  tests). Sim check: a rule appears, swipe → Stop → confirm → it disappears from the
  list and its past transaction remains in Home; empty state shows when none.

## Scope (restated)

Manage/cancel only. No resume/stopped state, no occurrence deletion on cancel, no
in-place rule editor, no edit-one-vs-series. With this, Recurring payments (SP1–SP4)
is complete.
