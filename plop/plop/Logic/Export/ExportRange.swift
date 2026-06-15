import Foundation

/// Which transactions an export run covers.
enum ExportRange: Equatable {
    case thisMonth
    case dateRange(ClosedRange<Date>)

    /// True if `date` falls in the range. `now`/`calendar` resolve `.thisMonth`.
    func contains(_ date: Date, now: Date, calendar: Calendar) -> Bool {
        switch self {
        case .thisMonth:
            return PeriodFilter.month.range(containing: now, calendar: calendar).contains(date)
        case .dateRange(let range):
            return range.contains(date)
        }
    }
}
