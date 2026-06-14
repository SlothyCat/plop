import SwiftUI

/// Presentational Insights screen: header + period toggle, donut, legend, empty state.
struct InsightsView: View {
    let transactions: [Transaction]
    @State private var period: PeriodFilter = .month
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()

    var body: some View {
        let range = period.range(containing: .now, calendar: .current)
        let spend = spendByCategory(transactions, in: range)
        let total = totalSpent(spend)
        let slices = donutSlices(from: spend)

        VStack(spacing: 0) {
            HStack {
                Text("Insights")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Spacer()
                InsightsPeriodToggle(period: $period)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)

            ScrollView {
                DonutChart(slices: slices, animationKey: period) {
                    VStack(spacing: 3) {
                        Text("SPENT")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(0.5)
                            .foregroundStyle(Palette.ink40)
                        Text(formattedMoney(total, currencyCode: currencyCode))
                            .font(.system(size: 30, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(Palette.ink)
                    }
                }
                .padding(.vertical, 26)

                if spend.isEmpty {
                    Text("No spending \(period == .year ? "this year" : "this month").")
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.ink40)
                        .padding(.top, 30)
                } else {
                    SpendLegend(spend: spend, total: total)
                        .padding(.horizontal, 18)
                }
            }
            .padding(.bottom, 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.bg)
    }
}

#if DEBUG
#Preview("Populated") { InsightsView(transactions: SampleData.transactions()) }
#Preview("Empty") { InsightsView(transactions: []) }
#endif
