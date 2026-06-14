import XCTest
@testable import plop

final class FormattingTests: XCTestCase {
    func test_money_unsignedNegativeShowsMinus() {
        let s = formattedMoney(Decimal(-612), signed: false, currencyCode: "USD")
        XCTAssertTrue(s.hasPrefix("-"), s)
        XCTAssertTrue(s.contains("612"), s)
    }

    func test_money_signedPositiveShowsPlus() {
        let s = formattedMoney(Decimal(1200), signed: true, currencyCode: "USD")
        XCTAssertTrue(s.hasPrefix("+"), s)
        XCTAssertTrue(s.contains("200"), s)
    }

    func test_dayLabel_todayAndYesterday() {
        let cal = fixedCalendar()
        let today = makeDate(2026, 5, 30, 9, 0, calendar: cal)
        XCTAssertEqual(dayLabel(for: makeDate(2026, 5, 30, 1, 0, calendar: cal),
                                relativeTo: today, calendar: cal), "TODAY")
        XCTAssertEqual(dayLabel(for: makeDate(2026, 5, 29, 1, 0, calendar: cal),
                                relativeTo: today, calendar: cal), "YESTERDAY")
    }

    func test_dayLabel_olderDateUsesWeekdayFormat() {
        let cal = fixedCalendar()
        let today = makeDate(2026, 5, 30, 9, 0, calendar: cal)
        let label = dayLabel(for: makeDate(2026, 5, 26, 1, 0, calendar: cal),
                             relativeTo: today, calendar: cal)
        XCTAssertTrue(label.hasSuffix("26 MAY"), "got \(label)")
        XCTAssertTrue(label.contains(", "))
    }
}
