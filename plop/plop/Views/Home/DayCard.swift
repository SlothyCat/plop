import SwiftUI

/// One day's group: a date subhead + day subtotal above a rounded card of rows.
/// Days are separated by the cards + spacing (no rule between groups).
struct DayCard: View {
    let group: DayGroup
    var onSelect: (Transaction) -> Void = { _ in }
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(dayLabel(for: group.date, relativeTo: .now, calendar: .current))
                    .tracking(0.6)
                Spacer()
                Text(formattedMoney(group.subtotal, currencyCode: currencyCode))
                    .monospacedDigit()
            }
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(Palette.ink40)
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(group.transactions.enumerated()), id: \.element.persistentModelID) { index, tx in
                    if index > 0 {
                        Rectangle()
                            .fill(Palette.hair)
                            .frame(height: 1)
                            .padding(.leading, 60)
                    }
                    TxRow(transaction: tx, onTap: { onSelect(tx) })
                }
            }
            .padding(.horizontal, 16)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Palette.ink.opacity(0.05), radius: 8, y: 4)
        }
    }
}

#if DEBUG
#Preview {
    DayCard(group: SampleData.sampleGroup())
        .padding()
        .background(Palette.bg)
}
#endif
