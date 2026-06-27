# Add Recurring Payment from Settings — Design

Status: Approved · Date: 2026-06-27

## Goal

Let the user create a recurring payment from Settings → Recurring payments
(`RecurringRulesSheet`), which today only lists rules and lets you stop them.

## Decision (approved)

**Reuse the full Entry page.** The Entry page already has the amount keypad, category picker,
note, date, interval picker, validation, success haptic, and — on save with a recurrence — the
`RecurringActions.create` path. A "+ Add recurring payment" button in the Recurring sheet opens
`EntryView` pre-set to a recurring interval; saving creates the rule. No duplicated input UI.

Default interval: **Monthly** (user can change it on the Entry page before saving).

## Components

### `EntryView` (`Views/Entry/EntryView.swift`)
Add an optional initial recurrence:
```swift
var initialRecurrence: RecurrenceInterval = .none
```
In `prefillIfEditing()`'s add branch (`editing == nil`), apply it so a fresh page opens already
marked recurring:
```swift
guard let tx = editing else {
    input = AmountInput(maxFractionDigits: currencyFractionDigits(currencyCode: currencyCode))
    recurrence = initialRecurrence
    return
}
```
Everything else is unchanged. With `recurrence != .none`, the page shows the active recurring
icon + "Repeats …" pill, and on save runs the existing recurring-confirm →
`RecurringActions.create` (rule + first occurrence) + success haptic.

### `RecurringRulesSheet` (`Views/Settings/RecurringRulesSheet.swift`)
- `@State private var addingRecurring = false`.
- A pinned **"Add recurring payment"** button at the bottom of the root `VStack` (after the
  list/empty-state branch), styled like Manage categories' add button (solid accent,
  `Palette.tileInk` text, radius 14):
  ```swift
  private var addButton: some View {
      Button { addingRecurring = true } label: {
          HStack(spacing: 8) {
              Image(systemName: "plus").font(.system(size: 17, weight: .semibold))
              Text("Add recurring payment").font(.system(size: 17, weight: .semibold))
          }
          .foregroundStyle(Palette.tileInk).frame(maxWidth: .infinity).padding(.vertical, 15)
          .background(Palette.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 18)
  }
  ```
  It shows in both the populated and empty states (so the first rule can be added).
- Present the Entry page as a nested full-screen cover (the same mechanism Home uses to edit a
  transaction):
  ```swift
  .fullScreenCover(isPresented: $addingRecurring) {
      EntryView(initialRecurrence: .monthly)
  }
  ```
  On save/dismiss it returns to the sheet, whose `@Query rules` refreshes and shows the new rule.

## Data flow

Entry save → `TransactionDraft(recurrence: .monthly, …)` → `RecurringActions.create(from:in:)`
inserts the `RecurringRule` + its first `Transaction` occurrence (unchanged path). The sheet's
`@Query(sort: \RecurringRule.createdAt)` re-fetches and the row appears.

## Behaviour notes

- Creating here also logs the first occurrence transaction — identical to creating a recurring
  payment from the normal add flow (consistent, not new behaviour).
- The Entry page has its own ×/dismiss; it is presented over the Settings popup.
- If the user clears the interval to "one-time" before saving, it creates a normal transaction
  (no rule) — acceptable; it's the same page semantics as everywhere else.

## Testing

- **No new unit tests** — reuses the already-tested `RecurringActions.create`; the
  `initialRecurrence` parameter is presentation only.
- Existing suite (188) stays green; build succeeds; SwiftLint at baseline (19/0).
- **Sim check:** Settings → Recurring payments → "Add recurring payment" opens the Entry page
  pre-set to Monthly; entering an amount + category and saving creates a rule that appears in
  the list; the button is present in the empty state too; light + dark.

## Scope

**In:** `EntryView` (one parameter + one line in `prefillIfEditing`); `RecurringRulesSheet`
(add button + state + cover). **Out:** editing an existing rule; a dedicated recurring-only
form; changing `RecurringActions`/the data model.

Single PR: `feature/add-recurring-from-settings`.
