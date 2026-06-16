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
@MainActor
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
