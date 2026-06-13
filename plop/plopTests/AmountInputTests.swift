import XCTest
@testable import plop

final class AmountInputTests: XCTestCase {
    private let enUS = Locale(identifier: "en_US")

    func test_digitsBuildValue() {
        var a = AmountInput()
        a.press("1"); a.press("2"); a.press("5")
        XCTAssertEqual(a.value, Decimal(125))
    }

    func test_leadingZeroIsReplaced() {
        var a = AmountInput()
        a.press("0"); a.press("5")
        XCTAssertEqual(a.value, Decimal(5))
        XCTAssertEqual(a.display(locale: enUS), "5")
    }

    func test_singleDecimalPointOnly() {
        var a = AmountInput()
        a.press("1"); a.press("."); a.press("."); a.press("5")
        XCTAssertEqual(a.value, Decimal(string: "1.5"))
    }

    func test_decimalOnEmptyStartsZero() {
        var a = AmountInput()
        a.press(".")
        XCTAssertEqual(a.display(locale: enUS), "0.")
    }

    func test_clampsToTwoFractionDigits() {
        var a = AmountInput(maxFractionDigits: 2)
        for k in ["1", ".", "2", "3", "4"] { a.press(k) }
        XCTAssertEqual(a.value, Decimal(string: "1.23"))
    }

    func test_zeroFractionDigitsRejectsDecimal() {
        var a = AmountInput(maxFractionDigits: 0)
        a.press("5"); a.press("."); a.press("0")
        XCTAssertEqual(a.value, Decimal(50))
    }

    func test_backspace() {
        var a = AmountInput()
        a.press("1"); a.press("2"); a.backspace()
        XCTAssertEqual(a.value, Decimal(1))
    }

    func test_canSave() {
        var a = AmountInput()
        XCTAssertFalse(a.canSave)
        a.press("0")
        XCTAssertFalse(a.canSave)
        a.press("1")
        XCTAssertTrue(a.canSave)
    }

    func test_displayGroupsThousands() {
        var a = AmountInput()
        for k in ["1", "2", "3", "4"] { a.press(k) }
        XCTAssertEqual(a.display(locale: enUS), "1,234")
    }

    func test_initFromValue() {
        let a = AmountInput(value: Decimal(string: "12.5")!)
        XCTAssertEqual(a.value, Decimal(string: "12.5"))
    }
}
