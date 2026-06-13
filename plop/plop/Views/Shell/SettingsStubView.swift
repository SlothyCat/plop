import SwiftUI

/// Placeholder for the Settings tab (built in a later feature).
struct SettingsStubView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Settings")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text("Coming soon")
                .font(.system(size: 15))
                .foregroundStyle(Palette.ink40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.bg)
    }
}

#if DEBUG
#Preview { SettingsStubView() }
#endif
