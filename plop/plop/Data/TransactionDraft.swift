import Foundation

/// Plain carrier of Entry's form fields, handed to TransactionActions.
struct TransactionDraft {
    var amount: Decimal
    var type: TransactionType
    var date: Date
    var note: String
    var recurrence: RecurrenceInterval
    var category: ExpenseCategory?

    init(amount: Decimal,
         type: TransactionType,
         date: Date,
         note: String = "",
         recurrence: RecurrenceInterval = .none,
         category: ExpenseCategory? = nil) {
        self.amount = amount
        self.type = type
        self.date = date
        self.note = note
        self.recurrence = recurrence
        self.category = category
    }
}
