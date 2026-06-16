import XCTest
@testable import plop

final class SheetBuilderTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }
    private func cat(_ name: String, budget: Decimal = 0) -> ExpenseCategory {
        ExpenseCategory(name: name, symbolName: "tag", colorHex: "#FFEBCC", budget: budget)
    }
    private func tx(_ amount: Decimal, _ type: TransactionType, _ date: Date,
                    note: String = "", category: ExpenseCategory? = nil) -> Transaction {
        Transaction(amount: amount, type: type, date: date, note: note, category: category)
    }

    private func options(_ range: ExportRange, mode: BudgetMode = .category,
                         general: String = "") -> ExportOptions {
        ExportOptions(range: range, budgetMode: mode, generalBudget: general,
                      currencyCode: "USD", now: day(2026, 6, 15), calendar: utc)
    }

    private func build(_ txs: [Transaction], _ cats: [ExpenseCategory],
                       range: ExportRange = .dateRange(Date.distantPast...Date.distantFuture))
        -> [MonthSheet] {
        buildExportSheets(transactions: txs, categories: cats, options: options(range))
    }

    func test_groupsByYearMonth_sortedWithTabTitles() {
        let food = cat("Food", budget: 400)
        let sheets = build([
            tx(10, .expense, day(2026, 5, 3), category: food),
            tx(20, .expense, day(2026, 6, 4), category: food),
            tx(30, .expense, day(2025, 12, 1), category: food)
        ], [food])
        XCTAssertEqual(sheets.map(\.tabTitle), ["2025-12", "2026-05", "2026-06"])
    }

    func test_monthSummary_totalsAndNet() {
        let food = cat("Food", budget: 400)
        let sheets = build([
            tx(100, .expense, day(2026, 6, 4), category: food),
            tx(300, .income, day(2026, 6, 5))
        ], [food])
        let june = sheets.first { $0.tabTitle == "2026-06" }!
        XCTAssertEqual(june.values[0], ["June 2026"])
        XCTAssertEqual(june.values[1], ["Total expense", "100"])
        XCTAssertEqual(june.values[2], ["Total income", "300"])
        XCTAssertEqual(june.values[3], ["Net", "200"])
        XCTAssertEqual(june.values[4], ["Total budget", "400"])
        XCTAssertEqual(june.values[5], ["Budget left", "300"])
    }

    func test_categoryBlock_budgetBlankWhenUnset_sortedDesc() {
        let food = cat("Food", budget: 400)
        let coffee = cat("Coffee")
        let sheets = build([
            tx(120, .expense, day(2026, 6, 4), category: food),
            tx(50, .expense, day(2026, 6, 6), category: coffee)
        ], [food, coffee])
        let v = sheets[0].values
        let header = v.firstIndex(of: ["Category", "Spent", "Budget", "Left"])!
        XCTAssertEqual(v[header + 1], ["Food", "120", "400", "280"])
        XCTAssertEqual(v[header + 2], ["Coffee", "50", "", ""])
    }

    func test_transactionRows_isoDateTypeAndCurrencyHeader() {
        let food = cat("Food", budget: 400)
        let sheets = build([tx(12.5, .expense, day(2026, 6, 4), note: "Lunch", category: food)], [food])
        let v = sheets[0].values
        let h = v.firstIndex(of: ["Date", "Category", "Note", "Type", "Amount (USD)"])!
        XCTAssertEqual(v[h + 1], ["2026-06-04", "Food", "Lunch", "Expense", "12.5"])
    }

    func test_uncategorizedExpense_labelled() {
        let sheets = build([tx(9, .expense, day(2026, 6, 4))], [])
        let v = sheets[0].values
        XCTAssertTrue(v.contains(["Uncategorized", "9", "", ""]))
    }

    func test_rangeFiltersOutOfRange() {
        let food = cat("Food", budget: 400)
        let sheets = build([
            tx(10, .expense, day(2026, 6, 4), category: food),
            tx(99, .expense, day(2026, 1, 4), category: food)
        ], [food], range: .thisMonth)
        XCTAssertEqual(sheets.map(\.tabTitle), ["2026-06"])
    }

    func test_generalBudget_usesParsedTotal() {
        let sheets = buildExportSheets(
            transactions: [tx(100, .expense, day(2026, 6, 4))],
            categories: [],
            options: options(.dateRange(Date.distantPast...Date.distantFuture),
                             mode: .general, general: "1000"))
        XCTAssertEqual(sheets[0].values[4], ["Total budget", "1000"])
        XCTAssertEqual(sheets[0].values[5], ["Budget left", "900"])
    }

    func test_transactions_newestDateFirst() {
        let food = cat("Food", budget: 400)
        let sheets = build([
            tx(10, .expense, day(2026, 6, 2), note: "older", category: food),
            tx(20, .expense, day(2026, 6, 9), note: "newer", category: food)
        ], [food])
        let v = sheets[0].values
        let h = v.firstIndex(of: ["Date", "Category", "Note", "Type", "Amount (USD)"])!
        XCTAssertEqual(v[h + 1][2], "newer")
        XCTAssertEqual(v[h + 2][2], "older")
    }
}
