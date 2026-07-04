import SwiftUI

/// The cash-register LCD panel on the Entry screen: a glass display in a beveled case showing
/// the transaction status (DEBIT·OUT / CREDIT·IN), category, amount, and date. Presentational.
struct RegisterDisplay: View {
    let type: TransactionType
    let currencySymbol: String
    let amount: String
    let category: ExpenseCategory?
    let dateText: String
    var amountInvalid: Bool = false

    private var statusText: String { type == .income ? "CREDIT · IN" : "DEBIT · OUT" }
    private var dotColor: Color { type == .income ? Palette.incomeGreen : Palette.ink }
    private var categoryText: String { category?.name.uppercased() ?? "NO CATEGORY" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 7) {
                    Circle().fill(dotColor).frame(width: 7, height: 7)
                    Text(statusText)
                        .font(.system(size: 12, weight: .bold)).tracking(1)
                }
                Spacer(minLength: 8)
                Text(categoryText)
                    .font(.system(size: 12, weight: .semibold)).tracking(1)
                    .lineLimit(1)
            }
            .foregroundStyle(Palette.lcdInk.opacity(0.75))

            Spacer(minLength: 12)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Spacer(minLength: 0)
                Text(currencySymbol)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Palette.lcdInk.opacity(0.7))
                Text(amount)
                    .font(.system(size: 64, weight: .bold)).monospacedDigit()
                    .foregroundStyle(amountInvalid ? Palette.danger : Palette.lcdInk)
            }

            Spacer(minLength: 12)

            Text(dateText.uppercased())
                .font(.system(size: 11, weight: .semibold)).tracking(1)
                .foregroundStyle(Palette.lcdInk.opacity(0.6))
        }
        .padding(20)
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Palette.lcdGlassTop, Palette.lcdGlassBottom],
                           startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
        .padding(8)
        .background(
            LinearGradient(colors: [Palette.lcdCaseTop, Palette.lcdCaseBottom],
                           startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: Palette.ink.opacity(0.10), radius: 10, y: 5)
        .padding(.horizontal, 18)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        RegisterDisplay(type: .expense, currencySymbol: "$", amount: "0",
                        category: ExpenseCategory(name: "Groceries", symbolName: "cart.fill",
                                                  colorHex: "#8CC0EB"),
                        dateText: "Today · 10:58 PM")
        RegisterDisplay(type: .income, currencySymbol: "$", amount: "42.50",
                        category: nil, dateText: "Today · 10:58 PM", amountInvalid: true)
    }
    .padding(.vertical, 40).frame(maxHeight: .infinity).background(Palette.bg)
}
#endif
