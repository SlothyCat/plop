import SwiftUI
import SwiftData

/// Lists categories as a tall blur popup: tap a card to edit, trash to delete (with the
/// reassign / last-category safeguards), "+ Add category" to add. Add/Edit and Reassign
/// present stacked over this popup.
struct ManageCategoriesView: View {
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.blurPopupClose) private var close
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @State private var editing: ExpenseCategory?
    @State private var showingAdd = false
    @State private var reassigning: ExpenseCategory?
    @State private var showLastCategoryAlert = false
    @State private var listHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 8) { ForEach(categories) { row($0) } }
                    .padding(.horizontal, 20).padding(.vertical, 4)
                    .readHeight(into: $listHeight)
            }
            .frame(maxHeight: listHeight == 0 ? nil : listHeight)
            addButton
        }
        .blurPopup(item: $editing) { CategoryFormView(editing: $0) }
        .blurPopup(isPresented: $showingAdd) { CategoryFormView() }
        .blurPopup(item: $reassigning) { category in
            ReassignCategorySheet(
                category: category,
                targets: categories.filter { $0.persistentModelID != category.persistentModelID })
        }
        .alert("Keep at least one category", isPresented: $showLastCategoryAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You need at least one category. Add another before deleting this one.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Categories")
                    .font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.ink)
                Spacer()
                Button { close() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.ink60)
                        .frame(width: 32, height: 32).background(Palette.field, in: Circle())
                }
                .buttonStyle(.plain)
            }
            Text("Tap a category to edit it, or remove ones you don't use.")
                .font(.system(size: 15)).foregroundStyle(Palette.ink60)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 12)
    }

    private func row(_ c: ExpenseCategory) -> some View {
        HStack(spacing: 12) {
            Button { editing = c } label: {
                HStack(spacing: 12) {
                    Image(systemName: c.symbolName)
                        .font(.system(size: 18)).foregroundStyle(Palette.tileInk)
                        .frame(width: 38, height: 38)
                        .background(Color(hex: c.colorHex),
                                    in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(c.name)
                            .font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.ink)
                        Text(c.budget > 0
                             ? "\(formattedMoney(c.budget, currencyCode: currencyCode))/mo"
                             : "No budget")
                            .font(.system(size: 13)).foregroundStyle(Palette.ink40).monospacedDigit()
                    }
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)
            Button { requestDelete(c) } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16)).foregroundStyle(Palette.ink60)
                    .frame(width: 34, height: 34)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10).padding(.vertical, 9)
        .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink12, lineWidth: 1))
    }

    private var addButton: some View {
        Button { showingAdd = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 17, weight: .semibold))
                Text("Add category").font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(Palette.tileInk).frame(maxWidth: .infinity).padding(.vertical, 15)
            .background(Palette.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 18)
    }

    private func requestDelete(_ category: ExpenseCategory) {
        if categories.count <= 1 {
            showLastCategoryAlert = true
        } else if category.transactions.isEmpty {
            CategoryActions.delete(category, in: modelContext)
        } else {
            reassigning = category
        }
    }
}

#if DEBUG
#Preview {
    ManageCategoriesView().modelContainer(SampleData.previewContainer())
}
#endif
