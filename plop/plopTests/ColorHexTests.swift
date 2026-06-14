import XCTest
import SwiftUI
@testable import plop

final class ColorHexTests: XCTestCase {
    func test_parsesSixDigitHex() {
        let c = RGBA(hex: "#8CC0EB")
        XCTAssertEqual(c.red,   Double(0x8C) / 255, accuracy: 0.001)
        XCTAssertEqual(c.green, Double(0xC0) / 255, accuracy: 0.001)
        XCTAssertEqual(c.blue,  Double(0xEB) / 255, accuracy: 0.001)
        XCTAssertEqual(c.alpha, 1.0, accuracy: 0.001)
    }

    func test_toleratesMissingHash() {
        XCTAssertEqual(RGBA(hex: "FFFFFF").red, 1.0, accuracy: 0.001)
    }

    func test_invalidHexFallsBackToBlack() {
        let c = RGBA(hex: "zzz")
        XCTAssertEqual(c.red + c.green + c.blue, 0, accuracy: 0.001)
    }

    func test_toHex_roundTripsSwatch() {
        XCTAssertEqual(Color(hex: "#8CC0EB").toHex(), "#8CC0EB")
        XCTAssertEqual(Color(hex: "#FFEBCC").toHex(), "#FFEBCC")
    }
}
