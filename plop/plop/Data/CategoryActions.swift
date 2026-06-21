import Foundation
import SwiftData

/// The editable fields of a category, passed to `CategoryActions.add`/`update` as one value
/// (keeps those calls to two arguments).
struct CategoryDraft {
    var name: String
    var symbolName: String
    var emoji: String = ""
    var colorHex: String
    var budget: Decimal = 0
}

/// The single locus for category mutations (mirrors TransactionActions).
enum CategoryActions {
    @discardableResult
    static func add(_ draft: CategoryDraft, in context: ModelContext) -> ExpenseCategory {
        let category = ExpenseCategory(name: draft.name, symbolName: draft.symbolName,
                                       emoji: draft.emoji, colorHex: draft.colorHex,
                                       budget: draft.budget)
        context.insert(category)
        return category
    }

    static func update(_ category: ExpenseCategory, with draft: CategoryDraft) {
        category.name = draft.name
        category.symbolName = draft.symbolName
        category.emoji = draft.emoji
        category.colorHex = draft.colorHex
        category.budget = draft.budget
    }

    /// Delete a category that has no transactions to keep.
    static func delete(_ category: ExpenseCategory, in context: ModelContext) {
        context.delete(category)
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
