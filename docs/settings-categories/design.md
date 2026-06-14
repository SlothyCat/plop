# Category Management — Design

Status: Approved (brainstorm complete) · Date: 2026-06-14

Companion to `requirements.md`. Architecture, the write path, screens/flows, testing,
and slicing.

## Architecture

```
plop/
  Data/
    CategoryActions.swift      (add / update / delete-with-reassign; in-memory tested)
  Logic/
    CategoryValidation.swift   (isCategoryNameAvailable — pure, tested)
  Models/
    CategoryIcons.swift        (curated [String] of SF Symbol names)
  Views/Settings/
    SettingsView.swift         (NavigationStack grouped list; Manage categories row)
    ManageCategoriesView.swift (@Query list; add / edit / delete)
    CategoryFormView.swift     (add/edit sheet: name, icon grid, color)
    ReassignCategorySheet.swift(pick target when deleting an in-use category)
```
`RootView` `.settings` case → `SettingsView()` (removes `SettingsStubView`).
Entry's `CategoryPickerSheet` re-enables its "New category" button to present `CategoryFormView`.

## Write path + validation

```swift
enum CategoryActions {
    static func add(name: String, symbolName: String, colorHex: String, in context: ModelContext)
    static func update(_ category: ExpenseCategory, name: String, symbolName: String, colorHex: String)
    /// Move this category's transactions to `target`, then delete it.
    static func delete(_ category: ExpenseCategory, reassigningTo target: ExpenseCategory, in context: ModelContext)
}

/// Trimmed, case-insensitive uniqueness. When editing, the category keeps its own name.
func isCategoryNameAvailable(_ name: String, existing: [ExpenseCategory], editing: ExpenseCategory?) -> Bool
```
- `delete(reassigningTo:)`: `category.transactions.forEach { $0.category = target }`, then
  `context.delete(category)`.
- "In use?" = `!category.transactions.isEmpty` (uses the existing inverse relationship).

## Screens & flows

- **SettingsView:** grouped "PREFERENCES" section, **Manage categories** row → push.
- **ManageCategoriesView:** rows = color tile + SF Symbol + name; trailing trash. Tap →
  edit sheet; "Add category" → add sheet. Delete: empty → confirm + delete; in-use →
  `ReassignCategorySheet`; only-one → trash disabled.
- **CategoryFormView (sheet):** name field; SF-Symbol grid (selected tinted with chosen
  color); 4 swatches + `ColorPicker`. Save disabled until name valid (non-empty + unique).
  Calls `CategoryActions.add` or `.update`.
- **ReassignCategorySheet:** "Move N transactions to…" + list of the other categories →
  `CategoryActions.delete(reassigningTo:)`.
- **Entry hook:** `CategoryPickerSheet`'s "New category" presents `CategoryFormView`; on
  save, set Entry's selected category to the new one.

## Testing

- **Unit (XCTest):** `CategoryActions` add / update / delete-empty / delete-with-reassign
  (verify transactions moved + category removed) against an in-memory `ModelContainer`;
  `isCategoryNameAvailable` (empty, duplicate case-insensitive, editing-keeps-own-name).
- **`#Preview` + simulator:** Settings shell, manage list, add/edit form, delete→reassign,
  Entry "New category".

## Implementation slicing (3 PRs)

| PR | Branch | Delivers | Tested |
|---|---|---|---|
| 1 | `feature/category-actions` | `CategoryActions`, `isCategoryNameAvailable`, `CategoryIcons` | Unit |
| 2 | `feature/category-manage-ui` | `SettingsView` shell + `ManageCategoriesView` + `CategoryFormView` (add/edit, icon/color, validation) + tab wiring | `#Preview` + sim |
| 3 | `feature/category-delete-entry` | delete→`ReassignCategorySheet` + re-enable Entry "New category" | unit (reassign) + sim |

## References
- `design_handoff_plop/README.md` (Settings) · `app/settings.jsx` · `app/dialogs.jsx`
- Relates to: `docs/insights/` (spend buckets by category name → name uniqueness).
