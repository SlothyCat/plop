//
//  plopUITests.swift
//  plopUITests
//
//  Created by Wen Kang Yap on 2/6/26.
//

import XCTest

final class plopUITests: XCTestCase {
    /// End-to-end smoke test of the core loop: add an expense via the keypad and
    /// confirm it appears on Home. (Not run in CI — CI is scoped to plopTests.)
    @MainActor
    func test_addExpense_appearsOnHome() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["centerButton"].tap()        // open Entry (add mode)
        app.buttons["key-1"].tap()
        app.buttons["key-2"].tap()
        app.buttons["categoryButton"].tap()      // open the category picker
        app.buttons["category-Food"].tap()       // pick a seeded category (required)
        app.buttons["key-confirm"].tap()         // save a $12 Food expense, dismiss

        // Back on Home: the new row should show its category.
        XCTAssertTrue(
            app.staticTexts["Food"].waitForExistence(timeout: 5),
            "Expected the added transaction to appear on Home"
        )
    }
}
