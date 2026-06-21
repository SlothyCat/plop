# Dialog Popups B2b (Manage categories cluster) — Design

Status: Approved (brainstorm complete) · Date: 2026-06-21

Companion to `requirements.md`. The `BlurPopup` item overload, the `CategoryActions` budget
change, the three rebuilt dialogs (stacked), the `SettingsView` swap, testing, and scope.

## Architecture

```
plop/Views/Common/BlurPopup.swift            (add item: overload)
plop/Data/CategoryActions.swift              (add/update gain budget: Decimal)
plop/Views/Settings/ManageCategoriesView.swift  (tall popup; stacked children)
plop/Views/Settings/CategoryFormView.swift      (hug popup; + budget field)
plop/Views/Settings/ReassignCategorySheet.swift (tall stacked popup)
plop/Views/Settings/SettingsView.swift          (row → Button + .blurPopup tall)
plopTests/…CategoryActions test                  (budget persisted)
```

## 1. `BlurPopup` — item overload

Mirrors `.sheet(item:)` so Edit / Reassign can present a specific category. Reuses
`BlurPopupContainer`; clearing happens by setting the item to nil.

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
(The existing `isPresented:` overload, `tall`, `readHeight`, and `\.blurPopupClose` are
unchanged. `ExpenseCategory` is `Identifiable` via `@Model`.)

## 2. `CategoryActions` — budget

```swift
@discardableResult
static func add(name: String, symbolName: String, colorHex: String,
                budget: Decimal = 0, in context: ModelContext) -> ExpenseCategory {
    let category = ExpenseCategory(name: name, symbolName: symbolName,
                                   colorHex: colorHex, budget: budget)
    context.insert(category)
    return category
}

static func update(_ category: ExpenseCategory, name: String, symbolName: String,
                   colorHex: String, budget: Decimal) {
    category.name = name
    category.symbolName = symbolName
    category.colorHex = colorHex
    category.budget = budget
}
```
`delete` / `delete(reassigningTo:)` unchanged. `ExpenseCategory.init` already accepts
`budget: Decimal = 0`.

## 3. Manage categories (match `category.jpg`) — `tall`

Card: header (title + round ×) + subtitle, a scrolling list of category cards, a pinned
"+ Add category". Child dialogs present **stacked** via `.blurPopup` from this card. The
delete flow (`requestDelete`: last-category alert / reassign / direct delete) is unchanged —
only the trigger moves from swipe to the trash button.

```swift
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
```
(`tall` so a long category list scrolls; the "+ Add category" button stays pinned below the
scroll, like the handoff.)

## 4. Add / Edit category (match `add_category.jpg`) — hug

Header + subtitle; NAME field; ICON (SF-glyph grid — **Icons only**, emoji deferred); COLOR
swatches + custom-color well; **MONTHLY BUDGET · OPTIONAL** $-prefixed field; Save (disabled
until the name is valid) + Cancel. Keeps name validation, icon/color options, and `onSave`.

```swift
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
                Button(action: { save() }) {
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
```
Note: `onSave` loses its `= nil` default (SwiftLint `implicit_optional_initialization`); call
sites that omit it still compile (optional defaults to nil in the memberwise init). The form
hugs; the keyboard raises the card for the NAME / budget fields.

## 5. Reassign (stacked) — `tall`

```swift
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
                    .padding(.horizontal, 20).padding(.vertical, 4).readHeight(into: $listHeight)
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
```
(Drops the old `NavigationStack` / `.presentationDetents`.)

## 6. SettingsView

```swift
    @State private var showingManage = false
```
Manage categories row:
```swift
// before: NavigationLink { ManageCategoriesView() } label: { SettingsRow(... "Manage categories" ...) }
Button { showingManage = true } label: {
    SettingsRow(tile: Palette.accentSoft, systemImage: "tag.fill",
                title: "Manage categories", showsChevron: false)
}
.buttonStyle(.plain)
```
Add popup (alongside the others):
```swift
.blurPopup(isPresented: $showingManage, tall: true) { ManageCategoriesView() }
```
The `NavigationStack` stays (it hosts the "Settings" title; no `NavigationLink`s remain but
the title relies on it).

## Testing

- **Unit:** extend `plop/plopTests/CategoryActionsTests.swift` — assert
  `CategoryActions.add(…, budget:)` and `update(…, budget:)` persist the budget. The
  existing `update` test call (currently `update(cat, name:symbolName:colorHex:)`) must gain a
  `budget:` argument, since `update` now requires it (`add`'s `budget` defaults to 0, so its
  existing calls still compile). Only `CategoryFormView` + this test call these APIs.
- **Views:** preview + simulator vs `category.jpg` / `add_category.jpg`, light + dark:
  - **stacked blur** — Add/Edit/Reassign slide up over the blurred Manage popup;
  - Manage: $X/mo + trash, tap-to-edit, "+ Add category"; × and drag/tap dismiss;
  - Add/Edit: name, icon grid, color (incl. custom), **budget field**; Save disabled until a
    valid name; edit prefills incl. budget; keyboard raises the card;
  - delete → reassign for a category with transactions; last-category alert for the final one;
  - B1/B2a dialogs still work (new `item:` overload doesn't affect them).

## Scope

Emoji category icons deferred to a separate feature. One PR on `feature/dialog-popups-3`.
