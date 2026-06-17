import XCTest
@testable import plop

@MainActor
final class ExportServiceTests: XCTestCase {

    private let sheets = [MonthSheet(year: 2026, month: 6, values: [["x"]])]
    private let url = URL(string: "https://docs.google.com/SS")!

    func test_run_success_setsSuccessPhase() async {
        let service = ExportService(authorize: { "TOKEN" },
                                    upload: { _, _ in self.url })
        await service.run(monthSheets: sheets)
        XCTAssertEqual(service.phase, .success(url))
    }

    func test_run_authFailure_mapsToFailure() async {
        let service = ExportService(authorize: { throw ExportError.cancelled },
                                    upload: { _, _ in self.url })
        await service.run(monthSheets: sheets)
        XCTAssertEqual(service.phase, .failure(.cancelled))
    }

    func test_run_uploadFailure_mapsToFailure() async {
        let service = ExportService(authorize: { "TOKEN" },
                                    upload: { _, _ in throw ExportError.storageFull })
        await service.run(monthSheets: sheets)
        XCTAssertEqual(service.phase, .failure(.storageFull))
    }

    func test_run_networkError_mappedThroughExportError() async {
        let service = ExportService(authorize: { throw URLError(.notConnectedToInternet) },
                                    upload: { _, _ in self.url })
        await service.run(monthSheets: sheets)
        XCTAssertEqual(service.phase, .failure(.network))
    }

    func test_run_passesTokenAndSheetsToUpload() async {
        var seenToken: String?
        var seenCount: Int?
        let service = ExportService(authorize: { "TOK" },
                                    upload: { token, sheets in
                                        seenToken = token; seenCount = sheets.count; return self.url
                                    })
        await service.run(monthSheets: sheets)
        XCTAssertEqual(seenToken, "TOK")
        XCTAssertEqual(seenCount, 1)
    }
}
