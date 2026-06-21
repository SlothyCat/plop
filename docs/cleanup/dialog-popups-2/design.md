# Dialog Popups B2a (Currency + Set budget) — Design

Status: Approved · Date: 2026-06-21 (revised to full handoff fidelity)

Companion to `requirements.md`. The `BlurPopup` `tall` option, the two conversions built
to match `currency.jpg` / `budget.jpg`, the `currencyFlag` helper, testing, and scope.

## Architecture

```
plop/Logic/Currency.swift                (add currencyFlag(_:) — pure, unit-tested)
plop/Views/Common/BlurPopup.swift        (add `tall` option — DONE)
plop/Views/Settings/CurrencyView.swift   (rebuild to match currency.jpg)
plop/Views/Settings/BudgetView.swift     (rebuild to match budget.jpg)
plop/Views/Settings/SettingsView.swift   (rows → Button + .blurPopup tall — DONE)
plopTests/CurrencyTests.swift            (currencyFlag cases)
```

`BlurPopup` `tall` option and the `SettingsView` row wiring are already implemented (B2a
first pass). This revision rebuilds the two view bodies to full fidelity and adds the flag
helper + test.

## 1. `BlurPopup` — `tall` option (done)

`func blurPopup(isPresented:tall:onDismiss:card:)` with `tall: Bool = false`. When `true`,
the container caps the card at ~80% of the available height (via `GeometryReader`) so the
content scrolls inside. `tall: false` preserves B1's hug behavior. No further change.

## 2. `currencyFlag(_:)` helper

Each supported currency code's first two letters are its flag region (USD→US, EUR→EU,
GBP→GB, CHF→CH, …), so a single mapping to Unicode regional-indicator symbols covers all of
`currencyChoices`. Pure function → unit-tested (project rule: business logic is TDD'd).

```swift
/// Flag emoji for a currency code (first two letters = region: USD→🇺🇸, EUR→🇪🇺, CHF→🇨🇭).
/// Returns "" if the code doesn't yield two A–Z letters.
func currencyFlag(_ code: String) -> String {
    let region = code.prefix(2).uppercased()
    guard region.count == 2 else { return "" }
    var flag = ""
    for scalar in region.unicodeScalars {
        guard scalar.value >= 65, scalar.value <= 90,
              let indicator = Unicode.Scalar(0x1F1E6 + scalar.value - 65) else { return "" }
        flag.unicodeScalars.append(indicator)
    }
    return flag
}
```

Test (`plopTests/CurrencyTests.swift`, add to the existing file or create it):
```swift
func testCurrencyFlagMapsCodeToRegionFlag() {
    XCTAssertEqual(currencyFlag("USD"), "🇺🇸")
    XCTAssertEqual(currencyFlag("EUR"), "🇪🇺")
    XCTAssertEqual(currencyFlag("GBP"), "🇬🇧")
    XCTAssertEqual(currencyFlag("CHF"), "🇨🇭")
    XCTAssertEqual(currencyFlag("JPY"), "🇯🇵")
}

func testCurrencyFlagAllChoicesNonEmpty() {
    for code in currencyChoices {
        XCTAssertFalse(currencyFlag(code).isEmpty, "no flag for \(code)")
    }
}

func testCurrencyFlagEmptyForBadCode() {
    XCTAssertEqual(currencyFlag("1"), "")
}
```

## 3. Currency (match `currency.jpg`)

Tall popup, white card. A fixed **header**, a **scrolling list of row-cards**, and a
**pinned bottom Done**. Switch `List` → `ScrollView`+`LazyVStack` so rows can be cards with
a custom accent-filled selected state. Selection still writes `@AppStorage` live.

```swift
import SwiftUI

/// Picks the app-wide display currency (no conversion). Matches the handoff Currency popup.
struct CurrencyView: View {
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @Environment(\.blurPopupClose) private var close

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(currencyChoices, id: \.self) { code in
                        Button { currencyCode = code } label: { row(code) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            doneBar
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Currency")
                .font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.ink)
            Text("Pick the currency symbol used across the app. Amounts aren't converted.")
                .font(.system(size: 15)).foregroundStyle(Palette.ink60)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 12)
    }

    private func row(_ code: String) -> some View {
        let on = code == currencyCode
        return HStack(spacing: 13) {
            Text(currencyFlag(code))
                .font(.system(size: 22))
                .frame(width: 44, height: 44)
                .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.ink12, lineWidth: 1))
            VStack(alignment: .leading, spacing: 1) {
                Text(code)
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.ink)
                Text(currencyDisplayName(code))
                    .font(.system(size: 13.5)).foregroundStyle(Palette.ink40).lineLimit(1)
            }
            Spacer()
            if on {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.ink)
            }
        }
        .padding(12)
        .background(on ? Palette.accent : Palette.card,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(on ? Color.clear : Palette.ink12, lineWidth: 1))
    }

    private var doneBar: some View {
        Button("Done") { close() }
            .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .overlay(Rectangle().fill(Palette.hair).frame(height: 1), alignment: .top)
    }
}

#if DEBUG
#Preview { CurrencyView() }
#endif
```
Notes: flag tile is white (so it reads on the accent-filled selected row too); the selected
row uses `Palette.accent` with no border; `currencySymbol` is no longer shown per the
handoff (code + name only). The `currencyChoices`, `currencyDisplayName`, and the
`@AppStorage` write are unchanged.

## 4. Set budget (match `budget.jpg`)

Tall popup. A fixed top block (icon header + segmented + subtitle), a **scrolling**
category/amount area, and a **pinned bottom block** (total card + Save + Cancel). Replaces
inline `TextField`s with `$`-prefixed field **cards**; keeps all save logic.

```swift
import SwiftUI
import SwiftData

/// Sets the app's monthly budget (Total or By-category). Matches the handoff Set budget popup.
struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.blurPopupClose) private var close
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @AppStorage(budgetModeKey) private var modeRaw = BudgetMode.category.rawValue
    @AppStorage(generalBudgetKey) private var generalBudget = ""

    @State private var generalField = ""
    @State private var catFields: [PersistentIdentifier: String] = [:]

    private var mode: BudgetMode { BudgetMode(rawValue: modeRaw) ?? .category }

    var body: some View {
        VStack(spacing: 0) {
            header
            VStack(spacing: 14) {
                Picker("Budget mode", selection: $modeRaw) {
                    Text("Total").tag(BudgetMode.general.rawValue)
                    Text("By category").tag(BudgetMode.category.rawValue)
                }
                .pickerStyle(.segmented)
                Text(mode == .general
                     ? "One monthly budget. Categories are ignored in this mode."
                     : "Give each category its own limit — they add up to your total.")
                    .font(.system(size: 14)).foregroundStyle(Palette.ink60)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)

            ScrollView {
                VStack(spacing: 10) {
                    if mode == .general {
                        fieldCard(text: $generalField)
                    } else {
                        ForEach(categories) { cat in categoryRow(cat) }
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 14)
            }

            footer
        }
        .onAppear(perform: loadFields)
    }

    private var header: some View {
        HStack(spacing: 13) {
            Image(systemName: "target")
                .font(.system(size: 18, weight: .medium)).foregroundStyle(Palette.tileInk)
                .frame(width: 42, height: 42)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text("Set budget")
                .font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.ink)
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 14)
    }

    private func categoryRow(_ cat: ExpenseCategory) -> some View {
        HStack(spacing: 12) {
            Image(systemName: cat.symbolName)
                .font(.system(size: 16)).foregroundStyle(Palette.tileInk)
                .frame(width: 38, height: 38)
                .background(Color(hex: cat.colorHex),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(cat.name).font(.system(size: 16, weight: .medium)).foregroundStyle(Palette.ink)
            Spacer()
            fieldCard(text: bindingFor(cat)).frame(width: 140)
        }
    }

    private func fieldCard(text: Binding<String>) -> some View {
        HStack(spacing: 6) {
            Text(currencySymbol(currencyCode))
                .font(.system(size: 15)).foregroundStyle(Palette.ink40)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, 12).padding(.vertical, 11)
        .background(Palette.field, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.ink12, lineWidth: 1))
    }

    private var footer: some View {
        VStack(spacing: 12) {
            if mode == .category {
                HStack {
                    Text("Total monthly budget")
                        .font(.system(size: 15)).foregroundStyle(Palette.ink60)
                    Spacer()
                    Text(formattedMoney(sumBudgetStrings(Array(catFields.values)),
                                        currencyCode: currencyCode))
                        .font(.system(size: 18, weight: .bold)).foregroundStyle(Palette.ink)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            Button { save(); close() } label: {
                Text("Save budget")
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.tileInk)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            Button("Cancel") { close() }
                .font(.system(size: 16, weight: .medium)).foregroundStyle(Palette.ink60)
        }
        .padding(.horizontal, 20).padding(.top, 6).padding(.bottom, 14)
    }

    // amountField removed (replaced by fieldCard). bindingFor / loadFields / save unchanged:
    private func bindingFor(_ cat: ExpenseCategory) -> Binding<String> {
        Binding(get: { catFields[cat.persistentModelID] ?? "" },
                set: { catFields[cat.persistentModelID] = $0 })
    }
    private func loadFields() {
        generalField = formatBudgetAmount(parseBudgetAmount(generalBudget))
        for cat in categories { catFields[cat.persistentModelID] = formatBudgetAmount(cat.budget) }
    }
    private func save() {
        let fields = categories.map { ($0, catFields[$0.persistentModelID] ?? "") }
        generalBudget = applyBudgetSave(mode: mode, generalField: generalField,
                                        categoryFields: fields)
        loadFields()
    }
}

#if DEBUG
#Preview { BudgetView().modelContainer(SampleData.previewContainer()) }
#endif
```
Notes: `Save budget` now persists **and** closes (handoff has Save + Cancel, no separate
Done); the total card shows only in by-category mode (matches the screenshot). All persist
logic (`applyBudgetSave`, `formatBudgetAmount`, `sumBudgetStrings`) is unchanged.

## 5. SettingsView (done)

Currency + Budget rows are `Button` + `.blurPopup(..., tall: true)`; Manage categories
stays a `NavigationLink`. No further change.

## Testing

- **Unit:** `currencyFlag` cases (the only new logic).
- **Views:** `#Preview` + simulator against `currency.jpg` / `budget.jpg`, light + dark:
  - Currency: flag tiles, code + name, **selected row filled accent** + checkmark, subtitle,
    bottom **Done**; tapping selects live; list scrolls.
  - Set budget: icon header, segmented + per-mode subtitle, colored category tiles with
    **$-prefixed field cards**, **Total card**, **Save** (persists + closes), **Cancel**;
    keyboard raises the card; reopen shows saved values.
  - **Regression:** B1 dialogs still hug; tap/drag/Done dismiss everywhere.

## Scope

The `currencyFlag` helper + test, and full-fidelity rebuilds of `CurrencyView` /
`BudgetView`. `BlurPopup` `tall` + `SettingsView` wiring already landed. One PR on
`feature/dialog-popups-2`. B2b (categories cluster) is separate.
