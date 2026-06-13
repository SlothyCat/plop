# Home + Entry — Design

Status: Approved (brainstorm complete) · Date: 2026-06-13

Companion to `requirements.md`. Covers architecture, the SwiftData model, the pure
logic layer, the write path, the two screens, and the 5-PR implementation slicing.

## Architecture

**Logical decoupling, idiomatic SwiftData.** There is no network/trust boundary in a
local on-device app, so we don't erect a client/server-style wall. The decoupling that
matters — **business logic vs. rendering** — is achieved with a pure `Logic/` layer.
Views use `@Query` (a declarative data binding) and `ModelContext` directly, as Apple
intends. All writes funnel through a small `TransactionActions` helper so mutation has
a single, testable locus — short of a full repository abstraction (rejected as overkill
that fights `@Query`).

### Module layout

```
plop/
  Models/
    Transaction.swift
    Category.swift
    TransactionType.swift        (enum)
    RecurrenceInterval.swift     (enum — stored but inert this feature)
  Logic/                         (pure; no SwiftUI / no ModelContext)
    PeriodFilter.swift
    TransactionAggregation.swift (net total, group-by-day, subtotals)
    Formatting.swift             (money + relative day labels)
  Data/
    TransactionActions.swift     (single locus for add/update/delete)
    TransactionDraft.swift       (plain value type carrying Entry's form fields)
  Seed/
    DefaultData.swift            (once-ever category seeding)
  Views/
    Shell/  RootView, TabBar, InsightsStub, SettingsStub
    Home/   HomeView, NetTotalHeader, FilterMenu, DayCard, TxRow
    Entry/  EntryView, Keypad, CategoryPickerSheet, WhenSheet, RecurringSheet
  plopApp.swift                  (ModelContainer registration)
```

## Data model

```swift
enum TransactionType: String, Codable, CaseIterable { case expense, income }

enum RecurrenceInterval: String, Codable, CaseIterable {
    case none, daily, weekly, monthly, yearly   // stored now; engine = Feature 2
}

@Model
final class Category {
    var name: String
    var symbolName: String        // SF Symbol, e.g. "fork.knife"
    var colorHex: String          // e.g. "#FFEBCC"
    var budget: Decimal?          // nil now; Budget feature fills it (forward-compat)

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction] = []

    init(name: String, symbolName: String, colorHex: String, budget: Decimal? = nil) {
        self.name = name; self.symbolName = symbolName
        self.colorHex = colorHex; self.budget = budget
    }
}

@Model
final class Transaction {
    var amount: Decimal           // always positive; sign derived from type
    var type: TransactionType
    var date: Date                // spend date+time
    var note: String
    var recurrence: RecurrenceInterval
    var createdAt: Date           // stable sort tiebreaker
    var category: Category?

    init(amount: Decimal, type: TransactionType, date: Date, note: String = "",
         recurrence: RecurrenceInterval = .none, category: Category? = nil) {
        self.amount = amount; self.type = type; self.date = date; self.note = note
        self.recurrence = recurrence; self.createdAt = .now; self.category = category
    }
}
```

## Pure logic layer (unit-tested)

```swift
enum PeriodFilter { case week, month, year
    func range(containing date: Date, calendar: Calendar) -> ClosedRange<Date>
}

func signedAmount(_ tx: Transaction) -> Decimal          // income +, expense −
func netTotal(of txs: [Transaction]) -> Decimal          // empty → 0

struct DayGroup { let date: Date; let transactions: [Transaction]; let subtotal: Decimal }
func groupByDay(_ txs: [Transaction], calendar: Calendar) -> [DayGroup]  // newest day first

func formattedMoney(_ amount: Decimal, signed: Bool) -> String           // device-locale currency
func dayLabel(for date: Date, relativeTo today: Date, calendar: Calendar) -> String
    // "TODAY" / "YESTERDAY" / "FRI, 29 MAY"
```

Pure functions (no SwiftUI, no `ModelContext`) → testable in isolation and reused by
both Home rendering and the PR3 fetch/filter wiring.

## Write path

```swift
struct TransactionDraft {           // built by Entry from its form state
    var amount: Decimal; var type: TransactionType; var date: Date
    var note: String; var recurrence: RecurrenceInterval; var category: Category?
}

enum TransactionActions {
    static func add(_ draft: TransactionDraft, in context: ModelContext)
    static func update(_ tx: Transaction, with draft: TransactionDraft)   // mutate in place
    static func delete(_ tx: Transaction, in context: ModelContext)
}
```

Reads stay as `@Query` in views; writes always go through here.

## Home screen

Composition (top → bottom): top bar with right-aligned **Filter** only · `NetTotalHeader`
(label + period pill + large signed amount) · day-grouped list of `DayCard`s (date label +
day subtotal above a rounded card of `TxRow`s) · empty state. `TxRow`: category color tile +
SF Symbol · name (+ small repeat icon if `recurrence != .none`) · note-or-time secondary ·
signed amount (income green `#1F8A5B`, expense charcoal). Tap a row → Entry in edit mode.

Data flow:
```
@Query (all transactions)
   → filter to PeriodFilter.range(period)   (in-memory, pure logic)
   → groupByDay → DayCard list
   → netTotal  → NetTotalHeader
```
Period is `@State` (default Month). **Fetch-all + filter in-memory** is chosen on purpose:
the dataset is tiny (<2k rows/yr) and it keeps filtering in the testable pure layer rather
than locked inside a `@Query` predicate.

## Entry screen

Full-screen cover. Opened to **add** (center "+") or **edit** (row tap, prefilled + Delete).
Composition: header (Close · Expense/Income segment · Recurring button · Delete in edit mode)
· large amount display (device-locale symbol) + custom keypad (1–9, `.`, 0, backspace,
confirm ✓; save disabled until amount > 0) · note pill/inline field · "When" sheet (native
date+time pickers) · category picker sheet (seeded categories; "New category" hidden this
feature) · recurring sheet (stores `recurrence`, shows "Repeats X" chip — inert).

Data flow:
```
Add:    form → TransactionDraft → TransactionActions.add(draft, context)        → dismiss
Edit:   prefill from tx → TransactionDraft → TransactionActions.update(tx, draft) → dismiss
Delete: TransactionActions.delete(tx, context)                                    → dismiss
```
Home's `@Query` auto-updates after any write.

## App shell / routing skeleton

`RootView` hosts a custom tab bar (the design's raised center "+"): **Home** wired, **Insights**
and **Settings** as stub placeholder views. SwiftUI tabs are state-driven, so later features
replace a stub with zero re-routing. Entry presents as a `.fullScreenCover` independent of the
tab bar. The "+" action and row-tap-to-edit are wired when Entry lands (PRs 4–5).

## Edge-case handling

- **Seeding once-ever:** persisted flag (`AppMetadata`/`UserDefaults`), not table-empty check.
- **Deleted category:** nullify → `category == nil` → "Uncategorized" + neutral tile.
- **Keypad:** single decimal; fraction digits clamped to currency precision; digit-count guard.
- **Dates:** absolute `Date`; periods + grouping via locale `Calendar` (week-start, timezone).
- **Sort:** day desc; within day time desc, then `createdAt` desc.

## Testing strategy

- **Unit (XCTest):** `signedAmount`, `netTotal`, `PeriodFilter.range`, `groupByDay`,
  formatting; `TransactionActions` and seeding against an **in-memory `ModelContainer`**.
- **`#Preview` + simulator:** Home (render/filter/empty), Entry (keypad/sheets/save),
  light + dark. Previews use `.modelContainer(inMemory: true)` with sample data.
- No forced SwiftUI view tests (per CLAUDE.md).

## Implementation slicing (5 sequential PRs)

| PR | Branch | Delivers | Tested by |
|---|---|---|---|
| 1 | `feature/expense-model` | Models + enums, Logic layer, `TransactionActions`, once-ever seeding, container registration | Unit |
| 2 | `feature/home-ui` | App shell (tab bar + Home + Insights/Settings stubs), Home UI from sample data | `#Preview` + sim |
| 3 | `feature/home-data` | Wire Home to `@Query`; period filter → real fetch → pure logic → render | Unit + sim |
| 4 | `feature/entry-ui` | Entry UI (keypad, segment, sheets); "+" presents Entry; local state | `#Preview` + sim |
| 5 | `feature/entry-data` | Entry save/update/delete via `TransactionActions`; row-tap → edit; loop closes | Unit + sim |

Dependency notes: the "+" exists in PR2 but its present-Entry action is wired in PR4;
row-tap → edit is wired in PR5. Every PR keeps `main` building and is independently reviewable.

## References

- `design_handoff_plop/README.md` — full spec (tokens, screens, behavior).
- `design_handoff_plop/app/{home,entry,store,theme}.jsx` — prototype source.
