# Dialog Popups (Cleanup B1) — Design

Status: Approved (brainstorm complete) · Date: 2026-06-21

Companion to `requirements.md`. The `BlurPopup` component, the four-dialog adoption,
testing, and scope. New file + edits to `SettingsView` and the four sheet views.

## Architecture

```
plop/Views/Common/
  BlurPopup.swift        (new folder + file — reusable blurred bottom-popup + .blurPopup modifier)
plop/Views/Settings/
  SettingsView.swift     (.sheet → .blurPopup for the four dialogs)
  AppearanceSheet.swift  (drop detents + own background; card now supplies it)
  ExportSheet.swift      (drop detents/drag-indicator + own background)
  BugReportSheet.swift   (drop detents/drag-indicator + own background; keep nested Mail .sheet)
  RecurringRulesSheet.swift (drop detents + own background)
```

(There is no shared-views folder today — the four feature folders plus `Shell`. We add a
new `Views/Common/` folder for the reusable `BlurPopup`; Xcode 16 file-system-synchronized
folders pick up the new folder + file automatically.)

## 1. The `BlurPopup` component

A `fullScreenCover` whose **background is cleared** so the presenter shows through; an
in-cover `.ultraThinMaterial` then blurs that real screen. The cover's own slide is
suppressed (`transaction.disablesAnimations`) so we drive enter/exit ourselves: the
scrim **fades** and the card **slides** — matching the handoff's separate scrim-fade +
card-slide.

```swift
import SwiftUI

extension View {
    /// Presents `card` as a handoff-style blurred bottom popup.
    func blurPopup<Card: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder card: @escaping () -> Card
    ) -> some View {
        fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) {
            BlurPopupContainer(isPresented: isPresented, card: card)
                .presentationBackground(.clear)
        }
        .transaction { $0.disablesAnimations = true }   // suppress the cover's slide
    }
}

private struct BlurPopupContainer<Card: View>: View {
    @Binding var isPresented: Bool
    @ViewBuilder var card: () -> Card

    @State private var shown = false
    @State private var drag: CGFloat = 0          // live downward drag

    private let anim: Animation = .spring(response: 0.34, dampingFraction: 0.86)

    var body: some View {
        ZStack(alignment: .bottom) {
            // backdrop: blurs the real screen + a light dim; tap to dismiss
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.18))
                .ignoresSafeArea()
                .opacity(shown ? 1 : 0)
                .contentShape(Rectangle())
                .onTapGesture { close() }

            card()
                .frame(maxWidth: .infinity)
                .background(Palette.card,
                            in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .offset(y: shown ? drag : 1000)     // start off-screen, then track drag
                .gesture(dragToDismiss)
        }
        .onAppear { withAnimation(anim) { shown = true } }
    }

    private var dragToDismiss: some Gesture {
        DragGesture()
            .onChanged { drag = max(0, $0.translation.height) }
            .onEnded { value in
                if value.translation.height > 120 || value.predictedEndTranslation.height > 240 {
                    close()
                } else {
                    withAnimation(anim) { drag = 0 }
                }
            }
    }

    private func close() {
        withAnimation(anim) { shown = false; drag = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) { isPresented = false }
    }
}
```

Notes:
- **Blur:** `.ultraThinMaterial` over the cleared cover blurs the actual screen behind
  (the handoff `blur(2px)`); the 0.18 black overlay is the ~32% scrim, toned for iOS.
- **Enter/exit:** `disablesAnimations` kills the system cover slide; `shown` drives the
  scrim opacity and the card offset (`1000 → 0`) via one spring. `close()` animates out,
  then clears the binding after the spring (~0.34s) so the now-invisible cover is torn
  down without a second slide.
- **Drag:** the card tracks downward drags; releasing past ~120pt (or a fast flick) calls
  `close()`, otherwise it springs back. Upward drag is clamped to 0.
- **Keyboard:** the card is bottom-pinned and does **not** ignore the keyboard safe area,
  so it rises with the keyboard automatically; tall content scrolls inside the card.
- The exact spring, scrim opacity, paddings, and drag threshold are tuned in the
  simulator against the handoff screenshots.

## 2. Adopting the four dialogs

`SettingsView` — swap each presentation (behavior unchanged):
```swift
// before:  .sheet(isPresented: $showingTheme) { AppearanceSheet(onDone: { showingTheme = false }) }
.blurPopup(isPresented: $showingTheme) { AppearanceSheet(onDone: { showingTheme = false }) }
```
…likewise for Export, Report a bug, and Recurring payments (matching each call's existing
arguments / closures).

In each sheet view, **remove the presentation chrome and the own-background** so the
`BlurPopup` card owns the surface:
- `AppearanceSheet`: drop `.presentationDetents([.medium])` and `.background(Palette.card)`;
  keep `.padding(24)`, the cards, and `Done`.
- `ExportSheet`: drop `.onGeometryChange`-driven `.presentationDetents` +
  `.presentationDragIndicator` and `.background(Palette.bg)`; keep the phase content,
  `Export`/`Cancel`/`Done`. (`sheetHeight` state is removed.)
- `BugReportSheet`: same removals; **keep** the nested `.sheet(isPresented: $showingMail)`
  Mail composer (system UI) and the `@Environment(\.dismiss)`-based Cancel — dismissing
  the popup still works because `BlurPopup` reacts to the binding flipping false. (If
  `dismiss()` proves not to flip our binding, switch Cancel to toggle the binding; decide
  in the plan against the call site.)
- `RecurringRulesSheet`: drop its detents + own background; keep its list/controls.

Because the card hugs its content and rises with the keyboard, the manual content-hugging
detent (`onGeometryChange` + `sheetHeight`) is no longer needed and is removed.

## Testing

Pure presentation — `#Preview` + simulator (no unit tests; nothing testable in business
logic changes). Verify against the handoff screenshots, light + dark:
- opening each of the four dialogs **blurs the screen** and slides an opaque card up;
  closing reverses;
- **tap the blurred area** dismisses; **drag the card down** dismisses (short drag springs
  back); the existing **Done/Cancel** dismiss;
- **Report a bug:** focusing the text editor raises the card above the keyboard; the Mail
  composer still opens (as a normal system sheet) and sending/cancelling returns cleanly;
- **Export:** range pickers, the running/success/error phases, and Open-in-Sheets all
  still work inside the card;
- no behavior change to theme writing, export, bug send, or recurring rules.

## Scope

Presentation only: one new `BlurPopup.swift` + `SettingsView` swaps + chrome/background
removal in the four sheet views. One PR on `feature/dialog-popups`. B2 (pushed→popup) and
Cleanup C (content restyle) are separate PRs.
