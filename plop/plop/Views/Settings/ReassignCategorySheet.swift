import SwiftUI
import SwiftData

/// Shown when deleting a category that has transactions: pick where they go, then delete.
struct ReassignCategorySheet: View {
    let category: ExpenseCategory
    let targets: [ExpenseCategory]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(targets) { target in
                        Button {
                            CategoryActions.delete(category, reassigningTo: target, in: modelContext)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: target.symbolName)
                                    .foregroundStyle(Palette.tileInk)
                                    .frame(width: 30, height: 30)
                                    .background(Color(hex: target.colorHex),
                                                in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                Text(target.name).foregroundStyle(Palette.ink)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    let count = category.transactions.count
                    Text("Move \(count) transaction\(count == 1 ? "" : "s") from \"\(category.name)\" to:")
                }
            }
            .navigationTitle("Delete \(category.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
