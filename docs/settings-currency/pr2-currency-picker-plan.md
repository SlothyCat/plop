# PR2 — Currency Picker UI Implementation Plan

> Execute inline (no worktrees). Steps use `- [ ]`. Branch off `main` after PR1 merges.

**Goal:** Make the display currency user-selectable: a Currency picker in Settings backed by `@AppStorage`, with every money view reading it so changing currency re-renders Home, Insights, and Entry (symbol + decimals).

**Architecture:** `CurrencyView` and all money views read `@AppStorage(currencyCodeKey)` (default `deviceCurrencyCode()`) and pass it to the PR1 `formattedMoney`/`currencySymbol`/`currencyFractionDigits`. SwiftUI re-renders on change → reactive. No new logic/tests (covered in PR1); verified in the simulator.

**Tech Stack:** SwiftUI, `@AppStorage`, PR1 Currency helpers. iOS 18.

---

## Conventions
- Branch `feature/currency-picker` off updated `main`. No worktrees.
- Commits present-tense + `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

## File Structure
- Create `plop/plop/Views/Settings/CurrencyView.swift`
- Modify `plop/plop/Views/Settings/SettingsView.swift` (+ Currency row)
- Modify money views: `TxRow`, `DayCard`, `NetTotalHeader`, `SpendLegend`, `InsightsView`, `EntryView`

---

### Task 1: CurrencyView + Settings row

**Files:** create `CurrencyView.swift`; modify `SettingsView.swift`.

- [ ] **Step 1: Branch**
```bash
git checkout main && git pull --ff-only && git checkout -b feature/currency-picker
```

- [ ] **Step 2: `CurrencyView.swift`**
```swift
import SwiftUI

/// Picks the app-wide display currency (no conversion). Writing @AppStorage re-renders
/// every money view that reads it.
struct CurrencyView: View {
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()

    var body: some View {
        List {
            Section {
                ForEach(currencyChoices, id: \.self) { code in
                    Button { currencyCode = code } label: { row(code) }
                        .buttonStyle(.plain)
                }
            } footer: {
                Text("Amounts aren't converted — only the symbol and decimal places change.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.bg)
        .navigationTitle("Currency")
    }

    private func row(_ code: String) -> some View {
        HStack(spacing: 12) {
            Text(code)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: 44, alignment: .leading)
            Text(currencySymbol(code)).foregroundStyle(Palette.ink40)
            Text(currencyDisplayName(code)).foregroundStyle(Palette.ink40).lineLimit(1)
            Spacer()
            if code == currencyCode {
                Image(systemName: "checkmark").foregroundStyle(Palette.accent)
            }
        }
    }
}

#if DEBUG
#Preview { NavigationStack { CurrencyView() } }
#endif
```

- [ ] **Step 3: Add the Currency row to `SettingsView`**

Add `@AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()` to
`SettingsView`, and a second row in the Preferences section:
```swift
                Section("Preferences") {
                    NavigationLink {
                        ManageCategoriesView()
                    } label: {
                        Label("Manage categories", systemImage: "tag.fill")
                    }
                    NavigationLink {
                        CurrencyView()
                    } label: {
                        HStack {
                            Label("Currency", systemImage: "dollarsign.circle.fill")
                            Spacer()
                            Text(currencyCode).foregroundStyle(.secondary)
                        }
                    }
                }
```

- [ ] **Step 4: Build, then commit**
```bash
xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'
```
Expected: `** BUILD SUCCEEDED **`.
```bash
git add plop/plop/Views/Settings/CurrencyView.swift plop/plop/Views/Settings/SettingsView.swift
git commit -m "Add Currency picker and Settings row"
```

---

### Task 2: Money views read @AppStorage

Each view gains `@AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()`
and passes `currencyCode` where it currently passes `deviceCurrencyCode()`.

- [ ] **Step 1: `TxRow.swift`** — add the `@AppStorage` property (next to no existing state; put it at the top of the struct), then change `currencyCode: deviceCurrencyCode()` → `currencyCode: currencyCode`.
```swift
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
```

- [ ] **Step 2: `DayCard.swift`** — same: add the property, change `deviceCurrencyCode()` → `currencyCode` in the `formattedMoney(group.subtotal, …)` call.

- [ ] **Step 3: `NetTotalHeader.swift`** — add the property, change the `formattedMoney(net, …)` call to `currencyCode`.

- [ ] **Step 4: `SpendLegend.swift`** — add the property, change `formattedMoney(item.amount, …)` to `currencyCode`.

- [ ] **Step 5: `InsightsView.swift`** — add the property, change `formattedMoney(total, …)` to `currencyCode`.

- [ ] **Step 6: `EntryView.swift`** — add the property; use it for the symbol and keypad:
  - Change `Text(currencySymbol(deviceCurrencyCode()))` → `Text(currencySymbol(currencyCode))`.
  - Replace `prefillIfEditing()` so the keypad's fraction digits use `currencyCode` for both add and edit:
```swift
    private func prefillIfEditing() {
        guard let tx = editing else {
            input = AmountInput(maxFractionDigits: currencyFractionDigits(currencyCode: currencyCode))
            return
        }
        mode = tx.type
        note = tx.note
        date = tx.date
        recurrence = tx.recurrence
        selected = tx.category
        input = AmountInput(value: tx.amount,
                            maxFractionDigits: currencyFractionDigits(currencyCode: currencyCode))
    }
```
  (The `@State input` default stays as-is; `.onAppear` already calls `prefillIfEditing`, which now sets the right fraction digits from the chosen currency.)

- [ ] **Step 7: Build + full test + lint**
```bash
xcrun simctl shutdown all 2>/dev/null; sleep 2
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO
swiftlint lint
```
Expected: 58 tests pass; no lint errors.

- [ ] **Step 8: Commit**
```bash
git add plop/plop/Views/Home/TxRow.swift plop/plop/Views/Home/DayCard.swift \
        plop/plop/Views/Home/NetTotalHeader.swift plop/plop/Views/Insights/SpendLegend.swift \
        plop/plop/Views/Insights/InsightsView.swift plop/plop/Views/Entry/EntryView.swift
git commit -m "Read selected currency from @AppStorage across money views"
```

---

### Task 3: Verify, PR

- [ ] **Step 1: Simulator check**

Run the app: Settings → Currency → pick **JPY** → Home/Insights net totals + rows show ¥ with
no decimals; open Entry → ¥ symbol, keypad blocks the decimal point. Switch back to USD →
everything updates live. Screenshot the Currency picker.

- [ ] **Step 2: Push + PR**
```bash
git push -u origin feature/currency-picker
```
Open PR `feature/currency-picker` → `main` via GitHub web; confirm CI green.

---

## Self-review notes
- **Spec coverage:** picker + Settings row (T1); reactive `@AppStorage` reads across all money
  views incl. Entry symbol + keypad decimals (T2). Completes the currency feature.
- **Reactivity:** every money view reads `@AppStorage(currencyCodeKey)`, so a change in the
  picker re-renders them immediately.
- **No new unit tests:** formatting logic was tested in PR1; this PR is wiring/UI (sim-verified).
- **Symbols:** Foundation locale-aware (per decision) — `currencySymbol(code)` / `NumberFormatter`.
