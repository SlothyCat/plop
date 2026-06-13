# PR2 — Insights UI (static) Implementation Plan

> Execute inline (no worktrees). Steps use `- [ ]`. Branch off `main` AFTER PR1 merges.

**Goal:** Build the Insights screen — period toggle, **static** donut, legend, empty state — reading real data, wired into the Insights tab. No draw animation (that's PR3).

**Architecture:** `InsightsContainer` (@Query) → presentational `InsightsView`, mirroring Home. A generic `DonutChart` renders arcs via `Circle().trim` from PR1's `donutSlices`; `SpendLegend` lists the categories. Views validated via `#Preview` + simulator.

**Tech Stack:** SwiftUI, SwiftData (@Query), PR1's `SpendAggregation`. iOS 18, light theme.

---

## Conventions
- Branch `feature/insights-ui` off updated `main` (after PR1 merges). No worktrees.
- Commits present-tense + `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- Build/screenshot locally on iPhone 16 OS=18.4; stale-crash remedies in `memory/xcode-build-sim-gotchas.md`.

## File Structure
- Create `plop/plop/Views/Insights/InsightsPeriodToggle.swift`
- Create `plop/plop/Views/Insights/DonutChart.swift`
- Create `plop/plop/Views/Insights/SpendLegend.swift`
- Create `plop/plop/Views/Insights/InsightsView.swift`
- Create `plop/plop/Views/Insights/InsightsContainer.swift`
- Modify `plop/plop/Views/Shell/RootView.swift` — `.insights` → `InsightsContainer()`
- Delete `plop/plop/Views/Shell/InsightsStubView.swift`

---

### Task 1: Period toggle + static donut

**Files:** create `InsightsPeriodToggle.swift`, `DonutChart.swift`.

- [ ] **Step 1: `InsightsPeriodToggle.swift`**
```swift
import SwiftUI

/// This Month / This Year segmented control, bound to PeriodFilter (.month/.year).
struct InsightsPeriodToggle: View {
    @Binding var period: PeriodFilter

    var body: some View {
        HStack(spacing: 2) {
            segment(.month, "This Month")
            segment(.year, "This Year")
        }
        .padding(3)
        .background(Palette.ink.opacity(0.06), in: Capsule())
    }

    private func segment(_ value: PeriodFilter, _ label: String) -> some View {
        let on = period == value
        return Button { period = value } label: {
            Text(label)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(on ? Palette.ink : Palette.ink40)
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .background {
                    if on {
                        Capsule().fill(Palette.card)
                            .shadow(color: Palette.ink.opacity(0.12), radius: 3, y: 1)
                    }
                }
        }
    }
}
```

- [ ] **Step 2: `DonutChart.swift` (static — no animation yet)**
```swift
import SwiftUI

/// A static donut: faint track + one stroked arc per slice (PR1 donutSlices),
/// with a center view. The draw animation is added in PR3.
struct DonutChart<Center: View>: View {
    let slices: [DonutSlice]
    @ViewBuilder var center: () -> Center

    private let size: CGFloat = 216
    private let lineWidth: CGFloat = 30

    var body: some View {
        ZStack {
            Circle().stroke(Palette.ink.opacity(0.06), lineWidth: lineWidth)
            ForEach(slices) { slice in
                Circle()
                    .trim(from: slice.start, to: slice.end)
                    .stroke(Color(hex: slice.colorHex),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            center()
        }
        .frame(width: size, height: size)
    }
}

#if DEBUG
#Preview {
    let spend = spendByCategory(SampleData.transactions(),
                                in: PeriodFilter.month.range(containing: .now, calendar: .current))
    return DonutChart(slices: donutSlices(from: spend)) {
        Text("SPENT").font(.caption)
    }
    .padding()
}
#endif
```

- [ ] **Step 3: Build**
```bash
xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**
```bash
git add plop/plop/Views/Insights/InsightsPeriodToggle.swift plop/plop/Views/Insights/DonutChart.swift
git commit -m "Add Insights period toggle and static donut chart"
```

---

### Task 2: Legend + InsightsView (compose, with empty state)

**Files:** create `SpendLegend.swift`, `InsightsView.swift`.

- [ ] **Step 1: `SpendLegend.swift`**
```swift
import SwiftUI

/// Legend rows: color dot, name, amount, % of total — largest first.
struct SpendLegend: View {
    let spend: [CategorySpend]
    let total: Decimal

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(spend.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle().fill(Palette.hair).frame(height: 1).padding(.leading, 26)
                }
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: item.colorHex))
                        .frame(width: 14, height: 14)
                    Text(item.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(formattedMoney(item.amount))
                            .font(.system(size: 17, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(Palette.ink)
                        Text("\(percent(item.amount))%")
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.ink40)
                    }
                }
                .padding(.vertical, 15)
            }
        }
        .padding(.horizontal, 18)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Palette.ink.opacity(0.05), radius: 8, y: 4)
    }

    private func percent(_ amount: Decimal) -> Int {
        guard total > 0 else { return 0 }
        let frac = NSDecimalNumber(decimal: amount).doubleValue
            / NSDecimalNumber(decimal: total).doubleValue
        return Int((frac * 100).rounded())
    }
}
```

- [ ] **Step 2: `InsightsView.swift`**
```swift
import SwiftUI

/// Presentational Insights screen: header + period toggle, donut, legend, empty state.
struct InsightsView: View {
    let transactions: [Transaction]
    @State private var period: PeriodFilter = .month

    var body: some View {
        let range = period.range(containing: .now, calendar: .current)
        let spend = spendByCategory(transactions, in: range)
        let total = totalSpent(spend)
        let slices = donutSlices(from: spend)

        VStack(spacing: 0) {
            HStack {
                Text("Insights")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Spacer()
                InsightsPeriodToggle(period: $period)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)

            ScrollView {
                DonutChart(slices: slices) {
                    VStack(spacing: 3) {
                        Text("SPENT")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(0.5)
                            .foregroundStyle(Palette.ink40)
                        Text(formattedMoney(total))
                            .font(.system(size: 30, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(Palette.ink)
                    }
                }
                .padding(.vertical, 26)

                if spend.isEmpty {
                    Text("No spending \(period == .year ? "this year" : "this month").")
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.ink40)
                        .padding(.top, 30)
                } else {
                    SpendLegend(spend: spend, total: total)
                        .padding(.horizontal, 18)
                }
            }
            .padding(.bottom, 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.bg)
    }
}

#if DEBUG
#Preview("Populated") { InsightsView(transactions: SampleData.transactions()) }
#Preview("Empty") { InsightsView(transactions: []) }
#endif
```

- [ ] **Step 3: Build, then commit**
```bash
xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'
```
Expected: `** BUILD SUCCEEDED **`.
```bash
git add plop/plop/Views/Insights/SpendLegend.swift plop/plop/Views/Insights/InsightsView.swift
git commit -m "Add Insights legend and screen composition"
```

---

### Task 3: Container + tab wiring, verify, PR

**Files:** create `InsightsContainer.swift`; modify `RootView.swift`; delete `InsightsStubView.swift`.

- [ ] **Step 1: `InsightsContainer.swift`**
```swift
import SwiftUI
import SwiftData

/// Reads transactions from SwiftData and feeds the presentational InsightsView.
struct InsightsContainer: View {
    @Query private var transactions: [Transaction]

    var body: some View {
        InsightsView(transactions: transactions)
    }
}

#if DEBUG
#Preview {
    InsightsContainer().modelContainer(SampleData.previewContainer())
}
#endif
```

- [ ] **Step 2: Wire the tab + remove the stub**

In `plop/plop/Views/Shell/RootView.swift`, change the insights case:
```swift
                case .insights: InsightsContainer()
```
Then delete the stub:
```bash
git rm plop/plop/Views/Shell/InsightsStubView.swift
```

- [ ] **Step 3: Build + full test + lint**
```bash
xcrun simctl shutdown all 2>/dev/null; sleep 2
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO
swiftlint lint
```
Expected: 41 tests pass; no lint errors.

- [ ] **Step 4: Simulator screenshot (populated donut)**

Temporarily point the app at a seeded container to screenshot the Insights tab:
in `plopApp.swift`, swap `.modelContainer(sharedModelContainer)` →
`.modelContainer(SampleData.previewContainer())`, build/install/launch, tap **Insights**,
screenshot, then **revert** the swap. (Verifies the donut + legend render with real data;
the empty state shows in the normal run.)

- [ ] **Step 5: Commit, push, PR**
```bash
git add plop/plop/Views/Insights/InsightsContainer.swift plop/plop/Views/Shell/RootView.swift plop/plop/Views/Shell/InsightsStubView.swift
git commit -m "Wire Insights tab to the real screen"
git push -u origin feature/insights-ui
```
Open PR `feature/insights-ui` → `main` via GitHub web. Confirm CI green.

---

## Self-review notes
- **Spec coverage:** toggle (T1), static donut (T1), legend (T2), composition + empty state (T2),
  container + tab wiring + stub removal (T3). Animation intentionally excluded (PR3).
- **Reuses PR1:** `spendByCategory` / `totalSpent` / `donutSlices` drive the views.
- **No filler shipped:** `SampleData` (DEBUG) only feeds previews/screenshots; the app reads `@Query`.
- **Type consistency:** `DonutChart(slices:center:)`, `SpendLegend(spend:total:)`,
  `InsightsView(transactions:)`, `InsightsPeriodToggle(period:)` consistent throughout.
