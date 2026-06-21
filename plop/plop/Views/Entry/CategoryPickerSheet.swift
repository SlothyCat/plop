import SwiftUI
import SwiftData

/// Bottom sheet to pick a category from the seeded set. "New category" creation is
/// intentionally omitted here — it arrives with the category-management feature.
struct CategoryPickerSheet: View {
    let categories: [ExpenseCategory]
    @Binding var selected: ExpenseCategory?
    var onDismiss: () -> Void
    var onAddNew: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            grabber
            Text("Choose category")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Palette.ink)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(categories) { category in
                    Button {
                        selected = category
                        onDismiss()
                    } label: { tile(category) }
                    .accessibilityIdentifier("category-\(category.name)")
                }
            }
            newCategoryButton
            Spacer(minLength: 0)
        }
        .padding(18)
        .presentationDetents([.medium, .large])
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

    private var grabber: some View {
        Capsule().fill(Palette.ink.opacity(0.15))
            .frame(width: 38, height: 5)
            .frame(maxWidth: .infinity)
    }
}
