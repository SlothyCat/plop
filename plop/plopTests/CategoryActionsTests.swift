import XCTest
import SwiftData
@testable import plop

@MainActor
final class CategoryActionsTests: XCTestCase {
    func test_add_insertsCategory() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        CategoryActions.add(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC", in: ctx)
        try ctx.save()

        let cats = try ctx.fetch(FetchDescriptor<ExpenseCategory>())
        XCTAssertEqual(cats.count, 1)
        XCTAssertEqual(cats.first?.name, "Food")
        XCTAssertEqual(cats.first?.symbolName, "fork.knife")
        XCTAssertEqual(cats.first?.colorHex, "#FFEBCC")
    }

    func test_update_mutatesFields() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let cat = ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC")
        ctx.insert(cat)

        CategoryActions.update(cat, name: "Groceries", symbolName: "cart.fill", colorHex: "#8CC0EB")
        try ctx.save()

        XCTAssertEqual(cat.name, "Groceries")
        XCTAssertEqual(cat.symbolName, "cart.fill")
        XCTAssertEqual(cat.colorHex, "#8CC0EB")
    }

    func test_delete_reassignsTransactionsThenRemovesCategory() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let food = ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC")
        let groceries = ExpenseCategory(name: "Groceries", symbolName: "cart.fill", colorHex: "#8CC0EB")
        ctx.insert(food); ctx.insert(groceries)
        let tx = Transaction(amount: 10, type: .expense, date: .now, category: food)
        ctx.insert(tx)
        try ctx.save()

        CategoryActions.delete(food, reassigningTo: groceries, in: ctx)
        try ctx.save()

        let cats = try ctx.fetch(FetchDescriptor<ExpenseCategory>())
        XCTAssertEqual(cats.map(\.name), ["Groceries"])
        let txs = try ctx.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(txs.count, 1)
        XCTAssertEqual(txs.first?.category?.name, "Groceries")
    }
}
