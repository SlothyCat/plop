import SwiftUI

/// A donut: faint track + one stroked arc per slice (from donutSlices), with a center
/// view. Arcs draw one-at-a-time at constant speed, replaying on appear / slice change.
struct DonutChart<Center: View>: View {
    let slices: [DonutSlice]
    /// Changing this replays the draw even if `slices` are identical (e.g. period toggle).
    var animationKey: AnyHashable = 0
    @ViewBuilder var center: () -> Center

    @State private var animate = false

    private let size: CGFloat = 216
    private let lineWidth: CGFloat = 30
    private let fade = 0.36     // track fade-in
    private let sweep = 1.1     // total ring draw time

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.ink.opacity(0.06), lineWidth: lineWidth)
                .opacity(animate ? 1 : 0)
                .animation(.easeIn(duration: fade), value: animate)

            ForEach(slices) { slice in
                Circle()
                    .trim(from: slice.start, to: animate ? slice.end : slice.start)
                    .stroke(Color(hex: slice.colorHex),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .opacity(animate ? 1 : 0)
                    .animation(
                        .linear(duration: max(0.0001, (slice.end - slice.start) * sweep))
                            .delay(fade + slice.start * sweep),
                        value: animate
                    )
            }

            center()
        }
        .frame(width: size, height: size)
        .onAppear { replay() }
        .onChange(of: animationKey) { _, _ in replay() }
    }

    /// Reset to hidden WITHOUT animating the reverse, then draw forward.
    private func replay() {
        var reset = SwiftUI.Transaction()   // not our @Model Transaction
        reset.disablesAnimations = true
        withTransaction(reset) { animate = false }
        DispatchQueue.main.async { animate = true }
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
