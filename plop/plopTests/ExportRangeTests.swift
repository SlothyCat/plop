import XCTest
@testable import plop

final class ExportRangeTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    func test_month_includesWholeChosenMonthExcludesNeighbours() {
        let r = ExportRange.month(date(2026, 6, 20))
        XCTAssertTrue(r.contains(date(2026, 6, 1), calendar: utc))
        XCTAssertTrue(r.contains(date(2026, 6, 30), calendar: utc))
        XCTAssertFalse(r.contains(date(2026, 5, 31), calendar: utc))
        XCTAssertFalse(r.contains(date(2026, 7, 1), calendar: utc))
    }

    func test_month_exactBoundaries() {
        let r = ExportRange.month(date(2026, 9, 15))
        let start = utc.date(from: DateComponents(year: 2026, month: 9, day: 1))!
        let nextStart = utc.date(from: DateComponents(year: 2026, month: 10, day: 1))!
        XCTAssertTrue(r.contains(start, calendar: utc))
        XCTAssertTrue(r.contains(nextStart.addingTimeInterval(-1), calendar: utc))
        XCTAssertFalse(r.contains(start.addingTimeInterval(-1), calendar: utc))
        XCTAssertFalse(r.contains(nextStart, calendar: utc))
    }

    func test_dateRange_inclusiveBounds() {
        let r = ExportRange.dateRange(date(2026, 3, 1)...date(2026, 4, 30))
        XCTAssertTrue(r.contains(date(2026, 3, 1), calendar: utc))
        XCTAssertTrue(r.contains(date(2026, 4, 30), calendar: utc))
        XCTAssertFalse(r.contains(date(2026, 2, 28), calendar: utc))
        XCTAssertFalse(r.contains(date(2026, 5, 1), calendar: utc))
    }

    func test_shiftMonth_back_returnsFirstOfPreviousMonth() {
        XCTAssertEqual(shiftMonth(date(2026, 10, 26), by: -1, calendar: utc),
                       utc.date(from: DateComponents(year: 2026, month: 9, day: 1)))
    }

    func test_shiftMonth_crossesYearBoundary() {
        XCTAssertEqual(shiftMonth(date(2026, 1, 31), by: -1, calendar: utc),
                       utc.date(from: DateComponents(year: 2025, month: 12, day: 1)))
        XCTAssertEqual(shiftMonth(date(2025, 12, 5), by: 1, calendar: utc),
                       utc.date(from: DateComponents(year: 2026, month: 1, day: 1)))
    }
}
