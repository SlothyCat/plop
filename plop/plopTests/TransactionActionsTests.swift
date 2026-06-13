import XCTest
import SwiftData
@testable import plop

@MainActor
final class TransactionActionsTests: XCTestCase {
    func test_add_insertsTransactionWithFields() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let draft = TransactionDraft(amount: Decimal(12), type: .expense,
                                     date: .now, note: "Lunch")
        TransactionActions.add(draft, in: ctx)
        try ctx.save()

        let all = try ctx.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.amount, Decimal(12))
        XCTAssertEqual(all.first?.type, .expense)
        XCTAssertEqual(all.first?.note, "Lunch")
    }

    func test_add_setsCategoryRelationship() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let cat = ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC")
        ctx.insert(cat)
        let draft = TransactionDraft(amount: Decimal(5), type: .expense,
                                     date: .now, category: cat)
        TransactionActions.add(draft, in: ctx)
        try ctx.save()

        let all = try ctx.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(all.first?.category?.name, "Food")
    }

    func test_update_mutatesFields() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let tx = Transaction(amount: Decimal(5), type: .expense, date: .now)
        ctx.insert(tx)
        let draft = TransactionDraft(amount: Decimal(9), type: .income,
                                     date: tx.date, note: "Refund")
        TransactionActions.update(tx, with: draft)
        try ctx.save()

        XCTAssertEqual(tx.amount, Decimal(9))
        XCTAssertEqual(tx.type, .income)
        XCTAssertEqual(tx.note, "Refund")
    }

    func test_delete_removesTransaction() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let tx = Transaction(amount: Decimal(5), type: .expense, date: .now)
        ctx.insert(tx)
        try ctx.save()
        TransactionActions.delete(tx, in: ctx)
        try ctx.save()

        let all = try ctx.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(all.count, 0)
    }

    func test_deletingCategory_nullifiesLink() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let cat = ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC")
        ctx.insert(cat)
        let tx = Transaction(amount: Decimal(5), type: .expense, date: .now, category: cat)
        ctx.insert(tx)
        try ctx.save()

        ctx.delete(cat)
        try ctx.save()

        let all = try ctx.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(all.count, 1)
        XCTAssertNil(all.first?.category)
    }
}
