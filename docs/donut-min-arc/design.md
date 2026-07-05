# Donut Minimum Arc (#3) — Design

Status: Approved (brainstorm complete) · Date: 2026-06-22

Companion to `requirements.md`. The `minArcAdjusted` helper, the two donut functions, the
tests, and scope.

## Architecture

```
plop/Logic/SpendAggregation.swift   (add minArcAdjusted; donutSlices gains minArc)
plop/Logic/BudgetProgress.swift     (budgetDonutSlices gains minArc)
plop/plopTests/SpendAggregationTests.swift   (minArcAdjusted + donutSlices min-arc)
plop/plopTests/BudgetProgressTests.swift     (budgetDonutSlices min-arc)
```

Only the slice math changes; `DonutChart`, legends, and captions are untouched.

## 1. `minArcAdjusted` (SpendAggregation.swift)

```swift
/// Raise each non-zero fraction below `minArc` up to `minArc`, shrinking the ≥ `minArc`
/// fractions proportionally to absorb the deficit so the set still sums to 1 (assuming the
/// input sums to 1). No-op when nothing is below `minArc`. If there isn't enough room to
/// steal the deficit (many tiny slices), falls back to an equal split among non-zero slices.
func minArcAdjusted(_ fractions: [Double], minArc: Double) -> [Double] {
    let deficit = fractions.filter { $0 > 0 && $0 < minArc }
                           .reduce(0.0) { $0 + (minArc - $1) }
    guard deficit > 0 else { return fractions }

    let bigSum = fractions.filter { $0 >= minArc }.reduce(0.0, +)
    guard bigSum > deficit else {
        let k = fractions.filter { $0 > 0 }.count
        let equal = k > 0 ? 1.0 / Double(k) : 0
        return fractions.map { $0 > 0 ? equal : 0 }
    }

    let factor = (bigSum - deficit) / bigSum
    return fractions.map { f in
        if f <= 0 { return 0 }
        return f < minArc ? minArc : f * factor
    }
}
```

## 2. `donutSlices` (Breakdown)

Add `minArc` and route fractions through `minArcAdjusted`. Current:
```swift
func donutSlices(from spend: [CategorySpend], gap: Double = 0.012) -> [DonutSlice] {
    let total = totalSpent(spend)
    guard total > 0 else { return [] }
    let totalDouble = NSDecimalNumber(decimal: total).doubleValue

    var cursor = 0.0
    var slices: [DonutSlice] = []
    for s in spend {
        let frac = NSDecimalNumber(decimal: s.amount).doubleValue / totalDouble
        let start = cursor + gap / 2
        let end = max(start, cursor + frac - gap / 2)
        slices.append(DonutSlice(id: s.id, colorHex: s.colorHex, start: start, end: end))
        cursor += frac
    }
    return slices
}
```
New:
```swift
func donutSlices(from spend: [CategorySpend], gap: Double = 0.012,
                 minArc: Double = 0.03) -> [DonutSlice] {
    let total = totalSpent(spend)
    guard total > 0 else { return [] }
    let totalDouble = NSDecimalNumber(decimal: total).doubleValue
    let drawn = minArcAdjusted(spend.map {
        NSDecimalNumber(decimal: $0.amount).doubleValue / totalDouble
    }, minArc: minArc)

    var cursor = 0.0
    var slices: [DonutSlice] = []
    for (i, s) in spend.enumerated() {
        let start = cursor + gap / 2
        let end = max(start, cursor + drawn[i] - gap / 2)
        slices.append(DonutSlice(id: s.id, colorHex: s.colorHex, start: start, end: end))
        cursor += drawn[i]
    }
    return slices
}
```
With the default `minArc`, balanced splits (75/25) have no sub-minimum slice → `deficit == 0`
→ `minArcAdjusted` returns the input unchanged → identical to today (existing tests pass).

## 3. `budgetDonutSlices` (Budget)

Add `minArc`; floor each non-zero spent row. Current:
```swift
func budgetDonutSlices(_ summary: BudgetSummary, gap: Double = 0.012) -> [DonutSlice] {
    let total = summary.totalBudget
    guard total > 0 else { return [] }
    let totalDouble = NSDecimalNumber(decimal: total).doubleValue

    var cursor = 0.0
    var slices: [DonutSlice] = []
    for row in summary.donutRows {
        let frac = NSDecimalNumber(decimal: row.spent).doubleValue / totalDouble
        let start = min(cursor + gap / 2, 1.0)
        let end = min(max(start, cursor + frac - gap / 2), 1.0)
        slices.append(DonutSlice(id: row.id, colorHex: row.colorHex, start: start, end: end))
        cursor += frac
    }
    return slices
}
```
New:
```swift
func budgetDonutSlices(_ summary: BudgetSummary, gap: Double = 0.012,
                       minArc: Double = 0.03) -> [DonutSlice] {
    let total = summary.totalBudget
    guard total > 0 else { return [] }
    let totalDouble = NSDecimalNumber(decimal: total).doubleValue

    var cursor = 0.0
    var slices: [DonutSlice] = []
    for row in summary.donutRows {
        let frac = NSDecimalNumber(decimal: row.spent).doubleValue / totalDouble
        let drawn = row.spent > 0 ? max(frac, minArc) : 0
        let start = min(cursor + gap / 2, 1.0)
        let end = min(max(start, cursor + drawn - gap / 2), 1.0)
        slices.append(DonutSlice(id: row.id, colorHex: row.colorHex, start: start, end: end))
        cursor += drawn
    }
    return slices
}
```
Rows already ≥ `minArc` are unchanged (existing tests: 0.3, 0.2/0.5 pass); over-budget still
clamps to 1.0; the partial under-budget ring is preserved (only tiny rows bump up).

## Testing

Add to `SpendAggregationTests` (the `donutSlices` section):
```swift
func test_minArcAdjusted_noOpWhenAllAboveMin() {
    XCTAssertEqual(minArcAdjusted([0.75, 0.25], minArc: 0.03), [0.75, 0.25])
}

func test_minArcAdjusted_bumpsTinyAndStealsFromLarge() {
    let out = minArcAdjusted([0.99, 0.01], minArc: 0.03)
    XCTAssertEqual(out[1], 0.03, accuracy: 0.0001)        // tiny bumped to minArc
    XCTAssertEqual(out[0], 0.97, accuracy: 0.0001)        // large shrunk by the deficit
    XCTAssertEqual(out.reduce(0, +), 1.0, accuracy: 0.0001)
}

func test_donutSlices_tinySliceStaysVisible() {
    let spend = [
        CategorySpend(id: "a", name: "A", colorHex: "#000000", amount: 99),
        CategorySpend(id: "b", name: "B", colorHex: "#111111", amount: 1),
    ]
    let slices = donutSlices(from: spend, gap: 0.0)
    XCTAssertGreaterThanOrEqual(slices[1].end - slices[1].start, 0.029)
}
```
Add to `BudgetProgressTests` (the `budgetDonutSlices` section), reusing `generalSummary`:
```swift
func test_donut_tinySpentRowStaysVisible() {
    // Under budget (ring not full) so the floored arc has room: 200/1000 + tiny.
    let s = generalSummary(spentAmounts: [("Big", 200), ("Tiny", 5)], total: 1000)
    let slices = budgetDonutSlices(s, gap: 0.0)
    XCTAssertGreaterThanOrEqual(slices[1].end - slices[1].start, 0.029)   // 5/1000 = 0.005 → 0.03
}
```

> Budget edge (acceptable): the floor is applied per-row then clamped to the remaining ring,
> so if spending already fills the ring (≈100% of budget) a trailing tiny row can still be
> squeezed to near-zero. That's the "everything maxed" case; the common under-budget case
> (and the Breakdown ring, which redistributes to 1) always show the sliver.
The existing donut tests (`singleSliceSpansRingMinusGap`, `cumulativeAndOrdered`,
`underBudget_fillsPartially`, `overBudget_clampsToFullRing`, `multipleSlicesAreCumulative`,
the empty cases) stay green with the default `minArc` (none have a sub-minimum slice).

Views are unchanged → preview/sim only confirms the Breakdown + Budget rings now show tiny
categories as slivers (light + dark).

## Scope

`minArcAdjusted` + `minArc` on the two donut functions + tests. One PR on
`feature/donut-min-arc`. No rendering/UI change.
