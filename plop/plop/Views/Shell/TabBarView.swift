import SwiftUI

/// Custom bottom tab bar: Insights (left) · raised center button · Settings (right).
/// The center button is context-aware — "+" on Home (add), "house" elsewhere (return home).
struct TabBarView: View {
    @Binding var selection: RootView.Tab
    var onCenterTap: () -> Void

    var body: some View {
        ZStack {
            HStack {
                tabButton(.insights, systemImage: "chart.bar", label: "Insights")
                Spacer()
                tabButton(.settings, systemImage: "gearshape", label: "Settings")
            }
            .padding(.horizontal, 44)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 14)
            .background(.ultraThinMaterial)
            .overlay(Rectangle().fill(Palette.hair).frame(height: 1), alignment: .top)

            centerButton.offset(y: -18)
        }
        .frame(height: 92)
    }

    private func tabButton(_ tab: RootView.Tab, systemImage: String, label: String) -> some View {
        let on = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: on ? .semibold : .regular))
                Text(label)
                    .font(.system(size: 10.5, weight: on ? .semibold : .medium))
            }
            .foregroundStyle(on ? Palette.ink : Palette.ink40)
        }
    }

    private var centerButton: some View {
        Button(action: onCenterTap) {
            Image(systemName: selection == .home ? "plus" : "house.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Palette.tileInk)
                .frame(width: 64, height: 64)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
                .shadow(color: Palette.accent.opacity(0.5), radius: 10, y: 3)
        }
    }
}
