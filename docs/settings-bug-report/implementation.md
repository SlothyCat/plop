# Report a Bug Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Settings "Report a bug" dialog (description + optional screenshot) that opens a prefilled native Mail compose to the support address, with a no-Mail fallback.

**Architecture:** A pure, tested `BugReport` (subject/body builder + support address); a `MailComposeView` wrapping `MFMailComposeViewController`; a `BugReportSheet` (description + `PhotosPicker` + Send/Cancel + fallback); and a Settings "Support" section grouping Export + Report a bug.

**Tech Stack:** SwiftUI, MessageUI, PhotosUI, UIKit, XCTest. iOS 18. No third-party deps.

Single PR on branch `feature/bug-report` (already created; spec committed there).

---

## File structure

- **Create** `plop/plop/Logic/BugReport.swift` — `supportEmail`, `subject`, `body(...)` (pure).
- **Create** `plop/plopTests/BugReportTests.swift`.
- **Create** `plop/plop/Views/Settings/MailComposeView.swift` — `UIViewControllerRepresentable`.
- **Create** `plop/plop/Views/Settings/BugReportSheet.swift` — the dialog.
- **Modify** `plop/plop/Views/Settings/SettingsView.swift` — Support section + Report a bug row + sheet.

### Verified existing context

- `SettingsView` currently has an untitled `Section { … Export button … }` after `Section("Preferences")`, and `.sheet(isPresented: $showingExport)` / `$showingAppearance` on the `List`. This task **retitles that Export section to `Section("Support")`** and adds the Report-a-bug row + sheet there.
- `Palette` tokens; the content-hugging sheet pattern (`onGeometryChange` + `.presentationDetents([.height(...)])`) is established in `ExportSheet.swift`.

### Test / build commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests/BugReportTests -parallel-testing-enabled NO 2>&1 | tail -25

xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'

swiftlint lint
```

> SourceKit false positives for new files are expected — the build/test run is the source of truth. Lines ≤ 120. **No `// swiftlint:disable`** (zero-disable baseline).

---

## Task 1: BugReport (pure) + tests

**Files:**
- Create: `plop/plop/Logic/BugReport.swift`
- Create: `plop/plopTests/BugReportTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/BugReportTests.swift`:

```swift
import XCTest
@testable import plop

final class BugReportTests: XCTestCase {

    func test_constants() {
        XCTAssertEqual(BugReport.supportEmail, "slothycatcoder@gmail.com")
        XCTAssertEqual(BugReport.subject, "plop bug report")
    }

    func test_body_containsDescriptionFirst() {
        let body = BugReport.body(description: "It crashed on save",
                                  appVersion: "1.0", build: "12",
                                  systemName: "iOS", systemVersion: "18.4",
                                  deviceModel: "iPhone")
        XCTAssertTrue(body.hasPrefix("It crashed on save"), body)
    }

    func test_body_containsDiagnostics() {
        let body = BugReport.body(description: "x",
                                  appVersion: "1.2", build: "34",
                                  systemName: "iOS", systemVersion: "18.4",
                                  deviceModel: "iPhone")
        XCTAssertTrue(body.contains("plop 1.2 (34)"), body)
        XCTAssertTrue(body.contains("iOS 18.4"), body)
        XCTAssertTrue(body.contains("iPhone"), body)
        XCTAssertTrue(body.contains("Diagnostics"), body)
    }

    func test_body_emptyDescription_stillWellFormed() {
        let body = BugReport.body(description: "",
                                  appVersion: "1.0", build: "1",
                                  systemName: "iOS", systemVersion: "18.0",
                                  deviceModel: "iPhone")
        XCTAssertTrue(body.contains("Diagnostics"), body)
    }
}
```

- [ ] **Step 2: Run the tests — confirm they FAIL to build.**

- [ ] **Step 3: Implement**

Create `plop/plop/Logic/BugReport.swift`:

```swift
import Foundation

/// Pure helpers for the bug-report email. The body builder takes diagnostics as
/// inputs (no Bundle/UIDevice here) so it is fully unit-testable.
enum BugReport {
    static let supportEmail = "slothycatcoder@gmail.com"
    static let subject = "plop bug report"

    static func body(description: String,
                     appVersion: String, build: String,
                     systemName: String, systemVersion: String,
                     deviceModel: String) -> String {
        """
        \(description)


        ——
        Diagnostics
        App: plop \(appVersion) (\(build))
        OS: \(systemName) \(systemVersion)
        Device: \(deviceModel)
        """
    }
}
```

- [ ] **Step 4: Run the tests — confirm PASS** (4 tests).

- [ ] **Step 5: SwiftLint** — no new violations; no disable comments.

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Logic/BugReport.swift plop/plopTests/BugReportTests.swift
git commit -m "Add BugReport email subject/body builder and tests

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: MailComposeView

**Files:**
- Create: `plop/plop/Views/Settings/MailComposeView.swift`

No unit tests (UIKit wrapper — verified via build). 

- [ ] **Step 1: Write the wrapper**

Create `plop/plop/Views/Settings/MailComposeView.swift`:

```swift
import SwiftUI
import MessageUI

/// Wraps MFMailComposeViewController for SwiftUI: prefills the bug report and reports
/// the result so the presenter can dismiss. Present only when canSendMail() is true.
struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let imageData: Data?
    var onFinish: (MFMailComposeResult) -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([BugReport.supportEmail])
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        if let imageData {
            controller.addAttachmentData(imageData, mimeType: "image/jpeg",
                                         fileName: "screenshot.jpg")
        }
        return controller
    }

    func updateUIViewController(_ controller: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: (MFMailComposeResult) -> Void

        init(onFinish: @escaping (MFMailComposeResult) -> Void) { self.onFinish = onFinish }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            onFinish(result)
        }
    }
}
```

- [ ] **Step 2: Verify the target builds**

Run `xcodebuild build …`. Expected `** BUILD SUCCEEDED **`.

> If Swift 6 concurrency complains that the delegate method must be `nonisolated` or
> `@MainActor`, mark `mailComposeController(_:didFinishWith:error:)` `nonisolated` and
> hop to the main actor for `onFinish` (`Task { @MainActor in onFinish(result) }`), or
> mark the `Coordinator` `@MainActor`. Resolve without disable comments.

- [ ] **Step 3: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/MailComposeView.swift
git commit -m "Add MailComposeView wrapper for MFMailComposeViewController

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: BugReportSheet + Settings Support section

**Files:**
- Create: `plop/plop/Views/Settings/BugReportSheet.swift`
- Modify: `plop/plop/Views/Settings/SettingsView.swift`

No unit tests (SwiftUI views — verify = builds).

- [ ] **Step 1: Write the sheet**

Create `plop/plop/Views/Settings/BugReportSheet.swift`:

```swift
import SwiftUI
import PhotosUI
import MessageUI
import UIKit

/// Report-a-bug dialog: a description + optional screenshot, sent via the native Mail
/// composer (with a no-Mail fallback). Content-hugging detent like ExportSheet.
struct BugReportSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var description = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showingMail = false
    @State private var showFallback = false
    @State private var sheetHeight: CGFloat = 380

    private var canSend: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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

    @ViewBuilder private var content: some View {
        if showFallback { fallback } else { form }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Report a bug")
                .font(.system(size: 22, weight: .bold)).foregroundStyle(Palette.ink)
            Text("Tell us what went wrong — the more detail, the faster we can fix it.")
                .font(.system(size: 14)).foregroundStyle(Palette.ink60)
                .fixedSize(horizontal: false, vertical: true)

            label("WHAT HAPPENED")
            ZStack(alignment: .topLeading) {
                if description.isEmpty {
                    Text("Describe the issue…")
                        .font(.system(size: 15)).foregroundStyle(Palette.ink40)
                        .padding(.horizontal, 12).padding(.vertical, 10)
                }
                TextEditor(text: $description)
                    .font(.system(size: 15)).foregroundStyle(Palette.ink)
                    .scrollContentBackground(.hidden)
                    .frame(height: 96)
                    .padding(.horizontal, 8).padding(.vertical, 2)
            }
            .background(Palette.field, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.ink12, lineWidth: 1))

            label("SCREENSHOT · OPTIONAL")
            screenshotRow

            VStack(spacing: 8) {
                Button { send() } label: { Text("Send").frame(maxWidth: .infinity) }
                    .buttonStyle(.borderedProminent).tint(Palette.accent)
                    .disabled(!canSend)
                Button("Cancel") { dismiss() }.foregroundStyle(Palette.ink60)
            }
        }
    }

    @ViewBuilder private var screenshotRow: some View {
        if let imageData, let image = UIImage(data: imageData) {
            HStack(spacing: 11) {
                Image(uiImage: image).resizable().scaledToFill()
                    .frame(width: 40, height: 52).clipShape(RoundedRectangle(cornerRadius: 7))
                Text("Screenshot").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Spacer()
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Text("Replace").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.ink60)
                }
                Button { self.imageData = nil; pickerItem = nil } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.ink40)
                }
            }
            .padding(10)
            .background(Palette.field, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.ink12, lineWidth: 1))
        } else {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                HStack(spacing: 8) {
                    Image(systemName: "photo")
                    Text("Add screenshot").font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity).padding(.vertical, 13)
                .overlay(RoundedRectangle(cornerRadius: 13)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundStyle(Palette.ink12))
            }
        }
    }

    private var fallback: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("No email set up").font(.system(size: 20, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text("Send your report to \(BugReport.supportEmail).")
                .font(.system(size: 14)).foregroundStyle(Palette.ink60)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 8) {
                Button {
                    UIPasteboard.general.string = composedBody()
                } label: { Text("Copy report").frame(maxWidth: .infinity) }
                    .buttonStyle(.borderedProminent).tint(Palette.accent)
                Button("Done") { dismiss() }.foregroundStyle(Palette.ink60)
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.system(size: 12, weight: .semibold)).tracking(0.5)
            .foregroundStyle(Palette.ink40)
    }

    private func send() {
        if MFMailComposeViewController.canSendMail() {
            showingMail = true
        } else {
            showFallback = true
        }
    }

    private func composedBody() -> String {
        let info = Bundle.main.infoDictionary
        let device = UIDevice.current
        return BugReport.body(
            description: description,
            appVersion: info?["CFBundleShortVersionString"] as? String ?? "?",
            build: info?["CFBundleVersion"] as? String ?? "?",
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            deviceModel: device.model)
    }
}

#if DEBUG
#Preview { BugReportSheet() }
#endif
```

- [ ] **Step 2: Add the Settings Support section + row + sheet**

In `plop/plop/Views/Settings/SettingsView.swift`:

(a) Add a state property after `@State private var showingExport = false`:
```swift
    @State private var showingBugReport = false
```

(b) Find the untitled Export section — `Section {` containing the "Export to Google
Sheets" button — and change its opening line to:
```swift
                Section("Support") {
```

(c) Inside that same section, immediately AFTER the Export button's closing
`.buttonStyle(.plain)` (and before the section's closing `}`), add:
```swift
                    Button {
                        showingBugReport = true
                    } label: {
                        HStack {
                            Label("Report a bug", systemImage: "ladybug.fill")
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
```

(d) Add a sheet modifier on the `List`, right after the existing
`.sheet(isPresented: $showingExport) { … }`:
```swift
            .sheet(isPresented: $showingBugReport) {
                BugReportSheet()
            }
```

Read the file first to place (a)–(d) precisely. Do not change anything else.

- [ ] **Step 3: Verify the target builds**

Run `xcodebuild build …`. Expected `** BUILD SUCCEEDED **`. If a real compile error
occurs in YOUR files, fix it; if in a file you did NOT touch, STOP and report BLOCKED.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/BugReportSheet.swift plop/plop/Views/Settings/SettingsView.swift
git commit -m "Add Report a bug sheet and Settings Support section

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` — all prior + `BugReportTests`.

- [ ] **Step 2: Lint** — `swiftlint lint` → no new violations, no disable comments.

- [ ] **Step 3: Simulator smoke check (manual)**

Run the app → Settings → **Report a bug**:
- Sheet hugs content; **Send** is disabled until a description is typed.
- Add a screenshot → thumbnail + Replace + remove work; sheet grows.
- On the simulator (`canSendMail()` usually false) → **Send** shows the fallback with
  the support address + **Copy report** (paste elsewhere to confirm body + diagnostics).
- On a device/simulator with Mail configured → Send opens the composer prefilled to
  `slothycatcoder@gmail.com` with the body + attached screenshot.
- Cancel dismisses.

- [ ] **Step 4: Push + PR**

```bash
git push -u origin feature/bug-report
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Add Settings → Report a bug: a description + optional screenshot composed into a
prefilled native Mail message to the support address (with diagnostics), plus a
no-Mail fallback (copy report). Completes the Settings cluster.

## Testing
All unit tests pass (4 new in BugReportTests); SwiftLint clean. Sheet + fallback
sim-verified; live Mail compose verified with a configured account.
```

---

## Self-review notes

- **Spec coverage:** pure subject/body + diagnostics builder (Task 1, tested); Mail
  compose wrapper + attachment (Task 2); description `TextEditor`, optional
  `PhotosPicker` screenshot (add/replace/remove), Send disabled-until-described,
  content-hugging detent, no-Mail fallback with copy-to-clipboard (Task 3); Settings
  Support section grouping Export + Report a bug (Task 3).
- **Type consistency:** `BugReport.{supportEmail,subject,body(...)}` used identically
  in `MailComposeView`, `BugReportSheet`, and tests; `MailComposeView(subject:body:imageData:onFinish:)`
  matches its call; `BugReportSheet()` (uses `@Environment(\.dismiss)`) matches the
  Settings call.
- **No placeholders / no disables:** complete code; the one concurrency risk (delegate
  isolation) has an explicit non-disable resolution.
- **Views untested by design:** only `BugReport` (logic) is unit-tested; the views are
  `#Preview` + simulator. The simulator's `canSendMail() == false` conveniently
  exercises the fallback path.
- **No new dependencies:** `MessageUI`/`PhotosUI`/`UIKit` are system frameworks.
