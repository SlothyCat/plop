import SwiftUI
import SwiftData

/// Settings tab: grouped list (DATA / PREFERENCES / RECURRING / SUPPORT). Rows use the
/// shared SettingsRow for consistent alignment. Every option opens a blurred bottom popup
/// (BlurPopup); the NavigationStack remains only to host the "Settings" title.
struct SettingsView: View {
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @AppStorage(budgetModeKey) private var budgetModeRaw = BudgetMode.category.rawValue
    @AppStorage(generalBudgetKey) private var generalBudget = ""
    @AppStorage(themeModeKey) private var themeModeRaw = ThemeMode.automatic.rawValue
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    @Query private var transactions: [Transaction]
    @State private var showingAppearance = false
    @State private var showingExport = false
    @State private var showingBugReport = false
    @State private var showingRecurring = false
    @State private var showingBudget = false
    @State private var showingCurrency = false
    @State private var showingManage = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { showingExport = true } label: {
                        SettingsRow(tile: Palette.accent, systemImage: "square.and.arrow.up",
                                    title: "Export to Google Sheets")
                    }
                    .buttonStyle(.plain)
                } header: { groupLabel("DATA") }

                Section {
                    Button { showingBudget = true } label: {
                        SettingsRow(tile: Palette.accent, systemImage: "chart.pie.fill",
                                    title: "Set budget", value: budgetSummary, showsChevron: false)
                    }
                    .buttonStyle(.plain)
                    Button { showingManage = true } label: {
                        SettingsRow(tile: Palette.accentSoft, systemImage: "tag.fill",
                                    title: "Manage categories", showsChevron: false)
                    }
                    .buttonStyle(.plain)
                    Button { showingCurrency = true } label: {
                        SettingsRow(tile: Palette.cream, systemImage: "dollarsign.circle.fill",
                                    title: "Currency", value: currencyCode, showsChevron: false)
                    }
                    .buttonStyle(.plain)
                    Button { showingAppearance = true } label: {
                        SettingsRow(tile: Palette.yellow, systemImage: "circle.lefthalf.filled",
                                    title: "Theme",
                                    value: (ThemeMode(rawValue: themeModeRaw) ?? .automatic).title)
                    }
                    .buttonStyle(.plain)
                } header: { groupLabel("PREFERENCES") }

                Section {
                    Button { showingRecurring = true } label: {
                        SettingsRow(tile: Palette.accentSoft,
                                    systemImage: "arrow.triangle.2.circlepath",
                                    title: "Recurring payments")
                    }
                    .buttonStyle(.plain)
                } header: { groupLabel("RECURRING") }

                Section {
                    Button { showingBugReport = true } label: {
                        SettingsRow(tile: Palette.accentSoft, systemImage: "ladybug.fill",
                                    title: "Report a bug")
                    }
                    .buttonStyle(.plain)
                } header: { groupLabel("SUPPORT") }

                Section {
                    Text(versionText)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Palette.ink40)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Palette.bg)
            .blurPopup(isPresented: $showingAppearance) {
                AppearanceSheet()
            }
            .blurPopup(isPresented: $showingExport) {
                ExportSheet(transactions: transactions, categories: categories)
            }
            .blurPopup(isPresented: $showingBugReport) {
                BugReportSheet()
            }
            .blurPopup(isPresented: $showingRecurring, tall: true) {
                RecurringRulesSheet()
            }
            .blurPopup(isPresented: $showingBudget) {
                BudgetView()
            }
            .blurPopup(isPresented: $showingCurrency, tall: true) {
                CurrencyView()
            }
            .blurPopup(isPresented: $showingManage, tall: true) {
                ManageCategoriesView()
            }
        }
        .tint(Palette.accent)
    }

    private func groupLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12.5, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(Palette.ink40)
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return "Version \(version ?? "")"
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
