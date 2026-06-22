import XCTest
@testable import plop

final class SpendAggregationTests: XCTestCase {
    private let cal = fixedCalendar()
    private var monthRange: ClosedRange<Date> {
        PeriodFilter.month.range(containing: makeDate(2026, 5, 15, calendar: cal), calendar: cal)
    }
    private func cat(_ name: String, _ color: String) -> ExpenseCategory {
        ExpenseCategory(name: name, symbolName: "tag", colorHex: color)
    }

    // MARK: spendByCategory

    func test_spendByCategory_sumsExpensesPerCategory_largestFirst() {
        let food = cat("Food", "#FFEBCC")
        let school = cat("School", "#8CC0EB")
        let txs = [
            Transaction(amount: 10, type: .expense, date: makeDate(2026, 5, 10, calendar: cal), category: food),
            Transaction(amount: 5,  type: .expense, date: makeDate(2026, 5, 11, calendar: cal), category: food),
            Transaction(amount: 30, type: .expense, date: makeDate(2026, 5, 12, calendar: cal), category: school),
        ]
        let result = spendByCategory(txs, in: monthRange)
        XCTAssertEqual(result.map(\.name), ["School", "Food"])   // largest first
        XCTAssertEqual(result.first?.amount, Decimal(30))
        XCTAssertEqual(result.last?.amount, Decimal(15))
    }

    func test_spendByCategory_excludesIncome() {
        let school = cat("School", "#8CC0EB")
        let txs = [
            Transaction(amount: 1000, type: .income,  date: makeDate(2026, 5, 5, calendar: cal), category: school),
            Transaction(amount: 20,   type: .expense, date: makeDate(2026, 5, 6, calendar: cal), category: school),
        ]
        let result = spendByCategory(txs, in: monthRange)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.amount, Decimal(20))
    }

    func test_spendByCategory_excludesOutOfRange() {
        let food = cat("Food", "#FFEBCC")
        let txs = [
            Transaction(amount: 20, type: .expense, date: makeDate(2026, 5, 6, calendar: cal), category: food),
            Transaction(amount: 99, type: .expense, date: makeDate(2026, 3, 1, calendar: cal), category: food),
        ]
        XCTAssertEqual(totalSpent(spendByCategory(txs, in: monthRange)), Decimal(20))
    }

    func test_spendByCategory_bucketsUncategorized() {
        let txs = [
            Transaction(amount: 7, type: .expense, date: makeDate(2026, 5, 6, calendar: cal), category: nil),
        ]
        let result = spendByCategory(txs, in: monthRange)
        XCTAssertEqual(result.first?.id, "__uncategorized__")
        XCTAssertEqual(result.first?.name, "Uncategorized")
        XCTAssertEqual(result.first?.amount, Decimal(7))
    }

    // MARK: totalSpent

    func test_totalSpent_sumsAllSlices() {
        let spend = [
            CategorySpend(id: "a", name: "A", colorHex: "#000000", amount: 30),
            CategorySpend(id: "b", name: "B", colorHex: "#000000", amount: 12),
        ]
        XCTAssertEqual(totalSpent(spend), Decimal(42))
    }

    func test_totalSpent_emptyIsZero() {
        XCTAssertEqual(totalSpent([]), Decimal(0))
    }

    // MARK: donutSlices

    func test_donutSlices_emptyWhenNoSpend() {
        XCTAssertTrue(donutSlices(from: []).isEmpty)
    }

    func test_donutSlices_singleSliceSpansRingMinusGap() {
        let spend = [CategorySpend(id: "a", name: "A", colorHex: "#000000", amount: 10)]
        let slices = donutSlices(from: spend, gap: 0.02)
        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices[0].start, 0.01, accuracy: 0.0001)   // gap/2
        XCTAssertEqual(slices[0].end, 0.99, accuracy: 0.0001)     // 1 - gap/2
    }

    func test_donutSlices_cumulativeAndOrdered() {
        let spend = [
            CategorySpend(id: "a", name: "A", colorHex: "#000000", amount: 75),
            CategorySpend(id: "b", name: "B", colorHex: "#111111", amount: 25),
        ]
        let slices = donutSlices(from: spend, gap: 0.0)   // no gap → exact boundaries
        XCTAssertEqual(slices.map(\.id), ["a", "b"])
        XCTAssertEqual(slices[0].start, 0.0,  accuracy: 0.0001)
        XCTAssertEqual(slices[0].end,   0.75, accuracy: 0.0001)
        XCTAssertEqual(slices[1].start, 0.75, accuracy: 0.0001)
        XCTAssertEqual(slices[1].end,   1.0,  accuracy: 0.0001)
    }

    func test_minArcAdjusted_noOpWhenAllAboveMin() {
        XCTAssertEqual(minArcAdjusted([0.75, 0.25], minArc: 0.03), [0.75, 0.25])
    }

    func test_minArcAdjusted_bumpsTinyAndStealsFromLarge() {
        let out = minArcAdjusted([0.99, 0.01], minArc: 0.03)
        XCTAssertEqual(out[1], 0.03, accuracy: 0.0001)
        XCTAssertEqual(out[0], 0.97, accuracy: 0.0001)
        XCTAssertEqual(out.reduce(0, +), 1.0, accuracy: 0.0001)
    }

    func test_donutSlices_tinySliceStaysVisible() {
        let spend = [
            CategorySpend(id: "a", name: "A", colorHex: "#000000", amount: 99),
            CategorySpend(id: "b", name: "B", colorHex: "#111111", amount: 1),
        ]
        let slices = donutSlices(from: spend, gap: 0.0)
        XCTAssertGreaterThanOrEqual(slices[1].end - slices[1].start, 0.029)
    }
}
