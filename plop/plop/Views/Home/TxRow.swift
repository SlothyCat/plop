import SwiftUI

/// A single transaction row: category tile, name (+ recurrence marker),
/// note-or-time, and the signed amount.
struct TxRow: View {
    let transaction: Transaction
    var onTap: () -> Void = {}

    var body: some View {
        let amount = signedAmount(transaction)
        HStack(spacing: 14) {
            tile
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(transaction.category?.name ?? "Uncategorized")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    if transaction.recurrence != .none {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Palette.ink40)
                    }
                }
                Text(secondaryText)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.ink40)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(formattedMoney(amount, signed: true, currencyCode: deviceCurrencyCode()))
                .font(.system(size: 17, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(amount > 0 ? Palette.incomeGreen : Palette.ink)
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var tile: some View {
        let color = transaction.category.map { Color(hex: $0.colorHex) } ?? Palette.hair
        return RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(color)
            .frame(width: 46, height: 46)
            .overlay(
                Image(systemName: transaction.category?.symbolName ?? "questionmark")
                    .font(.system(size: 20))
                    .foregroundStyle(Palette.tileInk)
            )
    }

    private var secondaryText: String {
        transaction.note.isEmpty
            ? transaction.date.formatted(date: .omitted, time: .shortened)
            : transaction.note
    }
}

#if DEBUG
#Preview {
    let txs = SampleData.transactions()
    return VStack {
        TxRow(transaction: txs[0])   // expense
        TxRow(transaction: txs[4])   // income
    }
    .padding()
    .background(Palette.card)
}
#endif
