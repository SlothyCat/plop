# Tab Bar Fidelity (Cleanup D) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Match the handoff tab bar — brighter blurred material, flush bottom layout (no floating gap), aligned glyphs, and a faithful center-button halo pulse on Home. Visual only.

**Architecture:** All in `TabBarView.swift` + a one-line `RootView` change. No behavior change.

**Tech Stack:** SwiftUI (KeyframeAnimator, materials). iOS 18. No tests added (view — preview + simulator).

Single PR on branch `feature/tab-bar` (off `main`; spec committed there).

---

## File structure

- **Modify** `plop/plop/Views/Shell/TabBarView.swift` — material, layout, glyphs, halo.
- **Modify** `plop/plop/Views/Shell/RootView.swift` — drop `.ignoresSafeArea(edges:.bottom)` on the bar.

### Current code (for reference)

`RootView` overlays the bar in a `ZStack(alignment: .bottom)`:
```swift
TabBarView(selection: $selection, onCenterTap: handleCenterTap)
    .ignoresSafeArea(edges: .bottom)
```
`TabBarView` today: `ZStack { HStack{insights,Spacer,settings}.padding(.horizontal,44).frame(maxHeight:.infinity,alignment:.top).padding(.top,14).background(.ultraThinMaterial).overlay(hair top); centerButton.offset(y:-18) }.frame(height: 92)`. Glyphs `chart.bar` / `gearshape`; `centerButton` = `plus`/`house.fill` accent squircle.

### The handoff halo (must match — `Expense Tracker.html` `addhalo`)
```
0%   spread 0,   rgba(140,192,235,0.5)   (= Palette.accent @ 0.5)
70%  spread 16px, opacity 0              (expand + fade)
100% spread 0,   opacity 0              (hold invisible → the gap)
2.8s ease-out infinite
```
Replicated as a filled accent squircle behind the (opaque) center button — only the
part beyond the button shows, i.e. an expanding ring — scaling `1.0 → 1.5` (≈ +16pt on
a 64pt tile) while opacity `0.5 → 0` over the first ~70% of 2.8s, then held invisible.

### Build / lint commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | tail -5

swiftlint lint
```

> SourceKit false positives expected. Lines ≤ 120. No `// swiftlint:disable`.

---

## Task 1: Restyle TabBarView (material, layout, glyphs, halo)

**Files:**
- Modify: `plop/plop/Views/Shell/TabBarView.swift`

- [ ] **Step 1: Replace the file**

Replace the entire contents of `plop/plop/Views/Shell/TabBarView.swift` with:

```swift
import SwiftUI

/// Custom bottom tab bar: Insights (left) · raised center button · Settings (right).
/// The center button is context-aware — "+" on Home (add), "house" elsewhere (return
/// home) — and radiates a soft halo on Home (the handoff `addhalo` pulse).
struct TabBarView: View {
    @Binding var selection: RootView.Tab
    var onCenterTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

            center
        }
        .frame(height: 60)
        .background(
            Rectangle()
                .fill(.regularMaterial)
                .overlay(Rectangle().fill(Palette.hair).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ tab: RootView.Tab, systemImage: String, label: String) -> some View {
        let on = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: on ? .semibold : .regular))
                Text(label)
                    .font(.system(size: 10.5, weight: on ? .semibold : .medium))
            }
            .foregroundStyle(on ? Palette.ink : Palette.ink40)
        }
    }

    // MARK: center button + halo

    private struct Halo: Equatable {
        var scale = 1.0
        var opacity = 0.5
    }

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
                            CubicKeyframe(1.5, duration: 2.8 * 0.69)
                            LinearKeyframe(1.5, duration: 2.8 * 0.30)
                        }
                        KeyframeTrack(\.opacity) {
                            LinearKeyframe(0.5, duration: 0.01)
                            CubicKeyframe(0.0, duration: 2.8 * 0.69)
                            LinearKeyframe(0.0, duration: 2.8 * 0.30)
                        }
                    }
                    .offset(y: -18)
                    .allowsHitTesting(false)
            }
            centerButton.offset(y: -18)
        }
    }

    private var centerButton: some View {
        Button(action: onCenterTap) {
            Image(systemName: selection == .home ? "plus" : "house.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Palette.tileInk)
                .frame(width: 64, height: 64)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
                .shadow(color: Palette.accent.opacity(0.5), radius: 10, y: 3)
        }
        .accessibilityIdentifier("centerButton")
    }
}
```

Notes:
- `.regularMaterial` replaces `.ultraThinMaterial`; the material background
  `.ignoresSafeArea(edges:.bottom)` bleeds under the home indicator while the bar
  content (60pt) respects the safe area (set in Task 2 via the RootView change).
- Halo matches `addhalo` (scale 1→1.5 ≈ +16pt, opacity 0.5→0 over ~70%, then held);
  Home-only, Reduce-Motion-aware, `allowsHitTesting(false)` so taps pass through.
- `centerButton` (action/fill/shadow/a11y id) is unchanged.

- [ ] **Step 2: Build** — `xcodebuild build …` → `** BUILD SUCCEEDED **`. If
  `keyframeAnimator`'s `repeating:` label errors on this SDK, the correct signature is
  `.keyframeAnimator(initialValue:repeating:content:keyframes:)` (iOS 17+); adjust only
  if the compiler disagrees (no disable comments).

- [ ] **Step 3: Lint** — no new violations; config untouched.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Shell/TabBarView.swift
git commit -m "Restyle tab bar: brighter material, glyphs, and center-button halo

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: RootView safe-area fix

**Files:**
- Modify: `plop/plop/Views/Shell/RootView.swift`

- [ ] **Step 1: Drop `.ignoresSafeArea` on the bar**

READ `RootView.swift`. Find the `TabBarView(...)` in the `ZStack(alignment: .bottom)`
and remove its `.ignoresSafeArea(edges: .bottom)` modifier so the bar respects the
safe area (its material background still bleeds to the bottom edge, from Task 1):

```swift
            TabBarView(selection: $selection, onCenterTap: handleCenterTap)
```

Change nothing else.

- [ ] **Step 2: Build** — `xcodebuild build …` → `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Shell/RootView.swift
git commit -m "Let the tab bar respect the bottom safe area (fix floating gap)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite** (nothing should break)

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` (same count, ~166).

- [ ] **Step 2: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 3: Simulator smoke check (manual — owner)**

Against `home.jpg` / `settings.jpg` / the `.mov`:
- Bar material is bright (not gray), light + dark.
- Content sits just above the home indicator — **no empty gap**; material reaches the
  bottom edge.
- Insights/Settings glyphs + active state look right; center "+" / house unchanged.
- On **Home**, the "+" radiates a halo every ~2.8s with a quiet gap (matches the
  `.mov`); switch to Insights/Settings → **no halo**; enable Reduce Motion → no halo;
  taps still work on every control.

- [ ] **Step 4: Push + PR**

```bash
git push -u origin feature/tab-bar
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Tab bar fidelity (cleanup D): brighter .regularMaterial bar flush to the bottom
(fixes the floating gap), aligned glyphs, and a Reduce-Motion-aware center-button halo
pulse on Home matching the handoff `addhalo`. Visual only.

## Testing
All unit tests pass (no new — visual change); SwiftLint clean. Sim-verified against the
handoff screenshots + the blink .mov (material, flush layout, halo).
```

---

## Self-review notes

- **Spec coverage:** material `.regularMaterial` (Task 1); safe-area flush layout via
  the background-bleed + RootView change (Tasks 1–2); glyphs (Task 1); halo matching
  `addhalo` keyframes, Home-only + Reduce-Motion-aware + non-interactive (Task 1).
- **Behavior preserved:** tab selection, `onCenterTap`, the center add/return-home
  action, and the `centerButton` a11y id are unchanged.
- **Halo fidelity:** scale 1→1.5 (≈ the 16px spread on a 64pt tile), opacity 0.5→0 over
  ~70% then held to 100% (the gap), 2.8s loop — a faithful port of the CSS keyframes.
- **No placeholders / no disables / config untouched.**
- **Sim-tuning flagged:** exact bar height/paddings and halo feel are confirmed in the
  simulator (the parts not verifiable without a live render).
