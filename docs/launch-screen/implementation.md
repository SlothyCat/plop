# Launch Screen (PR2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A cold-start launch experience matching the handoff — a static sky launch frame plus an animated SwiftUI splash (coin drop + ripples + wordmark + dots) that crossfades to Home.

**Architecture:** A `LaunchBackground` color + `UILaunchScreen` give the instant static frame; `SplashView` (SwiftUI shapes + animation) replicates the HTML and calls `onFinish`; `ContentView` overlays it over `RootView` and crossfades it away.

**Tech Stack:** SwiftUI (shapes, animation, `.task`), asset catalog, Info.plist. iOS 18. Presentation/animation only — no tests.

Single PR on branch `feature/launch-screen` (off `main`; spec committed there).

---

## File structure

- **Create** `plop/plop/Assets.xcassets/LaunchBackground.colorset/Contents.json` — sky color.
- **Modify** `plop/plop/Info.plist` — add the `UILaunchScreen` dict.
- **Create** `plop/plop/Views/Shell/SplashView.swift` — the animated splash (+ private `Coin`/`Smile`).
- **Modify** `plop/plop/ContentView.swift` — overlay the splash over `RootView`.

### Build / lint commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | tail -5

swiftlint lint
```

> SourceKit "Cannot find X" diagnostics are FALSE positives — `xcodebuild` is the source of
> truth. Lines ≤ 120. No `// swiftlint:disable`. Keep the lint baseline (19 violations, 0
> serious); do not edit `.swiftlint.yml`. `Color(hex:)` exists (`Theme/Color+Hex.swift`).

---

## Task 1: Static OS launch screen (color + Info.plist)

**Files:**
- Create: `plop/plop/Assets.xcassets/LaunchBackground.colorset/Contents.json`
- Modify: `plop/plop/Info.plist`

- [ ] **Step 1: Add the color asset**

Create `plop/plop/Assets.xcassets/LaunchBackground.colorset/Contents.json` with:
```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : { "red" : "0.494", "green" : "0.718", "blue" : "0.910", "alpha" : "1.000" }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

- [ ] **Step 2: Add `UILaunchScreen` to Info.plist**

In `plop/plop/Info.plist`, add this key/value inside the top-level `<dict>` (e.g. right after
the opening `<dict>`), leaving the existing `GoogleOAuthClientID` / `CFBundleURLTypes` keys:
```xml
  <key>UILaunchScreen</key>
  <dict>
    <key>UIColorName</key>
    <string>LaunchBackground</string>
  </dict>
```

- [ ] **Step 3: Build** — run the build command → `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Assets.xcassets/LaunchBackground.colorset plop/plop/Info.plist
git commit -m "Add a sky launch-screen background (static OS launch)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: SplashView

**Files:**
- Create: `plop/plop/Views/Shell/SplashView.swift`

- [ ] **Step 1: Create the file**

Create `plop/plop/Views/Shell/SplashView.swift` with:
```swift
import SwiftUI

/// Animated cold-start splash (replicates the handoff Launch Screen): a coin drops into
/// water with ripples, then the wordmark + tagline + dots. Calls `onFinish` to dismiss.
struct SplashView: View {
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dropped = false
    @State private var revealed = false
    @State private var rippling = false

    private let sky = LinearGradient(colors: [Color(hex: "#A8D3F2"), Color(hex: "#7EB7E8")],
                                     startPoint: .top, endPoint: .bottom)

    var body: some View {
        ZStack {
            sky.ignoresSafeArea()
            RadialGradient(colors: [.white.opacity(0.45), .clear], center: .top,
                           startRadius: 0, endRadius: 320)
                .ignoresSafeArea().allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer().frame(height: 120)
                ZStack {
                    ripples
                    Coin()
                        .frame(width: 96, height: 96)
                        .offset(y: dropped ? 0 : -190)
                        .scaleEffect(dropped ? 1 : 0.82)
                        .opacity(dropped ? 1 : 0)
                        .shadow(color: Color(hex: "#285078").opacity(0.28), radius: 14, y: 10)
                }
                .frame(height: 240)

                wordmark.padding(.top, 28)
                Text("Designed for Simplicity")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.top, 14)
                    .opacity(revealed ? 1 : 0).offset(y: revealed ? 0 : 14)

                Spacer()
                dots.padding(.bottom, 64)
            }
        }
        .task { await start() }
    }

    private var wordmark: some View {
        HStack(spacing: 0) {
            Text("pl"); Text("o").foregroundStyle(Color(hex: "#FFE7BC")); Text("p")
        }
        .font(.system(size: 72, weight: .heavy, design: .rounded))
        .foregroundStyle(.white)
        .shadow(color: Color(hex: "#285078").opacity(0.22), radius: 8, y: 3)
        .opacity(revealed ? 1 : 0).offset(y: revealed ? 0 : 16)
    }

    private var ripples: some View {
        ZStack {
            ripple(width: 240, peak: 0.5)
            ripple(width: 184, peak: 0.65)
            ripple(width: 124, peak: 0.85)
        }
        .offset(y: 30)
    }

    private func ripple(width: CGFloat, peak: Double) -> some View {
        Ellipse()
            .stroke(.white, lineWidth: 2.5)
            .frame(width: width, height: width * 0.34)
            .scaleEffect(rippling ? 1 : 0.4)
            .opacity(rippling ? 0 : peak)
            .animation(rippling ? .easeOut(duration: 2.4).repeatForever(autoreverses: false)
                                : nil, value: rippling)
    }

    private var dots: some View {
        HStack(spacing: 9) {
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(.white).frame(width: 8, height: 8)
                    .scaleEffect(revealed ? 1 : 0.8)
                    .animation(revealed && !reduceMotion
                               ? .easeInOut(duration: 0.7).repeatForever().delay(Double(i) * 0.22)
                               : nil, value: revealed)
            }
        }
        .opacity(revealed ? 1 : 0)
    }

    private func start() async {
        if reduceMotion {
            dropped = true; revealed = true
            try? await Task.sleep(for: .seconds(1.0))
            onFinish(); return
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) { dropped = true }
        withAnimation(.easeOut(duration: 0.45).delay(0.5)) { rippling = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.9)) { revealed = true }
        try? await Task.sleep(for: .seconds(2.2))
        onFinish()
    }
}

/// The smiling coin — SwiftUI port of the handoff `Coin` (scaled to the frame).
private struct Coin: View {
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(
                colors: [Color(hex: "#FFF3D6"), Color(hex: "#FFE7BC")],
                center: UnitPoint(x: 0.4, y: 0.34), startRadius: 2, endRadius: 92))
            Circle().strokeBorder(Color(hex: "#F4D49A"), lineWidth: 3)
            Circle().inset(by: 8.5).strokeBorder(Color(hex: "#FFF3D6"), lineWidth: 3.2)
            HStack(spacing: 19) {
                Circle().fill(Color(hex: "#5A4632")).frame(width: 8, height: 8)
                Circle().fill(Color(hex: "#5A4632")).frame(width: 8, height: 8)
            }
            .offset(y: -4)
            Smile()
                .stroke(Color(hex: "#5A4632"), style: StrokeStyle(lineWidth: 4.4, lineCap: .round))
                .frame(width: 22, height: 11)
                .offset(y: 13)
        }
    }
}

private struct Smile: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.midX, y: rect.maxY * 1.8))
        return p
    }
}

#if DEBUG
#Preview { SplashView(onFinish: {}) }
#endif
```

- [ ] **Step 2: Build** — run the build command → `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Shell/SplashView.swift
git commit -m "Add animated SplashView (coin drop, ripples, wordmark, dots)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Host the splash in ContentView

**Files:**
- Modify: `plop/plop/ContentView.swift`

- [ ] **Step 1: Overlay the splash over RootView**

Replace the `ContentView` struct body. Change:
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
to:
```swift
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(themeModeKey) private var themeModeRaw = ThemeMode.automatic.rawValue
    @State private var showSplash = true

    var body: some View {
        ZStack {
            RootView()
                .preferredColorScheme((ThemeMode(rawValue: themeModeRaw) ?? .automatic).colorScheme)
                .task {
                    DefaultData.seedIfNeeded(in: modelContext)
                }

            if showSplash {
                SplashView { withAnimation(.easeOut(duration: 0.35)) { showSplash = false } }
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
}
```
(The `#Preview` at the bottom is unchanged.)

- [ ] **Step 2: Build** — run the build command → `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/ContentView.swift
git commit -m "Show the SplashView on cold start, crossfading to Home

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite** (presentation only — nothing should break)

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` (unchanged count).

- [ ] **Step 2: Lint** — `swiftlint lint` → baseline 19/0, no new violations.

- [ ] **Step 3: Simulator smoke check (manual — owner)**, light + dark:
- **Cold launch**: a **sky-blue** frame (no white flash) → the coin **drops** in with
  expanding **ripples** and settles → the **"plop"** wordmark (cream "o") + **tagline** +
  **dots** appear → **crossfade** to Home around ~2.2s.
- **Reduce Motion** on: the resting coin + wordmark + tagline show (no drop/ripple/pulse) for
  ~1s, then fade to Home.
- Compare to `design_handoff_plop/Launch Screen.html`. If the coin face/eyes/smile, ripple
  size/position, wordmark size, or the 2.2s/1.0s timing look off, tune the constants flagged
  in `SplashView` (and report so they can be adjusted).

- [ ] **Step 4: Push + PR**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git push -u origin feature/launch-screen
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Launch screen: a static sky OS launch frame (LaunchBackground + UILaunchScreen) plus an
animated SwiftUI SplashView (coin drop, ripples, "plop" wordmark, tagline, dots) shown on cold
start and crossfading to Home (~2.2s; Reduce Motion shows a static splash ~1s). Replicates the
handoff Launch Screen.

## Testing
All unit tests pass (no new — presentation); SwiftLint clean (19/0). Sim-verified: no white
flash, coin/ripples/wordmark/dots, crossfade to Home; Reduce Motion static; light + dark.
```

---

## Self-review notes

- **Spec coverage:** static launch color + `UILaunchScreen` (Task 1, #1); `SplashView` with
  coin/ripples/wordmark/tagline/dots + `onFinish` + Reduce Motion (Task 2, #2/#4);
  `ContentView` host + crossfade (Task 3, #3); verify incl. no-flash + Reduce Motion (Task 4).
  All spec items map to a task.
- **Type consistency:** `SplashView(onFinish:)` created in Task 2, used in Task 3; `Coin` /
  `Smile` are private to `SplashView.swift`; `Color(hex:)`, `themeModeKey`, `ThemeMode`,
  `DefaultData.seedIfNeeded`, `RootView` are existing.
- **Behaviour:** splash is cold-start only (one `@State showSplash`), removed via the
  `onFinish` crossfade; it doesn't apply `preferredColorScheme` (transient brand look). No
  data/logic change → no unit tests (presentation; project convention).
- **Sim-tunable:** coin eye/smile geometry, ripple sizes/offset, drop spring, 2.2s/1.0s
  timings — flagged in Task 4.
- **No placeholders / no disables / config untouched / lines ≤ 120.**
