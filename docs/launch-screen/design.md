# Launch Screen (PR2) — Design

Status: Approved (brainstorm complete) · Date: 2026-06-22

Companion to `requirements.md`. The static OS launch (Info.plist + color asset), the animated
`SplashView` (coin, ripples, wordmark, dots), the `ContentView` host, testing, scope.

## Architecture

```
plop/plop/Assets.xcassets/LaunchBackground.colorset/   (new — solid sky color)
plop/plop/Info.plist                                   (add UILaunchScreen dict)
plop/plop/Views/Shell/SplashView.swift                 (new — animated splash)
plop/plop/ContentView.swift                            (host the splash over RootView)
```

All splash code is presentation; no logic/tests. The coin/ripple/wordmark numbers are tuned
in the simulator against the HTML.

## 1. Static OS launch screen

New color asset `LaunchBackground.colorset/Contents.json` (sky, ≈ `#7EB7E8`):
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
Add to `plop/plop/Info.plist` (inside the top-level `<dict>`):
```xml
  <key>UILaunchScreen</key>
  <dict>
    <key>UIColorName</key>
    <string>LaunchBackground</string>
  </dict>
```
This is the instant pre-load frame (solid sky); `SplashView` draws its gradient over it
immediately, so the transition is seamless.

## 2. SplashView

```swift
import SwiftUI

/// Animated cold-start splash (replicates the handoff Launch Screen): a coin drops into
/// water with ripples, then the wordmark + tagline + dots. Calls `onFinish` to dismiss.
struct SplashView: View {
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dropped = false     // coin landed
    @State private var revealed = false    // wordmark / tagline / dots in
    @State private var rippling = false    // ripple rings active

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
        .offset(y: 30)   // surface just under the coin's rest
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
                    .opacity(revealed ? 1 : 0)
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

/// The smiling coin — SwiftUI port of the handoff `Coin` (viewBox 100, scaled to the frame).
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
```
Notes: the eye spacing/size, smile curve, ripple offsets, drop spring, and the 2.2s/1.0s
timings are confirmed in the simulator against the HTML. Reduce Motion skips the drop, ripple,
and dot/bob animations.

## 3. Host in ContentView

```swift
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(themeModeKey) private var themeModeRaw = ThemeMode.automatic.rawValue
    @State private var showSplash = true

    var body: some View {
        ZStack {
            RootView()
                .preferredColorScheme((ThemeMode(rawValue: themeModeRaw) ?? .automatic).colorScheme)
                .task { DefaultData.seedIfNeeded(in: modelContext) }

            if showSplash {
                SplashView { withAnimation(.easeOut(duration: 0.35)) { showSplash = false } }
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
}
```
The splash ignores the app theme (it's always the sky brand look) — fine, it's transient and
removed before the user interacts. (`SplashView` does not apply `preferredColorScheme`.)

## Testing

No unit tests (presentation/animation). Simulator + preview, light + dark:
- cold launch shows the sky launch frame → coin drops with ripples → wordmark + tagline + dots
  → crossfade to Home (~2.2s), no white flash;
- **Reduce Motion**: resting coin + wordmark + tagline, no motion, ~1s, then fade;
- the splash matches the HTML reasonably (coin, ripples, wordmark with cream "o", tagline,
  dots); tune the noted constants if off.

## Scope

`LaunchBackground` color + `UILaunchScreen` in Info.plist + `SplashView.swift` + the
`ContentView` host. One PR on `feature/launch-screen`.
