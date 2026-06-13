import Foundation
import SwiftData

@Model
final class Category {
    var name: String
    var symbolName: String      // SF Symbol, e.g. "fork.knife"
    var colorHex: String        // e.g. "#FFEBCC"
    var budget: Decimal?        // unused now; Budget feature fills it later

    // Deleting a Category nullifies its transactions' link → they show "Uncategorized".
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction] = []

    init(name: String, symbolName: String, colorHex: String, budget: Decimal? = nil) {
        self.name = name
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.budget = budget
    }
}
