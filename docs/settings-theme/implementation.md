# Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Light / Dark / Automatic appearance setting that themes the whole app from a bottom-sheet picker in Settings.

**Architecture:** Make `Palette`'s scheme-dependent tokens adaptive (a `Color.dynamic(light:dark:)` helper), apply the chosen `ThemeMode` once at the app root via `.preferredColorScheme`, and present an `AppearanceSheet` from a Settings row. Because every view already reads `Palette.*`, no per-view changes are needed.

**Tech Stack:** SwiftUI, `@AppStorage`, UIKit dynamic `UIColor`, XCTest. iOS 18.

Single PR on branch `feature/theme` (already created; spec already committed there).

---

## File structure

- **Create** `plop/plop/Theme/ThemeMode.swift` — the mode enum, `colorScheme` mapping, `@AppStorage` key, display strings/symbols.
- **Create** `plop/plopTests/ThemeModeTests.swift` — unit tests for the enum logic.
- **Modify** `plop/plop/Theme/Color+Hex.swift` — add `Color.dynamic(_:_:)`.
- **Modify** `plop/plop/Theme/Palette.swift` — scheme-dependent tokens become dynamic.
- **Modify** `plop/plop/ContentView.swift` — apply `.preferredColorScheme`.
- **Create** `plop/plop/Views/Settings/AppearanceSheet.swift` — the bottom-sheet picker.
- **Modify** `plop/plop/Views/Settings/SettingsView.swift` — add the Theme row.

### Conventions (verified)

- `Color+Hex.swift` already imports `SwiftUI` + `UIKit` and defines `Color(hex:)`.
- Test file shape: `import XCTest` + `@testable import plop`, `final class XTests: XCTestCase` (see `CurrencyTests.swift`).
- `@AppStorage` settings pattern: `currencyCodeKey`, `budgetModeKey` etc. live next to their logic.
- Previews with SwiftData use `.modelContainer(SampleData.previewContainer())`.

### Test / build commands

```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests/ThemeModeTests -parallel-testing-enabled NO

xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'

swiftlint lint
```

> SourceKit shows false "Cannot find X in scope" / "No such module 'XCTest'" for
> same-module symbols and new files. **The build/test run is the source of truth.**
> Keep lines ≤ 120 chars (SwiftLint `line_length`).

---

## Task 1: ThemeMode + tests

**Files:**
- Create: `plop/plop/Theme/ThemeMode.swift`
- Create: `plop/plopTests/ThemeModeTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/ThemeModeTests.swift`:

```swift
import XCTest
import SwiftUI
@testable import plop

final class ThemeModeTests: XCTestCase {

    func test_rawValues() {
        XCTAssertEqual(ThemeMode.light.rawValue, "light")
        XCTAssertEqual(ThemeMode.dark.rawValue, "dark")
        XCTAssertEqual(ThemeMode.automatic.rawValue, "automatic")
    }

    func test_allCases_isThree() {
        XCTAssertEqual(ThemeMode.allCases.count, 3)
    }

    func test_colorScheme_mapping() {
        XCTAssertEqual(ThemeMode.light.colorScheme, .light)
        XCTAssertEqual(ThemeMode.dark.colorScheme, .dark)
        XCTAssertNil(ThemeMode.automatic.colorScheme)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the `-only-testing:plopTests/ThemeModeTests` command. Expected: BUILD FAILS — `ThemeMode` is undefined.

- [ ] **Step 3: Write the implementation**

Create `plop/plop/Theme/ThemeMode.swift`:

```swift
import SwiftUI

let themeModeKey = "themeMode"

/// The app appearance setting. `automatic` follows the system.
enum ThemeMode: String, CaseIterable, Identifiable {
    case light, dark, automatic

    var id: String { rawValue }

    /// nil = follow the system (Automatic).
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .automatic: return nil
        }
    }

    var title: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .automatic: return "Automatic"
        }
    }

    var subtitle: String {
        switch self {
        case .light: return "Always light"
        case .dark: return "Always dark"
        case .automatic: return "Match device appearance"
        }
    }

    var symbol: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .automatic: return "circle.lefthalf.filled"
        }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the Step 2 command. Expected: `** TEST SUCCEEDED **`, 3 tests green.

- [ ] **Step 5: Commit**

```bash
git add plop/plop/Theme/ThemeMode.swift plop/plopTests/ThemeModeTests.swift
git commit -m "Add ThemeMode enum and tests

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Adaptive Palette + root wiring

**Files:**
- Modify: `plop/plop/Theme/Color+Hex.swift`
- Modify: `plop/plop/Theme/Palette.swift`
- Modify: `plop/plop/ContentView.swift`

After this task the app already supports dark mode under **Automatic** (toggle the
simulator appearance to verify), before the picker exists.

- [ ] **Step 1: Add the dynamic-color helper**

In `plop/plop/Theme/Color+Hex.swift`, add to the `extension Color { ... }` block
(after `init(hex:)`):

```swift
    /// Resolves to `light` or `dark` per the active interface style; repaints on flip.
    static func dynamic(_ light: Color, _ dark: Color) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
    }
```

- [ ] **Step 2: Make Palette tokens adaptive**

Replace the entire contents of `plop/plop/Theme/Palette.swift` with:

```swift
import SwiftUI

/// Color tokens from the design handoff. Scheme-dependent tokens resolve light/dark
/// automatically via `Color.dynamic`, so the whole app themes with no per-view
/// changes. Brand accents are identical in both themes.
enum Palette {
    static let bg = Color.dynamic(Color(hex: "#DCEBF7"), Color(hex: "#121922"))
    static let card = Color.dynamic(Color(hex: "#FFFFFF"), Color(hex: "#1C2530"))
    static let field = Color.dynamic(Color(hex: "#FCFDFE"), Color(hex: "#232E3A"))
    static let ink = Color.dynamic(Color(hex: "#2A2A2A"), Color(hex: "#EAF1F7"))

    static let ink60 = Color.dynamic(charcoal(0.55), offWhite(0.62))
    static let ink40 = Color.dynamic(charcoal(0.38), offWhite(0.40))
    static let ink12 = Color.dynamic(charcoal(0.10), offWhite(0.14))
    static let hair = Color.dynamic(charcoal(0.08), offWhite(0.10))

    static let accent = Color(hex: "#8CC0EB")      // brand — fixed in both themes
    static let accentSoft = Color(hex: "#BFDDF0")
    static let cream = Color(hex: "#FFEBCC")
    static let yellow = Color(hex: "#FFF9D2")
    static let tileInk = Color(hex: "#2A2A2A")     // glyph on fixed pastel tiles
    static let incomeGreen = Color.dynamic(Color(hex: "#1F8A5B"), Color(hex: "#4ECB8B"))

    private static func charcoal(_ opacity: Double) -> Color {
        Color(.sRGB, white: 0x2A / 255, opacity: opacity)
    }

    private static func offWhite(_ opacity: Double) -> Color {
        Color(.sRGB, red: 234 / 255, green: 241 / 255, blue: 247 / 255, opacity: opacity)
    }
}
```

- [ ] **Step 3: Apply the mode at the root**

Replace the body of `plop/plop/ContentView.swift`'s `ContentView` with:

```swift
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(themeModeKey) private var themeModeRaw = ThemeMode.automatic.rawValue

    var body: some View {
        RootView()
            .preferredColorScheme((ThemeMode(rawValue: themeModeRaw) ?? .automatic).colorScheme)
            .task {
                DefaultData.seedIfNeeded(in: modelContext)
            }
    }
}
```

(Leave the `#Preview` block unchanged.)

- [ ] **Step 4: Verify the target builds**

Run the `xcodebuild build` command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add plop/plop/Theme/Color+Hex.swift plop/plop/Theme/Palette.swift plop/plop/ContentView.swift
git commit -m "Make Palette adaptive and apply theme at the root

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: AppearanceSheet + Settings row

**Files:**
- Create: `plop/plop/Views/Settings/AppearanceSheet.swift`
- Modify: `plop/plop/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Write the sheet**

Create `plop/plop/Views/Settings/AppearanceSheet.swift`:

```swift
import SwiftUI

/// Bottom-sheet appearance picker: Light / Dark / Automatic. Tapping a card writes
/// @AppStorage(themeModeKey); the app repaints live behind the sheet. Done dismisses.
struct AppearanceSheet: View {
    @AppStorage(themeModeKey) private var themeModeRaw = ThemeMode.automatic.rawValue
    var onDone: () -> Void

    private var selected: ThemeMode { ThemeMode(rawValue: themeModeRaw) ?? .automatic }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Appearance")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Text("Choose how the app looks. Automatic follows your device's "
                     + "light or dark setting.")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.ink60)
            }

            VStack(spacing: 10) {
                ForEach(ThemeMode.allCases) { mode in
                    card(mode)
                }
            }

            Button("Done") { onDone() }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.card)
        .presentationDetents([.medium])
    }

    private func card(_ mode: ThemeMode) -> some View {
        let on = mode == selected
        return Button { themeModeRaw = mode.rawValue } label: {
            HStack(spacing: 14) {
                Image(systemName: mode.symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 42, height: 42)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 1) {
                    Text(mode.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Text(mode.subtitle)
                        .font(.system(size: 13.5))
                        .foregroundStyle(Palette.ink40)
                }
                Spacer()
                if on {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                }
            }
            .padding(14)
            .background(on ? Palette.accentSoft : Palette.field,
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(on ? Color.clear : Palette.ink12, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview { AppearanceSheet(onDone: {}) }
#endif
```

- [ ] **Step 2: Add the Theme row to Settings**

In `plop/plop/Views/Settings/SettingsView.swift`, add to the stored properties
(after line `@Query(sort: \ExpenseCategory.name) private var categories...`):

```swift
    @AppStorage(themeModeKey) private var themeModeRaw = ThemeMode.automatic.rawValue
    @State private var showingAppearance = false
```

Add the Theme row inside `Section("Preferences")`, after the Currency
`NavigationLink` (the closing `}` of that link), so it's the last row:

```swift
                    Button {
                        showingAppearance = true
                    } label: {
                        HStack {
                            Label("Theme", systemImage: "circle.lefthalf.filled")
                            Spacer()
                            Text((ThemeMode(rawValue: themeModeRaw) ?? .automatic).title)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.forward")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
```

Attach the sheet to the `List` — add this modifier right after
`.background(Palette.bg)` (still inside the `NavigationStack`):

```swift
            .sheet(isPresented: $showingAppearance) {
                AppearanceSheet { showingAppearance = false }
            }
```

- [ ] **Step 3: Verify the target builds**

Run the `xcodebuild build` command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add plop/plop/Views/Settings/AppearanceSheet.swift plop/plop/Views/Settings/SettingsView.swift
git commit -m "Add Appearance sheet and Settings theme row

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Verify and open PR

**Files:** none (verification + PR).

- [ ] **Step 1: Run the full test suite**

```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO
```
Expected: `** TEST SUCCEEDED **` — all prior tests plus `ThemeModeTests`.

- [ ] **Step 2: Lint**

```bash
swiftlint lint
```
Expected: no new violations from the added/changed files (`line_length` ≤ 120).

- [ ] **Step 3: Simulator smoke check (manual)**

Run the app → Settings → Theme:
- Sheet rises from the bottom titled **Appearance** with three cards; the active
  one is filled and checked.
- Tap **Dark** → the app behind the sheet repaints to dark immediately.
- Tap **Light** → repaints light. Tap **Automatic** → matches the simulator's
  Appearance setting (flip Settings → Developer → Dark Appearance, or the
  Environment Overrides toolbar, to confirm it follows).
- **Done** dismisses; the Settings row shows the chosen mode.
- Relaunch → choice persists.
- Spot-check Home, Insights (both modes), and Entry in dark for legibility
  (accents/pastel tiles unchanged; text/bg/cards adapt).

- [ ] **Step 4: Push and open the PR**

```bash
git push -u origin feature/theme
```

`gh` is not installed — open the PR via the printed GitHub web URL. Use the
project PR-description format:

```markdown
## Summary
Add a Light / Dark / Automatic appearance setting: an Appearance bottom sheet from
Settings, adaptive Palette tokens (dark values from the handoff), and
.preferredColorScheme applied at the root. No per-view changes.

## Testing
All unit tests pass (3 new in ThemeModeTests); SwiftLint clean. Sim-verified:
light/dark/automatic, live repaint, persistence.
```

---

## Self-review notes

- **Spec coverage:** adaptive Palette + `Color.dynamic` (Task 2); dark token values
  incl. `incomeGreen` (Task 2); `ThemeMode` + `colorScheme` + `@AppStorage` (Task 1);
  root `.preferredColorScheme`, default Automatic (Task 2); Appearance bottom sheet
  with cards/checkmark/Done + live apply (Task 3); Settings Theme row with current
  mode (Task 3); unit-tested enum logic (Task 1). Out-of-scope items absent.
- **Type consistency:** `themeModeKey` and `ThemeMode(rawValue:)` used identically in
  `ContentView`, `AppearanceSheet`, `SettingsView`, and tests; `Color.dynamic(_:_:)`
  signature matches every `Palette` call; `ThemeMode.{title,subtitle,symbol,colorScheme}`
  match their uses.
- **No placeholders:** every code step is complete and runnable.
- **Note:** brand accents (`accent`, `accentSoft`, `cream`, `yellow`, `tileInk`) stay
  fixed — intentionally not wrapped in `Color.dynamic`.
