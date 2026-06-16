import XCTest
@testable import plop

final class OAuthEndpointsTests: XCTestCase {

    func test_reversedClientScheme() {
        XCTAssertEqual(
            reversedClientScheme(clientID: "12345-abc.apps.googleusercontent.com"),
            "com.googleusercontent.apps.12345-abc")
    }

    func test_tokenRequest_shape() {
        let req = tokenRequest(code: "AC", verifier: "VER", clientID: "CID",
                               redirectURI: "com.example:/oauth")
        XCTAssertEqual(req.url?.absoluteString, "https://oauth2.googleapis.com/token")
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"),
                       "application/x-www-form-urlencoded")
        let body = String(data: req.httpBody ?? Data(), encoding: .utf8) ?? ""
        XCTAssertTrue(body.contains("grant_type=authorization_code"), body)
        XCTAssertTrue(body.contains("code=AC"), body)
        XCTAssertTrue(body.contains("code_verifier=VER"), body)
        XCTAssertTrue(body.contains("client_id=CID"), body)
        XCTAssertTrue(body.contains("redirect_uri="), body)
    }

    func test_parseAccessToken() throws {
        let data = Data(#"{"access_token":"ya29.TOKEN","expires_in":3599}"#.utf8)
        XCTAssertEqual(try parseAccessToken(data), "ya29.TOKEN")
    }

    func test_authCode_success() throws {
        let url = URL(string: "com.example:/oauth?code=THECODE&scope=x")!
        XCTAssertEqual(try authCode(fromRedirect: url), "THECODE")
    }

    func test_authCode_denied() {
        let url = URL(string: "com.example:/oauth?error=access_denied")!
        XCTAssertThrowsError(try authCode(fromRedirect: url)) {
            XCTAssertEqual($0 as? ExportError, .consentDenied)
        }
    }

    func test_authCode_missing() {
        let url = URL(string: "com.example:/oauth?foo=bar")!
        XCTAssertThrowsError(try authCode(fromRedirect: url)) {
            XCTAssertEqual($0 as? ExportError, .signInFailed)
        }
    }
}
