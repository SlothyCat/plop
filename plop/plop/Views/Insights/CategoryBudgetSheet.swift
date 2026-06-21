import SwiftUI
import SwiftData

/// Inline editor for one category's monthly budget, opened from the budget legend.
/// Writes ExpenseCategory.budget; empty field clears the budget (0).
struct CategoryBudgetSheet: View {
    let category: ExpenseCategory
    var onDone: () -> Void

    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @State private var field = ""

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                CategoryIconView(category: category)
                    .font(.system(size: 20))
                    .foregroundStyle(Palette.tileInk)
                    .frame(width: 42, height: 42)
                    .background(Color(hex: category.colorHex),
                                in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 1) {
                    Text(category.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Text("Monthly budget")
                        .font(.system(size: 13.5))
                        .foregroundStyle(Palette.ink40)
                }
                Spacer()
            }

            HStack(spacing: 6) {
                Text(currencySymbol(currencyCode))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Palette.ink40)
                TextField("No budget", text: $field)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Palette.ink)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Palette.field, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink12, lineWidth: 1))

            VStack(spacing: 8) {
                Button { save() } label: {
                    Text("Save budget").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Palette.accent)
                Button("Cancel") { onDone() }
                    .foregroundStyle(Palette.ink60)
            }

            Spacer()
        }
        .padding(20)
        .background(Palette.bg)
        .onAppear { field = formatBudgetAmount(category.budget) }
        .presentationDetents([.medium])
    }

    private func save() {
        category.budget = parseBudgetAmount(field)
        onDone()
    }
}

#if DEBUG
#Preview {
    CategoryBudgetSheet(
        category: ExpenseCategory(name: "Food", symbolName: "fork.knife",
                                  colorHex: "#FFEBCC", budget: 300),
        onDone: {})
}
#endif
