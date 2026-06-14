import SwiftUI
import SwiftData

/// Add (editing == nil) or edit a category: name, SF-Symbol icon, color.
struct CategoryFormView: View {
    var editing: ExpenseCategory?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.name) private var existing: [ExpenseCategory]

    @State private var name = ""
    @State private var symbolName = "tag.fill"
    @State private var colorHex = "#8CC0EB"

    private let swatches = ["#8CC0EB", "#BFDDF0", "#FFEBCC", "#FFF9D2"]
    private let iconColumns = [GridItem(.adaptive(minimum: 50), spacing: 10)]

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                iconSection
                colorSection
            }
            .navigationTitle(editing == nil ? "New category" : "Edit category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
            .onAppear(perform: prefill)
        }
    }

    // MARK: sections

    private var nameSection: some View {
        Section("Name") {
            TextField("e.g. Transport", text: $name)
        }
    }

    private var iconSection: some View {
        Section("Icon") {
            LazyVGrid(columns: iconColumns, spacing: 10) {
                ForEach(categoryIconChoices, id: \.self) { symbol in
                    iconButton(symbol)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func iconButton(_ symbol: String) -> some View {
        let on = symbol == symbolName
        return Button { symbolName = symbol } label: {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundStyle(on ? Palette.tileInk : Palette.ink)
                .frame(width: 46, height: 46)
                .background(on ? Color(hex: colorHex) : Palette.field,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var colorSection: some View {
        Section("Color") {
            HStack(spacing: 14) {
                ForEach(swatches, id: \.self) { hex in
                    swatchView(hex)
                }
                ColorPicker("Custom", selection: colorBinding).labelsHidden()
            }
        }
    }

    private func swatchView(_ hex: String) -> some View {
        Circle()
            .fill(Color(hex: hex))
            .frame(width: 32, height: 32)
            .overlay(Circle().stroke(Palette.ink, lineWidth: hex == colorHex ? 2.5 : 0))
            .onTapGesture { colorHex = hex }
    }

    private var colorBinding: Binding<Color> {
        Binding(get: { Color(hex: colorHex) }, set: { colorHex = $0.toHex() })
    }

    // MARK: actions

    private var canSave: Bool {
        isCategoryNameAvailable(name, existing: existing, editing: editing)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let editing {
            CategoryActions.update(editing, name: trimmed, symbolName: symbolName, colorHex: colorHex)
        } else {
            CategoryActions.add(name: trimmed, symbolName: symbolName, colorHex: colorHex, in: modelContext)
        }
        dismiss()
    }

    private func prefill() {
        guard let editing else { return }
        name = editing.name
        symbolName = editing.symbolName
        colorHex = editing.colorHex
    }
}

#if DEBUG
#Preview { CategoryFormView().modelContainer(SampleData.previewContainer()) }
#endif
