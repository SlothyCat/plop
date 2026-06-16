# Export PR3 — OAuth Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the stateless Google OAuth layer — interactive sign-in (PKCE) plus authorization-code → access-token exchange — behind testable seams, with the typed `ExportError` model. No Sheets/Drive calls, no UI yet.

**Architecture:** A `WebAuthenticating` protocol wraps `ASWebAuthenticationSession` (real impl thin/untested); `GoogleOAuth.authorize()` orchestrates PKCE → web auth → token exchange over an injected `URLSession`. Pure request-builders/parsers and the `ExportError` mapping are fully unit-tested (token exchange via a `URLProtocol` mock; web auth via a fake).

**Tech Stack:** Swift, Foundation, AuthenticationServices, XCTest (`URLProtocol` mock). iOS 18.

> **Re-slice note:** the spec's "PR3 (networking + service)" was too large; it's split into **PR3 = OAuth** (this), **PR4 = SheetsClient + ExportService**, **PR5 = UI**.

Branch: `feature/export-oauth`, off `main` (PR1's `PKCE` is already on `main`). Independent of PR2's SheetBuilder.

---

## File structure

- **Create** `plop/plop/Networking/ExportError.swift` — typed errors + user messages + HTTP/Error mapping.
- **Create** `plop/plop/Networking/OAuthEndpoints.swift` — pure helpers: `Secrets`, `reversedClientScheme`, `tokenRequest`, `parseAccessToken`, `authCode(fromRedirect:)`.
- **Create** `plop/plop/Networking/GoogleOAuth.swift` — `WebAuthenticating` protocol, `WebAuthenticator` (real `ASWebAuthenticationSession` wrapper), `GoogleOAuth.authorize()`.
- **Create** `plop/plopTests/Support/MockURLProtocol.swift` — test seam for `URLSession`.
- **Create** `plop/plopTests/ExportErrorTests.swift`, `plop/plopTests/OAuthEndpointsTests.swift`, `plop/plopTests/GoogleOAuthTests.swift`.

### Verified existing symbols this builds on

- `PKCE.makeVerifier()`, `PKCE.challenge(for:)`, `PKCE.authorizationURL(clientID:redirectScheme:codeChallenge:scope:)`, `PKCE.redirectURI(scheme:)` (on `main` from PR1).

### Test / build commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests/ExportErrorTests -only-testing:plopTests/OAuthEndpointsTests \
  -only-testing:plopTests/GoogleOAuthTests -parallel-testing-enabled NO 2>&1 | tail -30

swiftlint lint
```

> SourceKit false positives for new files are expected — xcodebuild is the source
> of truth. Lines ≤ 120 (SwiftLint).

---

## Task 1: ExportError + mapping

**Files:**
- Create: `plop/plop/Networking/ExportError.swift`
- Create: `plop/plopTests/ExportErrorTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/ExportErrorTests.swift`:

```swift
import XCTest
@testable import plop

final class ExportErrorTests: XCTestCase {

    func test_cancelled_hasNoMessage() {
        XCTAssertNil(ExportError.cancelled.message)
    }

    func test_eachOtherCase_hasMessage() {
        for e in [ExportError.consentDenied, .network, .signInFailed,
                  .storageFull, .rateLimited, .serverError, .unknown] {
            XCTAssertFalse(e.message?.isEmpty ?? true, "\(e) should have a message")
        }
    }

    func test_unknown_mentionsBugReport() {
        XCTAssertEqual(ExportError.unknown.message,
                       "Export failed. Please try again in a while, or submit a bug report.")
    }

    func test_mapStatus_authAndQuota() {
        let quota = Data(#"{"error":{"errors":[{"reason":"storageQuotaExceeded"}],"code":403}}"#.utf8)
        let rate = Data(#"{"error":{"errors":[{"reason":"rateLimitExceeded"}],"code":403}}"#.utf8)
        XCTAssertEqual(exportError(status: 401, body: Data()), .signInFailed)
        XCTAssertEqual(exportError(status: 403, body: quota), .storageFull)
        XCTAssertEqual(exportError(status: 403, body: rate), .rateLimited)
        XCTAssertEqual(exportError(status: 403, body: Data()), .unknown)
        XCTAssertEqual(exportError(status: 429, body: Data()), .rateLimited)
        XCTAssertEqual(exportError(status: 503, body: Data()), .serverError)
        XCTAssertEqual(exportError(status: 418, body: Data()), .unknown)
    }

    func test_mapError_networkAndPassthrough() {
        XCTAssertEqual(exportError(from: URLError(.notConnectedToInternet)), .network)
        XCTAssertEqual(exportError(from: ExportError.storageFull), .storageFull)
        XCTAssertEqual(exportError(from: NSError(domain: "x", code: 1)), .unknown)
    }
}
```

- [ ] **Step 2: Run the tests — confirm they FAIL to build.**

- [ ] **Step 3: Implement**

Create `plop/plop/Networking/ExportError.swift`:

```swift
import Foundation

/// User-facing outcome of an export attempt.
enum ExportError: Error, Equatable {
    case cancelled        // user dismissed sign-in; no message (silent)
    case consentDenied
    case network
    case signInFailed
    case storageFull
    case rateLimited
    case serverError
    case unknown

    var message: String? {
        switch self {
        case .cancelled: return nil
        case .consentDenied: return "Sign-in was declined."
        case .network: return "No connection — check your network and try again."
        case .signInFailed: return "Couldn't sign in to Google. Try again."
        case .storageFull: return "Your Google Drive is full — free up space and retry."
        case .rateLimited: return "Google is busy — try again in a moment."
        case .serverError: return "Google Sheets is unavailable right now."
        case .unknown: return "Export failed. Please try again in a while, or submit a bug report."
        }
    }
}

/// Maps an HTTP status + Google JSON error body to an ExportError.
func exportError(status: Int, body: Data) -> ExportError {
    switch status {
    case 401:
        return .signInFailed
    case 403:
        switch googleErrorReason(body) {
        case "storageQuotaExceeded": return .storageFull
        case "rateLimitExceeded", "userRateLimitExceeded": return .rateLimited
        default: return .unknown
        }
    case 429:
        return .rateLimited
    case 500..<600:
        return .serverError
    default:
        return .unknown
    }
}

/// Maps a thrown error (URLError, or an already-typed ExportError) to ExportError.
func exportError(from error: Error) -> ExportError {
    if let e = error as? ExportError { return e }
    if error is URLError { return .network }
    return .unknown
}

/// Pulls `error.errors[0].reason` from a Google API error JSON body (or "").
private func googleErrorReason(_ body: Data) -> String {
    struct Payload: Decodable {
        struct Err: Decodable { struct Item: Decodable { let reason: String? }
            let errors: [Item]? }
        let error: Err?
    }
    let payload = try? JSONDecoder().decode(Payload.self, from: body)
    return payload?.error?.errors?.first?.reason ?? ""
}
```

- [ ] **Step 4: Run the tests — confirm PASS.**

- [ ] **Step 5: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Networking/ExportError.swift plop/plopTests/ExportErrorTests.swift
git commit -m "Add ExportError model and HTTP error mapping

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: OAuth endpoint helpers (pure)

**Files:**
- Create: `plop/plop/Networking/OAuthEndpoints.swift`
- Create: `plop/plopTests/OAuthEndpointsTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/OAuthEndpointsTests.swift`:

```swift
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
```

- [ ] **Step 2: Run the tests — confirm they FAIL to build.**

- [ ] **Step 3: Implement**

Create `plop/plop/Networking/OAuthEndpoints.swift`:

```swift
import Foundation

/// Reads OAuth config injected via the build (Secrets.xcconfig → Info.plist).
enum Secrets {
    /// The Google OAuth iOS client ID, or "" if not wired yet.
    static var googleClientID: String {
        Bundle.main.object(forInfoDictionaryKey: "GoogleOAuthClientID") as? String ?? ""
    }
}

/// The reversed-client-ID custom URL scheme used as the OAuth redirect.
func reversedClientScheme(clientID: String) -> String {
    let base = clientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
    return "com.googleusercontent.apps.\(base)"
}

/// Builds the authorization-code → token exchange request (form-encoded, fixed order).
func tokenRequest(code: String, verifier: String, clientID: String,
                  redirectURI: String) -> URLRequest {
    var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    var comps = URLComponents()
    comps.queryItems = [
        URLQueryItem(name: "grant_type", value: "authorization_code"),
        URLQueryItem(name: "code", value: code),
        URLQueryItem(name: "code_verifier", value: verifier),
        URLQueryItem(name: "client_id", value: clientID),
        URLQueryItem(name: "redirect_uri", value: redirectURI)
    ]
    request.httpBody = comps.percentEncodedQuery?.data(using: .utf8)
    return request
}

/// Extracts `access_token` from the token endpoint's JSON response.
func parseAccessToken(_ data: Data) throws -> String {
    struct Response: Decodable { let access_token: String }
    return try JSONDecoder().decode(Response.self, from: data).access_token
}

/// Pulls the auth `code` out of the OAuth redirect URL, or throws.
func authCode(fromRedirect url: URL) throws -> String {
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    if items.first(where: { $0.name == "error" })?.value == "access_denied" {
        throw ExportError.consentDenied
    }
    guard let code = items.first(where: { $0.name == "code" })?.value, !code.isEmpty else {
        throw ExportError.signInFailed
    }
    return code
}
```

- [ ] **Step 4: Run the tests — confirm PASS.** (`access_token` underscore name will trigger SwiftLint `identifier_name`? It is inside a local struct property mapped by Decodable — if SwiftLint flags it, add `// swiftlint:disable:next identifier_name` above that property, OR use a CodingKeys map. Prefer CodingKeys if flagged.)

- [ ] **Step 5: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Networking/OAuthEndpoints.swift plop/plopTests/OAuthEndpointsTests.swift
git commit -m "Add OAuth endpoint helpers (token request, parse, code extraction)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: GoogleOAuth orchestration + web-auth seam

**Files:**
- Create: `plop/plopTests/Support/MockURLProtocol.swift`
- Create: `plop/plop/Networking/GoogleOAuth.swift`
- Create: `plop/plopTests/GoogleOAuthTests.swift`

- [ ] **Step 1: Add the URLSession test seam**

Create `plop/plopTests/Support/MockURLProtocol.swift`:

```swift
import Foundation

/// Intercepts URLSession requests in tests. Set `handler` to return a canned response.
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse)); return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    /// A URLSession wired to this protocol.
    static func session() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
```

- [ ] **Step 2: Write the failing tests**

Create `plop/plopTests/GoogleOAuthTests.swift`:

```swift
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
        do { _ = try await body(); XCTFail("expected \(expected)", file: file, line: line) }
        catch { XCTAssertEqual(error as? ExportError, expected, file: file, line: line) }
    }
}
```

- [ ] **Step 3: Run the tests — confirm they FAIL to build** (`GoogleOAuth` / `WebAuthenticating` undefined).

- [ ] **Step 4: Implement**

Create `plop/plop/Networking/GoogleOAuth.swift`:

```swift
import Foundation
import AuthenticationServices

/// Presents a web sign-in and returns the redirect URL containing the auth code.
protocol WebAuthenticating {
    func authenticate(authURL: URL, callbackScheme: String) async throws -> URL
}

/// Stateless Google OAuth: PKCE auth → token exchange. The access token is returned
/// to the caller and never stored.
struct GoogleOAuth {
    let clientID: String
    let session: URLSession
    let webAuth: WebAuthenticating
    var scope = "https://www.googleapis.com/auth/drive.file"

    /// Runs the full flow and returns a short-lived access token.
    func authorize() async throws -> String {
        let verifier = PKCE.makeVerifier()
        let scheme = reversedClientScheme(clientID: clientID)
        let authURL = PKCE.authorizationURL(clientID: clientID, redirectScheme: scheme,
                                            codeChallenge: PKCE.challenge(for: verifier),
                                            scope: scope)

        let redirect: URL
        do {
            redirect = try await webAuth.authenticate(authURL: authURL, callbackScheme: scheme)
        } catch {
            throw exportError(from: error)   // .cancelled passes through
        }

        let code = try authCode(fromRedirect: redirect)
        return try await exchange(code: code, verifier: verifier, scheme: scheme)
    }

    private func exchange(code: String, verifier: String, scheme: String) async throws -> String {
        let request = tokenRequest(code: code, verifier: verifier, clientID: clientID,
                                   redirectURI: PKCE.redirectURI(scheme: scheme))
        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status) else { throw exportError(status: status, body: data) }
            return try parseAccessToken(data)
        } catch let error as ExportError {
            throw error
        } catch {
            throw exportError(from: error)
        }
    }
}

/// Real `ASWebAuthenticationSession` wrapper (system UI — not unit-tested).
final class WebAuthenticator: NSObject, WebAuthenticating,
                              ASWebAuthenticationPresentationContextProviding {
    func authenticate(authURL: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL, callbackURLScheme: callbackScheme
            ) { url, error in
                if let url {
                    continuation.resume(returning: url)
                } else if let error = error as? ASWebAuthenticationSessionError,
                          error.code == .canceledLogin {
                    continuation.resume(throwing: ExportError.cancelled)
                } else {
                    continuation.resume(throwing: ExportError.signInFailed)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}
```

- [ ] **Step 5: Run the tests — confirm PASS** (4 GoogleOAuth tests). Fix the implementation (not the tests) if needed.

- [ ] **Step 6: SwiftLint** — `swiftlint lint` → no new violations from the added files. (If `access_token` trips `identifier_name`, switch that `Decodable` to a `CodingKeys` map in `OAuthEndpoints.swift`.)

- [ ] **Step 7: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Networking/GoogleOAuth.swift plop/plopTests/GoogleOAuthTests.swift plop/plopTests/Support/MockURLProtocol.swift
git commit -m "Add GoogleOAuth flow with web-auth seam and token exchange

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` — all prior + the new OAuth tests.

- [ ] **Step 2: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 3: Push + PR**

```bash
git push -u origin feature/export-oauth
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Add the stateless Google OAuth layer: PKCE sign-in via ASWebAuthenticationSession
(behind a WebAuthenticating seam) and authorization-code → access-token exchange,
plus the ExportError model + HTTP error mapping. No Sheets/UI yet — sets up PR4.

## Testing
All unit tests pass (N new); SwiftLint clean. Live sign-in deferred to PR5 (UI),
once the Info.plist redirect scheme is wired.
```
(Replace `N`.)

---

## Self-review notes

- **Spec coverage:** PKCE auth URL + interactive session (Task 3 via `PKCE` + `WebAuthenticating`); token exchange, no refresh/no storage (Task 2/3); `ExportError` incl. storageFull/rateLimited/serverError/network + the bug-report fallback (Task 1); consent-denied + cancel handling (Task 2/3). Drive/Sheets calls and `ExportService` orchestration are PR4; UI is PR5 — absent here.
- **Type consistency:** `ExportError` cases + `exportError(status:body:)` / `exportError(from:)` used identically across files; `GoogleOAuth(clientID:session:webAuth:)` and `WebAuthenticating.authenticate(authURL:callbackScheme:)` match tests and the real wrapper; reuses `PKCE.*` as defined on `main`.
- **Testability:** live `ASWebAuthenticationSession` is isolated in `WebAuthenticator` (untested system UI); everything else is covered via `MockURLProtocol` + `FakeWebAuth`.
- **No placeholders:** every step has complete code; the one conditional (`access_token` lint) has an explicit fallback.
- **Dependency:** live runs need the Info.plist redirect scheme (the PR1 "Task 3" Xcode wiring); unit tests do not.
