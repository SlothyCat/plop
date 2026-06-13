# PR2 — Home UI Implementation Plan

> Execute task-by-task in the current session (no worktrees). Steps use `- [ ]`.

**Goal:** Build the app's routing shell (custom tab bar + Home/Insights/Settings) and
the Home screen UI, rendering from injected data so it's preview-driven and ships no
filler. No persistence wiring yet (that's PR3).

**Architecture:** A `RootView` owns tab selection and overlays a custom `TabBarView`
with a raised center button (the design's signature "+"). `HomeView` is presentational
— it takes `[Transaction]` + a period binding as inputs. Previews feed sample data; the
real shell passes `[]` for now → empty state. Light theme only (dark deferred).

**Tech:** SwiftUI, SF Symbols, the committed `Logic/` layer for grouping/formatting.
Views validated via `#Preview` + simulator (no view unit tests, per CLAUDE.md). The one
unit-testable bit — hex→color parsing — gets a test.

**Branch:** `feature/home-ui` (off updated `main`).

## Design tokens (light theme, from the handoff)
`bg #DCEBF7` · `card #FFFFFF` · `field #FCFDFE` · `ink #2A2A2A` · `ink60 rgba(42,42,42,0.55)`
· `ink40 …0.38` · `ink12 …0.10` · `hair …0.08` · `accent #8CC0EB` · `accentSoft #BFDDF0`
· `cream #FFEBCC` · `yellow #FFF9D2` · `tileInk #2A2A2A` · income green `#1F8A5B`.

## Files
- Create `plop/plop/Theme/Color+Hex.swift` — `RGBA(hex:)` parser + `Color(hex:)`.
- Create `plop/plop/Theme/Palette.swift` — named light-theme colors.
- Create `plop/plop/Views/Shell/RootView.swift` — tab state + screen switch + tab bar overlay.
- Create `plop/plop/Views/Shell/TabBarView.swift` — bar (Insights · center · Settings) + `CenterButton`.
- Create `plop/plop/Views/Shell/InsightsStubView.swift`, `SettingsStubView.swift` — placeholders.
- Create `plop/plop/Views/Home/TxRow.swift`, `DayCard.swift`, `NetTotalHeader.swift`,
  `FilterMenu.swift`, `HomeView.swift`.
- Create `plop/plop/Previews/SampleData.swift` — `@MainActor` sample container + fixtures
  (used by previews only).
- Create `plop/plopTests/ColorHexTests.swift`.
- Modify `plop/plop/ContentView.swift` — render `RootView()` (keep the launch seeding `.task`).

## Tasks

### Task 1: Branch + color tokens (TDD the parser)
- [ ] `git checkout main && git pull --ff-only && git checkout -b feature/home-ui`
- [ ] Write `plop/plopTests/ColorHexTests.swift`:
```swift
import XCTest
@testable import plop

final class ColorHexTests: XCTestCase {
    func test_parsesSixDigitHex() {
        let c = RGBA(hex: "#8CC0EB")
        XCTAssertEqual(c.red,   0x8C / 255, accuracy: 0.001)
        XCTAssertEqual(c.green, 0xC0 / 255, accuracy: 0.001)
        XCTAssertEqual(c.blue,  0xEB / 255, accuracy: 0.001)
        XCTAssertEqual(c.alpha, 1.0, accuracy: 0.001)
    }
    func test_toleratesMissingHash() {
        XCTAssertEqual(RGBA(hex: "FFFFFF").red, 1.0, accuracy: 0.001)
    }
    func test_invalidHexFallsBackToBlack() {
        let c = RGBA(hex: "zzz")
        XCTAssertEqual(c.red + c.green + c.blue, 0, accuracy: 0.001)
    }
}
```
- [ ] Run that test class → fails (no `RGBA`).
- [ ] Implement `plop/plop/Theme/Color+Hex.swift`:
```swift
import SwiftUI

struct RGBA { let red, green, blue, alpha: Double }

extension RGBA {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else {
            self = RGBA(red: 0, green: 0, blue: 0, alpha: 1); return
        }
        self = RGBA(red: Double((v >> 16) & 0xFF) / 255,
                    green: Double((v >> 8) & 0xFF) / 255,
                    blue: Double(v & 0xFF) / 255, alpha: 1)
    }
}

extension Color {
    init(hex: String) {
        let c = RGBA(hex: hex)
        self = Color(.sRGB, red: c.red, green: c.green, blue: c.blue, opacity: c.alpha)
    }
}
```
- [ ] Run `ColorHexTests` → passes. Commit "Add hex color parsing".

### Task 2: Palette
- [ ] `plop/plop/Theme/Palette.swift` — an `enum Palette` of `static let` `Color`s for
  every token above (e.g. `static let accent = Color(hex: "#8CC0EB")`, `incomeGreen`, etc.).
- [ ] Build. Commit "Add light-theme color palette".

### Task 3: App shell (tab bar + stubs)
- [ ] `TabBarView.swift`: a translucent bar (`.ultraThinMaterial`, ~92pt, hairline top)
  with Insights (`chart.bar`) left and Settings (`gearshape`) right, and a **raised center
  button** (64pt, `Palette.accent`, corner radius ~23, shadow). Center glyph is context-aware:
  `plus` on Home, `house` elsewhere. Expose `selection: Binding<Tab>` and an `onCenterTap`.
- [ ] `InsightsStubView` / `SettingsStubView`: centered "Insights" / "Settings" + "Coming soon".
- [ ] `RootView.swift`: `enum Tab { home, insights, settings }`, `@State selection`,
  switches the active screen, overlays `TabBarView`. Center tap: if on Home → no-op for now
  (TODO: present Entry in PR4); else → `selection = .home`.
- [ ] Point `ContentView` body at `RootView()` (keep the seeding `.task`).
- [ ] Build + run simulator; confirm tabs switch and the bar/center button render. Commit
  "Add app shell with custom tab bar and tab stubs".

### Task 4: TxRow
- [ ] `TxRow.swift`: HStack — category color tile (46pt, radius 14, `Palette` color from
  `tx.category?.colorHex`, SF Symbol from `symbolName`; neutral tile + "Uncategorized" when
  nil) · name (+ small `arrow.triangle.2.circlepath` if `recurrence != .none`) · note-or-time
  secondary (use `Logic` formatting) · signed amount (`formattedMoney(signedAmount(tx),
  signed: true)`, income `Palette.incomeGreen`, else `Palette.ink`, `.monospacedDigit()`).
- [ ] `#Preview` with two sample rows (expense + income). Build. Commit "Add TxRow".

### Task 5: DayCard
- [ ] `DayCard.swift`: takes a `DayGroup`; header row = `dayLabel(...)` + day subtotal
  (`formattedMoney`); below, a white rounded card (radius 22, soft shadow) of `TxRow`s
  separated by thin hairlines inset to align past the tile. Days separated by spacing only
  (no rule between groups, per the chosen design).
- [ ] `#Preview` with a sample group. Build. Commit "Add DayCard".

### Task 6: NetTotalHeader
- [ ] `NetTotalHeader.swift`: "Net total" label + period pill (e.g. "this month") + large
  signed amount (symbol small/`ink40`, magnitude ~60pt `ink`, monospaced digits) from a
  passed-in `Decimal` net and `PeriodFilter`.
- [ ] `#Preview`. Build. Commit "Add NetTotalHeader".

### Task 7: FilterMenu
- [ ] `FilterMenu.swift`: a top-bar filter button (`line.3.horizontal.decrease`) opening a
  Week/Month/Year menu (use SwiftUI `Menu`), bound to `Binding<PeriodFilter>`, active row
  checked.
- [ ] `#Preview`. Build. Commit "Add period FilterMenu".

### Task 8: HomeView (assemble, from injected data)
- [ ] `HomeView.swift`: inputs `transactions: [Transaction]`. Local `@State period` (default
  `.month`). Computes via the `Logic` layer: filter to `period.range(...)`, `netTotal`,
  `groupByDay`. Layout: top bar with `FilterMenu` → `NetTotalHeader` → scrolling `DayCard`s,
  or centered "No transactions {period}." when empty.
- [ ] `Previews/SampleData.swift`: `@MainActor` in-memory container + a spread of sample
  transactions across week/month/year (mirroring the handoff's fixtures) for previews ONLY.
- [ ] Two `#Preview`s: populated (sample data) and empty (`[]`).
- [ ] Wire `RootView`'s Home tab to `HomeView(transactions: [])` for now (PR3 swaps in `@Query`).
- [ ] Build + run simulator: empty state shows in the app; populated state shows in preview.
  Commit "Add HomeView assembling header, filter, and day list".

### Task 9: Verify, lint, push, PR
- [ ] `xcodebuild test ... -only-testing:plopTests` (ColorHexTests + PR1 tests) → green.
- [ ] `swiftlint lint` → no new warnings in added files.
- [ ] Run the app in the simulator; screenshot Home (empty) for the PR.
- [ ] Push `feature/home-ui`; open PR via GitHub web (gh not installed). Confirm CI green.

## Notes
- Local xcodebuild uses `-destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'`
  (CI uses `OS=latest`); disable parallel testing locally to avoid the clone churn from PR1.
- Heed `memory/swiftdata-gotchas.md` if any model touches happen (they shouldn't here).
