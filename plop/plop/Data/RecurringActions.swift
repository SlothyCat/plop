import Foundation
import SwiftData

/// Ledger mutations for recurring rules (mirrors TransactionActions).
enum RecurringActions {
    /// Creates a rule from a recurring draft and inserts its first occurrence (the
    /// entered transaction). anchorDay = the entry date's day-of-month; lastGenerated
    /// = the entry date so the SP2 engine resumes from the next occurrence.
    @discardableResult
    static func create(from draft: TransactionDraft, in context: ModelContext,
                       calendar: Calendar = .current) -> RecurringRule {
        let anchorDay = calendar.component(.day, from: draft.date)
        let rule = RecurringRule(amount: draft.amount, type: draft.type, note: draft.note,
                                 interval: draft.recurrence, anchorDay: anchorDay,
                                 startDate: draft.date, category: draft.category)
        context.insert(rule)

        let first = Transaction(amount: draft.amount, type: draft.type, date: draft.date,
                                note: draft.note, recurrence: draft.recurrence,
                                category: draft.category)
        first.rule = rule
        context.insert(first)

        rule.lastGeneratedDate = calendar.startOfDay(for: draft.date)
        return rule
    }

    /// Cancels a recurrence: deletes the rule so nothing new generates. Past
    /// occurrences remain (occurrences relationship is .nullify — their `rule` clears).
    static func cancel(_ rule: RecurringRule, in context: ModelContext) {
        context.delete(rule)
    }
}
