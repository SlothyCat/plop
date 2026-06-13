import XCTest
@testable import plop

final class PeriodFilterTests: XCTestCase {
    func test_month_coversWholeMonth() {
        let cal = fixedCalendar()
        let anchor = makeDate(2026, 5, 15, 12, 0, calendar: cal)
        let range = PeriodFilter.month.range(containing: anchor, calendar: cal)
        XCTAssertEqual(range.lowerBound, makeDate(2026, 5, 1, calendar: cal))
        let june1 = makeDate(2026, 6, 1, calendar: cal)
        XCTAssertEqual(range.upperBound, june1.addingTimeInterval(-1))
    }

    func test_year_coversWholeYear() {
        let cal = fixedCalendar()
        let anchor = makeDate(2026, 7, 4, calendar: cal)
        let range = PeriodFilter.year.range(containing: anchor, calendar: cal)
        XCTAssertEqual(range.lowerBound, makeDate(2026, 1, 1, calendar: cal))
        let nextYear = makeDate(2027, 1, 1, calendar: cal)
        XCTAssertEqual(range.upperBound, nextYear.addingTimeInterval(-1))
    }

    func test_week_isSevenDaysStartingMonday() {
        let cal = fixedCalendar(firstWeekday: 2)
        let anchor = makeDate(2026, 5, 30, 12, 0, calendar: cal)
        let range = PeriodFilter.week.range(containing: anchor, calendar: cal)
        XCTAssertTrue(range.contains(anchor))
        XCTAssertEqual(cal.component(.weekday, from: range.lowerBound), 2) // Monday
        let days = cal.dateComponents([.day], from: range.lowerBound,
                                      to: range.upperBound).day
        XCTAssertEqual(days, 6) // 6 whole days + remainder seconds = inclusive 7-day span
    }
}
