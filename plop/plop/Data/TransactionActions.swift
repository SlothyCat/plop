import Foundation
import SwiftData

/// The single locus for ledger mutations. Reads stay as @Query in views.
enum TransactionActions {
    static func add(_ draft: TransactionDraft, in context: ModelContext) {
        let tx = Transaction(amount: draft.amount,
                             type: draft.type,
                             date: draft.date,
                             note: draft.note,
                             recurrence: draft.recurrence,
                             category: draft.category)
        context.insert(tx)
    }

    static func update(_ tx: Transaction, with draft: TransactionDraft) {
        tx.amount = draft.amount
        tx.type = draft.type
        tx.date = draft.date
        tx.note = draft.note
        tx.recurrence = draft.recurrence
        tx.category = draft.category
    }

    static func delete(_ tx: Transaction, in context: ModelContext) {
        context.delete(tx)
    }
}
