# Currency Picker — Design

Status: Approved (brainstorm complete) · Date: 2026-06-14

Companion to `requirements.md`. Architecture, the formatting change, the picker,
reactivity, testing, and slicing.

## Architecture

```
plop/
  Logic/
    Currency.swift             (curated list + helpers; the @AppStorage key)
    Formatting.swift           (formattedMoney / currencyFractionDigits → currencyCode:)
  Views/Settings/
    CurrencyView.swift         (List of currencies, bound to @AppStorage)
    SettingsView.swift         (+ Currency row showing the current code)
  (money views)                (+ @AppStorage("currencyCode"), pass to formattedMoney)
```

## `Currency.swift`

```swift
let currencyCodeKey = "currencyCode"

let currencyChoices = ["USD", "EUR", "GBP", "JPY", "CNY", "SGD",
                       "AUD", "CAD", "HKD", "KRW", "INR", "CHF"]

func deviceCurrencyCode() -> String { Locale.current.currency?.identifier ?? "USD" }

func currencyDisplayName(_ code: String) -> String {
    Locale.current.localizedString(forCurrencyCode: code) ?? code
}

func currencySymbol(_ code: String) -> String {
    let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = code
    return f.currencySymbol ?? code
}
```

## `Formatting.swift` change

```swift
func formattedMoney(_ amount: Decimal, signed: Bool = false, currencyCode: String) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = currencyCode          // symbol + decimals, natively
    let body = f.string(from: NSDecimalNumber(decimal: abs(amount))) ?? "\(abs(amount))"
    if signed { return (amount < 0 ? "-" : "+") + body }
    return amount < 0 ? "-" + body : body
}

func currencyFractionDigits(currencyCode: String) -> Int {
    let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currencyCode
    return f.maximumFractionDigits
}
```
(`dayLabel` is unaffected.)

## Picker + reactivity

- `CurrencyView`: `@AppStorage("currencyCode") var code` over a `List(currencyChoices, id: \.self)`;
  each row shows `code` · `currencySymbol(code)` · `currencyDisplayName(code)` with a checkmark
  on the selected; tapping sets `code`.
- `SettingsView`: a "Currency" `NavigationLink` with the current code as its trailing value.
- Each money view adds `@AppStorage("currencyCode") private var currencyCode = deviceCurrencyCode()`
  and passes `currencyCode:` into `formattedMoney`. `EntryView` also uses `currencySymbol(currencyCode)`
  for the big amount and `currencyFractionDigits(currencyCode:)` for `AmountInput`.

Because every formatter reads `@AppStorage`, changing the currency re-renders them all.

## Call sites to update
`TxRow`, `DayCard`, `NetTotalHeader` (Home); `SpendLegend`, `InsightsView` center (Insights);
`EntryView` amount symbol + keypad fraction digits.

## Testing
- **Unit:** `currencyChoices` (non-empty, includes "USD"); `deviceCurrencyCode()` non-empty;
  `currencySymbol("USD") == "$"`; `formattedMoney(Decimal(-612), currencyCode: "USD") == "-$612.00"`;
  `formattedMoney(_, currencyCode: "JPY")` has no decimals; `currencyFractionDigits("USD") == 2`,
  `("JPY") == 0`. Update existing `FormattingTests` from `locale:` to `currencyCode:`.
- **Views:** `#Preview` + simulator (pick a currency → Home/Insights/Entry update; JPY blocks decimals).

## Slicing — 2 PRs
| PR | Branch | Delivers | Tested |
|---|---|---|---|
| 1 | `feature/currency-logic` | `Currency.swift`; `formattedMoney`/`currencyFractionDigits` → `currencyCode:`; update all call sites to pass `deviceCurrencyCode()` (behavior unchanged); update tests | Unit |
| 2 | `feature/currency-picker` | swap call sites to `@AppStorage("currencyCode")`; `CurrencyView` + Settings row | `#Preview` + sim |

## References
- `design_handoff_plop/README.md` (Settings → Currency) · `app/dialogs.jsx` · `app/store.jsx`
