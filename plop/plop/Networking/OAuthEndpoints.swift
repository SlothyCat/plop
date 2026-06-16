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
    struct Response: Decodable {
        let accessToken: String
        enum CodingKeys: String, CodingKey { case accessToken = "access_token" }
    }
    return try JSONDecoder().decode(Response.self, from: data).accessToken
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
