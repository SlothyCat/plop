# Report a Bug — Design

Status: Approved (brainstorm complete) · Date: 2026-06-17

Companion to `requirements.md`. Architecture, the mail-compose wrapper, the pure
body builder, the sheet, the no-mail fallback, testing, and slicing.

## Architecture

```
plop/
  Logic/
    BugReport.swift          (PURE: subject + body builder; support address constant)
  Views/Settings/
    MailComposeView.swift    (UIViewControllerRepresentable over MFMailComposeViewController)
    BugReportSheet.swift     (description + screenshot picker + Send/Cancel; presents mail)
    SettingsView.swift       (+ Support section: Export + Report a bug)
```

No new dependencies — `MessageUI` and `PhotosUI` are system frameworks. One PR.

## `BugReport.swift` (pure, the tested core)

```swift
import Foundation

enum BugReport {
    static let supportEmail = "slothycatcoder@gmail.com"
    static let subject = "plop bug report"

    /// The email body: the user's description followed by a diagnostics block.
    /// Inputs are injected so this is fully unit-testable (no Bundle/UIDevice here).
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

The view supplies the diagnostics from the system:
`Bundle.main` `CFBundleShortVersionString` / `CFBundleVersion`, and
`UIDevice.current` `systemName` / `systemVersion` / `model`.

## `MailComposeView.swift`

A `UIViewControllerRepresentable` wrapping `MFMailComposeViewController`:
- Configures recipients `[BugReport.supportEmail]`, subject, body, and—if present—
  `addAttachmentData(_:mimeType: "image/jpeg", fileName: "screenshot.jpg")`.
- A `Coordinator` is the `MFMailComposeViewControllerDelegate`; on finish it calls an
  `onFinish: (MFMailComposeResult) -> Void` to dismiss.
- Inputs: `subject`, `body`, `imageData: Data?`, `onFinish`.

## `BugReportSheet.swift`

Bottom sheet (content-hugging via the same `onGeometryChange` + `.height` detent as
`ExportSheet`):
- Title **Report a bug** + subtitle "Tell us what went wrong — the more detail, the
  faster we can fix it."
- **WHAT HAPPENED** — `TextEditor` bound to `@State description` (placeholder overlay
  "Describe the issue…"), ~96pt tall, `Palette.field` background.
- **SCREENSHOT · OPTIONAL** — `PhotosPicker(selection:matching: .images)`:
  - none → dashed **Add screenshot** button (photo icon).
  - picked → load `Data` + a `UIImage` thumbnail; show thumbnail + "Screenshot" label
    + **Replace** (reopens picker) + remove (×).
- **Send** — `borderedProminent`, `disabled(description.trimmed.isEmpty)`. On tap:
  - if `MFMailComposeViewController.canSendMail()` → present `MailComposeView`
    (subject `BugReport.subject`, body from `BugReport.body(...)`, `imageData`).
  - else → set `showFallback = true`.
- **Cancel** — dismiss.
- On mail finish (any result) → dismiss the sheet.

### State
```swift
@State private var description = ""
@State private var pickerItem: PhotosPickerItem?
@State private var imageData: Data?
@State private var showingMail = false
@State private var showFallback = false
@State private var sheetHeight: CGFloat = 360
```
Loading the image: `.onChange(of: pickerItem)` → `try await pickerItem?.loadTransferable(type: Data.self)` → `imageData`.

## No-mail fallback

When `showFallback`: replace the form body with a short notice —
"No email account set up. Send your report to **slothycatcoder@gmail.com**" — and a
**Copy report** button that puts the composed body (`BugReport.body(...)`) on
`UIPasteboard.general`. Plus a **Done** button.

## SettingsView

Group Export + Report a bug into a **Support** section:
```swift
Section("Support") {
    // existing Export row …
    Button { showingBugReport = true } label: {
        HStack {
            Label("Report a bug", systemImage: "ladybug.fill")
            Spacer()
            Image(systemName: "chevron.forward")
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.tertiary)
        }
    }
    .buttonStyle(.plain)
}
.sheet(isPresented: $showingBugReport) { BugReportSheet() }
```
(The existing standalone Export `Section` becomes this `Section("Support")`.)

## Testing

- `BugReportTests` (XCTest, pure): `supportEmail`/`subject` constants; `body(...)`
  contains the description and each diagnostic (app version, build, OS, device);
  description placed first; body well-formed with an empty description.
- `MailComposeView`, `BugReportSheet` — `#Preview` + simulator. Live Mail compose
  needs a Mail-configured device (the simulator typically reports `canSendMail()` ==
  false, which exercises the fallback path — useful for verifying that).

## Slicing

**One PR** (`feature/bug-report`): `BugReport.swift` + tests, `MailComposeView`,
`BugReportSheet`, the Settings Support section.
