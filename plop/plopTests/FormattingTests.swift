import XCTest
@testable import plop

final class FormattingTests: XCTestCase {
    private let enUS = Locale(identifier: "en_US")

    func test_money_unsignedNegativeShowsMinus() {
        XCTAssertEqual(formattedMoney(Decimal(-612), signed: false, locale: enUS), "-$612.00")
    }

    func test_money_signedPositiveShowsPlus() {
        XCTAssertEqual(formattedMoney(Decimal(1200), signed: true, locale: enUS), "+$1,200.00")
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
