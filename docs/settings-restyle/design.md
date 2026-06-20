# Settings Restyle (Cleanup A) — Design

Status: Approved (brainstorm complete) · Date: 2026-06-19

Companion to `requirements.md`. The reusable row, the regrouped `SettingsView`, the
version footer, the manual version bump, testing, and scope.

## Architecture

```
plop/
  Views/Settings/
    SettingsRow.swift   (NEW: tile + label + optional value + chevron)
    SettingsView.swift  (regroup into DATA/PREFERENCES/RECURRING/SUPPORT; rows use SettingsRow; version footer)
```

One PR. No new dependencies. Behavior, destinations, and sheets are untouched — only
row appearance, grouping, and the footer change.

## `SettingsRow.swift`

```swift
import SwiftUI

/// One Settings row: a colored icon tile, a label, an optional trailing value, and a
/// chevron. Used inside both NavigationLink labels (showsChevron: false — the link
/// supplies its own chevron) and Button labels (showsChevron: true).
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
```

## `SettingsView` restructure

Keep all existing state (`showingAppearance`/`showingExport`/`showingBugReport`/
`showingRecurring`, the `@AppStorage`/`@Query`, `budgetSummary`) and all `.sheet`
modifiers. Replace the row contents and grouping:

```swift
List {
    Section { 
        Button { showingExport = true } label: {
            SettingsRow(tile: Palette.accent, systemImage: "square.and.arrow.up",
                        title: "Export to Google Sheets")
        }.buttonStyle(.plain)
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
        }.buttonStyle(.plain)
    } header: { groupLabel("PREFERENCES") }

    Section {
        Button { showingRecurring = true } label: {
            SettingsRow(tile: Palette.accentSoft, systemImage: "arrow.triangle.2.circlepath",
                        title: "Recurring payments")
        }.buttonStyle(.plain)
    } header: { groupLabel("RECURRING") }

    Section {
        Button { showingBugReport = true } label: {
            SettingsRow(tile: Palette.accentSoft, systemImage: "ladybug.fill",
                        title: "Report a bug")
        }.buttonStyle(.plain)
    } header: { groupLabel("SUPPORT") }

    Section {
        Text(versionText)
            .font(.system(size: 12.5)).foregroundStyle(Palette.ink40)
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowBackground(Color.clear)
    }
}
.navigationTitle("Settings")
.scrollContentBackground(.hidden)
.background(Palette.bg)
// existing .sheet modifiers unchanged …
```

Helpers on `SettingsView`:
```swift
private func groupLabel(_ text: String) -> some View {
    Text(text).font(.system(size: 12.5, weight: .semibold)).tracking(0.5)
        .foregroundStyle(Palette.ink40)
}

private var versionText: String {
    let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    return "Version \(v ?? "")"
}
```

> Chevrons: NavigationLink rows already render the system disclosure chevron, so they
> pass `showsChevron: false`; Button rows draw the matching `chevron.forward`. Both sit
> on the trailing edge, so columns stay aligned.

## Manual Xcode step (owner)

Set the marketing version so the dynamic footer reads "Version 1.0.0":
- Xcode → **plop target → General → Identity → Version** = `1.0.0`
  (build setting `MARKETING_VERSION`; this writes `project.pbxproj`).
- If skipped, the footer simply reads "Version 1.0" (current value) — not blocking.

(The agent reads the value at runtime; it does not edit `project.pbxproj` while Xcode
is open.)

## Testing

- `SettingsRow` + `SettingsView` via `#Preview` + simulator (no view unit tests, per
  convention). Verify: tiles + colors, alignment of label/value/chevron across rows,
  the four group labels, the centered version footer, and that every row still does
  exactly what it did (Budget/Categories/Currency push; Theme/Export/Recurring/Bug
  open their sheets).

## Scope (restated)

Visual only. No push→popup conversion, no blur, no behavior/destination changes — all
deferred to Cleanup B.
