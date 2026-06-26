import UIKit

/// Fires the system "success" haptic to confirm a committed user action. Respects
/// iOS Settings → Sounds & Haptics → System Haptics automatically (the generator
/// no-ops when the user has disabled haptics), so there is no in-app toggle.
enum Haptics {
    @MainActor static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @MainActor static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
