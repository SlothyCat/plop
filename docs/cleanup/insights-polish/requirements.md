# Insights & Net-total Polish (Cleanup E) — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-21

Final fidelity polish from the audit: the Home net-total's gray "$" prefix, plus three
Insights tweaks (shorter mode toggle, equal spacing around the ring, dark arc outlines).
Small, presentation-focused; one new tested formatting helper.

Branch: `feature/insights-polish`, off `main` (B1 + B2a + B2b already merged). One PR.

> The Insights Breakdown/Budget toggle is **kept** (a shipped app needs the control; the
> handoff only flipped mode via a build flag). Decision recorded — no removal.

## User-visible outcome

- **Home net total** reads like the handoff: a smaller **gray currency symbol** before the
  big dark figure (e.g. `$512.73`; `-$12.00` when negative).
- **Insights** Breakdown/Budget control is a **shorter, centered** pill group (not full
  width); the **gap above the ring equals the gap below it** (ring ↔ category cards); and
  each **ring arc has a dark outline** so the pastel slices are clearly separated.

## In scope

1. **`formattedAmountDigits(_:currencyCode:)`** (new, in `Logic/Formatting.swift`, TDD) —
   grouped, **unsigned**, **no-symbol** amount string with the currency's fraction digits
   (`512.73`, `1,000.00`, `100` for JPY). Used to compose the split net-total label.
2. **`NetTotalHeader`** — render the amount as one concatenated `Text`: `(sign + symbol)`
   in `Palette.ink40` at ~34pt **+** `formattedAmountDigits` in `Palette.ink` at ~56pt,
   `monospacedDigit`. Replaces the single inline `formattedMoney` text.
3. **`InsightsView.modeToggle`** — shorten + center: cap the segmented control width
   (~280pt) and center it, instead of full-width `.padding(.horizontal, 22)`.
4. **`InsightsView` spacing** — drive the toggle→ring gap and the ring→cards gap from a
   single `sectionGap` (~28) so they are identical (both breakdown and budget modes).
5. **`DonutChart` arc outlines** — under each colored arc, stroke a dark underlay
   (`Palette.ink`, `lineWidth + ~2.5`, same trim/animation) so adjacent arcs get a thin
   dark separator and the ring gains a subtle inner/outer outline.

## Out of scope

- Removing the Breakdown/Budget toggle (kept by decision).
- Any data/aggregation change (`spendByCategory`, `donutSlices`, `budgetSummary`), the
  period toggle, or the legends' content.
- Emoji category icons (separately deferred feature).

## Key decisions (with rationale)

1. **Split the net total via a helper, not string-slicing** — separating a localized
   currency string is fragile; composing `currencySymbol` + `formattedAmountDigits` is
   robust across our 12 prefix-symbol currencies and keeps the sign correct.
2. **Single `sectionGap` constant** — makes the above/below-ring gaps provably equal and
   easy to tune, rather than scattered per-element paddings.
3. **Dark underlay for arc outlines** — one extra stroke per slice reuses the existing
   trim + animation; no geometry math, animates identically. `Palette.ink` (charcoal)
   stays on-theme vs pure black.
4. **Sim-tuned numbers** — the 34/56pt sizes, ~280pt toggle width, ~28 `sectionGap`, and
   the ~2.5 outline width are confirmed in the simulator (not verifiable from code alone).
