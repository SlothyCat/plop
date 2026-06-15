import SwiftUI

let themeModeKey = "themeMode"

/// The app appearance setting. `automatic` follows the system.
enum ThemeMode: String, CaseIterable, Identifiable {
    case light, dark, automatic

    var id: String { rawValue }

    /// nil = follow the system (Automatic).
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .automatic: return nil
        }
    }

    var title: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .automatic: return "Automatic"
        }
    }

    var subtitle: String {
        switch self {
        case .light: return "Always light"
        case .dark: return "Always dark"
        case .automatic: return "Match device appearance"
        }
    }

    var symbol: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .automatic: return "circle.lefthalf.filled"
        }
    }
}
