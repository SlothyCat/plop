# Insights Budget Mode — PR2 (UI) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the Insights budget-mode UI on top of PR1's Logic — a Breakdown/Budget toggle, a consumption donut with a LEFT/OVER center, a budget legend with progress bars, and tap-to-edit of a category's budget.

**Architecture:** Two new presentational views (`CategoryBudgetSheet`, `BudgetLegend`) plus changes to `InsightsView` (mode toggle + budget branch) and `InsightsContainer` (feed categories + budget `@AppStorage`). All rendering consumes PR1's pure `budgetSummary(...)` / `budgetDonutSlices(...)`; the existing `DonutChart` and `SpendLegend` are reused unchanged.

**Tech Stack:** SwiftUI, SwiftData, `@AppStorage`. iOS 18. Views verified via `#Preview` + simulator (no view unit tests, per CLAUDE.md).

---

## Branching

PR1 lives on `feature/insights-budget`. Branch PR2 **after PR1 merges**:
```bash
git checkout main && git pull --ff-only
git checkout -b feature/insights-budget-ui
```
(If PR1 isn't merged yet, branch off `feature/insights-budget` instead so the
PR1 Logic is present, and rebase onto `main` after PR1 merges.)

## File structure

- **Create** `plop/plop/Views/Insights/CategoryBudgetSheet.swift` — inline single-category budget editor.
- **Create** `plop/plop/Views/Insights/BudgetLegend.swift` — budget-mode legend rows + progress bar.
- **Modify** `plop/plop/Views/Insights/InsightsView.swift` — mode toggle + breakdown/budget branches + edit sheet.
- **Modify** `plop/plop/Views/Insights/InsightsContainer.swift` — query categories, read budget `@AppStorage`, pass down.

### Verified existing symbols this builds on

- PR1 Logic: `budgetSummary(spend:categories:mode:generalBudget:period:) -> BudgetSummary`, `budgetDonutSlices(_:gap:) -> [DonutSlice]`, `CategoryBudgetProgress` (`spent`, `budget`, `colorHex`, `name`, `id`, `hasBudget`, `isOver`, `fraction`), `BudgetSummary` (`rows`, `donutRows`, `totalBudget`, `spentBudgeted`, `remaining`, `isOver`).
- `Budget.swift`: `BudgetMode`, `budgetModeKey`, `generalBudgetKey`, `parseBudgetAmount`, `formatBudgetAmount`, `currencyCodeKey`, `deviceCurrencyCode`, `currencySymbol`.
- `SpendAggregation.swift`: `spendByCategory`, `totalSpent`, `donutSlices`, `CategorySpend`.
- Views: `DonutChart(slices:animationKey:center:)`, `SpendLegend(spend:total:)`, `InsightsPeriodToggle(period:)`.
- `Palette` tokens: `bg`, `card`, `field`, `ink`, `ink60`, `ink40`, `ink12`, `hair`, `accent`, `tileInk`; `Color(hex:)`.
- `ExpenseCategory` is a SwiftData `@Model` (Identifiable) with `name`, `symbolName`, `colorHex`, `budget`.

### Build/test commands

```bash
xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'

xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO

swiftlint lint
```

> SourceKit shows false "Cannot find X in scope" for same-module symbols. **The build is the source of truth.** Keep lines ≤ 120 chars (SwiftLint `line_length`).

---

## Task 1: CategoryBudgetSheet (inline editor)

**Files:**
- Create: `plop/plop/Views/Insights/CategoryBudgetSheet.swift`

- [ ] **Step 1: Write the view**

Create `plop/plop/Views/Insights/CategoryBudgetSheet.swift`:

```swift
import SwiftUI
import SwiftData

/// Inline editor for one category's monthly budget, opened from the budget legend.
/// Writes ExpenseCategory.budget; empty field clears the budget (0).
struct CategoryBudgetSheet: View {
    let category: ExpenseCategory
    var onDone: () -> Void

    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @State private var field = ""

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: category.symbolName)
                    .font(.system(size: 20))
                    .foregroundStyle(Palette.tileInk)
                    .frame(width: 42, height: 42)
                    .background(Color(hex: category.colorHex),
                                in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 1) {
                    Text(category.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Text("Monthly budget")
                        .font(.system(size: 13.5))
                        .foregroundStyle(Palette.ink40)
                }
                Spacer()
            }

            HStack(spacing: 6) {
                Text(currencySymbol(currencyCode))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Palette.ink40)
                TextField("No budget", text: $field)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Palette.ink)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Palette.field, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink12, lineWidth: 1))

            VStack(spacing: 8) {
                Button { save() } label: {
                    Text("Save budget").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Palette.accent)
                Button("Cancel") { onDone() }
                    .foregroundStyle(Palette.ink60)
            }

            Spacer()
        }
        .padding(20)
        .background(Palette.bg)
        .onAppear { field = formatBudgetAmount(category.budget) }
        .presentationDetents([.medium])
    }

    private func save() {
        category.budget = parseBudgetAmount(field)
        onDone()
    }
}

#if DEBUG
#Preview {
    CategoryBudgetSheet(
        category: ExpenseCategory(name: "Food", symbolName: "fork.knife",
                                  colorHex: "#FFEBCC", budget: 300),
        onDone: {})
}
#endif
```

> The mutually-exclusive Settings rule (saving Total clears categories) is *not*
> re-applied here: this editor only runs in the category flavour, where the total
> is always the derived category sum — so editing one category is self-consistent
> and `generalBudget` (general mode's value) is intentionally left untouched.

- [ ] **Step 2: Verify the target builds**

Run the `xcodebuild build` command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add plop/plop/Views/Insights/CategoryBudgetSheet.swift
git commit -m "Add inline category budget editor sheet

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: BudgetLegend (rows + progress bars)

**Files:**
- Create: `plop/plop/Views/Insights/BudgetLegend.swift`

- [ ] **Step 1: Write the view**

Create `plop/plop/Views/Insights/BudgetLegend.swift`:

```swift
import SwiftUI

/// Budget-mode legend: per-row spent/budget, a progress bar, and % used / · over /
/// "Set budget". In the category flavour rows are tappable to edit that budget.
struct BudgetLegend: View {
    let summary: BudgetSummary
    let flavour: BudgetMode
    var onEdit: (CategoryBudgetProgress) -> Void = { _ in }

    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(summary.rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Rectangle().fill(Palette.hair).frame(height: 1).padding(.leading, 26)
                }
                rowButton(row)
            }
        }
        .padding(.horizontal, 18)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Palette.ink.opacity(0.05), radius: 8, y: 4)
    }

    @ViewBuilder private func rowButton(_ row: CategoryBudgetProgress) -> some View {
        let tappable = flavour == .category
        Button { if tappable { onEdit(row) } } label: { rowBody(row) }
            .buttonStyle(.plain)
            .disabled(!tappable)
    }

    private func rowBody(_ row: CategoryBudgetProgress) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(hex: row.colorHex))
                    .frame(width: 14, height: 14)
                Text(row.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(amountLabel(row))
                        .font(.system(size: 16, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Palette.ink)
                    Text(captionLabel(row))
                        .font(.system(size: 13))
                        .fontWeight(row.isOver ? .semibold : .regular)
                        .foregroundStyle(row.isOver ? Palette.ink : Palette.ink40)
                }
            }
            if showsBar(row) {
                BudgetBar(fraction: barFraction(row),
                          color: Color(hex: row.colorHex), over: row.isOver)
            }
        }
        .padding(.vertical, 15)
    }

    // MARK: labels

    private func money(_ value: Decimal) -> String {
        formattedMoney(value, currencyCode: currencyCode)
    }

    private func amountLabel(_ row: CategoryBudgetProgress) -> String {
        if flavour == .category && row.hasBudget {
            return "\(money(row.spent)) / \(money(row.budget))"
        }
        return money(row.spent)
    }

    private func captionLabel(_ row: CategoryBudgetProgress) -> String {
        if flavour == .general {
            return "\(generalPercent(row))% of budget"
        }
        if !row.hasBudget { return "Set budget" }
        let pct = Int((row.fraction * 100).rounded())
        return row.isOver ? "\(pct)% · over" : "\(pct)% used"
    }

    private func showsBar(_ row: CategoryBudgetProgress) -> Bool {
        flavour == .general ? summary.totalBudget > 0 : row.hasBudget
    }

    private func barFraction(_ row: CategoryBudgetProgress) -> Double {
        flavour == .general ? generalFraction(row) : row.fraction
    }

    private func generalFraction(_ row: CategoryBudgetProgress) -> Double {
        guard summary.totalBudget > 0 else { return 0 }
        return NSDecimalNumber(decimal: row.spent).doubleValue
             / NSDecimalNumber(decimal: summary.totalBudget).doubleValue
    }

    private func generalPercent(_ row: CategoryBudgetProgress) -> Int {
        Int((generalFraction(row) * 100).rounded())
    }
}

/// A thin progress bar. Fills to `fraction` (clamped 0...1); charcoal when over.
private struct BudgetBar: View {
    let fraction: Double
    let color: Color
    let over: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.ink.opacity(0.08))
                Capsule().fill(over ? Palette.ink : color)
                    .frame(width: geo.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 6)
    }
}

#if DEBUG
#Preview {
    let rows = [
        CategoryBudgetProgress(id: "Rent", name: "Rent", colorHex: "#8CC0EB",
                               spent: 700, budget: 600),
        CategoryBudgetProgress(id: "Food", name: "Food", colorHex: "#FFEBCC",
                               spent: 300, budget: 400),
        CategoryBudgetProgress(id: "Subs", name: "Subs", colorHex: "#FFF9D2",
                               spent: 30, budget: 0)
    ]
    let summary = BudgetSummary(rows: rows, donutRows: rows.filter { $0.hasBudget },
                               totalBudget: 1000, spentBudgeted: 1000)
    return BudgetLegend(summary: summary, flavour: .category)
        .padding()
        .background(Palette.bg)
}
#endif
```

- [ ] **Step 2: Verify the target builds**

Run the `xcodebuild build` command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add plop/plop/Views/Insights/BudgetLegend.swift
git commit -m "Add budget-mode legend with progress bars

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: InsightsView mode toggle + budget branch + container wiring

**Files:**
- Modify: `plop/plop/Views/Insights/InsightsView.swift`
- Modify: `plop/plop/Views/Insights/InsightsContainer.swift`

- [ ] **Step 1: Replace InsightsView with the two-mode version**

Replace the entire contents of `plop/plop/Views/Insights/InsightsView.swift` with:

```swift
import SwiftUI

enum InsightsMode: String, CaseIterable { case breakdown, budget }

/// Presentational Insights screen with two modes: Breakdown (spend split) and
/// Budget (spend vs budget). Budget data comes from the container.
struct InsightsView: View {
    let transactions: [Transaction]
    var categories: [ExpenseCategory] = []
    var budgetFlavour: BudgetMode = .category
    var generalBudget: String = ""

    @State private var period: PeriodFilter = .month
    @State private var mode: InsightsMode = .breakdown
    @State private var editing: ExpenseCategory?
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()

    var body: some View {
        let range = period.range(containing: .now, calendar: .current)
        let spend = spendByCategory(transactions, in: range)

        VStack(spacing: 0) {
            header
            modeToggle
            ScrollView {
                if mode == .breakdown {
                    breakdown(spend)
                } else {
                    budget(spend)
                }
            }
            .padding(.bottom, 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.bg)
        .sheet(item: $editing) { cat in
            CategoryBudgetSheet(category: cat) { editing = nil }
        }
    }

    // MARK: chrome

    private var header: some View {
        HStack {
            Text("Insights")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Palette.ink)
            Spacer()
            InsightsPeriodToggle(period: $period)
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
    }

    private var modeToggle: some View {
        Picker("", selection: $mode) {
            Text("Breakdown").tag(InsightsMode.breakdown)
            Text("Budget").tag(InsightsMode.budget)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 22)
        .padding(.top, 12)
    }

    // MARK: breakdown

    @ViewBuilder private func breakdown(_ spend: [CategorySpend]) -> some View {
        let total = totalSpent(spend)
        DonutChart(slices: donutSlices(from: spend), animationKey: "breakdown\(period)") {
            VStack(spacing: 3) {
                Text("SPENT")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(Palette.ink40)
                Text(formattedMoney(total, currencyCode: currencyCode))
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

    // MARK: budget

    @ViewBuilder private func budget(_ spend: [CategorySpend]) -> some View {
        let summary = budgetSummary(spend: spend, categories: categories,
                                    mode: budgetFlavour, generalBudget: generalBudget,
                                    period: period)
        let key = "budget\(period)\(budgetFlavour)\(summary.totalBudget)\(summary.spentBudgeted)"

        DonutChart(slices: budgetDonutSlices(summary), animationKey: key) {
            budgetCenter(summary)
        }
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
    }

    private func budgetCenter(_ s: BudgetSummary) -> some View {
        let remaining = s.remaining < 0 ? -s.remaining : s.remaining
        return VStack(spacing: 3) {
            Text(s.isOver ? "OVER" : "LEFT")
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Palette.ink40)
            Text(formattedMoney(remaining, currencyCode: currencyCode))
                .font(.system(size: 30, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
            Text("of \(formattedMoney(s.totalBudget, currencyCode: currencyCode))")
                .font(.system(size: 12.5))
                .foregroundStyle(Palette.ink40)
        }
    }

    private func spentOfBudget(_ s: BudgetSummary) -> String {
        let spent = formattedMoney(s.spentBudgeted, currencyCode: currencyCode)
        let total = formattedMoney(s.totalBudget, currencyCode: currencyCode)
        return "\(spent) spent of \(total) budget"
    }

    private func edit(_ row: CategoryBudgetProgress) {
        editing = categories.first { $0.name == row.name }
    }
}

#if DEBUG
#Preview("Breakdown") { InsightsView(transactions: SampleData.transactions()) }
#Preview("Empty") { InsightsView(transactions: []) }
#endif
```

- [ ] **Step 2: Wire the container**

Replace the contents of `plop/plop/Views/Insights/InsightsContainer.swift` with:

```swift
import SwiftUI
import SwiftData

/// Reads transactions, categories, and the budget settings from SwiftData /
/// @AppStorage and feeds the presentational InsightsView.
struct InsightsContainer: View {
    @Query private var transactions: [Transaction]
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    @AppStorage(budgetModeKey) private var budgetModeRaw = BudgetMode.category.rawValue
    @AppStorage(generalBudgetKey) private var generalBudget = ""

    var body: some View {
        InsightsView(transactions: transactions,
                     categories: categories,
                     budgetFlavour: BudgetMode(rawValue: budgetModeRaw) ?? .category,
                     generalBudget: generalBudget)
    }
}

#if DEBUG
#Preview {
    InsightsContainer().modelContainer(SampleData.previewContainer())
}
#endif
```

- [ ] **Step 3: Verify the target builds**

Run the `xcodebuild build` command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add plop/plop/Views/Insights/InsightsView.swift plop/plop/Views/Insights/InsightsContainer.swift
git commit -m "Add Insights budget mode toggle, donut, legend, and edit sheet

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Verify and open PR

**Files:** none (verification + PR).

- [ ] **Step 1: Run the full test suite** (the PR1 Logic must still pass)

```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO
```
Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 2: Lint**

```bash
swiftlint lint
```
Expected: no new violations from the added/changed files (watch `line_length` ≤ 120).

- [ ] **Step 3: Simulator smoke check (manual)**

Run the app → Insights:
- Toggle **Breakdown ↔ Budget**; donut replays each switch.
- **Budget / category flavour** (default): donut fills toward budget; center shows
  LEFT or OVER `of {total}`; subhead `{spent} spent of {total} budget`; legend
  shows `spent / budget`, bars, `% used` / `% · over`; unbudgeted rows read
  "Set budget". Tap a row → sheet → set/clear a budget → Insights updates.
- Switch period to **This Year** → budgets scale ×12.
- Switch Settings → Set budget to **Total**, set a number → Insights budget mode
  (general flavour) shows `% of budget` rows, donut vs the single total.
- With no budget set → empty-state prompt; category flavour still lists tappable
  "Set budget" rows.
- Change the Currency picker → Insights money/symbols update.

- [ ] **Step 4: Push and open the PR**

```bash
git push -u origin feature/insights-budget-ui
```

`gh` is not installed — open the PR via the printed GitHub web URL. Use the
project PR-description format:

```markdown
## Summary
Add the Insights budget mode UI: Breakdown/Budget toggle, consumption donut with
a LEFT/OVER center, a budget legend with progress bars, and tap-to-edit of a
category's budget. Consumes the PR1 budget aggregation Logic.

## Testing
All unit tests pass (no new — UI change); SwiftLint clean. Sim-verified: toggle,
both flavours, year ×12, over-budget, no-budget, tap-to-edit, currency.
```

---

## Self-review notes

- **Spec coverage:** mode toggle below header (Task 3 `modeToggle`); consumption
  donut + LEFT/OVER center + `of {total}` (Task 3 `budget`/`budgetCenter`);
  subhead (Task 3 `spentOfBudget`); legend rows + bars + `% used`/`· over`/`Set
  budget` (Task 2); general flavour `% of budget` (Task 2 `captionLabel`);
  tap-to-edit sheet (Tasks 1 + 3 `edit`/`.sheet`); empty state (Task 3); year ×12
  (PR1, surfaced via the period toggle); currency reactivity (`@AppStorage` reads
  in every view). Breakdown mode unchanged.
- **Type consistency:** `InsightsView(transactions:categories:budgetFlavour:generalBudget:)`
  matches the container call (extra params have defaults so existing previews
  compile); `BudgetLegend(summary:flavour:onEdit:)` and
  `CategoryBudgetSheet(category:onDone:)` match their call sites; `edit(_:)` maps a
  `CategoryBudgetProgress` back to its `ExpenseCategory` by name; `sheet(item:)`
  relies on `ExpenseCategory` being an Identifiable `@Model`.
- **No placeholders:** every file's full contents are given.
- **Edge handling:** general flavour with `totalBudget == 0` shows only the prompt
  (no divide-by-zero rows, no legend); category flavour with `totalBudget == 0`
  shows the prompt plus tappable "Set budget" rows; `BudgetBar` clamps its fill to
  `0...1`; `budgetDonutSlices` already clamps the over-budget ring.
