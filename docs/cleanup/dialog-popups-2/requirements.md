# Dialog Popups B2a (Currency + Set budget) — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-21

Convert the two **standalone pushed** Settings screens — **Currency** and **Set budget** —
from `NavigationLink` push to the `BlurPopup` (built in B1), **built to fully match their
handoff screenshots** (`currency.jpg`, `budget.jpg`) in one pass. Add a small `tall`
option to `BlurPopup` so the content gets a height-capped, scrolling card. The screens'
*behavior* (currency write, budget save) is unchanged; their *layout* is rebuilt to match.

> **Scope change (2026-06-21):** originally B2a was presentation-only with a deferred
> "Cleanup C" restyle. Per the user, that produced popups that diverged too much from the
> handoff, so the visual restyle is **folded in here** — each screen lands matching its
> screenshot. There is no separate Cleanup C for these two.
>
> B2b (separate cycle/PR) still covers the Manage categories cluster (Add/Edit category +
> Reassign), also to full handoff fidelity.

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
- **Currency → blur popup, matching `currency.jpg`** — title + subtitle header; a
  scrolling list of **row-cards** each showing a **flag emoji** tile, code, and full name;
  the **selected row filled `Palette.accent`** with a checkmark; a **"Done" pinned at the
  bottom**, centered. Adds a `currencyFlag(_:)` helper (unit-tested). `SettingsView`'s
  Currency row → `Button` + `.blurPopup(isPresented:tall: true)`.
- **Set budget → blur popup, matching `budget.jpg`** — accent icon-tile + title header;
  styled segmented Total / By category with a per-mode subtitle; **category rows** with a
  colored tile + name + a **$-prefixed field card**; a **"Total monthly budget" card**; a
  full-width prominent **"Save budget"** button; a **"Cancel"** centered below. Save
  persists as today. `SettingsView`'s Budget row → `Button` + `.blurPopup(tall: true)`.
- **Currency flag emoji** — the one sanctioned emoji exception (now in CLAUDE.md).

## Out of scope

- **Manage categories / Add category / Reassign** — that is **B2b**. Its row stays a
  `NavigationLink` here, so `SettingsView` keeps its `NavigationStack`.
- Any change to currency persistence, budget save logic, or the money formatting (layout
  only).

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
