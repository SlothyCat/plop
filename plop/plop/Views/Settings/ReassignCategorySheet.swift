import SwiftUI
import SwiftData

/// Shown when deleting a category that has transactions: pick where they go, then delete.
/// A tall blur popup stacked over Manage categories.
struct ReassignCategorySheet: View {
    let category: ExpenseCategory
    let targets: [ExpenseCategory]

    @Environment(\.blurPopupClose) private var close
    @Environment(\.modelContext) private var modelContext
    @State private var listHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 8) { ForEach(targets) { targetRow($0) } }
                    .padding(.horizontal, 20).padding(.vertical, 4)
                    .readHeight(into: $listHeight)
            }
            .frame(maxHeight: listHeight == 0 ? nil : listHeight)
            Button("Cancel") { close() }
                .font(.system(size: 16, weight: .medium)).foregroundStyle(Palette.ink60)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .overlay(Rectangle().fill(Palette.hair).frame(height: 1), alignment: .top)
        }
    }

    private var header: some View {
        let count = category.transactions.count
        return VStack(alignment: .leading, spacing: 6) {
            Text("Delete \(category.name)")
                .font(.system(size: 22, weight: .bold)).foregroundStyle(Palette.ink)
            Text("Move \(count) transaction\(count == 1 ? "" : "s") from "
                 + "\"\(category.name)\" to:")
                .font(.system(size: 14)).foregroundStyle(Palette.ink60)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 12)
    }

    private func targetRow(_ target: ExpenseCategory) -> some View {
        Button {
            CategoryActions.delete(category, reassigningTo: target, in: modelContext)
            close()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: target.symbolName)
                    .font(.system(size: 16)).foregroundStyle(Palette.tileInk)
                    .frame(width: 34, height: 34)
                    .background(Color(hex: target.colorHex),
                                in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(target.name).font(.system(size: 16)).foregroundStyle(Palette.ink)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink12, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    ReassignCategorySheet(category: ExpenseCategory(name: "Food", symbolName: "fork.knife",
                                                    colorHex: "#FFEBCC"), targets: [])
}
#endif
