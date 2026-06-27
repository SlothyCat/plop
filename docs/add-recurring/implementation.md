# Add Recurring Payment from Settings — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "+ Add recurring payment" button in Settings → Recurring payments that opens the existing Entry page pre-set to Monthly, creating a `RecurringRule` on save. Per `docs/add-recurring/design.md`.

**Architecture:** Reuse `EntryView` via a new optional `initialRecurrence` parameter; present it as a nested `fullScreenCover` from `RecurringRulesSheet`. Saving runs the existing recurring-confirm → `RecurringActions.create` path; the sheet's `@Query` refreshes.

**Tech Stack:** Swift, SwiftUI, SwiftData. iOS 18.

Single PR on `feature/add-recurring-from-settings` (off `main`; the design spec is committed there).

---

## Context for the implementer

- `RecurringActions.create(from:in:)` already builds the rule + its first occurrence; do not
  change it. `EntryView` already calls it on save when `recurrence != .none`, including the
  success haptic and the "Recurring payment" confirm dialog.
- `RecurringRule` rows are shown via `@Query(sort: \RecurringRule.createdAt)` in
  `RecurringRulesSheet`, so a newly created rule appears automatically after the Entry page
  dismisses.
- `EntryView` is self-contained (own ×/dismiss) and is already presented as a `fullScreenCover`
  elsewhere (Home edit), so presenting it from the Settings popup works the same way.

### Build / test / lint commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:"
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 \
  | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
swiftlint lint 2>&1 | tail -1
```

> SourceKit "Cannot find X" / "No such module" diagnostics are FALSE positives — `xcodebuild`
> is the source of truth. Lines ≤ 120. No `// swiftlint:disable`. Keep the baseline (19/0).

---

## File structure

- **Modify** `plop/plop/Views/Entry/EntryView.swift` — add `initialRecurrence` + apply it on add.
- **Modify** `plop/plop/Views/Settings/RecurringRulesSheet.swift` — add button + state + cover.

---

## Task 1: EntryView accepts an initial recurrence

**Files:** `plop/plop/Views/Entry/EntryView.swift`

- [ ] **Step 1: Add the parameter**

Change:
```swift
struct EntryView: View {
    var editing: Transaction?
```
to:
```swift
struct EntryView: View {
    var editing: Transaction?
    var initialRecurrence: RecurrenceInterval = .none
```

- [ ] **Step 2: Apply it on a fresh add**

In `prefillIfEditing()`, change:
```swift
    private func prefillIfEditing() {
        guard let tx = editing else {
            input = AmountInput(maxFractionDigits: currencyFractionDigits(currencyCode: currencyCode))
            return
        }
```
to:
```swift
    private func prefillIfEditing() {
        guard let tx = editing else {
            input = AmountInput(maxFractionDigits: currencyFractionDigits(currencyCode: currencyCode))
            recurrence = initialRecurrence
            return
        }
```

- [ ] **Step 3: Build** → `** BUILD SUCCEEDED **` (existing call sites use the default, unchanged).
- [ ] **Step 4: Lint** → 19/0.
- [ ] **Step 5: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Entry/EntryView.swift
git commit -m "Let EntryView open with an initial recurrence

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Add-button + Entry presentation in RecurringRulesSheet

**Files:** `plop/plop/Views/Settings/RecurringRulesSheet.swift`

- [ ] **Step 1: Add the state flag**

Change:
```swift
    @State private var pendingCancel: RecurringRule?
    @State private var listHeight: CGFloat = 0
```
to:
```swift
    @State private var pendingCancel: RecurringRule?
    @State private var addingRecurring = false
    @State private var listHeight: CGFloat = 0
```

- [ ] **Step 2: Pin the add button + present the Entry cover**

Change the `body`'s root container:
```swift
        VStack(spacing: 0) {
            header
            if rules.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 8) { ForEach(rules) { row($0) } }
                        .padding(.horizontal, 20).padding(.vertical, 4)
                        .readHeight(into: $listHeight)
                }
                .frame(maxHeight: scrollCap)
            }
        }
        .confirmationDialog("Stop this recurring payment?",
```
to:
```swift
        VStack(spacing: 0) {
            header
            if rules.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 8) { ForEach(rules) { row($0) } }
                        .padding(.horizontal, 20).padding(.vertical, 4)
                        .readHeight(into: $listHeight)
                }
                .frame(maxHeight: scrollCap)
            }
            addButton
        }
        .fullScreenCover(isPresented: $addingRecurring) {
            EntryView(initialRecurrence: .monthly)
        }
        .confirmationDialog("Stop this recurring payment?",
```

- [ ] **Step 3: Add the `addButton` view**

Add after the `header` computed property (mirrors Manage categories' add button):
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

- [ ] **Step 4: Build** → `** BUILD SUCCEEDED **`.
- [ ] **Step 5: Lint** → 19/0.
- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/RecurringRulesSheet.swift
git commit -m "Add recurring payments from the Settings recurring sheet

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full build** → `** BUILD SUCCEEDED **`.
- [ ] **Step 2: Full test suite** → `** TEST SUCCEEDED **`, 188 tests (unchanged — no logic change).
- [ ] **Step 3: Lint** → 19/0.
- [ ] **Step 4: Simulator smoke check (manual — owner), light + dark:**
  - Settings → Recurring payments → tap **Add recurring payment** → the Entry page opens with
    the recurring icon active and "Repeats monthly".
  - Enter an amount, pick a category, Save → the recurring-confirm appears → Create → returns to
    the sheet and the new rule is listed (and a first occurrence shows on Home/Insights).
  - The **empty state** also shows the button (a first rule can be added).
  - The × / cancel on the Entry page returns without creating anything.
- [ ] **Step 5: Push + PR**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git push -u origin feature/add-recurring-from-settings
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Add a "Add recurring payment" button to Settings → Recurring payments that opens the existing
Entry page pre-set to Monthly; saving creates the rule via the existing RecurringActions.create
path. EntryView gains an optional initialRecurrence parameter.

## Testing
188 unit tests pass (no new — reuses the tested create path); SwiftLint clean (19/0).
Sim-verified: add button opens Entry as recurring, saving creates a listed rule; empty state
shows the button; light + dark.
```

---

## Self-review notes

- **Spec coverage:** `initialRecurrence` param + applied on add (Task 1); add button + state +
  cover, button in both states (Task 2); verify (Task 3). All design items map to a step.
- **Reuse:** no change to `RecurringActions`, `RecurringRule`, or the data model; the create
  path and success haptic come for free via `EntryView`.
- **Type consistency:** `EntryView(initialRecurrence:)` matches the new parameter; existing
  call sites (`EntryView()`, `EntryView(editing:)`) keep working via the default.
- **No new unit tests** (reuses tested logic; param is presentation — project convention).
- **No placeholders / no disables / config untouched / lines ≤ 120.**
