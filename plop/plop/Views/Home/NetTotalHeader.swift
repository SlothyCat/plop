import SwiftUI

/// The centered "Net total" block: label + period pill + large signed amount.
struct NetTotalHeader: View {
    let net: Decimal
    let period: PeriodFilter

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text("Net total")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Palette.ink60)
                Text(periodPill)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 3)
                    .background(Palette.card, in: Capsule())
                    .overlay(Capsule().stroke(Palette.ink12, lineWidth: 1))
            }
            Text(formattedMoney(net))
                .font(.system(size: 56, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
        }
    }

    private var periodPill: String {
        switch period {
        case .week: return "this week"
        case .month: return "this month"
        case .year: return "this year"
        }
    }
}

#if DEBUG
#Preview {
    NetTotalHeader(net: Decimal(string: "513.73")!, period: .month)
        .padding()
        .background(Palette.bg)
}
#endif
