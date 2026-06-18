import Foundation
import SwiftData

/// A recurring-payment template + scheduling state. Generated occurrences are normal
/// Transactions linked via `occurrences` (inverse: Transaction.rule). Generation and
/// UI arrive in later sub-projects.
@Model
final class RecurringRule {
    var amount: Decimal               // always positive; sign derived from `type`
    var type: TransactionType
    var note: String
    var interval: RecurrenceInterval  // never .none for a rule
    var anchorDay: Int                // day-of-month for .monthly; derived/ignored otherwise
    var startDate: Date
    var lastGeneratedDate: Date?      // nil until first generation (SP2)
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var category: ExpenseCategory?

    // Inverse inferred from Transaction.rule — declared on this side only to avoid
    // the SwiftData metadata-cycle trap. Nullify keeps occurrences when a rule goes.
    @Relationship(deleteRule: .nullify)
    var occurrences: [Transaction] = []

    init(amount: Decimal, type: TransactionType, note: String = "",
         interval: RecurrenceInterval, anchorDay: Int, startDate: Date,
         category: ExpenseCategory? = nil) {
        self.amount = amount
        self.type = type
        self.note = note
        self.interval = interval
        self.anchorDay = anchorDay
        self.startDate = startDate
        self.lastGeneratedDate = nil
        self.isActive = true
        self.createdAt = .now
        self.category = category
    }
}
