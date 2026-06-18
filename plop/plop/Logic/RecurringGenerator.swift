import Foundation
import SwiftData

/// Materializes due occurrences for active recurring rules. Idempotent: advancing
/// each rule's `lastGeneratedDate` means repeated runs do nothing until a new
/// occurrence is due. Runs on the supplied (main) context.
enum RecurringGenerator {
    /// Inserts a Transaction for every occurrence due (per rule) on/before `now`,
    /// links it to its rule, advances `lastGeneratedDate`, and saves. Returns the
    /// number of transactions inserted.
    @discardableResult
    static func generate(in context: ModelContext, now: Date = .now,
                         calendar: Calendar = .current) -> Int {
        let active = FetchDescriptor<RecurringRule>(predicate: #Predicate<RecurringRule> { $0.isActive == true })
        let rules = (try? context.fetch(active)) ?? []

        var inserted = 0
        for rule in rules {
            let dates = RecurringSchedule.dueOccurrences(
                interval: rule.interval, anchorDay: rule.anchorDay, startDate: rule.startDate,
                lastGenerated: rule.lastGeneratedDate, asOf: now, calendar: calendar)
            for date in dates {
                let tx = Transaction(amount: rule.amount, type: rule.type, date: date,
                                     note: rule.note, recurrence: rule.interval,
                                     category: rule.category)
                tx.rule = rule
                context.insert(tx)
                inserted += 1
            }
            if let last = dates.last { rule.lastGeneratedDate = last }
        }
        if inserted > 0 { try? context.save() }
        return inserted
    }
}
