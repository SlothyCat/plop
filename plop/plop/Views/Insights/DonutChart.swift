import SwiftUI

/// A static donut: faint track + one stroked arc per slice (from donutSlices), with a
/// center view. The sequential draw animation is added in PR3.
struct DonutChart<Center: View>: View {
    let slices: [DonutSlice]
    @ViewBuilder var center: () -> Center

    private let size: CGFloat = 216
    private let lineWidth: CGFloat = 30

    var body: some View {
        ZStack {
            Circle().stroke(Palette.ink.opacity(0.06), lineWidth: lineWidth)
            ForEach(slices) { slice in
                Circle()
                    .trim(from: slice.start, to: slice.end)
                    .stroke(Color(hex: slice.colorHex),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            center()
        }
        .frame(width: size, height: size)
    }
}

#if DEBUG
#Preview {
    let spend = spendByCategory(SampleData.transactions(),
                                in: PeriodFilter.month.range(containing: .now, calendar: .current))
    return DonutChart(slices: donutSlices(from: spend)) {
        Text("SPENT").font(.caption)
    }
    .padding()
}
#endif
