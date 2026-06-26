# Invalid-Action Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give an error ("no") haptic + inline red highlight & caption when a user taps a primary action on an incomplete form, replacing silently-disabled buttons. Per `docs/invalid-feedback/design.md`.

**Architecture:** `Haptics.error()` + two pure, unit-tested validation-message helpers + a semantic `Palette.danger`. The three disabled primary buttons (Entry confirm, Category save, Bug-report send) become always-tappable and validate on tap; Export already validates on tap and just gains the error haptic. Invalid tap → `Haptics.error()` + a per-view `showValidationErrors` flag drives derived red highlights + a caption that clears as each field becomes valid.

**Tech Stack:** Swift, SwiftUI, UIKit, XCTest. iOS 18.

Single PR on `feature/invalid-feedback`.

> **Dependency:** the haptics PR (`feature/haptics`) must be merged into `main` first, so
> `plop/plop/Services/Haptics.swift` exists. Then rebase this branch on `main` (or re-create it)
> before implementing. Confirm with: `test -f plop/plop/Services/Haptics.swift && grep -q "func success" plop/plop/Services/Haptics.swift && echo OK`.

---

## Context for the implementer

- `Color.dynamic(light, dark)` is the existing pattern for theme-adaptive colours (see
  `Palette.incomeGreen`).
- `isCategoryNameAvailable(_:existing:editing:)` already exists in `Logic/CategoryValidation.swift`
  (false for empty **or** duplicate names). `CategoryValidationTests.swift` already tests it.
- `AmountInput.canSave` is `value > 0`. `EntryView.canSave` is `input.canSave && selected != nil`.
- All call sites are SwiftUI button actions (main-actor); call `Haptics.error()` directly.
- Highlights/captions are **derived** from `showValidationErrors && <field still invalid>`, so
  they clear automatically — never store per-field error booleans as state.

### Build / test / lint commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
# Build
xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:"
# A single test class
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -parallel-testing-enabled NO \
  -only-testing:plopTests/EntryValidationTests 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
# Lint
swiftlint lint 2>&1 | tail -1
```

> SourceKit "Cannot find X" / "No such module" diagnostics are FALSE positives — `xcodebuild`
> is the source of truth. Lines ≤ 120. No `// swiftlint:disable`. Keep the baseline (19/0).

---

## File structure

- **Create** `plop/plop/Logic/EntryValidation.swift` — `entryValidationMessage(...)`.
- **Create** `plop/plopTests/EntryValidationTests.swift` — its tests.
- **Modify** `plop/plop/Logic/CategoryValidation.swift` — add `categoryNameMessage(...)`.
- **Modify** `plop/plopTests/CategoryValidationTests.swift` — add its tests.
- **Modify** `plop/plop/Services/Haptics.swift` — add `error()`.
- **Modify** `plop/plop/Theme/Palette.swift` — add `danger`.
- **Modify** `EntryView.swift`, `Keypad.swift`, `CategoryFormView.swift`, `BugReportSheet.swift`,
  `ExportSheet.swift` — tap-to-validate + red highlights + captions.

---

## Task 1: Foundations (TDD helpers, haptic, colour)

**Files:** create `Logic/EntryValidation.swift`, `plopTests/EntryValidationTests.swift`; modify
`Logic/CategoryValidation.swift`, `plopTests/CategoryValidationTests.swift`,
`Services/Haptics.swift`, `Theme/Palette.swift`.

- [ ] **Step 1: Write the failing Entry-validation tests**

Create `plop/plopTests/EntryValidationTests.swift`:
```swift
import XCTest
@testable import plop

final class EntryValidationTests: XCTestCase {
    func test_validWhenAmountAndCategoryPresent() {
        XCTAssertNil(entryValidationMessage(hasAmount: true, hasCategory: true))
    }

    func test_missingAmountOnly() {
        XCTAssertEqual(entryValidationMessage(hasAmount: false, hasCategory: true),
                       "Enter an amount.")
    }

    func test_missingCategoryOnly() {
        XCTAssertEqual(entryValidationMessage(hasAmount: true, hasCategory: false),
                       "Pick a category.")
    }

    func test_missingBoth() {
        XCTAssertEqual(entryValidationMessage(hasAmount: false, hasCategory: false),
                       "Enter an amount and pick a category.")
    }
}
```

- [ ] **Step 2: Run it — expect FAIL** (`entryValidationMessage` undefined)

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -parallel-testing-enabled NO \
  -only-testing:plopTests/EntryValidationTests 2>&1 | grep -E "error:|TEST (SUCCEEDED|FAILED)" | tail -3
```
Expected: compile failure / FAIL.

- [ ] **Step 3: Implement `entryValidationMessage`**

Create `plop/plop/Logic/EntryValidation.swift`:
```swift
import Foundation

/// The caption shown when an expense can't be saved, or nil when it's valid.
func entryValidationMessage(hasAmount: Bool, hasCategory: Bool) -> String? {
    switch (hasAmount, hasCategory) {
    case (true, true):   return nil
    case (false, true):  return "Enter an amount."
    case (true, false):  return "Pick a category."
    case (false, false): return "Enter an amount and pick a category."
    }
}
```

- [ ] **Step 4: Run — expect PASS** (same command as Step 2 → `** TEST SUCCEEDED **`).

- [ ] **Step 5: Add the failing category-message tests**

Append inside `plop/plopTests/CategoryValidationTests.swift` (before the closing `}`):
```swift
    func test_message_nilWhenAvailable() {
        XCTAssertNil(categoryNameMessage(name: "Transport", isAvailable: true))
    }

    func test_message_emptyName() {
        XCTAssertEqual(categoryNameMessage(name: "  ", isAvailable: false), "Enter a name.")
    }

    func test_message_duplicateName() {
        XCTAssertEqual(categoryNameMessage(name: "Food", isAvailable: false),
                       "That name's already taken.")
    }
```

- [ ] **Step 6: Run — expect FAIL** (`-only-testing:plopTests/CategoryValidationTests`).

- [ ] **Step 7: Implement `categoryNameMessage`**

Append to `plop/plop/Logic/CategoryValidation.swift`:
```swift

/// The caption shown when a category name can't be saved, or nil when it's valid.
/// `isAvailable` is the `isCategoryNameAvailable(...)` result for the same name.
func categoryNameMessage(name: String, isAvailable: Bool) -> String? {
    if isAvailable { return nil }
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "Enter a name." : "That name's already taken."
}
```

- [ ] **Step 8: Run — expect PASS** (`-only-testing:plopTests/CategoryValidationTests`).

- [ ] **Step 9: Add `Haptics.error()`**

In `plop/plop/Services/Haptics.swift`, add inside the `Haptics` enum after `success()`:
```swift
    @MainActor static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
```

- [ ] **Step 10: Add `Palette.danger`**

In `plop/plop/Theme/Palette.swift`, add next to `incomeGreen`:
```swift
    static let danger = Color.dynamic(Color(hex: "#C0392B"), Color(hex: "#FF6B5E"))
```

- [ ] **Step 11: Build + full-suite + lint**

Build → `** BUILD SUCCEEDED **`. Lint → 19/0. Run the two new/edited classes (Steps 4 & 8) green.

- [ ] **Step 12: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Logic/EntryValidation.swift plop/plopTests/EntryValidationTests.swift \
  plop/plop/Logic/CategoryValidation.swift plop/plopTests/CategoryValidationTests.swift \
  plop/plop/Services/Haptics.swift plop/plop/Theme/Palette.swift
git commit -m "Add error haptic, danger colour, and validation-message helpers

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Entry — always-active confirm + validate-on-tap

**Files:** `Views/Entry/Keypad.swift`, `Views/Entry/EntryView.swift`.

- [ ] **Step 1: Make the Keypad confirm key always active**

In `Keypad.swift`, remove the `canConfirm` parameter:
```swift
    var onKey: (String) -> Void
    var onConfirm: () -> Void
    var canConfirm: Bool
```
→
```swift
    var onKey: (String) -> Void
    var onConfirm: () -> Void
```
And in `confirmKey`, drop the dim + disable:
```swift
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundStyle(Palette.tileInk)
                .opacity(canConfirm ? 1 : 0.4)
        }
        .disabled(!canConfirm)
        .accessibilityIdentifier("key-confirm")
```
→
```swift
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundStyle(Palette.tileInk)
        }
        .accessibilityIdentifier("key-confirm")
```

- [ ] **Step 2: Stop passing `canConfirm`**

In `EntryView.swift`:
```swift
        Keypad(onKey: { input.press($0) }, onConfirm: confirm, canConfirm: canSave)
```
→
```swift
        Keypad(onKey: { input.press($0) }, onConfirm: confirm)
```

- [ ] **Step 3: Add the validation flag + derived invalids**

Add to the `@State` block (after `showingRecurringConfirm`):
```swift
    @State private var showValidationErrors = false
```
Add next to `canSave` (after `private var canSave: Bool { input.canSave && selected != nil }`):
```swift
    private var amountInvalid: Bool { showValidationErrors && !input.canSave }
    private var categoryInvalid: Bool { showValidationErrors && selected == nil }
```

- [ ] **Step 4: Validate on tap in `confirm()`**

```swift
    private func confirm() {
        guard canSave else { return }
        if editing == nil && recurrence != .none {
```
→
```swift
    private func confirm() {
        guard canSave else {
            showValidationErrors = true
            Haptics.error()
            return
        }
        if editing == nil && recurrence != .none {
```

- [ ] **Step 5: Red amount + caption**

In `amountArea`, change the amount value colour:
```swift
                Text(input.display())
                    .font(.system(size: 66, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
```
→
```swift
                Text(input.display())
                    .font(.system(size: 66, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(amountInvalid ? Palette.danger : Palette.ink)
```
Then add the caption immediately after the amount `HStack` closes (the `}` ending the
`HStack(alignment: .firstTextBaseline, spacing: 4) { … }`), as the next element inside the
`VStack(spacing: 18)`:
```swift
            if showValidationErrors,
               let message = entryValidationMessage(hasAmount: input.canSave,
                                                     hasCategory: selected != nil) {
                Text(message)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Palette.danger)
                    .multilineTextAlignment(.center)
            }
```

- [ ] **Step 6: Red category pill**

In `detailPills`, the category `Button`'s label, change:
```swift
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(selected != nil ? Palette.tileInk : Palette.ink60)
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
                .background(selected.map { Color(hex: $0.colorHex) } ?? Palette.card, in: Capsule())
                .overlay(Capsule().stroke(Palette.ink12, lineWidth: 1))
```
→
```swift
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(categoryInvalid ? Palette.danger
                                 : (selected != nil ? Palette.tileInk : Palette.ink60))
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
                .background(selected.map { Color(hex: $0.colorHex) } ?? Palette.card, in: Capsule())
                .overlay(Capsule().stroke(categoryInvalid ? Palette.danger : Palette.ink12,
                                          lineWidth: categoryInvalid ? 1.5 : 1))
```

- [ ] **Step 7: Build + lint** → BUILD SUCCEEDED, 19/0.
- [ ] **Step 8: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Entry/Keypad.swift plop/plop/Views/Entry/EntryView.swift
git commit -m "Validate add-expense on tap with error haptic and inline highlights

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Category form — validate-on-tap

**Files:** `Views/Settings/CategoryFormView.swift`.

- [ ] **Step 1: Add the validation flag + derived invalid**

Add to the `@State` block (near `@State private var name = ""`):
```swift
    @State private var showValidationErrors = false
```
Add next to `canSave` (the `private var canSave: Bool { isCategoryNameAvailable(...) }`):
```swift
    private var nameInvalid: Bool { showValidationErrors && !canSave }
```

- [ ] **Step 2: Always-tappable Save that validates**

```swift
                Button { save() } label: {
                    Text("Save")
                }
                .buttonStyle(PopupPrimaryButton(enabled: canSave)).disabled(!canSave)
```
→
```swift
                Button {
                    if canSave { save() } else { showValidationErrors = true; Haptics.error() }
                } label: {
                    Text("Save")
                }
                .buttonStyle(PopupPrimaryButton())
```

- [ ] **Step 3: Red name field + caption**

Replace the `field("NAME") { … }` block:
```swift
            field("NAME") {
                TextField("e.g. Transport", text: $name)
                    .font(.system(size: 16)).foregroundStyle(Palette.ink)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(Palette.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.ink12, lineWidth: 1))
            }
```
with:
```swift
            field("NAME") {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("e.g. Transport", text: $name)
                        .font(.system(size: 16)).foregroundStyle(Palette.ink)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(Palette.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 13)
                            .stroke(nameInvalid ? Palette.danger : Palette.ink12,
                                    lineWidth: nameInvalid ? 1.5 : 1))
                    if showValidationErrors,
                       let message = categoryNameMessage(name: name, isAvailable: canSave) {
                        Text(message)
                            .font(.system(size: 13)).foregroundStyle(Palette.danger)
                    }
                }
            }
```

- [ ] **Step 4: Build + lint** → BUILD SUCCEEDED, 19/0.
- [ ] **Step 5: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/CategoryFormView.swift
git commit -m "Validate category form on tap with error haptic and inline name highlight

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Bug report — validate-on-tap

**Files:** `Views/Settings/BugReportSheet.swift`.

- [ ] **Step 1: Add the validation flag + derived invalid**

Add to the `@State` block (near `@State private var description = ""`):
```swift
    @State private var showValidationErrors = false
```
Add next to `canSend` (the `private var canSend: Bool { … }`):
```swift
    private var descriptionInvalid: Bool { showValidationErrors && !canSend }
```

- [ ] **Step 2: Always-tappable Send that validates**

```swift
                Button { send() } label: { Text("Send") }
                    .buttonStyle(PopupPrimaryButton(enabled: canSend))
                    .disabled(!canSend)
```
→
```swift
                Button {
                    if canSend { send() } else { showValidationErrors = true; Haptics.error() }
                } label: { Text("Send") }
                    .buttonStyle(PopupPrimaryButton())
```

- [ ] **Step 3: Red description box + caption**

Change the description container overlay:
```swift
            .background(Palette.field, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.ink12, lineWidth: 1))

            label("SCREENSHOT · OPTIONAL")
```
→
```swift
            .background(Palette.field, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13)
                .stroke(descriptionInvalid ? Palette.danger : Palette.ink12,
                        lineWidth: descriptionInvalid ? 1.5 : 1))
            if descriptionInvalid {
                Text("Add a description first.")
                    .font(.system(size: 13)).foregroundStyle(Palette.danger)
            }

            label("SCREENSHOT · OPTIONAL")
```

- [ ] **Step 4: Build + lint** → BUILD SUCCEEDED, 19/0.
- [ ] **Step 5: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/BugReportSheet.swift
git commit -m "Validate bug report on tap with error haptic and inline highlight

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Export error feedback + verify + PR

**Files:** `Views/Settings/ExportSheet.swift`.

- [ ] **Step 1: Error haptic + red notice on empty range**

In `runExport()`:
```swift
        guard !sheets.isEmpty else { emptyNotice = true; return }
```
→
```swift
        guard !sheets.isEmpty else { emptyNotice = true; Haptics.error(); return }
```
And colour the existing notice red:
```swift
            if emptyNotice {
                Text("No transactions in this range.")
                    .font(.system(size: 13.5)).foregroundStyle(Palette.ink60)
            }
```
→
```swift
            if emptyNotice {
                Text("No transactions in this range.")
                    .font(.system(size: 13.5)).foregroundStyle(Palette.danger)
            }
```

- [ ] **Step 2: Build** → `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Full test suite** (must include the new tests and stay green)

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 \
  | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **`, **188 tests** (181 + 7 new).

- [ ] **Step 4: Lint** → 19/0.

- [ ] **Step 5: Simulator + device smoke check (manual — owner).** Sim shows the red
  highlights/captions; a **physical device** confirms the error buzz.
  - **Entry:** tap ✓ with no amount and no category → error buzz, amount turns red, category
    pill turns red, caption "Enter an amount and pick a category."; type an amount → amount +
    that half of the caption clear; pick a category → all clear; ✓ saves with the success buzz.
  - **Category form:** Save with empty name → error buzz, red name field, "Enter a name.";
    type a duplicate → "That name's already taken."; type a unique name → clears, Save works.
  - **Bug report:** Send with empty description → error buzz, red box, "Add a description
    first."; type text → clears, Send opens Mail.
  - **Export:** pick a range with no transactions → Export → error buzz + red "No transactions
    in this range."
  - Light **and** dark.

- [ ] **Step 6: Commit + push + PR**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/ExportSheet.swift
git commit -m "Buzz and flag an empty export range

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
git push -u origin feature/invalid-feedback
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Replace silently-disabled primary buttons with tap-to-validate feedback: an error haptic plus
an inline red highlight + caption naming what's missing, across Entry (amount/category),
Category form (name), Bug report (description), and Export (empty range). Adds Haptics.error(),
Palette.danger, and two unit-tested validation-message helpers.

## Testing
188 unit tests pass (7 new for the validation helpers); SwiftLint clean (19/0). Device-verified
each form buzzes with the error pattern and shows the right red field + caption, clearing as
fields are fixed; valid submits behave as before. Light + dark.
```

---

## Self-review notes

- **Spec coverage:** `Haptics.error()` + `Palette.danger` + both helpers with tests (Task 1);
  Entry incl. always-active confirm (Task 2); Category form (Task 3); Bug report (Task 4);
  Export (Task 5). All design sections map to a task.
- **Derived, not stored:** every highlight/caption is computed from
  `showValidationErrors && <still invalid>`, so it self-clears — matches the design.
- **Behaviour unchanged for valid input:** each button's success path (`save()`/`send()`/
  `performSave()` + existing success haptic) is untouched; only the invalid branch is new.
- **TDD:** the two pure helpers are tested first (Steps 1–8); view effects (haptic, red) are
  not unit-tested, per project convention.
- **Type consistency:** `entryValidationMessage(hasAmount:hasCategory:)`,
  `categoryNameMessage(name:isAvailable:)`, `Haptics.error()`, `Palette.danger` used identically
  in views and tests. `canSave`/`canSend`/`emptyNotice` semantics unchanged.
- **Dependency:** requires `Services/Haptics.swift` from the merged haptics PR (noted up top).
- **No placeholders / no disables / config untouched / lines ≤ 120.**
