# Insights & Net-total Polish (Cleanup E) — Design

Status: Approved (brainstorm complete) · Date: 2026-06-21

Companion to `requirements.md`. The formatting helper, the net-total split, the Insights
toggle width + spacing, and the donut arc outlines. Testing + scope.

## Architecture

```
plop/Logic/Formatting.swift             (add formattedAmountDigits — TDD)
plop/Views/Home/NetTotalHeader.swift    (split symbol/digits)
plop/Views/Insights/InsightsView.swift  (toggle width + sectionGap)
plop/Views/Insights/DonutChart.swift    (dark arc underlay)
plop/plopTests/FormattingTests.swift    (helper cases)
```

## 1. `formattedAmountDigits` (Logic/Formatting.swift)

```swift
/// Grouped, unsigned amount with NO currency symbol — for composing a custom money label
/// (e.g. a gray symbol prefix + dark digits). Fraction digits follow the currency.
func formattedAmountDigits(_ amount: Decimal, currencyCode: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.usesGroupingSeparator = true
    let digits = currencyFractionDigits(currencyCode: currencyCode)
    formatter.minimumFractionDigits = digits
    formatter.maximumFractionDigits = digits
    let magnitude = NSDecimalNumber(decimal: abs(amount))
    return formatter.string(from: magnitude) ?? "\(abs(amount))"
}
```

Tests (append to `FormattingTests`, locale-robust like the existing ones):
```swift
func test_amountDigits_unsignedNoSymbol() {
    let s = formattedAmountDigits(Decimal(-612), currencyCode: "USD")
    XCTAssertFalse(s.hasPrefix("-"), s)
    XCTAssertFalse(s.contains("$"), s)
    XCTAssertTrue(s.contains("612"), s)
}

func test_amountDigits_usdHasTwoFractionDigits() {
    XCTAssertTrue(formattedAmountDigits(Decimal(5), currencyCode: "USD").hasSuffix("00"),
                  formattedAmountDigits(Decimal(5), currencyCode: "USD"))
}

func test_amountDigits_jpyHasNoFraction() {
    XCTAssertEqual(formattedAmountDigits(Decimal(100), currencyCode: "JPY"), "100")
}
```

## 2. NetTotalHeader (split symbol / digits)

Replace the single amount `Text`:
```swift
            Text(formattedMoney(net, currencyCode: currencyCode))
                .font(.system(size: 56, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
```
with a concatenated `Text` (gray symbol + dark digits, baseline-aligned):
```swift
            (Text((net < 0 ? "-" : "") + currencySymbol(currencyCode))
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Palette.ink40)
             + Text(formattedAmountDigits(net, currencyCode: currencyCode))
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(Palette.ink))
                .monospacedDigit()
```
The sign rides with the gray symbol (`-$512.73`). `currencySymbol` already exists; all 12
currencies are prefix-symbol. (The `VStack(spacing: 18)` and the label/pill row are
unchanged.)

## 3. InsightsView — toggle width + spacing

Add a spacing constant on the view:
```swift
    private let sectionGap: CGFloat = 28
```

**Shorter, centered toggle.** Change:
```swift
    private var modeToggle: some View {
        Picker("", selection: $mode) {
            Text("Breakdown").tag(InsightsMode.breakdown)
            Text("Budget").tag(InsightsMode.budget)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 22)
        .padding(.top, 12)
    }
```
to:
```swift
    private var modeToggle: some View {
        Picker("", selection: $mode) {
            Text("Breakdown").tag(InsightsMode.breakdown)
            Text("Budget").tag(InsightsMode.budget)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 280)
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }
```

**Equal gaps around the ring.** The donut currently uses symmetric `.padding(.vertical, 26)`;
switch to a top-only `sectionGap`, and give the element right after the ring the same
`sectionGap` top (donut bottom padding removed). In `breakdown(_:)`:
```swift
        DonutChart(slices: donutSlices(from: spend), animationKey: "breakdown\(period)") {
            // center unchanged
        }
        .padding(.top, sectionGap)            // was .padding(.vertical, 26)

        if spend.isEmpty {
            Text("No spending \(period == .year ? "this year" : "this month").")
                .font(.system(size: 15))
                .foregroundStyle(Palette.ink40)
                .padding(.top, sectionGap)     // was .padding(.top, 30)
        } else {
            SpendLegend(spend: spend, total: total)
                .padding(.horizontal, 18)
                .padding(.top, sectionGap)     // new — matches the toggle→ring gap
        }
```
In `budget(_:)`:
```swift
        DonutChart(slices: budgetDonutSlices(summary), animationKey: key) {
            budgetCenter(summary)
        }
        .padding(.top, sectionGap)            // was .padding(.vertical, 26)

        if summary.totalBudget == 0 {
            Text("Set a budget to track your progress.")
                // …unchanged modifiers…
                .padding(.top, sectionGap)     // was .padding(.top, 8)
            if budgetFlavour == .category && !summary.rows.isEmpty {
                BudgetLegend(summary: summary, flavour: budgetFlavour, onEdit: edit)
                    .padding(.horizontal, 18)
                    .padding(.top, 18)         // unchanged (spacing under the notice)
            }
        } else {
            Text(spentOfBudget(summary))
                .font(.system(size: 13.5))
                .foregroundStyle(Palette.ink40)
                .padding(.top, sectionGap)     // new — ring→subhead gap matches
                .padding(.bottom, 6)
            BudgetLegend(summary: summary, flavour: budgetFlavour, onEdit: edit)
                .padding(.horizontal, 18)
        }
```
Net effect: toggle→ring gap and ring→(cards/notice/subhead) gap are both `sectionGap`.

## 4. DonutChart — dark arc outlines

Extract an `arc` builder and stack a dark underlay beneath each colored arc (same trim +
animation), so the outline animates with the slice. Replace the `ForEach(slices)` block:
```swift
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
```
with:
```swift
            ForEach(slices) { slice in
                ZStack {
                    arc(slice, color: Palette.ink, width: lineWidth + 2.5)
                    arc(slice, color: Color(hex: slice.colorHex), width: lineWidth)
                }
            }
```
and add the builder:
```swift
    private func arc(_ slice: DonutSlice, color: Color, width: CGFloat) -> some View {
        Circle()
            .trim(from: slice.start, to: animate ? slice.end : slice.start)
            .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .opacity(animate ? 1 : 0)
            .animation(
                .linear(duration: max(0.0001, (slice.end - slice.start) * sweep))
                    .delay(fade + slice.start * sweep),
                value: animate
            )
    }
```
The dark underlay is ~1.25pt wider on each edge → a thin dark outline on the ring's inner
and outer circumference and a dark separator at each slice end (the existing `gap: 0.012`
between slices already parts them). The faint track circle and center view are unchanged.

## Testing

- **Unit (new):** the three `formattedAmountDigits` cases above. Existing FormattingTests
  unaffected.
- **Views:** preview + simulator, light + dark, vs `home.jpg` / `insight.jpg`:
  - Net total shows a smaller gray symbol + big dark digits; negative shows `-$…`; verify a
    non-`$` currency (e.g. EUR/JPY) still aligns and JPY shows no decimals.
  - Insights toggle is shorter + centered; the gap above the ring equals the gap below it
    (cards), in both Breakdown and Budget modes;
  - ring arcs have visible dark separators/outline; the draw animation still plays on
    appear and on period/mode change.

## Scope

Four files + a helper test. No data-layer change; Insights toggle kept. One PR on
`feature/insights-polish`. This closes the audit (aside from the deferred emoji-icons
feature).
