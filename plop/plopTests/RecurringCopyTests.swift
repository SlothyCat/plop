import XCTest
@testable import plop

final class RecurringCopyTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d))!
    }
    private func summary(_ i: RecurrenceInterval, _ d: Date) -> String {
        recurringSummary(interval: i, date: d, calendar: utc)
    }

    func test_none_isEmpty() {
        XCTAssertEqual(summary(.none, day(2026, 6, 18)), "")
    }

    func test_daily() {
        XCTAssertEqual(summary(.daily, day(2026, 6, 18)), "daily")
    }

    func test_weekly_usesWeekdayPlural() {
        XCTAssertEqual(summary(.weekly, day(2026, 1, 1)), "weekly on Thursdays")
    }

    func test_monthly_usesOrdinalDay() {
        XCTAssertEqual(summary(.monthly, day(2026, 6, 18)), "monthly on the 18th")
        XCTAssertEqual(summary(.monthly, day(2026, 6, 1)), "monthly on the 1st")
        XCTAssertEqual(summary(.monthly, day(2026, 6, 2)), "monthly on the 2nd")
        XCTAssertEqual(summary(.monthly, day(2026, 6, 3)), "monthly on the 3rd")
    }

    func test_yearly_usesMonthDay() {
        XCTAssertEqual(summary(.yearly, day(2026, 6, 18)), "yearly on Jun 18")
    }
}
