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

    private var subtitle: String {
        mode == .general
            ? "One monthly limit for everything you spend."
            : "Give each category its own limit — they add up to your total."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("BUDGET TYPE")
                Picker("Budget mode", selection: $modeRaw) {
                    Text("Total").tag(BudgetMode.general.rawValue)
                    Text("By category").tag(BudgetMode.category.rawValue)
                }
                .pickerStyle(.segmented)
                Text(subtitle)
                    .font(.system(size: 14)).foregroundStyle(Palette.ink60)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if mode == .general {
                VStack(alignment: .leading, spacing: 7) {
                    sectionLabel("MONTHLY BUDGET")
                    bigField
                }
            } else {
                VStack(spacing: 12) {
                    VStack(spacing: 8) {
                        ForEach(categories) { cat in categoryRow(cat) }
                    }
                    totalCard
                }
            }

            VStack(spacing: 4) {
                Button { save(); close() } label: {
                    Text("Save budget")
                        .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.tileInk)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(Palette.accent,
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 18)
        .onAppear(perform: loadFields)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 22, weight: .regular)).foregroundStyle(Palette.tileInk)
                .frame(width: 42, height: 42)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            Text("Set budget")
                .font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.ink)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12.5, weight: .semibold)).tracking(0.4)
            .foregroundStyle(Palette.ink40)
    }

    private var bigField: some View {
        HStack(spacing: 8) {
            Text(currencySymbol(currencyCode))
                .font(.system(size: 22, weight: .semibold)).foregroundStyle(Palette.ink40)
            TextField("No budget", text: $generalField)
                .keyboardType(.decimalPad)
                .font(.system(size: 28, weight: .bold)).foregroundStyle(Palette.ink)
                .monospacedDigit()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink12, lineWidth: 1))
    }

    private func categoryRow(_ cat: ExpenseCategory) -> some View {
        HStack(spacing: 12) {
            CategoryIconView(category: cat)
                .font(.system(size: 18)).foregroundStyle(Palette.tileInk)
                .frame(width: 38, height: 38)
                .background(Color(hex: cat.colorHex),
                            in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            Text(cat.name).font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.ink)
            Spacer()
            smallField(text: bindingFor(cat)).frame(width: 116)
        }
    }

    private func smallField(text: Binding<String>) -> some View {
        HStack(spacing: 6) {
            Text(currencySymbol(currencyCode))
                .font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.ink40)
            TextField("0", text: text)
                .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.ink)
                .monospacedDigit()
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(Palette.field, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.ink12, lineWidth: 1))
    }

    private var totalCard: some View {
        HStack {
            Text("Total monthly budget")
                .font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.ink60)
            Spacer()
            Text(formattedMoney(sumBudgetStrings(Array(catFields.values)),
                                currencyCode: currencyCode))
                .font(.system(size: 19, weight: .bold)).foregroundStyle(Palette.ink).monospacedDigit()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink12, lineWidth: 1))
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
