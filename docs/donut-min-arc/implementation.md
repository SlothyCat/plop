# Donut Minimum Arc (#3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every non-zero donut slice a minimum visible arc so tiny categories don't vanish, in both the Breakdown and Budget rings.

**Architecture:** A tested `minArcAdjusted` helper + a `minArc` parameter on `donutSlices` (Breakdown, redistributes to 1) and `budgetDonutSlices` (Budget, per-row floor with the existing clamp). Pure-function change; rendering untouched.

**Tech Stack:** Swift, XCTest. iOS 18.

Single PR on branch `feature/donut-min-arc` (off `main`; spec committed there).

---

## File structure

- **Modify** `plop/plop/Logic/SpendAggregation.swift` — add `minArcAdjusted`; `donutSlices` gains `minArc`.
- **Modify** `plop/plopTests/SpendAggregationTests.swift` — helper + Breakdown min-arc tests.
- **Modify** `plop/plop/Logic/BudgetProgress.swift` — `budgetDonutSlices` gains `minArc`.
- **Modify** `plop/plopTests/BudgetProgressTests.swift` — Budget min-arc test.

### Build / test / lint commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests/SpendAggregationTests \
  -only-testing:plopTests/BudgetProgressTests -parallel-testing-enabled NO 2>&1 \
  | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2

swiftlint lint
```

> SourceKit "No such module 'XCTest'" / "Cannot find X" diagnostics are FALSE positives —
> `xcodebuild` is the source of truth. Lines ≤ 120. No `// swiftlint:disable`. Keep the lint
> baseline (19 violations, 0 serious); do not edit `.swiftlint.yml`.

---

## Task 1: Breakdown — `minArcAdjusted` + `donutSlices.minArc` (TDD)

**Files:**
- Modify: `plop/plopTests/SpendAggregationTests.swift`
- Modify: `plop/plop/Logic/SpendAggregation.swift`

- [ ] **Step 1: Add the failing tests**

In `SpendAggregationTests.swift`, inside the `// MARK: donutSlices` section (after
`test_donutSlices_cumulativeAndOrdered`), add:
```swift
    func test_minArcAdjusted_noOpWhenAllAboveMin() {
        XCTAssertEqual(minArcAdjusted([0.75, 0.25], minArc: 0.03), [0.75, 0.25])
    }

    func test_minArcAdjusted_bumpsTinyAndStealsFromLarge() {
        let out = minArcAdjusted([0.99, 0.01], minArc: 0.03)
        XCTAssertEqual(out[1], 0.03, accuracy: 0.0001)
        XCTAssertEqual(out[0], 0.97, accuracy: 0.0001)
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

- [ ] **Step 2: Run tests to verify they fail** — run the test command. Expected: compile
  error (`minArcAdjusted` not defined).

- [ ] **Step 3: Add `minArcAdjusted` and the `minArc` parameter**

In `SpendAggregation.swift`, add the helper (e.g. just above `func donutSlices`):
```swift
/// Raise each non-zero fraction below `minArc` up to `minArc`, shrinking the ≥ `minArc`
/// fractions proportionally to absorb the deficit so the set still sums to 1 (assuming the
/// input sums to 1). No-op when nothing is below `minArc`. Falls back to an equal split among
/// non-zero entries if there isn't enough room to steal the deficit.
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
Then change `donutSlices`:
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
to:
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

- [ ] **Step 4: Run tests to verify they pass** — run the test command → `** TEST
  SUCCEEDED **`. The existing `test_donutSlices_singleSliceSpansRingMinusGap` and
  `test_donutSlices_cumulativeAndOrdered` must still pass (no sub-minimum slice → `deficit`
  is 0 → unchanged).

- [ ] **Step 5: Lint + commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && swiftlint lint 2>&1 | tail -3
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Logic/SpendAggregation.swift plop/plopTests/SpendAggregationTests.swift
git commit -m "Give tiny breakdown donut slices a minimum visible arc

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Budget — `budgetDonutSlices.minArc` (TDD)

**Files:**
- Modify: `plop/plopTests/BudgetProgressTests.swift`
- Modify: `plop/plop/Logic/BudgetProgress.swift`

- [ ] **Step 1: Add the failing test**

In `BudgetProgressTests.swift`, in the `// MARK: budgetDonutSlices` section (after
`test_donut_multipleSlicesAreCumulative`), add — it reuses the existing private
`generalSummary` helper:
```swift
    func test_donut_tinySpentRowStaysVisible() {
        // Under budget (ring not full) so the floored arc has room: 200/1000 + tiny 5/1000.
        let s = generalSummary(spentAmounts: [("Big", 200), ("Tiny", 5)], total: 1000)
        let slices = budgetDonutSlices(s, gap: 0.0)
        XCTAssertGreaterThanOrEqual(slices[1].end - slices[1].start, 0.029)
    }
```

- [ ] **Step 2: Run tests to verify it fails** — run the test command. Expected: the new test
  FAILS (the 5/1000 = 0.005 arc is below 0.029; the others pass).

- [ ] **Step 3: Add the `minArc` parameter + per-row floor**

In `BudgetProgress.swift`, change `budgetDonutSlices`:
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
to:
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

- [ ] **Step 4: Run tests to verify they pass** — run the test command → `** TEST
  SUCCEEDED **`. The existing `test_donut_underBudget_fillsPartially` (0.3),
  `test_donut_overBudget_clampsToFullRing` (1.0), and `test_donut_multipleSlicesAreCumulative`
  (0.2 / 0.5) must still pass (all rows ≥ `minArc`, so `drawn == frac`).

- [ ] **Step 5: Lint + commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && swiftlint lint 2>&1 | tail -3
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Logic/BudgetProgress.swift plop/plopTests/BudgetProgressTests.swift
git commit -m "Floor tiny spent rows in the budget donut to a minimum arc

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` (4 new tests; existing donut tests unchanged).

- [ ] **Step 2: Lint** — `swiftlint lint` → baseline 19/0, no new violations.

- [ ] **Step 3: Simulator smoke check (manual — owner)**

In Insights (the screenshot scenario — one big category), light + dark:
- **Breakdown** "This Year": the 1% / ~0% categories now show a thin arc on the ring (no
  longer swallowed by the 99% slice); the dominant slice still dominates; legend %s unchanged.
- **Budget** mode (under budget): a category with tiny spend shows a sliver; under-budget
  partial ring and over-budget full ring still look right; center caption numbers unchanged.

- [ ] **Step 4: Push + PR**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git push -u origin feature/donut-min-arc
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Donut min-arc (#3): tiny non-zero categories now show a minimum visible arc instead of
vanishing when one category dominates. Breakdown redistributes to keep the ring summed to 1;
Budget floors each non-zero spent row (keeping under/over-budget semantics). Slice math only —
captions/legend numbers unchanged.

## Testing
All unit tests pass (4 new: minArcAdjusted no-op + bump, breakdown + budget tiny-slice
visible); existing donut tests unchanged; SwiftLint clean (19/0).
```

---

## Self-review notes

- **Spec coverage:** `minArcAdjusted` + `donutSlices.minArc` (Task 1); `budgetDonutSlices.minArc`
  (Task 2); verify incl. the Breakdown screenshot scenario + Budget (Task 3). All map to a task.
- **Existing tests stay green:** the default `minArc = 0.03` is a no-op for every existing
  donut test (75/25, single, 0.3, 0.2/0.5, over-budget clamp) since none has a sub-minimum
  slice — verified in Steps 4 of both tasks.
- **Type consistency:** `minArcAdjusted(_ fractions: [Double], minArc: Double) -> [Double]`
  used by `donutSlices`; both `donutSlices` and `budgetDonutSlices` gain `minArc: Double =
  0.03` after `gap`; `DonutSlice` / `CategorySpend` / `BudgetSummary` / `generalSummary` are
  the existing types/helpers.
- **No behaviour change to numbers:** captions/legend read the summary; the floor is purely
  visual. Budget full-ring edge (trailing tiny row can clamp) is documented and accepted.
- **No placeholders / no disables / config untouched / lines ≤ 120.**
