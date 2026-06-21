# Insights & Net-total Polish (Cleanup E) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish the Home net total (gray symbol + dark digits) and Insights (shorter centered mode toggle, equal spacing around the ring, dark arc outlines).

**Architecture:** Add one tested formatting helper, then small presentation edits to three views. No data-layer change.

**Tech Stack:** SwiftUI, XCTest. iOS 18. Views verified via `#Preview` + simulator.

Single PR on branch `feature/insights-polish` (off `main`; spec committed there).

---

## File structure

- **Modify** `plop/plop/Logic/Formatting.swift` — add `formattedAmountDigits`.
- **Modify** `plop/plopTests/FormattingTests.swift` — three helper cases.
- **Modify** `plop/plop/Views/Home/NetTotalHeader.swift` — split symbol/digits.
- **Modify** `plop/plop/Views/Insights/InsightsView.swift` — toggle width + `sectionGap`.
- **Modify** `plop/plop/Views/Insights/DonutChart.swift` — dark arc underlay.

### Build / lint / test commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | tail -5

cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests/FormattingTests \
  -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2

swiftlint lint
```

> SourceKit "Cannot find X" / "No such module" diagnostics are FALSE positives — `xcodebuild`
> is the source of truth. Lines ≤ 120. No `// swiftlint:disable`. Keep the lint baseline
> (21 violations, 0 serious); do not edit `.swiftlint.yml`.

---

## Task 1: `formattedAmountDigits` helper (TDD)

**Files:**
- Modify: `plop/plopTests/FormattingTests.swift`
- Modify: `plop/plop/Logic/Formatting.swift`

- [ ] **Step 1: Add the failing tests**

In `FormattingTests.swift`, add these three methods inside the `FormattingTests` class (e.g.
after `test_money_signedPositiveShowsPlus`):
```swift
    func test_amountDigits_unsignedNoSymbol() {
        let s = formattedAmountDigits(Decimal(-612), currencyCode: "USD")
        XCTAssertFalse(s.hasPrefix("-"), s)
        XCTAssertFalse(s.contains("$"), s)
        XCTAssertTrue(s.contains("612"), s)
    }

    func test_amountDigits_usdHasTwoFractionDigits() {
        let s = formattedAmountDigits(Decimal(5), currencyCode: "USD")
        XCTAssertTrue(s.hasSuffix("00"), s)
    }

    func test_amountDigits_jpyHasNoFraction() {
        XCTAssertEqual(formattedAmountDigits(Decimal(100), currencyCode: "JPY"), "100")
    }
```

- [ ] **Step 2: Run tests to verify they fail** — run the test command. Expected: compile
  error / FAIL (`formattedAmountDigits` not defined).

- [ ] **Step 3: Implement the helper**

In `Formatting.swift`, add after `formattedMoney(...)`:
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

- [ ] **Step 4: Run tests to verify they pass** — run the test command → `** TEST
  SUCCEEDED **`.

- [ ] **Step 5: Lint + commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && swiftlint lint 2>&1 | tail -3
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Logic/Formatting.swift plop/plopTests/FormattingTests.swift
git commit -m "Add formattedAmountDigits: unsigned, no-symbol grouped amount

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: NetTotalHeader — gray symbol + dark digits

**Files:**
- Modify: `plop/plop/Views/Home/NetTotalHeader.swift`

- [ ] **Step 1: Split the amount text**

Change:
```swift
            Text(formattedMoney(net, currencyCode: currencyCode))
                .font(.system(size: 56, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
```
to:
```swift
            (Text((net < 0 ? "-" : "") + currencySymbol(currencyCode))
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Palette.ink40)
             + Text(formattedAmountDigits(net, currencyCode: currencyCode))
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(Palette.ink))
                .monospacedDigit()
```
(The `VStack(spacing: 18)`, the "Net total" label, and the period pill are unchanged.)

- [ ] **Step 2: Build** — run the build command → `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Home/NetTotalHeader.swift
git commit -m "Render net total with a gray currency symbol before the figure

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: InsightsView — shorter toggle + equal ring spacing

**Files:**
- Modify: `plop/plop/Views/Insights/InsightsView.swift`

- [ ] **Step 1: Add the spacing constant**

After the `@AppStorage(currencyCodeKey) ...` line (the last stored property), add:
```swift
    private let sectionGap: CGFloat = 28
```

- [ ] **Step 2: Shorten + center the mode toggle**

Change:
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

- [ ] **Step 3: Equalize the breakdown spacing**

In `breakdown(_:)`, change the donut padding and the elements after it. Change:
```swift
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
```
to:
```swift
        .padding(.top, sectionGap)

        if spend.isEmpty {
            Text("No spending \(period == .year ? "this year" : "this month").")
                .font(.system(size: 15))
                .foregroundStyle(Palette.ink40)
                .padding(.top, sectionGap)
        } else {
            SpendLegend(spend: spend, total: total)
                .padding(.horizontal, 18)
                .padding(.top, sectionGap)
        }
```

- [ ] **Step 4: Equalize the budget spacing**

In `budget(_:)`, change the donut padding and the elements after it. Change:
```swift
        .padding(.vertical, 26)

        if summary.totalBudget == 0 {
            Text("Set a budget to track your progress.")
                .font(.system(size: 15))
                .foregroundStyle(Palette.ink40)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.top, 8)
            if budgetFlavour == .category && !summary.rows.isEmpty {
                BudgetLegend(summary: summary, flavour: budgetFlavour, onEdit: edit)
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
            }
        } else {
            Text(spentOfBudget(summary))
                .font(.system(size: 13.5))
                .foregroundStyle(Palette.ink40)
                .padding(.bottom, 6)
            BudgetLegend(summary: summary, flavour: budgetFlavour, onEdit: edit)
                .padding(.horizontal, 18)
        }
```
to:
```swift
        .padding(.top, sectionGap)

        if summary.totalBudget == 0 {
            Text("Set a budget to track your progress.")
                .font(.system(size: 15))
                .foregroundStyle(Palette.ink40)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.top, sectionGap)
            if budgetFlavour == .category && !summary.rows.isEmpty {
                BudgetLegend(summary: summary, flavour: budgetFlavour, onEdit: edit)
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
            }
        } else {
            Text(spentOfBudget(summary))
                .font(.system(size: 13.5))
                .foregroundStyle(Palette.ink40)
                .padding(.top, sectionGap)
                .padding(.bottom, 6)
            BudgetLegend(summary: summary, flavour: budgetFlavour, onEdit: edit)
                .padding(.horizontal, 18)
        }
```

- [ ] **Step 5: Build** — run the build command → `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 7: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Insights/InsightsView.swift
git commit -m "Shorten/center Insights mode toggle and equalize ring spacing

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: DonutChart — dark arc outlines

**Files:**
- Modify: `plop/plop/Views/Insights/DonutChart.swift`

- [ ] **Step 1: Stack a dark underlay under each colored arc**

Change the `ForEach(slices) { ... }` block:
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
to:
```swift
            ForEach(slices) { slice in
                ZStack {
                    arc(slice, color: Palette.ink, width: lineWidth + 2.5)
                    arc(slice, color: Color(hex: slice.colorHex), width: lineWidth)
                }
            }
```

- [ ] **Step 2: Add the `arc` builder**

Add this method to `DonutChart` (e.g. just before `replay()`):
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

- [ ] **Step 3: Build** — run the build command → `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 5: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Insights/DonutChart.swift
git commit -m "Outline donut arcs with a dark underlay for contrast

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` (3 new FormattingTests).

- [ ] **Step 2: Lint** — `swiftlint lint` → baseline 21/0, no new violations.

- [ ] **Step 3: Simulator smoke check (manual — owner)**

Light + dark, vs `home.jpg` / `insight.jpg`:
- **Home:** net total shows a smaller **gray symbol** + big dark digits; a negative net shows
  `-$…`; switch currency to **EUR** and **JPY** (Settings → Currency) and confirm alignment
  and that **JPY shows no decimals**.
- **Insights:** the Breakdown/Budget toggle is **shorter + centered**; the gap **above** the
  ring equals the gap **below** it (to the cards) in **both** Breakdown and Budget modes;
  the ring **arcs have a visible dark separator/outline**; the draw animation still plays on
  appear and on period/mode change.
- If the symbol size (34), digit size (56), toggle width (280), `sectionGap` (28), or outline
  width (2.5) look off, tune those constants — they're the sim-tunable knobs.

- [ ] **Step 4: Push + PR**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git push -u origin feature/insights-polish
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Cleanup E (final polish): net total renders a gray currency symbol before the big figure;
Insights gets a shorter centered mode toggle, equal spacing above/below the ring, and dark
outlines on the donut arcs. Insights Breakdown/Budget toggle kept by decision.

## Testing
All unit tests pass (3 new for formattedAmountDigits); SwiftLint clean (baseline 21/0).
Sim-verified vs home.jpg / insight.jpg (gray symbol, JPY no-decimals, equal ring gaps, arc
outlines), light + dark.
```

---

## Self-review notes

- **Spec coverage:** `formattedAmountDigits` + tests (Task 1); net-total split (Task 2);
  toggle width + `sectionGap` in both modes (Task 3); donut arc underlay (Task 4); verify +
  sim incl. EUR/JPY + equal-gaps check (Task 5). Insights toggle kept (no removal task — by
  decision). All spec items map to a task.
- **Type consistency:** `formattedAmountDigits(_:currencyCode:)` defined in Task 1, used in
  Task 2; `currencySymbol` / `currencyFractionDigits` already exist; `sectionGap` defined
  once and reused; `arc(_:color:width:)` added in Task 4 and used in the same file;
  `DonutSlice` fields (`start`/`end`/`colorHex`/`id`) match the existing struct.
- **Behavior preserved:** no aggregation/period/legend/data change; the donut draw animation
  is unchanged (the underlay reuses the same trim + animation). Only `formattedAmountDigits`
  is new logic (unit-tested); the rest is presentation (preview + sim per project convention).
- **No placeholders / no disables / config untouched / lines ≤ 120.**
- **Sim-tunable:** 34/56pt, 280pt toggle, 28 `sectionGap`, 2.5 outline — flagged in Task 5.
