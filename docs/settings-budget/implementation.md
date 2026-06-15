# Set Budget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Settings "Set budget" screen (Total / By category) that persists a monthly budget for Insights to chart against later.

**Architecture:** Pure budget helpers in a new `Logic/Budget.swift` (unit-tested); a pushed `BudgetView` mirroring `CurrencyView`; a Settings row showing the active total. Mode + general amount persist in `@AppStorage`; per-category amounts persist on the existing `ExpenseCategory.budget` SwiftData field. The category-mode total is always derived, never stored.

**Tech Stack:** SwiftUI, SwiftData, `@AppStorage`, XCTest. iOS 18.

Single PR on branch `feature/set-budget` (already created; spec already committed there).

---

## File structure

- **Create** `plop/plop/Logic/Budget.swift` — keys, `BudgetMode`, and pure helpers: `parseBudgetAmount`, `formatBudgetAmount`, `categoryBudgetSum`, `sumBudgetStrings`, `activeBudgetTotal`.
- **Create** `plop/plopTests/BudgetTests.swift` — unit tests for every helper.
- **Create** `plop/plop/Views/Settings/BudgetView.swift` — pushed Total / By category screen.
- **Modify** `plop/plop/Views/Settings/SettingsView.swift` — add the Set budget `NavigationLink` row with active-total summary.

> Note on helpers vs. design: the design names `parseBudgetAmount` / `formatBudgetAmount` / `categoryBudgetSum`. This plan adds two thin derived-total helpers — `sumBudgetStrings` (live footer over in-progress text fields) and `activeBudgetTotal` (Settings summary over persisted values). Both are "derived total" refinements consistent with the design's "category total is always derived" decision, factored out so they're unit-testable rather than inlined in views.

### Conventions to follow (verified against the codebase)

- Test file shape: `import XCTest` + `@testable import plop`, `final class XTests: XCTestCase`. See `plop/plopTests/CurrencyTests.swift`.
- Palette tokens exist: `Palette.bg`, `.card`, `.field`, `.ink`, `.ink60`, `.ink40`, `.ink12`, `.accent`, `.tileInk` (`plop/plop/Theme/Palette.swift`).
- Money formatting: `formattedMoney(_ amount: Decimal, signed: Bool = false, currencyCode: String)` (`plop/plop/Logic/Formatting.swift:5`).
- Currency reactivity: `@AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()`; symbol via `currencySymbol(code)`.
- View+model pattern: `@Query(sort: \ExpenseCategory.name) private var categories` + `@Environment(\.modelContext)` (see `ManageCategoriesView.swift`).
- Previews use `.modelContainer(SampleData.previewContainer())` when SwiftData is involved.

### Test command (this repo)

```bash
# Whole suite:
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO

# Just the new class (faster while iterating):
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests/BudgetTests -parallel-testing-enabled NO
```

> SourceKit may show false "Cannot find X in scope" for new same-module symbols/files. **xcodebuild is the source of truth** — trust `** TEST SUCCEEDED **`, not the editor squiggles. (See `memory/xcode-build-sim-gotchas.md`.)

---

## Task 1: Budget Logic + tests

**Files:**
- Create: `plop/plop/Logic/Budget.swift`
- Create: `plop/plopTests/BudgetTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `plop/plopTests/BudgetTests.swift`:

```swift
import XCTest
import SwiftData
@testable import plop

final class BudgetTests: XCTestCase {

    // MARK: parseBudgetAmount

    func test_parse_empty_isZero() {
        XCTAssertEqual(parseBudgetAmount(""), 0)
    }

    func test_parse_decimal() {
        XCTAssertEqual(parseBudgetAmount("12.50"), Decimal(string: "12.5"))
    }

    func test_parse_stripsSymbolsAndLetters() {
        XCTAssertEqual(parseBudgetAmount("$1,200"), 1200)
        XCTAssertEqual(parseBudgetAmount("abc"), 0)
    }

    // MARK: formatBudgetAmount

    func test_format_zero_isEmpty() {
        XCTAssertEqual(formatBudgetAmount(0), "")
    }

    func test_format_roundTripsNonZero() {
        let value = Decimal(string: "300")!
        XCTAssertEqual(parseBudgetAmount(formatBudgetAmount(value)), value)
    }

    // MARK: BudgetMode

    func test_mode_rawValues() {
        XCTAssertEqual(BudgetMode.general.rawValue, "general")
        XCTAssertEqual(BudgetMode.category.rawValue, "category")
    }

    // MARK: categoryBudgetSum

    func test_categorySum_sumsAndIgnoresZero() throws {
        let cats = [
            ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC", budget: 300),
            ExpenseCategory(name: "Subs", symbolName: "tv", colorHex: "#FFF9D2", budget: 120),
            ExpenseCategory(name: "None", symbolName: "tag", colorHex: "#BFDDF0", budget: 0)
        ]
        XCTAssertEqual(categoryBudgetSum(cats), 420)
    }

    func test_categorySum_emptyIsZero() {
        XCTAssertEqual(categoryBudgetSum([]), 0)
    }

    // MARK: sumBudgetStrings

    func test_sumStrings_parsesEachAndSums() {
        XCTAssertEqual(sumBudgetStrings(["300", "", "120.50", "x"]), Decimal(string: "420.5"))
    }

    // MARK: activeBudgetTotal

    func test_activeTotal_generalUsesString() {
        XCTAssertEqual(activeBudgetTotal(mode: .general, generalBudget: "500", categories: []), 500)
    }

    func test_activeTotal_categoryUsesModelSum() {
        let cats = [
            ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC", budget: 300),
            ExpenseCategory(name: "Subs", symbolName: "tv", colorHex: "#FFF9D2", budget: 120)
        ]
        XCTAssertEqual(activeBudgetTotal(mode: .category, generalBudget: "999", categories: cats), 420)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests/BudgetTests -parallel-testing-enabled NO
```
Expected: BUILD FAILS / tests don't compile — `parseBudgetAmount`, `BudgetMode`, etc. are undefined.

- [ ] **Step 3: Write the implementation**

Create `plop/plop/Logic/Budget.swift`:

```swift
import Foundation

/// Persistence keys for the budget feature (see docs/settings-budget/design.md).
/// Per-category budgets live on `ExpenseCategory.budget`; only the mode and the
/// general-mode amount are stored here in @AppStorage.
let budgetModeKey = "budgetMode"
let generalBudgetKey = "generalBudget"

/// Which budgeting style is active. Raw values match the persisted contract.
enum BudgetMode: String {
    case general    // one monthly total; per-category budgets ignored
    case category   // per-category budgets, summed into the total
}

/// Parses user text into a budget amount. Keeps digits and a decimal point,
/// drops currency symbols, separators, and letters. Empty / unparseable -> 0
/// (meaning "no budget").
func parseBudgetAmount(_ text: String) -> Decimal {
    let filtered = text.filter { $0.isNumber || $0 == "." }
    return Decimal(string: filtered) ?? 0
}

/// Renders a stored amount back into an editable field (plain number, no symbol).
/// 0 -> "" so an unset budget shows the placeholder rather than "0".
func formatBudgetAmount(_ value: Decimal) -> String {
    value == 0 ? "" : "\(value)"
}

/// Sum of the persisted per-category budgets — the derived category-mode total.
func categoryBudgetSum(_ categories: [ExpenseCategory]) -> Decimal {
    categories.reduce(0) { $0 + $1.budget }
}

/// Sum of in-progress text-field values (for the live footer before saving).
func sumBudgetStrings(_ values: [String]) -> Decimal {
    values.reduce(0) { $0 + parseBudgetAmount($1) }
}

/// The active budget total: the general amount, or the derived category sum.
func activeBudgetTotal(mode: BudgetMode, generalBudget: String,
                       categories: [ExpenseCategory]) -> Decimal {
    switch mode {
    case .general:  return parseBudgetAmount(generalBudget)
    case .category: return categoryBudgetSum(categories)
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the Step 2 command. Expected: `** TEST SUCCEEDED **`, all `BudgetTests` green.

- [ ] **Step 5: Commit**

```bash
git add plop/plop/Logic/Budget.swift plop/plopTests/BudgetTests.swift
git commit -m "Add budget Logic helpers and tests

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: BudgetView (pushed Total / By category screen)

**Files:**
- Create: `plop/plop/Views/Settings/BudgetView.swift`

No unit tests (SwiftUI view — validated via `#Preview` + simulator, per CLAUDE.md). Verification is "the target builds."

- [ ] **Step 1: Write the view**

Create `plop/plop/Views/Settings/BudgetView.swift`:

```swift
import SwiftUI
import SwiftData

/// Sets the app's monthly budget. Two modes: a single general total, or
/// per-category amounts summed into a total. Mode + general amount persist in
/// @AppStorage; per-category amounts persist on ExpenseCategory.budget.
struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @AppStorage(budgetModeKey) private var modeRaw = BudgetMode.category.rawValue
    @AppStorage(generalBudgetKey) private var generalBudget = ""

    @State private var generalField = ""
    @State private var catFields: [PersistentIdentifier: String] = [:]

    private var mode: BudgetMode { BudgetMode(rawValue: modeRaw) ?? .category }

    var body: some View {
        List {
            Section {
                Picker("Budget mode", selection: $modeRaw) {
                    Text("Total").tag(BudgetMode.general.rawValue)
                    Text("By category").tag(BudgetMode.category.rawValue)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            if mode == .general {
                Section {
                    amountField(text: $generalField)
                } footer: {
                    Text("One monthly budget. Categories are ignored in this mode.")
                }
            } else {
                Section {
                    ForEach(categories) { cat in
                        HStack(spacing: 12) {
                            Image(systemName: cat.symbolName).foregroundStyle(Palette.ink60)
                                .frame(width: 24)
                            Text(cat.name).foregroundStyle(Palette.ink)
                            Spacer()
                            amountField(text: bindingFor(cat))
                                .frame(maxWidth: 120)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                } footer: {
                    HStack {
                        Text("Total monthly budget")
                        Spacer()
                        Text(formattedMoney(sumBudgetStrings(Array(catFields.values)),
                                            currencyCode: currencyCode))
                            .foregroundStyle(Palette.ink)
                    }
                    .font(.system(size: 14, weight: .semibold))
                }
            }

            Section {
                Button("Save budget") { save() }
                    .frame(maxWidth: .infinity)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.bg)
        .navigationTitle("Set budget")
        .onAppear(perform: loadFields)
    }

    private func amountField(text: Binding<String>) -> some View {
        HStack(spacing: 4) {
            Text(currencySymbol(currencyCode)).foregroundStyle(Palette.ink40)
            TextField("No budget", text: text)
                .keyboardType(.decimalPad)
                .foregroundStyle(Palette.ink)
        }
    }

    private func bindingFor(_ cat: ExpenseCategory) -> Binding<String> {
        Binding(
            get: { catFields[cat.persistentModelID] ?? "" },
            set: { catFields[cat.persistentModelID] = $0 }
        )
    }

    private func loadFields() {
        generalField = formatBudgetAmount(parseBudgetAmount(generalBudget))
        for cat in categories {
            catFields[cat.persistentModelID] = formatBudgetAmount(cat.budget)
        }
    }

    private func save() {
        if mode == .general {
            generalBudget = "\(parseBudgetAmount(generalField))"
        } else {
            for cat in categories {
                cat.budget = parseBudgetAmount(catFields[cat.persistentModelID] ?? "")
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack { BudgetView() }
        .modelContainer(SampleData.previewContainer())
}
#endif
```

- [ ] **Step 2: Verify the target builds**

Run:
```bash
xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'
```
Expected: `** BUILD SUCCEEDED **`. (Ignore any SourceKit "cannot find in scope" editor warnings — the build is the source of truth.)

- [ ] **Step 3: Commit**

```bash
git add plop/plop/Views/Settings/BudgetView.swift
git commit -m "Add Set budget view with Total and By category modes

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Settings row

**Files:**
- Modify: `plop/plop/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Add the budget @AppStorage reads + the row**

In `SettingsView.swift`, add below the existing `@AppStorage(currencyCodeKey)` line:

```swift
    @AppStorage(budgetModeKey) private var budgetModeRaw = BudgetMode.category.rawValue
    @AppStorage(generalBudgetKey) private var generalBudget = ""
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
```

Add the `Set budget` row as the first row in the `Section("Preferences")`, above `Manage categories`:

```swift
                    NavigationLink {
                        BudgetView()
                    } label: {
                        HStack {
                            Label("Set budget", systemImage: "chart.pie.fill")
                            Spacer()
                            Text(budgetSummary).foregroundStyle(.secondary)
                        }
                    }
```

Add this computed property to the `SettingsView` struct (e.g. after `body`):

```swift
    private var budgetSummary: String {
        let mode = BudgetMode(rawValue: budgetModeRaw) ?? .category
        let total = activeBudgetTotal(mode: mode, generalBudget: generalBudget,
                                      categories: categories)
        return total == 0 ? "None" : formattedMoney(total, currencyCode: currencyCode)
    }
```

(`SettingsView.swift` already has `import SwiftData`, so `@Query` compiles.)

- [ ] **Step 2: Verify the target builds**

Run:
```bash
xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add plop/plop/Views/Settings/SettingsView.swift
git commit -m "Add Set budget row to Settings with active-total summary

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Verify and open PR

**Files:** none (verification + PR).

- [ ] **Step 1: Run the full test suite**

```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:plopTests -parallel-testing-enabled NO
```
Expected: `** TEST SUCCEEDED **` — all prior tests plus the new `BudgetTests`.

- [ ] **Step 2: Lint**

```bash
swiftlint lint
```
Expected: no new violations from the added files. (A pre-existing baseline of unrelated violations is acceptable; do not introduce new ones.)

- [ ] **Step 3: Simulator smoke check (manual)**

Build/run the app. Settings → Set budget:
- Switch to **Total**, enter an amount, Save, leave and return → amount persists; Settings row shows it.
- Switch to **By category**, enter amounts → footer "Total monthly budget" live-sums; Save, return → amounts persist; Settings row shows the category sum.
- Change the Currency picker → symbol/decimals update here too.

- [ ] **Step 4: Push and open the PR**

```bash
git push -u origin feature/set-budget
```

`gh` is not installed — open the PR via the printed GitHub web URL. Use the project PR-description format:

```markdown
## Summary
Add a Settings "Set budget" screen (Total / By category) with hybrid persistence
(@AppStorage mode + general amount; per-category budgets on ExpenseCategory).
Sets up Insights budget mode (separate follow-up). Amounts aren't converted.

## Testing
All unit tests pass (10 new in BudgetTests); SwiftLint clean.
```

---

## Self-review notes

- **Spec coverage:** modes (Task 2 picker), hybrid persistence (Tasks 1–3), derived category total (`categoryBudgetSum`/`activeBudgetTotal`), pushed view (Task 2), Settings summary row (Task 3), currency reactivity (Task 2/3 read `currencyCodeKey`), unit-tested helpers (Task 1). Deferred items (Insights mode, year ×12) are intentionally absent.
- **Type consistency:** `BudgetMode` raw values `general`/`category` used identically across Budget.swift, BudgetView, SettingsView, and tests; `parseBudgetAmount`/`formatBudgetAmount`/`categoryBudgetSum`/`sumBudgetStrings`/`activeBudgetTotal` signatures match every call site.
- **No placeholders:** every code step is complete and runnable.
