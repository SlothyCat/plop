# Entry "Cash Register" Redesign — Design

Status: Approved · Date: 2026-07-04

## Goal

Reskin the add/edit Entry screen to match the new handoff
(`design_handoff_plop/Entry - Cash Register.html` + `screenshots/add_entry_cashier_register.jpg`):
a skeuomorphic blue "cash-register LCD" display replaces the plain `$0.00` area, with a more
tactile keypad/pills and a "Plop CASHIER" footer. **Presentation only** — all behaviour (amount
entry, category/date/recurring pickers, validation, haptics, save/delete) is reused unchanged.

## Decisions (approved)

1. **Full-screen reskin** — register card + tactile keypad/pills + footer, matching the mockup.
2. **Amount stays SF (monospaced-bold), no bundled font.** The handoff uses a 7-segment font
   (DSEG7); we deliberately **diverge** to keep the app font-asset-free. Documented divergence
   from the handoff (per the "flag, don't silently diverge" rule — this one is flagged + chosen).
3. **Dark-mode variant** of the register card (the handoff is light-only) — colors below.

## Component: `RegisterDisplay` (new)

`plop/plop/Views/Entry/RegisterDisplay.swift` — a self-contained LCD card, so `EntryView` stays
readable. Inputs it needs (passed from `EntryView`): the transaction `type`, the formatted amount
string, the currency symbol, the selected category (name + optional), the date, and the
`amountInvalid` flag (for the red state).

Layout (a beveled "case" frame around a glass panel):
- **Top-left status:** `● DEBIT · OUT` (Expense) or `● CREDIT · IN` (Income) — exact strings from
  the handoff (`income ? 'CREDIT · IN' : 'DEBIT · OUT'`). Uppercase, tracked. The leading dot is
  the type color: expense → `Palette.ink`, income → `Palette.incomeGreen`.
- **Top-right:** category name uppercased (e.g. `GROCERIES`), or `NO CATEGORY` when none.
- **Amount (center-right, large):** `$` (SF) + digits (SF, `.monospacedDigit()`, bold),
  right-aligned, in the LCD-ink color; turns `Palette.danger` when `amountInvalid`.
- **Bottom-left:** `TODAY · 10:58 PM` (or the weekday/date for other days) — uppercase, small,
  LCD-ink at reduced opacity.

## Palette tokens (new, dynamic light/dark)

Add to `Palette` (mirroring the `Color.dynamic(light, dark)` pattern):
- `lcdGlassTop` — light `#C6DEF1`, dark `#1B3A52`
- `lcdGlassBottom` — light `#C7DCEE`, dark `#14314A`
- `lcdInk` — light `#173A57`, dark `#BFE0F5`
- `lcdCaseTop` — light `#C6CED5`, dark `#2A3A47`
- `lcdCaseBottom` — light `#A7B2BB`, dark `#1C2833`

The glass is a vertical gradient `lcdGlassTop → lcdGlassBottom`; the case frame a gradient
`lcdCaseTop → lcdCaseBottom` with a subtle inner bevel. A faint top highlight
(`rgba(255,255,255,0.28)`) on the glass sells the "lit LCD" look.

## EntryView layout changes

Reorder/​restyle `EntryView`'s body to match the mockup (top → bottom):
1. **Header** — unchanged behaviour: × (left), Expense/Income `SegmentedToggle` (center),
   recurring icon (right). Buttons keep the existing rounded-card style.
2. **`RegisterDisplay`** — replaces the current `amountArea` amount block.
3. **Note + backspace row** — full-width "Add Note" field with a leading lines icon
   (`line.3.horizontal`) and the backspace as a **separate** rounded button to its right (today
   they're overlaid). Note binding unchanged.
4. **Detail pills** — date pill (left) + category pill (right: colored dot + `square.grid.2x2`
   + name), restyled to the tactile card look; existing tap actions unchanged.
5. **Keypad** — restyled tactile keys (see below).
6. **Footer** — `Plop` (bold) + `CASHIER` (tracked, `Palette.ink40`) with thin side rules,
   centered.

When `recurrence != .none`, keep the small "Repeats <summary>" line directly under the card
(unchanged behaviour, tap reopens the recurring sheet).

## Keypad restyle

`Keypad.swift`: keep the grid, keys, and always-active confirm (from the invalid-feedback work).
Restyle only: white rounded key cards (radius ~18), a stronger tactile shadow
(`0 1px 4px rgba(0,0,0,0.12)` per the handoff), and the blue ✓ confirm key on `Palette.accent`.
No change to `onKey`/`onConfirm`/accessibility identifiers.

## Validation (preserved, re-placed)

The invalid-save feedback from the invalid-feedback feature stays, adapted to the new layout:
- Error haptic on an invalid confirm (unchanged).
- **Amount turns `Palette.danger` inside the card** (via `amountInvalid` passed to
  `RegisterDisplay`).
- **Category pill turns red** (`categoryInvalid`).
- The **caption** ("Enter an amount and pick a category" etc.) shows directly under the card.

## Testing

- **No new unit tests** — a view-layer reskin with zero logic change (project convention: views
  via preview/sim, logic via XCTest). `AmountInput`/formatting/actions are untouched.
- Existing **188 tests** stay green; `xcodebuild build` succeeds; SwiftLint at baseline (19/0).
- **Sim check, light + dark** (read `add_entry_cashier_register.jpg` again when verifying):
  the register card renders (DEBIT·OUT / CREDIT·IN, category, SF amount, TODAY·time), the note
  row/pills/keypad/footer match, typing updates the LCD amount, Expense/Income flips the status,
  invalid save shows the red amount + red pill + caption + error buzz, and save/delete work.

## Scope

**In:** new `RegisterDisplay` view; `Palette` LCD tokens (light+dark); `EntryView` layout
restyle (register card, note/backspace row, pills, footer, validation re-placement); `Keypad`
restyle. **Out:** the DSEG7 segmented font; any behaviour/logic change; other screens; the
`.mov` handoff recording (reference only).

**Divergence from handoff (flagged + approved):** amount digits use SF, not the DSEG7 7-segment
font — so the digits read as normal numerals inside the register layout, not segmented glyphs.

Single PR: `feature/entry-cash-register`.
