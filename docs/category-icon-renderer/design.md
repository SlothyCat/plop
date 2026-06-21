# Category Icon Renderer (Emoji icons PR1) — Design

Status: Approved (brainstorm complete) · Date: 2026-06-21

Companion to `requirements.md`. The model field, `CategoryIconView`, the eight adoptions,
testing, and scope.

## Architecture

```
plop/Models/ExpenseCategory.swift          (add `emoji` stored property + init param)
plop/Views/Common/CategoryIconView.swift   (new — emoji-or-symbol renderer)
plop/Views/Home/TxRow.swift                (adopt)
plop/Views/Entry/EntryView.swift           (adopt — selected-category row)
plop/Views/Entry/CategoryPickerSheet.swift (adopt)
plop/Views/Settings/RecurringRulesSheet.swift   (adopt)
plop/Views/Settings/BudgetView.swift            (adopt)
plop/Views/Settings/ManageCategoriesView.swift  (adopt)
plop/Views/Settings/ReassignCategorySheet.swift (adopt)
plop/Views/Insights/CategoryBudgetSheet.swift   (adopt)
```

## 1. Model

In `ExpenseCategory`, add the property after `symbolName` and a defaulted init param:
```swift
    var name: String
    var symbolName: String      // SF Symbol, e.g. "fork.knife"
    var emoji: String = ""      // non-empty ⇒ render this emoji instead of symbolName
    var colorHex: String        // e.g. "#FFEBCC"
    var budget: Decimal = 0
```
```swift
    init(name: String, symbolName: String, emoji: String = "", colorHex: String,
         budget: Decimal = 0) {
        self.name = name
        self.symbolName = symbolName
        self.emoji = emoji
        self.colorHex = colorHex
        self.budget = budget
    }
```
Existing call sites (`Seed/DefaultData`, `Previews/SampleData`, `CategoryActions.add`) omit
`emoji` → default `""`. The init keeps `colorHex`/`budget` labels in the same order, so those
call sites compile unchanged (they pass `colorHex:`/`budget:` by label).

> Migration: additive non-optional `String` with a default — the same shape as the existing
> `budget: Decimal = 0`, which migrated cleanly. No `VersionedSchema`/`MigrationPlan` needed;
> SwiftData backfills existing rows with `""`. (Verified by launching on a store seeded
> before the change — see Testing.)

## 2. CategoryIconView (new)

```swift
import SwiftUI

/// A category's icon: its emoji if set, otherwise its SF Symbol (or `fallbackSymbol` when
/// the category — or its symbol — is missing). Style from the call site: `.font` sizes both
/// emoji and symbol; `.foregroundStyle` tints the SF Symbol and is ignored by emoji.
struct CategoryIconView: View {
    let category: ExpenseCategory?
    var fallbackSymbol: String = "questionmark"

    var body: some View {
        if let emoji = category?.emoji, !emoji.isEmpty {
            Text(emoji)
        } else {
            Image(systemName: category?.symbolName ?? fallbackSymbol)
        }
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 16) {
        CategoryIconView(category: ExpenseCategory(name: "Food", symbolName: "fork.knife",
                                                   colorHex: "#FFEBCC"))
        CategoryIconView(category: ExpenseCategory(name: "Fun", symbolName: "tag.fill",
                                                   emoji: "🎉", colorHex: "#BFDDF0"))
        CategoryIconView(category: nil, fallbackSymbol: "questionmark")
    }
    .font(.system(size: 22)).foregroundStyle(Palette.tileInk).padding()
}
#endif
```
A non-optional category auto-promotes to the optional parameter, so both optional and
non-optional call sites use the same initializer.

## 3. Adoptions (preserve each site's modifiers)

Each change swaps only the `Image(systemName: …)` for `CategoryIconView(...)`; the
`.font/.foregroundStyle/.frame/.background/.overlay` around it stay exactly as they are.

**TxRow.swift** (~47):
```swift
Image(systemName: transaction.category?.symbolName ?? "questionmark")
```
→
```swift
CategoryIconView(category: transaction.category, fallbackSymbol: "questionmark")
```

**EntryView.swift** (~157, the selected-category button):
```swift
Image(systemName: selected?.symbolName ?? "square.grid.2x2")
```
→
```swift
CategoryIconView(category: selected, fallbackSymbol: "square.grid.2x2")
```

**CategoryPickerSheet.swift** (~55):
```swift
Image(systemName: category.symbolName)
```
→
```swift
CategoryIconView(category: category)
```

**RecurringRulesSheet.swift** (~63):
```swift
Image(systemName: rule.category?.symbolName ?? "arrow.triangle.2.circlepath")
```
→
```swift
CategoryIconView(category: rule.category, fallbackSymbol: "arrow.triangle.2.circlepath")
```

**BudgetView.swift** (~108):
```swift
Image(systemName: cat.symbolName)
```
→
```swift
CategoryIconView(category: cat)
```

**ManageCategoriesView.swift** (~74):
```swift
Image(systemName: c.symbolName)
```
→
```swift
CategoryIconView(category: c)
```

**ReassignCategorySheet.swift** (~56):
```swift
Image(systemName: target.symbolName)
```
→
```swift
CategoryIconView(category: target)
```

**CategoryBudgetSheet.swift** (~16):
```swift
Image(systemName: category.symbolName)
```
→
```swift
CategoryIconView(category: category)
```

(`CategoryFormView.swift` line ~95 `Image(systemName: symbol)` is the SF-glyph **picker** —
left unchanged; PR2 handles the editor.)

## Testing

- **Unit (optional, trivial):** `ExpenseCategory(name:symbolName:colorHex:).emoji == ""`
  (confirms the default) — add to an existing model/category test if convenient.
- **Views:** `#Preview` + simulator — every category surface still shows its SF glyph
  exactly as before (TxRow, Entry + picker, Insights legend + budget sheet, Budget, Manage,
  Reassign, Recurring), light + dark.
- **Migration (the key check):** run on a simulator that already has categories from a build
  **before** this change (don't erase the app) — confirm it launches, existing categories
  load, and their glyphs render. (Per the project's SwiftData gotchas, verify on a non-clean
  store, not just a fresh install.)

## Scope

Model field + `CategoryIconView` + eight one-line adoptions. No behavior change; nothing
sets `emoji` yet. One PR on `feature/category-icon-renderer`. PR2 adds the editor.
