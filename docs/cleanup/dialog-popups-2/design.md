# Dialog Popups B2a (Currency + Set budget) — Design

Status: Approved (brainstorm complete) · Date: 2026-06-21

Companion to `requirements.md`. The `BlurPopup` `tall` option, the two conversions,
testing, and scope. Edits `BlurPopup.swift`, `CurrencyView.swift`, `BudgetView.swift`,
and `SettingsView.swift`.

## Architecture

```
plop/Views/Common/BlurPopup.swift        (add `tall` option)
plop/Views/Settings/CurrencyView.swift   (header + Done; drop nav chrome)
plop/Views/Settings/BudgetView.swift     (header + Done; drop nav chrome)
plop/Views/Settings/SettingsView.swift   (Currency/Budget rows: NavigationLink → Button + .blurPopup tall)
```

## 1. `BlurPopup` — `tall` option

Add `tall: Bool = false` to the modifier and cap the card height when set. `List`/`Form`
have no intrinsic height, so without a cap they would either collapse or force a full-height
card; with `tall` the card is bounded to ~80% of the available height and the list scrolls
inside. `tall: false` preserves B1's hug-to-content behavior exactly (existing call sites
omit the argument).

```swift
extension View {
    func blurPopup<Card: View>(
        isPresented: Binding<Bool>,
        tall: Bool = false,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder card: @escaping () -> Card
    ) -> some View {
        fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) {
            BlurPopupContainer(isPresented: isPresented, tall: tall, card: card)
                .presentationBackground(.clear)
        }
        .transaction { $0.disablesAnimations = true }
    }
}
```

`BlurPopupContainer` gains `var tall: Bool`, wraps its `ZStack` in a `GeometryReader` for
the available height, and applies the cap on the card frame:

```swift
private struct BlurPopupContainer<Card: View>: View {
    @Binding var isPresented: Bool
    var tall: Bool
    @ViewBuilder var card: () -> Card

    @State private var shown = false
    @State private var drag: CGFloat = 0

    private let anim: Animation = .spring(response: 0.34, dampingFraction: 0.86)
    private let outDelay = 0.34

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(Color.black.opacity(0.18))
                    .ignoresSafeArea()
                    .opacity(shown ? 1 : 0)
                    .contentShape(Rectangle())
                    .onTapGesture { close() }

                card()
                    .frame(maxWidth: .infinity,
                           maxHeight: tall ? proxy.size.height * 0.8 : nil)
                    .background(Palette.card,
                                in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .offset(y: shown ? drag : 1000)
                    .gesture(dragToDismiss)
                    .environment(\.blurPopupClose, close)
            }
        }
        .onAppear { withAnimation(anim) { shown = true } }
    }

    // dragToDismiss and close() are unchanged from B1.
}
```

Notes:
- `GeometryReader` reports the safe-area height, which shrinks when the keyboard appears,
  so a `tall` budget card with `decimalPad` fields still rises above the keyboard (the card
  stays bottom-pinned).
- `0.8` and the existing spring / scrim / paddings / drag thresholds are tuned in the
  simulator.

## 2. Currency

`CurrencyView` becomes card content: a fixed header above the existing `List`. It reads
`\.blurPopupClose` for Done, drops `.navigationTitle` and its own `.background` (the card
supplies `Palette.card`). The rows, selection write, and footer note are unchanged.

```swift
struct CurrencyView: View {
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @Environment(\.blurPopupClose) private var close

    var body: some View {
        VStack(spacing: 0) {
            header
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
        }
    }

    private var header: some View {
        HStack {
            Text("Currency")
                .font(.system(size: 22, weight: .bold)).foregroundStyle(Palette.ink)
            Spacer()
            Button("Done") { close() }
                .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 6)
    }

    // row(_:) unchanged.
}
```
Preview becomes `#Preview { CurrencyView() }` (no `NavigationStack`).

## 3. Set budget

Same shape — a header above the existing `List`. `BudgetView` reads `\.blurPopupClose`,
drops `.navigationTitle` and `.background`, and keeps everything else: the segmented
Total / By-category picker, the amount fields, the live total footer, the **"Save budget"**
button (persists exactly as today), and `.onAppear(perform: loadFields)`.

```swift
    var body: some View {
        VStack(spacing: 0) {
            header
            List {
                // ... existing sections unchanged (mode picker, fields, total, Save) ...
            }
            .scrollContentBackground(.hidden)
            .onAppear(perform: loadFields)
        }
    }

    private var header: some View {
        HStack {
            Text("Set budget")
                .font(.system(size: 22, weight: .bold)).foregroundStyle(Palette.ink)
            Spacer()
            Button("Done") { close() }
                .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 6)
    }
```
The `import SwiftData`, `@Query`, `@AppStorage`, `@State` fields, `amountField`,
`bindingFor`, `loadFields`, and `save` are unchanged. Preview becomes
`#Preview { BudgetView().modelContainer(SampleData.previewContainer()) }`.

## 4. SettingsView

Add two state flags and convert the Currency + Budget rows from `NavigationLink` to
`Button` + `.blurPopup(..., tall: true)`. The Manage categories row stays a
`NavigationLink`, so the `NavigationStack` remains.

```swift
    @State private var showingBudget = false
    @State private var showingCurrency = false
    // ... existing showingAppearance/Export/BugReport/Recurring ...
```

In the PREFERENCES section, change:
```swift
            NavigationLink { BudgetView() } label: {
                SettingsRow(tile: Palette.accent, systemImage: "chart.pie.fill",
                            title: "Set budget", value: budgetSummary, showsChevron: false)
            }
```
to:
```swift
            Button { showingBudget = true } label: {
                SettingsRow(tile: Palette.accent, systemImage: "chart.pie.fill",
                            title: "Set budget", value: budgetSummary, showsChevron: false)
            }
            .buttonStyle(.plain)
```
and the Currency row from:
```swift
            NavigationLink { CurrencyView() } label: {
                SettingsRow(tile: Palette.cream, systemImage: "dollarsign.circle.fill",
                            title: "Currency", value: currencyCode, showsChevron: false)
            }
```
to:
```swift
            Button { showingCurrency = true } label: {
                SettingsRow(tile: Palette.cream, systemImage: "dollarsign.circle.fill",
                            title: "Currency", value: currencyCode, showsChevron: false)
            }
            .buttonStyle(.plain)
```
(The `NavigationLink { ManageCategoriesView() }` row is unchanged.)

Add two popups alongside the existing `.blurPopup` modifiers:
```swift
            .blurPopup(isPresented: $showingBudget, tall: true) {
                BudgetView()
            }
            .blurPopup(isPresented: $showingCurrency, tall: true) {
                CurrencyView()
            }
```

## Testing

Presentation only — `#Preview` + simulator (no unit tests; currency/budget logic is
untouched and already covered). Verify against the handoff Currency screenshot, light + dark:
- Tapping **Currency** / **Set budget** blurs the screen and slides a tall card up; the
  list scrolls inside the card; closing reverses.
- **Tap-scrim / drag-down / Done** all dismiss.
- **Currency:** tapping a code selects it (checkmark moves) and updates money across the app
  live behind the blur.
- **Set budget:** segmented mode switch, typing in an amount field **raises the card above
  the keyboard**, the total footer updates, and **Save budget** persists (reopen shows the
  saved values); the General/By-category modes still replace each other.
- Manage categories still pushes (unchanged).
- **Regression:** because `BlurPopup` itself changed (the `GeometryReader` wrap), re-verify
  the B1 dialogs (Theme, Export, Report a bug, Recurring) still **hug their content**
  (`tall: false`) and dismiss/keyboard-rise as before.

## Scope

Presentation only: the `BlurPopup` `tall` option + header/chrome swaps on Currency and
Set budget + the two `SettingsView` row conversions. One PR on `feature/dialog-popups-2`.
B2b (categories cluster) and Cleanup C (content restyle) are separate.
