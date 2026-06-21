import SwiftUI

/// A category's icon: its emoji if set, otherwise its SF Symbol (or `fallbackSymbol` when
/// the category — or its symbol — is missing). Style from the call site: `.font` sizes both
/// emoji and symbol; `.foregroundStyle` tints the SF Symbol and is ignored by emoji.
struct CategoryIconView: View {
    let category: ExpenseCategory?
    var fallbackSymbol: String = "questionmark"

    var body: some View {
        if let emoji = category?.emoji, !emoji.isEmpty {
            Text(emoji)
        } else {
            Image(systemName: category?.symbolName ?? fallbackSymbol)
        }
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 16) {
        CategoryIconView(category: ExpenseCategory(name: "Food", symbolName: "fork.knife",
                                                   colorHex: "#FFEBCC"))
        CategoryIconView(category: ExpenseCategory(name: "Fun", symbolName: "tag.fill",
                                                   emoji: "🎉", colorHex: "#BFDDF0"))
        CategoryIconView(category: nil, fallbackSymbol: "questionmark")
    }
    .font(.system(size: 22)).foregroundStyle(Palette.tileInk).padding()
}
#endif
