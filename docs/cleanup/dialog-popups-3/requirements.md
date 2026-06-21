# Dialog Popups B2b (Manage categories cluster) — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-21

Convert the Manage categories cluster — **Manage categories**, **Add/Edit category**, and
**Reassign-on-delete** — from pushed/`.sheet` screens to **stacked `BlurPopup`s** built to
fully match the handoff screenshots (`category.jpg`, `add_category.jpg`). Adds an optional
**monthly budget** to the add/edit category form. Emoji category icons are **deferred** to
a separate feature.

Branch: `feature/dialog-popups-3`, branched off `feature/dialog-popups-2` (so B1 + B2a are
present); rebased onto `main` after B1 and B2a merge, before its PR.

## User-visible outcome

Tapping **Manage categories** opens a blurred bottom popup (not a pushed screen) listing
category cards (colored tile, name, **$X/mo**, a **trash** button) with a pinned **"+ Add
category"**. Tapping a card opens **Edit category** stacked over it; "+ Add category" opens
**New category**; trashing a category with transactions opens **Reassign** stacked over it.
The add/edit form can set an optional **monthly budget**. Delete safeguards (keep at least
one category; reassign transactions) are unchanged.

## In scope

- **`BlurPopup` item overload** — add `blurPopup(item:tall:onDismiss:){ item in … }`
  (mirrors `.sheet(item:)`) so Edit and Reassign can present a specific category;
  `close()` / `\.blurPopupClose` clear the item. (B1's `isPresented`/`tall` overloads and
  all existing call sites are unchanged.)
- **Manage categories → blur popup (tall), matching `category.jpg`** — header "Categories"
  + round **× close**; subtitle "Tap a category to edit it, or remove ones you don't use.";
  scrolling **category cards** (38px colored tile + name + **"$X/mo"** / "No budget" +
  right-side **trash**); pinned **"+ Add category"**. Tap card → edit; trash → existing
  delete flow.
- **Add/Edit category → stacked blur popup (hug), matching `add_category.jpg`** — header +
  subtitle; NAME; ICON (SF-glyph grid, **Icons only**); COLOR swatches + custom-color well;
  **"MONTHLY BUDGET · OPTIONAL"** $-prefixed field; Save (disabled until name valid) +
  Cancel.
- **Reassign → stacked blur popup (tall)** — header "Delete <name>" + "Move N
  transactions… to:"; target rows; Cancel.
- **`CategoryActions.add`/`update` gain `budget: Decimal = 0`** (TDD).
- **SettingsView** — Manage categories row `NavigationLink` → `Button` +
  `.blurPopup(tall: true)`. The `NavigationStack` stays (it hosts the "Settings" title).

## Out of scope

- **Emoji category icons** (the handoff Icons/Emoji toggle) — deferred to its own feature:
  it is a SwiftData model change plus a rendering change everywhere categories appear, and a
  no-emoji-rule decision. B2b keeps SF-glyph icons only.
- Currency / Set budget (B2a) and the four B1 dialogs.
- Any change to delete / reassign / last-category logic, name validation, or icon/color
  options (presentation + the new budget field only).

## Key decisions (with rationale)

1. **Stacked blur popups** — Add/Edit and Reassign present over the (blurred) Manage popup,
   matching the handoff where every option is a popup; consistent with B1/B2a.
2. **Item-based `blurPopup` overload** — Edit/Reassign need a specific category; an
   `item:` overload mirrors the existing `.sheet(item:)` pattern cleanly.
3. **Include the monthly-budget field** — small TDD'd `CategoryActions` change; makes the
   Manage list's "$X/mo" meaningful at create time and matches the handoff form.
4. **Defer emoji icons** — cross-cutting model + rendering feature, out of place in a dialog
   conversion; keeps B2b reviewable.
5. **Inline trash (not swipe)** — the handoff shows a trash button per row; it routes to the
   same `requestDelete` (last-category alert / reassign / direct delete) as today.
6. **Manage + Reassign `tall`, Add/Edit hug** — list dialogs scroll within a capped card;
   the form hugs and rises with the keyboard.
