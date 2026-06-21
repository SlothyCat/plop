import Foundation

/// Currency string for an already-signed amount. `signed: true` forces an explicit
/// +/− prefix (transaction rows); otherwise only negatives get a leading "-".
func formattedMoney(_ amount: Decimal, signed: Bool = false, currencyCode: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode
    let magnitude = NSDecimalNumber(decimal: abs(amount))
    let body = formatter.string(from: magnitude) ?? "\(abs(amount))"
    if signed { return (amount < 0 ? "-" : "+") + body }
    return amount < 0 ? "-" + body : body
}

/// Grouped, unsigned amount with NO currency symbol — for composing a custom money label
/// (e.g. a gray symbol prefix + dark digits). Fraction digits follow the currency.
func formattedAmountDigits(_ amount: Decimal, currencyCode: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.usesGroupingSeparator = true
    let digits = currencyFractionDigits(currencyCode: currencyCode)
    formatter.minimumFractionDigits = digits
    formatter.maximumFractionDigits = digits
    let magnitude = NSDecimalNumber(decimal: abs(amount))
    return formatter.string(from: magnitude) ?? "\(abs(amount))"
}

/// Day-group header: "TODAY" / "YESTERDAY" / "FRI, 29 MAY".
func dayLabel(for date: Date, relativeTo today: Date, calendar: Calendar) -> String {
    let startOfDate = calendar.startOfDay(for: date)
    let startOfToday = calendar.startOfDay(for: today)
    let days = calendar.dateComponents([.day], from: startOfDate, to: startOfToday).day ?? 0
    if days == 0 { return "TODAY" }
    if days == 1 { return "YESTERDAY" }
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = calendar.locale ?? .current
    formatter.timeZone = calendar.timeZone
    formatter.dateFormat = "EEE, d MMM"
    return formatter.string(from: date).uppercased()
}
