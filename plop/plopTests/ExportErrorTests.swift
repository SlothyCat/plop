import XCTest
@testable import plop

final class ExportErrorTests: XCTestCase {

    func test_cancelled_hasNoMessage() {
        XCTAssertNil(ExportError.cancelled.message)
    }

    func test_eachOtherCase_hasMessage() {
        for e in [ExportError.consentDenied, .network, .signInFailed,
                  .storageFull, .rateLimited, .serverError, .unknown] {
            XCTAssertFalse(e.message?.isEmpty ?? true, "\(e) should have a message")
        }
    }

    func test_unknown_mentionsBugReport() {
        XCTAssertEqual(ExportError.unknown.message,
                       "Export failed. Please try again in a while, or submit a bug report.")
    }

    func test_mapStatus_authAndQuota() {
        let quota = Data(#"{"error":{"errors":[{"reason":"storageQuotaExceeded"}],"code":403}}"#.utf8)
        let rate = Data(#"{"error":{"errors":[{"reason":"rateLimitExceeded"}],"code":403}}"#.utf8)
        XCTAssertEqual(exportError(status: 401, body: Data()), .signInFailed)
        XCTAssertEqual(exportError(status: 403, body: quota), .storageFull)
        XCTAssertEqual(exportError(status: 403, body: rate), .rateLimited)
        XCTAssertEqual(exportError(status: 403, body: Data()), .unknown)
        XCTAssertEqual(exportError(status: 429, body: Data()), .rateLimited)
        XCTAssertEqual(exportError(status: 503, body: Data()), .serverError)
        XCTAssertEqual(exportError(status: 418, body: Data()), .unknown)
    }

    func test_mapError_networkAndPassthrough() {
        XCTAssertEqual(exportError(from: URLError(.notConnectedToInternet)), .network)
        XCTAssertEqual(exportError(from: ExportError.storageFull), .storageFull)
        XCTAssertEqual(exportError(from: NSError(domain: "x", code: 1)), .unknown)
    }
}
