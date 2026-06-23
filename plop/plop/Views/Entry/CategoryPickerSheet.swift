import SwiftUI
import SwiftData

/// Bottom sheet to pick a category from the seeded set. "New category" creation is
/// intentionally omitted here — it arrives with the category-management feature.
struct CategoryPickerSheet: View {
    let categories: [ExpenseCategory]
    @Binding var selected: ExpenseCategory?
    var onAddNew: () -> Void

    @Environment(\.blurPopupClose) private var close
    @Environment(\.blurPopupMaxHeight) private var maxHeight
    @State private var gridHeight: CGFloat = 0

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)

    private var scrollCap: CGFloat {
        let ceiling = maxHeight.isFinite ? maxHeight * 0.7 : 100_000
        return gridHeight == 0 ? ceiling : min(gridHeight, ceiling)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose category")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Palette.ink)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(categories) { category in
                        Button {
                            selected = category
                            close()
                        } label: { tile(category) }
                        .accessibilityIdentifier("category-\(category.name)")
                    }
                }
                .readHeight(into: $gridHeight)
            }
            .frame(maxHeight: scrollCap)

            newCategoryButton
        }
        .padding(18)
    }

    private var newCategoryButton: some View {
        Button(action: onAddNew) {
            Label("New category", systemImage: "plus")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(Palette.ink12, style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                )
        }
        .buttonStyle(.plain)
    }

    private func tile(_ category: ExpenseCategory) -> some View {
        let isOn = selected?.persistentModelID == category.persistentModelID
        return HStack(spacing: 11) {
            CategoryIconView(category: category)
                .foregroundStyle(Palette.tileInk)
                .frame(width: 34, height: 34)
                .background(Color(hex: category.colorHex), in: RoundedRectangle(cornerRadius: 10))
            Text(category.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(11)
        .background(Palette.field, in: RoundedRectangle(cornerRadius: 15))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isOn ? Palette.ink : Palette.ink12, lineWidth: isOn ? 1.5 : 1)
        )
    }

}
