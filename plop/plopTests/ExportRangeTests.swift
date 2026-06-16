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

    func test_thisMonth_includesSameMonthExcludesOthers() {
        let now = date(2026, 6, 15)
        let r = ExportRange.thisMonth
        XCTAssertTrue(r.contains(date(2026, 6, 1), now: now, calendar: utc))
        XCTAssertTrue(r.contains(date(2026, 6, 30), now: now, calendar: utc))
        XCTAssertFalse(r.contains(date(2026, 5, 31), now: now, calendar: utc))
        XCTAssertFalse(r.contains(date(2026, 7, 1), now: now, calendar: utc))
    }

    func test_dateRange_inclusiveBounds() {
        let r = ExportRange.dateRange(date(2026, 3, 1)...date(2026, 4, 30))
        let now = date(2026, 6, 15)
        XCTAssertTrue(r.contains(date(2026, 3, 1), now: now, calendar: utc))
        XCTAssertTrue(r.contains(date(2026, 4, 30), now: now, calendar: utc))
        XCTAssertFalse(r.contains(date(2026, 2, 28), now: now, calendar: utc))
        XCTAssertFalse(r.contains(date(2026, 5, 1), now: now, calendar: utc))
    }
}
