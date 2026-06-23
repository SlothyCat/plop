import SwiftUI

/// Bottom sheet to set the transaction's date + time. The picker binds directly to
/// `date`, so selections apply live — no confirm button. Dismiss by swiping down or
/// tapping outside the sheet.
struct WhenSheet: View {
    @Binding var date: Date

    var body: some View {
        DatePicker("Date & time", selection: $date)
            .datePickerStyle(.graphical)
            .labelsHidden()
            .tint(Palette.accent)
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 20)
    }
}
