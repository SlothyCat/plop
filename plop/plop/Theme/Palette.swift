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
    static let danger = Color.dynamic(Color(hex: "#C0392B"), Color(hex: "#FF6B5E"))

    // Cash-register LCD (Entry). Light values from the handoff; dark is a lit-display variant.
    static let lcdGlassTop = Color.dynamic(Color(hex: "#C6DEF1"), Color(hex: "#1B3A52"))
    static let lcdGlassBottom = Color.dynamic(Color(hex: "#C7DCEE"), Color(hex: "#14314A"))
    static let lcdInk = Color.dynamic(Color(hex: "#173A57"), Color(hex: "#BFE0F5"))
    static let lcdCaseTop = Color.dynamic(Color(hex: "#C6CED5"), Color(hex: "#2A3A47"))
    static let lcdCaseBottom = Color.dynamic(Color(hex: "#A7B2BB"), Color(hex: "#1C2833"))

    private static func charcoal(_ opacity: Double) -> Color {
        Color(.sRGB, white: 0x2A / 255, opacity: opacity)
    }

    private static func offWhite(_ opacity: Double) -> Color {
        Color(.sRGB, red: 234 / 255, green: 241 / 255, blue: 247 / 255, opacity: opacity)
    }
}
