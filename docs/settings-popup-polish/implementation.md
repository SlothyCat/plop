# Settings Popup Polish (PR A) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every Settings popup a standard top-right × (replacing Done/Cancel), make popups follow the app theme live, and make the whole currency row tappable.

**Architecture:** One change to `BlurPopup` (auto × overlay + `preferredColorScheme`) covers the × and theme for all popups; then remove the now-redundant dismiss buttons from each popup view and add a `contentShape` to the currency row. Presentation only.

**Tech Stack:** SwiftUI, SwiftData. iOS 18. Views verified via `#Preview` + simulator.

Single PR on branch `feature/settings-popup-polish` (off `main`; spec committed there).

---

## File structure

- **Modify** `plop/plop/Views/Common/BlurPopup.swift` — `@AppStorage(themeModeKey)`, × overlay, `preferredColorScheme`.
- **Modify** these popups to drop dismiss-only buttons (keep primary actions):
  `CurrencyView` (doneBar + row `contentShape`), `AppearanceSheet` (Done),
  `RecurringRulesSheet` (doneBar), `BudgetView` (Cancel), `ExportSheet` (form Cancel +
  success Done), `BugReportSheet` (form Cancel + fallback Done), `CategoryFormView` (Cancel),
  `ReassignCategorySheet` (Cancel), `ManageCategoriesView` (its own header ×).

### Build / lint commands

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | tail -5

swiftlint lint
```

> SourceKit "Cannot find X" diagnostics are FALSE positives — `xcodebuild` is the source of
> truth. Lines ≤ 120. No `// swiftlint:disable`. Keep the lint baseline (19 violations, 0
> serious); do not edit `.swiftlint.yml`.

---

## Task 1: BlurPopup — auto × + theme

**Files:**
- Modify: `plop/plop/Views/Common/BlurPopup.swift`

- [ ] **Step 1: Add the theme AppStorage**

In `BlurPopupContainer`, change:
```swift
    @Binding var isPresented: Bool
    var tall: Bool
    @ViewBuilder var card: () -> Card

    @State private var shown = false
    @State private var drag: CGFloat = 0
```
to:
```swift
    @Binding var isPresented: Bool
    var tall: Bool
    @ViewBuilder var card: () -> Card

    @AppStorage(themeModeKey) private var themeModeRaw = ThemeMode.automatic.rawValue
    @State private var shown = false
    @State private var drag: CGFloat = 0
```

- [ ] **Step 2: Add the × overlay + apply preferredColorScheme**

Change the `card()` chain + the trailing `.onAppear`:
```swift
                card()
                    .frame(maxWidth: .infinity)
                    .background(Palette.card,
                                in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .offset(y: shown ? drag : 1000)
                    .opacity(shown ? 1 : 0)   // gate visibility so content never paints pre-slide
                    .gesture(dragToDismiss)
                    .environment(\.blurPopupClose, close)
                    .environment(\.blurPopupMaxHeight, tall ? proxy.size.height : .infinity)
            }
        }
        .onAppear { withAnimation(anim) { shown = true } }
    }
```
to:
```swift
                card()
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .topTrailing) { closeButton }
                    .background(Palette.card,
                                in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .offset(y: shown ? drag : 1000)
                    .opacity(shown ? 1 : 0)   // gate visibility so content never paints pre-slide
                    .gesture(dragToDismiss)
                    .environment(\.blurPopupClose, close)
                    .environment(\.blurPopupMaxHeight, tall ? proxy.size.height : .infinity)
            }
        }
        .preferredColorScheme((ThemeMode(rawValue: themeModeRaw) ?? .automatic).colorScheme)
        .onAppear { withAnimation(anim) { shown = true } }
    }

    private var closeButton: some View {
        Button { close() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.ink60)
                .frame(width: 32, height: 32).background(Palette.field, in: Circle())
        }
        .buttonStyle(.plain)
        .padding(.top, 14).padding(.trailing, 14)
    }
```

- [ ] **Step 3: Build** — run the build command → `** BUILD SUCCEEDED **`. (Every popup now
  shows a × and follows the theme; the popups still have their own Done/Cancel until Task 2 —
  that's fine and compiles.)

- [ ] **Step 4: Lint** — `swiftlint lint` → no new violations.

- [ ] **Step 5: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Common/BlurPopup.swift
git commit -m "BlurPopup: add a top-right close button and apply the app theme to popups

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Remove redundant dismiss buttons + currency row tap

**Files:** the nine popup views listed below.

- [ ] **Step 1: CurrencyView — drop `doneBar`, add row `contentShape`**

In `CurrencyView.swift`, remove the `doneBar` from the body. Change:
```swift
            .frame(maxHeight: scrollCap)
            doneBar
        }
    }
```
to:
```swift
            .frame(maxHeight: scrollCap)
        }
    }
```
Delete the `doneBar` property:
```swift
    private var doneBar: some View {
        Button("Done") { close() }
            .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .overlay(Rectangle().fill(Palette.hair).frame(height: 1), alignment: .top)
    }
```
In `row(_:)`, add `.contentShape(Rectangle())` after the `.overlay(...)`:
```swift
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(on ? Color.clear : Palette.ink12, lineWidth: 1))
        .contentShape(Rectangle())
    }
```

- [ ] **Step 2: AppearanceSheet — drop "Done"**

In `AppearanceSheet.swift`, remove the Done button block:
```swift
            Button("Done") { close() }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
```
(Leave the `VStack(spacing: 10) { ForEach(...) { card($0) } }` above it as the VStack's last
element.)

- [ ] **Step 3: RecurringRulesSheet — drop `doneBar`**

Remove it from the body:
```swift
                .frame(maxHeight: scrollCap)
            }
            doneBar
        }
```
to:
```swift
                .frame(maxHeight: scrollCap)
            }
        }
```
Delete the `doneBar` property:
```swift
    private var doneBar: some View {
        Button("Done") { close() }
            .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .overlay(Rectangle().fill(Palette.hair).frame(height: 1), alignment: .top)
    }
```

- [ ] **Step 4: BudgetView — drop "Cancel"**

In the bottom `VStack(spacing: 4)`, remove:
```swift
                Button("Cancel") { close() }
                    .font(.system(size: 16, weight: .medium)).foregroundStyle(Palette.ink60)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
```
(Keep the "Save budget" button and the surrounding `VStack(spacing: 4) { … }.padding(.top, 2)`.)

- [ ] **Step 5: ExportSheet — drop form "Cancel" and success "Done"**

In `form`, remove:
```swift
                Button("Cancel") { close() }.foregroundStyle(Palette.ink60)
```
In `phaseSuccess(_:)`, remove:
```swift
            Button("Done") { close() }.foregroundStyle(Palette.ink60)
```
(Keep "Export" and "Open in Google Sheets".)

- [ ] **Step 6: BugReportSheet — drop form "Cancel" and fallback "Done"**

In `form`, remove:
```swift
                Button("Cancel") { close() }.foregroundStyle(Palette.ink60)
```
In `fallback`, remove:
```swift
                Button("Done") { close() }.foregroundStyle(Palette.ink60)
```
(Keep "Send" and "Copy report".)

- [ ] **Step 7: CategoryFormView — drop "Cancel"**

In the bottom `VStack(spacing: 4)`, remove:
```swift
                Button("Cancel") { close() }
                    .font(.system(size: 16, weight: .medium)).foregroundStyle(Palette.ink60)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
```
(Keep the "Save" button.)

- [ ] **Step 8: ReassignCategorySheet — drop "Cancel"**

Remove the trailing Cancel button:
```swift
            Button("Cancel") { close() }
                .font(.system(size: 16, weight: .medium)).foregroundStyle(Palette.ink60)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .overlay(Rectangle().fill(Palette.hair).frame(height: 1), alignment: .top)
```
(The `ScrollView { … }.frame(maxHeight: scrollCap)` is then the body's last element.)

- [ ] **Step 9: ManageCategoriesView — drop its own header ×**

Replace the header's title row. Change:
```swift
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
```
to:
```swift
        VStack(alignment: .leading, spacing: 6) {
            Text("Categories")
                .font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.ink)
            Text("Tap a category to edit it, or remove ones you don't use.")
                .font(.system(size: 15)).foregroundStyle(Palette.ink60)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
```

- [ ] **Step 10: Build** — run the build command → `** BUILD SUCCEEDED **`. If a now-single
  `VStack` or an empty `VStack(spacing: 8/4)` wrapper triggers a warning, leave it (harmless)
  unless it fails the build.

- [ ] **Step 11: Lint** — `swiftlint lint` → no new violations beyond baseline.

- [ ] **Step 12: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Views/Settings/CurrencyView.swift plop/plop/Views/Settings/AppearanceSheet.swift \
        plop/plop/Views/Settings/RecurringRulesSheet.swift plop/plop/Views/Settings/BudgetView.swift \
        plop/plop/Views/Settings/ExportSheet.swift plop/plop/Views/Settings/BugReportSheet.swift \
        plop/plop/Views/Settings/CategoryFormView.swift plop/plop/Views/Settings/ReassignCategorySheet.swift \
        plop/plop/Views/Settings/ManageCategoriesView.swift
git commit -m "Drop per-popup Done/Cancel in favour of the BlurPopup close button

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Verify and open PR

**Files:** none.

- [ ] **Step 1: Full suite** (presentation only — nothing should break)

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:plopTests -parallel-testing-enabled NO 2>&1 | grep -E "Executed [0-9]+ tests, with|TEST (SUCCEEDED|FAILED)" | tail -2
```
Expected: `** TEST SUCCEEDED **` (unchanged count).

- [ ] **Step 2: Lint** — `swiftlint lint` → baseline 19/0, no new violations.

- [ ] **Step 3: Simulator smoke check (manual — owner)**, light + dark:
- Every Settings popup (Export, Set budget, Manage categories, Add/Edit category, Reassign,
  Currency, Theme, Recurring, Report a bug) shows a **top-right ×** that dismisses; **drag
  down** still dismisses; **primary actions** remain (Save budget, Export / Open in Sheets,
  Send / Copy report, Save category) and work; no leftover Done/Cancel.
- Open a popup and toggle **Theme** → the open popup and the others switch **light/dark
  live**; set a non-Automatic theme and reopen popups → they honour it.
- Tapping **anywhere on a currency row** selects it.
- **#2:** the **Save budget** button is tappable promptly after the popup settles (no real
  delay). If a delay persists, report it — it's not gated in code.

- [ ] **Step 4: Push + PR**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git push -u origin feature/settings-popup-polish
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Settings popup polish: BlurPopup gains a standard top-right × and applies the app theme to
popups (so the Appearance toggle repaints them live); per-popup Done/Cancel are removed in
favour of the × (primary actions kept); the whole currency row is now tappable.

## Testing
All unit tests pass (no new — presentation change); SwiftLint clean (baseline 19/0).
Sim-verified: × on every popup, theme switches live in popups, full-row currency tap,
Save-budget taps promptly; light + dark.
```

---

## Self-review notes

- **Spec coverage:** × overlay + `preferredColorScheme` in BlurPopup (Task 1, #4 + #5);
  dismiss-button removals across all nine popups (Task 2, #5); currency row `contentShape`
  (Task 2 Step 1, #1); Save-budget sim re-check (Task 3 Step 3, #2). All map to a task.
- **Behaviour preserved:** primary actions (Save/Export/Send/Copy) and drag/tap dismiss stay;
  `\.blurPopupClose` still drives dismissal (now via the × and primary-button closures). No
  data/logic change → no unit tests (presentation; project convention).
- **Type consistency:** `closeButton` added in BlurPopupContainer and used in the same
  container's overlay; `themeModeKey`/`ThemeMode` already exist (Theme/ThemeMode.swift);
  removed buttons all called `close()` (`\.blurPopupClose`), now redundant.
- **No placeholders / no disables / config untouched / lines ≤ 120.**
- **Out of scope:** the donut small-slice fix (#3) is PR B.
