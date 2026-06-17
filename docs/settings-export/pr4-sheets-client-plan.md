# Export PR4 — SheetsClient Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the Drive + Sheets networking client that, given an access token and the per-month value matrices, finds/creates the `plop-transactions` folder → `plop {year}` spreadsheet → month tabs, then clears and rewrites each tab. No UI; no auth UI.

**Architecture:** Pure request-builders + response-parsers in `SheetsEndpoints.swift` (fully unit-tested), and an async `SheetsClient` that sequences them over an injected `URLSession`, mapping non-2xx to `ExportError`. Tested with `MockURLProtocol` routing by method+path.

**Tech Stack:** Swift, Foundation, XCTest (`MockURLProtocol`). iOS 18.

> **Re-slice note:** PR4 is just `SheetsClient`; the thin `ExportService` orchestrator + the `ExportSheet` UI are PR5.

Branch: `feature/export-sheets-client` (off `main`, which has PR1–PR3 + wiring).

---

## File structure

- **Create** `plop/plop/Networking/SheetsEndpoints.swift` — pure `URLRequest` builders + JSON parsers for Drive/Sheets.
- **Create** `plop/plop/Networking/SheetsClient.swift` — async client: folder/spreadsheet/tab find-or-create + clear/write + `upload`.
- **Create** `plop/plopTests/SheetsEndpointsTests.swift`, `plop/plopTests/SheetsClientTests.swift`.

### Verified existing symbols this builds on

- `MonthSheet` (`year: Int`, `month: Int`, `values: [[String]]`, `tabTitle: String` = `"yyyy-MM"`).
- `ExportError`, `exportError(status:body:)`, `exportError(from:)`.
- `MockURLProtocol` (test seam: `MockURLProtocol.handler`, `MockURLProtocol.session()`).

### Google API endpoints used (drive.file scope)

| Purpose | Method | URL |
|---|---|---|
| Find file/folder by name | GET | `https://www.googleapis.com/drive/v3/files?q=…&fields=files(id,name)&spaces=drive` |
| Create folder | POST | `https://www.googleapis.com/drive/v3/files` (`{name, mimeType: application/vnd.google-apps.folder}`) |
| Create spreadsheet | POST | `https://sheets.googleapis.com/v4/spreadsheets` (`{properties:{title}}`) |
| Move file into folder | PATCH | `https://www.googleapis.com/drive/v3/files/{id}?addParents={folder}&removeParents=root&fields=id` |
| Get tab titles | GET | `https://sheets.googleapis.com/v4/spreadsheets/{id}?fields=sheets.properties.title` |
| Add tabs | POST | `https://sheets.googleapis.com/v4/spreadsheets/{id}:batchUpdate` (`{requests:[{addSheet:{properties:{title}}}]}`) |
| Clear a tab | POST | `https://sheets.googleapis.com/v4/spreadsheets/{id}/values/{range}:clear` |
| Write a tab (RAW) | PUT | `https://sheets.googleapis.com/v4/spreadsheets/{id}/values/{range}?valueInputOption=RAW` (`{values:[[…]]}`) |

All requests carry `Authorization: Bearer <token>`; bodies are JSON (`Content-Type: application/json`).

### Test / build commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests/SheetsEndpointsTests -only-testing:plopTests/SheetsClientTests \
  -parallel-testing-enabled NO 2>&1 | tail -30

swiftlint lint
```

> SourceKit false positives for new files are expected — xcodebuild is the source of truth. Lines ≤ 120 (SwiftLint). No `// swiftlint:disable` comments (the repo keeps a zero-disable baseline).

---

## Task 1: SheetsEndpoints (pure builders + parsers)

**Files:**
- Create: `plop/plop/Networking/SheetsEndpoints.swift`
- Create: `plop/plopTests/SheetsEndpointsTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/SheetsEndpointsTests.swift`:

```swift
import XCTest
@testable import plop

final class SheetsEndpointsTests: XCTestCase {

    private func auth(_ req: URLRequest) -> String? {
        req.value(forHTTPHeaderField: "Authorization")
    }
    private func bodyString(_ req: URLRequest) -> String {
        String(data: req.httpBody ?? Data(), encoding: .utf8) ?? ""
    }

    // MARK: search

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

    // MARK: create

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
        // range is the tab title; ":clear" suffixes the values path
        XCTAssertTrue(req.url!.absoluteString.contains("/values/2026-06:clear"),
                      req.url!.absoluteString)
    }

    func test_writeRequest_rawValues() {
        let req = SheetsEndpoints.write(token: "T", spreadsheetID: "S1", tab: "2026-06",
                                        values: [["A", "B"], ["1", "2"]])
        XCTAssertEqual(req.httpMethod, "PUT")
        let url = req.url!.absoluteString
        XCTAssertTrue(url.contains("/values/2026-06"), url)          // range starts with tab
        XCTAssertTrue(url.contains("valueInputOption=RAW"), url)
        XCTAssertTrue(bodyString(req).contains("\"values\""), bodyString(req))
    }

    // MARK: parsers

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
```

- [ ] **Step 2: Run the tests — confirm they FAIL to build.**

- [ ] **Step 3: Implement**

Create `plop/plop/Networking/SheetsEndpoints.swift`:

```swift
import Foundation

/// Pure builders + parsers for the Drive/Sheets REST calls used by SheetsClient.
/// drive.file scope. No networking here.
enum SheetsEndpoints {
    static let folderName = "plop-transactions"
    static let folderMime = "application/vnd.google-apps.folder"

    private static let driveFiles = "https://www.googleapis.com/drive/v3/files"
    private static let sheets = "https://sheets.googleapis.com/v4/spreadsheets"

    // MARK: requests

    static func search(token: String, name: String, mimeType: String?, parentID: String?) -> URLRequest {
        var q = "name = '\(name)' and trashed = false"
        if let mimeType { q += " and mimeType = '\(mimeType)'" }
        if let parentID { q += " and '\(parentID)' in parents" }
        var comps = URLComponents(string: driveFiles)!
        comps.queryItems = [
            URLQueryItem(name: "q", value: q),
            URLQueryItem(name: "fields", value: "files(id,name)"),
            URLQueryItem(name: "spaces", value: "drive")
        ]
        return get(comps.url!, token: token)
    }

    static func createFolder(token: String, name: String) -> URLRequest {
        jsonBody(post(URL(string: driveFiles)!, token: token),
                 ["name": name, "mimeType": folderMime])
    }

    static func createSpreadsheet(token: String, title: String) -> URLRequest {
        jsonBody(post(URL(string: sheets)!, token: token),
                 ["properties": ["title": title]])
    }

    static func moveFile(token: String, fileID: String, folderID: String) -> URLRequest {
        var comps = URLComponents(string: "\(driveFiles)/\(fileID)")!
        comps.queryItems = [
            URLQueryItem(name: "addParents", value: folderID),
            URLQueryItem(name: "removeParents", value: "root"),
            URLQueryItem(name: "fields", value: "id")
        ]
        var req = authed(comps.url!, token: token)
        req.httpMethod = "PATCH"
        return req
    }

    static func getTabs(token: String, spreadsheetID: String) -> URLRequest {
        var comps = URLComponents(string: "\(sheets)/\(spreadsheetID)")!
        comps.queryItems = [URLQueryItem(name: "fields", value: "sheets.properties.title")]
        return get(comps.url!, token: token)
    }

    static func addTabs(token: String, spreadsheetID: String, titles: [String]) -> URLRequest {
        let requests = titles.map { ["addSheet": ["properties": ["title": $0]]] }
        return jsonBody(post(URL(string: "\(sheets)/\(spreadsheetID):batchUpdate")!, token: token),
                        ["requests": requests])
    }

    static func clear(token: String, spreadsheetID: String, tab: String) -> URLRequest {
        let range = encode(tab)
        let req = post(URL(string: "\(sheets)/\(spreadsheetID)/values/\(range):clear")!, token: token)
        return jsonBody(req, [:])
    }

    static func write(token: String, spreadsheetID: String, tab: String,
                      values: [[String]]) -> URLRequest {
        let range = encode("\(tab)!A1")
        var comps = URLComponents(string: "\(sheets)/\(spreadsheetID)/values/\(range)")!
        comps.queryItems = [URLQueryItem(name: "valueInputOption", value: "RAW")]
        var req = authed(comps.url!, token: token)
        req.httpMethod = "PUT"
        return jsonBody(req, ["values": values])
    }

    // MARK: parsers

    static func firstFileID(_ data: Data) -> String? {
        struct R: Decodable { struct F: Decodable { let id: String }; let files: [F] }
        return (try? JSONDecoder().decode(R.self, from: data))?.files.first?.id
    }

    static func createdID(_ data: Data) throws -> String {
        struct R: Decodable { let id: String }
        return try JSONDecoder().decode(R.self, from: data).id
    }

    static func spreadsheet(_ data: Data) throws -> (id: String, url: String) {
        struct R: Decodable { let spreadsheetId: String; let spreadsheetUrl: String }
        let r = try JSONDecoder().decode(R.self, from: data)
        return (r.spreadsheetId, r.spreadsheetUrl)
    }

    static func tabTitles(_ data: Data) -> [String] {
        struct R: Decodable { struct S: Decodable { struct P: Decodable { let title: String }
            let properties: P }
            let sheets: [S] }
        return ((try? JSONDecoder().decode(R.self, from: data))?.sheets ?? []).map { $0.properties.title }
    }

    // MARK: helpers

    private static func encode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? s
    }

    private static func authed(_ url: URL, token: String) -> URLRequest {
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return req
    }

    private static func get(_ url: URL, token: String) -> URLRequest {
        var req = authed(url, token: token)
        req.httpMethod = "GET"
        return req
    }

    private static func post(_ url: URL, token: String) -> URLRequest {
        var req = authed(url, token: token)
        req.httpMethod = "POST"
        return req
    }

    private static func jsonBody(_ request: URLRequest, _ object: Any) -> URLRequest {
        var req = request
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: object)
        return req
    }
}
```

> Note on `test_clearRequest_encodesRange` / `test_writeRequest_rawValues`: `encode`
> uses `.alphanumerics`, so the tab `2026-06` becomes `2026%2D06`? No — `-` is NOT
> alphanumeric, so it WOULD be encoded. **Adjust the allowed set to include `-`** so
> `2026-06` stays readable and the tests' `contains("/values/2026-06")` pass: use
> `CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))`. The `!A1` `!`
> still encodes (to `%21`), which Sheets accepts. Verify the tests pass and adjust the
> allowed set if needed.

- [ ] **Step 4: Run the tests — confirm PASS.** If `clear`/`write` range assertions fail because `-` got encoded, widen the `encode` allowed set to include `-` (as noted) and re-run.

- [ ] **Step 5: SwiftLint** — no new violations; **no disable comments**. The `tabTitles`
  parser uses triple-nested `Decodable` structs (`R › S › P`), which trips SwiftLint's
  `nesting` rule. If it fires, **flatten** them to sibling structs declared inside the
  function (as was done for `ExportError`'s `googleErrorReason`) rather than disabling:

  ```swift
  static func tabTitles(_ data: Data) -> [String] {
      struct Props: Decodable { let title: String }
      struct Sheet: Decodable { let properties: Props }
      struct Payload: Decodable { let sheets: [Sheet] }
      return ((try? JSONDecoder().decode(Payload.self, from: data))?.sheets ?? [])
          .map { $0.properties.title }
  }
  ```

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Networking/SheetsEndpoints.swift plop/plopTests/SheetsEndpointsTests.swift
git commit -m "Add Drive/Sheets request builders and response parsers

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: SheetsClient (async flow)

**Files:**
- Create: `plop/plop/Networking/SheetsClient.swift`
- Create: `plop/plopTests/SheetsClientTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/SheetsClientTests.swift`:

```swift
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
            return ok(#"{"files":[{"id":"FOLDER"}]}"#)          // folder exists
        case ("GET", let u) where u.contains("/drive/v3/files?"):
            return ok(#"{"files":[]}"#)                          // spreadsheet missing
        case ("POST", let u) where u.hasSuffix("/v4/spreadsheets"):
            return ok(#"{"spreadsheetId":"SS","spreadsheetUrl":"https://docs.google.com/SS"}"#)
        case ("PATCH", _):
            return ok(#"{"id":"SS"}"#)                           // move into folder
        case ("GET", let u) where u.contains("/v4/spreadsheets/SS?"):
            return ok(#"{"sheets":[]}"#)                         // no existing tabs
        case ("POST", let u) where u.contains(":batchUpdate"):
            return ok(#"{}"#)                                    // addSheet
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
```

- [ ] **Step 2: Run the tests — confirm they FAIL to build** (`SheetsClient` undefined).

- [ ] **Step 3: Implement**

Create `plop/plop/Networking/SheetsClient.swift`:

```swift
import Foundation

/// Uploads per-month value matrices to Google Sheets, organised as one spreadsheet
/// per year (`plop {year}`) inside a `plop-transactions` Drive folder, one tab per
/// month. Find-or-create + rewrite (idempotent). Stateless: the token is passed in.
struct SheetsClient {
    let token: String
    let session: URLSession

    /// Writes all month sheets and returns the URL of the last spreadsheet touched.
    func upload(monthSheets: [MonthSheet]) async throws -> URL {
        let folderID = try await findOrCreateFolder()

        var lastURL: URL?
        let byYear = Dictionary(grouping: monthSheets, by: { $0.year })
        for year in byYear.keys.sorted() {
            let sheets = byYear[year] ?? []
            let spreadsheet = try await findOrCreateSpreadsheet(year: year, folderID: folderID)
            let existing = Set(try await tabTitles(spreadsheetID: spreadsheet.id))
            let missing = sheets.map(\.tabTitle).filter { !existing.contains($0) }
            if !missing.isEmpty {
                try await send(SheetsEndpoints.addTabs(token: token,
                                                       spreadsheetID: spreadsheet.id, titles: missing))
            }
            for sheet in sheets {
                try await send(SheetsEndpoints.clear(token: token,
                                                     spreadsheetID: spreadsheet.id, tab: sheet.tabTitle))
                try await send(SheetsEndpoints.write(token: token, spreadsheetID: spreadsheet.id,
                                                     tab: sheet.tabTitle, values: sheet.values))
            }
            lastURL = URL(string: spreadsheet.url)
        }

        guard let url = lastURL else { throw ExportError.unknown }
        return url
    }

    // MARK: steps

    private func findOrCreateFolder() async throws -> String {
        let found = SheetsEndpoints.firstFileID(
            try await send(SheetsEndpoints.search(token: token, name: SheetsEndpoints.folderName,
                                                  mimeType: SheetsEndpoints.folderMime, parentID: nil)))
        if let found { return found }
        return try SheetsEndpoints.createdID(
            try await send(SheetsEndpoints.createFolder(token: token, name: SheetsEndpoints.folderName)))
    }

    private func findOrCreateSpreadsheet(year: Int,
                                         folderID: String) async throws -> (id: String, url: String) {
        let name = "plop \(year)"
        if let id = SheetsEndpoints.firstFileID(
            try await send(SheetsEndpoints.search(token: token, name: name,
                                                  mimeType: nil, parentID: folderID))) {
            // Existing: fetch its URL via the spreadsheets get (id is enough for writes; build URL).
            return (id, "https://docs.google.com/spreadsheets/d/\(id)")
        }
        let created = try SheetsEndpoints.spreadsheet(
            try await send(SheetsEndpoints.createSpreadsheet(token: token, title: name)))
        try await send(SheetsEndpoints.moveFile(token: token, fileID: created.id, folderID: folderID))
        return created
    }

    private func tabTitles(spreadsheetID: String) async throws -> [String] {
        SheetsEndpoints.tabTitles(
            try await send(SheetsEndpoints.getTabs(token: token, spreadsheetID: spreadsheetID)))
    }

    @discardableResult
    private func send(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status) else { throw exportError(status: status, body: data) }
            return data
        } catch let error as ExportError {
            throw error
        } catch {
            throw exportError(from: error)
        }
    }
}
```

- [ ] **Step 4: Run the tests — confirm PASS** (2 tests). Fix the implementation (not the tests) if needed.

- [ ] **Step 5: SwiftLint** — no new violations; no disable comments. (If `function_body_length` fires on `upload`, extract the per-year body into a private `uploadYear(_:sheets:folderID:)` helper rather than disabling.)

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Networking/SheetsClient.swift plop/plopTests/SheetsClientTests.swift
git commit -m "Add SheetsClient: folder/spreadsheet/tab find-create + rewrite

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` — all prior + `SheetsEndpointsTests` + `SheetsClientTests`.

- [ ] **Step 2: Lint** — `swiftlint lint` → no new violations, no disable comments.

- [ ] **Step 3: Push + PR**

```bash
git push -u origin feature/export-sheets-client
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Add SheetsClient: finds/creates the plop-transactions Drive folder → plop {year}
spreadsheet → month tabs, then clears + rewrites each tab from the SheetBuilder
matrices. Pure request builders/parsers + an async client. No UI — sets up PR5.

## Testing
All unit tests pass (N new); SwiftLint clean.
```
(Replace `N`.)

---

## Self-review notes

- **Spec coverage:** `plop-transactions` folder find/create; `plop {year}` per-year
  spreadsheet find/create + move-into-folder; month-tab ensure (addSheet); clear +
  RAW write per tab; idempotent find-or-rewrite; non-2xx → `ExportError` (incl.
  storageFull). `ExportService` orchestration + UI are PR5 — absent here.
- **Type consistency:** `SheetsEndpoints.{search,createFolder,createSpreadsheet,moveFile,getTabs,addTabs,clear,write,firstFileID,createdID,spreadsheet,tabTitles}` used identically in `SheetsClient` and tests; `SheetsClient(token:session:)` + `upload(monthSheets:)` match the tests; reuses `MonthSheet.tabTitle`, `exportError(status:body:)`/`exportError(from:)`, `MockURLProtocol`.
- **Determinism:** the upload test routes responses by method+URL (no ordering assumptions beyond the client's own sequence); years iterated sorted.
- **No placeholders / no disables:** complete code; lint-pressure points (range encoding, `upload` length) have explicit non-disable resolutions.
- **Known simplification:** for an *existing* `plop {year}`, the URL is reconstructed as `https://docs.google.com/spreadsheets/d/{id}` rather than a second GET — valid and avoids an extra round-trip.
