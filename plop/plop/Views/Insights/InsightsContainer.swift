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
