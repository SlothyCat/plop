import Foundation
import SwiftData

/// First-run starter categories, seeded exactly once (guarded by a persisted flag,
/// NOT a table-empty check — so deleting all categories later never re-seeds).
enum DefaultData {
    static let seededFlagKey = "didSeedDefaultCategories"

    struct CategorySpec {
        let name: String
        let symbolName: String
        let colorHex: String
    }

    static let defaultCategorySpecs: [CategorySpec] = [
        CategorySpec(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC"),
        CategorySpec(name: "Transport", symbolName: "car.fill", colorHex: "#BFDDF0"),
        CategorySpec(name: "Shopping", symbolName: "bag.fill", colorHex: "#8CC0EB"),
        CategorySpec(name: "Bills", symbolName: "doc.text.fill", colorHex: "#FFF9D2"),
        CategorySpec(name: "Entertainment", symbolName: "play.tv.fill", colorHex: "#BFDDF0"),
    ]

    /// Returns true if it seeded on this call.
    @discardableResult
    static func seedIfNeeded(in context: ModelContext,
                             defaults: UserDefaults = .standard) -> Bool {
        guard !defaults.bool(forKey: seededFlagKey) else { return false }
        for spec in defaultCategorySpecs {
            context.insert(ExpenseCategory(name: spec.name,
                                           symbolName: spec.symbolName,
                                           colorHex: spec.colorHex))
        }
        defaults.set(true, forKey: seededFlagKey)
        return true
    }
}
