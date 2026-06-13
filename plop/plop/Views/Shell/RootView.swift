import SwiftUI

/// App routing skeleton: owns tab selection, shows the active screen, and overlays
/// the custom tab bar. Insights/Settings are stubs for now; Home gets [] until PR3.
struct RootView: View {
    enum Tab { case home, insights, settings }
    @State private var selection: Tab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.bg.ignoresSafeArea()

            Group {
                switch selection {
                case .home: HomeView(transactions: [])
                case .insights: InsightsStubView()
                case .settings: SettingsStubView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            TabBarView(selection: $selection, onCenterTap: handleCenterTap)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func handleCenterTap() {
        if selection == .home {
            // TODO(PR4): present the Entry screen here.
        } else {
            selection = .home
        }
    }
}

#if DEBUG
#Preview { RootView() }
#endif
