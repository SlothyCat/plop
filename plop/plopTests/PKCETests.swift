import XCTest
@testable import plop

final class PKCETests: XCTestCase {

    func test_base64URL_isURLSafeAndUnpadded() {
        // 0xFB 0xFF encodes to "+/8=" in standard base64 → "-_8" url-safe, no pad.
        let out = PKCE.base64URL(Data([0xFB, 0xFF]))
        XCTAssertFalse(out.contains("+"))
        XCTAssertFalse(out.contains("/"))
        XCTAssertFalse(out.contains("="))
        XCTAssertEqual(out, "-_8")
    }

    func test_verifier_lengthAndCharset() {
        let v = PKCE.makeVerifier()
        XCTAssertEqual(v.count, 43)   // 32 random bytes → 43 base64url chars
        let allowed = CharacterSet(charactersIn:
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        XCTAssertTrue(v.unicodeScalars.allSatisfy { allowed.contains($0) })
    }

    func test_verifier_isRandom() {
        XCTAssertNotEqual(PKCE.makeVerifier(), PKCE.makeVerifier())
    }

    func test_challenge_knownVector() {
        // RFC 7636 Appendix B.
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        XCTAssertEqual(PKCE.challenge(for: verifier),
                       "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    func test_authorizationURL_hasExpectedQuery() {
        let url = PKCE.authorizationURL(clientID: "CID.apps.googleusercontent.com",
                                        redirectScheme: "com.googleusercontent.apps.CID",
                                        codeChallenge: "CHAL",
                                        scope: "https://www.googleapis.com/auth/drive.file")
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let items = Dictionary(uniqueKeysWithValues:
            (comps.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(comps.host, "accounts.google.com")
        XCTAssertEqual(items["client_id"], "CID.apps.googleusercontent.com")
        XCTAssertEqual(items["response_type"], "code")
        XCTAssertEqual(items["code_challenge"], "CHAL")
        XCTAssertEqual(items["code_challenge_method"], "S256")
        XCTAssertEqual(items["scope"], "https://www.googleapis.com/auth/drive.file")
        XCTAssertEqual(items["redirect_uri"], "com.googleusercontent.apps.CID:/oauth")
    }
}
