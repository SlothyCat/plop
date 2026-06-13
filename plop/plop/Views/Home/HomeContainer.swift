import SwiftUI
import SwiftData

/// The single SwiftData touch-point for Home: reads transactions via @Query and
/// hands them to the presentational HomeView (which stays array-driven/testable).
/// When Entry saves a transaction (PR5), @Query updates this automatically.
struct HomeContainer: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    var body: some View {
        HomeView(transactions: transactions)
    }
}

#if DEBUG
#Preview {
    // In-memory store seeded with sample data → proves the @Query path renders
    // real persisted rows (not just an injected array).
    HomeContainer().modelContainer(SampleData.previewContainer())
}
#endif
