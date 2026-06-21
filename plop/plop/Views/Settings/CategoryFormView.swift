import SwiftUI
import SwiftData

/// Add (editing == nil) or edit a category as a blur popup: name, SF-symbol icon, color,
/// and an optional monthly budget. Matches the handoff Add/Edit category dialog.
struct CategoryFormView: View {
    var editing: ExpenseCategory?
    var onSave: ((ExpenseCategory) -> Void)?

    @Environment(\.blurPopupClose) private var close
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.name) private var existing: [ExpenseCategory]
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()

    @State private var name = ""
    @State private var symbolName = "tag.fill"
    @State private var colorHex = "#8CC0EB"
    @State private var budgetField = ""

    private let swatches = ["#8CC0EB", "#BFDDF0", "#FFEBCC", "#FFF9D2"]
    private let iconsPerRow = 5

    /// Icons chunked into fixed rows. Rendered eagerly (not LazyVGrid): a lazy grid in a
    /// non-scrolling popup card snaps its cells to final positions instead of sliding with
    /// the card on present.
    private var iconRows: [[String]] {
        stride(from: 0, to: categoryIconChoices.count, by: iconsPerRow).map {
            Array(categoryIconChoices[$0 ..< min($0 + iconsPerRow, categoryIconChoices.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(editing == nil ? "New category" : "Edit category")
                    .font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.ink)
                Text("Group your transactions under a custom label.")
                    .font(.system(size: 15)).foregroundStyle(Palette.ink60)
                    .fixedSize(horizontal: false, vertical: true)
            }
            field("NAME") {
                TextField("e.g. Transport", text: $name)
                    .font(.system(size: 16)).foregroundStyle(Palette.ink)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(Palette.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.ink12, lineWidth: 1))
            }
            field("ICON") {
                VStack(spacing: 10) {
                    ForEach(iconRows, id: \.self) { row in
                        HStack(spacing: 10) {
                            ForEach(row, id: \.self) { iconButton($0).frame(maxWidth: .infinity) }
                            ForEach(0 ..< (iconsPerRow - row.count), id: \.self) { _ in
                                Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                            }
                        }
                    }
                }
            }
            field("COLOR") {
                HStack(spacing: 14) {
                    ForEach(swatches, id: \.self) { swatchView($0) }
                    ColorPicker("Custom", selection: colorBinding).labelsHidden()
                }
            }
            field("MONTHLY BUDGET · OPTIONAL") { budgetFieldView }
            VStack(spacing: 4) {
                Button { save() } label: {
                    Text("Save")
                        .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.tileInk)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(Palette.accent.opacity(canSave ? 1 : 0.45),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain).disabled(!canSave)
                Button("Cancel") { close() }
                    .font(.system(size: 16, weight: .medium)).foregroundStyle(Palette.ink60)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 18)
        .onAppear(perform: prefill)
    }

    private func field<Content: View>(_ label: String,
                                      @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label).font(.system(size: 12.5, weight: .semibold)).tracking(0.4)
                .foregroundStyle(Palette.ink40)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
    }

    private var budgetFieldView: some View {
        HStack(spacing: 6) {
            Text(currencySymbol(currencyCode))
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.ink40)
            TextField("No budget", text: $budgetField)
                .keyboardType(.decimalPad).font(.system(size: 16)).foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Palette.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.ink12, lineWidth: 1))
    }

    private func iconButton(_ symbol: String) -> some View {
        let on = symbol == symbolName
        return Button { symbolName = symbol } label: {
            Image(systemName: symbol)
                .font(.system(size: 20)).foregroundStyle(on ? Palette.tileInk : Palette.ink)
                .frame(width: 46, height: 46)
                .background(on ? Color(hex: colorHex) : Palette.field,
                            in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13)
                    .stroke(on ? Color.clear : Palette.ink12, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func swatchView(_ hex: String) -> some View {
        Circle().fill(Color(hex: hex)).frame(width: 34, height: 34)
            .overlay(Circle().stroke(Palette.ink, lineWidth: hex == colorHex ? 2.5 : 0))
            .onTapGesture { colorHex = hex }
    }

    private var colorBinding: Binding<Color> {
        Binding(get: { Color(hex: colorHex) }, set: { colorHex = $0.toHex() })
    }

    private var canSave: Bool {
        isCategoryNameAvailable(name, existing: existing, editing: editing)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let budget = parseBudgetAmount(budgetField)
        if let editing {
            CategoryActions.update(editing, name: trimmed, symbolName: symbolName,
                                   colorHex: colorHex, budget: budget)
            onSave?(editing)
        } else {
            let created = CategoryActions.add(name: trimmed, symbolName: symbolName,
                                              colorHex: colorHex, budget: budget,
                                              in: modelContext)
            onSave?(created)
        }
        close()
    }

    private func prefill() {
        guard let editing else { return }
        name = editing.name
        symbolName = editing.symbolName
        colorHex = editing.colorHex
        budgetField = editing.budget > 0 ? formatBudgetAmount(editing.budget) : ""
    }
}

#if DEBUG
#Preview { CategoryFormView().modelContainer(SampleData.previewContainer()) }
#endif
