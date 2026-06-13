import SwiftUI

/// Expense / Income segmented control.
struct SegmentedToggle: View {
    @Binding var selection: TransactionType

    var body: some View {
        HStack(spacing: 2) {
            segment(.expense, "Expense")
            segment(.income, "Income")
        }
        .padding(3)
        .background(Palette.ink.opacity(0.06), in: Capsule())
        .fixedSize()
    }

    private func segment(_ type: TransactionType, _ label: String) -> some View {
        let on = selection == type
        return Button { selection = type } label: {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .fixedSize()
                .foregroundStyle(on ? Palette.ink : Palette.ink40)
                .padding(.vertical, 8)
                .padding(.horizontal, 18)
                .background {
                    if on {
                        Capsule().fill(Palette.card)
                            .shadow(color: Palette.ink.opacity(0.12), radius: 3, y: 1)
                    }
                }
        }
    }
}
