import Foundation

/// One month's tab: a `yyyy-MM` title and a 2-D array of cell strings.
struct MonthSheet: Equatable {
    let year: Int
    let month: Int
    let values: [[String]]

    var tabTitle: String { String(format: "%04d-%02d", year, month) }
}

/// Caller-configured export settings (everything that isn't transaction data).
struct ExportOptions {
    var range: ExportRange
    var budgetMode: BudgetMode
    var generalBudget: String
    var currencyCode: String
    var now: Date = .now
    var calendar: Calendar = .current
}

private struct MonthKey: Hashable, Comparable {
    let year: Int
    let month: Int
    static func < (lhs: MonthKey, rhs: MonthKey) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}

/// Transactions (filtered by `options.range`) → one `MonthSheet` per month with
/// data, sorted oldest-first. Pure.
func buildExportSheets(transactions: [Transaction],
                       categories: [ExpenseCategory],
                       options: ExportOptions) -> [MonthSheet] {
    let calendar = options.calendar
    let inRange = transactions.filter {
        options.range.contains($0.date, now: options.now, calendar: calendar)
    }

    var groups: [MonthKey: [Transaction]] = [:]
    for tx in inRange {
        let comps = calendar.dateComponents([.year, .month], from: tx.date)
        guard let year = comps.year, let month = comps.month else { continue }
        groups[MonthKey(year: year, month: month), default: []].append(tx)
    }

    return groups.keys.sorted().map { key in
        MonthSheet(year: key.year, month: key.month,
                   values: monthMatrix(monthTxs: groups[key] ?? [],
                                       year: key.year, month: key.month,
                                       categories: categories, options: options))
    }
}

// MARK: - matrix

private func monthMatrix(monthTxs: [Transaction], year: Int, month: Int,
                         categories: [ExpenseCategory], options: ExportOptions) -> [[String]] {
    let calendar = options.calendar
    let totalBudget = activeBudgetTotal(mode: options.budgetMode,
                                        generalBudget: options.generalBudget,
                                        categories: categories)
    let budgetByName = Dictionary(categories.map { ($0.name, $0.budget) },
                                  uniquingKeysWith: { first, _ in first })

    let totalExpense = monthTxs.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
    let totalIncome = monthTxs.filter { $0.type == .income }.reduce(Decimal(0)) { $0 + $1.amount }

    var spentByCat: [String: Decimal] = [:]
    for tx in monthTxs where tx.type == .expense {
        let name = tx.category?.name ?? "Uncategorized"
        spentByCat[name, default: 0] += tx.amount
    }
    let catRows = spentByCat.sorted {
        $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key
    }

    var rows: [[String]] = [
        [monthTitle(year: year, month: month, calendar: calendar)],
        ["Total expense", sheetNumber(totalExpense)],
        ["Total income", sheetNumber(totalIncome)],
        ["Net", sheetNumber(totalIncome - totalExpense)],
        ["Total budget", sheetNumber(totalBudget)],
        ["Budget left", sheetNumber(totalBudget - totalExpense)],
        [],
        ["Spending by category"],
        ["Category", "Spent", "Budget", "Left"]
    ]

    for (name, spent) in catRows {
        let budget = budgetByName[name] ?? 0
        if budget > 0 {
            rows.append([name, sheetNumber(spent), sheetNumber(budget), sheetNumber(budget - spent)])
        } else {
            rows.append([name, sheetNumber(spent), "", ""])
        }
    }

    rows.append([])
    rows.append(["Transactions"])
    rows.append(["Date", "Category", "Note", "Type", "Amount (\(options.currencyCode))"])

    let sorted = monthTxs.sorted {
        $0.date != $1.date ? $0.date > $1.date : $0.createdAt > $1.createdAt
    }
    for tx in sorted {
        rows.append([
            sheetDate(tx.date, calendar: calendar),
            tx.category?.name ?? "Uncategorized",
            tx.note,
            tx.type == .expense ? "Expense" : "Income",
            sheetNumber(tx.amount)
        ])
    }
    return rows
}

// MARK: - formatting (deterministic)

private func sheetNumber(_ value: Decimal) -> String {
    NSDecimalNumber(decimal: value).stringValue
}

private func sheetDate(_ date: Date, calendar: Calendar) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

private func monthTitle(year: Int, month: Int, calendar: Calendar) -> String {
    var comps = DateComponents()
    comps.year = year
    comps.month = month
    comps.day = 1
    guard let date = calendar.date(from: comps) else { return "\(year)-\(month)" }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.dateFormat = "LLLL yyyy"
    return formatter.string(from: date)
}
