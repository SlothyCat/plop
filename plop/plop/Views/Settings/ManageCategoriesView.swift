import SwiftUI
import SwiftData

/// Lists categories; tap to edit, "+" to add. Deleting arrives in the next PR.
struct ManageCategoriesView: View {
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    @State private var editing: ExpenseCategory?
    @State private var showingAdd = false

    var body: some View {
        List {
            ForEach(categories) { category in
                Button { editing = category } label: { row(category) }
                    .buttonStyle(.plain)
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
