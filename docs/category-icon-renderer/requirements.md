# Category Icon Renderer (Emoji icons PR1) — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-21

Groundwork for emoji category icons: give `ExpenseCategory` an optional `emoji`, add a
reusable `CategoryIconView` that renders the emoji (if set) or the SF Symbol, and adopt it
at every category icon surface. **Invisible refactor** — all categories still render their
SF glyphs; nothing sets `emoji` yet.

Branch: `feature/category-icon-renderer`, off `main`. One PR.

> PR1 of the emoji-icons feature. **PR2** (separate cycle) adds the Add/Edit category
> form's Icons/Emoji toggle + curated emoji grid + free emoji field, and wires
> `CategoryActions`/the form to set `emoji`.

## User-visible outcome

None in PR1 (pure groundwork). Every existing category renders exactly as before; existing
data loads unchanged after the model gains the new field.

## In scope

1. **Model** — `ExpenseCategory` gains `var emoji: String = ""` and an `emoji: String = ""`
   init parameter. Non-empty `emoji` ⇒ render the emoji; empty ⇒ render `symbolName`
   (today's behavior). Additive, non-optional, defaulted — mirrors the existing
   `budget: Decimal = 0`, so SwiftData lightweight-migrates existing rows to `emoji == ""`.
2. **`CategoryIconView`** (new, `Views/Common/CategoryIconView.swift`) — renders
   `Text(emoji)` if the category has one, else `Image(systemName: symbolName ?? fallback)`.
   Callers style it (`.font` / `.foregroundStyle` / `.frame` / `.background`); the tint
   applies to the SF Symbol and is harmlessly ignored by emoji.
3. **Adopt at all 8 render sites** — replace `Image(systemName: …symbolName)` (incl. the
   `?? "…"` fallback forms) with `CategoryIconView(category:fallbackSymbol:)`, preserving
   each site's surrounding modifiers: TxRow (`questionmark`), EntryView selected-row
   (`square.grid.2x2`), CategoryPickerSheet, RecurringRulesSheet
   (`arrow.triangle.2.circlepath`), BudgetView, ManageCategoriesView, ReassignCategorySheet,
   CategoryBudgetSheet.

## Out of scope (PR2)

- The Add/Edit category form's Icons/Emoji toggle, curated emoji grid, and free emoji field.
- `CategoryActions.add/update` gaining an `emoji` parameter, and the form setting `emoji`.
- `CategoryFormView`'s SF-glyph grid (`Image(systemName: symbol)` at line ~95) — that's the
  picker, not a category render; untouched in PR1.
- Any default-category emoji (Seed/DefaultData stays SF glyphs).

## Key decisions (with rationale)

1. **Presence-as-discriminator (`emoji: String = ""`)** — no separate type flag; the field's
   emptiness says whether to use the emoji or the glyph. Simplest model + cleanest migration.
2. **Non-optional defaulted field** — matches the proven `budget` pattern; optional values
   are the SwiftData crash risk (see the project's SwiftData gotchas), so we avoid them.
3. **One `CategoryIconView`** — DRYs eight near-identical render sites and is the single
   place PR2's emoji rendering already flows through, so PR2 only touches the editor.
4. **Ship the refactor first** — PR1 is behavior-neutral and low-risk (the migration lands
   isolated); PR2 then only adds the editor UI.
