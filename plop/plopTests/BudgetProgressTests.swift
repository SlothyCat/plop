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

    // MARK: budgetSummary — general flavour

    func test_summary_general_monthTotalsAndRows() {
        let spend = [
            CategorySpend(id: "Food", name: "Food", colorHex: "#FFEBCC", amount: 300),
            CategorySpend(id: "Subs", name: "Subs", colorHex: "#FFF9D2", amount: 120)
        ]
        let s = budgetSummary(spend: spend, categories: [], mode: .general,
                              generalBudget: "1000", period: .month)
        XCTAssertEqual(s.totalBudget, 1000)
        XCTAssertEqual(s.spentBudgeted, 420)
        XCTAssertEqual(s.remaining, 580)
        XCTAssertFalse(s.isOver)
        XCTAssertEqual(s.rows.count, 2)
        XCTAssertEqual(s.donutRows, s.rows)   // general: legend == donut source
    }

    func test_summary_general_yearScalesBudget() {
        let s = budgetSummary(spend: [], categories: [], mode: .general,
                              generalBudget: "1000", period: .year)
        XCTAssertEqual(s.totalBudget, 12000)
    }

    // MARK: budgetSummary — category flavour

    func test_summary_category_totalsOverBudgetedOnly() {
        let cats = [
            ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC", budget: 400),
            ExpenseCategory(name: "Rent", symbolName: "house", colorHex: "#8CC0EB", budget: 600),
            ExpenseCategory(name: "Subs", symbolName: "tv", colorHex: "#FFF9D2", budget: 0)
        ]
        let spend = [
            CategorySpend(id: "Rent", name: "Rent", colorHex: "#8CC0EB", amount: 700),
            CategorySpend(id: "Food", name: "Food", colorHex: "#FFEBCC", amount: 300)
        ]
        let s = budgetSummary(spend: spend, categories: cats, mode: .category,
                              generalBudget: "9999", period: .month)
        XCTAssertEqual(s.totalBudget, 1000)        // 400 + 600 (Subs has none)
        XCTAssertEqual(s.spentBudgeted, 1000)      // 700 + 300
        XCTAssertEqual(s.remaining, 0)
        XCTAssertEqual(s.rows.count, 3)            // all categories appear in the legend
        XCTAssertEqual(s.rows.first?.name, "Rent") // sorted by spent desc
        XCTAssertEqual(s.donutRows.count, 2)       // only budgeted categories
        XCTAssertFalse(s.rows.first(where: { $0.name == "Subs" })!.hasBudget)
    }

    func test_summary_category_yearScalesEachBudget() {
        let cats = [
            ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC", budget: 400)
        ]
        let s = budgetSummary(spend: [], categories: cats, mode: .category,
                              generalBudget: "0", period: .year)
        XCTAssertEqual(s.totalBudget, 4800)        // 400 × 12
    }

    func test_summary_category_omitsUncategorizedSpend() {
        let cats = [
            ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC", budget: 400)
        ]
        let spend = [
            CategorySpend(id: "Food", name: "Food", colorHex: "#FFEBCC", amount: 300),
            CategorySpend(id: uncategorizedSpendID, name: "Uncategorized",
                          colorHex: "#C9CDD2", amount: 999)
        ]
        let s = budgetSummary(spend: spend, categories: cats, mode: .category,
                              generalBudget: "0", period: .month)
        XCTAssertEqual(s.rows.count, 1)            // only the real category
        XCTAssertEqual(s.spentBudgeted, 300)       // uncategorized excluded
    }

    func test_summary_isOver_whenSpentExceedsBudget() {
        let s = budgetSummary(
            spend: [CategorySpend(id: "Food", name: "Food", colorHex: "#FFEBCC", amount: 150)],
            categories: [], mode: .general, generalBudget: "100", period: .month)
        XCTAssertEqual(s.remaining, -50)
        XCTAssertTrue(s.isOver)
    }
}
