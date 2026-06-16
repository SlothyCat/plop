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
    struct ErrorItem: Decodable { let reason: String? }
    struct ErrorBody: Decodable { let errors: [ErrorItem]? }
    struct Payload: Decodable { let error: ErrorBody? }
    let payload = try? JSONDecoder().decode(Payload.self, from: body)
    return payload?.error?.errors?.first?.reason ?? ""
}
