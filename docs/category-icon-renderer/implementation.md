# Category Icon Renderer (Emoji icons PR1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `ExpenseCategory.emoji` and a reusable `CategoryIconView`, and route every category icon surface through it — without changing any current behavior.

**Architecture:** Additive non-optional model field (`emoji: String = ""`, presence = render emoji vs SF symbol); one renderer view; eight one-line adoptions. No data/logic change.

**Tech Stack:** SwiftUI, SwiftData, XCTest. iOS 18. Views verified via `#Preview` + simulator.

Single PR on branch `feature/category-icon-renderer` (off `main`; spec committed there).

---

## File structure

- **Modify** `plop/plop/Models/ExpenseCategory.swift` — add `emoji` property + init param.
- **Create** `plop/plop/Views/Common/CategoryIconView.swift` — emoji-or-symbol renderer.
- **Modify** the 8 render sites (one `Image(systemName:)` → `CategoryIconView` each):
  `Views/Home/TxRow.swift`, `Views/Entry/EntryView.swift`,
  `Views/Entry/CategoryPickerSheet.swift`, `Views/Settings/RecurringRulesSheet.swift`,
  `Views/Settings/BudgetView.swift`, `Views/Settings/ManageCategoriesView.swift`,
  `Views/Settings/ReassignCategorySheet.swift`, `Views/Insights/CategoryBudgetSheet.swift`.

### Build / lint / test commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | tail -5

cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests/CategoryActionsTests \
  -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2

swiftlint lint
```

> SourceKit "Cannot find X" / "No such module" diagnostics are FALSE positives — `xcodebuild`
> is the source of truth. Lines ≤ 120. No `// swiftlint:disable`. Keep the lint baseline
> (21 violations, 0 serious); do not edit `.swiftlint.yml`.

---

## Task 1: Model — add `emoji` + a default test

**Files:**
- Modify: `plop/plop/Models/ExpenseCategory.swift`
- Modify: `plop/plopTests/CategoryActionsTests.swift`

- [ ] **Step 1: Add the failing test**

In `CategoryActionsTests.swift`, add this method inside the class (e.g. after
`test_add_insertsCategory`):
```swift
    func test_category_emojiDefaultsEmpty() {
        let cat = ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC")
        XCTAssertEqual(cat.emoji, "")
    }
```

- [ ] **Step 2: Run the test to verify it fails** — run the test command. Expected: compile
  error (`ExpenseCategory` has no member `emoji`).

- [ ] **Step 3: Add the property + init param**

In `ExpenseCategory.swift`, add `emoji` after `symbolName`:
```swift
    var name: String
    var symbolName: String      // SF Symbol, e.g. "fork.knife"
    var emoji: String = ""      // non-empty ⇒ render this emoji instead of symbolName
    var colorHex: String        // e.g. "#FFEBCC"
    var budget: Decimal = 0     // 0 = no budget set; Budget feature gives it meaning later
                                // (non-optional: optional Decimal crashes SwiftData)
```
and update the initializer:
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
(`emoji` is defaulted, so existing callers that pass `colorHex:`/`budget:` by label —
`Seed/DefaultData`, `Previews/SampleData`, `CategoryActions.add` — compile unchanged.)

- [ ] **Step 4: Run the test to verify it passes** — run the test command → `** TEST
  SUCCEEDED **`.

- [ ] **Step 5: Lint + commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && swiftlint lint 2>&1 | tail -3
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Models/ExpenseCategory.swift plop/plopTests/CategoryActionsTests.swift
git commit -m "Add ExpenseCategory.emoji (defaults empty; renders instead of the SF symbol)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: CategoryIconView (new renderer)

**Files:**
- Create: `plop/plop/Views/Common/CategoryIconView.swift`

- [ ] **Step 1: Create the file**

Create `plop/plop/Views/Common/CategoryIconView.swift` with:
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

- [ ] **Step 2: Build** — run the build command → `** BUILD SUCCEEDED **` (unused view, just
  compiles).

- [ ] **Step 3: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Common/CategoryIconView.swift
git commit -m "Add CategoryIconView: render a category's emoji or SF symbol

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Adopt CategoryIconView at all 8 render sites

**Files:**
- Modify: `plop/plop/Views/Home/TxRow.swift`
- Modify: `plop/plop/Views/Entry/EntryView.swift`
- Modify: `plop/plop/Views/Entry/CategoryPickerSheet.swift`
- Modify: `plop/plop/Views/Settings/RecurringRulesSheet.swift`
- Modify: `plop/plop/Views/Settings/BudgetView.swift`
- Modify: `plop/plop/Views/Settings/ManageCategoriesView.swift`
- Modify: `plop/plop/Views/Settings/ReassignCategorySheet.swift`
- Modify: `plop/plop/Views/Insights/CategoryBudgetSheet.swift`

Each step replaces ONLY the `Image(systemName: …)` line; leave the surrounding
`.font/.foregroundStyle/.frame/.background/.overlay` modifiers exactly as they are.

- [ ] **Step 1: TxRow.swift** — change:
```swift
                Image(systemName: transaction.category?.symbolName ?? "questionmark")
```
to:
```swift
                CategoryIconView(category: transaction.category, fallbackSymbol: "questionmark")
```

- [ ] **Step 2: EntryView.swift** (selected-category button) — change:
```swift
                    Image(systemName: selected?.symbolName ?? "square.grid.2x2")
```
to:
```swift
                    CategoryIconView(category: selected, fallbackSymbol: "square.grid.2x2")
```

- [ ] **Step 3: CategoryPickerSheet.swift** — change:
```swift
            Image(systemName: category.symbolName)
```
to:
```swift
            CategoryIconView(category: category)
```

- [ ] **Step 4: RecurringRulesSheet.swift** — change:
```swift
            Image(systemName: rule.category?.symbolName ?? "arrow.triangle.2.circlepath")
```
to:
```swift
            CategoryIconView(category: rule.category, fallbackSymbol: "arrow.triangle.2.circlepath")
```

- [ ] **Step 5: BudgetView.swift** — change:
```swift
            Image(systemName: cat.symbolName)
```
to:
```swift
            CategoryIconView(category: cat)
```

- [ ] **Step 6: ManageCategoriesView.swift** — change:
```swift
                    Image(systemName: c.symbolName)
```
to:
```swift
                    CategoryIconView(category: c)
```

- [ ] **Step 7: ReassignCategorySheet.swift** — change:
```swift
                Image(systemName: target.symbolName)
```
to:
```swift
                CategoryIconView(category: target)
```

- [ ] **Step 8: CategoryBudgetSheet.swift** — change:
```swift
                Image(systemName: category.symbolName)
```
to:
```swift
                CategoryIconView(category: category)
```

- [ ] **Step 9: Build** — run the build command → `** BUILD SUCCEEDED **`. If a site fails
  because its category value is non-optional, that's fine — it auto-promotes to the optional
  parameter; only fix REAL errors.

- [ ] **Step 10: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 11: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Home/TxRow.swift plop/plop/Views/Entry/EntryView.swift \
        plop/plop/Views/Entry/CategoryPickerSheet.swift \
        plop/plop/Views/Settings/RecurringRulesSheet.swift \
        plop/plop/Views/Settings/BudgetView.swift \
        plop/plop/Views/Settings/ManageCategoriesView.swift \
        plop/plop/Views/Settings/ReassignCategorySheet.swift \
        plop/plop/Views/Insights/CategoryBudgetSheet.swift
git commit -m "Render category icons via CategoryIconView at all surfaces

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` (1 new test).

- [ ] **Step 2: Lint** — `swiftlint lint` → baseline 21/0, no new violations.

- [ ] **Step 3: Simulator smoke check (manual — owner)**

- **No visual change:** every category icon still shows its SF glyph — TxRow, Entry +
  category picker, Insights legend + budget sheet, Set budget rows, Manage categories,
  Reassign, Recurring — light + dark.
- **Migration (key):** launch on a simulator that ALREADY has categories from a build
  **before** this change (do NOT erase the app / clean the store). Confirm it launches,
  existing categories load, and their glyphs render. (Per the project's SwiftData gotchas,
  test on a non-clean store, not just a fresh install.)
- Optionally, in the debugger/preview, set a category's `emoji` (e.g. "🎉") and confirm
  `CategoryIconView` shows the emoji in place of the glyph everywhere — this previews PR2.

- [ ] **Step 4: Push + PR**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git push -u origin feature/category-icon-renderer
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Emoji-icons groundwork (PR1): add ExpenseCategory.emoji (defaults empty) and a reusable
CategoryIconView that renders the emoji or the SF symbol, adopted at every category icon
surface. Invisible refactor — nothing sets emoji yet (PR2 adds the editor).

## Testing
All unit tests pass (1 new: emoji defaults empty); SwiftLint clean (baseline 21/0).
Sim-verified: icons unchanged everywhere, and existing categories migrate/load fine on a
non-clean store; light + dark.
```

---

## Self-review notes

- **Spec coverage:** `emoji` field + init + default test (Task 1); `CategoryIconView`
  (Task 2); all 8 adoptions (Task 3); verify incl. the migration check (Task 4). Out-of-scope
  items (form toggle/emoji picker, `CategoryActions` emoji param, the glyph-grid `Image` in
  `CategoryFormView`) are deliberately untouched.
- **Type consistency:** `CategoryIconView(category: ExpenseCategory?, fallbackSymbol: String)`
  — used with both optional (TxRow/EntryView/Recurring) and non-optional (auto-promoted)
  categories; `emoji` property + the new init parameter ordering (`…symbolName:emoji:colorHex:
  budget:`, `emoji` defaulted) keep existing call sites compiling.
- **Behavior preserved:** every site keeps its modifiers; nothing assigns `emoji`, so all
  icons remain SF glyphs. The only new logic (the empty default) is unit-tested; the rest is
  presentation (preview + sim per project convention) plus the manual migration check.
- **No placeholders / no disables / config untouched / lines ≤ 120.**
