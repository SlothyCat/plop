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
            let spreadsheet = try await findOrCreateSpreadsheet(year: year, folderID: folderID)
            try await writeYear(spreadsheet: spreadsheet, sheets: byYear[year] ?? [])
            lastURL = URL(string: spreadsheet.url)
        }

        guard let url = lastURL else { throw ExportError.unknown }
        return url
    }

    // MARK: steps

    private func writeYear(spreadsheet: (id: String, url: String),
                           sheets: [MonthSheet]) async throws {
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
    }

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
