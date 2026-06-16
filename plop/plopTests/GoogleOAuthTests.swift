import XCTest
@testable import plop

private struct FakeWebAuth: WebAuthenticating {
    let result: Result<URL, Error>
    func authenticate(authURL: URL, callbackScheme: String) async throws -> URL {
        try result.get()
    }
}

final class GoogleOAuthTests: XCTestCase {

    override func tearDown() { MockURLProtocol.handler = nil; super.tearDown() }

    private func oauth(web: WebAuthenticating) -> GoogleOAuth {
        GoogleOAuth(clientID: "12345-abc.apps.googleusercontent.com",
                    session: MockURLProtocol.session(), webAuth: web)
    }

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://oauth2.googleapis.com/token")!,
                        statusCode: status, httpVersion: nil, headerFields: nil)!
    }

    func test_authorize_returnsAccessToken() async throws {
        MockURLProtocol.handler = { _ in (self.http(200), Data(#"{"access_token":"ya29.OK"}"#.utf8)) }
        let redirect = URL(string: "com.googleusercontent.apps.12345-abc:/oauth?code=AC")!
        let token = try await oauth(web: FakeWebAuth(result: .success(redirect))).authorize()
        XCTAssertEqual(token, "ya29.OK")
    }

    func test_authorize_mapsStorageFull() async {
        MockURLProtocol.handler = { _ in
            (self.http(403), Data(#"{"error":{"errors":[{"reason":"storageQuotaExceeded"}]}}"#.utf8))
        }
        let redirect = URL(string: "com.googleusercontent.apps.12345-abc:/oauth?code=AC")!
        await assertThrows(.storageFull) {
            try await self.oauth(web: FakeWebAuth(result: .success(redirect))).authorize()
        }
    }

    func test_authorize_propagatesCancelled() async {
        await assertThrows(.cancelled) {
            try await self.oauth(web: FakeWebAuth(result: .failure(ExportError.cancelled))).authorize()
        }
    }

    func test_authorize_deniedConsent() async {
        let redirect = URL(string: "com.googleusercontent.apps.12345-abc:/oauth?error=access_denied")!
        await assertThrows(.consentDenied) {
            try await self.oauth(web: FakeWebAuth(result: .success(redirect))).authorize()
        }
    }

    private func assertThrows(_ expected: ExportError,
                              _ body: @escaping () async throws -> String,
                              file: StaticString = #file, line: UInt = #line) async {
        do {
            _ = try await body()
            XCTFail("expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? ExportError, expected, file: file, line: line)
        }
    }
}
