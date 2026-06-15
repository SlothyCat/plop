import SwiftUI

/// Color tokens from the design handoff. Scheme-dependent tokens resolve light/dark
/// automatically via `Color.dynamic`, so the whole app themes with no per-view
/// changes. Brand accents are identical in both themes.
enum Palette {
    static let bg = Color.dynamic(Color(hex: "#DCEBF7"), Color(hex: "#121922"))
    static let card = Color.dynamic(Color(hex: "#FFFFFF"), Color(hex: "#1C2530"))
    static let field = Color.dynamic(Color(hex: "#FCFDFE"), Color(hex: "#232E3A"))
    static let ink = Color.dynamic(Color(hex: "#2A2A2A"), Color(hex: "#EAF1F7"))

    static let ink60 = Color.dynamic(charcoal(0.55), offWhite(0.62))
    static let ink40 = Color.dynamic(charcoal(0.38), offWhite(0.40))
    static let ink12 = Color.dynamic(charcoal(0.10), offWhite(0.14))
    static let hair = Color.dynamic(charcoal(0.08), offWhite(0.10))

    static let accent = Color(hex: "#8CC0EB")      // brand — fixed in both themes
    static let accentSoft = Color(hex: "#BFDDF0")
    static let cream = Color(hex: "#FFEBCC")
    static let yellow = Color(hex: "#FFF9D2")
    static let tileInk = Color(hex: "#2A2A2A")     // glyph on fixed pastel tiles
    static let incomeGreen = Color.dynamic(Color(hex: "#1F8A5B"), Color(hex: "#4ECB8B"))

    private static func charcoal(_ opacity: Double) -> Color {
        Color(.sRGB, white: 0x2A / 255, opacity: opacity)
    }

    private static func offWhite(_ opacity: Double) -> Color {
        Color(.sRGB, red: 234 / 255, green: 241 / 255, blue: 247 / 255, opacity: opacity)
    }
}
