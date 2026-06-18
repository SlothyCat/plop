import XCTest
import SwiftData
@testable import plop

@MainActor
final class RecurringGeneratorTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d))!
    }
    private func txCount(_ context: ModelContext) throws -> Int {
        try context.fetch(FetchDescriptor<Transaction>()).count
    }

    func test_generatesDueOccurrences_linksAndAdvances() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let rule = RecurringRule(amount: 15, type: .expense, note: "Netflix",
                                 interval: .monthly, anchorDay: 5, startDate: day(2026, 1, 5))
        context.insert(rule)

        let count = RecurringGenerator.generate(in: context, now: day(2026, 3, 10),
                                                calendar: utc)

        XCTAssertEqual(count, 3)
        XCTAssertEqual(try txCount(context), 3)
        XCTAssertEqual(rule.occurrences.count, 3)
        XCTAssertEqual(rule.lastGeneratedDate, day(2026, 3, 5))
    }

    func test_copiesRuleFields() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let food = ExpenseCategory(name: "Subs", symbolName: "tv", colorHex: "#FFF9D2")
        context.insert(food)
        let rule = RecurringRule(amount: 12, type: .expense, note: "Spotify",
                                 interval: .monthly, anchorDay: 1, startDate: day(2026, 1, 1),
                                 category: food)
        context.insert(rule)

        _ = RecurringGenerator.generate(in: context, now: day(2026, 1, 1), calendar: utc)

        let tx = try context.fetch(FetchDescriptor<Transaction>()).first
        XCTAssertEqual(tx?.amount, 12)
        XCTAssertEqual(tx?.type, .expense)
        XCTAssertEqual(tx?.note, "Spotify")
        XCTAssertEqual(tx?.category?.name, "Subs")
        XCTAssertEqual(tx?.recurrence, .monthly)
        XCTAssertEqual(tx?.date, day(2026, 1, 1))
    }

    func test_idempotent_secondRunInsertsNothing() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let rule = RecurringRule(amount: 9, type: .expense, note: "Gym",
                                 interval: .monthly, anchorDay: 1, startDate: day(2026, 1, 1))
        context.insert(rule)

        let first = RecurringGenerator.generate(in: context, now: day(2026, 3, 1), calendar: utc)
        let second = RecurringGenerator.generate(in: context, now: day(2026, 3, 1), calendar: utc)

        XCTAssertEqual(first, 3)
        XCTAssertEqual(second, 0)
        XCTAssertEqual(try txCount(context), 3)
    }

    func test_inactiveRule_skipped() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let rule = RecurringRule(amount: 9, type: .expense, note: "Old",
                                 interval: .monthly, anchorDay: 1, startDate: day(2026, 1, 1))
        rule.isActive = false
        context.insert(rule)

        let count = RecurringGenerator.generate(in: context, now: day(2026, 6, 1), calendar: utc)
        XCTAssertEqual(count, 0)
        XCTAssertEqual(try txCount(context), 0)
    }

    func test_nothingDue_noInsertNoAdvance() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let rule = RecurringRule(amount: 9, type: .expense, note: "Future",
                                 interval: .monthly, anchorDay: 5, startDate: day(2026, 6, 18))
        context.insert(rule)

        let count = RecurringGenerator.generate(in: context, now: day(2026, 6, 30), calendar: utc)
        XCTAssertEqual(count, 0)
        XCTAssertEqual(try txCount(context), 0)
        XCTAssertNil(rule.lastGeneratedDate)
    }
}
