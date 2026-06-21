# Dialog Popups (Cleanup B1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reusable handoff-style blurred bottom-popup (`BlurPopup`) and present the four card-style Settings dialogs (Theme, Export, Report a bug, Recurring) with it instead of system `.sheet`.

**Architecture:** A `fullScreenCover` with `.presentationBackground(.clear)` lets the real screen show through; an in-cover `.ultraThinMaterial` scrim blurs it while an opaque `Palette.card` slides up from the bottom. The cover's own slide is suppressed so we drive the scrim-fade + card-slide ourselves. All dismissal (tap-scrim, drag-down, the card's own buttons) routes through one animated `close()`, shared with content via an environment closure `\.blurPopupClose`. Presentation only — no behavior change, no business logic, so no unit tests.

**Tech Stack:** SwiftUI (`fullScreenCover`, `presentationBackground`, materials, `DragGesture`). iOS 18. Views verified via `#Preview` + simulator.

Single PR on branch `feature/dialog-popups` (already created; spec committed there).

---

## File structure

- **Create** `plop/plop/Views/Common/BlurPopup.swift` — the `.blurPopup` modifier, the
  `BlurPopupContainer` (scrim + sliding card + drag/tap dismiss), and the
  `\.blurPopupClose` environment value. New `Views/Common/` folder (Xcode 16
  file-system-synchronized folders pick it up automatically).
- **Modify** `plop/plop/Views/Settings/SettingsView.swift` — swap the four
  `.sheet(isPresented:)` modifiers for `.blurPopup(isPresented:)` and drop the now-unused
  `onDone` closures at the call sites.
- **Modify** `plop/plop/Views/Settings/AppearanceSheet.swift` — drop `onDone` (use
  `\.blurPopupClose`), `.presentationDetents`, own `.background`, and `maxHeight: .infinity`.
- **Modify** `plop/plop/Views/Settings/ExportSheet.swift` — drop `onDone`, the
  `onGeometryChange`/`sheetHeight` detent machinery, `.presentationDragIndicator`, and own
  `.background`.
- **Modify** `plop/plop/Views/Settings/BugReportSheet.swift` — replace
  `@Environment(\.dismiss)` with `\.blurPopupClose`; drop the detent machinery and own
  `.background`; keep the nested Mail `.sheet`.
- **Modify** `plop/plop/Views/Settings/RecurringRulesSheet.swift` — drop `onDone` (use
  `\.blurPopupClose`); recolor the inner surface to `Palette.card` so it matches the
  popup card.

### Build / lint commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | tail -5

swiftlint lint
```

> SourceKit "Cannot find X in scope" diagnostics are FALSE positives — `xcodebuild` is the
> source of truth. Lines ≤ 120. No `// swiftlint:disable`. Keep the lint baseline (21
> violations, 0 serious); do not edit `.swiftlint.yml`.

---

## Task 1: The `BlurPopup` component

**Files:**
- Create: `plop/plop/Views/Common/BlurPopup.swift`

- [ ] **Step 1: Create the file**

Create `plop/plop/Views/Common/BlurPopup.swift` with exactly:

```swift
import SwiftUI

/// Presents `card` as a handoff-style blurred bottom popup: a full-screen
/// `.ultraThinMaterial` scrim blurs the real screen behind, and an opaque rounded card
/// slides up from the bottom. Dismiss by tapping the scrim, dragging the card down, or
/// having the card's own controls call `\.blurPopupClose` from the environment.
extension View {
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
}

/// Closure the card content calls to dismiss the popup *with* the slide-out animation.
/// Defaults to a no-op so previews and standalone use compile.
private struct BlurPopupCloseKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var blurPopupClose: () -> Void {
        get { self[BlurPopupCloseKey.self] }
        set { self[BlurPopupCloseKey.self] = newValue }
    }
}

private struct BlurPopupContainer<Card: View>: View {
    @Binding var isPresented: Bool
    @ViewBuilder var card: () -> Card

    @State private var shown = false
    @State private var drag: CGFloat = 0

    private let anim: Animation = .spring(response: 0.34, dampingFraction: 0.86)
    private let outDelay = 0.34

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

    private var dragToDismiss: some Gesture {
        DragGesture()
            .onChanged { drag = max(0, $0.translation.height) }
            .onEnded { value in
                if value.translation.height > 120
                    || value.predictedEndTranslation.height > 240 {
                    close()
                } else {
                    withAnimation(anim) { drag = 0 }
                }
            }
    }

    private func close() {
        withAnimation(anim) { shown = false; drag = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + outDelay) { isPresented = false }
    }
}
```

Notes:
- `.ultraThinMaterial` over the cleared cover blurs the actual screen (the handoff
  `blur(2px)`); the 0.18 black overlay is the toned ~32% scrim.
- `disablesAnimations` kills the system cover slide; `shown` drives the scrim opacity and
  the card offset (`1000 → 0`) via one spring. `close()` animates out, then clears the
  binding after the spring so the now-invisible cover is torn down without a second slide.
- The card tracks downward drags; release past ~120pt (or a fast flick) closes, else it
  springs back. `clipShape` rounds any content (incl. nav bars / lists) to the card.
- The card is bottom-pinned and does NOT ignore the keyboard, so it rises with the keyboard
  automatically.

- [ ] **Step 2: Build** — run the build command → `** BUILD SUCCEEDED **`. (No call sites
  yet; this just compiles the new file. Ignore SourceKit false positives.)

- [ ] **Step 3: Lint** — `swiftlint lint` → no new violations (baseline 21/0).

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Common/BlurPopup.swift
git commit -m "Add BlurPopup: reusable blurred bottom-popup presentation

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Adopt for Theme + Export

**Files:**
- Modify: `plop/plop/Views/Settings/AppearanceSheet.swift`
- Modify: `plop/plop/Views/Settings/ExportSheet.swift`
- Modify: `plop/plop/Views/Settings/SettingsView.swift`

- [ ] **Step 1: AppearanceSheet — use `\.blurPopupClose`, drop sheet chrome**

In `AppearanceSheet.swift`:

Replace the stored `onDone` with the environment close. Change:
```swift
    @AppStorage(themeModeKey) private var themeModeRaw = ThemeMode.automatic.rawValue
    var onDone: () -> Void
```
to:
```swift
    @AppStorage(themeModeKey) private var themeModeRaw = ThemeMode.automatic.rawValue
    @Environment(\.blurPopupClose) private var close
```

Change the Done button:
```swift
            Button("Done") { onDone() }
```
to:
```swift
            Button("Done") { close() }
```

Replace the trailing layout/background/detent modifiers. Change:
```swift
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.card)
        .presentationDetents([.medium])
    }
```
to:
```swift
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
```

Update the preview. Change:
```swift
#Preview { AppearanceSheet(onDone: {}) }
```
to:
```swift
#Preview { AppearanceSheet() }
```

- [ ] **Step 2: ExportSheet — use `\.blurPopupClose`, drop detent machinery + background**

In `ExportSheet.swift`:

Add the environment close and remove the `onDone` + `sheetHeight` state. Change:
```swift
    var onDone: () -> Void

    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
```
to:
```swift
    @Environment(\.blurPopupClose) private var close

    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
```

Remove the `sheetHeight` state line entirely:
```swift
    @State private var sheetHeight: CGFloat = 320
```

Replace the body's trailing modifiers. Change:
```swift
    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.bg)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { sheetHeight = $0 }
            .presentationDetents([.height(sheetHeight)])
            .presentationDragIndicator(.visible)
    }
```
to:
```swift
    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
```

Change the two dismiss call sites — the Cancel button in `form`:
```swift
                Button("Cancel") { onDone() }.foregroundStyle(Palette.ink60)
```
to:
```swift
                Button("Cancel") { close() }.foregroundStyle(Palette.ink60)
```
and the Done button in `phaseSuccess(_:)`:
```swift
            Button("Done") { onDone() }.foregroundStyle(Palette.ink60)
```
to:
```swift
            Button("Done") { close() }.foregroundStyle(Palette.ink60)
```

Update the preview. Change:
```swift
    ExportSheet(transactions: [], categories: [], onDone: {})
```
to:
```swift
    ExportSheet(transactions: [], categories: [])
```

- [ ] **Step 3: SettingsView — present Theme + Export via `.blurPopup`**

In `SettingsView.swift`, change the appearance + export sheet modifiers. Change:
```swift
            .sheet(isPresented: $showingAppearance) {
                AppearanceSheet { showingAppearance = false }
            }
            .sheet(isPresented: $showingExport) {
                ExportSheet(transactions: transactions, categories: categories) {
                    showingExport = false
                }
            }
```
to:
```swift
            .blurPopup(isPresented: $showingAppearance) {
                AppearanceSheet()
            }
            .blurPopup(isPresented: $showingExport) {
                ExportSheet(transactions: transactions, categories: categories)
            }
```
Leave the `.sheet(isPresented: $showingBugReport)` and `.sheet(isPresented: $showingRecurring)` modifiers unchanged for now (converted in Task 3).

- [ ] **Step 4: Build** — run the build command → `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/AppearanceSheet.swift \
        plop/plop/Views/Settings/ExportSheet.swift \
        plop/plop/Views/Settings/SettingsView.swift
git commit -m "Present Theme and Export as blurred bottom popups

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Adopt for Report a bug + Recurring

**Files:**
- Modify: `plop/plop/Views/Settings/BugReportSheet.swift`
- Modify: `plop/plop/Views/Settings/RecurringRulesSheet.swift`
- Modify: `plop/plop/Views/Settings/SettingsView.swift`

- [ ] **Step 1: BugReportSheet — swap dismiss for `\.blurPopupClose`, drop detents**

In `BugReportSheet.swift`:

Replace the dismiss environment and remove `sheetHeight`. Change:
```swift
    @Environment(\.dismiss) private var dismiss

    @State private var description = ""
```
to:
```swift
    @Environment(\.blurPopupClose) private var close

    @State private var description = ""
```
and remove the line:
```swift
    @State private var sheetHeight: CGFloat = 380
```

Replace the body's trailing modifiers, keeping the nested Mail `.sheet` and the
`onChange`. Change:
```swift
    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.bg)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { sheetHeight = $0 }
            .presentationDetents([.height(sheetHeight)])
            .presentationDragIndicator(.visible)
            .sheet(isPresented: $showingMail) {
                MailComposeView(subject: BugReport.subject, body: composedBody(),
                                imageData: imageData) { _ in
                    showingMail = false
                    dismiss()
                }
            }
            .onChange(of: pickerItem) { _, item in
                Task { imageData = try? await item?.loadTransferable(type: Data.self) }
            }
    }
```
to:
```swift
    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sheet(isPresented: $showingMail) {
                MailComposeView(subject: BugReport.subject, body: composedBody(),
                                imageData: imageData) { _ in
                    showingMail = false
                    close()
                }
            }
            .onChange(of: pickerItem) { _, item in
                Task { imageData = try? await item?.loadTransferable(type: Data.self) }
            }
    }
```

Change the remaining `dismiss()` calls. In `form`:
```swift
                Button("Cancel") { dismiss() }.foregroundStyle(Palette.ink60)
```
to:
```swift
                Button("Cancel") { close() }.foregroundStyle(Palette.ink60)
```
and in `fallback`:
```swift
                Button("Done") { dismiss() }.foregroundStyle(Palette.ink60)
```
to:
```swift
                Button("Done") { close() }.foregroundStyle(Palette.ink60)
```
(The `#Preview { BugReportSheet() }` needs no change.)

- [ ] **Step 2: RecurringRulesSheet — use `\.blurPopupClose`, match the card surface**

In `RecurringRulesSheet.swift`:

Replace the `onDone` store with the environment close. Change:
```swift
    @State private var pendingCancel: RecurringRule?
    var onDone: () -> Void
```
to:
```swift
    @State private var pendingCancel: RecurringRule?
    @Environment(\.blurPopupClose) private var close
```

Recolor the inner surface so it matches the popup card. Change:
```swift
            .background(Palette.bg)
            .navigationTitle("Recurring payments")
```
to:
```swift
            .background(Palette.card)
            .navigationTitle("Recurring payments")
```

Change the toolbar Done button:
```swift
                    Button("Done") { onDone() }
```
to:
```swift
                    Button("Done") { close() }
```

Update the preview. Change:
```swift
    RecurringRulesSheet(onDone: {}).modelContainer(SampleData.previewContainer())
```
to:
```swift
    RecurringRulesSheet().modelContainer(SampleData.previewContainer())
```

- [ ] **Step 3: SettingsView — present Report a bug + Recurring via `.blurPopup`**

In `SettingsView.swift`, change the remaining two sheet modifiers. Change:
```swift
            .sheet(isPresented: $showingBugReport) {
                BugReportSheet()
            }
            .sheet(isPresented: $showingRecurring) {
                RecurringRulesSheet { showingRecurring = false }
            }
```
to:
```swift
            .blurPopup(isPresented: $showingBugReport) {
                BugReportSheet()
            }
            .blurPopup(isPresented: $showingRecurring) {
                RecurringRulesSheet()
            }
```

- [ ] **Step 4: Build** — run the build command → `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/BugReportSheet.swift \
        plop/plop/Views/Settings/RecurringRulesSheet.swift \
        plop/plop/Views/Settings/SettingsView.swift
git commit -m "Present Report a bug and Recurring as blurred bottom popups

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite** (nothing should break — presentation only)

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` (same count, ~166).

- [ ] **Step 2: Lint** — `swiftlint lint` → baseline 21/0, no new violations.

- [ ] **Step 3: Simulator smoke check (manual — owner)**

In Settings, against the handoff screenshots, light + dark:
- Opening **Theme / Export / Report a bug / Recurring** blurs the screen and slides an
  opaque rounded card up; closing reverses (no abrupt system slide).
- **Tap the blurred area** dismisses; **drag the card down** dismisses (a short drag
  springs back); the card's **Done / Cancel** dismiss with the same slide-out.
- **Theme:** tapping a mode repaints the (blurred) app live behind the card.
- **Export:** segmented range, date pickers, and the running / success / error phases all
  work inside the card; "Open in Google Sheets" still opens.
- **Report a bug:** focusing the description **raises the card above the keyboard**; "Add
  screenshot" opens the photo picker; "Send" opens the **Mail composer** (a normal system
  sheet), and sending/cancelling returns to a dismissed popup cleanly; the no-Mail
  fallback's Copy/Done work.
- **Recurring:** the list, swipe-to-Stop, the confirmation dialog, and Done all work.
- If the system cover slide still appears under the custom animation, tune per the note
  below.

- [ ] **Step 4: Push + PR**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git push -u origin feature/dialog-popups
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Cleanup B1: add a reusable BlurPopup (blurred scrim + opaque bottom card sliding up,
matching the handoff Dialog) and present Theme, Export, Report a bug, and Recurring with
it instead of system sheets. Dismiss via tap-scrim, drag-down, or the cards' own buttons;
the Report-a-bug card rises with the keyboard. Presentation only.

## Testing
All unit tests pass (no new — presentation change); SwiftLint clean (baseline 21/0).
Sim-verified in Settings against the handoff screenshots: blur + slide, all dismiss
paths, keyboard-rise, and Mail compose, light + dark.
```

---

## Sim-tuning note (the one fiddly bit)

The custom enter/exit relies on `.transaction { $0.disablesAnimations = true }` to
suppress `fullScreenCover`'s built-in slide so only our scrim-fade + card-slide play. If
the simulator still shows the system slide under our animation, the fallback is to drive
the *presentation* without animation at the toggle points — e.g. wrap the
`showing… = true/false` writes in `withTransaction(Transaction { $0.disablesAnimations = true })`
— rather than adding any disable comments. The exact spring (`response 0.34`), scrim
opacity (`0.18`), card paddings (12), and drag thresholds (120 / 240) are confirmed in the
simulator against the handoff.

---

## Self-review notes

- **Spec coverage:** `BlurPopup` component with `.ultraThinMaterial` blur + 0.18 dim,
  radius-26 opaque card, slide-up + scrim-fade, tap/drag/button dismiss, keyboard-rise
  (Task 1); adoption for all four card dialogs via `.blurPopup` + dropping
  detents/own-background (Tasks 2–3); Mail composer kept as a system `.sheet` (Task 3,
  Step 1); `Views/Common/` placement (Task 1). All requirements map to a task.
- **Unified dismissal:** all three dismiss paths route through `BlurPopupContainer.close()`
  — tap-scrim and drag directly, the cards' buttons via the injected
  `\.blurPopupClose`closure — so every dismissal animates (resolves the design's
  BugReportSheet `dismiss()` uncertainty).
- **Type consistency:** the environment key is `blurPopupClose: () -> Void` everywhere;
  `AppearanceSheet`, `ExportSheet`, `RecurringRulesSheet` lose `onDone` and read
  `@Environment(\.blurPopupClose) private var close`; `BugReportSheet` swaps
  `@Environment(\.dismiss)` for the same. All call sites and previews updated to match the
  new initializers.
- **Behavior preserved:** export, theme writing, bug send (Mail + fallback), and recurring
  cancel are untouched; only presentation changes. No business logic → no unit tests
  (consistent with the project's view-testing convention).
- **No placeholders / no disables / config untouched / lines ≤ 120.**
- **Build-green increments:** each task compiles on its own (sheets converted together with
  their call sites; unconverted dialogs keep their existing `.sheet` + initializers).
