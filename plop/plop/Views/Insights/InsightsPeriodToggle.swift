import SwiftUI

/// This Month / This Year segmented control, bound to PeriodFilter (.month/.year).
struct InsightsPeriodToggle: View {
    @Binding var period: PeriodFilter

    var body: some View {
        HStack(spacing: 2) {
            segment(.month, "This Month")
            segment(.year, "This Year")
        }
        .padding(3)
        .background(Palette.ink.opacity(0.06), in: Capsule())
    }

    private func segment(_ value: PeriodFilter, _ label: String) -> some View {
        let on = period == value
        return Button { period = value } label: {
            Text(label)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(on ? Palette.ink : Palette.ink40)
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .background {
                    if on {
                        Capsule().fill(Palette.card)
                            .shadow(color: Palette.ink.opacity(0.12), radius: 3, y: 1)
                    }
                }
        }
    }
}
