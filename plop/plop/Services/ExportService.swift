import Foundation
import Observation

/// Orchestrates an export: authorize → upload, publishing the phase for the UI.
/// `authorize`/`upload` are injected so the live wiring (GoogleOAuth + SheetsClient)
/// and tests (fakes) share one path. Stateless — no token is retained after `run`.
@MainActor
@Observable
final class ExportService {
    enum Phase: Equatable {
        case idle
        case running
        case success(URL)
        case failure(ExportError)
    }

    private(set) var phase: Phase = .idle

    private let authorize: () async throws -> String
    private let upload: (String, [MonthSheet]) async throws -> URL

    init(authorize: @escaping () async throws -> String,
         upload: @escaping (String, [MonthSheet]) async throws -> URL) {
        self.authorize = authorize
        self.upload = upload
    }

    func run(monthSheets: [MonthSheet]) async {
        phase = .running
        do {
            let token = try await authorize()
            phase = .success(try await upload(token, monthSheets))
        } catch {
            phase = .failure(exportError(from: error))
        }
    }
}

extension ExportService {
    /// Production wiring: real OAuth + Sheets client over URLSession.shared.
    @MainActor
    static func live() -> ExportService {
        ExportService(
            authorize: {
                try await GoogleOAuth(clientID: Secrets.googleClientID,
                                      session: .shared,
                                      webAuth: WebAuthenticator()).authorize()
            },
            upload: { token, sheets in
                try await SheetsClient(token: token, session: .shared).upload(monthSheets: sheets)
            })
    }
}
