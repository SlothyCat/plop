# Export PR5 — ExportService + UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tie the export feature together end-to-end: an `ExportService` that runs auth → build → upload with observable phases, an `ExportSheet` dialog (range picker → Export → progress / success-with-link / error), and the Settings **Export to Google Sheets** row. This is the first **live OAuth** path.

**Architecture:** `ExportService` (`@MainActor @Observable`) takes injected `authorize`/`upload` closures (live factory wires `GoogleOAuth` + `SheetsClient`; tests inject fakes) and publishes a `Phase`. `ExportSheet` builds the `[MonthSheet]` via `buildExportSheets` from the chosen `ExportRange`, drives the service, and renders each phase. Settings presents it.

**Tech Stack:** SwiftUI, Observation, SwiftData, XCTest. iOS 18.

**Final export PR.** Branch: `feature/export-service-ui`, off `main` after PR4 (SheetsClient) merges.

---

## File structure

- **Create** `plop/plop/Services/ExportService.swift` — observable orchestrator (unit-tested).
- **Create** `plop/plopTests/ExportServiceTests.swift`.
- **Create** `plop/plop/Views/Settings/ExportSheet.swift` — the dialog (build + sim verified).
- **Modify** `plop/plop/Views/Settings/SettingsView.swift` — add the Export row + sheet.

### Verified existing symbols this builds on

- `GoogleOAuth(clientID:session:webAuth:)` + `authorize() async throws -> String`; `WebAuthenticator()`; `Secrets.googleClientID`.
- `SheetsClient(token:session:)` + `upload(monthSheets:) async throws -> URL`.
- `buildExportSheets(transactions:categories:options:) -> [MonthSheet]`, `ExportOptions(range:budgetMode:generalBudget:currencyCode:now:calendar:)`, `ExportRange` (`.thisMonth` / `.dateRange(ClosedRange<Date>)`).
- `ExportError` + `exportError(from:)`; `BudgetMode`, keys `currencyCodeKey`/`budgetModeKey`/`generalBudgetKey`, `deviceCurrencyCode()`.
- `Palette`, `Transaction`, `ExpenseCategory`.

### Test / build commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests/ExportServiceTests -parallel-testing-enabled NO 2>&1 | tail -25

xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'

swiftlint lint
```

> SourceKit false positives expected. Lines ≤ 120. **No `// swiftlint:disable`** (zero-disable baseline).

---

## Task 1: ExportService + tests

**Files:**
- Create: `plop/plop/Services/ExportService.swift`
- Create: `plop/plopTests/ExportServiceTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/ExportServiceTests.swift`:

```swift
import XCTest
@testable import plop

@MainActor
final class ExportServiceTests: XCTestCase {

    private let sheets = [MonthSheet(year: 2026, month: 6, values: [["x"]])]
    private let url = URL(string: "https://docs.google.com/SS")!

    func test_run_success_setsSuccessPhase() async {
        let service = ExportService(authorize: { "TOKEN" },
                                    upload: { _, _ in self.url })
        await service.run(monthSheets: sheets)
        XCTAssertEqual(service.phase, .success(url))
    }

    func test_run_authFailure_mapsToFailure() async {
        let service = ExportService(authorize: { throw ExportError.cancelled },
                                    upload: { _, _ in self.url })
        await service.run(monthSheets: sheets)
        XCTAssertEqual(service.phase, .failure(.cancelled))
    }

    func test_run_uploadFailure_mapsToFailure() async {
        let service = ExportService(authorize: { "TOKEN" },
                                    upload: { _, _ in throw ExportError.storageFull })
        await service.run(monthSheets: sheets)
        XCTAssertEqual(service.phase, .failure(.storageFull))
    }

    func test_run_networkError_mappedThroughExportError() async {
        let service = ExportService(authorize: { throw URLError(.notConnectedToInternet) },
                                    upload: { _, _ in self.url })
        await service.run(monthSheets: sheets)
        XCTAssertEqual(service.phase, .failure(.network))
    }

    func test_run_passesTokenAndSheetsToUpload() async {
        var seenToken: String?
        var seenCount: Int?
        let service = ExportService(authorize: { "TOK" },
                                    upload: { token, sheets in
                                        seenToken = token; seenCount = sheets.count; return self.url
                                    })
        await service.run(monthSheets: sheets)
        XCTAssertEqual(seenToken, "TOK")
        XCTAssertEqual(seenCount, 1)
    }
}
```

- [ ] **Step 2: Run the tests — confirm they FAIL to build.**

- [ ] **Step 3: Implement**

Create `plop/plop/Services/ExportService.swift`:

```swift
import Foundation
import Observation

/// Orchestrates an export: authorize → upload, publishing the phase for the UI.
/// `authorize`/`upload` are injected so the live wiring (GoogleOAuth + SheetsClient)
/// and tests (fakes) share one path. Stateless — no token is retained after `run`.
@MainActor
@Observable
final class ExportService {
    enum Phase: Equatable {
        case idle
        case running
        case success(URL)
        case failure(ExportError)
    }

    private(set) var phase: Phase = .idle

    private let authorize: () async throws -> String
    private let upload: (String, [MonthSheet]) async throws -> URL

    init(authorize: @escaping () async throws -> String,
         upload: @escaping (String, [MonthSheet]) async throws -> URL) {
        self.authorize = authorize
        self.upload = upload
    }

    func run(monthSheets: [MonthSheet]) async {
        phase = .running
        do {
            let token = try await authorize()
            phase = .success(try await upload(token, monthSheets))
        } catch {
            phase = .failure(exportError(from: error))
        }
    }
}

extension ExportService {
    /// Production wiring: real OAuth + Sheets client over URLSession.shared.
    static func live() -> ExportService {
        ExportService(
            authorize: {
                try await GoogleOAuth(clientID: Secrets.googleClientID,
                                      session: .shared,
                                      webAuth: WebAuthenticator()).authorize()
            },
            upload: { token, sheets in
                try await SheetsClient(token: token, session: .shared).upload(monthSheets: sheets)
            })
    }
}
```

- [ ] **Step 4: Run the tests — confirm PASS** (5 tests).

- [ ] **Step 5: SwiftLint** — no new violations; no disable comments.

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Services/ExportService.swift plop/plopTests/ExportServiceTests.swift
git commit -m "Add ExportService orchestrator with observable phases

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: ExportSheet + Settings row

**Files:**
- Create: `plop/plop/Views/Settings/ExportSheet.swift`
- Modify: `plop/plop/Views/Settings/SettingsView.swift`

No unit tests (SwiftUI views — `#Preview` + simulator, per CLAUDE.md). Verify = builds.

- [ ] **Step 1: Write the ExportSheet view**

Create `plop/plop/Views/Settings/ExportSheet.swift`:

```swift
import SwiftUI

/// Export dialog: pick a range, run the export, and show progress / success (with a
/// link to the sheet) / error. Builds the month matrices from local data on Export.
struct ExportSheet: View {
    let transactions: [Transaction]
    let categories: [ExpenseCategory]
    var onDone: () -> Void

    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @AppStorage(budgetModeKey) private var budgetModeRaw = BudgetMode.category.rawValue
    @AppStorage(generalBudgetKey) private var generalBudget = ""
    @Environment(\.openURL) private var openURL

    @State private var service = ExportService.live()
    @State private var rangeKind: RangeKind = .thisMonth
    @State private var from = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var to = Date.now
    @State private var emptyNotice = false

    private enum RangeKind: String, CaseIterable { case thisMonth = "This month"
        case dateRange = "Date range" }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            switch service.phase {
            case .running:
                phaseRunning
            case .success(let url):
                phaseSuccess(url)
            default:
                form
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.bg)
        .presentationDetents([.medium])
    }

    // MARK: form (idle / failure)

    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20)).foregroundStyle(Palette.tileInk)
                    .frame(width: 42, height: 42)
                    .background(Palette.accentSoft, in: RoundedRectangle(cornerRadius: 13))
                Text("Export to Google Sheets")
                    .font(.system(size: 20, weight: .bold)).foregroundStyle(Palette.ink)
            }

            Text("Your transactions for the selected period are sent to a sheet in your "
                 + "Google account.")
                .font(.system(size: 14)).foregroundStyle(Palette.ink60)

            Picker("Range", selection: $rangeKind) {
                ForEach(RangeKind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            if rangeKind == .dateRange {
                HStack(spacing: 10) {
                    DatePicker("From", selection: $from, displayedComponents: .date)
                        .labelsHidden()
                    Text("to").foregroundStyle(Palette.ink40)
                    DatePicker("To", selection: $to, in: from..., displayedComponents: .date)
                        .labelsHidden()
                }
                .tint(Palette.accent)
            }

            if case .failure(let error) = service.phase, let message = error.message {
                Text(message).font(.system(size: 13.5)).foregroundStyle(Palette.ink)
            }
            if emptyNotice {
                Text("No transactions in this range.")
                    .font(.system(size: 13.5)).foregroundStyle(Palette.ink60)
            }

            VStack(spacing: 8) {
                Button { Task { await runExport() } } label: {
                    Text("Export").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(Palette.accent)
                Button("Cancel") { onDone() }.foregroundStyle(Palette.ink60)
            }
            Spacer(minLength: 0)
        }
    }

    private var phaseRunning: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text("Exporting…").font(.system(size: 15)).foregroundStyle(Palette.ink60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func phaseSuccess(_ url: URL) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44)).foregroundStyle(Palette.accent)
            Text("Export complete").font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Palette.ink)
            Button { openURL(url) } label: {
                Label("Open in Google Sheets", systemImage: "arrow.up.right.square")
            }
            .buttonStyle(.borderedProminent).tint(Palette.accent)
            Button("Done") { onDone() }.foregroundStyle(Palette.ink60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: action

    private func runExport() async {
        emptyNotice = false
        let range: ExportRange = rangeKind == .thisMonth
            ? .thisMonth
            : .dateRange(min(from, to)...max(from, to))
        let sheets = buildExportSheets(
            transactions: transactions, categories: categories,
            options: ExportOptions(range: range,
                                   budgetMode: BudgetMode(rawValue: budgetModeRaw) ?? .category,
                                   generalBudget: generalBudget, currencyCode: currencyCode))
        guard !sheets.isEmpty else { emptyNotice = true; return }
        await service.run(monthSheets: sheets)
    }
}

#if DEBUG
#Preview {
    ExportSheet(transactions: [], categories: [], onDone: {})
}
#endif
```

- [ ] **Step 2: Add the Settings Export row**

In `plop/plop/Views/Settings/SettingsView.swift`:

Add stored properties (after the existing `@AppStorage`/`@Query` lines):

```swift
    @Query private var transactions: [Transaction]
    @State private var showingExport = false
```

Add a second `Section` after the `Section("Preferences") { … }` block (inside `List`):

```swift
                Section {
                    Button {
                        showingExport = true
                    } label: {
                        HStack {
                            Label("Export to Google Sheets", systemImage: "square.and.arrow.up")
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
```

Add the sheet modifier next to the existing `.sheet(isPresented: $showingAppearance)` (on the `List`):

```swift
            .sheet(isPresented: $showingExport) {
                ExportSheet(transactions: transactions, categories: categories) {
                    showingExport = false
                }
            }
```

- [ ] **Step 3: Verify the target builds**

```bash
xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/ExportSheet.swift plop/plop/Views/Settings/SettingsView.swift
git commit -m "Add Export sheet and Settings row

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
Expected: `** TEST SUCCEEDED **` — all prior + `ExportServiceTests`.

- [ ] **Step 2: Lint** — `swiftlint lint` → no new violations, no disable comments.

- [ ] **Step 3: LIVE simulator check (manual — owner; needs a Google account)**

Run the app → Settings → **Export to Google Sheets**:
- **This month** → Export → the Google sign-in sheet appears (real OAuth via the
  Info.plist redirect scheme on `main`) → consent → progress → "Export complete" →
  **Open in Google Sheets** opens the spreadsheet.
- Verify in Drive: a **`plop-transactions`** folder with **`plop {year}`** containing a
  **`{year}-MM`** tab — summary block (totals, budget, category breakdown) + transaction rows.
- **Re-export** the same month → no duplicate file/rows (tab rewritten).
- **Date range** spanning two months → two tabs written.
- **Cancel** the sign-in → returns to the form silently (no error).
- Airplane mode → Export → "No connection…" message.
- Switch the Currency picker → exported amounts' header reflects it.

- [ ] **Step 4: Push + PR**

```bash
git push -u origin feature/export-service-ui
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Wire up export end-to-end: ExportService (authorize → upload, observable phases),
the ExportSheet dialog (range picker, progress, success-with-link, error), and the
Settings Export row. Completes the Google Sheets export feature.

## Testing
All unit tests pass (5 new in ExportServiceTests); SwiftLint clean. Live OAuth +
Sheets export verified in the simulator (sign-in, folder/spreadsheet/tabs, re-export
rewrite, open link, cancel, offline).
```

---

## Self-review notes

- **Spec coverage:** ExportService orchestration + error mapping (Task 1, tested);
  ExportSheet range picker (This month / Date range), Export action building matrices,
  progress/success(open-link)/error states, empty-range notice (Task 2); Settings
  Export row (Task 2); live OAuth path via `ExportService.live()` (Task 2/3).
- **Type consistency:** `ExportService(authorize:upload:)` + `.run(monthSheets:)` +
  `.Phase` match tests; `ExportSheet(transactions:categories:onDone:)` matches the
  Settings call; reuses `buildExportSheets`/`ExportOptions`/`ExportRange`,
  `GoogleOAuth`/`SheetsClient`/`Secrets`, `ExportError`/`exportError(from:)`.
- **No placeholders / no disables:** complete code; the one copy-slip
  (`Palette.incomeGreen == …`) is explicitly corrected in Task 2 Step 2.
- **Views untested by design:** ExportSheet via `#Preview` + the manual live run; only
  ExportService (logic) is unit-tested.
- **Dependency:** PR4 (SheetsClient) and PR1–3 + wiring must be on `main` first.
