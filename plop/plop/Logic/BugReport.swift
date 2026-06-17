import Foundation

/// Pure helpers for the bug-report email. The body builder takes diagnostics as a
/// value object (no Bundle/UIDevice here) so it is fully unit-testable.
enum BugReport {
    static let supportEmail = "slothycatcoder@gmail.com"
    static let subject = "plop bug report"

    /// App + environment context appended to a report. The view fills this from
    /// `Bundle` / `UIDevice`.
    struct Diagnostics: Equatable {
        let appVersion: String
        let build: String
        let systemName: String
        let systemVersion: String
        let deviceModel: String
    }

    static func body(description: String, diagnostics: Diagnostics) -> String {
        """
        \(description)


        ——
        Diagnostics
        App: plop \(diagnostics.appVersion) (\(diagnostics.build))
        OS: \(diagnostics.systemName) \(diagnostics.systemVersion)
        Device: \(diagnostics.deviceModel)
        """
    }
}
