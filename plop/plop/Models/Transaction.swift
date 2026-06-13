import Foundation
import SwiftData

@Model
final class Transaction {
    var amount: Decimal           // always positive; sign derived from `type`
    var type: TransactionType
    var date: Date                // spend date + time
    var note: String
    var recurrence: RecurrenceInterval
    var createdAt: Date           // stable sort tiebreaker
    var category: Category?

    init(amount: Decimal,
         type: TransactionType,
         date: Date,
         note: String = "",
         recurrence: RecurrenceInterval = .none,
         category: Category? = nil) {
        self.amount = amount
        self.type = type
        self.date = date
        self.note = note
        self.recurrence = recurrence
        self.createdAt = .now
        self.category = category
    }
}
