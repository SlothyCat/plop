import SwiftUI
import SwiftData

/// Lists categories; tap to edit, "+" to add. Deleting arrives in the next PR.
struct ManageCategoriesView: View {
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    @Environment(\.modelContext) private var modelContext
    @State private var editing: ExpenseCategory?
    @State private var showingAdd = false
    @State private var reassigning: ExpenseCategory?
    @State private var showLastCategoryAlert = false

    var body: some View {
        List {
            ForEach(categories) { category in
                Button { editing = category } label: { row(category) }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { requestDelete(category) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.bg)
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(item: $editing) { CategoryFormView(editing: $0) }
        .sheet(isPresented: $showingAdd) { CategoryFormView() }
        .sheet(item: $reassigning) { category in
            ReassignCategorySheet(
                category: category,
                targets: categories.filter { $0.persistentModelID != category.persistentModelID }
            )
        }
        .alert("Keep at least one category", isPresented: $showLastCategoryAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You need at least one category. Add another before deleting this one.")
        }
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

    private func row(_ c: ExpenseCategory) -> some View {
        HStack(spacing: 12) {
            Image(systemName: c.symbolName)
                .foregroundStyle(Palette.tileInk)
                .frame(width: 34, height: 34)
                .background(Color(hex: c.colorHex), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(c.name).foregroundStyle(Palette.ink)
            Spacer()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack { ManageCategoriesView() }
        .modelContainer(SampleData.previewContainer())
}
#endif
