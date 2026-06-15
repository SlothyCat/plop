import SwiftUI
import SwiftData

/// Settings tab: grouped list. Only "Manage categories" is wired for now; other rows
/// arrive with their features.
struct SettingsView: View {
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @AppStorage(budgetModeKey) private var budgetModeRaw = BudgetMode.category.rawValue
    @AppStorage(generalBudgetKey) private var generalBudget = ""
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    var body: some View {
        NavigationStack {
            List {
                Section("Preferences") {
                    NavigationLink {
                        BudgetView()
                    } label: {
                        HStack {
                            Label("Set budget", systemImage: "chart.pie.fill")
                            Spacer()
                            Text(budgetSummary).foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink {
                        ManageCategoriesView()
                    } label: {
                        Label("Manage categories", systemImage: "tag.fill")
                    }
                    NavigationLink {
                        CurrencyView()
                    } label: {
                        HStack {
                            Label("Currency", systemImage: "dollarsign.circle.fill")
                            Spacer()
                            Text(currencyCode).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(Palette.bg)
        }
        .tint(Palette.accent)
    }

    private var budgetSummary: String {
        let mode = BudgetMode(rawValue: budgetModeRaw) ?? .category
        let total = activeBudgetTotal(mode: mode, generalBudget: generalBudget,
                                      categories: categories)
        return total == 0 ? "None" : formattedMoney(total, currencyCode: currencyCode)
    }
}

#if DEBUG
#Preview { SettingsView().modelContainer(SampleData.previewContainer()) }
#endif
