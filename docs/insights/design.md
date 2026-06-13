# Insights — Design

Status: Approved (brainstorm complete) · Date: 2026-06-14

Companion to `requirements.md`. Covers architecture, the pure aggregation, the
hand-rolled donut + sequential animation, screen composition, testing, and slicing.

## Architecture (mirrors Home)

```
plop/
  Logic/
    SpendAggregation.swift     (pure, unit-tested)
  Views/Insights/
    InsightsContainer.swift    (@Query → InsightsView)
    InsightsView.swift         (header, toggle, donut, legend, empty state)
    DonutChart.swift           (hand-rolled trim arcs + sequential animation)
    SpendLegend.swift          (legend rows)
    InsightsPeriodToggle.swift (This Month / This Year)
```
`RootView` `.insights` case → `InsightsContainer()` (removes `InsightsStubView`).

## Pure aggregation (the tested core)

```swift
struct CategorySpend: Identifiable {
    let id: String        // category name, or "__uncategorized__"
    let name: String      // "Food" … or "Uncategorized"
    let colorHex: String  // category color, or neutral gray
    let amount: Decimal   // total expense magnitude in the period
}

/// Expenses only, within `range`, summed per category, largest first.
func spendByCategory(_ txs: [Transaction], in range: ClosedRange<Date>) -> [CategorySpend]

func totalSpent(_ spend: [CategorySpend]) -> Decimal

struct DonutSlice: Identifiable {
    let id: String
    let colorHex: String
    let start: Double     // fraction of the ring [0,1], with gaps applied
    let end: Double
}

/// Cumulative start/end fractions per slice, shrunk for inter-slice gaps.
func donutSlices(from spend: [CategorySpend], gap: Double = 0.012) -> [DonutSlice]
```
Pure (no SwiftUI / no `ModelContext`) → testable in isolation and reused by the views.

## Data flow

```
InsightsContainer: @Query all transactions
  → InsightsView(transactions:)
       period (@State: .month | .year, default .month)
       → spendByCategory(txs, in: period.range(containing: .now, calendar: .current))
       → totalSpent(...) ; donutSlices(...)
       → DonutChart(slices:) + SpendLegend(spend:, total:)
```
Changing period recomputes and replays the donut draw.

## Donut + sequential animation

`DonutChart` renders a faint full-ring **track** + one stroked arc per slice:
- `Circle().trim(from: slice.start, to: slice.end).stroke(color, StrokeStyle(lineWidth: 30,
  lineCap: .round)).rotationEffect(.degrees(-90))` → starts at 12 o'clock, sweeps clockwise.
- Center overlay: `SPENT` + total.

**Sequential draw** via per-slice staggered animations (animates while drawing, then rests):
- `@State animate`; reset to false then true on `.onAppear` and `.onChange(of: period)`.
- Track fades in `.easeIn(duration: 0.36)`.
- Slice *i*: `duration = fraction × 1.1s`, `delay = 0.36 + cumulativeBefore × 1.1s`;
  animates trim end collapsed→full and opacity 0→1 with `.linear(duration:).delay(delay)`.
  The delayed opacity keeps each arc hidden (no stray round-cap dot) until its turn.

Caveats (accepted): opacity ramps over each arc's own draw (vs. an instant snap);
fallback is a per-slice visibility flag only if it looks off. The animation is verified
in the simulator; the underlying **slice fractions are unit-tested** via `donutSlices`.

## Screen composition (`InsightsView`)

- Header: "Insights" title + `InsightsPeriodToggle` (This Month / This Year).
- Donut centered (`SPENT` + total in the center).
- Legend card: per slice — color dot, name, amount, **% of total** — largest first.
- **Empty** (`total == 0`): empty track + `SPENT $0.00` + "No spending this month/year."

## Testing

- **Unit (XCTest):** `spendByCategory` (expenses-only, grouping, uncategorized bucket,
  largest-first), `totalSpent`, `donutSlices` (fractions+gaps sum, single-slice, empty).
- **`#Preview` + simulator:** donut, legend, empty state, and the draw animation
  (screenshots mid-draw + final). No view unit tests (per CLAUDE.md).

## Implementation slicing (3 PRs)

| PR | Branch | Delivers | Tested |
|---|---|---|---|
| 1 | `feature/insights-logic` | `SpendAggregation` (`spendByCategory`, `totalSpent`, `donutSlices`) | Unit |
| 2 | `feature/insights-ui` | `InsightsContainer`/`View`, **static** donut + legend + period toggle + empty state + tab wiring | `#Preview` + sim |
| 3 | `feature/insights-animation` | sequential draw animation on the donut | sim |

Splitting static UI (PR2) from animation (PR3) isolates the risky motion work.

## References
- `design_handoff_plop/README.md` (Insights) · `design_handoff_plop/app/insights.jsx`
