import Foundation

/// Pure occurrence-date math for recurring rules — no SwiftData, no side effects.
/// All results are start-of-day in the supplied calendar. The generation engine
/// (SP2) consumes `dueOccurrences` to insert occurrences and advance state.
enum RecurringSchedule {

    /// Occurrence dates due strictly after `lastGenerated` (or from the first
    /// occurrence when nil) and on/before `asOf`, ascending. Returns all (no cap).
    static func dueOccurrences(interval: RecurrenceInterval, anchorDay: Int,
                               startDate: Date, lastGenerated: Date?, asOf: Date,
                               calendar: Calendar = .current) -> [Date] {
        guard interval != .none else { return [] }
        let cap = calendar.startOfDay(for: asOf)
        let after = lastGenerated.map { calendar.startOfDay(for: $0) }

        var result: [Date] = []
        var index = 0
        while true {
            let date = occurrence(index: index, interval: interval, anchorDay: anchorDay,
                                  startDate: startDate, calendar: calendar)
            if date > cap { break }
            if after == nil || date > after! { result.append(date) }
            index += 1
        }
        return result
    }

    /// The 0-based index-th occurrence of the sequence.
    static func occurrence(index: Int, interval: RecurrenceInterval, anchorDay: Int,
                           startDate: Date, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: startDate)
        switch interval {
        case .none:
            return start
        case .daily:
            return calendar.date(byAdding: .day, value: index, to: start)!
        case .weekly:
            return calendar.date(byAdding: .day, value: index * 7, to: start)!
        case .monthly:
            let first = firstMonthly(anchorDay: anchorDay, onOrAfter: start, calendar: calendar)
            var comps = calendar.dateComponents([.year, .month], from: first)
            comps.month = (comps.month ?? 1) + index
            return clampDay(anchorDay, inMonthOf: comps, calendar: calendar)
        case .yearly:
            let target = calendar.date(byAdding: .year, value: index, to: start)!
            let comps = calendar.dateComponents([.year, .month], from: target)
            return clampDay(calendar.component(.day, from: start), inMonthOf: comps,
                            calendar: calendar)
        }
    }

    // MARK: helpers

    /// First date on `anchorDay` (clamped to month length) that is >= `start`.
    private static func firstMonthly(anchorDay: Int, onOrAfter start: Date,
                                     calendar: Calendar) -> Date {
        let thisMonth = clampDay(anchorDay,
                                 inMonthOf: calendar.dateComponents([.year, .month], from: start),
                                 calendar: calendar)
        if thisMonth >= start { return thisMonth }
        let next = calendar.date(byAdding: .month, value: 1, to: start)!
        return clampDay(anchorDay,
                        inMonthOf: calendar.dateComponents([.year, .month], from: next),
                        calendar: calendar)
    }

    /// `day`, clamped to the length of the month in `monthComps` (year + month),
    /// as a start-of-day date. `monthComps.month` may be out of 1...12 — Calendar
    /// normalizes it into the correct year.
    private static func clampDay(_ day: Int, inMonthOf monthComps: DateComponents,
                                 calendar: Calendar) -> Date {
        var comps = DateComponents()
        comps.year = monthComps.year
        comps.month = monthComps.month
        comps.day = 1
        let monthStart = calendar.date(from: comps)!
        let length = calendar.range(of: .day, in: .month, for: monthStart)!.count
        comps.day = min(max(day, 1), length)
        return calendar.startOfDay(for: calendar.date(from: comps)!)
    }
}
