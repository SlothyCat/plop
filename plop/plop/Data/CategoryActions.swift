import Foundation
import SwiftData

/// The single locus for category mutations (mirrors TransactionActions).
enum CategoryActions {
    static func add(name: String, symbolName: String, colorHex: String, in context: ModelContext) {
        context.insert(ExpenseCategory(name: name, symbolName: symbolName, colorHex: colorHex))
    }

    static func update(_ category: ExpenseCategory, name: String, symbolName: String, colorHex: String) {
        category.name = name
        category.symbolName = symbolName
        category.colorHex = colorHex
    }

    /// Move this category's transactions to `target`, then delete it.
    static func delete(_ category: ExpenseCategory, reassigningTo target: ExpenseCategory,
                       in context: ModelContext) {
        for tx in Array(category.transactions) {   // snapshot: reassign mutates the relationship
            tx.category = target
        }
        context.delete(category)
    }
}
