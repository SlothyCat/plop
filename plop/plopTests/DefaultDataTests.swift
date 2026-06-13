import XCTest
import SwiftData
@testable import plop

@MainActor
final class DefaultDataTests: XCTestCase {
    private func ephemeralDefaults() -> UserDefaults {
        UserDefaults(suiteName: "test-\(UUID().uuidString)")!
    }

    func test_seedIfNeeded_insertsDefaultsWhenFlagUnset() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let defaults = ephemeralDefaults()

        let didSeed = DefaultData.seedIfNeeded(in: ctx, defaults: defaults)
        try ctx.save()

        XCTAssertTrue(didSeed)
        let cats = try ctx.fetch(FetchDescriptor<ExpenseCategory>())
        XCTAssertEqual(cats.count, DefaultData.defaultCategorySpecs.count)
    }

    func test_seedIfNeeded_doesNotReseedWhenFlagSet() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let defaults = ephemeralDefaults()
        defaults.set(true, forKey: DefaultData.seededFlagKey)

        let didSeed = DefaultData.seedIfNeeded(in: ctx, defaults: defaults)
        try ctx.save()

        XCTAssertFalse(didSeed)
        let cats = try ctx.fetch(FetchDescriptor<ExpenseCategory>())
        XCTAssertEqual(cats.count, 0)
    }
}
