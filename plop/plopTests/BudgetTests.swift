import XCTest
import SwiftData
@testable import plop

final class BudgetTests: XCTestCase {

    // MARK: parseBudgetAmount

    func test_parse_empty_isZero() {
        XCTAssertEqual(parseBudgetAmount(""), 0)
    }

    func test_parse_decimal() {
        XCTAssertEqual(parseBudgetAmount("12.50"), Decimal(string: "12.5"))
    }

    func test_parse_stripsSymbolsAndLetters() {
        XCTAssertEqual(parseBudgetAmount("$1,200"), 1200)
        XCTAssertEqual(parseBudgetAmount("abc"), 0)
    }

    // MARK: formatBudgetAmount

    func test_format_zero_isEmpty() {
        XCTAssertEqual(formatBudgetAmount(0), "")
    }

    func test_format_roundTripsNonZero() {
        let value = Decimal(string: "300")!
        XCTAssertEqual(parseBudgetAmount(formatBudgetAmount(value)), value)
    }

    // MARK: BudgetMode

    func test_mode_rawValues() {
        XCTAssertEqual(BudgetMode.general.rawValue, "general")
        XCTAssertEqual(BudgetMode.category.rawValue, "category")
    }

    // MARK: categoryBudgetSum

    func test_categorySum_sumsAndIgnoresZero() throws {
        let cats = [
            ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC", budget: 300),
            ExpenseCategory(name: "Subs", symbolName: "tv", colorHex: "#FFF9D2", budget: 120),
            ExpenseCategory(name: "None", symbolName: "tag", colorHex: "#BFDDF0", budget: 0)
        ]
        XCTAssertEqual(categoryBudgetSum(cats), 420)
    }

    func test_categorySum_emptyIsZero() {
        XCTAssertEqual(categoryBudgetSum([]), 0)
    }

    // MARK: sumBudgetStrings

    func test_sumStrings_parsesEachAndSums() {
        XCTAssertEqual(sumBudgetStrings(["300", "", "120.50", "x"]), Decimal(string: "420.5"))
    }

    // MARK: activeBudgetTotal

    func test_activeTotal_generalUsesString() {
        XCTAssertEqual(activeBudgetTotal(mode: .general, generalBudget: "500", categories: []), 500)
    }

    func test_activeTotal_categoryUsesModelSum() {
        let cats = [
            ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC", budget: 300),
            ExpenseCategory(name: "Subs", symbolName: "tv", colorHex: "#FFF9D2", budget: 120)
        ]
        XCTAssertEqual(activeBudgetTotal(mode: .category, generalBudget: "999", categories: cats), 420)
    }
}
