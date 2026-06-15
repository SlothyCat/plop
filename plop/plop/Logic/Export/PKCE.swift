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
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        precondition(status == errSecSuccess, "PKCE verifier RNG failed")
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
