# Dialog Popups (Cleanup B1) — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-21

Build a reusable **blurred bottom-popup** presentation that matches the handoff `Dialog`
(opaque card sliding up over a blurred scrim), and adopt it for the four Settings
dialogs that are already card-style: **Theme, Export, Report a bug, Recurring payments**.
Pure presentation — what each dialog *does* is unchanged.

> B1 is the first of two Cleanup B slices. B2 (separate PR) converts the four
> pushed/Form dialogs — Currency, Set budget, Manage categories, Add category — to the
> same component. Deep per-dialog content restyle is **Cleanup C**.

## User-visible outcome

Opening Theme / Export / Report a bug / Recurring no longer dims-and-scales the screen
behind a system sheet. Instead the screen **blurs** and an opaque rounded card **slides
up** from the bottom — the handoff look. The card is dismissible by tapping the blurred
area, dragging it down, or its existing Done/Cancel button. The Report-a-bug text editor
pushes the card up when the keyboard appears; the card returns when it dismisses.

## In scope

- **`BlurPopup` component** — a reusable `.blurPopup(isPresented:onDismiss:) { card }`
  view modifier:
  - a full-screen `.ultraThinMaterial` backdrop that **blurs the real screen behind it**
    plus a light dim (~`Color.black.opacity(0.18)`), matching the handoff
    `blur(2px) + 32% black` scrim;
  - an opaque `Palette.card` container, corner radius **26**, pinned to the bottom with
    side + bottom padding, holding the caller's content;
  - **enter:** scrim fades in, card slides up (offset → 0) + fades; **exit:** reverse;
  - **dismiss** via (a) tap on the backdrop, (b) **drag the card down** past a threshold,
    (c) the caller's own buttons toggling the binding;
  - **keyboard:** the bottom-pinned card rises with the keyboard (no
    `ignoresSafeArea(.keyboard)`); tall content scrolls inside the card.
- **Adopt for four dialogs** — replace each `.sheet(isPresented:)` in `SettingsView`
  with `.blurPopup(isPresented:)`; in each sheet view drop `.presentationDetents` /
  `.presentationDragIndicator` and stop drawing its own full-screen background (the
  `BlurPopup` card now provides it). Keep each view's content, controls, and behavior.

## Out of scope

- The four pushed/Form dialogs (Currency, Set budget, Manage categories, Add category) —
  that is **B2**.
- Any content restyle (flags, tiles, field styling, Done/× chrome) — that is **Cleanup C**.
- Behavior changes to export, theme writing, bug-report sending, or recurring rules.
- The nested **Mail composer** inside Report-a-bug stays a real system `.sheet` (system
  UI; no blur), as does any other genuinely system-provided sheet (e.g. PhotosPicker).

## The handoff Dialog (source of truth)

From `design_handoff_plop` `dialogs.jsx` / `Expense Tracker.html`: a bottom-anchored card
(`max-width 320`, radius 26, padding 22) sliding up over a scrim that combines
`backdrop-filter: blur(2px)` with ~32% black, tap-scrim to dismiss.

## Key decisions (with rationale)

1. **Faithful blur via `fullScreenCover` + `.presentationBackground(.clear)`** — the
   transparent cover lets the real screen show through so the in-cover `.ultraThinMaterial`
   actually blurs it, while still giving a real presentation context (keyboard avoidance,
   state-driven dismiss). Chosen over a plain `.sheet` (no background blur) and over
   `.presentationBackground(.ultraThinMaterial)` (blurs the card itself — wrong look,
   hurts readability).
2. **Convert all dialogs to the popup** (across B1 + B2) — the user wants every Settings
   option to read as the handoff's blurred popup; consistency over per-screen iOS norms.
3. **Drag-to-dismiss included** — feels native and matches the sheet affordance users
   expect from a bottom card.
4. **One reusable component** — a single `BlurPopup` keeps all dialogs consistent and
   isolates the fiddly transition/keyboard handling in one place.
5. **Presentation only in B/B1** — content and behavior untouched, keeping the slice
   low-risk and reviewable; visual content restyle is deferred to Cleanup C.
