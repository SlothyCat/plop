import Foundation
import SwiftData

/// The single locus for category mutations (mirrors TransactionActions).
enum CategoryActions {
    @discardableResult
    static func add(name: String, symbolName: String, emoji: String = "", colorHex: String,
                    budget: Decimal = 0, in context: ModelContext) -> ExpenseCategory {
        let category = ExpenseCategory(name: name, symbolName: symbolName, emoji: emoji,
                                       colorHex: colorHex, budget: budget)
        context.insert(category)
        return category
    }

    /// Delete a category that has no transactions to keep.
    static func delete(_ category: ExpenseCategory, in context: ModelContext) {
        context.delete(category)
    }

    static func update(_ category: ExpenseCategory, name: String, symbolName: String,
                       emoji: String, colorHex: String, budget: Decimal) {
        category.name = name
        category.symbolName = symbolName
        category.emoji = emoji
        category.colorHex = colorHex
        category.budget = budget
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
