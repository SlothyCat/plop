import SwiftUI
import SwiftData

/// Sets the app's monthly budget. Two modes: a single general total, or
/// per-category amounts summed into a total. Mode + general amount persist in
/// @AppStorage; per-category amounts persist on ExpenseCategory.budget.
/// Presented as a tall BlurPopup from Settings.
struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.blurPopupClose) private var close
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @AppStorage(budgetModeKey) private var modeRaw = BudgetMode.category.rawValue
    @AppStorage(generalBudgetKey) private var generalBudget = ""

    @State private var generalField = ""
    @State private var catFields: [PersistentIdentifier: String] = [:]

    private var mode: BudgetMode { BudgetMode(rawValue: modeRaw) ?? .category }

    var body: some View {
        VStack(spacing: 0) {
            header
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
            .onAppear(perform: loadFields)
        }
    }

    private var header: some View {
        HStack {
            Text("Set budget")
                .font(.system(size: 22, weight: .bold)).foregroundStyle(Palette.ink)
            Spacer()
            Button("Done") { close() }
                .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 6)
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
        let fields = categories.map { ($0, catFields[$0.persistentModelID] ?? "") }
        generalBudget = applyBudgetSave(mode: mode, generalField: generalField,
                                        categoryFields: fields)
        loadFields()   // resync @State from the new persisted truth (modes replace each other)
    }
}

#if DEBUG
#Preview {
    BudgetView()
        .modelContainer(SampleData.previewContainer())
}
#endif
