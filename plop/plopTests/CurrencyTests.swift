import XCTest
import UIKit
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

    func test_currencyRegionCode_mapsCodeToRegion() {
        XCTAssertEqual(currencyRegionCode("USD"), "us")
        XCTAssertEqual(currencyRegionCode("EUR"), "eu")
        XCTAssertEqual(currencyRegionCode("GBP"), "gb")
        XCTAssertEqual(currencyRegionCode("CHF"), "ch")
        XCTAssertEqual(currencyRegionCode("JPY"), "jp")
    }

    func test_currencyFlagAsset_namesBundledImage() {
        XCTAssertEqual(currencyFlagAsset("USD"), "flag-us")
        XCTAssertEqual(currencyFlagAsset("KRW"), "flag-kr")
    }

    func test_currencyFlagAsset_existsForEveryChoice() {
        for code in currencyChoices {
            XCTAssertNotNil(UIImage(named: currencyFlagAsset(code)),
                            "missing flag asset for \(code)")
        }
    }
}
