import XCTest
@testable import plop

final class SheetsEndpointsTests: XCTestCase {

    private func auth(_ req: URLRequest) -> String? {
        req.value(forHTTPHeaderField: "Authorization")
    }
    private func bodyString(_ req: URLRequest) -> String {
        String(data: req.httpBody ?? Data(), encoding: .utf8) ?? ""
    }

    func test_searchRequest_folder() {
        let req = SheetsEndpoints.search(token: "T", name: "plop-transactions",
                                         mimeType: "application/vnd.google-apps.folder",
                                         parentID: nil)
        XCTAssertEqual(req.httpMethod, "GET")
        XCTAssertEqual(auth(req), "Bearer T")
        let url = req.url!.absoluteString
        XCTAssertTrue(url.hasPrefix("https://www.googleapis.com/drive/v3/files"), url)
        let q = URLComponents(url: req.url!, resolvingAgainstBaseURL: false)!
            .queryItems!.first { $0.name == "q" }!.value!
        XCTAssertTrue(q.contains("name = 'plop-transactions'"), q)
        XCTAssertTrue(q.contains("mimeType = 'application/vnd.google-apps.folder'"), q)
        XCTAssertTrue(q.contains("trashed = false"), q)
    }

    func test_searchRequest_withParent() {
        let req = SheetsEndpoints.search(token: "T", name: "plop 2026", mimeType: nil, parentID: "F1")
        let q = URLComponents(url: req.url!, resolvingAgainstBaseURL: false)!
            .queryItems!.first { $0.name == "q" }!.value!
        XCTAssertTrue(q.contains("'F1' in parents"), q)
    }

    func test_createFolderRequest() {
        let req = SheetsEndpoints.createFolder(token: "T", name: "plop-transactions")
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(req.url!.absoluteString, "https://www.googleapis.com/drive/v3/files")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/json")
        let body = bodyString(req)
        XCTAssertTrue(body.contains("\"name\":\"plop-transactions\""), body)
        XCTAssertTrue(body.contains("application/vnd.google-apps.folder"), body)
    }

    func test_createSpreadsheetRequest() {
        let req = SheetsEndpoints.createSpreadsheet(token: "T", title: "plop 2026")
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(req.url!.absoluteString, "https://sheets.googleapis.com/v4/spreadsheets")
        XCTAssertTrue(bodyString(req).contains("\"title\":\"plop 2026\""), bodyString(req))
    }

    func test_moveFileRequest() {
        let req = SheetsEndpoints.moveFile(token: "T", fileID: "S1", folderID: "F1")
        XCTAssertEqual(req.httpMethod, "PATCH")
        let url = req.url!.absoluteString
        XCTAssertTrue(url.contains("/drive/v3/files/S1"), url)
        XCTAssertTrue(url.contains("addParents=F1"), url)
        XCTAssertTrue(url.contains("removeParents=root"), url)
    }

    func test_addTabsRequest() {
        let req = SheetsEndpoints.addTabs(token: "T", spreadsheetID: "S1", titles: ["2026-06", "2026-07"])
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertTrue(req.url!.absoluteString.hasSuffix("/v4/spreadsheets/S1:batchUpdate"))
        let body = bodyString(req)
        XCTAssertTrue(body.contains("\"title\":\"2026-06\""), body)
        XCTAssertTrue(body.contains("\"title\":\"2026-07\""), body)
        XCTAssertTrue(body.contains("addSheet"), body)
    }

    func test_clearRequest_encodesRange() {
        let req = SheetsEndpoints.clear(token: "T", spreadsheetID: "S1", tab: "2026-06")
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertTrue(req.url!.absoluteString.contains("/values/2026-06:clear"),
                      req.url!.absoluteString)
    }

    func test_writeRequest_rawValues() {
        let req = SheetsEndpoints.write(token: "T", spreadsheetID: "S1", tab: "2026-06",
                                        values: [["A", "B"], ["1", "2"]])
        XCTAssertEqual(req.httpMethod, "PUT")
        let url = req.url!.absoluteString
        XCTAssertTrue(url.contains("/values/2026-06"), url)
        XCTAssertTrue(url.contains("valueInputOption=RAW"), url)
        XCTAssertTrue(bodyString(req).contains("\"values\""), bodyString(req))
    }

    func test_parseFirstFileID() {
        let hit = Data(#"{"files":[{"id":"F1","name":"plop-transactions"}]}"#.utf8)
        let miss = Data(#"{"files":[]}"#.utf8)
        XCTAssertEqual(SheetsEndpoints.firstFileID(hit), "F1")
        XCTAssertNil(SheetsEndpoints.firstFileID(miss))
    }

    func test_parseCreatedID() throws {
        let data = Data(#"{"id":"NEW","name":"x"}"#.utf8)
        XCTAssertEqual(try SheetsEndpoints.createdID(data), "NEW")
    }

    func test_parseSpreadsheet() throws {
        let data = Data(#"{"spreadsheetId":"S1","spreadsheetUrl":"https://docs.google.com/x"}"#.utf8)
        let result = try SheetsEndpoints.spreadsheet(data)
        XCTAssertEqual(result.id, "S1")
        XCTAssertEqual(result.url, "https://docs.google.com/x")
    }

    func test_parseTabTitles() {
        let data = Data(#"{"sheets":[{"properties":{"title":"2026-06"}},{"properties":{"title":"Sheet1"}}]}"#.utf8)
        XCTAssertEqual(SheetsEndpoints.tabTitles(data), ["2026-06", "Sheet1"])
    }
}
