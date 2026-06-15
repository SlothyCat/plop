import Foundation

/// Monthly budgets scale by this for the period. Insights is month/year only;
/// anything that isn't a year stays monthly (×1).
func periodBudgetMultiplier(_ period: PeriodFilter) -> Int {
    period == .year ? 12 : 1
}

/// One legend row in budget mode: a category's spend against its (already scaled)
/// monthly budget. `budget == 0` means the category has no budget set.
struct CategoryBudgetProgress: Identifiable, Equatable {
    let id: String          // category name, or uncategorizedSpendID
    let name: String
    let colorHex: String
    let spent: Decimal
    let budget: Decimal     // already × period multiplier; 0 when unbudgeted

    var hasBudget: Bool { budget > 0 }
    var isOver: Bool { budget > 0 && spent > budget }

    /// Fraction of this row's budget consumed (0 when unbudgeted).
    var fraction: Double {
        guard budget > 0 else { return 0 }
        return NSDecimalNumber(decimal: spent).doubleValue
             / NSDecimalNumber(decimal: budget).doubleValue
    }
}

/// The fully-computed budget view-model for a period and flavour.
struct BudgetSummary: Equatable {
    let rows: [CategoryBudgetProgress]        // legend rows
    let donutRows: [CategoryBudgetProgress]   // rows that draw donut arcs
    let totalBudget: Decimal
    let spentBudgeted: Decimal

    var remaining: Decimal { totalBudget - spentBudgeted }
    var isOver: Bool { remaining < 0 }
}

/// Assembles the budget summary from spend + categories for the active flavour.
/// - general: rows = all spend; totalBudget = generalBudget × mult; spentBudgeted = total spent.
/// - category: rows = all categories (each with its spend), sorted by spend desc;
///   donutRows = the budgeted subset; totalBudget = Σ budgeted; spentBudgeted = Σ
///   spent of budgeted. Uncategorized spend is omitted (no category to budget).
func budgetSummary(spend: [CategorySpend],
                   categories: [ExpenseCategory],
                   mode: BudgetMode,
                   generalBudget: String,
                   period: PeriodFilter) -> BudgetSummary {
    let mult = Decimal(periodBudgetMultiplier(period))

    switch mode {
    case .general:
        let rows = spend.map {
            CategoryBudgetProgress(id: $0.id, name: $0.name, colorHex: $0.colorHex,
                                   spent: $0.amount, budget: 0)
        }
        return BudgetSummary(rows: rows, donutRows: rows,
                             totalBudget: parseBudgetAmount(generalBudget) * mult,
                             spentBudgeted: totalSpent(spend))

    case .category:
        let spentByName = Dictionary(uniqueKeysWithValues:
            spend.filter { $0.id != uncategorizedSpendID }.map { ($0.name, $0.amount) })

        var rows = categories.map { cat in
            CategoryBudgetProgress(id: cat.name, name: cat.name, colorHex: cat.colorHex,
                                   spent: spentByName[cat.name] ?? 0,
                                   budget: cat.budget * mult)
        }
        rows.sort { $0.spent != $1.spent ? $0.spent > $1.spent : $0.name < $1.name }

        let donutRows = rows.filter { $0.hasBudget }
        return BudgetSummary(
            rows: rows,
            donutRows: donutRows,
            totalBudget: donutRows.reduce(Decimal(0)) { $0 + $1.budget },
            spentBudgeted: donutRows.reduce(Decimal(0)) { $0 + $1.spent })
    }
}

/// Donut slices for budget mode: each `donutRows` entry's spent ÷ totalBudget,
/// cumulative, clamped to [0, 1] so an over-budget ring fills to a full circle
/// (over-ness is shown by the center caption, not by overflowing arcs).
/// Empty when totalBudget == 0.
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
