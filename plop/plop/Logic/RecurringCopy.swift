import Foundation

/// Human summary of a rule's cadence for the Entry chip + the save disclosure.
/// e.g. "monthly on the 18th", "weekly on Thursdays", "daily", "yearly on Jun 18".
/// Pure; uses the supplied calendar (en_US_POSIX for stable English).
func recurringSummary(interval: RecurrenceInterval, date: Date,
                      calendar: Calendar = .current) -> String {
    switch interval {
    case .none:
        return ""
    case .daily:
        return "daily"
    case .weekly:
        return "weekly on \(formatted(date, "EEEE", calendar))s"
    case .monthly:
        return "monthly on the \(ordinal(calendar.component(.day, from: date)))"
    case .yearly:
        return "yearly on \(formatted(date, "MMM d", calendar))"
    }
}

private func formatted(_ date: Date, _ pattern: String, _ calendar: Calendar) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = pattern
    return formatter.string(from: date)
}

private func ordinal(_ n: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
}
