import SwiftUI

/// The Home screen. Presentational: it renders whatever transactions it's handed
/// (previews inject sample data; the app passes [] until PR3 wires @Query).
struct HomeView: View {
    let transactions: [Transaction]
    @State private var period: PeriodFilter = .month

    var body: some View {
        let range = period.range(containing: .now, calendar: .current)
        let inRange = transactions.filter { range.contains($0.date) }
        let groups = groupByDay(inRange, calendar: .current)
        let net = netTotal(of: inRange)

        VStack(spacing: 0) {
            HStack {
                Spacer()
                FilterMenu(period: $period)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)

            NetTotalHeader(net: net, period: period)
                .padding(.vertical, 18)

            if groups.isEmpty {
                Spacer()
                Text("No transactions \(periodPill).")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.ink40)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(groups, id: \.date) { group in
                            DayCard(group: group)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 150)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.bg)
    }

    private var periodPill: String {
        switch period {
        case .week: return "this week"
        case .month: return "this month"
        case .year: return "this year"
        }
    }
}

#if DEBUG
#Preview("Populated") {
    HomeView(transactions: SampleData.transactions())
}

#Preview("Empty") {
    HomeView(transactions: [])
}
#endif
