# Popup Consistency — Design

Status: Approved · Date: 2026-06-23

Companion to `requirements.md`. PR1 (`CategoryBudgetSheet`) in full; PR2 (Entry popups)
outlined per file. Both follow the Settings standard: `BlurPopup` (free top-right ×),
`PopupPrimaryButton`, live theme, `\.blurPopupClose` for dismissal, no grabbers/detents.

## PR1 — CategoryBudgetSheet (Insights)

**InsightsView** — present via `BlurPopup`. Change:
```swift
        .sheet(item: $editing) { cat in
            CategoryBudgetSheet(category: cat) { editing = nil }
        }
```
to:
```swift
        .blurPopup(item: $editing) { cat in
            CategoryBudgetSheet(category: cat)
        }
```

**CategoryBudgetSheet** —
- Replace `var onDone: () -> Void` with `@Environment(\.blurPopupClose) private var close`.
- `save()`: `category.budget = parseBudgetAmount(field); close()`.
- In `body`: remove the trailing `Spacer()`, `.presentationDetents([.medium])`, and
  `.background(Palette.bg)` (the card supplies it). Keep `.padding(20)` and the `.onAppear`.
- The button block becomes just the primary action:
```swift
            Button { save() } label: { Text("Save budget") }
                .buttonStyle(PopupPrimaryButton())
```
  (remove the `VStack`'s "Cancel" — × dismisses).
- Preview: `CategoryBudgetSheet(category: …)` (drop the `onDone:` argument).

Result: a hugging blurred card with the icon/name header, the $-field, a standard Save
button, and the auto ×. `category.budget` write is unchanged.

## PR2 — Entry popups

`EntryView` swaps its four `.sheet`s for `.blurPopup`; each child sheet drops its grabber +
`.presentationDetents` and dismisses via `\.blurPopupClose`.

**New category** (no view change — fixes the dismiss bug):
```swift
        .blurPopup(isPresented: $showingNewCategory) {
            CategoryFormView(onSave: { selected = $0 })
        }
```
`CategoryFormView` already calls `close()` on Save/Cancel; `BlurPopup` now supplies it.

**WhenSheet** (date picker):
```swift
        .blurPopup(isPresented: $whenOpen) { WhenSheet(date: $date) }
```
In `WhenSheet`: remove the grabber `Capsule` and `.presentationDetents`. The graphical
`DatePicker` binds live; the × dismisses (no button). It hugs its intrinsic height.

**RecurringSheet**:
```swift
        .blurPopup(isPresented: $recurOpen) { RecurringSheet(recurrence: $recurrence) }
```
In `RecurringSheet`: drop the `onDismiss` param + grabber + `.presentationDetents`; add
`@Environment(\.blurPopupClose) private var close`; a row tap does
`recurrence = option.value; close()`. Few rows → hugs.

**CategoryPickerSheet** (the one with a grid):
```swift
        .blurPopup(isPresented: $pickerOpen, tall: true) {
            CategoryPickerSheet(categories: categories, selected: $selected,
                                onAddNew: { pickerOpen = false; showingNewCategory = true })
        }
```
In `CategoryPickerSheet`: drop the grabber + `.presentationDetents` + the `onDismiss` param;
add `@Environment(\.blurPopupClose) private var close`. Structure like Manage: a fixed header,
then the category grid in a **`ScrollView`** capped via `.readHeight`/`scrollCap` (so it
scrolls when long), then the pinned **"New category"** dashed button. A tile tap does
`selected = category; close()`. The grid stays a `LazyVGrid` **inside the ScrollView** (lazy
is fine in a scroll context). "New category" calls `onAddNew()` (EntryView closes the picker
and opens the New-category popup, which stacks).

> Note: `onAddNew` sets `pickerOpen = false` directly (instant close) before opening New
> category — acceptable; selection/× use the animated `close()`.

## Testing

- **No unit tests** (presentation; no logic change — budget/recurrence/date writes unchanged).
- **PR1 sim:** Insights → Budget → tap a category → a blurred card with × + standard Save;
  Save writes the budget and closes; × / drag dismiss; theme matches.
- **PR2 sim:** Entry → each of category picker (scrolls, select closes, "New category" opens
  the New-category popup), New category (Save/Cancel **now close it**), when (date applies
  live), recurring (pick closes); all have × + themed blur; light + dark.

## Scope

PR1: `InsightsView` + `CategoryBudgetSheet`. PR2: `EntryView` + `CategoryPickerSheet` /
`WhenSheet` / `RecurringSheet` (CategoryFormView unchanged). Two PRs on
`feature/insights-budget-popup` then a PR2 branch.
