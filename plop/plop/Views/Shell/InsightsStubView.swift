import SwiftUI

/// Placeholder for the Insights tab (built in a later feature).
struct InsightsStubView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Insights")
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
#Preview { InsightsStubView() }
#endif
