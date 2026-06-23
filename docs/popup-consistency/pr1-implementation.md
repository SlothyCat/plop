# Popup Consistency PR1 (CategoryBudgetSheet) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the Insights per-category budget popup (`CategoryBudgetSheet`) to the shared `BlurPopup` standard (top-right ×, `PopupPrimaryButton`, live theme).

**Architecture:** Present it via `.blurPopup(item:)` instead of `.sheet(item:)`; the view dismisses via `\.blurPopupClose`, uses `PopupPrimaryButton` for Save, and drops its grabber-era chrome (detents / own background / Cancel).

**Tech Stack:** SwiftUI. iOS 18. Presentation only — no tests.

Single PR on branch `feature/insights-budget-popup` (off `main`; spec committed there).

---

## File structure

- **Modify** `plop/plop/Views/Insights/CategoryBudgetSheet.swift` — use `\.blurPopupClose`, `PopupPrimaryButton`, drop Cancel/detents/background/Spacer.
- **Modify** `plop/plop/Views/Insights/InsightsView.swift` — `.sheet(item:)` → `.blurPopup(item:)`.

### Build / lint commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | tail -5

swiftlint lint
```

> SourceKit "Cannot find X" diagnostics are FALSE positives — `xcodebuild` is the source of
> truth. Lines ≤ 120. No `// swiftlint:disable`. Keep the lint baseline (19 violations, 0
> serious). `BlurPopup`, `\.blurPopupClose`, and `PopupPrimaryButton` already exist.

---

## Task 1: Convert CategoryBudgetSheet + present via BlurPopup

**Files:**
- Modify: `plop/plop/Views/Insights/CategoryBudgetSheet.swift`
- Modify: `plop/plop/Views/Insights/InsightsView.swift`

- [ ] **Step 1: Swap the dismiss closure for `\.blurPopupClose`**

In `CategoryBudgetSheet.swift`, change:
```swift
    let category: ExpenseCategory
    var onDone: () -> Void

    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @State private var field = ""
```
to:
```swift
    let category: ExpenseCategory

    @Environment(\.blurPopupClose) private var close
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @State private var field = ""
```

- [ ] **Step 2: Standard button + drop the sheet chrome**

Change the button block + trailing modifiers:
```swift
            VStack(spacing: 8) {
                Button { save() } label: {
                    Text("Save budget").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Palette.accent)
                Button("Cancel") { onDone() }
                    .foregroundStyle(Palette.ink60)
            }

            Spacer()
        }
        .padding(20)
        .background(Palette.bg)
        .onAppear { field = formatBudgetAmount(category.budget) }
        .presentationDetents([.medium])
    }
```
to:
```swift
            Button { save() } label: { Text("Save budget") }
                .buttonStyle(PopupPrimaryButton())
        }
        .padding(20)
        .onAppear { field = formatBudgetAmount(category.budget) }
    }
```
(Removes the `VStack` wrapper + "Cancel", the trailing `Spacer()`, `.background(Palette.bg)`,
and `.presentationDetents([.medium])`. The card hugs; × dismisses.)

- [ ] **Step 3: `save()` closes via `close()`**

Change:
```swift
    private func save() {
        category.budget = parseBudgetAmount(field)
        onDone()
    }
```
to:
```swift
    private func save() {
        category.budget = parseBudgetAmount(field)
        close()
    }
```

- [ ] **Step 4: Update the preview**

Change:
```swift
    CategoryBudgetSheet(
        category: ExpenseCategory(name: "Food", symbolName: "fork.knife",
                                  colorHex: "#FFEBCC", budget: 300),
        onDone: {})
```
to:
```swift
    CategoryBudgetSheet(
        category: ExpenseCategory(name: "Food", symbolName: "fork.knife",
                                  colorHex: "#FFEBCC", budget: 300))
```

- [ ] **Step 5: Present via `.blurPopup(item:)` in InsightsView**

In `InsightsView.swift`, change:
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

- [ ] **Step 6: Build** — run the build command → `** BUILD SUCCEEDED **`.

- [ ] **Step 7: Lint** — `swiftlint lint` → no new violations (baseline 19/0).

- [ ] **Step 8: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Insights/CategoryBudgetSheet.swift plop/plop/Views/Insights/InsightsView.swift
git commit -m "Present the category budget editor as a BlurPopup (× + standard Save)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite** (presentation only — nothing should break)

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` (unchanged count).

- [ ] **Step 2: Lint** — `swiftlint lint` → baseline 19/0.

- [ ] **Step 3: Simulator smoke check (manual — owner)**, light + dark:
- Insights → **Budget** mode → tap a category row → it opens as a **blurred bottom card**
  with a **top-right ×**, the icon/name header, the $-field, and a **Save budget** button that
  matches Save/Add category (accent fill, tile-ink text);
- typing a number and **Save** writes the budget and dismisses; **×** / drag dismiss without
  saving; the popup follows the **theme**.

- [ ] **Step 4: Push + PR**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git push -u origin feature/insights-budget-popup
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Popup consistency (PR1): the Insights per-category budget editor (CategoryBudgetSheet) now
uses BlurPopup — top-right ×, standard PopupPrimaryButton Save, live theme — instead of a
plain .sheet with a blue Save + Cancel.

## Testing
All unit tests pass (no new — presentation); SwiftLint clean (19/0). Sim-verified: blurred
card, ×, standard Save writes + closes; light + dark.
```

---

## Self-review notes

- **Spec coverage (PR1):** `\.blurPopupClose` (Step 1/3), `PopupPrimaryButton` + drop
  Cancel/detents/background/Spacer (Step 2), preview (Step 4), `.blurPopup(item:)` in
  InsightsView (Step 5), verify (Task 2). All PR1 spec items map to a step.
- **Type consistency:** `CategoryBudgetSheet(category:)` (no `onDone`) matches the new
  `.blurPopup(item:)` call; `\.blurPopupClose`, `PopupPrimaryButton` are existing; the
  `category.budget` / `parseBudgetAmount` / `formatBudgetAmount` logic is unchanged.
- **Behaviour:** budget write unchanged; only presentation/dismissal/button style change. No
  unit tests (presentation; project convention).
- **No placeholders / no disables / config untouched / lines ≤ 120.**
- **PR2 (Entry popups) is a separate plan.**
