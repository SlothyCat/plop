import Foundation
import SwiftData
@testable import plop

/// Deterministic calendar for tests: UTC, POSIX locale, Monday-start by default.
func fixedCalendar(firstWeekday: Int = 2) -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    cal.locale = Locale(identifier: "en_US_POSIX")
    cal.firstWeekday = firstWeekday   // 2 = Monday
    return cal
}

func makeDate(_ year: Int, _ month: Int, _ day: Int,
              _ hour: Int = 0, _ minute: Int = 0,
              calendar: Calendar) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day,
                                       hour: hour, minute: minute))!
}

/// Fresh in-memory SwiftData container for data-layer tests.
/// Return the CONTAINER (not just its context): a ModelContext does not strongly
/// retain its container, so a context whose container has gone out of scope traps
/// on the next SwiftData call. Tests keep the returned container alive.
@MainActor
func makeInMemoryContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: Transaction.self, ExpenseCategory.self,
                              configurations: config)
}
