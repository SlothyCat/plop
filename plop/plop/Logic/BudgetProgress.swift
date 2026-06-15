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
