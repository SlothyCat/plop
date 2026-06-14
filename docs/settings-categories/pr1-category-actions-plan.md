# PR1 — Category Actions & Validation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline, no worktrees). Steps use `- [ ]`.

**Goal:** Build the category write path (add/update/delete-with-reassign), name-uniqueness validation, and the curated SF-Symbol icon list — with unit tests. No UI.

**Architecture:** `CategoryActions` (mirrors `TransactionActions`) mutates via `ModelContext`; `isCategoryNameAvailable` is a pure function; `categoryIconChoices` is a constant list. Tested against an in-memory `ModelContainer` (kept alive) and plain values.

**Tech Stack:** Swift, SwiftData (models), XCTest. iOS 18.

---

## Conventions
- Branch `feature/category-actions` off `main`. No worktrees.
- Commit present-tense + `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- Run tests: `xcodebuild test -project plop/plop.xcodeproj -scheme plop -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -parallel-testing-enabled NO -only-testing:plopTests/CLASS/METHOD`
- In-memory tests use `makeInMemoryContainer()` and keep the container alive (per `memory/swiftdata-gotchas.md`). Bogus crashes → `memory/xcode-build-sim-gotchas.md`.

## File Structure
- Create `plop/plop/Data/CategoryActions.swift`
- Create `plop/plop/Logic/CategoryValidation.swift`
- Create `plop/plop/Models/CategoryIcons.swift`
- Create `plop/plopTests/CategoryActionsTests.swift`, `CategoryValidationTests.swift`, `CategoryIconsTests.swift`

---

### Task 1: `CategoryActions.add` + `.update`

**Files:** create `plop/plopTests/CategoryActionsTests.swift`, `plop/plop/Data/CategoryActions.swift`.

- [ ] **Step 1: Branch**
```bash
git checkout main && git pull --ff-only && git checkout -b feature/category-actions
```

- [ ] **Step 2: Write the failing tests**

`plop/plopTests/CategoryActionsTests.swift`:
```swift
import XCTest
import SwiftData
@testable import plop

@MainActor
final class CategoryActionsTests: XCTestCase {
    func test_add_insertsCategory() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        CategoryActions.add(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC", in: ctx)
        try ctx.save()

        let cats = try ctx.fetch(FetchDescriptor<ExpenseCategory>())
        XCTAssertEqual(cats.count, 1)
        XCTAssertEqual(cats.first?.name, "Food")
        XCTAssertEqual(cats.first?.symbolName, "fork.knife")
        XCTAssertEqual(cats.first?.colorHex, "#FFEBCC")
    }

    func test_update_mutatesFields() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let cat = ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC")
        ctx.insert(cat)

        CategoryActions.update(cat, name: "Groceries", symbolName: "cart.fill", colorHex: "#8CC0EB")
        try ctx.save()

        XCTAssertEqual(cat.name, "Groceries")
        XCTAssertEqual(cat.symbolName, "cart.fill")
        XCTAssertEqual(cat.colorHex, "#8CC0EB")
    }
}
```

- [ ] **Step 3: Run to verify it fails**
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/CategoryActionsTests/test_add_insertsCategory
```
Expected: FAIL — `cannot find 'CategoryActions'`.

- [ ] **Step 4: Write minimal implementation**

`plop/plop/Data/CategoryActions.swift`:
```swift
import Foundation
import SwiftData

/// The single locus for category mutations (mirrors TransactionActions).
enum CategoryActions {
    static func add(name: String, symbolName: String, colorHex: String, in context: ModelContext) {
        context.insert(ExpenseCategory(name: name, symbolName: symbolName, colorHex: colorHex))
    }

    static func update(_ category: ExpenseCategory, name: String, symbolName: String, colorHex: String) {
        category.name = name
        category.symbolName = symbolName
        category.colorHex = colorHex
    }
}
```

- [ ] **Step 5: Run to verify it passes, then commit**
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/CategoryActionsTests
```
Expected: PASS (2).
```bash
git add plop/plop/Data/CategoryActions.swift plop/plopTests/CategoryActionsTests.swift
git commit -m "Add CategoryActions add and update"
```

---

### Task 2: `CategoryActions.delete(reassigningTo:)`

**Files:** modify `plop/plopTests/CategoryActionsTests.swift`, `plop/plop/Data/CategoryActions.swift`.

- [ ] **Step 1: Add the failing test**

Add inside `CategoryActionsTests`:
```swift
    func test_delete_reassignsTransactionsThenRemovesCategory() throws {
        let container = try makeInMemoryContainer()
        let ctx = container.mainContext
        let food = ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC")
        let groceries = ExpenseCategory(name: "Groceries", symbolName: "cart.fill", colorHex: "#8CC0EB")
        ctx.insert(food); ctx.insert(groceries)
        let tx = Transaction(amount: 10, type: .expense, date: .now, category: food)
        ctx.insert(tx)
        try ctx.save()

        CategoryActions.delete(food, reassigningTo: groceries, in: ctx)
        try ctx.save()

        let cats = try ctx.fetch(FetchDescriptor<ExpenseCategory>())
        XCTAssertEqual(cats.map(\.name), ["Groceries"])
        let txs = try ctx.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(txs.count, 1)
        XCTAssertEqual(txs.first?.category?.name, "Groceries")
    }
```

- [ ] **Step 2: Run to verify it fails**
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/CategoryActionsTests/test_delete_reassignsTransactionsThenRemovesCategory
```
Expected: FAIL — no `delete(_:reassigningTo:in:)`.

- [ ] **Step 3: Write minimal implementation**

Append to `CategoryActions`:
```swift
    /// Move this category's transactions to `target`, then delete it.
    static func delete(_ category: ExpenseCategory, reassigningTo target: ExpenseCategory,
                       in context: ModelContext) {
        for tx in Array(category.transactions) {   // snapshot: reassign mutates the relationship
            tx.category = target
        }
        context.delete(category)
    }
```

- [ ] **Step 4: Run to verify it passes, then commit**
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/CategoryActionsTests
```
Expected: PASS (3).
```bash
git add plop/plop/Data/CategoryActions.swift plop/plopTests/CategoryActionsTests.swift
git commit -m "Add CategoryActions delete with reassignment"
```

---

### Task 3: Name validation + icon list, full green, PR

**Files:** create `plop/plop/Logic/CategoryValidation.swift`, `plop/plop/Models/CategoryIcons.swift`,
`plop/plopTests/CategoryValidationTests.swift`, `plop/plopTests/CategoryIconsTests.swift`.

- [ ] **Step 1: Write the failing validation tests**

`plop/plopTests/CategoryValidationTests.swift`:
```swift
import XCTest
@testable import plop

final class CategoryValidationTests: XCTestCase {
    private func cat(_ name: String) -> ExpenseCategory {
        ExpenseCategory(name: name, symbolName: "tag.fill", colorHex: "#8CC0EB")
    }

    func test_rejectsEmptyOrWhitespace() {
        XCTAssertFalse(isCategoryNameAvailable("   ", existing: []))
    }
    func test_rejectsDuplicateCaseInsensitive() {
        XCTAssertFalse(isCategoryNameAvailable("food", existing: [cat("Food")]))
    }
    func test_allowsUniqueName() {
        XCTAssertTrue(isCategoryNameAvailable("Transport", existing: [cat("Food")]))
    }
    func test_editingKeepsOwnName() {
        let food = cat("Food")
        XCTAssertTrue(isCategoryNameAvailable("Food", existing: [food], editing: food))
    }
    func test_editingToAnothersNameRejected() {
        let food = cat("Food"); let transport = cat("Transport")
        XCTAssertFalse(isCategoryNameAvailable("Food", existing: [food, transport], editing: transport))
    }
}
```

- [ ] **Step 2: Run to verify it fails**
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests/CategoryValidationTests/test_allowsUniqueName
```
Expected: FAIL — `cannot find 'isCategoryNameAvailable'`.

- [ ] **Step 3: Implement validation + icon list**

`plop/plop/Logic/CategoryValidation.swift`:
```swift
import Foundation

/// True if `name` (trimmed, non-empty) is not already used by another category.
/// Case-insensitive. When `editing`, that category keeps its own name.
func isCategoryNameAvailable(_ name: String,
                            existing: [ExpenseCategory],
                            editing: ExpenseCategory? = nil) -> Bool {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return false }
    return !existing.contains { other in
        if let editing, other === editing { return false }
        return other.name.caseInsensitiveCompare(trimmed) == .orderedSame
    }
}
```

`plop/plop/Models/CategoryIcons.swift`:
```swift
import Foundation

/// Curated SF Symbol names offered when creating/editing a category.
let categoryIconChoices: [String] = [
    "fork.knife", "cart.fill", "bag.fill", "cup.and.saucer.fill",
    "car.fill", "bus.fill", "fuelpump.fill", "airplane",
    "house.fill", "bolt.fill", "wifi", "drop.fill",
    "cross.case.fill", "pills.fill", "heart.fill", "dumbbell.fill",
    "gamecontroller.fill", "film.fill", "music.note", "book.fill",
    "graduationcap.fill", "gift.fill", "pawprint.fill", "tshirt.fill",
    "creditcard.fill", "dollarsign.circle.fill", "tag.fill", "ellipsis.circle.fill",
]
```

`plop/plopTests/CategoryIconsTests.swift`:
```swift
import XCTest
@testable import plop

final class CategoryIconsTests: XCTestCase {
    func test_iconsNonEmptyAndUnique() {
        XCTAssertFalse(categoryIconChoices.isEmpty)
        XCTAssertEqual(categoryIconChoices.count, Set(categoryIconChoices).count)
    }
}
```

- [ ] **Step 4: Run validation + icon tests**
```bash
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO \
  -only-testing:plopTests/CategoryValidationTests -only-testing:plopTests/CategoryIconsTests
```
Expected: PASS (6).

- [ ] **Step 5: Full test target + lint**
```bash
xcrun simctl shutdown all 2>/dev/null; sleep 2
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -parallel-testing-enabled NO -only-testing:plopTests
swiftlint lint
```
Expected: all pass (existing 41 + 9 new = 50); no lint errors.

- [ ] **Step 6: Commit, push, PR**
```bash
git add plop/plop/Logic/CategoryValidation.swift plop/plop/Models/CategoryIcons.swift \
        plop/plopTests/CategoryValidationTests.swift plop/plopTests/CategoryIconsTests.swift
git commit -m "Add category name validation and curated SF Symbol list"
git push -u origin feature/category-actions
```
Open PR `feature/category-actions` → `main` via GitHub web; confirm CI green.

---

## Self-review notes
- **Spec coverage:** `CategoryActions` add/update (T1), delete-with-reassign (T2),
  `isCategoryNameAvailable` (T3), `categoryIconChoices` (T3). No UI — correct for PR1.
- **SwiftData safety:** in-memory tests keep the container alive; `delete` snapshots
  `transactions` into an Array before reassigning (the relationship mutates during the loop).
- **Type consistency:** `CategoryActions.add(name:symbolName:colorHex:in:)`,
  `.update(_:name:symbolName:colorHex:)`, `.delete(_:reassigningTo:in:)`,
  `isCategoryNameAvailable(_:existing:editing:)`, `categoryIconChoices` used identically.
- **Identity for editing:** uses `===` (ExpenseCategory is a final class) — no SwiftData import needed in validation.
