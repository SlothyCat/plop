# PR1 — Currency Logic & Format Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline, no worktrees). Steps use `- [ ]`.

**Goal:** Add `Currency.swift` helpers and switch money formatting from a `locale:` param to a `currencyCode:` param — updating every call site to pass `deviceCurrencyCode()` so behavior is unchanged (device-locale). No picker UI yet.

**Architecture:** New pure `Logic/Currency.swift` (curated list + helpers, incl. the moved `currencyFractionDigits`). `formattedMoney`/`currencyFractionDigits` take a `currencyCode:` using `NumberFormatter.currencyCode` (symbol + decimals natively). The signature change forces an atomic update of all call sites in one task.

**Tech Stack:** Swift, Foundation, XCTest. iOS 18.

---

## Conventions
- Branch `feature/currency-logic` off `main`. No worktrees.
- Commit present-tense + `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- Tests: `xcodebuild test -project plop/plop.xcodeproj -scheme plop -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -parallel-testing-enabled NO -only-testing:plopTests[/CLASS]`
- Bogus crashes → `memory/xcode-build-sim-gotchas.md`.

## File Structure
- Create `plop/plop/Logic/Currency.swift`
- Create `plop/plopTests/CurrencyTests.swift`
- Modify `plop/plop/Logic/Formatting.swift` (formattedMoney → currencyCode)
- Modify `plop/plop/Views/Entry/AmountInput.swift` (remove currencyFractionDigits — moves to Currency)
- Modify `plop/plopTests/FormattingTests.swift` (locale → currencyCode)
- Modify call sites: `TxRow`, `DayCard`, `NetTotalHeader`, `SpendLegend`, `InsightsView`, `EntryView`

---

### Task 1: `Currency.swift` (helpers, no fraction digits yet)

**Files:** create `Currency.swift`, `CurrencyTests.swift`.

- [ ] **Step 1: Branch**
```bash
git checkout main && git pull --ff-only && git checkout -b feature/currency-logic
```

- [ ] **Step 2: Write the failing tests**

`plop/plopTests/CurrencyTests.swift`:
```swift
import XCTest
@testable import plop

final class CurrencyTests: XCTestCase {
    func test_choices_nonEmptyAndIncludeUSD() {
        XCTAssertFalse(currencyChoices.isEmpty)
        XCTAssertTrue(currencyChoices.contains("USD"))
    }
    func test_deviceCurrencyCode_nonEmpty() {
        XCTAssertFalse(deviceCurrencyCode().isEmpty)
    }
    func test_symbol_forUSD() {
        XCTAssertEqual(currencySymbol("USD"), "$")
    }
}
```

- [ ] **Step 3: Run to verify it fails**
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/CurrencyTests/test_symbol_forUSD
```
Expected: FAIL — `cannot find 'currencySymbol'`.

- [ ] **Step 4: Implement `Currency.swift`**
```swift
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

func currencySymbol(_ code: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = code
    return formatter.currencySymbol ?? code
}
```

- [ ] **Step 5: Run to verify it passes, then commit**
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/CurrencyTests
```
Expected: PASS (3).
```bash
git add plop/plop/Logic/Currency.swift plop/plopTests/CurrencyTests.swift
git commit -m "Add Currency helpers (choices, device default, name, symbol)"
```

---

### Task 2: Refactor formatting to `currencyCode:` + update all call sites (atomic)

This single task changes the signatures and every caller so `main` keeps building.

**Files:** modify `Formatting.swift`, `AmountInput.swift`, `Currency.swift`,
`FormattingTests.swift`, `CurrencyTests.swift`, and the six view files.

- [ ] **Step 1: Move `currencyFractionDigits` into `Currency.swift` (with `currencyCode:`)**

In `plop/plop/Views/Entry/AmountInput.swift`, **delete** the existing function at the bottom:
```swift
/// Max fraction digits for the active currency (e.g. 2 for USD, 0 for JPY/KRW).
func currencyFractionDigits(locale: Locale = .current) -> Int {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = locale
    return formatter.maximumFractionDigits
}
```
Append to `plop/plop/Logic/Currency.swift`:
```swift
/// Max fraction digits for a currency (2 for USD, 0 for JPY/KRW).
func currencyFractionDigits(currencyCode: String) -> Int {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode
    return formatter.maximumFractionDigits
}
```

- [ ] **Step 2: Change `formattedMoney` in `Formatting.swift`**

Replace the `formattedMoney` function (leave `dayLabel` untouched):
```swift
/// Currency string for an already-signed amount. `signed: true` forces an explicit
/// +/- prefix (rows); otherwise only negatives get a leading "-".
func formattedMoney(_ amount: Decimal, signed: Bool = false, currencyCode: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode
    let magnitude = NSDecimalNumber(decimal: abs(amount))
    let body = formatter.string(from: magnitude) ?? "\(abs(amount))"
    if signed { return (amount < 0 ? "-" : "+") + body }
    return amount < 0 ? "-" + body : body
}
```

- [ ] **Step 3: Update the tests**

In `plop/plopTests/FormattingTests.swift`, remove `private let enUS = Locale(identifier: "en_US")`
and change the two money tests to:
```swift
    func test_money_unsignedNegativeShowsMinus() {
        XCTAssertEqual(formattedMoney(Decimal(-612), signed: false, currencyCode: "USD"), "-$612.00")
    }

    func test_money_signedPositiveShowsPlus() {
        XCTAssertEqual(formattedMoney(Decimal(1200), signed: true, currencyCode: "USD"), "+$1,200.00")
    }
```
Append to `plop/plopTests/CurrencyTests.swift` inside `CurrencyTests`:
```swift
    func test_fractionDigits_perCurrency() {
        XCTAssertEqual(currencyFractionDigits(currencyCode: "USD"), 2)
        XCTAssertEqual(currencyFractionDigits(currencyCode: "JPY"), 0)
    }

    func test_money_jpyHasNoDecimals() {
        XCTAssertFalse(formattedMoney(Decimal(100), currencyCode: "JPY").contains("."))
    }
```

- [ ] **Step 4: Update the five `formattedMoney` call sites**

Pass `currencyCode: deviceCurrencyCode()` (behavior unchanged):
- `plop/plop/Views/Home/TxRow.swift`: `formattedMoney(amount, signed: true)` →
  `formattedMoney(amount, signed: true, currencyCode: deviceCurrencyCode())`
- `plop/plop/Views/Home/DayCard.swift`: `formattedMoney(group.subtotal)` →
  `formattedMoney(group.subtotal, currencyCode: deviceCurrencyCode())`
- `plop/plop/Views/Home/NetTotalHeader.swift`: `formattedMoney(net)` →
  `formattedMoney(net, currencyCode: deviceCurrencyCode())`
- `plop/plop/Views/Insights/SpendLegend.swift`: `formattedMoney(item.amount)` →
  `formattedMoney(item.amount, currencyCode: deviceCurrencyCode())`
- `plop/plop/Views/Insights/InsightsView.swift`: `formattedMoney(total)` →
  `formattedMoney(total, currencyCode: deviceCurrencyCode())`

- [ ] **Step 5: Update `EntryView.swift` (symbol + fraction digits)**

- Replace the amount-input initializer:
  `@State private var input = AmountInput(maxFractionDigits: currencyFractionDigits())`
  →
  `@State private var input = AmountInput(maxFractionDigits: currencyFractionDigits(currencyCode: deviceCurrencyCode()))`
- In `prefillIfEditing()`:
  `input = AmountInput(value: tx.amount, maxFractionDigits: currencyFractionDigits())`
  →
  `input = AmountInput(value: tx.amount, maxFractionDigits: currencyFractionDigits(currencyCode: deviceCurrencyCode()))`
- Replace the private symbol property and its use: delete
  `private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }`
  and change `Text(currencySymbol)` (in `amountArea`) to
  `Text(currencySymbol(deviceCurrencyCode()))`.

- [ ] **Step 6: Build + run the whole suite**
```bash
xcrun simctl shutdown all 2>/dev/null; sleep 2
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO
```
Expected: all pass (53 existing + 5 new Currency tests = 58; FormattingTests count unchanged). `** TEST SUCCEEDED **`.

- [ ] **Step 7: Commit**
```bash
git add plop/plop/Logic/Formatting.swift plop/plop/Logic/Currency.swift \
        plop/plop/Views/Entry/AmountInput.swift plop/plopTests/FormattingTests.swift \
        plop/plopTests/CurrencyTests.swift \
        plop/plop/Views/Home/TxRow.swift plop/plop/Views/Home/DayCard.swift \
        plop/plop/Views/Home/NetTotalHeader.swift plop/plop/Views/Insights/SpendLegend.swift \
        plop/plop/Views/Insights/InsightsView.swift plop/plop/Views/Entry/EntryView.swift
git commit -m "Format money by currencyCode (device default); move currencyFractionDigits"
```

---

### Task 3: Lint + PR

- [ ] **Step 1: Lint**
```bash
swiftlint lint
```
Expected: no errors.

- [ ] **Step 2: Push + PR**
```bash
git push -u origin feature/currency-logic
```
Open PR `feature/currency-logic` → `main` via GitHub web; confirm CI green.

---

## Self-review notes
- **Spec coverage:** `Currency.swift` helpers (T1); `formattedMoney`/`currencyFractionDigits`
  → `currencyCode:` + all call sites pass `deviceCurrencyCode()` (T2). Picker UI is PR2.
- **Atomicity:** signature change + every caller updated in Task 2 so `main` always builds.
- **Behavior unchanged:** `deviceCurrencyCode()` reproduces the prior device-locale formatting.
- **Type consistency:** `formattedMoney(_:signed:currencyCode:)`, `currencyFractionDigits(currencyCode:)`,
  `currencySymbol(_:)`, `deviceCurrencyCode()`, `currencyChoices`, `currencyCodeKey` used identically.
- **Note:** `currencyFractionDigits` moves from `AmountInput.swift` to `Currency.swift` (one definition only).
