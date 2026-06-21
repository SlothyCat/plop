import Foundation

/// @AppStorage key for the user's chosen display currency (set by the picker in PR2).
let currencyCodeKey = "currencyCode"

/// Curated set of common currencies offered in the picker.
let currencyChoices = ["USD", "EUR", "GBP", "JPY", "CNY", "SGD",
                       "AUD", "CAD", "HKD", "KRW", "INR", "CHF"]

/// The device's currency, used as the default until the user picks one.
func deviceCurrencyCode() -> String {
    Locale.current.currency?.identifier ?? "USD"
}

func currencyDisplayName(_ code: String) -> String {
    Locale.current.localizedString(forCurrencyCode: code) ?? code
}

/// Flag emoji for a currency code (first two letters = region: USD→🇺🇸, EUR→🇪🇺, CHF→🇨🇭).
/// Returns "" if the code doesn't yield two A–Z letters.
func currencyFlag(_ code: String) -> String {
    let region = code.prefix(2).uppercased()
    guard region.count == 2 else { return "" }
    var flag = ""
    for scalar in region.unicodeScalars {
        guard scalar.value >= 65, scalar.value <= 90,
              let indicator = Unicode.Scalar(0x1F1E6 + scalar.value - 65) else { return "" }
        flag.unicodeScalars.append(indicator)
    }
    return flag
}

func currencySymbol(_ code: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = code
    return formatter.currencySymbol ?? code
}

/// Max fraction digits for a currency (2 for USD, 0 for JPY/KRW).
func currencyFractionDigits(currencyCode: String) -> Int {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode
    return formatter.maximumFractionDigits
}
