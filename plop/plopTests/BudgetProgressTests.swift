import XCTest
@testable import plop

final class BudgetProgressTests: XCTestCase {

    // MARK: periodBudgetMultiplier

    func test_multiplier_monthIsOne_yearIsTwelve() {
        XCTAssertEqual(periodBudgetMultiplier(.month), 1)
        XCTAssertEqual(periodBudgetMultiplier(.week), 1)
        XCTAssertEqual(periodBudgetMultiplier(.year), 12)
    }

    // MARK: CategoryBudgetProgress derived properties

    func test_progress_underBudget() {
        let row = CategoryBudgetProgress(id: "Food", name: "Food", colorHex: "#FFEBCC",
                                         spent: 75, budget: 100)
        XCTAssertTrue(row.hasBudget)
        XCTAssertFalse(row.isOver)
        XCTAssertEqual(row.fraction, 0.75, accuracy: 0.0001)
    }

    func test_progress_overBudget() {
        let row = CategoryBudgetProgress(id: "Rent", name: "Rent", colorHex: "#8CC0EB",
                                         spent: 120, budget: 100)
        XCTAssertTrue(row.isOver)
        XCTAssertEqual(row.fraction, 1.2, accuracy: 0.0001)
    }

    func test_progress_noBudget() {
        let row = CategoryBudgetProgress(id: "Subs", name: "Subs", colorHex: "#FFF9D2",
                                         spent: 30, budget: 0)
        XCTAssertFalse(row.hasBudget)
        XCTAssertFalse(row.isOver)
        XCTAssertEqual(row.fraction, 0, accuracy: 0.0001)
    }
}
