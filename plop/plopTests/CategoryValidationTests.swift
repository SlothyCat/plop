import XCTest
@testable import plop

final class CategoryValidationTests: XCTestCase {
    private func cat(_ name: String) -> ExpenseCategory {
        ExpenseCategory(name: name, symbolName: "tag.fill", colorHex: "#8CC0EB")
    }

    func test_rejectsEmptyOrWhitespace() {
        XCTAssertFalse(isCategoryNameAvailable("   ", existing: []))
    }

    func test_rejectsDuplicateCaseInsensitive() {
        XCTAssertFalse(isCategoryNameAvailable("food", existing: [cat("Food")]))
    }

    func test_allowsUniqueName() {
        XCTAssertTrue(isCategoryNameAvailable("Transport", existing: [cat("Food")]))
    }

    func test_editingKeepsOwnName() {
        let food = cat("Food")
        XCTAssertTrue(isCategoryNameAvailable("Food", existing: [food], editing: food))
    }

    func test_editingToAnothersNameRejected() {
        let food = cat("Food"); let transport = cat("Transport")
        XCTAssertFalse(isCategoryNameAvailable("Food", existing: [food, transport], editing: transport))
    }

    func test_message_nilWhenAvailable() {
        XCTAssertNil(categoryNameMessage(name: "Transport", isAvailable: true))
    }

    func test_message_emptyName() {
        XCTAssertEqual(categoryNameMessage(name: "  ", isAvailable: false), "Enter a name.")
    }

    func test_message_duplicateName() {
        XCTAssertEqual(categoryNameMessage(name: "Food", isAvailable: false),
                       "That name's already taken.")
    }
}
