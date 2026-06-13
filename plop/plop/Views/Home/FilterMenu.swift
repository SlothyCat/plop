import SwiftUI

/// Top-bar period filter: a menu of Week / Month / Year with the active row checked.
struct FilterMenu: View {
    @Binding var period: PeriodFilter

    var body: some View {
        Menu {
            ForEach(options, id: \.value) { option in
                Button {
                    period = option.value
                } label: {
                    if period == option.value {
                        Label(option.label, systemImage: "checkmark")
                    } else {
                        Text(option.label)
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: 42, height: 42)
        }
    }

    private var options: [(value: PeriodFilter, label: String)] {
        [(.week, "Week"), (.month, "Month"), (.year, "Year")]
    }
}

#if DEBUG
#Preview {
    @Previewable @State var period: PeriodFilter = .month
    return FilterMenu(period: $period)
}
#endif
