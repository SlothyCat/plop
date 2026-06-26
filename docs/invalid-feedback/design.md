# Invalid-Action Feedback — Design

Status: Approved · Date: 2026-06-26

## Goal

When a user tries to commit an incomplete form, give a distinct **error ("no") haptic** plus an
**inline, on-screen indication of what's missing** — instead of a silently disabled button.
Starts from add-expense and covers every validated form in the app.

## Decisions (approved)

1. **Inline highlight + caption** — the missing field(s) turn red and a short caption says what
   to fix. No modal alert (keeps the clean, minimal handoff aesthetic).
2. **All forms with validation** — Entry, Category form, Bug report, Export.
3. **Drop the disabled state** on the three currently-disabled primary buttons (Entry confirm,
   Category save, Bug-report send): they become always tappable and **validate on tap**.
4. **Reuses `Haptics`** — adds `Haptics.error()` next to the existing `Haptics.success()`.

> **Dependency:** branch off `main` **after the haptics PR (`feature/haptics`) is merged**, so
> `plop/plop/Services/Haptics.swift` exists. This feature only adds `error()` to it.

## Interaction model

The primary action is always tappable. On tap:
- **Valid** → proceed exactly as today (and the existing `Haptics.success()` fires).
- **Invalid** → `Haptics.error()`, set a per-view `showValidationErrors = true`, and **do not**
  perform the action.

When `showValidationErrors` is on, each field's highlight + the caption are **derived** from
whether that field is *still* invalid, so they **clear automatically** as the user fixes each
one (e.g. picking a category clears the category highlight). Feedback only appears **after** a
failed tap — never before the user attempts to submit.

## Component changes

### `Haptics` (`plop/plop/Services/Haptics.swift`)
Add:
```swift
@MainActor static func error() {
    UINotificationFeedbackGenerator().notificationOccurred(.error)
}
```

### Validation logic (testable, pure) — `plop/plop/Logic/Validation.swift` (new)
```swift
/// The caption shown when an expense can't be saved, or nil when it's valid.
func entryValidationMessage(hasAmount: Bool, hasCategory: Bool) -> String? {
    switch (hasAmount, hasCategory) {
    case (true, true):   return nil
    case (false, true):  return "Enter an amount."
    case (true, false):  return "Pick a category."
    case (false, false): return "Enter an amount and pick a category."
    }
}

/// The caption shown when a category name can't be saved, or nil when it's valid.
/// `isAvailable` is the existing `isCategoryNameAvailable(...)` result.
func categoryNameMessage(name: String, isAvailable: Bool) -> String? {
    if isAvailable { return nil }
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "Enter a name." : "That name's already taken."
}
```
Bug-report and Export captions are fixed strings with no branching, so they need no helper.

## Per-form behaviour

### 1. Entry (`Views/Entry/EntryView.swift`, `Views/Entry/Keypad.swift`)
- **Keypad confirm key becomes always active**: drop `canConfirm` gating — remove
  `.disabled(!canConfirm)` and the `0.4` dim so the ✓ is always full-opacity and tappable.
  `Keypad`'s `canConfirm` parameter is removed (EntryView stops passing it).
- `EntryView.confirm()`: replace `guard canSave else { return }` with —
  if `canSave`, proceed as today; else `showValidationErrors = true` + `Haptics.error()`.
- `@State private var showValidationErrors = false`.
- Derived: `amountInvalid = showValidationErrors && !input.canSave`;
  `categoryInvalid = showValidationErrors && selected == nil`.
- **Highlight:** amount `Text` foreground turns the app's error red when `amountInvalid`; the
  category pill border/label turns red when `categoryInvalid`.
- **Caption:** below the amount area, show
  `entryValidationMessage(hasAmount: input.canSave, hasCategory: selected != nil)` in error red
  when `showValidationErrors` and it is non-nil.

### 2. Category form (`Views/Settings/CategoryFormView.swift`)
- Save button becomes always tappable: `PopupPrimaryButton(enabled: true)` and drop
  `.disabled(!canSave)`.
- Button action: if `canSave`, run the existing `save()`; else `showValidationErrors = true` +
  `Haptics.error()` (do **not** close).
- `@State private var showValidationErrors = false`.
- **Highlight:** the name `TextField`'s container border turns error red when
  `showValidationErrors && !canSave`.
- **Caption:** under the name field, `categoryNameMessage(name: name, isAvailable: canSave)`
  in error red when `showValidationErrors` and non-nil.

### 3. Bug report (`Views/Settings/BugReportSheet.swift`)
- Send button becomes always tappable: `PopupPrimaryButton(enabled: true)` and drop
  `.disabled(!canSend)`.
- Button action: if `canSend`, run the existing `send()`; else `showValidationErrors = true` +
  `Haptics.error()`.
- `@State private var showValidationErrors = false`.
- **Highlight:** the description `TextEditor`'s container turns error red when
  `showValidationErrors && !canSend`.
- **Caption:** "Add a description first." in error red when `showValidationErrors && !canSend`.

### 4. Export (`Views/Settings/ExportSheet.swift`)
- Already validates on tap (`runExport()` sets `emptyNotice = true` for an empty range). Add
  `Haptics.error()` at that point, and render the existing "No transactions in this range."
  notice in the error red.

## Error colour

No red token exists today. Add a single semantic `Palette.danger`, mirroring the existing
`incomeGreen` dynamic pattern — a light-theme red plus a brighter dark-theme variant — so all
highlights/captions are consistent and theme-correct:
```swift
static let danger = Color.dynamic(Color(hex: "#C0392B"), Color(hex: "#FF6B5E"))
```

## Testing

- **Unit tests (XCTest), TDD:** `entryValidationMessage(...)` (all four combinations) and
  `categoryNameMessage(...)` (valid / empty / duplicate). These are pure and deterministic.
- **No tests for haptics or red highlights** (view/hardware effects) — verified on device/sim:
  tapping confirm/save/send while incomplete buzzes with the *error* pattern, shows the right
  red field(s) + caption, and the feedback clears as each field is fixed; a valid submit behaves
  exactly as before (success haptic, saves, dismisses).
- **No regressions:** existing suite stays green; build succeeds; SwiftLint at baseline (19/0).

## Scope

**In:** `Haptics.error()`; a new `Logic/Validation.swift` with two tested helpers; the four
forms' tap-to-validate + inline red highlight + caption; `Palette.danger`.

**Out:** modal alerts/toasts; validating non-form interactions; changing what counts as valid
(the existing `canSave`/`canSend`/empty-range rules are unchanged); the data layer.

## Decomposition (single PR, `feature/invalid-feedback`)

- Task 1: `Haptics.error()` + `Logic/Validation.swift` (TDD) + `Palette.danger`.
- Task 2: Entry (Keypad always-active + validate-on-tap + highlights + caption).
- Task 3: Category form (validate-on-tap + highlight + caption).
- Task 4: Bug report (validate-on-tap + highlight + caption).
- Task 5: Export (error haptic + red notice) + final verify + PR.
