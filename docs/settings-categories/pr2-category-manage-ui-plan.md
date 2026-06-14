# PR2 — Category Manage UI Implementation Plan

> Execute inline (no worktrees). Steps use `- [ ]`. Branch off `main` after PR1 merges.

**Goal:** A real Settings tab → Manage Categories list → Add/Edit category form (name, SF-Symbol icon, color), wired up. Deleting categories + the Entry "New category" hook are PR3.

**Architecture:** `SettingsView` (NavigationStack grouped list) pushes `ManageCategoriesView` (@Query list), which presents `CategoryFormView` (sheet) for add/edit using PR1's `CategoryActions` + `isCategoryNameAvailable`. A small tested `Color.toHex()` backs the custom color picker.

**Tech Stack:** SwiftUI, SwiftData (@Query), PR1 logic. iOS 18, light theme.

---

## Conventions
- Branch `feature/category-manage-ui` off updated `main`. No worktrees.
- Commits present-tense + `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- Build/screenshot iPhone 16 OS=18.4; stale-crash remedies in `memory/xcode-build-sim-gotchas.md`.

## File Structure
- Modify `plop/plop/Theme/Color+Hex.swift` — add `Color.toHex()`.
- Modify `plop/plopTests/ColorHexTests.swift` — round-trip test.
- Create `plop/plop/Views/Settings/SettingsView.swift`
- Create `plop/plop/Views/Settings/ManageCategoriesView.swift`
- Create `plop/plop/Views/Settings/CategoryFormView.swift`
- Modify `plop/plop/Views/Shell/RootView.swift` — `.settings` → `SettingsView()`
- Delete `plop/plop/Views/Shell/SettingsStubView.swift`

---

### Task 1: `Color.toHex()` (TDD) + Settings shell + Manage list

**Files:** modify `Color+Hex.swift`, `ColorHexTests.swift`; create `SettingsView.swift`,
`ManageCategoriesView.swift`; modify `RootView.swift`; delete `SettingsStubView.swift`.

- [ ] **Step 1: Branch**
```bash
git checkout main && git pull --ff-only && git checkout -b feature/category-manage-ui
```

- [ ] **Step 2: Add the failing round-trip test**

Append to `plop/plopTests/ColorHexTests.swift` inside `ColorHexTests`:
```swift
    func test_toHex_roundTripsSwatch() {
        XCTAssertEqual(Color(hex: "#8CC0EB").toHex(), "#8CC0EB")
        XCTAssertEqual(Color(hex: "#FFEBCC").toHex(), "#FFEBCC")
    }
```

- [ ] **Step 3: Run to verify it fails**
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/ColorHexTests/test_toHex_roundTripsSwatch
```
Expected: FAIL — no `toHex()`.

- [ ] **Step 4: Implement `Color.toHex()`**

Append to `plop/plop/Theme/Color+Hex.swift`:
```swift
import UIKit

extension Color {
    /// "#RRGGBB" for the color's sRGB components.
    func toHex() -> String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X",
                      Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
    }
}
```

- [ ] **Step 5: Run to verify it passes**
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/ColorHexTests
```
Expected: PASS.

- [ ] **Step 6: `SettingsView.swift`**
```swift
import SwiftUI

/// Settings tab: grouped list. Only "Manage categories" is wired for now; other rows
/// arrive with their features.
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Preferences") {
                    NavigationLink {
                        ManageCategoriesView()
                    } label: {
                        Label("Manage categories", systemImage: "tag.fill")
                    }
                }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(Palette.bg)
        }
        .tint(Palette.accent)
    }
}

#if DEBUG
#Preview { SettingsView().modelContainer(SampleData.previewContainer()) }
#endif
```

- [ ] **Step 7: `ManageCategoriesView.swift` (list + add/edit entry points; no delete yet)**
```swift
import SwiftUI
import SwiftData

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
```

- [ ] **Step 8: Wire the tab + remove the stub**

In `plop/plop/Views/Shell/RootView.swift`, change the settings case:
```swift
                case .settings: SettingsView()
```
Then:
```bash
git rm plop/plop/Views/Shell/SettingsStubView.swift
```
(Note: `CategoryFormView` doesn't exist yet — build happens after Task 2.)

- [ ] **Step 9: Commit**
```bash
git add plop/plop/Theme/Color+Hex.swift plop/plopTests/ColorHexTests.swift \
        plop/plop/Views/Settings/SettingsView.swift plop/plop/Views/Settings/ManageCategoriesView.swift \
        plop/plop/Views/Shell/RootView.swift plop/plop/Views/Shell/SettingsStubView.swift
git commit -m "Add Settings shell and Manage Categories list, plus Color.toHex"
```

---

### Task 2: `CategoryFormView` (add/edit)

**Files:** create `plop/plop/Views/Settings/CategoryFormView.swift`.

- [ ] **Step 1: `CategoryFormView.swift`**
```swift
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
                Section("Name") {
                    TextField("e.g. Transport", text: $name)
                }
                Section("Icon") {
                    LazyVGrid(columns: iconColumns, spacing: 10) {
                        ForEach(categoryIconChoices, id: \.self) { symbol in
                            Button { symbolName = symbol } label: {
                                Image(systemName: symbol)
                                    .font(.system(size: 20))
                                    .foregroundStyle(symbol == symbolName ? Palette.tileInk : Palette.ink)
                                    .frame(width: 46, height: 46)
                                    .background(symbol == symbolName ? Color(hex: colorHex) : Palette.field,
                                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Color") {
                    HStack(spacing: 14) {
                        ForEach(swatches, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(Palette.ink, lineWidth: hex == colorHex ? 2.5 : 0))
                                .onTapGesture { colorHex = hex }
                        }
                        ColorPicker("Custom", selection: Binding(
                            get: { Color(hex: colorHex) },
                            set: { colorHex = $0.toHex() }
                        ))
                        .labelsHidden()
                    }
                }
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
```

- [ ] **Step 2: Build**
```bash
xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**
```bash
git add plop/plop/Views/Settings/CategoryFormView.swift
git commit -m "Add category add/edit form with icon and color pickers"
```

---

### Task 3: Verify, screenshot, PR

- [ ] **Step 1: Full test + lint**
```bash
xcrun simctl shutdown all 2>/dev/null; sleep 2
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO
swiftlint lint
```
Expected: 51 tests pass (50 + 1 round-trip); no lint errors.

- [ ] **Step 2: Simulator screenshots**

Temporarily default to the Settings tab (`RootView`: `selection = .settings`) with a seeded
container (`plopApp`: `.modelContainer(SampleData.previewContainer())`); build/install/launch,
screenshot Settings → Manage categories → tap a row (edit form). Then **revert both temp edits**.

- [ ] **Step 3: Commit (if revert produced changes), push, PR**
```bash
git push -u origin feature/category-manage-ui
```
Open PR `feature/category-manage-ui` → `main` via GitHub web; confirm CI green.

---

## Self-review notes
- **Spec coverage:** Settings shell + tab wiring (T1), Manage list + add/edit entry (T1),
  add/edit form with icon/color/validation (T2). Delete + Entry hook deferred to PR3 (per spec).
- **Reuses PR1:** `CategoryActions`, `isCategoryNameAvailable`, `categoryIconChoices`.
- **`Color.toHex()`** added + round-trip tested for the custom color picker.
- **Type consistency:** `CategoryFormView(editing:)`, `ManageCategoriesView()`, `SettingsView()`,
  `Color.toHex()` consistent. `@Query` containers come from the environment (seeded in previews).
