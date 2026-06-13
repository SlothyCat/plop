import XCTest
@testable import plop

final class TransactionAggregationTests: XCTestCase {
    func test_signedAmount_expenseIsNegative() {
        let tx = Transaction(amount: Decimal(10), type: .expense, date: .now)
        XCTAssertEqual(signedAmount(tx), Decimal(-10))
    }

    func test_signedAmount_incomeIsPositive() {
        let tx = Transaction(amount: Decimal(10), type: .income, date: .now)
        XCTAssertEqual(signedAmount(tx), Decimal(10))
    }

    func test_netTotal_mixedSum() {
        let txs = [
            Transaction(amount: Decimal(100), type: .income,  date: .now),
            Transaction(amount: Decimal(30),  type: .expense, date: .now),
            Transaction(amount: Decimal(20),  type: .expense, date: .now),
        ]
        XCTAssertEqual(netTotal(of: txs), Decimal(50))
    }

    func test_netTotal_emptyIsZero() {
        XCTAssertEqual(netTotal(of: []), Decimal(0))
    }

    func test_groupByDay_groupsSortsAndSubtotals() {
        let cal = fixedCalendar()
        let early = makeDate(2026, 5, 29, 13, 0, calendar: cal)
        let late  = makeDate(2026, 5, 29, 22, 0, calendar: cal)
        let other = makeDate(2026, 5, 26, 11, 0, calendar: cal)
        let txs = [
            Transaction(amount: Decimal(5),   type: .expense, date: early),
            Transaction(amount: Decimal(612), type: .expense, date: late),
            Transaction(amount: Decimal(4),   type: .expense, date: other),
        ]

        let groups = groupByDay(txs, calendar: cal)

        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0].date, cal.startOfDay(for: late))   // newest day first
        XCTAssertEqual(groups[1].date, cal.startOfDay(for: other))
        XCTAssertEqual(groups[0].transactions.first?.date, late)    // newest time first
        XCTAssertEqual(groups[0].subtotal, Decimal(-617))           // -(5 + 612)
    }
}
