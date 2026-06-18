import XCTest
import SwiftData
@testable import plop

@MainActor
final class RecurringRuleTests: XCTestCase {

    func test_rule_linksTransactionBothWays() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let rule = RecurringRule(amount: 15, type: .expense, note: "Netflix",
                                 interval: .monthly, anchorDay: 5, startDate: .now)
        context.insert(rule)

        let tx = Transaction(amount: 15, type: .expense, date: .now, note: "Netflix")
        tx.rule = rule
        context.insert(tx)
        try context.save()

        XCTAssertEqual(tx.rule?.note, "Netflix")
        XCTAssertEqual(rule.occurrences.count, 1)
        XCTAssertEqual(rule.occurrences.first?.amount, 15)
    }

    func test_deletingRule_keepsTransaction_nullifiesLink() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let rule = RecurringRule(amount: 9, type: .expense, note: "Gym",
                                 interval: .monthly, anchorDay: 1, startDate: .now)
        context.insert(rule)
        let tx = Transaction(amount: 9, type: .expense, date: .now, note: "Gym")
        tx.rule = rule
        context.insert(tx)
        try context.save()

        context.delete(rule)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(remaining.count, 1)
        XCTAssertNil(remaining.first?.rule)
    }
}
