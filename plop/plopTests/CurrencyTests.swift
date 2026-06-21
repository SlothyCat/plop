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
        XCTAssertTrue(currencySymbol("USD").contains("$"), currencySymbol("USD"))
    }

    func test_fractionDigits_perCurrency() {
        XCTAssertEqual(currencyFractionDigits(currencyCode: "USD"), 2)
        XCTAssertEqual(currencyFractionDigits(currencyCode: "JPY"), 0)
    }

    func test_money_jpyHasNoDecimals() {
        XCTAssertFalse(formattedMoney(Decimal(100), currencyCode: "JPY").contains("."))
    }

    func test_currencyFlag_mapsCodeToRegionFlag() {
        XCTAssertEqual(currencyFlag("USD"), "🇺🇸")
        XCTAssertEqual(currencyFlag("EUR"), "🇪🇺")
        XCTAssertEqual(currencyFlag("GBP"), "🇬🇧")
        XCTAssertEqual(currencyFlag("CHF"), "🇨🇭")
        XCTAssertEqual(currencyFlag("JPY"), "🇯🇵")
    }

    func test_currencyFlag_allChoicesNonEmpty() {
        for code in currencyChoices {
            XCTAssertFalse(currencyFlag(code).isEmpty, "no flag for \(code)")
        }
    }

    func test_currencyFlag_emptyForBadCode() {
        XCTAssertEqual(currencyFlag("1"), "")
    }
}
