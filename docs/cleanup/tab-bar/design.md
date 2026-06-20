# Tab Bar Fidelity (Cleanup D) — Design

Status: Approved (brainstorm complete) · Date: 2026-06-20

Companion to `requirements.md`. The material, the safe-area layout fix, glyphs, the
center-button halo, testing, and scope. All in `TabBarView.swift` + a one-line
`RootView` change. Visual only.

## Architecture

```
plop/Views/Shell/
  TabBarView.swift   (material, layout, glyphs, halo)
  RootView.swift     (drop .ignoresSafeArea on the bar so it respects the safe area)
```

## 1. Material + 2. Safe-area layout

Today the bar is `.frame(height: 92)` + `.ignoresSafeArea(edges:.bottom)` in RootView →
the inset stacks as empty height (the floating gap). Fix: let the **bar respect the
safe area** (content sits just above the home indicator) while only the **material
background bleeds to the bottom edge**.

`RootView` — drop the ignoresSafeArea on the bar:
```swift
// before: TabBarView(selection: $selection, onCenterTap: handleCenterTap)
//             .ignoresSafeArea(edges: .bottom)
TabBarView(selection: $selection, onCenterTap: handleCenterTap)
```

`TabBarView` — content at a fixed height, material extended behind the indicator:
```swift
var body: some View {
    ZStack {
        HStack {
            tabButton(.insights, systemImage: "chart.bar.fill", label: "Insights")
            Spacer()
            tabButton(.settings, systemImage: "gearshape.fill", label: "Settings")
        }
        .padding(.horizontal, 44)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

        center   // halo + button, raised
    }
    .frame(height: 60)
    .background(
        Rectangle()
            .fill(.regularMaterial)
            .overlay(Rectangle().fill(Palette.hair).frame(height: 1), alignment: .top)
            .ignoresSafeArea(edges: .bottom)   // material bleeds under the home indicator
    )
}
```
- `.regularMaterial` → bright near-white (light) / dark translucent (dark), adapting —
  replaces the gray `.ultraThinMaterial`.
- The bar's content is 60pt and, because the view (not its background) respects the
  safe area, sits just above the indicator — no empty band.
- Exact `height`/paddings are tuned in the simulator against `home.jpg`.

## 3. Glyphs

Insights → `chart.bar.fill`, Settings → `gearshape.fill`; the active tab keeps its
heavier weight + `Palette.ink` (inactive `Palette.ink40`). Center button unchanged
(`plus` on Home, `house.fill` elsewhere).

## 4. Center-button halo

A soft accent ring behind the center button, **only on Home** and **only when Reduce
Motion is off**, pulsing per the handoff `addhalo` (expand + fade over 70% of 2.8s,
then hold invisible to 100% → the "occasional" gap).

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

private struct Halo: Equatable { var scale = 1.0; var opacity = 0.5 }

private var center: some View {
    ZStack {
        if selection == .home && !reduceMotion {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .fill(Palette.accent)
                .frame(width: 64, height: 64)
                .keyframeAnimator(initialValue: Halo(), repeating: true) { view, value in
                    view.scaleEffect(value.scale).opacity(value.opacity)
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        LinearKeyframe(1.0, duration: 0.01)
                        CubicKeyframe(1.5, duration: 2.8 * 0.69)   // 0→70%: expand ~16pt
                        LinearKeyframe(1.5, duration: 2.8 * 0.30)  // hold invisible
                    }
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(0.5, duration: 0.01)
                        CubicKeyframe(0.0, duration: 2.8 * 0.69)   // fade out
                        LinearKeyframe(0.0, duration: 2.8 * 0.30)
                    }
                }
                .offset(y: -18)
                .allowsHitTesting(false)
        }
        centerButton.offset(y: -18)
    }
}
```
- `scaleEffect 1.0 → 1.5` on a 64pt squircle ≈ +16pt all around, matching the
  `0 0 0 16px` spread; opacity `0.5 → 0` matches the fade.
- `repeating: true` loops; the trailing hold keyframes create the quiet gap.
- `allowsHitTesting(false)` so the halo never intercepts taps.
- Behind `centerButton` in the ZStack (button stays on top).

(`centerButton` keeps its existing fill/shadow/accessibility id and `onCenterTap`.)

## Testing

Pure view — `#Preview` + simulator (no unit tests). Verify against the references:
- bar material is bright (not gray), light + dark;
- content sits just above the home indicator with **no empty gap**;
- Insights/Settings glyphs + active state;
- center "+" on Home pulses a halo (~2.8s, with a gap), no halo on other tabs, none
  under Reduce Motion; taps still work;
- routing/center behavior unchanged.

## Scope

Visual only; `TabBarView` + the one RootView line. No behavior change. One PR.
