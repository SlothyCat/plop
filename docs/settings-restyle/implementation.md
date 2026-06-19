# Settings Restyle (Cleanup A) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle Settings to the handoff — colored icon tiles, DATA/PREFERENCES/RECURRING/SUPPORT groups, consistent row alignment, and a dynamic version footer. Visual only; no behavior change.

**Architecture:** A reusable `SettingsRow` (tile + label + value + chevron); `SettingsView` regrouped to use it; all existing state/sheets/destinations unchanged.

**Tech Stack:** SwiftUI. iOS 18. No new deps, no tests added (SwiftUI views — preview + simulator).

Single PR on branch `feature/settings-restyle` (off `main`; spec committed there).

---

## File structure

- **Create** `plop/plop/Views/Settings/SettingsRow.swift`.
- **Modify** `plop/plop/Views/Settings/SettingsView.swift` (regroup + use `SettingsRow` + version footer).
- **Manual (owner, Xcode):** set `MARKETING_VERSION = 1.0.0`.

### Verified context

- `Palette` tokens: `accent`, `accentSoft`, `cream`, `yellow`, `tileInk`, `ink`, `ink40`, `bg`.
- `SettingsView` state to preserve: `@AppStorage` currencyCode/budgetModeRaw/generalBudget/themeModeRaw, `@Query` categories + transactions, `showingAppearance/showingExport/showingBugReport/showingRecurring`, `budgetSummary`, and the four `.sheet` modifiers.
- Rows + behaviors (unchanged): Set budget / Manage categories / Currency = `NavigationLink` (push); Theme / Recurring / Export / Bug = `Button` → sheet.

### Build / lint commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | tail -5

swiftlint lint
```

> SourceKit false positives expected. Lines ≤ 120. No `// swiftlint:disable`; don't edit `.swiftlint.yml`.

---

## Task 1: SettingsRow component

**Files:**
- Create: `plop/plop/Views/Settings/SettingsRow.swift`

- [ ] **Step 1: Write it**

Create `plop/plop/Views/Settings/SettingsRow.swift`:

```swift
import SwiftUI

/// One Settings row: a colored icon tile, a label, an optional trailing value, and a
/// chevron. Used inside NavigationLink labels (showsChevron: false — the link adds its
/// own chevron) and Button labels (showsChevron: true).
struct SettingsRow: View {
    let tile: Color
    let systemImage: String
    let title: String
    var value: String? = nil
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Palette.tileInk)
                .frame(width: 30, height: 30)
                .background(tile, in: RoundedRectangle(cornerRadius: 9))
            Text(title)
                .font(.system(size: 16.5, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer(minLength: 8)
            if let value {
                Text(value).font(.system(size: 15.5)).foregroundStyle(Palette.ink40)
            }
            if showsChevron {
                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#if DEBUG
#Preview {
    List {
        SettingsRow(tile: Palette.accent, systemImage: "chart.pie.fill",
                    title: "Set budget", value: "$1,020", showsChevron: false)
        SettingsRow(tile: Palette.yellow, systemImage: "circle.lefthalf.filled",
                    title: "Theme", value: "Automatic")
    }
}
#endif
```

- [ ] **Step 2: Verify the target builds**

Run `xcodebuild build …`. Expected `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Lint** — no new violations.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/SettingsRow.swift
git commit -m "Add reusable SettingsRow with colored icon tile

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Restructure SettingsView

**Files:**
- Modify: `plop/plop/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Replace the file**

Replace the entire contents of `plop/plop/Views/Settings/SettingsView.swift` with:

```swift
import SwiftUI
import SwiftData

/// Settings tab: grouped list (DATA / PREFERENCES / RECURRING / SUPPORT). Rows use the
/// shared SettingsRow for consistent alignment. Behaviors are unchanged: Set budget /
/// Manage categories / Currency push; Theme / Recurring / Export / Bug open sheets.
struct SettingsView: View {
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @AppStorage(budgetModeKey) private var budgetModeRaw = BudgetMode.category.rawValue
    @AppStorage(generalBudgetKey) private var generalBudget = ""
    @AppStorage(themeModeKey) private var themeModeRaw = ThemeMode.automatic.rawValue
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    @Query private var transactions: [Transaction]
    @State private var showingAppearance = false
    @State private var showingExport = false
    @State private var showingBugReport = false
    @State private var showingRecurring = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { showingExport = true } label: {
                        SettingsRow(tile: Palette.accent, systemImage: "square.and.arrow.up",
                                    title: "Export to Google Sheets")
                    }
                    .buttonStyle(.plain)
                } header: { groupLabel("DATA") }

                Section {
                    NavigationLink { BudgetView() } label: {
                        SettingsRow(tile: Palette.accent, systemImage: "chart.pie.fill",
                                    title: "Set budget", value: budgetSummary, showsChevron: false)
                    }
                    NavigationLink { ManageCategoriesView() } label: {
                        SettingsRow(tile: Palette.accentSoft, systemImage: "tag.fill",
                                    title: "Manage categories", showsChevron: false)
                    }
                    NavigationLink { CurrencyView() } label: {
                        SettingsRow(tile: Palette.cream, systemImage: "dollarsign.circle.fill",
                                    title: "Currency", value: currencyCode, showsChevron: false)
                    }
                    Button { showingAppearance = true } label: {
                        SettingsRow(tile: Palette.yellow, systemImage: "circle.lefthalf.filled",
                                    title: "Theme",
                                    value: (ThemeMode(rawValue: themeModeRaw) ?? .automatic).title)
                    }
                    .buttonStyle(.plain)
                } header: { groupLabel("PREFERENCES") }

                Section {
                    Button { showingRecurring = true } label: {
                        SettingsRow(tile: Palette.accentSoft,
                                    systemImage: "arrow.triangle.2.circlepath",
                                    title: "Recurring payments")
                    }
                    .buttonStyle(.plain)
                } header: { groupLabel("RECURRING") }

                Section {
                    Button { showingBugReport = true } label: {
                        SettingsRow(tile: Palette.accentSoft, systemImage: "ladybug.fill",
                                    title: "Report a bug")
                    }
                    .buttonStyle(.plain)
                } header: { groupLabel("SUPPORT") }

                Section {
                    Text(versionText)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Palette.ink40)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(Palette.bg)
            .sheet(isPresented: $showingAppearance) {
                AppearanceSheet { showingAppearance = false }
            }
            .sheet(isPresented: $showingExport) {
                ExportSheet(transactions: transactions, categories: categories) {
                    showingExport = false
                }
            }
            .sheet(isPresented: $showingBugReport) {
                BugReportSheet()
            }
            .sheet(isPresented: $showingRecurring) {
                RecurringRulesSheet { showingRecurring = false }
            }
        }
        .tint(Palette.accent)
    }

    private func groupLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12.5, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(Palette.ink40)
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return "Version \(version ?? "")"
    }

    private var budgetSummary: String {
        let mode = BudgetMode(rawValue: budgetModeRaw) ?? .category
        let total = activeBudgetTotal(mode: mode, generalBudget: generalBudget,
                                      categories: categories)
        return total == 0 ? "None" : formattedMoney(total, currencyCode: currencyCode)
    }
}

#if DEBUG
#Preview { SettingsView().modelContainer(SampleData.previewContainer()) }
#endif
```

- [ ] **Step 2: Verify the target builds**

Run `xcodebuild build …`. Expected `** BUILD SUCCEEDED **`. (If a real error is in a file you didn't touch, STOP and report BLOCKED.)

- [ ] **Step 3: Lint** — no new violations; `.swiftlint.yml` unchanged.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/SettingsView.swift
git commit -m "Restyle Settings: tiled rows, DATA/PREFERENCES/RECURRING/SUPPORT, version footer

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Bump marketing version (MANUAL — owner)

So the dynamic footer reads "Version 1.0.0".

- [ ] **Step 1:** Xcode → **plop target → General → Identity → Version** = `1.0.0`
  (build setting `MARKETING_VERSION`). ⌘B.
- [ ] **Step 2:** Commit the `project.pbxproj` change:
```bash
git add plop/plop.xcodeproj/project.pbxproj
git commit -m "Bump marketing version to 1.0.0

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```
(Optional/non-blocking: if skipped, the footer reads "Version 1.0".)

---

## Task 4: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite** (no tests added, but confirm nothing broke)

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` — same count as before (166).

- [ ] **Step 2: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 3: Simulator smoke check (manual)**

Settings shows four groups (DATA / PREFERENCES / RECURRING / SUPPORT), each row with a
colored tile, aligned label/value/chevron columns, and a centered "Version …" footer.
Every row still does what it did: Set budget / Manage categories / Currency push;
Theme / Recurring / Export / Report a bug open their sheets. Check light + dark.

- [ ] **Step 4: Push + PR**

```bash
git push -u origin feature/settings-restyle
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Settings restyle (cleanup A): a reusable SettingsRow with colored icon tiles, regrouped
into DATA / PREFERENCES / RECURRING / SUPPORT, aligned rows, and a dynamic version
footer. Visual only — no behavior/presentation change (push-vs-popup + blur is cleanup B).

## Testing
All unit tests pass (no new — visual change); SwiftLint clean. Settings sim-verified
(light + dark); row behaviors unchanged.
```

---

## Self-review notes

- **Spec coverage:** reusable `SettingsRow` with tiles (Task 1); DATA/PREFERENCES/
  RECURRING/SUPPORT grouping with Export under DATA + custom labels (Task 2);
  per-row tile/icon mapping (Task 2); dynamic version footer (Task 2) + the manual
  `MARKETING_VERSION` bump (Task 3). Push-vs-popup + blur deferred to cleanup B.
- **Behavior preserved:** all `@AppStorage`/`@Query` state, `budgetSummary`, the four
  `.sheet` modifiers, and every row's push/sheet action are unchanged — only row
  appearance + grouping + footer differ.
- **Type consistency:** `SettingsRow(tile:systemImage:title:value:showsChevron:)` matches
  all call sites; reuses `Palette`, `ThemeMode`, `BudgetMode`, `activeBudgetTotal`,
  `formattedMoney`, the existing sheet views.
- **No placeholders / no disables / config untouched** (the version bump is a manual
  Xcode step, not an agent pbxproj edit).
