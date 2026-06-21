# Dialog Popups B2a (Currency + Set budget) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the Currency and Set budget Settings screens from pushed `NavigationLink` screens to tall `BlurPopup` popups, adding a `tall` option to `BlurPopup`.

**Architecture:** `BlurPopup` gains `tall: Bool = false`; when set, the card is height-capped (via a `GeometryReader`) so `List` content scrolls inside. `CurrencyView` and `BudgetView` get a fixed header (title + Done calling `\.blurPopupClose`) above their existing `List`, drop their nav chrome, and `SettingsView` presents them via `.blurPopup(tall: true)` instead of pushing. Presentation only — no business logic, so no unit tests.

**Tech Stack:** SwiftUI (`fullScreenCover`, `GeometryReader`, materials). iOS 18. Views verified via `#Preview` + simulator.

Single PR on branch `feature/dialog-popups-2` (already created; spec committed there). The
branch sits on top of `feature/dialog-popups` so `BlurPopup` exists; rebase onto `main`
after B1 merges, before opening this PR.

---

## File structure

- **Modify** `plop/plop/Views/Common/BlurPopup.swift` — add the `tall` option (modifier
  arg + `GeometryReader` height cap).
- **Modify** `plop/plop/Views/Settings/CurrencyView.swift` — header + Done; drop nav
  chrome; keep List/selection/footer.
- **Modify** `plop/plop/Views/Settings/BudgetView.swift` — header + Done; drop nav chrome;
  keep everything else.
- **Modify** `plop/plop/Views/Settings/SettingsView.swift` — Currency + Budget rows
  `NavigationLink` → `Button` + `.blurPopup(tall: true)`; add two `@State` flags.

### Build / lint commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | tail -5

swiftlint lint
```

> SourceKit "Cannot find X in scope" / "unavailable in macOS" diagnostics are FALSE
> positives — `xcodebuild` is the source of truth. Lines ≤ 120. No `// swiftlint:disable`.
> Keep the lint baseline (21 violations, 0 serious); do not edit `.swiftlint.yml`.

---

## Task 1: Add the `tall` option to `BlurPopup`

**Files:**
- Modify: `plop/plop/Views/Common/BlurPopup.swift`

- [ ] **Step 1: Add `tall` to the modifier**

In `BlurPopup.swift`, change the `blurPopup` function. Change:
```swift
    func blurPopup<Card: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder card: @escaping () -> Card
    ) -> some View {
        fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) {
            BlurPopupContainer(isPresented: isPresented, card: card)
                .presentationBackground(.clear)
        }
        .transaction { $0.disablesAnimations = true }   // suppress the cover's own slide
    }
```
to:
```swift
    func blurPopup<Card: View>(
        isPresented: Binding<Bool>,
        tall: Bool = false,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder card: @escaping () -> Card
    ) -> some View {
        fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) {
            BlurPopupContainer(isPresented: isPresented, tall: tall, card: card)
                .presentationBackground(.clear)
        }
        .transaction { $0.disablesAnimations = true }   // suppress the cover's own slide
    }
```

- [ ] **Step 2: Add the `tall` stored property**

Change:
```swift
private struct BlurPopupContainer<Card: View>: View {
    @Binding var isPresented: Bool
    @ViewBuilder var card: () -> Card
```
to:
```swift
private struct BlurPopupContainer<Card: View>: View {
    @Binding var isPresented: Bool
    var tall: Bool
    @ViewBuilder var card: () -> Card
```

- [ ] **Step 3: Wrap the body in a `GeometryReader` and cap the card height**

Change the entire `body`:
```swift
    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.18))
                .ignoresSafeArea()
                .opacity(shown ? 1 : 0)
                .contentShape(Rectangle())
                .onTapGesture { close() }

            card()
                .frame(maxWidth: .infinity)
                .background(Palette.card,
                            in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .offset(y: shown ? drag : 1000)
                .gesture(dragToDismiss)
                .environment(\.blurPopupClose, close)
        }
        .onAppear { withAnimation(anim) { shown = true } }
    }
```
to:
```swift
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(Color.black.opacity(0.18))
                    .ignoresSafeArea()
                    .opacity(shown ? 1 : 0)
                    .contentShape(Rectangle())
                    .onTapGesture { close() }

                card()
                    .frame(maxWidth: .infinity,
                           maxHeight: tall ? proxy.size.height * 0.8 : nil)
                    .background(Palette.card,
                                in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .offset(y: shown ? drag : 1000)
                    .gesture(dragToDismiss)
                    .environment(\.blurPopupClose, close)
            }
        }
        .onAppear { withAnimation(anim) { shown = true } }
    }
```
(`dragToDismiss` and `close()` are unchanged. Existing B1 call sites omit `tall`, so they
default to `false` → unchanged hug-to-content behavior.)

- [ ] **Step 4: Build** — run the build command → `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Lint** — `swiftlint lint` → no new violations (baseline 21/0).

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Common/BlurPopup.swift
git commit -m "Add tall option to BlurPopup for scrolling list content

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Convert CurrencyView to card content

**Files:**
- Modify: `plop/plop/Views/Settings/CurrencyView.swift`

- [ ] **Step 1: Add the popup close, header, and drop nav chrome**

Replace the whole file with:
```swift
import SwiftUI

/// Picks the app-wide display currency (no conversion). Writing @AppStorage re-renders
/// every money view that reads it. Presented as a tall BlurPopup from Settings.
struct CurrencyView: View {
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @Environment(\.blurPopupClose) private var close

    var body: some View {
        VStack(spacing: 0) {
            header
            List {
                Section {
                    ForEach(currencyChoices, id: \.self) { code in
                        Button { currencyCode = code } label: { row(code) }
                            .buttonStyle(.plain)
                    }
                } footer: {
                    Text("Amounts aren't converted — only the symbol and decimal places change.")
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    private var header: some View {
        HStack {
            Text("Currency")
                .font(.system(size: 22, weight: .bold)).foregroundStyle(Palette.ink)
            Spacer()
            Button("Done") { close() }
                .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 6)
    }

    private func row(_ code: String) -> some View {
        HStack(spacing: 12) {
            Text(code)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: 44, alignment: .leading)
            Text(currencySymbol(code)).foregroundStyle(Palette.ink40)
            Text(currencyDisplayName(code)).foregroundStyle(Palette.ink40).lineLimit(1)
            Spacer()
            if code == currencyCode {
                Image(systemName: "checkmark").foregroundStyle(Palette.accent)
            }
        }
    }
}

#if DEBUG
#Preview { CurrencyView() }
#endif
```
(Changes vs. current: added `@Environment(\.blurPopupClose) private var close`; wrapped the
`List` in a `VStack` with a `header`; removed `.background(Palette.bg)` and
`.navigationTitle("Currency")`; preview no longer wraps in `NavigationStack`. `row(_:)`,
the selection write, and the footer are unchanged.)

- [ ] **Step 2: Build** — run the build command → `** BUILD SUCCEEDED **`. (`SettingsView`
  still uses `NavigationLink { CurrencyView() }` — it compiles and pushes the new content;
  it is converted in Task 4.)

- [ ] **Step 3: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/CurrencyView.swift
git commit -m "Make CurrencyView popup card content (header + Done)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Convert BudgetView to card content

**Files:**
- Modify: `plop/plop/Views/Settings/BudgetView.swift`

- [ ] **Step 1: Add the popup close + header**

In `BudgetView.swift`, add the environment close. Change:
```swift
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @AppStorage(budgetModeKey) private var modeRaw = BudgetMode.category.rawValue
    @AppStorage(generalBudgetKey) private var generalBudget = ""
```
to:
```swift
    @Environment(\.blurPopupClose) private var close

    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @AppStorage(budgetModeKey) private var modeRaw = BudgetMode.category.rawValue
    @AppStorage(generalBudgetKey) private var generalBudget = ""
```

- [ ] **Step 2: Wrap the List in a header VStack, drop nav chrome**

Change the start of `body`:
```swift
    var body: some View {
        List {
            Section {
                Picker("Budget mode", selection: $modeRaw) {
```
to:
```swift
    var body: some View {
        VStack(spacing: 0) {
            header
            List {
                Section {
                    Picker("Budget mode", selection: $modeRaw) {
```

> NOTE: the `List { ... }` content moves one indent level deeper. Re-indent the existing
> `List` body (the mode picker, the general/category sections, and the Save section) by one
> level so it nests inside the new `VStack`. Keep the section contents byte-for-byte; only
> indentation changes.

Then change the end of `body` — the modifiers currently attached to the `List`:
```swift
        }
        .scrollContentBackground(.hidden)
        .background(Palette.bg)
        .navigationTitle("Set budget")
        .onAppear(perform: loadFields)
    }
```
to (close the `List`, keep `.scrollContentBackground`/`.onAppear` on the `List`, drop
`.background`/`.navigationTitle`, then close the `VStack`):
```swift
            }
            .scrollContentBackground(.hidden)
            .onAppear(perform: loadFields)
        }
    }

    private var header: some View {
        HStack {
            Text("Set budget")
                .font(.system(size: 22, weight: .bold)).foregroundStyle(Palette.ink)
            Spacer()
            Button("Done") { close() }
                .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 6)
    }
```

- [ ] **Step 3: Update the preview** — change:
```swift
#Preview {
    NavigationStack { BudgetView() }
        .modelContainer(SampleData.previewContainer())
}
```
to:
```swift
#Preview {
    BudgetView()
        .modelContainer(SampleData.previewContainer())
}
```
(`import SwiftData`, `@Query`, `@State` fields, `mode`, `amountField`, `bindingFor`,
`loadFields`, and `save` are all unchanged.)

- [ ] **Step 4: Build** — run the build command → `** BUILD SUCCEEDED **`. If the build
  reports a brace/indent mismatch, the most likely cause is the re-indent in Step 2 — verify
  the `List` opens inside the `VStack` and both close. (`SettingsView` still pushes
  `BudgetView()` until Task 4.)

- [ ] **Step 5: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/BudgetView.swift
git commit -m "Make BudgetView popup card content (header + Done)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Present Currency + Set budget via `.blurPopup`

**Files:**
- Modify: `plop/plop/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Add two state flags**

Change:
```swift
    @State private var showingAppearance = false
    @State private var showingExport = false
    @State private var showingBugReport = false
    @State private var showingRecurring = false
```
to:
```swift
    @State private var showingAppearance = false
    @State private var showingExport = false
    @State private var showingBugReport = false
    @State private var showingRecurring = false
    @State private var showingBudget = false
    @State private var showingCurrency = false
```

- [ ] **Step 2: Convert the Set budget row**

Change:
```swift
                    NavigationLink { BudgetView() } label: {
                        SettingsRow(tile: Palette.accent, systemImage: "chart.pie.fill",
                                    title: "Set budget", value: budgetSummary, showsChevron: false)
                    }
```
to:
```swift
                    Button { showingBudget = true } label: {
                        SettingsRow(tile: Palette.accent, systemImage: "chart.pie.fill",
                                    title: "Set budget", value: budgetSummary, showsChevron: false)
                    }
                    .buttonStyle(.plain)
```

- [ ] **Step 3: Convert the Currency row**

Change:
```swift
                    NavigationLink { CurrencyView() } label: {
                        SettingsRow(tile: Palette.cream, systemImage: "dollarsign.circle.fill",
                                    title: "Currency", value: currencyCode, showsChevron: false)
                    }
```
to:
```swift
                    Button { showingCurrency = true } label: {
                        SettingsRow(tile: Palette.cream, systemImage: "dollarsign.circle.fill",
                                    title: "Currency", value: currencyCode, showsChevron: false)
                    }
                    .buttonStyle(.plain)
```
(Leave the `NavigationLink { ManageCategoriesView() }` row unchanged — it keeps the
`NavigationStack` in use until B2b.)

- [ ] **Step 4: Add the two popups**

Change the existing block of `.blurPopup` modifiers — currently:
```swift
            .blurPopup(isPresented: $showingAppearance) {
                AppearanceSheet()
            }
            .blurPopup(isPresented: $showingExport) {
                ExportSheet(transactions: transactions, categories: categories)
            }
            .blurPopup(isPresented: $showingBugReport) {
                BugReportSheet()
            }
            .blurPopup(isPresented: $showingRecurring) {
                RecurringRulesSheet()
            }
```
to (append the two tall popups):
```swift
            .blurPopup(isPresented: $showingAppearance) {
                AppearanceSheet()
            }
            .blurPopup(isPresented: $showingExport) {
                ExportSheet(transactions: transactions, categories: categories)
            }
            .blurPopup(isPresented: $showingBugReport) {
                BugReportSheet()
            }
            .blurPopup(isPresented: $showingRecurring) {
                RecurringRulesSheet()
            }
            .blurPopup(isPresented: $showingBudget, tall: true) {
                BudgetView()
            }
            .blurPopup(isPresented: $showingCurrency, tall: true) {
                CurrencyView()
            }
```

- [ ] **Step 5: Build** — run the build command → `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 7: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/SettingsView.swift
git commit -m "Present Currency and Set budget as tall blur popups

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite** (presentation only — nothing should break)

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` (~166, unchanged).

- [ ] **Step 2: Lint** — `swiftlint lint` → baseline 21/0, no new violations.

- [ ] **Step 3: Simulator smoke check (manual — owner)**

Against the handoff `currency.jpg`, light + dark:
- Tapping **Currency** / **Set budget** blurs the screen and slides a **tall** card up; the
  list **scrolls inside** the card; closing reverses.
- **Tap-scrim / drag-down / Done** each dismiss.
- **Currency:** tapping a code moves the checkmark and updates money across the app live
  behind the blur.
- **Set budget:** segmented Total / By-category switch works; typing in an amount field
  **raises the card above the keyboard**; the total footer updates; **Save budget** persists
  (reopen shows saved values).
- **Regression — B1 dialogs:** Theme / Export / Report a bug / Recurring still **hug their
  content** (not tall), and dismiss + keyboard-rise as before.
- **Manage categories** still pushes (unchanged).

- [ ] **Step 4: Rebase onto `main` (after B1 merges), then push + PR**

If B1 (`feature/dialog-popups`) has merged to `main`:
```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git fetch origin && git rebase origin/main
```
Re-run Steps 1–2 after the rebase. Then:
```bash
git push -u origin feature/dialog-popups-2
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Cleanup B2a: convert Currency and Set budget from pushed screens to tall blur popups, and
add a `tall` option to BlurPopup so list content scrolls inside a height-capped card.
Presentation only — selection/save logic unchanged. (B2b converts the categories cluster;
content restyle is Cleanup C.)

## Testing
166 unit tests pass (no new — presentation change); SwiftLint clean (baseline 21/0).
Sim-verified: tall popups scroll, all dismiss paths, currency selection live, budget save +
keyboard-rise, and B1 dialogs still hug; light + dark.
```

---

## Self-review notes

- **Spec coverage:** `tall` option (Task 1); Currency conversion — header/Done, drop nav
  chrome, keep List/selection/footer (Task 2); Budget conversion — header/Done, keep
  picker/fields/total/Save/loadFields (Task 3); `SettingsView` rows → `Button` +
  `.blurPopup(tall: true)`, Manage categories left pushed (Task 4); regression check of B1
  dialogs (Task 5, Step 3). All spec items map to a task.
- **Type consistency:** `blurPopup(isPresented:tall:onDismiss:card:)` with `tall: Bool =
  false`; `BlurPopupContainer` gains `var tall: Bool` and is constructed with
  `tall: tall`; both screens read `@Environment(\.blurPopupClose) private var close` and
  call `close()`; the `header` computed property is added to each. Names match across tasks.
- **Behavior preserved:** currency persistence, budget save (`save()` / `loadFields()` /
  mode replacement), and money formatting are untouched; only presentation changes. No
  business logic → no unit tests (project convention: views via preview + simulator).
- **Build-green increments:** Tasks 2–3 build while `SettingsView` still pushes the views
  (initializers unchanged); Task 4 swaps presentation. Each task compiles and commits on its
  own.
- **No placeholders / no disables / config untouched / lines ≤ 120.**
- **Sim-tunable:** the `0.8` height fraction (and the inherited spring/scrim/drag values)
  are confirmed in the simulator.
