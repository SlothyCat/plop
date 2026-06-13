import SwiftUI

/// Light-theme color tokens from the design handoff. Dark theme is deferred to the
/// Settings/theme feature, so these are the single source of truth for now.
enum Palette {
    static let bg = Color(hex: "#DCEBF7")          // app background (baby blue)
    static let card = Color(hex: "#FFFFFF")        // cards / sheets
    static let field = Color(hex: "#FCFDFE")       // inputs / inset wells
    static let ink = Color(hex: "#2A2A2A")         // text & icons (charcoal)
    static let ink60 = Color(.sRGB, white: 0x2A / 255, opacity: 0.55)
    static let ink40 = Color(.sRGB, white: 0x2A / 255, opacity: 0.38)
    static let ink12 = Color(.sRGB, white: 0x2A / 255, opacity: 0.10)
    static let hair = Color(.sRGB, white: 0x2A / 255, opacity: 0.08)

    static let accent = Color(hex: "#8CC0EB")      // primary sky blue
    static let accentSoft = Color(hex: "#BFDDF0")
    static let cream = Color(hex: "#FFEBCC")
    static let yellow = Color(hex: "#FFF9D2")
    static let tileInk = Color(hex: "#2A2A2A")     // glyph on fixed pastel tiles
    static let incomeGreen = Color(hex: "#1F8A5B") // positive amounts
}
