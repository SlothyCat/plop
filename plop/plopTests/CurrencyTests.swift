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
}
