import XCTest
import SwiftData
@testable import plop

@MainActor
final class RecurringActionsTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d))!
    }

    func test_create_buildsRuleAndFirstOccurrence() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let cat = ExpenseCategory(name: "Subs", symbolName: "tv", colorHex: "#FFF9D2")
        context.insert(cat)
        let draft = TransactionDraft(amount: 15, type: .expense, date: day(2026, 6, 18),
                                     note: "Netflix", recurrence: .monthly, category: cat)

        let rule = RecurringActions.create(from: draft, in: context, calendar: utc)

        XCTAssertEqual(rule.interval, .monthly)
        XCTAssertEqual(rule.anchorDay, 18)
        XCTAssertEqual(rule.startDate, day(2026, 6, 18))
        XCTAssertEqual(rule.amount, 15)
        XCTAssertEqual(rule.note, "Netflix")
        XCTAssertEqual(rule.category?.name, "Subs")
        XCTAssertTrue(rule.isActive)
        XCTAssertEqual(rule.lastGeneratedDate, day(2026, 6, 18))

        XCTAssertEqual(rule.occurrences.count, 1)
        let first = rule.occurrences.first
        XCTAssertEqual(first?.amount, 15)
        XCTAssertEqual(first?.recurrence, .monthly)
        XCTAssertEqual(first?.date, day(2026, 6, 18))
        XCTAssertEqual(first?.rule?.note, "Netflix")
    }

    func test_create_thenGenerateSameDay_noDoubleOccurrence() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let draft = TransactionDraft(amount: 9, type: .expense, date: day(2026, 6, 18),
                                     note: "Gym", recurrence: .monthly)
        _ = RecurringActions.create(from: draft, in: context, calendar: utc)

        let added = RecurringGenerator.generate(in: context, now: day(2026, 6, 18), calendar: utc)
        XCTAssertEqual(added, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Transaction>()).count, 1)
    }

    func test_cancel_removesRule_keepsOccurrence() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let draft = TransactionDraft(amount: 9, type: .expense, date: day(2026, 6, 18),
                                     note: "Gym", recurrence: .monthly)
        let rule = RecurringActions.create(from: draft, in: context, calendar: utc)
        try context.save()

        RecurringActions.cancel(rule, in: context)
        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<RecurringRule>()).count, 0)
        let txs = try context.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(txs.count, 1)        // first occurrence kept
        XCTAssertNil(txs.first?.rule)       // link nullified
    }
}
