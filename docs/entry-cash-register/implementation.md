# Entry "Cash Register" Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reskin the Entry screen to the "cash register" handoff — a blue LCD `RegisterDisplay` card, a note/backspace row, tactile pills/keypad, and a "Plop CASHIER" footer — per `docs/entry-cash-register/design.md`. Presentation only; behaviour unchanged.

**Architecture:** Extract a `RegisterDisplay` view, add dynamic LCD color tokens to `Palette`, and reflow/​restyle `EntryView` + `Keypad`. `AmountInput`, pickers, validation, haptics, and save/delete are reused verbatim.

**Tech Stack:** SwiftUI, iOS 18. No new fonts, no logic, no new tests.

Single PR on `feature/entry-cash-register` (design spec committed there).

---

## Context for the implementer

- **Read `design_handoff_plop/screenshots/add_entry_cashier_register.jpg` before building and again
  when verifying** — it's the visual source of truth (project rule). Match layout/spacing; the
  numeric values below are a faithful starting point, nudge them to match the screenshot.
- **Approved divergence:** the amount uses SF `.monospacedDigit()` bold (NOT the DSEG7 segmented
  font). Don't add any font asset.
- Behaviour is reused: `AmountInput` (`input.display()`, `input.press`, `input.backspace`,
  `input.canSave`), the pickers, `confirm()/performSave()`, the validation flags
  (`amountInvalid`, `categoryInvalid`, `validationCaption`), and haptics stay exactly as they are.
- `currencySymbol(currencyCode)` gives the `$`; `dateLabel`/`timeLabel` already exist in EntryView.

### Build / lint commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:"

swiftlint lint 2>&1 | tail -1
```

> SourceKit "Cannot find X" diagnostics are FALSE positives — xcodebuild is the source of truth.
> Lines ≤ 120. No `// swiftlint:disable`. Keep the baseline (19 violations, 0 serious).

---

## File structure

- **Modify** `plop/plop/Theme/Palette.swift` — 5 LCD tokens.
- **Create** `plop/plop/Views/Entry/RegisterDisplay.swift` — the LCD card.
- **Modify** `plop/plop/Views/Entry/EntryView.swift` — reflow + note row + footer + pill restyle.
- **Modify** `plop/plop/Views/Entry/Keypad.swift` — tactile key restyle.

---

## Task 1: Palette LCD tokens + `RegisterDisplay`

**Files:** modify `Palette.swift`; create `RegisterDisplay.swift`.

- [ ] **Step 1: Add the LCD tokens.** In `Palette.swift`, after the `danger` line, add:
```swift

    // Cash-register LCD (Entry). Light values from the handoff; dark is a lit-display variant.
    static let lcdGlassTop = Color.dynamic(Color(hex: "#C6DEF1"), Color(hex: "#1B3A52"))
    static let lcdGlassBottom = Color.dynamic(Color(hex: "#C7DCEE"), Color(hex: "#14314A"))
    static let lcdInk = Color.dynamic(Color(hex: "#173A57"), Color(hex: "#BFE0F5"))
    static let lcdCaseTop = Color.dynamic(Color(hex: "#C6CED5"), Color(hex: "#2A3A47"))
    static let lcdCaseBottom = Color.dynamic(Color(hex: "#A7B2BB"), Color(hex: "#1C2833"))
```

- [ ] **Step 2: Create `plop/plop/Views/Entry/RegisterDisplay.swift`:**
```swift
import SwiftUI

/// The cash-register LCD panel on the Entry screen: a glass display in a beveled case showing
/// the transaction status (DEBIT·OUT / CREDIT·IN), category, amount, and date. Presentational.
struct RegisterDisplay: View {
    let type: TransactionType
    let currencySymbol: String
    let amount: String
    let category: ExpenseCategory?
    let dateText: String
    var amountInvalid: Bool = false

    private var statusText: String { type == .income ? "CREDIT · IN" : "DEBIT · OUT" }
    private var dotColor: Color { type == .income ? Palette.incomeGreen : Palette.ink }
    private var categoryText: String { category?.name.uppercased() ?? "NO CATEGORY" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 7) {
                    Circle().fill(dotColor).frame(width: 7, height: 7)
                    Text(statusText)
                        .font(.system(size: 12, weight: .bold)).tracking(1)
                }
                Spacer(minLength: 8)
                Text(categoryText)
                    .font(.system(size: 12, weight: .semibold)).tracking(1)
                    .lineLimit(1)
            }
            .foregroundStyle(Palette.lcdInk.opacity(0.75))

            Spacer(minLength: 12)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Spacer(minLength: 0)
                Text(currencySymbol)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Palette.lcdInk.opacity(0.7))
                Text(amount)
                    .font(.system(size: 64, weight: .bold)).monospacedDigit()
                    .foregroundStyle(amountInvalid ? Palette.danger : Palette.lcdInk)
            }

            Spacer(minLength: 12)

            Text(dateText.uppercased())
                .font(.system(size: 11, weight: .semibold)).tracking(1)
                .foregroundStyle(Palette.lcdInk.opacity(0.6))
        }
        .padding(20)
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Palette.lcdGlassTop, Palette.lcdGlassBottom],
                           startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
        .padding(8)
        .background(
            LinearGradient(colors: [Palette.lcdCaseTop, Palette.lcdCaseBottom],
                           startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: Palette.ink.opacity(0.10), radius: 10, y: 5)
        .padding(.horizontal, 18)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        RegisterDisplay(type: .expense, currencySymbol: "$", amount: "0",
                        category: ExpenseCategory(name: "Groceries", symbolName: "cart.fill",
                                                  colorHex: "#8CC0EB"),
                        dateText: "Today · 10:58 PM")
        RegisterDisplay(type: .income, currencySymbol: "$", amount: "42.50",
                        category: nil, dateText: "Today · 10:58 PM", amountInvalid: true)
    }
    .padding(.vertical, 40).frame(maxHeight: .infinity).background(Palette.bg)
}
#endif
```

- [ ] **Step 3: Build + lint** → BUILD SUCCEEDED, 19/0. Check the `#Preview` renders both cards
  (light + dark) resembling the handoff.

- [ ] **Step 4: Commit**
```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Theme/Palette.swift plop/plop/Views/Entry/RegisterDisplay.swift
git commit -m "Add register-display LCD component and palette tokens

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: EntryView reflow (register card, note row, footer, pill restyle)

**Files:** `plop/plop/Views/Entry/EntryView.swift`.

- [ ] **Step 1: Replace the `body` VStack** (lines from `VStack(spacing: 0) {` through the
  `keypad` line before `.background`). Change:
```swift
        VStack(spacing: 0) {
            header
            Spacer()
            amountArea
            Spacer()
            detailPills
            keypad
        }
```
to:
```swift
        VStack(spacing: 0) {
            header
            Spacer(minLength: 8)
            RegisterDisplay(type: mode, currencySymbol: currencySymbol(currencyCode),
                            amount: input.display(), category: selected,
                            dateText: "\(dateLabel) · \(timeLabel)", amountInvalid: amountInvalid)
            belowCard
            Spacer(minLength: 8)
            detailPills
            keypad
            footer
        }
```

- [ ] **Step 2: Replace `amountArea` + `notePill`** (the whole `// MARK: amount` block, both
  computed properties) with `belowCard`, `noteRow`, and `footer`:
```swift
    // MARK: below the register (caption, recurring, note)

    private var belowCard: some View {
        VStack(spacing: 12) {
            if let message = validationCaption {
                Text(message)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Palette.danger)
                    .multilineTextAlignment(.center)
            }
            if recurrence != .none {
                Button { recurOpen = true } label: {
                    Label("Repeats \(recurringSummary(interval: recurrence, date: date))",
                          systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Palette.ink60)
                }
            }
            noteRow
        }
        .padding(.top, 14)
    }

    private var noteRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal").foregroundStyle(Palette.ink40)
                TextField("Add Note", text: $note).font(.system(size: 15))
            }
            .padding(.vertical, 12).padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink12, lineWidth: 1))

            Button { input.backspace() } label: {
                Image(systemName: "delete.left")
                    .font(.system(size: 20)).foregroundStyle(Palette.ink60)
                    .frame(width: 54, height: 48)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink12, lineWidth: 1))
            }
        }
        .padding(.horizontal, 18)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Palette.ink12).frame(width: 40, height: 1)
            HStack(spacing: 6) {
                Text("Plop").font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.ink60)
                Text("CASHIER").font(.system(size: 13, weight: .semibold)).tracking(3)
                    .foregroundStyle(Palette.ink40)
            }
            Rectangle().fill(Palette.ink12).frame(width: 40, height: 1)
        }
        .padding(.top, 10).padding(.bottom, 16)
    }
```

- [ ] **Step 3: Restyle the two pills** in `detailPills` from `Capsule()` to a rounded rectangle
  to match the mockup's tactile cards. In the date pill, change:
```swift
                .background(Palette.card, in: Capsule())
                .overlay(Capsule().stroke(Palette.ink12, lineWidth: 1))
```
to:
```swift
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink12, lineWidth: 1))
```
And in the category pill, change:
```swift
                .background(selected.map { Color(hex: $0.colorHex) } ?? Palette.card, in: Capsule())
                .overlay(Capsule().stroke(categoryInvalid ? Palette.danger : Palette.ink12,
                                          lineWidth: categoryInvalid ? 1.5 : 1))
```
to:
```swift
                .background(selected.map { Color(hex: $0.colorHex) } ?? Palette.card,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(categoryInvalid ? Palette.danger : Palette.ink12,
                                          lineWidth: categoryInvalid ? 1.5 : 1))
```

- [ ] **Step 4: Build + lint** → BUILD SUCCEEDED, 19/0. (The `#Preview` at the bottom of
  EntryView still compiles; `amountArea`/`notePill` are gone and no longer referenced.)

- [ ] **Step 5: Commit**
```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Entry/EntryView.swift
git commit -m "Reflow Entry around the register display with note row and cashier footer

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Keypad tactile restyle

**Files:** `plop/plop/Views/Entry/Keypad.swift`.

- [ ] **Step 1: Strengthen the key shadow + radius** to the handoff's tactile look. In the `key`
  builder, change:
```swift
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundStyle(Palette.ink)
                .shadow(color: Palette.ink.opacity(0.05), radius: 2, y: 1)
```
to:
```swift
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .foregroundStyle(Palette.ink)
                .shadow(color: Color.black.opacity(0.12), radius: 4, y: 1)
```
And in `confirmKey`, change the confirm background radius `18` → `20`:
```swift
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
```
to:
```swift
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
```

- [ ] **Step 2: Build + lint** → BUILD SUCCEEDED, 19/0.

- [ ] **Step 3: Commit**
```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Entry/Keypad.swift
git commit -m "Restyle the keypad keys to the tactile cash-register look

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full build** → `** BUILD SUCCEEDED **`.
- [ ] **Step 2: Full test suite** (no logic changed — must stay green)
```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 \
  | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **`, 188 tests.
- [ ] **Step 3: Lint** → 19/0.
- [ ] **Step 4: Simulator check (manual — owner), light + dark**, comparing against
  `design_handoff_plop/screenshots/add_entry_cashier_register.jpg`:
  - Register card: `DEBIT · OUT` (Expense) / `CREDIT · IN` (Income, flips with the toggle),
    category top-right (or `NO CATEGORY`), the `$` + amount updates as you type, `TODAY · time`.
  - Note row (lines icon + separate backspace), tactile date/category pills, tactile keypad with
    blue ✓, and the `— Plop CASHIER —` footer.
  - Invalid confirm → error buzz + red amount in the card + red category pill + caption.
  - Editing an existing entry prefills; save + delete + recurring still work.
- [ ] **Step 5: Push + PR**
```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git push -u origin feature/entry-cash-register
```
PR (project format):
```markdown
## Summary
Reskin the Entry screen to the cash-register handoff: a blue LCD RegisterDisplay card (DEBIT·OUT /
CREDIT·IN, category, SF amount, date), a note/backspace row, tactile pills/keypad, and a
Plop CASHIER footer. New Palette LCD tokens (light + dark). Presentation only — no behaviour change.

## Testing
188 unit tests pass (no new — view reskin); SwiftLint clean (19/0). Sim-verified against the
handoff, light + dark: status/category/amount/date, validation red states, save/delete/recurring.
```

---

## Self-review notes

- **Spec coverage:** LCD tokens + `RegisterDisplay` (T1); EntryView reflow incl. note row, footer,
  validation re-placement, pill restyle (T2); keypad restyle (T3); verify (T4). All design items map.
- **Behaviour preserved:** `input`/pickers/`confirm`/`performSave`/validation flags/haptics are
  untouched; only presentation moves. `amountInvalid`/`categoryInvalid`/`validationCaption` are
  re-used (now feeding the card + caption). No new unit tests (project convention).
- **Divergence flagged:** SF monospaced amount, not DSEG7 — documented in the spec + this plan.
- **Fidelity:** numeric paddings/heights are a faithful start; implementer reads the screenshot and
  nudges to match. Dark variant via the new dynamic tokens.
- **No placeholders / no disables / config untouched / lines ≤ 120.**
