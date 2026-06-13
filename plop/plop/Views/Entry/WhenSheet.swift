import SwiftUI

/// Bottom sheet to set the transaction's date + time. The picker binds directly to
/// `date`, so selections apply live — no confirm button. Dismiss by swiping down or
/// tapping outside the sheet.
struct WhenSheet: View {
    @Binding var date: Date

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Palette.ink.opacity(0.15))
                .frame(width: 38, height: 5)
            DatePicker("Date & time", selection: $date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(Palette.accent)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .presentationDetents([.medium, .large])
    }
}
