import SwiftUI
import UIKit

/// Plain RGBA components parsed from a hex string — testable without SwiftUI.
struct RGBA {
    let red, green, blue, alpha: Double
}

extension RGBA {
    /// Parses "#RRGGBB" (the leading "#" is optional). Invalid input → opaque black.
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else {
            self = RGBA(red: 0, green: 0, blue: 0, alpha: 1)
            return
        }
        self = RGBA(red: Double((v >> 16) & 0xFF) / 255,
                    green: Double((v >> 8) & 0xFF) / 255,
                    blue: Double(v & 0xFF) / 255,
                    alpha: 1)
    }
}

extension Color {
    init(hex: String) {
        let c = RGBA(hex: hex)
        self = Color(.sRGB, red: c.red, green: c.green, blue: c.blue, opacity: c.alpha)
    }

    /// "#RRGGBB" for the color's sRGB components.
    func toHex() -> String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X",
                      Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
    }
}
