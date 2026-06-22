# Donut Minimum Arc (#3) — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-22

When one category dominates the Insights donut (e.g. Bills 99%), tiny categories
(Entertainment 1%, Food ~0%) currently render **no visible arc** — they vanish from the
ring. Give every non-zero slice a **minimum visible arc** so small categories still show a
sliver, in both the **Breakdown** and **Budget** donuts. Pure-function change → TDD.

Branch: `feature/donut-min-arc`, off `main`. One PR.

## User-visible outcome

In Insights, a category with a small but non-zero share shows a thin arc on the donut
instead of disappearing — for both Breakdown (spend split) and Budget (spend-vs-budget)
modes. Balanced charts look exactly as before; only tiny slices change.

## Cause

`donutSlices(from:gap:)` (`Logic/SpendAggregation.swift`) and `budgetDonutSlices(_:gap:)`
(`Logic/BudgetProgress.swift`) subtract the inter-slice `gap` (~0.012) from each arc, so any
slice whose fraction is below the gap clamps to zero length and draws nothing.

## In scope

1. **`minArcAdjusted(_ fractions:minArc:)`** (new, tested, in `SpendAggregation.swift`) —
   raise each non-zero fraction below `minArc` up to `minArc`, and shrink the
   ≥`minArc` fractions proportionally to absorb the deficit, so the set still **sums to 1**
   and keeps order. No-op when nothing is below `minArc`. Falls back to an equal split if
   there isn't enough room to steal (degenerate many-tiny-slices case).
2. **`donutSlices`** — add a `minArc: Double = 0.03` parameter and route fractions through
   `minArcAdjusted` before laying out arcs (Breakdown ring; still sums to 1).
3. **`budgetDonutSlices`** — add a `minArc: Double = 0.03` parameter; per donut row,
   `drawn = spent > 0 ? max(spent / totalBudget, minArc) : 0`, advancing the cursor by
   `drawn` with the existing cumulative clamp to `1.0`. Preserves the partial ring when
   under budget and the full-ring clamp when over; only tiny spent rows are bumped.

## Out of scope

- Any change to the donut **rendering** (`DonutChart`), the legend, center captions, or the
  budget/spend **numbers** (those come from the summary, not the slices, and stay accurate).
- Changing the default visual gap or the `DonutChart` arc outline.

## Key decisions (with rationale)

1. **Only sub-minimum slices change** — balanced/large slices keep exact proportions (so the
   existing donut tests, which assert 0.75/0.25, 0.3, 0.2/0.5, pass with the default
   `minArc`); only tiny ones get a sliver. Avoids distorting every chart.
2. **Breakdown normalizes to 1; Budget does not** — the Breakdown ring represents the full
   spend split (sums to 1), so the deficit is redistributed; the Budget ring is progress
   (partial when under budget), so each row is independently floored at `minArc` and the
   cumulative clamp caps it. Two functions, two correct behaviours.
3. **`minArc` as a parameter (default 0.03 ≈ 11°)** — lets tests pin exact behaviour
   (`minArc: 0` reproduces the old math) and makes the sliver size tunable in the sim.
4. **Numbers stay truthful** — captions/legend use the summary, so a floored tiny arc is a
   purely visual minimum, not a misreported value.
