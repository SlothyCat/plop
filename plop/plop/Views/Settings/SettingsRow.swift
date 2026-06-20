import SwiftUI

/// One Settings row: a colored icon tile, a label, an optional trailing value, and a
/// chevron. Used inside NavigationLink labels (showsChevron: false — the link adds its
/// own chevron) and Button labels (showsChevron: true).
struct SettingsRow: View {
    let tile: Color
    let systemImage: String
    let title: String
    var value: String?
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Palette.tileInk)
                .frame(width: 30, height: 30)
                .background(tile, in: RoundedRectangle(cornerRadius: 9))
            Text(title)
                .font(.system(size: 16.5, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer(minLength: 8)
            if let value {
                Text(value).font(.system(size: 15.5)).foregroundStyle(Palette.ink40)
            }
            if showsChevron {
                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#if DEBUG
#Preview {
    List {
        SettingsRow(tile: Palette.accent, systemImage: "chart.pie.fill",
                    title: "Set budget", value: "$1,020", showsChevron: false)
        SettingsRow(tile: Palette.yellow, systemImage: "circle.lefthalf.filled",
                    title: "Theme", value: "Automatic")
    }
}
#endif
