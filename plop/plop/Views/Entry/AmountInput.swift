import Foundation

/// Pure keypad input logic for the amount field. Tracks the raw digit string and
/// derives a Decimal value + grouped display. Tested in isolation.
struct AmountInput {
    private(set) var digits: String
    let maxFractionDigits: Int

    init(maxFractionDigits: Int = 2) {
        self.digits = ""
        self.maxFractionDigits = maxFractionDigits
    }

    init(value: Decimal, maxFractionDigits: Int = 2) {
        self.maxFractionDigits = maxFractionDigits
        self.digits = value > 0 ? NSDecimalNumber(decimal: value).stringValue : ""
    }

    mutating func press(_ key: String) {
        if key == "." {
            guard maxFractionDigits > 0, !digits.contains(".") else { return }
            digits = digits.isEmpty ? "0." : digits + "."
            return
        }
        if let dot = digits.firstIndex(of: ".") {
            let fractionCount = digits.distance(from: digits.index(after: dot), to: digits.endIndex)
            if fractionCount >= maxFractionDigits { return }
        }
        digits = (digits == "0") ? key : digits + key
    }

    mutating func backspace() {
        if !digits.isEmpty { digits.removeLast() }
    }

    var value: Decimal {
        Decimal(string: digits.isEmpty ? "0" : digits) ?? 0
    }

    var canSave: Bool { value > 0 }

    func display(locale: Locale = .current) -> String {
        guard !digits.isEmpty else { return "0" }
        let parts = digits.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        let intText = parts[0].isEmpty ? "0" : parts[0]
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.maximumFractionDigits = 0
        let grouped = formatter.string(from: NSDecimalNumber(string: intText)) ?? intText
        if digits.contains(".") {
            return grouped + "." + (parts.count > 1 ? parts[1] : "")
        }
        return grouped
    }
}
