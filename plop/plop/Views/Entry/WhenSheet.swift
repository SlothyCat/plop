import SwiftUI

/// Bottom sheet to set the transaction's date + time.
struct WhenSheet: View {
    @Binding var date: Date
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Palette.ink.opacity(0.15))
                .frame(width: 38, height: 5)
            Text("When")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Palette.ink)

            DatePicker("Date & time", selection: $date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(Palette.accent)

            Button("Done", action: onDismiss)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.accent)
            Spacer(minLength: 0)
        }
        .padding(18)
        .presentationDetents([.medium, .large])
    }
}
