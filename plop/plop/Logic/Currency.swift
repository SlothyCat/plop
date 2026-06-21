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

/// Two-letter lowercase region for a currency code (USD→"us", EUR→"eu", CHF→"ch"); the
/// bundled flag image is named "flag-<region>" (flag-icons SVGs in the asset catalog).
func currencyRegionCode(_ code: String) -> String {
    code.prefix(2).lowercased()
}

/// Asset-catalog name for a currency's flag image (e.g. "flag-us").
func currencyFlagAsset(_ code: String) -> String {
    "flag-\(currencyRegionCode(code))"
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
