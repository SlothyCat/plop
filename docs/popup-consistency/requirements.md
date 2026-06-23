# Popup Consistency — Requirements

Status: Approved (brainstorm/audit complete) · Date: 2026-06-23

Bring every remaining bottom-popup in the app onto the shared `BlurPopup` standard
(top-right × from `BlurPopup`, `PopupPrimaryButton` for the primary action, live theme),
matching the Settings popups. Audit found these still using plain `.sheet`:

- **`CategoryBudgetSheet`** (Insights → tap a Budget legend row) — old blue "Save budget" +
  "Cancel", no ×. *(reported)*
- **Entry popups** (4): New category (`CategoryFormView`), Category picker
  (`CategoryPickerSheet`), the date "when" sheet (`WhenSheet`), Recurring (`RecurringSheet`).

Also fixes a **bug**: `CategoryFormView` dismisses via `\.blurPopupClose`, but Entry presents
it as a `.sheet`, so **Save/Cancel don't close it** there (close() is a no-op in a `.sheet`).

Correctly left as plain presentations: the **Mail composer** (system UI) and the full-screen
**Entry / edit pages** (`fullScreenCover` — pages, not popups).

## Decomposition

- **PR1 — `CategoryBudgetSheet`** → `BlurPopup` (the reported one; small, self-contained).
- **PR2 — Entry popups** → `BlurPopup` (New category, picker, when, recurring; fixes the
  dismiss bug).

## User-visible outcome

Every popup looks/behaves like the Settings ones: slides up over a blurred + themed scrim,
has a **top-right ×**, primary buttons match **Save budget / Save**, and dismiss the same way
(× / drag / primary action). Entry's "New category" closes on Save/Cancel.

## In scope

**PR1 (`CategoryBudgetSheet`):**
- Present via `.blurPopup(item:)` in `InsightsView` (was `.sheet(item:)`).
- Use `\.blurPopupClose` (drop the `onDone` closure); remove "Cancel"; "Save budget" →
  `PopupPrimaryButton`; drop `.presentationDetents`, own `.background`, trailing `Spacer`.

**PR2 (Entry):**
- **New category:** present `CategoryFormView` via `.blurPopup(isPresented:)` (fixes dismiss;
  gets × / theme). No change to `CategoryFormView`.
- **Category picker / When / Recurring:** present via `.blurPopup`; drop each sheet's
  **grabber** + `.presentationDetents`; dismiss/select via `\.blurPopupClose` (animated);
  list/grid content that scrolls uses `tall:` + a capped `ScrollView` (no lazy-in-hug).
- Primary affordances styled consistently (the picker's "New category" dashed button and the
  When/Recurring rows keep their look; any full-width primary uses `PopupPrimaryButton`).

## Out of scope

- The Mail composer and the Entry/edit `fullScreenCover` pages.
- Redesigning the popups' content beyond the standard chrome (×, button style, theme).
- The donut/settings-title/roadmap fixes (separate open PRs).

## Key decisions (with rationale)

1. **Everything through `BlurPopup`** — one source of × + theme + slide; removes per-popup
   grabbers/detents/Done-Cancel; matches the Settings standard the user set.
2. **`\.blurPopupClose` for dismissal** — so the slide-out animates (setting the bound flag
   directly tears down instantly); selection actions set their binding then call `close()`.
3. **Fix the Entry New-category dismiss bug by converting it** — the view already expects
   `\.blurPopupClose`; presenting it via `BlurPopup` supplies it.
4. **Two PRs** — PR1 (Insights) is the reported, low-risk one; PR2 (Entry) is larger and
   touches the picker's select/add-new handoff, so it's isolated.
