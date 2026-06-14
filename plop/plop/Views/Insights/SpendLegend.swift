import SwiftUI

/// Legend rows: color dot, name, amount, % of total — largest first.
struct SpendLegend: View {
    let spend: [CategorySpend]
    let total: Decimal

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(spend.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle().fill(Palette.hair).frame(height: 1).padding(.leading, 26)
                }
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: item.colorHex))
                        .frame(width: 14, height: 14)
                    Text(item.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(formattedMoney(item.amount, currencyCode: deviceCurrencyCode()))
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
