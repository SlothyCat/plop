# Export PR1 — Config + PKCE Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold the OAuth secrets/redirect config and ship the pure, tested PKCE logic that later PRs use — no UI, no live network.

**Architecture:** A git-ignored `Secrets.xcconfig` (real client ID) + committed example; the redirect URL scheme + client ID surfaced to the app via build settings; and a pure `PKCE` type (verifier/challenge + authorization-URL builder) covered by XCTest. Project-settings wiring is done manually in Xcode (the agent must not rewrite `project.pbxproj` while Xcode is open).

**Tech Stack:** Swift, Foundation, CryptoKit, XCTest. iOS 18.

Branch `feature/export` (already created; spec committed there).

> **The OAuth client ID for this project** (public — embedded in the app binary, not a secret):
> `YOUR_CLIENT_ID.apps.googleusercontent.com`
> Redirect scheme (reversed): `com.googleusercontent.apps.YOUR_CLIENT_ID`

---

## File structure

- **Create** `Secrets.example.xcconfig` (repo root, committed) — placeholders.
- **Create** `Secrets.xcconfig` (repo root, **git-ignored**) — the real client ID.
- **Modify** `.gitignore` — ignore `Secrets.xcconfig`.
- **Create** `plop/plop/Info.plist` — `CFBundleURLTypes` (redirect scheme) + the client-ID key, both via `$(...)` build variables.
- **Create** `plop/plop/Logic/Export/PKCE.swift` — pure verifier/challenge + auth-URL builder.
- **Create** `plop/plopTests/PKCETests.swift` — unit tests.
- **Manual (Xcode):** assign `Secrets.xcconfig` as the project base configuration and set `INFOPLIST_FILE` (Task 3).

### Test / build commands

```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests/PKCETests -parallel-testing-enabled NO

xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'

swiftlint lint
```

> SourceKit shows false "No such module" / "Cannot find X" for new files. The
> build/test run is the source of truth. Keep lines ≤ 120 (SwiftLint).

---

## Task 1: Secrets config files + gitignore

**Files:**
- Modify: `.gitignore`
- Create: `Secrets.example.xcconfig`
- Create: `Secrets.xcconfig` (git-ignored)

- [ ] **Step 1: Ignore the real secrets file FIRST** (so it can never be staged)

Append to `.gitignore`:

```gitignore

## ---------------------------------------------------------------------------
## Secrets — real OAuth config (commit only Secrets.example.xcconfig)
## ---------------------------------------------------------------------------
Secrets.xcconfig
```

- [ ] **Step 2: Create the committed example**

Create `Secrets.example.xcconfig`:

```xcconfig
// Copy this file to Secrets.xcconfig and fill in your Google OAuth iOS client ID.
// Secrets.xcconfig is git-ignored. The client ID is public (it ships in the app
// binary); there is NO client secret — the OAuth flow uses PKCE.

// e.g. 1234567890-abcdefg.apps.googleusercontent.com
GOOGLE_OAUTH_CLIENT_ID = YOUR_CLIENT_ID.apps.googleusercontent.com

// The reversed client ID (drop the .apps.googleusercontent.com suffix and prefix
// com.googleusercontent.apps.). Used as the OAuth redirect URL scheme.
GOOGLE_REDIRECT_SCHEME = com.googleusercontent.apps.YOUR_CLIENT_ID
```

- [ ] **Step 3: Create the real (git-ignored) config**

Create `Secrets.xcconfig`:

```xcconfig
GOOGLE_OAUTH_CLIENT_ID = YOUR_CLIENT_ID.apps.googleusercontent.com
GOOGLE_REDIRECT_SCHEME = com.googleusercontent.apps.YOUR_CLIENT_ID
```

- [ ] **Step 4: Confirm it is ignored**

Run: `git status --porcelain | grep Secrets.xcconfig` → expect **no output** (ignored).
Run: `git check-ignore Secrets.xcconfig` → expect it prints `Secrets.xcconfig`.

- [ ] **Step 5: Commit (example + gitignore only)**

```bash
git add .gitignore Secrets.example.xcconfig
git commit -m "Add OAuth secrets config scaffolding

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: PKCE logic + tests

**Files:**
- Create: `plop/plop/Logic/Export/PKCE.swift`
- Create: `plop/plopTests/PKCETests.swift`

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/PKCETests.swift`:

```swift
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the `-only-testing:plopTests/PKCETests` command. Expected: BUILD FAILS — `PKCE` undefined.

- [ ] **Step 3: Write the implementation**

Create `plop/plop/Logic/Export/PKCE.swift`:

```swift
import Foundation
import CryptoKit

/// RFC 7636 PKCE helpers + the Google authorization-URL builder. Pure and testable;
/// no networking. The verifier is generated per export and never stored.
enum PKCE {
    /// Base64url without padding (`+`→`-`, `/`→`_`, drop `=`).
    static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// A high-entropy code verifier (32 random bytes → 43 url-safe chars).
    static func makeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return base64URL(Data(bytes))
    }

    /// code_challenge = base64url(SHA256(verifier)), method S256.
    static func challenge(for verifier: String) -> String {
        base64URL(Data(SHA256.hash(data: Data(verifier.utf8))))
    }

    /// The redirect URI for a reversed-client-ID scheme.
    static func redirectURI(scheme: String) -> String { "\(scheme):/oauth" }

    /// Builds the Google OAuth 2.0 authorization URL (S256 PKCE).
    static func authorizationURL(clientID: String,
                                 redirectScheme: String,
                                 codeChallenge: String,
                                 scope: String) -> URL {
        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        comps.queryItems = [
            .init(name: "client_id", value: clientID),
            .init(name: "redirect_uri", value: redirectURI(scheme: redirectScheme)),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: scope),
            .init(name: "code_challenge", value: codeChallenge),
            .init(name: "code_challenge_method", value: "S256")
        ]
        return comps.url!
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the Step 2 command. Expected: `** TEST SUCCEEDED **`, 5 tests green.

- [ ] **Step 5: Commit**

```bash
git add plop/plop/Logic/Export/PKCE.swift plop/plopTests/PKCETests.swift
git commit -m "Add PKCE helpers and authorization URL builder

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Wire the config in Xcode (MANUAL — owner does this)

The agent must not edit `project.pbxproj` while Xcode is open. Do these in Xcode;
they make `Secrets.xcconfig` values available to the build and register the OAuth
redirect scheme. (Strictly needed only before PR3/PR4's live flow — but do it now
to keep PR1 self-contained.)

- [ ] **Step 1: Create the Info.plist** (agent creates the file; you wire it)

Create `plop/plop/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>GoogleOAuthClientID</key>
  <string>$(GOOGLE_OAUTH_CLIENT_ID)</string>
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLName</key>
      <string>google-oauth</string>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>$(GOOGLE_REDIRECT_SCHEME)</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
```

- [ ] **Step 2: Assign the base configuration**
  - Xcode → **plop project** (not target) → **Info** tab → **Configurations**.
  - Expand **Debug** and **Release**; for the **plop** project row, set
    **Based on Configuration File** → `Secrets` for both.

- [ ] **Step 3: Point the target at the Info.plist**
  - **plop target → Build Settings** → search `INFOPLIST_FILE` → set to
    `plop/Info.plist`. Leave `GENERATE_INFOPLIST_FILE = YES` (Xcode merges the
    generated keys with this file's custom keys).

- [ ] **Step 4: Verify the build picks up the values**

```bash
xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'
```
Expected: `** BUILD SUCCEEDED **`. (Optional sanity: the built app's `Info.plist`
contains the real reversed-ID scheme under `CFBundleURLTypes`.)

- [ ] **Step 5: Commit the Info.plist + the pbxproj changes**

```bash
git add plop/plop/Info.plist plop/plop.xcodeproj/project.pbxproj
git commit -m "Wire Secrets.xcconfig and OAuth redirect scheme into the build

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

> If you'd rather defer the Xcode wiring, skip Task 3 for now — PR1 still delivers
> the tested PKCE logic + committed example config. Do Task 3 before PR3/PR4, since
> the live auth session needs the registered scheme.

---

## Task 4: Verify and open PR

**Files:** none (verification + PR).

- [ ] **Step 1: Full test suite**

```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO
```
Expected: `** TEST SUCCEEDED **` — all prior tests + `PKCETests`.

- [ ] **Step 2: Lint**

```bash
swiftlint lint
```
Expected: no new violations from `PKCE.swift` / `PKCETests.swift`.

- [ ] **Step 3: Confirm no secret leaked**

Run: `git log -p -1 -- Secrets.xcconfig` → expect **empty** (file never tracked).
Run: `git ls-files | grep -i secrets` → expect only `Secrets.example.xcconfig`.

- [ ] **Step 4: Push and open the PR**

```bash
git push -u origin feature/export
```

`gh` is not installed — open the PR via the printed GitHub web URL, project format:

```markdown
## Summary
Scaffold OAuth config (git-ignored Secrets.xcconfig + example, Info.plist redirect
scheme) and add pure PKCE logic (verifier/challenge + auth-URL builder). Sets up the
Sheets export flow. No UI / no live calls.

## Testing
All unit tests pass (5 new in PKCETests); SwiftLint clean.
```

---

## Self-review notes

- **Spec coverage (PR1 scope):** Secrets scaffolding + gitignore (Task 1); Info.plist
  redirect scheme + client-ID key (Task 3); PKCE verifier/challenge + auth-URL builder
  (Task 2). Networking, SheetBuilder, UI are later PRs — absent here.
- **Type consistency:** `PKCE.{base64URL,makeVerifier,challenge,redirectURI,authorizationURL}`
  used identically in source and tests; the auth-URL `redirect_uri` (`scheme:/oauth`)
  matches `redirectURI(scheme:)`.
- **No placeholders:** every agent step has complete content; Task 3 is explicitly
  manual (Xcode), with exact settings and an opt-to-defer note.
- **Secret safety:** `.gitignore` is updated before the real file is created; Task 1
  Step 4 and Task 4 Step 3 verify it's never tracked. The client ID is public (ships
  in the binary); there is no client secret.
