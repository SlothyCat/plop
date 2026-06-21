import Foundation
import SwiftData

// Named ExpenseCategory (not Category) to avoid a clash with the Objective-C
// runtime's `Category` type, which is visible wherever Foundation is imported.
@Model
final class ExpenseCategory {
    var name: String
    var symbolName: String      // SF Symbol, e.g. "fork.knife"
    var emoji: String = ""      // non-empty ⇒ render this emoji instead of symbolName
    var colorHex: String        // e.g. "#FFEBCC"
    var budget: Decimal = 0     // 0 = no budget set; Budget feature gives it meaning later
                                // (non-optional: optional Decimal crashes SwiftData)

    // Deleting a category nullifies its transactions' link → they show "Uncategorized".
    // The inverse is inferred from Transaction.category; declaring it explicitly here
    // creates a metadata cycle that traps SwiftData at fetch time.
    @Relationship(deleteRule: .nullify)
    var transactions: [Transaction] = []

    init(name: String, symbolName: String, emoji: String = "", colorHex: String,
         budget: Decimal = 0) {
        self.name = name
        self.symbolName = symbolName
        self.emoji = emoji
        self.colorHex = colorHex
        self.budget = budget
    }
}
