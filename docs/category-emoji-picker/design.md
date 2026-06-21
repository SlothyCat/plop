# Category Emoji Picker (Emoji icons PR2) — Design

Status: Approved (brainstorm complete) · Date: 2026-06-21

Companion to `requirements.md`. The curated set, `CategoryActions` emoji, the form's ICON
section (toggle + emoji grid + custom field), save/prefill, testing, scope.

## Architecture

```
plop/Models/CategoryIcons.swift            (add categoryEmojiChoices)
plop/Data/CategoryActions.swift            (add/update gain emoji)
plop/Views/Settings/CategoryFormView.swift (ICON toggle + emoji grid + custom field)
plop/plopTests/CategoryActionsTests.swift  (emoji persistence; fix update call)
CLAUDE.md                                  (extend the flag/emoji exception)
```

`ExpenseCategory.emoji` and `CategoryIconView` (renders emoji-or-glyph everywhere) already
exist from PR1. PR2 only adds the *editor* + the actions plumbing.

## 1. Curated set (Models/CategoryIcons.swift)

Append:
```swift
/// Curated emoji offered when creating/editing a category (Emoji mode).
let categoryEmojiChoices: [String] = [
    "🎓", "🍔", "📺", "🚗", "🏠", "✈️", "🛒", "💡", "🐶",
    "💪", "🎁", "💰", "☕", "🎮", "👕", "💊", "🎵", "🧾",
]
```

## 2. CategoryActions (emoji)

```swift
    @discardableResult
    static func add(name: String, symbolName: String, emoji: String = "", colorHex: String,
                    budget: Decimal = 0, in context: ModelContext) -> ExpenseCategory {
        let category = ExpenseCategory(name: name, symbolName: symbolName, emoji: emoji,
                                       colorHex: colorHex, budget: budget)
        context.insert(category)
        return category
    }

    static func update(_ category: ExpenseCategory, name: String, symbolName: String,
                       emoji: String, colorHex: String, budget: Decimal) {
        category.name = name
        category.symbolName = symbolName
        category.emoji = emoji
        category.colorHex = colorHex
        category.budget = budget
    }
```
`add`'s `emoji` is defaulted (Seed/SampleData compile unchanged); `update`'s is required
(only `CategoryFormView` + the test call it). Parameter order matches the model init
(`…symbolName, emoji, colorHex, budget`).

## 3. CategoryFormView — ICON section

New state + an icon-type enum:
```swift
    @State private var name = ""
    @State private var symbolName = "tag.fill"
    @State private var emoji = ""
    @State private var iconType: IconType = .glyph
    @State private var colorHex = "#8CC0EB"
    @State private var budgetField = ""

    private enum IconType { case glyph, emoji }

    private let emojiPerRow = 6
    private var emojiRows: [[String]] {
        stride(from: 0, to: categoryEmojiChoices.count, by: emojiPerRow).map {
            Array(categoryEmojiChoices[$0 ..< min($0 + emojiPerRow, categoryEmojiChoices.count)])
        }
    }
```
(`iconsPerRow` / `iconRows` for the glyph grid already exist.)

Replace the existing `field("ICON") { …glyph grid… }` block with a custom section whose label
row carries the toggle:
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

Toggle (compact pill, matching the handoff):
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
```

Glyph grid — extract the current eager grid into a property (same content as today):
```swift
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
```

Emoji grid (eager, 6 per row) + buttons:
```swift
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
```

Custom emoji field — focuses the iOS emoji keyboard; keeps the last entered emoji. Shows the
current emoji only when it's NOT one of the curated ones (so the field reads as "custom"):
```swift
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
            set: { if let last = $0.last { emoji = String(last) } }   // keep the last emoji
        )
    }
```
Note: iOS has no API to force the emoji keyboard; the user taps the 🌐/emoji key. `$0.last`
returns the trailing grapheme, so multi-scalar emoji (✈️, flags, ZWJ) are kept whole.

Save + prefill (only the icon bits change):
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
`canSave` (name validity) is unchanged.

## 4. CLAUDE.md

Extend the existing flag exception so it also covers **user-chosen category emoji** (the
emoji a user picks as a category icon are user content, not shipped decoration).

## Testing

- **Unit (TDD):** in `CategoryActionsTests` —
  - update the existing `test_update_mutatesFields` call to pass `emoji: ""` (now required);
  - `test_add_persistsEmoji`: `add(…, emoji: "🎉", …)` → `created.emoji == "🎉"`;
  - `test_update_setsEmoji`: `update(…, emoji: "🍔", …)` → `cat.emoji == "🍔"`.
- **Views:** preview + simulator —
  - the ICON toggle switches between the glyph grid and the emoji grid;
  - tapping a curated emoji selects it (fills with the chosen color); the **custom field**
    opens the emoji keyboard and any picked emoji becomes the selection;
  - Save persists; reopening the category shows the saved icon + correct mode (Edit
    prefills); the icon renders on Home / Insights / Budget / Manage / Reassign / Recurring
    / Entry via PR1's `CategoryIconView`; light + dark.
  - The grids slide with the popup card (eager), not snap (regression guard).

## Scope

`categoryEmojiChoices` + `CategoryActions` emoji + the `CategoryFormView` ICON section + the
CLAUDE.md exception. One PR on `feature/category-emoji-picker`. Completes the emoji-icons
feature.
