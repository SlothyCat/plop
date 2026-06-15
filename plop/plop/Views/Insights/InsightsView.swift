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
