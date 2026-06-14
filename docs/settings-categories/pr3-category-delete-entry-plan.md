# PR3 — Category Delete + Entry Hook Implementation Plan

> Execute inline (no worktrees). Steps use `- [ ]`. Branch off `main` after PR2 merges.

**Goal:** Finish category management — delete a category (empty deletes; in-use prompts to reassign; last one is protected) and re-enable Entry's "New category" so it creates and selects a category inline.

**Architecture:** Add a plain `CategoryActions.delete(_:in:)` and make `.add` return the created category. `ManageCategoriesView` gets swipe-to-delete → `ReassignCategorySheet` for in-use categories. Entry's `CategoryPickerSheet` regains its "New category" button, presenting `CategoryFormView` which reports the saved category back so Entry selects it.

**Tech Stack:** SwiftUI, SwiftData, PR1/PR2 code. iOS 18.

---

## Conventions
- Branch `feature/category-delete-entry` off updated `main`. No worktrees.
- Commits present-tense + `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- When a commit also deletes a file, do NOT pass the deleted path to `git add` (per
  `memory/git-rm-add-gotcha.md`) — none expected here.

## File Structure
- Modify `plop/plop/Data/CategoryActions.swift` (+ `delete(_:in:)`, `.add` returns category)
- Modify `plop/plopTests/CategoryActionsTests.swift`
- Create `plop/plop/Views/Settings/ReassignCategorySheet.swift`
- Modify `plop/plop/Views/Settings/ManageCategoriesView.swift` (delete flow)
- Modify `plop/plop/Views/Settings/CategoryFormView.swift` (onSave callback)
- Modify `plop/plop/Views/Entry/CategoryPickerSheet.swift` (New category button)
- Modify `plop/plop/Views/Entry/EntryView.swift` (wire New category)

---

### Task 1: `CategoryActions` — plain delete + add returns category

**Files:** modify `CategoryActions.swift`, `CategoryActionsTests.swift`.

- [ ] **Step 1: Branch**
```bash
git checkout main && git pull --ff-only && git checkout -b feature/category-delete-entry
```

- [ ] **Step 2: Add failing tests** (append inside `CategoryActionsTests`)
```swift
    func test_add_returnsInsertedCategory() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let created = CategoryActions.add(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC", in: ctx)
        XCTAssertEqual(created.name, "Food")
        let cats = try ctx.fetch(FetchDescriptor<ExpenseCategory>())
        XCTAssertEqual(cats.count, 1)
    }

    func test_delete_removesEmptyCategory() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let cat = ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC")
        ctx.insert(cat)
        try ctx.save()

        CategoryActions.delete(cat, in: ctx)
        try ctx.save()

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ExpenseCategory>()).count, 0)
    }
```

- [ ] **Step 3: Run to verify it fails**
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/CategoryActionsTests/test_delete_removesEmptyCategory
```
Expected: FAIL — no `delete(_:in:)`.

- [ ] **Step 4: Update `CategoryActions`**

Change `add` to return the category, and add the plain `delete`:
```swift
    @discardableResult
    static func add(name: String, symbolName: String, colorHex: String, in context: ModelContext) -> ExpenseCategory {
        let category = ExpenseCategory(name: name, symbolName: symbolName, colorHex: colorHex)
        context.insert(category)
        return category
    }

    /// Delete a category that has no transactions (or whose transactions you don't need to keep).
    static func delete(_ category: ExpenseCategory, in context: ModelContext) {
        context.delete(category)
    }
```
(Keep `update` and `delete(_:reassigningTo:in:)` as-is.)

- [ ] **Step 5: Run to verify it passes, then commit**
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/CategoryActionsTests
```
Expected: PASS (5).
```bash
git add plop/plop/Data/CategoryActions.swift plop/plopTests/CategoryActionsTests.swift
git commit -m "Add plain category delete and return created category from add"
```

---

### Task 2: Delete flow in Manage Categories

**Files:** create `ReassignCategorySheet.swift`; modify `ManageCategoriesView.swift`.

- [ ] **Step 1: `ReassignCategorySheet.swift`**
```swift
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
                    Text("Move \(category.transactions.count) transaction\(category.transactions.count == 1 ? "" : "s") from \"\(category.name)\" to:")
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
```

- [ ] **Step 2: Add the delete flow to `ManageCategoriesView`**

Add `@Environment(\.modelContext) private var modelContext`, two `@State`s, the swipe
action, the reassign sheet, and the last-category alert.

State (next to the existing `@State`s):
```swift
    @Environment(\.modelContext) private var modelContext
    @State private var reassigning: ExpenseCategory?
    @State private var showLastCategoryAlert = false
```
Swipe action — change the `ForEach` row to add `.swipeActions`:
```swift
            ForEach(categories) { category in
                Button { editing = category } label: { row(category) }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { requestDelete(category) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
```
Modifiers — add alongside the existing `.sheet`s:
```swift
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
```
Handler (add as a method):
```swift
    private func requestDelete(_ category: ExpenseCategory) {
        if categories.count <= 1 {
            showLastCategoryAlert = true
        } else if category.transactions.isEmpty {
            CategoryActions.delete(category, in: modelContext)
        } else {
            reassigning = category
        }
    }
```

- [ ] **Step 3: Build, then commit**
```bash
xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'
```
Expected: `** BUILD SUCCEEDED **`.
```bash
git add plop/plop/Views/Settings/ReassignCategorySheet.swift plop/plop/Views/Settings/ManageCategoriesView.swift
git commit -m "Add category delete with reassignment and last-category guard"
```

---

### Task 3: Entry "New category" hook, verify, PR

**Files:** modify `CategoryFormView.swift`, `CategoryPickerSheet.swift`, `EntryView.swift`.

- [ ] **Step 1: `CategoryFormView` reports the saved category**

Add a callback property:
```swift
    var onSave: ((ExpenseCategory) -> Void)? = nil
```
Update `save()`:
```swift
    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let editing {
            CategoryActions.update(editing, name: trimmed, symbolName: symbolName, colorHex: colorHex)
            onSave?(editing)
        } else {
            let created = CategoryActions.add(name: trimmed, symbolName: symbolName, colorHex: colorHex, in: modelContext)
            onSave?(created)
        }
        dismiss()
    }
```

- [ ] **Step 2: `CategoryPickerSheet` regains "New category"**

Add a callback and a button. Add property:
```swift
    var onAddNew: () -> Void
```
After the category grid (before the closing of the VStack), add:
```swift
            Button(action: onAddNew) {
                Label("New category", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                            .foregroundStyle(Palette.ink12)
                    )
            }
            .buttonStyle(.plain)
```

- [ ] **Step 3: Wire it in `EntryView`**

Add state:
```swift
    @State private var showingNewCategory = false
```
Update the category picker sheet call to pass `onAddNew`:
```swift
        .sheet(isPresented: $pickerOpen) {
            CategoryPickerSheet(categories: categories, selected: $selected,
                                onDismiss: { pickerOpen = false },
                                onAddNew: { pickerOpen = false; showingNewCategory = true })
        }
```
Add a sheet that presents the form and selects the new category:
```swift
        .sheet(isPresented: $showingNewCategory) {
            CategoryFormView(onSave: { selected = $0 })
        }
```

- [ ] **Step 4: Full test + lint**
```bash
xcrun simctl shutdown all 2>/dev/null; sleep 2
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO
swiftlint lint
```
Expected: 53 tests pass (51 + 2 new); no lint errors.

- [ ] **Step 5: Simulator check**

Run the app: Settings → Manage categories → swipe-delete an unused category (gone) and an
in-use one (reassign sheet → pick → moved). In Entry, open Category → "New category" →
create one → it's selected. Screenshot the reassign sheet. (No temp edits needed — these
are reachable by tapping.)

- [ ] **Step 6: Commit, push, PR**
```bash
git add plop/plop/Views/Settings/CategoryFormView.swift \
        plop/plop/Views/Entry/CategoryPickerSheet.swift plop/plop/Views/Entry/EntryView.swift
git commit -m "Re-enable Entry New category and select the created category"
git push -u origin feature/category-delete-entry
```
Open PR `feature/category-delete-entry` → `main` via GitHub web; confirm CI green.

---

## Self-review notes
- **Spec coverage:** delete (empty/in-use→reassign/last-blocked) — T1+T2; Entry "New
  category" creates + selects — T3. Completes the category-management spec.
- **Reuses:** `CategoryActions.delete(_:reassigningTo:in:)` (PR1), `CategoryFormView` (PR2).
- **Type consistency:** `CategoryActions.add(...) -> ExpenseCategory`, `.delete(_:in:)`,
  `ReassignCategorySheet(category:targets:)`, `CategoryFormView(editing:onSave:)`,
  `CategoryPickerSheet(categories:selected:onDismiss:onAddNew:)`.
- **No new model changes.** `category.transactions` drives the in-use check and count.
