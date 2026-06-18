import XCTest
@testable import plop

final class RecurringScheduleTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d))!
    }
    private func due(_ interval: RecurrenceInterval, anchorDay: Int,
                     start: Date, lastGenerated: Date?, asOf: Date) -> [Date] {
        RecurringSchedule.dueOccurrences(interval: interval, anchorDay: anchorDay,
                                         startDate: start, lastGenerated: lastGenerated,
                                         asOf: asOf, calendar: utc)
    }

    func test_none_isEmpty() {
        XCTAssertTrue(due(.none, anchorDay: 1, start: day(2026, 1, 1),
                          lastGenerated: nil, asOf: day(2026, 12, 1)).isEmpty)
    }

    func test_monthly_normalAnchor() {
        let result = due(.monthly, anchorDay: 5, start: day(2026, 1, 3),
                         lastGenerated: nil, asOf: day(2026, 4, 10))
        XCTAssertEqual(result, [day(2026, 1, 5), day(2026, 2, 5),
                                day(2026, 3, 5), day(2026, 4, 5)])
    }

    func test_monthly_clampsToMonthEnd() {
        let result = due(.monthly, anchorDay: 31, start: day(2026, 1, 31),
                         lastGenerated: nil, asOf: day(2026, 4, 30))
        XCTAssertEqual(result, [day(2026, 1, 31), day(2026, 2, 28),
                                day(2026, 3, 31), day(2026, 4, 30)])
    }

    func test_monthly_firstOccurrenceAfterStart() {
        let result = due(.monthly, anchorDay: 5, start: day(2026, 6, 18),
                         lastGenerated: nil, asOf: day(2026, 8, 31))
        XCTAssertEqual(result, [day(2026, 7, 5), day(2026, 8, 5)])
    }

    func test_daily() {
        let result = due(.daily, anchorDay: 1, start: day(2026, 1, 1),
                         lastGenerated: nil, asOf: day(2026, 1, 4))
        XCTAssertEqual(result, [day(2026, 1, 1), day(2026, 1, 2),
                                day(2026, 1, 3), day(2026, 1, 4)])
    }

    func test_weekly_keepsWeekday() {
        let result = due(.weekly, anchorDay: 1, start: day(2026, 1, 1),
                         lastGenerated: nil, asOf: day(2026, 1, 22))
        XCTAssertEqual(result, [day(2026, 1, 1), day(2026, 1, 8),
                                day(2026, 1, 15), day(2026, 1, 22)])
    }

    func test_yearly_leapClamp() {
        let result = due(.yearly, anchorDay: 1, start: day(2024, 2, 29),
                         lastGenerated: nil, asOf: day(2028, 3, 1))
        XCTAssertEqual(result, [day(2024, 2, 29), day(2025, 2, 28),
                                day(2026, 2, 28), day(2027, 2, 28), day(2028, 2, 29)])
    }

    func test_lastGenerated_isExclusiveBoundary() {
        let result = due(.monthly, anchorDay: 5, start: day(2026, 1, 5),
                         lastGenerated: day(2026, 2, 5), asOf: day(2026, 4, 5))
        XCTAssertEqual(result, [day(2026, 3, 5), day(2026, 4, 5)])
    }

    func test_catchUp_yearGapDaily() {
        let result = due(.daily, anchorDay: 1, start: day(2025, 6, 18),
                         lastGenerated: day(2025, 6, 18), asOf: day(2026, 6, 18))
        XCTAssertEqual(result.count, 365)
        XCTAssertEqual(result.first, day(2025, 6, 19))
        XCTAssertEqual(result.last, day(2026, 6, 18))
    }

    func test_asOfBeforeFirstOccurrence_isEmpty() {
        let result = due(.monthly, anchorDay: 5, start: day(2026, 6, 18),
                         lastGenerated: nil, asOf: day(2026, 6, 30))
        XCTAssertTrue(result.isEmpty)
    }
}
