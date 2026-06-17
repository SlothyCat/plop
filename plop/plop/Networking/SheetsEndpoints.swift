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
        struct File: Decodable { let id: String }
        struct Payload: Decodable { let files: [File] }
        return (try? JSONDecoder().decode(Payload.self, from: data))?.files.first?.id
    }

    static func createdID(_ data: Data) throws -> String {
        struct Payload: Decodable { let id: String }
        return try JSONDecoder().decode(Payload.self, from: data).id
    }

    static func spreadsheet(_ data: Data) throws -> (id: String, url: String) {
        struct Payload: Decodable { let spreadsheetId: String; let spreadsheetUrl: String }
        let result = try JSONDecoder().decode(Payload.self, from: data)
        return (result.spreadsheetId, result.spreadsheetUrl)
    }

    static func tabTitles(_ data: Data) -> [String] {
        struct Props: Decodable { let title: String }
        struct Sheet: Decodable { let properties: Props }
        struct Payload: Decodable { let sheets: [Sheet] }
        return ((try? JSONDecoder().decode(Payload.self, from: data))?.sheets ?? [])
            .map { $0.properties.title }
    }

    // MARK: helpers

    private static func encode(_ str: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        return str.addingPercentEncoding(withAllowedCharacters: allowed) ?? str
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
        req.httpBody = try? JSONSerialization.data(withJSONObject: object, options: .withoutEscapingSlashes)
        return req
    }
}
