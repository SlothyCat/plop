import SwiftUI
import UIKit

extension View {
    /// Dismisses the keyboard when the user taps an empty area of this view. Interactive
    /// controls (buttons, text fields) keep handling their own taps.
    func dismissKeyboardOnTap() -> some View {
        contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}
