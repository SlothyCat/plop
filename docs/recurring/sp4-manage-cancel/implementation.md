# Recurring Payments SP4 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Settings "Recurring payments" popup that lists active rules and lets the user cancel one (stops future generation; keeps past occurrences). Completes Feature 2.

**Architecture:** Add `RecurringActions.cancel` (deletes the rule; `.nullify` keeps occurrences), a `RecurringRulesSheet` list view, and a Settings row that presents it.

**Tech Stack:** Swift, SwiftData, SwiftUI, XCTest. iOS 18. No new deps.

Single PR on branch `feature/recurring-sp4` (off `main`; spec already committed there).

---

## File structure

- **Modify** `plop/plop/Data/RecurringActions.swift` — add `cancel(_:in:)`.
- **Modify** `plop/plopTests/RecurringActionsTests.swift` — add a cancel test.
- **Create** `plop/plop/Views/Settings/RecurringRulesSheet.swift` — the popup list.
- **Modify** `plop/plop/Views/Settings/SettingsView.swift` — Preferences row + sheet.

### Verified existing context

- `RecurringActions` is an `enum` with `create(from:in:calendar:)`. `RecurringActionsTests` (`@MainActor`) already has `utc`/`day(_:_:_:)` helpers + uses `makeInMemoryContainer()`.
- `RecurringRule` (`amount/type/note/interval/anchorDay/startDate/createdAt/category/occurrences`); occurrences relationship is `.nullify`.
- `recurringSummary(interval:date:calendar:)` (SP3), `formattedMoney(_:signed:currencyCode:)`, `currencyCodeKey`/`deviceCurrencyCode()`, `Palette`, `Color(hex:)`.
- `SettingsView`: `Section("Preferences")` has a Theme `Button` ending in `.buttonStyle(.plain)`; the `List` carries `.sheet(isPresented: $showingAppearance)` / `$showingExport` / `$showingBugReport`; state flags live near the top.

### Test / build commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests/RecurringActionsTests -parallel-testing-enabled NO 2>&1 | tail -25

xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'

swiftlint lint
```

> SourceKit false positives expected. Lines ≤ 120. **No `// swiftlint:disable`; do not edit `.swiftlint.yml`.**

---

## Task 1: RecurringActions.cancel + test

**Files:**
- Modify: `plop/plop/Data/RecurringActions.swift`
- Modify: `plop/plopTests/RecurringActionsTests.swift`

- [ ] **Step 1: Add the failing test**

In `plop/plopTests/RecurringActionsTests.swift`, add this method inside the
`RecurringActionsTests` class (before the closing brace):

```swift
    func test_cancel_removesRule_keepsOccurrence() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let draft = TransactionDraft(amount: 9, type: .expense, date: day(2026, 6, 18),
                                     note: "Gym", recurrence: .monthly)
        let rule = RecurringActions.create(from: draft, in: context, calendar: utc)
        try context.save()

        RecurringActions.cancel(rule, in: context)
        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<RecurringRule>()).count, 0)
        let txs = try context.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(txs.count, 1)        // first occurrence kept
        XCTAssertNil(txs.first?.rule)       // link nullified
    }
```

- [ ] **Step 2: Run the tests — confirm it FAILS to build** (`cancel` undefined).

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests/RecurringActionsTests -parallel-testing-enabled NO 2>&1 | tail -20
```

- [ ] **Step 3: Implement**

In `plop/plop/Data/RecurringActions.swift`, add inside the `RecurringActions` enum
(after `create`):

```swift
    /// Cancels a recurrence: deletes the rule so nothing new generates. Past
    /// occurrences remain (occurrences relationship is .nullify — their `rule` clears).
    static func cancel(_ rule: RecurringRule, in context: ModelContext) {
        context.delete(rule)
    }
```

- [ ] **Step 4: Run the tests — confirm PASS** (all `RecurringActionsTests` green).

- [ ] **Step 5: SwiftLint** — no new violations; config untouched.

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Data/RecurringActions.swift plop/plopTests/RecurringActionsTests.swift
git commit -m "Add RecurringActions.cancel (delete rule, keep occurrences)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: RecurringRulesSheet + Settings row

**Files:**
- Create: `plop/plop/Views/Settings/RecurringRulesSheet.swift`
- Modify: `plop/plop/Views/Settings/SettingsView.swift`

No unit tests (SwiftUI views — verify = builds).

- [ ] **Step 1: Write the sheet**

Create `plop/plop/Views/Settings/RecurringRulesSheet.swift`:

```swift
import SwiftUI
import SwiftData

/// Popup listing active recurring rules. Swipe a row to Stop (cancel) it: future
/// occurrences stop; past ones stay.
struct RecurringRulesSheet: View {
    @Query(sort: \RecurringRule.createdAt) private var rules: [RecurringRule]
    @Environment(\.modelContext) private var modelContext
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @State private var pendingCancel: RecurringRule?
    var onDone: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if rules.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(rules) { rule in row(rule) }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Palette.bg)
            .navigationTitle("Recurring payments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onDone() }
                }
            }
            .confirmationDialog("Stop this recurring payment?",
                                isPresented: cancelDialogBinding,
                                titleVisibility: .visible,
                                presenting: pendingCancel) { rule in
                Button("Stop recurring", role: .destructive) {
                    RecurringActions.cancel(rule, in: modelContext)
                    pendingCancel = nil
                }
                Button("Keep", role: .cancel) { pendingCancel = nil }
            } message: { _ in
                Text("Future charges stop; past ones stay.")
            }
        }
    }

    private var cancelDialogBinding: Binding<Bool> {
        Binding(get: { pendingCancel != nil }, set: { if !$0 { pendingCancel = nil } })
    }

    private func row(_ rule: RecurringRule) -> some View {
        HStack(spacing: 12) {
            Image(systemName: rule.category?.symbolName ?? "arrow.triangle.2.circlepath")
                .font(.system(size: 16))
                .foregroundStyle(Palette.tileInk)
                .frame(width: 36, height: 36)
                .background(rule.category.map { Color(hex: $0.colorHex) } ?? Palette.accentSoft,
                            in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title(rule))
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.ink)
                Text(recurringSummary(interval: rule.interval, date: rule.startDate))
                    .font(.system(size: 13)).foregroundStyle(Palette.ink40)
            }
            Spacer()
            Text(formattedMoney(rule.amount, currencyCode: currencyCode))
                .font(.system(size: 15, weight: .semibold)).monospacedDigit()
                .foregroundStyle(Palette.ink)
        }
        .listRowBackground(Palette.card)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { pendingCancel = rule } label: {
                Label("Stop", systemImage: "xmark.circle")
            }
        }
    }

    private func title(_ rule: RecurringRule) -> String {
        if !rule.note.isEmpty { return rule.note }
        return rule.category?.name ?? "Recurring payment"
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 32)).foregroundStyle(Palette.ink40)
            Text("No recurring payments yet")
                .font(.system(size: 15)).foregroundStyle(Palette.ink40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview {
    RecurringRulesSheet(onDone: {}).modelContainer(SampleData.previewContainer())
}
#endif
```

- [ ] **Step 2: Add the Settings row + sheet**

In `plop/plop/Views/Settings/SettingsView.swift`:

(a) Add a state flag near the others (e.g. after `showingBugReport` or `showingAppearance`):
```swift
    @State private var showingRecurring = false
```

(b) In `Section("Preferences")`, add this row immediately after the Theme button's
`.buttonStyle(.plain)` (still inside the section):
```swift
                    Button {
                        showingRecurring = true
                    } label: {
                        HStack {
                            Label("Recurring payments", systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
```

(c) Add a sheet modifier alongside the existing `.sheet(...)` modifiers on the `List`:
```swift
            .sheet(isPresented: $showingRecurring) {
                RecurringRulesSheet { showingRecurring = false }
            }
```

Read the file first to place (a)–(c) precisely. Change nothing else.

- [ ] **Step 3: Verify the target builds**

Run `xcodebuild build …`. Expected `** BUILD SUCCEEDED **`. (Ignore SourceKit
squiggles; if a real error is in a file you didn't touch, STOP and report BLOCKED.)

- [ ] **Step 4: SwiftLint** — no new violations; config untouched.

- [ ] **Step 5: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/RecurringRulesSheet.swift plop/plop/Views/Settings/SettingsView.swift
git commit -m "Add Recurring payments manage/cancel sheet and Settings row

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` — all prior + the new cancel test.

- [ ] **Step 2: Lint** — `swiftlint lint` → no new violations; `.swiftlint.yml` unchanged.

- [ ] **Step 3: Simulator smoke check (manual)**

Create a recurring entry (Entry → Monthly → Create). Settings → **Recurring payments**
→ the rule is listed with its cadence + amount. Swipe → **Stop** → confirm → it leaves
the list, and its already-created transaction remains in Home. With no rules, the
empty state shows.

- [ ] **Step 4: Push + PR**

```bash
git push -u origin feature/recurring-sp4
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Recurring payments SP4: a Settings "Recurring payments" popup listing active rules,
each cancellable (stops future occurrences, keeps past). Completes the recurring
feature (SP1 model → SP2 engine → SP3 create → SP4 manage/cancel).

## Testing
All unit tests pass (1 new cancel test); SwiftLint clean. Manage/cancel sim-verified.
```

---

## Self-review notes

- **Spec coverage:** `cancel` deletes the rule, keeps occurrences (Task 1, tested);
  Settings "Recurring payments" row → sheet listing active rules with cadence/amount,
  swipe-Stop + confirm + empty state (Task 2). No resume/stopped/occurrence-deletion/
  series-edit (out of scope) — absent.
- **Type consistency:** `RecurringActions.cancel(_:in:)` matches the test + the sheet
  call; reuses `recurringSummary`, `formattedMoney`, `RecurringRule`, `Palette`,
  `SampleData.previewContainer` as defined.
- **No placeholders / no disables / config untouched.**
- **Cancel keeps history** via the SP1 `.nullify` relationship — verified by
  `test_cancel_removesRule_keepsOccurrence`.
