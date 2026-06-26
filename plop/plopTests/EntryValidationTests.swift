import XCTest
@testable import plop

final class EntryValidationTests: XCTestCase {
    func test_validWhenAmountAndCategoryPresent() {
        XCTAssertNil(entryValidationMessage(hasAmount: true, hasCategory: true))
    }

    func test_missingAmountOnly() {
        XCTAssertEqual(entryValidationMessage(hasAmount: false, hasCategory: true),
                       "Enter an amount.")
    }

    func test_missingCategoryOnly() {
        XCTAssertEqual(entryValidationMessage(hasAmount: true, hasCategory: false),
                       "Pick a category.")
    }

    func test_missingBoth() {
        XCTAssertEqual(entryValidationMessage(hasAmount: false, hasCategory: false),
                       "Enter an amount and pick a category.")
    }
}
