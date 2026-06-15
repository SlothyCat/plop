import SwiftUI
import SwiftData

/// Sets the app's monthly budget. Two modes: a single general total, or
/// per-category amounts summed into a total. Mode + general amount persist in
/// @AppStorage; per-category amounts persist on ExpenseCategory.budget.
struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @AppStorage(budgetModeKey) private var modeRaw = BudgetMode.category.rawValue
    @AppStorage(generalBudgetKey) private var generalBudget = ""

    @State private var generalField = ""
    @State private var catFields: [PersistentIdentifier: String] = [:]

    private var mode: BudgetMode { BudgetMode(rawValue: modeRaw) ?? .category }

    var body: some View {
        List {
            Section {
                Picker("Budget mode", selection: $modeRaw) {
                    Text("Total").tag(BudgetMode.general.rawValue)
                    Text("By category").tag(BudgetMode.category.rawValue)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            if mode == .general {
                Section {
                    amountField(text: $generalField)
                } footer: {
                    Text("One monthly budget. Categories are ignored in this mode.")
                }
            } else {
                Section {
                    ForEach(categories) { cat in
                        HStack(spacing: 12) {
                            Image(systemName: cat.symbolName).foregroundStyle(Palette.ink60)
                                .frame(width: 24)
                            Text(cat.name).foregroundStyle(Palette.ink)
                            Spacer()
                            amountField(text: bindingFor(cat))
                                .frame(maxWidth: 120)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                } footer: {
                    HStack {
                        Text("Total monthly budget")
                        Spacer()
                        Text(formattedMoney(sumBudgetStrings(Array(catFields.values)),
                                            currencyCode: currencyCode))
                            .foregroundStyle(Palette.ink)
                    }
                    .font(.system(size: 14, weight: .semibold))
                }
            }

            Section {
                Button("Save budget") { save() }
                    .frame(maxWidth: .infinity)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.bg)
        .navigationTitle("Set budget")
        .onAppear(perform: loadFields)
    }

    private func amountField(text: Binding<String>) -> some View {
        HStack(spacing: 4) {
            Text(currencySymbol(currencyCode)).foregroundStyle(Palette.ink40)
            TextField("No budget", text: text)
                .keyboardType(.decimalPad)
                .foregroundStyle(Palette.ink)
        }
    }

    private func bindingFor(_ cat: ExpenseCategory) -> Binding<String> {
        Binding(
            get: { catFields[cat.persistentModelID] ?? "" },
            set: { catFields[cat.persistentModelID] = $0 }
        )
    }

    private func loadFields() {
        generalField = formatBudgetAmount(parseBudgetAmount(generalBudget))
        for cat in categories {
            catFields[cat.persistentModelID] = formatBudgetAmount(cat.budget)
        }
    }

    private func save() {
        if mode == .general {
            generalBudget = "\(parseBudgetAmount(generalField))"
        } else {
            for cat in categories {
                cat.budget = parseBudgetAmount(catFields[cat.persistentModelID] ?? "")
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack { BudgetView() }
        .modelContainer(SampleData.previewContainer())
}
#endif
