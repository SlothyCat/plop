import XCTest
@testable import plop

final class BugReportTests: XCTestCase {

    private func diagnostics(appVersion: String = "1.0", build: String = "1",
                             systemVersion: String = "18.4",
                             deviceModel: String = "iPhone") -> BugReport.Diagnostics {
        BugReport.Diagnostics(appVersion: appVersion, build: build,
                              systemName: "iOS", systemVersion: systemVersion,
                              deviceModel: deviceModel)
    }

    func test_constants() {
        XCTAssertEqual(BugReport.supportEmail, "slothycatcoder@gmail.com")
        XCTAssertEqual(BugReport.subject, "plop bug report")
    }

    func test_body_containsDescriptionFirst() {
        let body = BugReport.body(description: "It crashed on save", diagnostics: diagnostics())
        XCTAssertTrue(body.hasPrefix("It crashed on save"), body)
    }

    func test_body_containsDiagnostics() {
        let body = BugReport.body(description: "x",
                                  diagnostics: diagnostics(appVersion: "1.2", build: "34"))
        XCTAssertTrue(body.contains("plop 1.2 (34)"), body)
        XCTAssertTrue(body.contains("iOS 18.4"), body)
        XCTAssertTrue(body.contains("iPhone"), body)
        XCTAssertTrue(body.contains("Diagnostics"), body)
    }

    func test_body_emptyDescription_stillWellFormed() {
        let body = BugReport.body(description: "", diagnostics: diagnostics(systemVersion: "18.0"))
        XCTAssertTrue(body.contains("Diagnostics"), body)
    }
}
