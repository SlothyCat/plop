# Settings Popup Polish (PR A) — Design

Status: Approved (brainstorm complete) · Date: 2026-06-22

Companion to `requirements.md`. The `BlurPopup` × + theme change, the per-popup
dismiss-button removals, the currency row tap fix, testing, scope.

## Architecture

```
plop/Views/Common/BlurPopup.swift          (auto × overlay + preferredColorScheme)
plop/Views/Settings/CurrencyView.swift     (drop doneBar; row .contentShape)
plop/Views/Settings/AppearanceSheet.swift  (drop "Done")
plop/Views/Settings/RecurringRulesSheet.swift (drop doneBar)
plop/Views/Settings/BudgetView.swift       (drop "Cancel"; keep Save)
plop/Views/Settings/ExportSheet.swift      (drop form "Cancel" + success "Done")
plop/Views/Settings/BugReportSheet.swift   (drop form "Cancel" + fallback "Done")
plop/Views/Settings/CategoryFormView.swift (drop "Cancel"; keep Save)
plop/Views/Settings/ReassignCategorySheet.swift (drop "Cancel")
plop/Views/Settings/ManageCategoriesView.swift  (drop its own header ×)
```

## 1. `BlurPopup` — auto × + theme (the crux)

In `BlurPopupContainer`: add `@AppStorage(themeModeKey)`, overlay a × on the card, and apply
`preferredColorScheme` so popups follow the theme.

```swift
private struct BlurPopupContainer<Card: View>: View {
    @Binding var isPresented: Bool
    var tall: Bool
    @ViewBuilder var card: () -> Card

    @AppStorage(themeModeKey) private var themeModeRaw = ThemeMode.automatic.rawValue
    @State private var shown = false
    @State private var drag: CGFloat = 0
    // …anim/outDelay unchanged…

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                // …scrim unchanged…

                card()
                    .frame(maxWidth: .infinity, maxHeight: tall ? proxy.size.height * 0.8 : nil)
                    // NOTE: confirm against current file — the height cap currently lives on
                    // the card frame; keep whatever the merged BlurPopup uses, just add the
                    // overlay + envs below.
                    .overlay(alignment: .topTrailing) { closeButton }
                    .background(Palette.card,
                                in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .offset(y: shown ? drag : 1000)
                    .opacity(shown ? 1 : 0)
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
}
```
The × overlays the card's top-right (inside the rounded clip), pinned above any scroll. Every
`.blurPopup`/`.blurPopup(item:)` gets it. `preferredColorScheme` re-reads `themeModeKey`, so
the Appearance toggle repaints the open popup live; all popups now match the theme.

> Implementation note: apply the overlay to the **exact** current `card()` modifier chain in
> the merged file (don't restructure the existing frame/offset/opacity/env lines — only add
> `.overlay(alignment: .topTrailing) { closeButton }`, the `@AppStorage`, and the
> `.preferredColorScheme` line).

## 2. Remove the redundant dismiss buttons

Each popup loses only its dismiss-only control; the × now handles exit.

- **CurrencyView** — remove `doneBar` from the body (`.frame(maxHeight: scrollCap)` is the
  last element) and delete the `doneBar` property.
- **AppearanceSheet** — remove the `Button("Done") { close() }` block (and the now-trailing
  blank line in the VStack).
- **RecurringRulesSheet** — remove `doneBar` from the body and delete the `doneBar` property.
- **BudgetView** — in the bottom `VStack(spacing: 4)`, remove the `Button("Cancel")`; keep
  the "Save budget" button. (The `VStack(spacing: 4)` may collapse to just the Save button.)
- **ExportSheet** — remove the form's `Button("Cancel")` and the success state's
  `Button("Done")`; keep "Export" and "Open in Google Sheets".
- **BugReportSheet** — remove the form's `Button("Cancel")` and the fallback's
  `Button("Done")`; keep "Send" and "Copy report".
- **CategoryFormView** — remove the `Button("Cancel")`; keep "Save".
- **ReassignCategorySheet** — remove the trailing `Button("Cancel")` (the
  `.frame(maxHeight: scrollCap)` ScrollView is then the last element).
- **ManageCategoriesView** — replace the header's `HStack { Text("Categories"); Spacer;
  Button(×) }` with just `Text("Categories")` (the BlurPopup × replaces the hand-rolled one).

(Leaving the primary-action `VStack` wrappers in place is fine even if they now hold one
button.)

## 3. Currency row tap target (#1)

In `CurrencyView.row(_:)`, after the `.background`/`.overlay`, add:
```swift
        .contentShape(Rectangle())
```
so the full padded row is hit-testable.

## 4. Verify #2 (Save budget)

No `disabled` exists on the Save button; re-check in the simulator that it taps promptly
after the popup settles. If a real delay remains beyond the ~0.34s slide-in, investigate
then — no code change planned otherwise.

## Testing

- **No new unit tests** (presentation only; no logic change).
- **Views:** preview + simulator, light + dark:
  - every Settings popup shows a top-right × that dismisses (tap); drag-down + primary
    actions still work; no leftover Done/Cancel except primary actions (Save/Export/Send/
    Copy);
  - open a popup, toggle **Theme** → the open popup (and the rest) switch light/dark live;
    set a non-Automatic theme → popups honour it;
  - tapping anywhere on a **currency row** selects it;
  - **#2:** Save budget is tappable promptly.

## Scope

`BlurPopup` (× + theme) + nine popups' dismiss-button removals + the currency row
`contentShape`. One PR on `feature/settings-popup-polish`. Donut small-slice fix is PR B.
