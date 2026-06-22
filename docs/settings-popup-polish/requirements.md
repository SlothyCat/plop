# Settings Popup Polish (PR A) — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-22

A batch of Settings-popup fixes from field notes: a standard **× close** on every popup,
popups that **follow the theme** live, and a fully-tappable **currency row**. Plus a
simulator re-check of the Save-budget button.

Branch: `feature/settings-popup-polish`, off `main`. One PR.

## User-visible outcome

- Every Settings popup has a **× in the top-right** to exit; the redundant bottom
  **Done/Cancel** buttons are gone (primary actions like Save / Export / Send stay).
- Toggling **Theme** (or having a non-Automatic theme) is reflected **inside the popups**
  immediately — popups are no longer stuck in the system appearance.
- Tapping **anywhere on a currency row** selects it.

## In scope

1. **Auto × close in `BlurPopup`** (#5) — `BlurPopup` overlays a top-right × on the card
   that calls `\.blurPopupClose`; so every settings popup gets a consistent exit control.
2. **Remove redundant dismiss buttons** (#5) — drop the per-popup Done/Cancel that only
   dismissed: Currency `doneBar`, Appearance "Done", Recurring `doneBar`, Set budget
   "Cancel", Export "Cancel" (form) + "Done" (success), Report a bug "Cancel" (form) +
   "Done" (no-mail fallback), Add/Edit category "Cancel", Reassign "Cancel", and Manage
   categories' hand-rolled header ×. **Keep primary actions:** Save budget, Export / Open in
   Sheets, Send / Copy report, Save (category).
3. **Theme in popups** (#4) — `BlurPopup` applies
   `.preferredColorScheme(themeMode.colorScheme)` (from `@AppStorage(themeModeKey)`) so
   popup content matches the chosen theme and updates live (fullScreenCover doesn't inherit
   the app's `preferredColorScheme`).
4. **Currency row tap target** (#1) — add `.contentShape(Rectangle())` to the currency row
   so the whole row (not just the opaque bits) registers the tap.
5. **Verify #2** — re-check in the simulator that the **Save budget** button is tappable
   promptly (no `disabled` gating exists in code; suspected to be just the slide-in). Fix
   only if a real delay is observed.

## Out of scope

- The Breakdown/Budget donut small-slice fix (#3) — separate PR B.
- The Entry category picker (a system `.sheet`, not a `BlurPopup`) and any non-settings UI.
- Changing popup headers/content beyond removing the dismiss buttons + adding the ×.

## Key decisions (with rationale)

1. **× lives in `BlurPopup`, not each popup** — one overlay gives every settings popup the
   same exit affordance and removes per-popup boilerplate; matches the user's "standardise"
   ask. Manage's bespoke × is removed in favour of it.
2. **× replaces dismiss-only buttons; primary actions stay** (user's choice) — no duplicate
   dismiss controls; Save/Export/Send remain where the user must act.
3. **Theme fix in `BlurPopup`** — the popups are the only views that miss the app's
   `preferredColorScheme`; applying it once in the shared container fixes all of them.
4. **`contentShape` for the currency row** — guarantees the full row is hit-testable
   regardless of transparent regions.
