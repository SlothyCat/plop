import XCTest
@testable import plop

final class CategoryIconsTests: XCTestCase {
    func test_iconsNonEmptyAndUnique() {
        XCTAssertFalse(categoryIconChoices.isEmpty)
        XCTAssertEqual(categoryIconChoices.count, Set(categoryIconChoices).count)
    }
}
