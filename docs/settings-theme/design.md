# Theme — Design

Status: Approved (brainstorm complete) · Date: 2026-06-15

Companion to `requirements.md`. Architecture, the adaptive Palette, the mode
enum + root wiring, the Appearance sheet, testing, and slicing.

## Architecture

```
plop/
  Theme/
    Color+Hex.swift     (+ Color.dynamic(light:dark:) helper)
    Palette.swift       (scheme-dependent tokens become dynamic colors)
    ThemeMode.swift     (NEW: enum + colorScheme mapping + @AppStorage key)
  ContentView.swift     (+ .preferredColorScheme(themeMode.colorScheme))
  Views/Settings/
    AppearanceSheet.swift  (NEW: the bottom-sheet picker)
    SettingsView.swift     (+ Theme row that presents the sheet)
```

No per-view changes: every view already reads `Palette.*`, so making those tokens
adaptive is what turns on dark mode everywhere. One PR (`feature/theme`).

## Adaptive Palette

Add a helper in `Color+Hex.swift`:

```swift
extension Color {
    /// Resolves to `light` or `dark` per the active interface style; repaints on flip.
    static func dynamic(_ light: Color, _ dark: Color) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
    }
}
```

Token values (light → dark); brand accents stay fixed:

| token       | light                         | dark                          |
|-------------|-------------------------------|-------------------------------|
| bg          | #DCEBF7                       | #121922                       |
| card        | #FFFFFF                       | #1C2530                       |
| field       | #FCFDFE                       | #232E3A                       |
| ink         | #2A2A2A                       | #EAF1F7                       |
| ink60       | charcoal @0.55                | off-white(#EAF1F7) @0.62      |
| ink40       | charcoal @0.38                | off-white @0.40               |
| ink12       | charcoal @0.10                | off-white @0.14               |
| hair        | charcoal @0.08                | off-white @0.10               |
| incomeGreen | #1F8A5B                       | #4ECB8B                       |
| accent, accentSoft, cream, yellow, tileInk | **fixed both themes** | (unchanged) |

So e.g.:
```swift
static let bg = Color.dynamic(Color(hex: "#DCEBF7"), Color(hex: "#121922"))
static let ink60 = Color.dynamic(Color(.sRGB, white: 0x2A / 255, opacity: 0.55),
                                 Color(.sRGB, red: 234/255, green: 241/255, blue: 247/255,
                                       opacity: 0.62))
```

`tileInk` stays charcoal (glyphs on fixed pastel tiles must not flip).

## ThemeMode + root

`Theme/ThemeMode.swift`:

```swift
import SwiftUI

let themeModeKey = "themeMode"

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

`ContentView` applies it once for the whole window (covers sheets / full-screen
covers):

```swift
@AppStorage(themeModeKey) private var themeModeRaw = ThemeMode.automatic.rawValue
...
RootView()
    .preferredColorScheme((ThemeMode(rawValue: themeModeRaw) ?? .automatic).colorScheme)
```

Default is **Automatic** (follow system) for a new install.

## AppearanceSheet + Settings row

`AppearanceSheet.swift` — a bottom sheet matching the mockup:
- Title **Appearance**; subtitle "Choose how the app looks. Automatic follows your
  device's light or dark setting."
- A card per `ThemeMode.allCases`: an icon tile (`mode.symbol`), `title`,
  `subtitle`, and a trailing checkmark on the active one. The selected card is
  filled with `Palette.accentSoft`; others use `Palette.field` with a hairline border.
- Tapping a card writes `@AppStorage(themeModeKey)` → the app repaints live behind
  the sheet. A **Done** button dismisses.
- `.presentationDetents([.medium])`, `Palette.bg`/`card` background.

`SettingsView` gets a **Theme** row (icon `circle.lefthalf.filled`) in Preferences
showing the current `ThemeMode.title` as trailing text; tapping sets
`@State showingAppearance = true` to present the sheet.

## Testing

- `ThemeModeTests` (XCTest): raw values (`light`/`dark`/`automatic`); `colorScheme`
  mapping (`.light` → `.light`, `.dark` → `.dark`, `.automatic` → `nil`); `allCases`
  count is 3.
- `Palette`, `AppearanceSheet`, root wiring verified via `#Preview` (light + dark
  via `.preferredColorScheme`) + simulator. No view unit tests, per convention.

## Slicing

**One PR** (`feature/theme`): the `Color.dynamic` helper + adaptive `Palette`,
`ThemeMode` + `ContentView` wiring, `AppearanceSheet`, the Settings row, and
`ThemeModeTests`.
