import Foundation

enum PeriodFilter: CaseIterable {
    case week, month, year

    /// Inclusive date range of the period containing `date`, per the given calendar.
    func range(containing date: Date, calendar: Calendar) -> ClosedRange<Date> {
        let component: Calendar.Component
        switch self {
        case .week:  component = .weekOfYear
        case .month: component = .month
        case .year:  component = .year
        }
        let interval = calendar.dateInterval(of: component, for: date)!
        // dateInterval.end is exclusive (start of next period); make it inclusive.
        return interval.start...interval.end.addingTimeInterval(-1)
    }
}
