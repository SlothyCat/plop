# Keyboard Dismiss + Insights Legend Icons — Design

Status: Approved · Date: 2026-06-27

Two small, independent fixes in one PR (`fix/keyboard-and-legend-icons`).

## 1. Tap-to-dismiss the number keypad

**Problem:** the budget/amount fields use `.keyboardType(.decimalPad)`, which has no Return key,
and the popups aren't scrollable — so once the keypad is up there's no way to dismiss it.

**Fix:** a reusable modifier that resigns first responder when the user taps an empty
(non-interactive) area. Buttons and text fields keep handling their own taps.

`plop/plop/Views/Common/KeyboardDismiss.swift`:
```swift
import SwiftUI
import UIKit

extension View {
    /// Dismisses the keyboard when the user taps an empty area of this view. Interactive
    /// controls (buttons, text fields) keep handling their own taps.
    func dismissKeyboardOnTap() -> some View {
        contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}
```

Applied to the root container of every number-pad popup (scope = all three, approved):
`CategoryFormView`, `BudgetView` (Settings → Set budget), `CategoryBudgetSheet` (Insights).

## 2. Category icon in the Insights legend rows

**Problem:** the breakdown/budget legends show a plain colour square; the user wants the
category's icon (emoji or SF Symbol), matching the picker / Manage rows.

**Fix:** pass `categories: [ExpenseCategory]` into `SpendLegend` and `BudgetLegend`; build a
name→category lookup and render `CategoryIconView` on a small coloured tile in place of the
14×14 square. Uncategorized (no matching category) falls back to a neutral glyph.

- `SpendLegend` / `BudgetLegend`: add `var categories: [ExpenseCategory] = []`; replace the
  `RoundedRectangle(...).fill(Color(hex:)).frame(14×14)` swatch with:
  ```swift
  CategoryIconView(category: lookup[<row.id>], fallbackSymbol: "tray")
      .font(.system(size: 15)).foregroundStyle(Palette.tileInk)
      .frame(width: 30, height: 30)
      .background(Color(hex: <row.colorHex>), in: RoundedRectangle(cornerRadius: 9))
  ```
  where `lookup = Dictionary(categories.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })`.
  Nudge the inter-row divider `.padding(.leading, 26)` → `44` to sit under the text.
- `InsightsView`: pass `categories: categories` to both legend call sites.

No changes to the aggregation value types (`CategorySpend`, `CategoryBudgetProgress`) or their
tests — the icon is resolved in the view from the existing `categories` list.

## Testing

- No unit tests — both are view-layer changes (no logic). Existing suite (188) stays green;
  build succeeds; SwiftLint at baseline (19/0).
- **Sim/device check:** the keypad dismisses on a background tap in all three popups; the
  Insights breakdown + budget legends show each category's emoji/symbol on its colour tile,
  with a neutral fallback for uncategorized; light + dark.

## Scope

**In:** the reusable modifier + its 3 applications; `categories` into the 2 legends + icon tile;
`InsightsView` wiring. **Out:** the custom Entry keypad (no system keyboard); aggregation types.
