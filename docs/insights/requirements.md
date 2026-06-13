# Insights — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-14 · Feature 3 of the app build.

## Purpose

A second tab that visualizes **spending by category** for a period as a donut chart
with a legend, so the user can see where money goes at a glance. Reads existing
transactions; no new data entry.

Design source: `design_handoff_plop/README.md` (Insights section) and
`design_handoff_plop/app/insights.jsx`.

## In scope

- **Breakdown donut** of expense spend split by category (center = total spent).
- **Legend** rows: color dot, category name, amount, % of total — largest first.
- **This Month / This Year** period toggle.
- The donut's **sequential draw animation** (ring fades in, arcs draw one-at-a-time),
  replaying on tab entry and period change.
- Wire the Insights tab to the real screen (replace the stub).

## Out of scope (deferred)

- **Budget mode** (spend vs. budget, center LEFT/OVER, per-category budget bars) →
  follow-up once the Settings "Set budget" feature exists. Nothing to chart against yet.
- **Week** period (Insights is month/year only).
- Tapping legend rows to edit budgets (part of budget mode).

## Key decisions (with rationale)

1. **Breakdown-only now.** Budget mode depends on budgets from the unbuilt Settings
   feature; shipping breakdown delivers value with no cross-feature dependency.
2. **Hand-rolled donut** (SwiftUI shapes + `trim`), not Swift Charts — needed for the
   precise per-slice **sequential draw** the design highlights.
3. **Full sequential-draw animation** (track fades in ~0.36s, then arcs fill
   one-at-a-time at constant angular speed ~1.1s), replaying on entry/period change.
4. **Expenses only** in the donut; income is excluded from the spending breakdown.
5. **Reuse `PeriodFilter`** (`.month`/`.year`) for the toggle — no new period type.
6. **Defensive "Uncategorized" bucket** (neutral gray). Category is now required at
   entry, so this should not normally appear, but keeps the donut + total honest if a
   future category deletion ever produces nil-category spend.
7. **Largest slice first** in both donut and legend.

## Behavioral requirements & edge cases

- **Period toggle** recomputes slices and **replays** the draw animation.
- **Empty period:** donut shows only the empty track, center reads `SPENT $0.00`, and
  the legend area shows "No spending this month/year."
- **Single category:** one full ring (round caps + tiny gap so it reads as a ring).
- **Percent** per row = amount / total spent (0 when total is 0).

## Success criteria

- Insights tab shows a donut + legend reflecting the period's expenses; switching
  This Month / This Year updates both and replays the draw.
- Total in the center equals the sum of all slices; legend percentages sum to ~100%.
- Empty state renders cleanly with no spending.
- Aggregation + slice math are unit-tested (green in CI); the donut/animation are
  verified via `#Preview` and the simulator.
