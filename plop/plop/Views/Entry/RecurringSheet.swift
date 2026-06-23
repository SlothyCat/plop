import SwiftUI

/// Bottom sheet to choose how often the transaction repeats. Stored on the
/// transaction (inert this feature); the generation engine is a later feature.
struct RecurringSheet: View {
    @Binding var recurrence: RecurrenceInterval

    @Environment(\.blurPopupClose) private var close

    private let options: [(value: RecurrenceInterval, title: String, subtitle: String)] = [
        (.none, "One-time", "Doesn't repeat"),
        (.daily, "Daily", "Every day"),
        (.weekly, "Weekly", "Every week"),
        (.monthly, "Monthly", "Every month"),
        (.yearly, "Yearly", "Every year"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repeat")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text("How often does this payment occur?")
                .font(.system(size: 13.5))
                .foregroundStyle(Palette.ink40)

            ForEach(options, id: \.value) { option in
                Button {
                    recurrence = option.value
                    close()
                } label: { row(option) }
            }
        }
        .padding(18)
    }

    private func row(_ option: (value: RecurrenceInterval, title: String, subtitle: String)) -> some View {
        let isOn = recurrence == option.value
        return HStack(spacing: 13) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(Palette.tileInk)
                .frame(width: 34, height: 34)
                .background(isOn ? Color.white.opacity(0.5) : Palette.card,
                            in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(option.title).font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.ink)
                Text(option.subtitle).font(.system(size: 13)).foregroundStyle(Palette.ink40)
            }
            Spacer()
            if isOn { Image(systemName: "checkmark").foregroundStyle(Palette.ink) }
        }
        .padding(12)
        .background(isOn ? Palette.accent : Palette.field, in: RoundedRectangle(cornerRadius: 14))
    }
}
