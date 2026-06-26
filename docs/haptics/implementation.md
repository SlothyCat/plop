# Haptic Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fire one uniform `.success` haptic to confirm each of 10 committed user actions, per `docs/haptics/design.md`.

**Architecture:** A 3-line `Haptics` service (`UINotificationFeedbackGenerator`) is called imperatively at each action's commit point in the view layer. No data-layer changes, no Settings UI, no in-app toggle (the generator auto-respects the system haptics setting).

**Tech Stack:** Swift, SwiftUI, UIKit (feedback generator). iOS 18.

Single PR on `feature/haptics` (off `main`; the design spec is already committed there).

---

## Context for the implementer

- The actions live in views; the data layer (`Data/*Actions.swift`) is untouched.
- **Fire only on a valid, committed action** — after `guard`/validation, never on Cancel, the
  top-right ×, drag-dismiss, or a failed/invalid/cancelled attempt. Exactly one per action.
- `Haptics.success()` is `@MainActor`; every call site is a SwiftUI button action or a
  view-body `.onChange`, which are already main-actor — call it directly (no `await`/wrapping).
- `MFMailComposeResult` (site #9) comes from `MessageUI`, already imported in `BugReportSheet`
  (it calls `MFMailComposeViewController.canSendMail()`). `ExportService.Phase` is `Equatable`
  (site #10), so `.onChange(of: service.phase)` is valid.

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

- **Create** `plop/plop/Services/Haptics.swift` — the `Haptics.success()` service.
- **Modify** 9 view files (10 call sites): `EntryView`, `CategoryBudgetSheet`, `BudgetView`,
  `CurrencyView`, `AppearanceSheet`, `CategoryFormView`, `RecurringSheet`, `RecurringRulesSheet`
  (synchronous), `BugReportSheet`, `ExportSheet` (async/state).

---

## Task 1: Add the Haptics service

**Files:** Create `plop/plop/Services/Haptics.swift`

- [ ] **Step 1: Create the file**

```swift
import UIKit

/// Fires the system "success" haptic to confirm a committed user action. Respects
/// iOS Settings → Sounds & Haptics → System Haptics automatically (the generator
/// no-ops when the user has disabled haptics), so there is no in-app toggle.
enum Haptics {
    @MainActor static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
```

- [ ] **Step 2: Add the file to the Xcode target** — confirm it compiles into `plop`.

> The `.xcodeproj` uses the modern file-system synchronized group, so files under
> `plop/plop/` are picked up automatically. Build to confirm; if `Haptics` is "not found"
> at a call site in a later task despite correct code, the file isn't in the target — add it
> via Xcode (owner) before proceeding.

- [ ] **Step 3: Build** → `** BUILD SUCCEEDED **`.
- [ ] **Step 4: Lint** → baseline 19/0.
- [ ] **Step 5: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Services/Haptics.swift
git commit -m "Add Haptics success-feedback service

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Wire the synchronous call sites (1–8)

**Files:** `EntryView.swift`, `CategoryBudgetSheet.swift`, `BudgetView.swift`,
`CurrencyView.swift`, `AppearanceSheet.swift`, `CategoryFormView.swift`, `RecurringSheet.swift`,
`RecurringRulesSheet.swift`.

- [ ] **Step 1 — Site 1: Add/save an entry** (`Views/Entry/EntryView.swift`, `performSave()`)

Change:
```swift
        } else {
            TransactionActions.add(draft, in: modelContext)
        }
        dismiss()
    }
```
to:
```swift
        } else {
            TransactionActions.add(draft, in: modelContext)
        }
        Haptics.success()
        dismiss()
    }
```

- [ ] **Step 2 — Site 2: Category budget (Insights)** (`Views/Insights/CategoryBudgetSheet.swift`, `save()`)

Change:
```swift
    private func save() {
        category.budget = parseBudgetAmount(field)
        close()
    }
```
to:
```swift
    private func save() {
        category.budget = parseBudgetAmount(field)
        Haptics.success()
        close()
    }
```

- [ ] **Step 3 — Site 3: Budget (Settings)** (`Views/Settings/BudgetView.swift`, Save button)

Change:
```swift
                Button { save(); close() } label: {
                    Text("Save budget")
                }
```
to:
```swift
                Button { save(); Haptics.success(); close() } label: {
                    Text("Save budget")
                }
```

- [ ] **Step 4 — Site 4: Change currency** (`Views/Settings/CurrencyView.swift`, row button — change-only)

Change:
```swift
                        Button { currencyCode = code } label: { row(code) }
                            .buttonStyle(.plain)
```
to:
```swift
                        Button {
                            if code != currencyCode { Haptics.success() }
                            currencyCode = code
                        } label: { row(code) }
                            .buttonStyle(.plain)
```

- [ ] **Step 5 — Site 5: Set theme** (`Views/Settings/AppearanceSheet.swift`, `card(_:)` — change-only)

Change:
```swift
        return Button { themeModeRaw = mode.rawValue } label: {
```
to:
```swift
        return Button {
            if mode.rawValue != themeModeRaw { Haptics.success() }
            themeModeRaw = mode.rawValue
        } label: {
```

- [ ] **Step 6 — Site 6: Create/save a category** (`Views/Settings/CategoryFormView.swift`, `save()`)

Change:
```swift
        } else {
            let created = CategoryActions.add(draft, in: modelContext)
            onSave?(created)
        }
        close()
    }
```
to:
```swift
        } else {
            let created = CategoryActions.add(draft, in: modelContext)
            onSave?(created)
        }
        Haptics.success()
        close()
    }
```

- [ ] **Step 7 — Site 7: Recurring interval (Entry)** (`Views/Entry/RecurringSheet.swift`, option button)

Change:
```swift
                Button {
                    recurrence = option.value
                    close()
                } label: { row(option) }
```
to:
```swift
                Button {
                    recurrence = option.value
                    Haptics.success()
                    close()
                } label: { row(option) }
```

- [ ] **Step 8 — Site 8: Stop a recurring rule (Settings)** (`Views/Settings/RecurringRulesSheet.swift`, "Stop recurring")

Change:
```swift
            Button("Stop recurring", role: .destructive) {
                RecurringActions.cancel(rule, in: modelContext)
                pendingCancel = nil
            }
```
to:
```swift
            Button("Stop recurring", role: .destructive) {
                RecurringActions.cancel(rule, in: modelContext)
                Haptics.success()
                pendingCancel = nil
            }
```

- [ ] **Step 9: Build** → `** BUILD SUCCEEDED **`.
- [ ] **Step 10: Lint** → baseline 19/0.
- [ ] **Step 11: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Entry/EntryView.swift plop/plop/Views/Insights/CategoryBudgetSheet.swift \
  plop/plop/Views/Settings/BudgetView.swift plop/plop/Views/Settings/CurrencyView.swift \
  plop/plop/Views/Settings/AppearanceSheet.swift plop/plop/Views/Settings/CategoryFormView.swift \
  plop/plop/Views/Entry/RecurringSheet.swift plop/plop/Views/Settings/RecurringRulesSheet.swift
git commit -m "Fire success haptic on entry, budget, currency, theme, category, and recurring actions

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Wire the async / state call sites (9–10)

These fire on **success only**, not on the triggering tap.

**Files:** `BugReportSheet.swift`, `ExportSheet.swift`.

- [ ] **Step 1 — Site 9: Report a bug** (`Views/Settings/BugReportSheet.swift`, Mail completion)

The Mail composer's `onFinish` receives an `MFMailComposeResult`; fire only when it is `.sent`.
Change:
```swift
                MailComposeView(subject: BugReport.subject, body: composedBody(),
                                imageData: imageData) { _ in
                    showingMail = false
                    close()
                }
```
to:
```swift
                MailComposeView(subject: BugReport.subject, body: composedBody(),
                                imageData: imageData) { result in
                    if result == .sent { Haptics.success() }
                    showingMail = false
                    close()
                }
```

- [ ] **Step 2 — Site 10: Export to Google Sheets** (`Views/Settings/ExportSheet.swift`, `body`)

Fire when the export phase becomes `.success` (the success screen), not on the Export tap.
`ExportService.Phase` is `Equatable`, and `body` is main-actor, so use `.onChange`. Change:
```swift
    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
```
to:
```swift
    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: service.phase) { _, phase in
                if case .success = phase { Haptics.success() }
            }
    }
```

- [ ] **Step 3: Build** → `** BUILD SUCCEEDED **`.
- [ ] **Step 4: Lint** → baseline 19/0.
- [ ] **Step 5: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/BugReportSheet.swift plop/plop/Views/Settings/ExportSheet.swift
git commit -m "Fire success haptic on a sent bug report and a completed export

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full build** → `** BUILD SUCCEEDED **`.

- [ ] **Step 2: Full test suite** (no logic changed — must stay green)

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 \
  | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **`, 181 tests (unchanged).

- [ ] **Step 3: Lint** → baseline 19/0.

- [ ] **Step 4: Physical-device smoke check (manual — owner).** The simulator does not produce
  haptics, so verify on a real device:
  - Each of the 10 actions buzzes **once** on success: add an entry; set a category budget in
    Insights; save a budget in Settings; change the currency; change the theme; create and save
    a category; pick a recurring interval in Entry; stop a recurring rule in Settings; send a
    bug report; complete an export.
  - **No buzz** on: Cancel / × / drag-dismiss of any popup; **re-selecting the current**
    currency or theme; **cancelling** the Mail composer (bug report); a **failed/empty** export.

- [ ] **Step 5: Push + PR**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git push -u origin feature/haptics
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Add a uniform success haptic confirming 10 committed actions (add entry, set budgets, change
currency/theme, create/save category, set/stop recurring, send bug report, export). A 3-line
Haptics service called at each commit point; respects the system haptics setting, no in-app
toggle, no data-layer changes.

## Testing
181 unit tests pass (no new — view-layer effect); SwiftLint clean (19/0). Device-verified:
each action buzzes once on success; Cancel/×/dismiss, re-selecting the current currency/theme,
a cancelled mail, and an empty export do not buzz.
```

---

## Self-review notes

- **Spec coverage:** all 10 sites from `design.md` map to a step (Task 2 = sites 1–8, Task 3 =
  sites 9–10), plus the service (Task 1) and verify (Task 4).
- **Behaviour rules honoured:** commit-point only (after guards / on `.sent` / on `.success`
  phase); change-only guards for currency (#4) and theme (#5); async sites fire on success, not
  on tap.
- **Concurrency:** `Haptics.success()` is `@MainActor`; every call site is a button action or a
  main-actor `.onChange` — no `await`/`MainActor.run` needed. Export uses `.onChange` (Phase is
  Equatable) precisely to stay on the main actor and avoid wrapping inside the async `runExport`.
- **Type consistency:** `Haptics.success()` used identically everywhere; `result == .sent` is
  `MFMailComposeResult` (MessageUI already imported); `service.phase` is `ExportService.Phase`.
- **No placeholders / no disables / config untouched / lines ≤ 120 / no unit tests (view-layer
  effect, no logic change — project convention).**
