# Popup Consistency PR2 (Entry popups) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring Entry's four popups — New category, Recurring, When, Category picker — onto the shared `BlurPopup` standard (top-right ×, live theme, `\.blurPopupClose` dismissal, no grabbers/detents), matching Settings + Insights.

**Architecture:** `EntryView` swaps its four `.sheet`s for `.blurPopup`. Each child sheet drops its grabber `Capsule` and `.presentationDetents`, and dismisses/selects via `\.blurPopupClose`. The grid-bearing picker presents `tall:` with a height-capped `ScrollView` (the Manage-categories pattern). `CategoryFormView` is unchanged — presenting it via `BlurPopup` **fixes a real bug**: it already calls `\.blurPopupClose`, which is a no-op inside a `.sheet`, so its Save/Cancel currently don't dismiss in Entry.

**Tech Stack:** SwiftUI. iOS 18. Presentation only — no unit tests.

Single PR on a new branch `feature/entry-popups` off `main`. **Branch only after PR1 (`feature/insights-budget-popup`) is merged**, so this builds on the standardized `CategoryBudgetSheet` baseline.

---

## Context the implementer needs

- `EntryView` is itself presented in a `fullScreenCover` (RootView's `showingEntry`). Its child
  popups are therefore **nested** popups — the same context where Manage-categories' BlurPopups
  work today. Stacking BlurPopups is proven (Manage stacks edit/reassign over itself).
- `BlurPopup` already exists (`Views/Common/BlurPopup.swift`) with both overloads:
  `.blurPopup(isPresented:tall:onDismiss:card:)` and `.blurPopup(item:tall:onDismiss:card:)`.
  It supplies the top-right ×, the blurred themed scrim, the slide animation, and the
  `\.blurPopupClose` environment closure. **Do not modify `BlurPopup`.**
- `\.blurPopupMaxHeight` (env, `CGFloat`) is the popup's available height when `tall: true`;
  `.readHeight(into:)` reports a subview's height. The Manage pattern caps a `ScrollView` at
  `min(contentHeight, maxHeight * 0.7)` so a tall popup hugs short content but scrolls long
  content. Mirror it for the picker.
- A `LazyVGrid` is fine **inside a `ScrollView`** (lazy works in a scroll context); it only
  snaps cells when lazy inside a non-scrolling offset-animated card. The picker grid moves
  into a `ScrollView`, so it stays `LazyVGrid`.
- `CategoryFormView(editing:onSave:)` already uses `\.blurPopupClose` and calls `close()` on
  Save/Cancel — no change needed.

### Build / lint commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:"

swiftlint lint 2>&1 | tail -1
```

> SourceKit "Cannot find X" / "No such module" diagnostics are FALSE positives — `xcodebuild`
> is the source of truth. Lines ≤ 120. No `// swiftlint:disable`. Keep the lint baseline
> (19 violations, 0 serious). Don't edit `.swiftlint.yml`.

---

## File structure

- **Modify** `plop/plop/Views/Entry/EntryView.swift` — four `.sheet` → `.blurPopup`; drop the
  picker/recurring `onDismiss` closures.
- **Modify** `plop/plop/Views/Entry/WhenSheet.swift` — drop grabber + detents.
- **Modify** `plop/plop/Views/Entry/RecurringSheet.swift` — drop `onDismiss` + grabber +
  detents; use `\.blurPopupClose`.
- **Modify** `plop/plop/Views/Entry/CategoryPickerSheet.swift` — drop `onDismiss` + grabber +
  detents; use `\.blurPopupClose`; grid into a capped `ScrollView`.
- `CategoryFormView.swift` — **unchanged** (presentation swap in EntryView fixes its bug).

---

## Task 1: New category — fix the dismiss bug via BlurPopup

The smallest change with the highest value: presenting `CategoryFormView` via `BlurPopup`
makes its existing `close()` work (currently a no-op in a `.sheet`).

**Files:** Modify `plop/plop/Views/Entry/EntryView.swift`

- [ ] **Step 1: Swap the presentation**

Change:
```swift
        .sheet(isPresented: $showingNewCategory) {
            CategoryFormView(onSave: { selected = $0 })
        }
```
to:
```swift
        .blurPopup(isPresented: $showingNewCategory) {
            CategoryFormView(onSave: { selected = $0 })
        }
```

- [ ] **Step 2: Build** → `** BUILD SUCCEEDED **`.
- [ ] **Step 3: Lint** → baseline 19/0.
- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Entry/EntryView.swift
git commit -m "Present Entry's New category form as a BlurPopup (fixes Save/Cancel not dismissing)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: WhenSheet → BlurPopup

**Files:**
- Modify `plop/plop/Views/Entry/WhenSheet.swift`
- Modify `plop/plop/Views/Entry/EntryView.swift`

- [ ] **Step 1: Strip the grabber + detents from WhenSheet**

Replace the whole `body` in `WhenSheet.swift`:
```swift
    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Palette.ink.opacity(0.15))
                .frame(width: 38, height: 5)
            DatePicker("Date & time", selection: $date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(Palette.accent)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .presentationDetents([.medium, .large])
    }
```
with:
```swift
    var body: some View {
        DatePicker("Date & time", selection: $date)
            .datePickerStyle(.graphical)
            .labelsHidden()
            .tint(Palette.accent)
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 20)
    }
```
(The graphical `DatePicker` binds live → no button; the × dismisses; the card hugs.)

- [ ] **Step 2: Present via BlurPopup in EntryView**

Change:
```swift
        .sheet(isPresented: $whenOpen) {
            WhenSheet(date: $date)
        }
```
to:
```swift
        .blurPopup(isPresented: $whenOpen) {
            WhenSheet(date: $date)
        }
```

- [ ] **Step 3: Build** → `** BUILD SUCCEEDED **`.
- [ ] **Step 4: Lint** → baseline 19/0.
- [ ] **Step 5: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Entry/WhenSheet.swift plop/plop/Views/Entry/EntryView.swift
git commit -m "Present Entry's When sheet as a BlurPopup

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: RecurringSheet → BlurPopup

**Files:**
- Modify `plop/plop/Views/Entry/RecurringSheet.swift`
- Modify `plop/plop/Views/Entry/EntryView.swift`

- [ ] **Step 1: Drop `onDismiss`; use `\.blurPopupClose`**

In `RecurringSheet.swift`, change the property block:
```swift
struct RecurringSheet: View {
    @Binding var recurrence: RecurrenceInterval
    var onDismiss: () -> Void
```
to:
```swift
struct RecurringSheet: View {
    @Binding var recurrence: RecurrenceInterval

    @Environment(\.blurPopupClose) private var close
```

- [ ] **Step 2: Remove the grabber + detents; select via `close()`**

Change the `body`:
```swift
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule().fill(Palette.ink.opacity(0.15))
                .frame(width: 38, height: 5)
                .frame(maxWidth: .infinity)
            Text("Repeat")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text("How often does this payment occur?")
                .font(.system(size: 13.5))
                .foregroundStyle(Palette.ink40)

            ForEach(options, id: \.value) { option in
                Button {
                    recurrence = option.value
                    onDismiss()
                } label: { row(option) }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .presentationDetents([.medium, .large])
    }
```
to:
```swift
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repeat")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text("How often does this payment occur?")
                .font(.system(size: 13.5))
                .foregroundStyle(Palette.ink40)

            ForEach(options, id: \.value) { option in
                Button {
                    recurrence = option.value
                    close()
                } label: { row(option) }
            }
        }
        .padding(18)
    }
```
(Few rows → the card hugs; the title sits left of the auto ×.)

- [ ] **Step 3: Present via BlurPopup in EntryView**

Change:
```swift
        .sheet(isPresented: $recurOpen) {
            RecurringSheet(recurrence: $recurrence) { recurOpen = false }
        }
```
to:
```swift
        .blurPopup(isPresented: $recurOpen) {
            RecurringSheet(recurrence: $recurrence)
        }
```

- [ ] **Step 4: Build** → `** BUILD SUCCEEDED **`.
- [ ] **Step 5: Lint** → baseline 19/0.
- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Entry/RecurringSheet.swift plop/plop/Views/Entry/EntryView.swift
git commit -m "Present Entry's Recurring sheet as a BlurPopup

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: CategoryPickerSheet → BlurPopup (tall + capped scroll)

The picker has a 2-column grid that can exceed the screen, so it presents `tall: true` with a
height-capped `ScrollView` (the Manage-categories pattern). The grabber/detents/`onDismiss` go;
a tile tap selects then `close()`; "New category" still calls `onAddNew`.

**Files:**
- Modify `plop/plop/Views/Entry/CategoryPickerSheet.swift`
- Modify `plop/plop/Views/Entry/EntryView.swift`

- [ ] **Step 1: Rework CategoryPickerSheet**

Replace the property block:
```swift
struct CategoryPickerSheet: View {
    let categories: [ExpenseCategory]
    @Binding var selected: ExpenseCategory?
    var onDismiss: () -> Void
    var onAddNew: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
```
with:
```swift
struct CategoryPickerSheet: View {
    let categories: [ExpenseCategory]
    @Binding var selected: ExpenseCategory?
    var onAddNew: () -> Void

    @Environment(\.blurPopupClose) private var close
    @Environment(\.blurPopupMaxHeight) private var maxHeight
    @State private var gridHeight: CGFloat = 0

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)

    private var scrollCap: CGFloat {
        let ceiling = maxHeight.isFinite ? maxHeight * 0.7 : 100_000
        return gridHeight == 0 ? ceiling : min(gridHeight, ceiling)
    }
```

- [ ] **Step 2: Rework the body (header fixed, grid in capped ScrollView, pinned New button)**

Change the `body`:
```swift
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            grabber
            Text("Choose category")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Palette.ink)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(categories) { category in
                    Button {
                        selected = category
                        onDismiss()
                    } label: { tile(category) }
                    .accessibilityIdentifier("category-\(category.name)")
                }
            }
            newCategoryButton
            Spacer(minLength: 0)
        }
        .padding(18)
        .presentationDetents([.medium, .large])
    }
```
to:
```swift
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose category")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Palette.ink)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(categories) { category in
                        Button {
                            selected = category
                            close()
                        } label: { tile(category) }
                        .accessibilityIdentifier("category-\(category.name)")
                    }
                }
                .readHeight(into: $gridHeight)
            }
            .frame(maxHeight: scrollCap)

            newCategoryButton
        }
        .padding(18)
    }
```

- [ ] **Step 3: Delete the now-unused `grabber`**

Remove the whole computed property:
```swift
    private var grabber: some View {
        Capsule().fill(Palette.ink.opacity(0.15))
            .frame(width: 38, height: 5)
            .frame(maxWidth: .infinity)
    }
```

- [ ] **Step 4: Present via BlurPopup in EntryView (drop `onDismiss`)**

Change:
```swift
        .sheet(isPresented: $pickerOpen) {
            CategoryPickerSheet(categories: categories, selected: $selected,
                                onDismiss: { pickerOpen = false },
                                onAddNew: { pickerOpen = false; showingNewCategory = true })
        }
```
to:
```swift
        .blurPopup(isPresented: $pickerOpen, tall: true) {
            CategoryPickerSheet(categories: categories, selected: $selected,
                                onAddNew: { pickerOpen = false; showingNewCategory = true })
        }
```

> `onAddNew` sets `pickerOpen = false` directly (instant teardown) before opening New category
> — keep it as-is. This is the one place a popup closes without the animated `close()`; it
> hands off to the New-category popup. Verify the handoff in the sim (see Task 5, Step 4).

- [ ] **Step 5: Build** → `** BUILD SUCCEEDED **`.
- [ ] **Step 6: Lint** → baseline 19/0.
- [ ] **Step 7: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Entry/CategoryPickerSheet.swift plop/plop/Views/Entry/EntryView.swift
git commit -m "Present Entry's category picker as a tall BlurPopup with a capped scroll grid

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full build** → `** BUILD SUCCEEDED **`.

- [ ] **Step 2: Full test suite** (presentation only — nothing should break)

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 \
  | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` (unchanged count).

> Note: `plopUITests` reference `category-<name>` and `categoryButton` identifiers, which are
> preserved. If a UI test target is run, the picker tile IDs still resolve.

- [ ] **Step 3: Lint** → baseline 19/0.

- [ ] **Step 4: Simulator smoke check (manual — owner)**, light + dark. Open Entry (Home → center "+"):
  - **Recurring** (top-right ↻): opens as a blurred themed card with × ; tapping an option sets
    it and the card slides out; × / drag dismiss.
  - **When** (date pill): blurred card with the graphical date picker; changing date/time
    applies live to the pill; × / drag dismiss.
  - **Category picker** (category pill): tall blurred card; grid **scrolls** when categories are
    many, **hugs** when few; tapping a tile selects it and closes; × / drag dismiss.
  - **New category** (picker → "New category"): the picker closes and the New-category form
    opens; **Save and Cancel now dismiss it** (the bug fix), and Save selects the new category.
    *Watch the picker→New-category handoff specifically — it dismisses one popup and presents
    another. If New category fails to appear, the fallback is to present it from the picker
    popup's `onDismiss` instead; flag it and I'll adjust.*
  - All four: top-right ×, themed blur, slide in/out; correct in light **and** dark.

- [ ] **Step 5: Push + PR**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git push -u origin feature/entry-popups
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Popup consistency (PR2): Entry's four popups — New category, Recurring, When, and the category
picker — now use BlurPopup (top-right ×, themed blur, live theme) instead of plain .sheets.
Fixes Entry's New-category Save/Cancel not dismissing (close() was a no-op in a .sheet).

## Testing
All unit tests pass (no new — presentation); SwiftLint clean (19/0). Sim-verified all four
popups (×, drag, select) and the New-category dismiss fix; light + dark.
```

---

## Self-review notes

- **Spec coverage (design.md PR2):** New category presentation swap (Task 1, fixes dismiss
  bug), When (Task 2), Recurring with `\.blurPopupClose` (Task 3), picker `tall:` + capped
  `ScrollView` + `\.blurPopupClose` + `onAddNew` retained (Task 4), verify (Task 5). All PR2
  items map to a task.
- **Signature consistency:** `CategoryPickerSheet` loses `onDismiss` (callers updated in Task 4
  Step 4); `RecurringSheet` loses `onDismiss` (caller updated in Task 3 Step 3); `WhenSheet`
  and `CategoryFormView` signatures unchanged. `selected`/`recurrence`/`date` bindings and the
  draft/save logic in EntryView are untouched.
- **Grid:** `LazyVGrid` stays lazy but now lives inside a `ScrollView` (valid) — no eager
  conversion needed.
- **No placeholders / no disables / config untouched / lines ≤ 120.**
- **Behaviour:** only presentation/dismissal change; category/recurrence/date writes unchanged,
  so no unit tests (project convention: views via preview/sim).
- **Branch off `main` after PR1 merges** so `CategoryBudgetSheet` is already standardized.
