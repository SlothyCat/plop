import Foundation

/// Which transactions an export run covers.
enum ExportRange: Equatable {
    /// The calendar month containing the given date.
    case month(Date)
    case dateRange(ClosedRange<Date>)

    /// True if `date` falls in the range.
    func contains(_ date: Date, calendar: Calendar) -> Bool {
        switch self {
        case .month(let anchor):
            return PeriodFilter.month.range(containing: anchor, calendar: calendar).contains(date)
        case .dateRange(let range):
            return range.contains(date)
        }
    }
}

/// The first day of the month `months` away from the month containing `date`.
func shiftMonth(_ date: Date, by months: Int, calendar: Calendar) -> Date {
    let start = calendar.dateInterval(of: .month, for: date)!.start
    return calendar.date(byAdding: .month, value: months, to: start)!
}
