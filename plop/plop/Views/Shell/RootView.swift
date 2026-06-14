import SwiftUI
import SwiftData

/// App routing skeleton: owns tab selection, shows the active screen, and overlays
/// the custom tab bar. Insights/Settings are stubs for now; Home reads via @Query.
struct RootView: View {
    enum Tab { case home, insights, settings }
    @State private var selection: Tab = .home
    @State private var showingEntry = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.bg.ignoresSafeArea()

            Group {
                switch selection {
                case .home: HomeContainer()
                case .insights: InsightsContainer()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            TabBarView(selection: $selection, onCenterTap: handleCenterTap)
                .ignoresSafeArea(edges: .bottom)
        }
        .fullScreenCover(isPresented: $showingEntry) {
            EntryView()
        }
    }

    private func handleCenterTap() {
        if selection == .home {
            showingEntry = true
        } else {
            selection = .home
        }
    }
}

#if DEBUG
#Preview {
    RootView().modelContainer(SampleData.previewContainer())
}
#endif
