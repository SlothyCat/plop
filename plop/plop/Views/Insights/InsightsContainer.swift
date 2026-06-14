import SwiftUI
import SwiftData

/// Reads transactions from SwiftData and feeds the presentational InsightsView.
struct InsightsContainer: View {
    @Query private var transactions: [Transaction]

    var body: some View {
        InsightsView(transactions: transactions)
    }
}

#if DEBUG
#Preview {
    InsightsContainer().modelContainer(SampleData.previewContainer())
}
#endif
