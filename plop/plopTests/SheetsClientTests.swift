import XCTest
@testable import plop

final class SheetsClientTests: XCTestCase {

    override func tearDown() { MockURLProtocol.handler = nil; super.tearDown() }

    private func client() -> SheetsClient {
        SheetsClient(token: "T", session: MockURLProtocol.session())
    }
    private func ok(_ json: String) -> (HTTPURLResponse, Data) {
        (HTTPURLResponse(url: URL(string: "https://x")!, statusCode: 200,
                         httpVersion: nil, headerFields: nil)!, Data(json.utf8))
    }
    private func status(_ code: Int, _ json: String = "{}") -> (HTTPURLResponse, Data) {
        (HTTPURLResponse(url: URL(string: "https://x")!, statusCode: code,
                         httpVersion: nil, headerFields: nil)!, Data(json.utf8))
    }

    /// Routes a request to a canned response by method + URL substring.
    private func route(_ request: URLRequest) throws -> (HTTPURLResponse, Data) {
        let url = request.url!.absoluteString
        let method = request.httpMethod!
        switch (method, url) {
        case ("GET", let u) where u.contains("/drive/v3/files?") && u.contains("folder"):
            return ok(#"{"files":[{"id":"FOLDER"}]}"#)
        case ("GET", let u) where u.contains("/drive/v3/files?"):
            return ok(#"{"files":[]}"#)
        case ("POST", let u) where u.hasSuffix("/v4/spreadsheets"):
            return ok(#"{"spreadsheetId":"SS","spreadsheetUrl":"https://docs.google.com/SS"}"#)
        case ("PATCH", _):
            return ok(#"{"id":"SS"}"#)
        case ("GET", let u) where u.contains("/v4/spreadsheets/SS?"):
            return ok(#"{"sheets":[]}"#)
        case ("POST", let u) where u.contains(":batchUpdate"):
            return ok(#"{}"#)
        case ("POST", let u) where u.contains(":clear"):
            return ok(#"{}"#)
        case ("PUT", let u) where u.contains("/values/"):
            return ok(#"{}"#)
        default:
            XCTFail("unexpected request \(method) \(url)"); return status(500)
        }
    }

    func test_upload_happyPath_returnsSpreadsheetURL() async throws {
        MockURLProtocol.handler = route
        let sheets = [MonthSheet(year: 2026, month: 6, values: [["June 2026"], ["x", "1"]])]
        let url = try await client().upload(monthSheets: sheets)
        XCTAssertEqual(url.absoluteString, "https://docs.google.com/SS")
    }

    func test_upload_mapsStorageFull() async {
        MockURLProtocol.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://x")!, statusCode: 403,
                             httpVersion: nil, headerFields: nil)!,
             Data(#"{"error":{"errors":[{"reason":"storageQuotaExceeded"}]}}"#.utf8))
        }
        let sheets = [MonthSheet(year: 2026, month: 6, values: [["x"]])]
        do {
            _ = try await client().upload(monthSheets: sheets)
            XCTFail("expected throw")
        } catch {
            XCTAssertEqual(error as? ExportError, .storageFull)
        }
    }
}
