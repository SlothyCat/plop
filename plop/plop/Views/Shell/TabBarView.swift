import SwiftUI

/// Custom bottom tab bar: Insights (left) · raised center button · Settings (right).
/// The center button is context-aware — "+" on Home (add), "house" elsewhere (return
/// home) — and radiates a soft halo on Home (the handoff `addhalo` pulse).
struct TabBarView: View {
    @Binding var selection: RootView.Tab
    var onCenterTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                tabButton(.insights, systemImage: "chart.bar.fill", label: "Insights")
                    .frame(maxWidth: .infinity)
                Color.clear.frame(width: 84)
                tabButton(.settings, systemImage: "gearshape.fill", label: "Settings")
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            center
        }
        .frame(height: 60)
        .background(
            Rectangle()
                .fill(.regularMaterial)
                .overlay(Rectangle().fill(Palette.hair).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
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

    // MARK: center button + halo

    private struct Halo: Equatable {
        var scale = 1.0
        var opacity = 0.5
    }

    private var center: some View {
        ZStack {
            if selection == .home && !reduceMotion {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .fill(Palette.accent)
                    .frame(width: 64, height: 64)
                    .keyframeAnimator(initialValue: Halo(), repeating: true) { view, value in
                        view.scaleEffect(value.scale).opacity(value.opacity)
                    } keyframes: { _ in
                        KeyframeTrack(\.scale) {
                            LinearKeyframe(1.0, duration: 0.01)
                            CubicKeyframe(1.5, duration: 2.8 * 0.69)
                            LinearKeyframe(1.5, duration: 2.8 * 0.30)
                        }
                        KeyframeTrack(\.opacity) {
                            LinearKeyframe(0.5, duration: 0.01)
                            CubicKeyframe(0.0, duration: 2.8 * 0.69)
                            LinearKeyframe(0.0, duration: 2.8 * 0.30)
                        }
                    }
                    .offset(y: -18)
                    .allowsHitTesting(false)
            }
            centerButton.offset(y: -18)
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
        .accessibilityIdentifier("centerButton")
    }
}
