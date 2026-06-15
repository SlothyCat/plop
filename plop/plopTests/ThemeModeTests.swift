import XCTest
import SwiftUI
@testable import plop

final class ThemeModeTests: XCTestCase {

    func test_rawValues() {
        XCTAssertEqual(ThemeMode.light.rawValue, "light")
        XCTAssertEqual(ThemeMode.dark.rawValue, "dark")
        XCTAssertEqual(ThemeMode.automatic.rawValue, "automatic")
    }

    func test_allCases_isThree() {
        XCTAssertEqual(ThemeMode.allCases.count, 3)
    }

    func test_colorScheme_mapping() {
        XCTAssertEqual(ThemeMode.light.colorScheme, .light)
        XCTAssertEqual(ThemeMode.dark.colorScheme, .dark)
        XCTAssertNil(ThemeMode.automatic.colorScheme)
    }
}
