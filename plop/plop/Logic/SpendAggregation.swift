import Foundation

let uncategorizedSpendID = "__uncategorized__"
let uncategorizedSpendColor = "#C9CDD2"   // neutral gray

struct CategorySpend: Identifiable, Equatable {
    let id: String        // category name, or uncategorizedSpendID
    let name: String
    let colorHex: String
    let amount: Decimal
}

/// Expenses only, within `range`, summed per category, largest first
/// (ties broken by name for a stable order).
func spendByCategory(_ txs: [Transaction], in range: ClosedRange<Date>) -> [CategorySpend] {
    var bucket: [String: (name: String, color: String, amount: Decimal)] = [:]
    for tx in txs where tx.type == .expense && range.contains(tx.date) {
        let key = tx.category?.name ?? uncategorizedSpendID
        let name = tx.category?.name ?? "Uncategorized"
        let color = tx.category?.colorHex ?? uncategorizedSpendColor
        var entry = bucket[key] ?? (name, color, Decimal(0))
        entry.amount += tx.amount
        bucket[key] = entry
    }
    return bucket
        .map { CategorySpend(id: $0.key, name: $0.value.name, colorHex: $0.value.color, amount: $0.value.amount) }
        .sorted { $0.amount != $1.amount ? $0.amount > $1.amount : $0.name < $1.name }
}

func totalSpent(_ spend: [CategorySpend]) -> Decimal {
    spend.reduce(Decimal(0)) { $0 + $1.amount }
}

struct DonutSlice: Identifiable, Equatable {
    let id: String
    let colorHex: String
    let start: Double   // fraction of the ring [0,1]
    let end: Double
}

/// Raise each non-zero fraction below `minArc` up to `minArc`, shrinking the ≥ `minArc`
/// fractions proportionally to absorb the deficit so the set still sums to 1 (assuming the
/// input sums to 1). No-op when nothing is below `minArc`. Falls back to an equal split among
/// non-zero entries if there isn't enough room to steal the deficit.
func minArcAdjusted(_ fractions: [Double], minArc: Double) -> [Double] {
    let deficit = fractions.filter { $0 > 0 && $0 < minArc }
                           .reduce(0.0) { $0 + (minArc - $1) }
    guard deficit > 0 else { return fractions }

    let bigSum = fractions.filter { $0 >= minArc }.reduce(0.0, +)
    guard bigSum > deficit else {
        let k = fractions.filter { $0 > 0 }.count
        let equal = k > 0 ? 1.0 / Double(k) : 0
        return fractions.map { $0 > 0 ? equal : 0 }
    }

    let factor = (bigSum - deficit) / bigSum
    return fractions.map { f in
        if f <= 0 { return 0 }
        return f < minArc ? minArc : f * factor
    }
}

/// Cumulative start/end ring fractions per slice, inset by `gap` between slices.
/// Tiny slices clamp to zero length (start == end) rather than going negative.
func donutSlices(from spend: [CategorySpend], gap: Double = 0.012,
                 minArc: Double = 0.03) -> [DonutSlice] {
    let total = totalSpent(spend)
    guard total > 0 else { return [] }
    let totalDouble = NSDecimalNumber(decimal: total).doubleValue
    let drawn = minArcAdjusted(spend.map {
        NSDecimalNumber(decimal: $0.amount).doubleValue / totalDouble
    }, minArc: minArc)

    var cursor = 0.0
    var slices: [DonutSlice] = []
    for (i, s) in spend.enumerated() {
        let start = cursor + gap / 2
        let end = max(start, cursor + drawn[i] - gap / 2)
        slices.append(DonutSlice(id: s.id, colorHex: s.colorHex, start: start, end: end))
        cursor += drawn[i]
    }
    return slices
}
