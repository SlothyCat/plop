# PR3 — Insights Donut Animation Implementation Plan

> Execute inline (no worktrees). Steps use `- [ ]`. Branch off `main` after PR2 merges.

**Goal:** Add the signature sequential-draw animation to the donut: the track fades in, then arcs draw one-at-a-time at constant speed, replaying on tab entry and period change.

**Architecture:** A single-file change to `DonutChart`. An `animate` flag drives per-slice `trim` + opacity animations, each `.delay`ed so arcs fill in order. Reset (non-animated) then set on `.onAppear` and `.onChange(of: slices)`. Verified in the simulator (motion).

**Tech Stack:** SwiftUI. iOS 18.

---

## Conventions
- Branch `feature/insights-animation` off updated `main`. No worktrees.
- Commit present-tense + `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

## File Structure
- Modify `plop/plop/Views/Insights/DonutChart.swift` (only).

---

### Task 1: Sequential draw animation

**Files:** modify `plop/plop/Views/Insights/DonutChart.swift`.

- [ ] **Step 1: Branch**
```bash
git checkout main && git pull --ff-only && git checkout -b feature/insights-animation
```

- [ ] **Step 2: Replace `DonutChart` body with the animated version**

Replace the whole `struct DonutChart` (keep the `#Preview`) with:
```swift
struct DonutChart<Center: View>: View {
    let slices: [DonutSlice]
    @ViewBuilder var center: () -> Center

    @State private var animate = false

    private let size: CGFloat = 216
    private let lineWidth: CGFloat = 30
    private let fade = 0.36     // track fade-in
    private let sweep = 1.1     // total ring draw time

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.ink.opacity(0.06), lineWidth: lineWidth)
                .opacity(animate ? 1 : 0)
                .animation(.easeIn(duration: fade), value: animate)

            ForEach(slices) { slice in
                Circle()
                    .trim(from: slice.start, to: animate ? slice.end : slice.start)
                    .stroke(Color(hex: slice.colorHex),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .opacity(animate ? 1 : 0)
                    .animation(
                        .linear(duration: max(0.0001, (slice.end - slice.start) * sweep))
                            .delay(fade + slice.start * sweep),
                        value: animate
                    )
            }

            center()
        }
        .frame(width: size, height: size)
        .onAppear { replay() }
        .onChange(of: slices) { _, _ in replay() }
    }

    /// Reset to hidden WITHOUT animating the reverse, then draw forward.
    private func replay() {
        var reset = SwiftUI.Transaction()   // SwiftUI.Transaction, not our @Model Transaction
        reset.disablesAnimations = true
        withTransaction(reset) { animate = false }
        DispatchQueue.main.async { animate = true }
    }
}
```

Notes:
- Each arc's `delay = fade + slice.start × sweep` and `duration = (slice.end − slice.start) × sweep`,
  so arcs fill in order at constant angular speed.
- The delayed **opacity** keeps each arc hidden until its turn (avoids a stray round-cap dot).
- `replay()` resets non-animated (so it doesn't visibly "un-draw"), then animates forward;
  fires on appear (tab entry) and when `slices` change (period toggle).
- Use `SwiftUI.Transaction` explicitly — bare `Transaction` resolves to our `@Model`.

- [ ] **Step 3: Build**
```bash
xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Verify motion in the simulator**

Temporarily point the app at a seeded container and default to the Insights tab
(`plopApp.swift`: `.modelContainer(SampleData.previewContainer())`; `RootView`:
`selection = .insights`), build/install/launch, and observe the donut draw on entry.
Screenshot the final state; toggle This Month/This Year to confirm it replays. Then
**revert both temporary edits**.

- [ ] **Step 5: Full test + lint**
```bash
xcrun simctl shutdown all 2>/dev/null; sleep 2
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO
swiftlint lint
```
Expected: 41 tests pass; no lint errors.

- [ ] **Step 6: Commit, push, PR**
```bash
git add plop/plop/Views/Insights/DonutChart.swift
git commit -m "Add sequential draw animation to the Insights donut"
git push -u origin feature/insights-animation
```
Open PR `feature/insights-animation` → `main` via GitHub web; confirm CI green.

---

## Self-review notes
- **Spec coverage:** track fade → arcs draw one-at-a-time at constant speed, replay on
  entry + period change (Chunk B). Single-file change; no logic/test changes.
- **Caveat (accepted):** opacity ramps over each arc's own draw vs. an instant snap; fallback
  (per-slice visibility flag) only if it looks off in the sim.
- **No new unit tests:** motion is view-only (slice math already tested in PR1).
