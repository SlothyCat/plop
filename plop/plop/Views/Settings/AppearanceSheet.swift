import SwiftUI

/// Bottom-sheet appearance picker: Light / Dark / Automatic. Tapping a card writes
/// @AppStorage(themeModeKey); the app repaints live behind the sheet. Done dismisses.
struct AppearanceSheet: View {
    @AppStorage(themeModeKey) private var themeModeRaw = ThemeMode.automatic.rawValue
    var onDone: () -> Void

    private var selected: ThemeMode { ThemeMode(rawValue: themeModeRaw) ?? .automatic }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Appearance")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Text("Choose how the app looks. Automatic follows your device's "
                     + "light or dark setting.")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.ink60)
            }

            VStack(spacing: 10) {
                ForEach(ThemeMode.allCases) { mode in
                    card(mode)
                }
            }

            Button("Done") { onDone() }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.card)
        .presentationDetents([.medium])
    }

    private func card(_ mode: ThemeMode) -> some View {
        let on = mode == selected
        return Button { themeModeRaw = mode.rawValue } label: {
            HStack(spacing: 14) {
                Image(systemName: mode.symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 42, height: 42)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 1) {
                    Text(mode.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Text(mode.subtitle)
                        .font(.system(size: 13.5))
                        .foregroundStyle(Palette.ink40)
                }
                Spacer()
                if on {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                }
            }
            .padding(14)
            .background(on ? Palette.accentSoft : Palette.field,
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(on ? Color.clear : Palette.ink12, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview { AppearanceSheet(onDone: {}) }
#endif
