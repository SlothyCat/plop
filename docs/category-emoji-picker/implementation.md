# Category Emoji Picker (Emoji icons PR2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a category's icon be an SF glyph or an emoji — a curated emoji grid plus a custom field (any iOS emoji) — in the Add/Edit category form, persisted via CategoryActions.

**Architecture:** Curated emoji list + `CategoryActions` emoji plumbing + a toggle/emoji-grid/custom-field ICON section in `CategoryFormView`. `ExpenseCategory.emoji` and `CategoryIconView` (renders it everywhere) already exist from PR1.

**Tech Stack:** SwiftUI, SwiftData, XCTest. iOS 18. Views verified via `#Preview` + simulator.

Single PR on branch `feature/category-emoji-picker` (off `main`; spec committed there).

---

## File structure

- **Modify** `plop/plop/Models/CategoryIcons.swift` — add `categoryEmojiChoices`.
- **Modify** `plop/plop/Data/CategoryActions.swift` — `add`/`update` gain `emoji`.
- **Modify** `plop/plopTests/CategoryActionsTests.swift` — emoji tests + fix `update` call.
- **Modify** `plop/plop/Views/Settings/CategoryFormView.swift` — ICON toggle + emoji grid +
  custom field + save/prefill.
- **Modify** `CLAUDE.md` — extend the flag/emoji exception.

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

## Task 1: Curated emoji set

**Files:**
- Modify: `plop/plop/Models/CategoryIcons.swift`

- [ ] **Step 1: Append the list**

At the end of `CategoryIcons.swift`, add:
```swift

/// Curated emoji offered when creating/editing a category (Emoji mode).
let categoryEmojiChoices: [String] = [
    "🎓", "🍔", "📺", "🚗", "🏠", "✈️", "🛒", "💡", "🐶",
    "💪", "🎁", "💰", "☕", "🎮", "👕", "💊", "🎵", "🧾",
]
```

- [ ] **Step 2: Build** — run the build command → `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Models/CategoryIcons.swift
git commit -m "Add categoryEmojiChoices for the category emoji picker

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: CategoryActions emoji (TDD)

**Files:**
- Modify: `plop/plopTests/CategoryActionsTests.swift`
- Modify: `plop/plop/Data/CategoryActions.swift`
- Modify: `plop/plop/Views/Settings/CategoryFormView.swift` (minimal call-site fix only)

- [ ] **Step 1: Update tests (red)**

In `CategoryActionsTests.swift`, change the `update` call in `test_update_mutatesFields`
(it now requires `emoji:`):
```swift
        CategoryActions.update(cat, name: "Groceries", symbolName: "cart.fill",
                               colorHex: "#8CC0EB", budget: 250)
```
to:
```swift
        CategoryActions.update(cat, name: "Groceries", symbolName: "cart.fill",
                               emoji: "", colorHex: "#8CC0EB", budget: 250)
```
Then add two tests after `test_category_emojiDefaultsEmpty`:
```swift
    func test_add_persistsEmoji() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let created = CategoryActions.add(name: "Fun", symbolName: "tag.fill", emoji: "🎉",
                                          colorHex: "#BFDDF0", in: ctx)
        XCTAssertEqual(created.emoji, "🎉")
        try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ExpenseCategory>()).first?.emoji, "🎉")
    }

    func test_update_setsEmoji() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let cat = ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC")
        ctx.insert(cat)
        CategoryActions.update(cat, name: "Food", symbolName: "fork.knife",
                               emoji: "🍔", colorHex: "#FFEBCC", budget: 0)
        XCTAssertEqual(cat.emoji, "🍔")
    }
```

- [ ] **Step 2: Run tests to verify they fail** — run the test command. Expected: compile
  error (`update` has no `emoji:`; `add` `emoji:` unknown).

- [ ] **Step 3: Add `emoji` to CategoryActions**

In `CategoryActions.swift`, change `add`:
```swift
    @discardableResult
    static func add(name: String, symbolName: String, colorHex: String,
                    budget: Decimal = 0, in context: ModelContext) -> ExpenseCategory {
        let category = ExpenseCategory(name: name, symbolName: symbolName,
                                       colorHex: colorHex, budget: budget)
        context.insert(category)
        return category
    }
```
to:
```swift
    @discardableResult
    static func add(name: String, symbolName: String, emoji: String = "", colorHex: String,
                    budget: Decimal = 0, in context: ModelContext) -> ExpenseCategory {
        let category = ExpenseCategory(name: name, symbolName: symbolName, emoji: emoji,
                                       colorHex: colorHex, budget: budget)
        context.insert(category)
        return category
    }
```
and `update`:
```swift
    static func update(_ category: ExpenseCategory, name: String, symbolName: String,
                       colorHex: String, budget: Decimal) {
        category.name = name
        category.symbolName = symbolName
        category.colorHex = colorHex
        category.budget = budget
    }
```
to:
```swift
    static func update(_ category: ExpenseCategory, name: String, symbolName: String,
                       emoji: String, colorHex: String, budget: Decimal) {
        category.name = name
        category.symbolName = symbolName
        category.emoji = emoji
        category.colorHex = colorHex
        category.budget = budget
    }
```

- [ ] **Step 4: Minimal call-site fix so the suite compiles**

`update` is now required-`emoji`, but `CategoryFormView.save()` still calls it without
`emoji` (the full ICON rework is Task 3). Patch ONLY that one call so the test target builds.
In `CategoryFormView.swift`, change:
```swift
            CategoryActions.update(editing, name: trimmed, symbolName: symbolName,
                                   colorHex: colorHex, budget: budget)
```
to:
```swift
            CategoryActions.update(editing, name: trimmed, symbolName: symbolName,
                                   emoji: editing.emoji, colorHex: colorHex, budget: budget)
```
(Preserves current behavior — keeps the existing emoji, which is `""` today. Task 3 replaces
this with the chosen emoji.)

- [ ] **Step 5: Run tests to verify they pass** — run the test command → `** TEST
  SUCCEEDED **`.

- [ ] **Step 6: Lint + commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && swiftlint lint 2>&1 | tail -3
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Data/CategoryActions.swift plop/plopTests/CategoryActionsTests.swift \
        plop/plop/Views/Settings/CategoryFormView.swift
git commit -m "Add emoji to CategoryActions add/update

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: CategoryFormView — Icons/Emoji toggle + emoji picker

**Files:**
- Modify: `plop/plop/Views/Settings/CategoryFormView.swift`

- [ ] **Step 1: Add state + an icon-type enum + emoji rows**

Change:
```swift
    @State private var name = ""
    @State private var symbolName = "tag.fill"
    @State private var colorHex = "#8CC0EB"
    @State private var budgetField = ""

    private let swatches = ["#8CC0EB", "#BFDDF0", "#FFEBCC", "#FFF9D2"]
    private let iconsPerRow = 5
```
to:
```swift
    @State private var name = ""
    @State private var symbolName = "tag.fill"
    @State private var emoji = ""
    @State private var iconType: IconType = .glyph
    @State private var colorHex = "#8CC0EB"
    @State private var budgetField = ""

    private enum IconType { case glyph, emoji }

    private let swatches = ["#8CC0EB", "#BFDDF0", "#FFEBCC", "#FFF9D2"]
    private let iconsPerRow = 5
    private let emojiPerRow = 6

    private var emojiRows: [[String]] {
        stride(from: 0, to: categoryEmojiChoices.count, by: emojiPerRow).map {
            Array(categoryEmojiChoices[$0 ..< min($0 + emojiPerRow, categoryEmojiChoices.count)])
        }
    }
```

- [ ] **Step 2: Replace the ICON section in `body`**

Change:
```swift
            field("ICON") {
                VStack(spacing: 10) {
                    ForEach(iconRows, id: \.self) { row in
                        HStack(spacing: 10) {
                            ForEach(row, id: \.self) { iconButton($0).frame(maxWidth: .infinity) }
                            ForEach(0 ..< (iconsPerRow - row.count), id: \.self) { _ in
                                Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                            }
                        }
                    }
                }
            }
```
to:
```swift
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("ICON").font(.system(size: 12.5, weight: .semibold)).tracking(0.4)
                        .foregroundStyle(Palette.ink40)
                    Spacer()
                    iconTypeToggle
                }
                if iconType == .glyph {
                    glyphGrid
                } else {
                    emojiGrid
                    customEmojiField
                }
            }
```

- [ ] **Step 3: Add the new subviews**

Add these methods/properties to `CategoryFormView` (e.g. just before `iconButton`):
```swift
    private var iconTypeToggle: some View {
        HStack(spacing: 2) {
            toggleChip("Icons", on: iconType == .glyph) { iconType = .glyph }
            toggleChip("Emoji", on: iconType == .emoji) {
                iconType = .emoji
                if emoji.isEmpty { emoji = categoryEmojiChoices.first ?? "🛒" }
            }
        }
        .padding(2)
        .background(Palette.field, in: Capsule())
    }

    private func toggleChip(_ title: String, on: Bool,
                            _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(on ? Palette.ink : Palette.ink40)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(on ? Palette.card : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var glyphGrid: some View {
        VStack(spacing: 10) {
            ForEach(iconRows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { iconButton($0).frame(maxWidth: .infinity) }
                    ForEach(0 ..< (iconsPerRow - row.count), id: \.self) { _ in
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                    }
                }
            }
        }
    }

    private var emojiGrid: some View {
        VStack(spacing: 10) {
            ForEach(emojiRows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { emojiButton($0) }
                    ForEach(0 ..< (emojiPerRow - row.count), id: \.self) { _ in
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                    }
                }
            }
        }
    }

    private func emojiButton(_ choice: String) -> some View {
        let on = choice == emoji
        return Button { emoji = choice } label: {
            Text(choice).font(.system(size: 22))
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(on ? Color(hex: colorHex) : Palette.field,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(on ? Color.clear : Palette.ink12, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var customEmojiField: some View {
        HStack(spacing: 8) {
            Text("Custom").font(.system(size: 14)).foregroundStyle(Palette.ink60)
            Spacer()
            TextField("Any emoji", text: customEmojiBinding)
                .multilineTextAlignment(.trailing).font(.system(size: 20))
                .frame(width: 90)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Palette.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.ink12, lineWidth: 1))
    }

    private var customEmojiBinding: Binding<String> {
        Binding(
            get: { categoryEmojiChoices.contains(emoji) ? "" : emoji },
            set: { if let last = $0.last { emoji = String(last) } }
        )
    }
```

- [ ] **Step 4: Update `save()` and `prefill()`**

Change `save()`:
```swift
    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let budget = parseBudgetAmount(budgetField)
        if let editing {
            CategoryActions.update(editing, name: trimmed, symbolName: symbolName,
                                   emoji: editing.emoji, colorHex: colorHex, budget: budget)
            onSave?(editing)
        } else {
            let created = CategoryActions.add(name: trimmed, symbolName: symbolName,
                                              colorHex: colorHex, budget: budget,
                                              in: modelContext)
            onSave?(created)
        }
        close()
    }
```
to:
```swift
    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let budget = parseBudgetAmount(budgetField)
        let chosenEmoji = iconType == .emoji ? emoji : ""
        if let editing {
            CategoryActions.update(editing, name: trimmed, symbolName: symbolName,
                                   emoji: chosenEmoji, colorHex: colorHex, budget: budget)
            onSave?(editing)
        } else {
            let created = CategoryActions.add(name: trimmed, symbolName: symbolName,
                                              emoji: chosenEmoji, colorHex: colorHex,
                                              budget: budget, in: modelContext)
            onSave?(created)
        }
        close()
    }
```
Change `prefill()`:
```swift
    private func prefill() {
        guard let editing else { return }
        name = editing.name
        symbolName = editing.symbolName
        colorHex = editing.colorHex
        budgetField = editing.budget > 0 ? formatBudgetAmount(editing.budget) : ""
    }
```
to:
```swift
    private func prefill() {
        guard let editing else { return }
        name = editing.name
        symbolName = editing.symbolName
        emoji = editing.emoji
        iconType = editing.emoji.isEmpty ? .glyph : .emoji
        colorHex = editing.colorHex
        budgetField = editing.budget > 0 ? formatBudgetAmount(editing.budget) : ""
    }
```

- [ ] **Step 5: Build** — run the build command → `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 7: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/CategoryFormView.swift
git commit -m "Add Icons/Emoji toggle, emoji grid, and custom emoji field to the category form

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: CLAUDE.md — extend the emoji exception

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Extend the exception**

In `CLAUDE.md`, find the design-constraints exception that currently covers currency flags
(the bullet under "No emoji … No decorative SVG art …"). Append a sentence so it also covers
user-chosen category emoji, e.g.:
```
    Users may also pick an emoji as a category icon (Emoji mode in the category form) — user
    content, not shipped decoration. These are the only sanctioned emoji/flag exceptions.
```
Keep the existing flag-exception text; just add the category-emoji clause.

- [ ] **Step 2: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add CLAUDE.md
git commit -m "Document category emoji as a sanctioned user-content exception

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` (2 new emoji tests).

- [ ] **Step 2: Lint** — `swiftlint lint` → baseline 21/0, no new violations.

- [ ] **Step 3: Simulator smoke check (manual — owner)**

In Settings → Manage categories → Add category / Edit, light + dark:
- The **ICON** row shows an **Icons / Emoji** toggle; switching flips between the SF-glyph
  grid and the emoji grid (both slide with the card — no snap).
- Tapping a curated emoji selects it (tile fills with the chosen color).
- The **Custom** field opens the iOS emoji keyboard (tap the 🌐/emoji key); picking ANY emoji
  makes it the selected icon (curated tiles deselect).
- **Save** persists; the icon appears on Home / Insights / Budget / Manage / Reassign /
  Recurring / Entry. **Edit** a category and confirm it prefills the saved icon + correct
  mode; switching back to Icons and saving clears the emoji (renders the glyph).

- [ ] **Step 4: Push + PR**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git push -u origin feature/category-emoji-picker
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Emoji-icons PR2: the Add/Edit category form gains an Icons/Emoji toggle — a curated emoji
grid plus a custom field for any iOS emoji — persisted via CategoryActions to
ExpenseCategory.emoji and rendered everywhere by PR1's CategoryIconView.

## Testing
All unit tests pass (2 new for CategoryActions emoji); SwiftLint clean (baseline 21/0).
Sim-verified: toggle, curated + custom emoji, save/prefill, renders on all surfaces; light + dark.
```

---

## Self-review notes

- **Spec coverage:** curated set (Task 1); `CategoryActions` emoji + tests (Task 2); form
  toggle + emoji grid + custom field + save/prefill (Task 3); CLAUDE.md exception (Task 4);
  verify incl. all-surfaces + custom-keyboard check (Task 5). All spec items map to a task.
- **Build-green ordering:** Task 2 makes `update` require `emoji`; it patches the single
  `CategoryFormView.save()` call (`emoji: editing.emoji`) in the same commit so the suite
  compiles, and Task 3 replaces that with the chosen emoji. (Mirrors the B2b budget rollout.)
- **Type consistency:** `add(name:symbolName:emoji:colorHex:budget:in:)` (emoji defaulted),
  `update(_:name:symbolName:emoji:colorHex:budget:)` (emoji required) — order matches the
  model init; `iconType` enum + `emoji` state + `categoryEmojiChoices` used consistently;
  eager `glyphGrid`/`emojiGrid` (no `LazyVGrid`, per the popup gotcha).
- **Behavior preserved:** Icons mode reproduces today's behavior (`emoji == ""` → glyph via
  `CategoryIconView`); name validation, color, budget unchanged. Only `CategoryActions` emoji
  is new tested logic; the form is preview + sim.
- **No placeholders / no disables / config untouched / lines ≤ 120.**
