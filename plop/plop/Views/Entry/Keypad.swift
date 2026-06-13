import SwiftUI

/// Custom numeric keypad: 1–9, ".", 0, and the confirm (✓) key.
struct Keypad: View {
    var onKey: (String) -> Void
    var onConfirm: () -> Void
    var canConfirm: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9"], id: \.self) { digit in
                key(digit) { onKey(digit) }
            }
            key(".") { onKey(".") }
            key("0") { onKey("0") }
            confirmKey
        }
    }

    private func key(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 28))
                .monospacedDigit()
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundStyle(Palette.ink)
                .shadow(color: Palette.ink.opacity(0.05), radius: 2, y: 1)
        }
    }

    private var confirmKey: some View {
        Button(action: onConfirm) {
            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundStyle(Palette.tileInk)
                .opacity(canConfirm ? 1 : 0.4)
        }
        .disabled(!canConfirm)
    }
}
