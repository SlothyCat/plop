# Dialog Popups B2a (Currency + Set budget) — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-21

Convert the two **standalone pushed** Settings screens — **Currency** and **Set budget** —
from `NavigationLink` push to the `BlurPopup` (built in B1). Add a small `tall` option to
`BlurPopup` so list/form content gets a height-capped, scrolling card. Presentation only —
what each screen *does* is unchanged.

> B2a is the first half of Cleanup B2. **B2b** (separate cycle/PR) converts the Manage
> categories cluster (Add/Edit category + Reassign-on-delete) using stacked blur popups.
> Deep per-screen content restyle (currency flags + filled-selected row + bottom Done,
> budget tiles, etc.) is **Cleanup C** — out of scope here.

Branch: `feature/dialog-popups-2`, branched off `feature/dialog-popups` so `BlurPopup`
is present; **rebased onto `main` once B1 (PR for `feature/dialog-popups`) merges**.

## User-visible outcome

Tapping **Currency** or **Set budget** in Settings no longer pushes a full screen — the
screen blurs and a tall opaque card slides up (the handoff look), dismissible by tapping
the blurred area, dragging down, or **Done**. Currency selection still writes live; the
budget fields still save; the budget's decimal keyboard raises the card.

## In scope

- **`BlurPopup` `tall` option** — add `tall: Bool = false` to the `.blurPopup(...)`
  modifier. When `true`, the card is capped at ~80% of the available height (via a
  `GeometryReader`) so `List`/`Form` content scrolls inside; when `false` the B1
  hug-to-content behavior is unchanged.
- **Currency → blur popup** — `CurrencyView` gains a fixed header (`Text("Currency")` +
  a `Done` button calling `\.blurPopupClose`) above its existing `List`; drop
  `.navigationTitle`. `SettingsView`'s Currency row changes from `NavigationLink` to a
  `Button` + `.blurPopup(isPresented:tall: true)`.
- **Set budget → blur popup** — `BudgetView` gains the same header (`Text("Set budget")`
  + `Done`) above its existing `List`; drop `.navigationTitle`. The segmented mode picker,
  amount fields, live total footer, and the existing **"Save budget"** button are all kept
  (Save persists as today; Done closes). `SettingsView`'s Budget row becomes a `Button` +
  `.blurPopup(isPresented:tall: true)`.

## Out of scope

- **Manage categories / Add category / Reassign** — that is **B2b**. Its row stays a
  `NavigationLink` here, so `SettingsView` keeps its `NavigationStack`.
- **Content restyle** — currency flags, per-row cards, accent-filled selected row, the
  subtitle line, moving Done to a centered bottom button; budget tiles / field styling.
  All **Cleanup C**.
- Any change to currency persistence, budget save logic, or the money formatting.

## Key decisions (with rationale)

1. **`tall` option on `BlurPopup`** (not per-screen height hacks) — `List`/`Form` lack an
   intrinsic height, so a height cap belongs in the reusable component; keeps both screens
   consistent and leaves B1's hugging dialogs untouched.
2. **Minimal header now, restyle in C** — a working title + `Done` is enough to convert
   presentation; matching the handoff (bottom centered Done, flags, filled rows) is content
   restyle and is deferred so we don't do the chrome twice.
3. **Keep `tall: true` for both** — Currency is inherently long; Budget's by-category mode
   grows with categories. A consistent tall, scrolling card matches the handoff Currency
   screenshot and avoids mode-dependent resizing.
4. **Presentation only** — no logic change keeps the slice low-risk and reviewable; no unit
   tests (views are verified via preview + simulator, per project convention).
