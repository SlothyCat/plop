import Foundation

/// Signed value of a transaction: income positive, expense negative.
func signedAmount(_ tx: Transaction) -> Decimal {
    switch tx.type {
    case .income:  return tx.amount
    case .expense: return -tx.amount
    }
}

/// Signed sum over a set of transactions. Empty → 0.
func netTotal(of txs: [Transaction]) -> Decimal {
    txs.reduce(Decimal(0)) { $0 + signedAmount($1) }
}

struct DayGroup {
    let date: Date              // start of day
    let transactions: [Transaction]
    let subtotal: Decimal
}

/// Group transactions by local calendar day, newest day first; within a day
/// newest time first, tiebroken by createdAt.
func groupByDay(_ txs: [Transaction], calendar: Calendar) -> [DayGroup] {
    let grouped = Dictionary(grouping: txs) { calendar.startOfDay(for: $0.date) }
    return grouped.keys.sorted(by: >).map { day in
        let rows = grouped[day]!.sorted {
            if $0.date != $1.date { return $0.date > $1.date }
            return $0.createdAt > $1.createdAt
        }
        return DayGroup(date: day, transactions: rows, subtotal: netTotal(of: rows))
    }
}
