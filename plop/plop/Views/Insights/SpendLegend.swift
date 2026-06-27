import SwiftUI

/// Legend rows: color dot, name, amount, % of total — largest first.
struct SpendLegend: View {
    let spend: [CategorySpend]
    let total: Decimal
    var categories: [ExpenseCategory] = []
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()

    private var lookup: [String: ExpenseCategory] {
        Dictionary(categories.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(spend.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle().fill(Palette.hair).frame(height: 1).padding(.leading, 44)
                }
                HStack(spacing: 14) {
                    CategoryIconView(category: lookup[item.id], fallbackSymbol: "tray")
                        .font(.system(size: 15)).foregroundStyle(Palette.tileInk)
                        .frame(width: 30, height: 30)
                        .background(Color(hex: item.colorHex), in: RoundedRectangle(cornerRadius: 9))
                    Text(item.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(formattedMoney(item.amount, currencyCode: currencyCode))
                            .font(.system(size: 17, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(Palette.ink)
                        Text("\(percent(item.amount))%")
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.ink40)
                    }
                }
                .padding(.vertical, 15)
            }
        }
        .padding(.horizontal, 18)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Palette.ink.opacity(0.05), radius: 8, y: 4)
    }

    private func percent(_ amount: Decimal) -> Int {
        guard total > 0 else { return 0 }
        let frac = NSDecimalNumber(decimal: amount).doubleValue
            / NSDecimalNumber(decimal: total).doubleValue
        return Int((frac * 100).rounded())
    }
}
