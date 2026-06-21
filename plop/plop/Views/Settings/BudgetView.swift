import SwiftUI
import SwiftData

/// Sets the app's monthly budget (Total or By-category). Matches the handoff Set budget popup.
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
            VStack(spacing: 14) {
                Picker("Budget mode", selection: $modeRaw) {
                    Text("Total").tag(BudgetMode.general.rawValue)
                    Text("By category").tag(BudgetMode.category.rawValue)
                }
                .pickerStyle(.segmented)
                Text(mode == .general
                     ? "One monthly budget. Categories are ignored in this mode."
                     : "Give each category its own limit — they add up to your total.")
                    .font(.system(size: 14)).foregroundStyle(Palette.ink60)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)

            ScrollView {
                VStack(spacing: 10) {
                    if mode == .general {
                        fieldCard(text: $generalField)
                    } else {
                        ForEach(categories) { cat in categoryRow(cat) }
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 14)
            }

            footer
        }
        .onAppear(perform: loadFields)
    }

    private var header: some View {
        HStack(spacing: 13) {
            Image(systemName: "target")
                .font(.system(size: 18, weight: .medium)).foregroundStyle(Palette.tileInk)
                .frame(width: 42, height: 42)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text("Set budget")
                .font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.ink)
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 14)
    }

    private func categoryRow(_ cat: ExpenseCategory) -> some View {
        HStack(spacing: 12) {
            Image(systemName: cat.symbolName)
                .font(.system(size: 16)).foregroundStyle(Palette.tileInk)
                .frame(width: 38, height: 38)
                .background(Color(hex: cat.colorHex),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(cat.name).font(.system(size: 16, weight: .medium)).foregroundStyle(Palette.ink)
            Spacer()
            fieldCard(text: bindingFor(cat)).frame(width: 140)
        }
    }

    private func fieldCard(text: Binding<String>) -> some View {
        HStack(spacing: 6) {
            Text(currencySymbol(currencyCode))
                .font(.system(size: 15)).foregroundStyle(Palette.ink40)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, 12).padding(.vertical, 11)
        .background(Palette.field, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.ink12, lineWidth: 1))
    }

    private var footer: some View {
        VStack(spacing: 12) {
            if mode == .category {
                HStack {
                    Text("Total monthly budget")
                        .font(.system(size: 15)).foregroundStyle(Palette.ink60)
                    Spacer()
                    Text(formattedMoney(sumBudgetStrings(Array(catFields.values)),
                                        currencyCode: currencyCode))
                        .font(.system(size: 18, weight: .bold)).foregroundStyle(Palette.ink)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            Button { save(); close() } label: {
                Text("Save budget")
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.tileInk)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            Button("Cancel") { close() }
                .font(.system(size: 16, weight: .medium)).foregroundStyle(Palette.ink60)
        }
        .padding(.horizontal, 20).padding(.top, 6).padding(.bottom, 14)
    }

    private func bindingFor(_ cat: ExpenseCategory) -> Binding<String> {
        Binding(get: { catFields[cat.persistentModelID] ?? "" },
                set: { catFields[cat.persistentModelID] = $0 })
    }

    private func loadFields() {
        generalField = formatBudgetAmount(parseBudgetAmount(generalBudget))
        for cat in categories { catFields[cat.persistentModelID] = formatBudgetAmount(cat.budget) }
    }

    private func save() {
        let fields = categories.map { ($0, catFields[$0.persistentModelID] ?? "") }
        generalBudget = applyBudgetSave(mode: mode, generalField: generalField,
                                        categoryFields: fields)
        loadFields()
    }
}

#if DEBUG
#Preview { BudgetView().modelContainer(SampleData.previewContainer()) }
#endif
