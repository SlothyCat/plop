import Foundation

/// Persistence keys for the budget feature (see docs/settings-budget/design.md).
/// Per-category budgets live on `ExpenseCategory.budget`; only the mode and the
/// general-mode amount are stored here in @AppStorage.
let budgetModeKey = "budgetMode"
let generalBudgetKey = "generalBudget"

/// Which budgeting style is active. Raw values match the persisted contract.
enum BudgetMode: String {
    case general    // one monthly total; per-category budgets ignored
    case category   // per-category budgets, summed into the total
}

/// Parses user text into a budget amount. Keeps digits and a decimal point,
/// drops currency symbols, separators, and letters. Empty / unparseable -> 0
/// (meaning "no budget").
func parseBudgetAmount(_ text: String) -> Decimal {
    let filtered = text.filter { $0.isNumber || $0 == "." }
    return Decimal(string: filtered) ?? 0
}

/// Renders a stored amount back into an editable field (plain number, no symbol).
/// 0 -> "" so an unset budget shows the placeholder rather than "0".
func formatBudgetAmount(_ value: Decimal) -> String {
    value == 0 ? "" : "\(value)"
}

/// Sum of the persisted per-category budgets — the derived category-mode total.
func categoryBudgetSum(_ categories: [ExpenseCategory]) -> Decimal {
    categories.reduce(0) { $0 + $1.budget }
}

/// Sum of in-progress text-field values (for the live footer before saving).
func sumBudgetStrings(_ values: [String]) -> Decimal {
    values.reduce(0) { $0 + parseBudgetAmount($1) }
}

/// The active budget total: the general amount, or the derived category sum.
func activeBudgetTotal(mode: BudgetMode, generalBudget: String,
                       categories: [ExpenseCategory]) -> Decimal {
    switch mode {
    case .general:  return parseBudgetAmount(generalBudget)
    case .category: return categoryBudgetSum(categories)
    }
}
