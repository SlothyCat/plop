# Dialog Popups B2b (Manage categories cluster) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the Manage categories cluster (Manage categories + Add/Edit category + Reassign) to stacked `BlurPopup`s matching the handoff, and add an optional monthly budget to the category form.

**Architecture:** Add an `item:` overload to `BlurPopup`; give `CategoryActions.add/update` a `budget`; rebuild the three dialog views as popup cards (Manage + Reassign `tall` with scrolling lists, Add/Edit hugging with a budget field); `SettingsView` presents Manage via `.blurPopup(tall: true)`. Presentation + one small TDD'd logic change (budget).

**Tech Stack:** SwiftUI (`fullScreenCover`, `GeometryReader`, materials), SwiftData, XCTest. iOS 18. Views verified via `#Preview` + simulator.

Single PR on branch `feature/dialog-popups-3` (off `feature/dialog-popups-2`; spec committed
there). Rebase onto `main` after B1 + B2a merge, before opening this PR.

---

## File structure

- **Modify** `plop/plop/Views/Common/BlurPopup.swift` — add the `item:` overload.
- **Modify** `plop/plop/Data/CategoryActions.swift` — `add`/`update` gain `budget`.
- **Modify** `plop/plopTests/CategoryActionsTests.swift` — budget assertions; fix the
  `update` call.
- **Modify** `plop/plop/Views/Settings/ManageCategoriesView.swift` — tall popup, stacked children.
- **Modify** `plop/plop/Views/Settings/CategoryFormView.swift` — hug popup + budget field.
- **Modify** `plop/plop/Views/Settings/ReassignCategorySheet.swift` — tall stacked popup.
- **Modify** `plop/plop/Views/Settings/SettingsView.swift` — Manage row → Button + `.blurPopup`.

### Build / lint / test commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | tail -5

cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests/CategoryActionsTests \
  -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2

swiftlint lint
```

> SourceKit "Cannot find X in scope" / "No such module" diagnostics are FALSE positives —
> `xcodebuild` is the source of truth. Lines ≤ 120. No `// swiftlint:disable`. Keep the lint
> baseline (21 violations, 0 serious); do not edit `.swiftlint.yml`.

---

## Task 1: `BlurPopup` item overload

**Files:**
- Modify: `plop/plop/Views/Common/BlurPopup.swift`

- [ ] **Step 1: Add the `item:` overload**

In `BlurPopup.swift`, immediately AFTER the closing `}` of the existing
`func blurPopup<Card: View>(isPresented:tall:onDismiss:card:)` (still inside the
`extension View { … }` block), add:

```swift

    func blurPopup<Item: Identifiable, Card: View>(
        item: Binding<Item?>,
        tall: Bool = false,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder card: @escaping (Item) -> Card
    ) -> some View {
        fullScreenCover(item: item, onDismiss: onDismiss) { value in
            BlurPopupContainer(
                isPresented: Binding(get: { item.wrappedValue != nil },
                                     set: { if !$0 { item.wrappedValue = nil } }),
                tall: tall
            ) { card(value) }
                .presentationBackground(.clear)
        }
        .transaction { $0.disablesAnimations = true }
    }
```

- [ ] **Step 2: Build** — run the build command → `** BUILD SUCCEEDED **`. (Overload unused
  yet; just compiles.)

- [ ] **Step 3: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Common/BlurPopup.swift
git commit -m "Add item-based blurPopup overload

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: `CategoryActions` budget (TDD)

**Files:**
- Modify: `plop/plopTests/CategoryActionsTests.swift`
- Modify: `plop/plop/Data/CategoryActions.swift`

- [ ] **Step 1: Update the tests first (red)**

In `CategoryActionsTests.swift`, change the `update` call in `test_update_mutatesFields`
(it now requires `budget:`) and add a budget assertion. Change:
```swift
        CategoryActions.update(cat, name: "Groceries", symbolName: "cart.fill", colorHex: "#8CC0EB")
        try ctx.save()

        XCTAssertEqual(cat.name, "Groceries")
        XCTAssertEqual(cat.symbolName, "cart.fill")
        XCTAssertEqual(cat.colorHex, "#8CC0EB")
    }
```
to:
```swift
        CategoryActions.update(cat, name: "Groceries", symbolName: "cart.fill",
                               colorHex: "#8CC0EB", budget: 250)
        try ctx.save()

        XCTAssertEqual(cat.name, "Groceries")
        XCTAssertEqual(cat.symbolName, "cart.fill")
        XCTAssertEqual(cat.colorHex, "#8CC0EB")
        XCTAssertEqual(cat.budget, 250)
    }
```

Then add a new test after `test_add_returnsInsertedCategory` (before
`test_delete_removesEmptyCategory`):
```swift
    func test_add_persistsBudget() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let created = CategoryActions.add(name: "Food", symbolName: "fork.knife",
                                          colorHex: "#FFEBCC", budget: 300, in: ctx)
        XCTAssertEqual(created.budget, 300)
        try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ExpenseCategory>()).first?.budget, 300)
    }

    func test_add_defaultsBudgetToZero() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let created = CategoryActions.add(name: "Food", symbolName: "fork.knife",
                                          colorHex: "#FFEBCC", in: ctx)
        XCTAssertEqual(created.budget, 0)
    }
```

- [ ] **Step 2: Run tests to verify they fail** — run the test command. Expected: FAIL /
  compile error (`update` has no `budget:` label; `cat.budget` mismatch).

- [ ] **Step 3: Add `budget` to `CategoryActions`**

In `CategoryActions.swift`, change the `add` signature:
```swift
    @discardableResult
    static func add(name: String, symbolName: String, colorHex: String, in context: ModelContext) -> ExpenseCategory {
        let category = ExpenseCategory(name: name, symbolName: symbolName, colorHex: colorHex)
        context.insert(category)
        return category
    }
```
to:
```swift
    @discardableResult
    static func add(name: String, symbolName: String, colorHex: String,
                    budget: Decimal = 0, in context: ModelContext) -> ExpenseCategory {
        let category = ExpenseCategory(name: name, symbolName: symbolName,
                                       colorHex: colorHex, budget: budget)
        context.insert(category)
        return category
    }
```
and change `update`:
```swift
    static func update(_ category: ExpenseCategory, name: String, symbolName: String, colorHex: String) {
        category.name = name
        category.symbolName = symbolName
        category.colorHex = colorHex
    }
```
to:
```swift
    static func update(_ category: ExpenseCategory, name: String, symbolName: String,
                       colorHex: String, budget: Decimal) {
        category.name = name
        category.symbolName = symbolName
        category.colorHex = colorHex
        category.budget = budget
    }
```
(Leave both `delete` methods unchanged.)

- [ ] **Step 4: Run tests to verify they pass** — run the test command → `** TEST
  SUCCEEDED **`.

> NOTE: `CategoryFormView` still calls the OLD `update`/`add` (no `budget:`) at this point.
> `add`'s `budget` defaults to 0 so its call still compiles, but `update` now requires
> `budget:` — so a full BUILD will fail until Task 4. That's expected; this task only runs
> the `CategoryActionsTests` (which compile against the new APIs). Do NOT run a full build
> here; proceed to commit and then Task 4.

- [ ] **Step 5: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Data/CategoryActions.swift plop/plopTests/CategoryActionsTests.swift
git commit -m "Add budget to CategoryActions add/update

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Rebuild ManageCategoriesView (tall popup, stacked children)

**Files:**
- Modify: `plop/plop/Views/Settings/ManageCategoriesView.swift`

- [ ] **Step 1: Replace the file**

Replace the ENTIRE contents of `ManageCategoriesView.swift` with:

```swift
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
```

- [ ] **Step 2: Build** — run the build command. NOTE: this will still FAIL to build because
  `CategoryFormView` (rebuilt in Task 4) currently calls the old `update` without `budget:`.
  That is expected; just confirm the only errors are in `CategoryFormView.swift`. (If you see
  errors in `ManageCategoriesView.swift` itself, fix them.) Proceed to Task 4; the build is
  verified green at the end of Task 4.

- [ ] **Step 3: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/ManageCategoriesView.swift
git commit -m "Rebuild Manage categories as a tall blur popup with stacked children

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Rebuild CategoryFormView (hug popup + budget field)

**Files:**
- Modify: `plop/plop/Views/Settings/CategoryFormView.swift`

- [ ] **Step 1: Replace the file**

Replace the ENTIRE contents of `CategoryFormView.swift` with:

```swift
import SwiftUI
import SwiftData

/// Add (editing == nil) or edit a category as a blur popup: name, SF-symbol icon, color,
/// and an optional monthly budget. Matches the handoff Add/Edit category dialog.
struct CategoryFormView: View {
    var editing: ExpenseCategory?
    var onSave: ((ExpenseCategory) -> Void)?

    @Environment(\.blurPopupClose) private var close
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.name) private var existing: [ExpenseCategory]
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()

    @State private var name = ""
    @State private var symbolName = "tag.fill"
    @State private var colorHex = "#8CC0EB"
    @State private var budgetField = ""

    private let swatches = ["#8CC0EB", "#BFDDF0", "#FFEBCC", "#FFF9D2"]
    private let iconColumns = [GridItem(.adaptive(minimum: 50), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(editing == nil ? "New category" : "Edit category")
                    .font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.ink)
                Text("Group your transactions under a custom label.")
                    .font(.system(size: 15)).foregroundStyle(Palette.ink60)
                    .fixedSize(horizontal: false, vertical: true)
            }
            field("NAME") {
                TextField("e.g. Transport", text: $name)
                    .font(.system(size: 16)).foregroundStyle(Palette.ink)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(Palette.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.ink12, lineWidth: 1))
            }
            field("ICON") {
                LazyVGrid(columns: iconColumns, spacing: 10) {
                    ForEach(categoryIconChoices, id: \.self) { iconButton($0) }
                }
            }
            field("COLOR") {
                HStack(spacing: 14) {
                    ForEach(swatches, id: \.self) { swatchView($0) }
                    ColorPicker("Custom", selection: colorBinding).labelsHidden()
                }
            }
            field("MONTHLY BUDGET · OPTIONAL") { budgetFieldView }
            VStack(spacing: 4) {
                Button { save() } label: {
                    Text("Save")
                        .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.tileInk)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(Palette.accent.opacity(canSave ? 1 : 0.45),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain).disabled(!canSave)
                Button("Cancel") { close() }
                    .font(.system(size: 16, weight: .medium)).foregroundStyle(Palette.ink60)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 18)
        .onAppear(perform: prefill)
    }

    private func field<Content: View>(_ label: String,
                                      @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label).font(.system(size: 12.5, weight: .semibold)).tracking(0.4)
                .foregroundStyle(Palette.ink40)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
    }

    private var budgetFieldView: some View {
        HStack(spacing: 6) {
            Text(currencySymbol(currencyCode))
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.ink40)
            TextField("No budget", text: $budgetField)
                .keyboardType(.decimalPad).font(.system(size: 16)).foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Palette.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.ink12, lineWidth: 1))
    }

    private func iconButton(_ symbol: String) -> some View {
        let on = symbol == symbolName
        return Button { symbolName = symbol } label: {
            Image(systemName: symbol)
                .font(.system(size: 20)).foregroundStyle(on ? Palette.tileInk : Palette.ink)
                .frame(width: 46, height: 46)
                .background(on ? Color(hex: colorHex) : Palette.field,
                            in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13)
                    .stroke(on ? Color.clear : Palette.ink12, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func swatchView(_ hex: String) -> some View {
        Circle().fill(Color(hex: hex)).frame(width: 34, height: 34)
            .overlay(Circle().stroke(Palette.ink, lineWidth: hex == colorHex ? 2.5 : 0))
            .onTapGesture { colorHex = hex }
    }

    private var colorBinding: Binding<Color> {
        Binding(get: { Color(hex: colorHex) }, set: { colorHex = $0.toHex() })
    }

    private var canSave: Bool {
        isCategoryNameAvailable(name, existing: existing, editing: editing)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let budget = parseBudgetAmount(budgetField)
        if let editing {
            CategoryActions.update(editing, name: trimmed, symbolName: symbolName,
                                   colorHex: colorHex, budget: budget)
            onSave?(editing)
        } else {
            let created = CategoryActions.add(name: trimmed, symbolName: symbolName,
                                              colorHex: colorHex, budget: budget,
                                              in: modelContext)
            onSave?(created)
        }
        close()
    }

    private func prefill() {
        guard let editing else { return }
        name = editing.name
        symbolName = editing.symbolName
        colorHex = editing.colorHex
        budgetField = editing.budget > 0 ? formatBudgetAmount(editing.budget) : ""
    }
}

#if DEBUG
#Preview { CategoryFormView().modelContainer(SampleData.previewContainer()) }
#endif
```

- [ ] **Step 2: Build** — run the build command → `** BUILD SUCCEEDED **` (Tasks 3 + 4
  together now compile: `ManageCategoriesView` presents `CategoryFormView`, which calls the
  new `CategoryActions` APIs from Task 2).

- [ ] **Step 3: Lint** — `swiftlint lint` → no new violations (note: `onSave` has no `= nil`
  to avoid `implicit_optional_initialization`).

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/CategoryFormView.swift
git commit -m "Rebuild Add/Edit category as a blur popup with a monthly-budget field

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Rebuild ReassignCategorySheet (tall stacked popup)

**Files:**
- Modify: `plop/plop/Views/Settings/ReassignCategorySheet.swift`

- [ ] **Step 1: Replace the file**

Replace the ENTIRE contents of `ReassignCategorySheet.swift` with:

```swift
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
```

- [ ] **Step 2: Build** — run the build command → `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/ReassignCategorySheet.swift
git commit -m "Rebuild Reassign as a tall stacked blur popup

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 6: Present Manage categories via `.blurPopup`

**Files:**
- Modify: `plop/plop/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Add a state flag**

In `SettingsView.swift`, add `showingManage` alongside the other flags. Change:
```swift
    @State private var showingBudget = false
    @State private var showingCurrency = false
```
to:
```swift
    @State private var showingBudget = false
    @State private var showingCurrency = false
    @State private var showingManage = false
```

- [ ] **Step 2: Convert the Manage categories row**

Change:
```swift
                    NavigationLink { ManageCategoriesView() } label: {
                        SettingsRow(tile: Palette.accentSoft, systemImage: "tag.fill",
                                    title: "Manage categories", showsChevron: false)
                    }
```
to:
```swift
                    Button { showingManage = true } label: {
                        SettingsRow(tile: Palette.accentSoft, systemImage: "tag.fill",
                                    title: "Manage categories", showsChevron: false)
                    }
                    .buttonStyle(.plain)
```

- [ ] **Step 3: Add the popup**

Change:
```swift
            .blurPopup(isPresented: $showingCurrency, tall: true) {
                CurrencyView()
            }
```
to:
```swift
            .blurPopup(isPresented: $showingCurrency, tall: true) {
                CurrencyView()
            }
            .blurPopup(isPresented: $showingManage, tall: true) {
                ManageCategoriesView()
            }
```

- [ ] **Step 4: Build** — run the build command → `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/SettingsView.swift
git commit -m "Present Manage categories as a tall blur popup

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 7: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite** (CategoryActions tests are new; rest unchanged)

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` (~171 — 169 + 2 new budget tests).

- [ ] **Step 2: Lint** — `swiftlint lint` → baseline 21/0, no new violations.

- [ ] **Step 3: Simulator smoke check (manual — owner)**

Against `category.jpg` / `add_category.jpg`, light + dark:
- **Manage categories** opens as a blurred bottom popup: category cards with colored tile,
  name, **$X/mo** (or "No budget"), and a **trash** button; pinned **"+ Add category"**;
  the list scrolls when long; **×** / tap-scrim / drag dismiss.
- **Tap a card** → **Edit category** slides up **stacked** over the (blurred) Manage popup;
  **"+ Add category"** → **New category**.
- **Add/Edit:** name, icon grid, color swatches + **custom color**, **MONTHLY BUDGET** field;
  **Save** disabled until a valid name; editing prefills incl. budget; the keyboard raises the
  card; Save persists (reopen shows the new budget as "$X/mo").
- **Trash** a category **with transactions** → **Reassign** stacked popup; picking a target
  moves them and deletes. Trash the **last** category → the "keep at least one" alert.
- B1/B2a dialogs still work; nothing else in Settings changed.

- [ ] **Step 4: Rebase onto `main` (after B1 + B2a merge), then push + PR**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git fetch origin && git rebase origin/main
```
Re-run Steps 1–2 after the rebase. Then:
```bash
git push -u origin feature/dialog-popups-3
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Cleanup B2b: convert the Manage categories cluster (Manage categories + Add/Edit category +
Reassign) to stacked blur popups matching the handoff, add an item-based blurPopup overload,
and add an optional monthly budget to the category form. Emoji category icons deferred.

## Testing
All unit tests pass (2 new for CategoryActions budget); SwiftLint clean (baseline 21/0).
Sim-verified vs category.jpg / add_category.jpg: stacked popups, $X/mo + trash, add/edit incl.
budget, reassign-on-delete + last-category alert, keyboard-rise; light + dark.
```

---

## Self-review notes

- **Spec coverage:** item overload (Task 1); `CategoryActions` budget + tests (Task 2);
  Manage popup w/ $X/mo + trash + stacked children + Add button (Task 3); Add/Edit popup +
  budget field, Icons-only (Task 4); Reassign stacked popup (Task 5); SettingsView row →
  `.blurPopup(tall:)`, NavigationStack kept (Task 6); regression + sim check (Task 7). All
  spec items map to a task. Emoji icons explicitly out of scope.
- **Build-green ordering:** Task 2 changes `update` to require `budget:`, which breaks a full
  build until `CategoryFormView` is rebuilt — so Tasks 3+4 are verified together (full BUILD
  green at end of Task 4). Task 2 itself only runs `CategoryActionsTests` (which compile
  against the new APIs). This is called out in Tasks 2 and 3.
- **Type consistency:** `blurPopup(item:tall:onDismiss:card:)`; `CategoryActions.add(…,
  budget: Decimal = 0, in:)` and `update(…, budget: Decimal)`; views read
  `@Environment(\.blurPopupClose)` and use `readHeight(into:)`/`tall`. `ExpenseCategory`
  is `Identifiable` (`@Model`) and `.init` accepts `budget: Decimal = 0`. `parseBudgetAmount`
  / `formatBudgetAmount` / `formattedMoney` / `currencySymbol` / `isCategoryNameAvailable`
  / `categoryIconChoices` all exist and are reused unchanged.
- **Behavior preserved:** delete / reassign / last-category guard, name validation, icon &
  color options, `onSave` — unchanged; only presentation + the new budget field.
- **No placeholders / no disables / config untouched / lines ≤ 120.**
