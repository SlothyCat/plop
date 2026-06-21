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

    func test_category_emojiDefaultsEmpty() {
        let cat = ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC")
        XCTAssertEqual(cat.emoji, "")
    }

    func test_update_mutatesFields() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let cat = ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC")
        ctx.insert(cat)

        CategoryActions.update(cat, name: "Groceries", symbolName: "cart.fill",
                               colorHex: "#8CC0EB", budget: 250)
        try ctx.save()

        XCTAssertEqual(cat.name, "Groceries")
        XCTAssertEqual(cat.symbolName, "cart.fill")
        XCTAssertEqual(cat.colorHex, "#8CC0EB")
        XCTAssertEqual(cat.budget, 250)
    }

    func test_add_returnsInsertedCategory() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let created = CategoryActions.add(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC", in: ctx)
        XCTAssertEqual(created.name, "Food")
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ExpenseCategory>()).count, 1)
    }

    func test_add_persistsBudget() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let created = CategoryActions.add(name: "Food", symbolName: "fork.knife",
                                          colorHex: "#FFEBCC", budget: 300, in: ctx)
        XCTAssertEqual(created.budget, 300)
        try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ExpenseCategory>()).first?.budget, 300)
    }

    func test_add_defaultsBudgetToZero() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let created = CategoryActions.add(name: "Food", symbolName: "fork.knife",
                                          colorHex: "#FFEBCC", in: ctx)
        XCTAssertEqual(created.budget, 0)
    }

    func test_delete_removesEmptyCategory() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let cat = ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC")
        ctx.insert(cat)
        try ctx.save()

        CategoryActions.delete(cat, in: ctx)
        try ctx.save()

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ExpenseCategory>()).count, 0)
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
