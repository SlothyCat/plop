import SwiftUI

/// The standard full-width accent button for a popup's primary action (Save / Export /
/// Send …). Pass `enabled: false` (alongside `.disabled`) to dim it.
struct PopupPrimaryButton: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Palette.tileInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Palette.accent.opacity(enabled ? 1 : 0.45),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}
