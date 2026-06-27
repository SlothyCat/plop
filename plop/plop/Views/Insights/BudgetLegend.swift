import SwiftUI

/// Budget-mode legend: per-row spent/budget, a progress bar, and % used / · over /
/// "Set budget". In the category flavour rows are tappable to edit that budget.
struct BudgetLegend: View {
    let summary: BudgetSummary
    let flavour: BudgetMode
    var onEdit: (CategoryBudgetProgress) -> Void = { _ in }
    var categories: [ExpenseCategory] = []

    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()

    private var lookup: [String: ExpenseCategory] {
        Dictionary(categories.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(summary.rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Rectangle().fill(Palette.hair).frame(height: 1).padding(.leading, 44)
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
                CategoryIconView(category: lookup[row.id], fallbackSymbol: "tray")
                    .font(.system(size: 15)).foregroundStyle(Palette.tileInk)
                    .frame(width: 30, height: 30)
                    .background(Color(hex: row.colorHex), in: RoundedRectangle(cornerRadius: 9))
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
