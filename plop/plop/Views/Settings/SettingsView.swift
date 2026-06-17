import SwiftUI
import SwiftData

/// Settings tab: grouped list. Only "Manage categories" is wired for now; other rows
/// arrive with their features.
struct SettingsView: View {
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @AppStorage(budgetModeKey) private var budgetModeRaw = BudgetMode.category.rawValue
    @AppStorage(generalBudgetKey) private var generalBudget = ""
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    @AppStorage(themeModeKey) private var themeModeRaw = ThemeMode.automatic.rawValue
    @State private var showingAppearance = false
    @Query private var transactions: [Transaction]
    @State private var showingExport = false

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
                    Button {
                        showingAppearance = true
                    } label: {
                        HStack {
                            Label("Theme", systemImage: "circle.lefthalf.filled")
                            Spacer()
                            Text((ThemeMode(rawValue: themeModeRaw) ?? .automatic).title)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.forward")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Section {
                    Button {
                        showingExport = true
                    } label: {
                        HStack {
                            Label("Export to Google Sheets", systemImage: "square.and.arrow.up")
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(Palette.bg)
            .sheet(isPresented: $showingAppearance) {
                AppearanceSheet { showingAppearance = false }
            }
            .sheet(isPresented: $showingExport) {
                ExportSheet(transactions: transactions, categories: categories) {
                    showingExport = false
                }
            }
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
