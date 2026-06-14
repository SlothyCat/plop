# Category Management — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-14 · First Settings sub-feature.

## Purpose

Let the user manage their categories (add / edit / delete) from a real Settings tab,
and re-enable the "New category" shortcut in Entry. Establishes the Settings list shell
that later sub-features (currency, theme, budget, export, bug report) will extend.

Design source: `design_handoff_plop/README.md` (Settings), `app/settings.jsx`,
`app/dialogs.jsx` (ManageCategoriesDialog, AddCategoryDialog).

## In scope

- **Settings shell**: grouped list in a `NavigationStack`, with a single working row —
  **Manage categories** (other rows arrive with their features).
- **Manage Categories** screen: list of categories; add, edit, delete.
- **Add/Edit Category** form (sheet): name, **SF Symbol** icon (curated grid), color
  (4 palette swatches + a custom `ColorPicker`).
- **Delete → reassign**: deleting a category with transactions prompts to move them to
  another category, then deletes; empty categories delete immediately.
- **Unique, non-empty name** validation.
- **Re-enable Entry's "New category"** → opens the Add Category sheet; the new category
  is selected on save.

## Out of scope (deferred)

- **Budget** field/flow → the **Set budget** sub-feature (next). Category form is
  name/icon/color only.
- Other Settings rows (Currency, Theme, Export, Report a bug) → their own sub-features.
- **Emoji** category icons (SF Symbols only for now).

## Key decisions (with rationale)

1. **Delete prompts to reassign** transactions to another category (empty categories
   delete immediately). Preserves the "every transaction has a category" invariant from
   the require-category change. **The last remaining category cannot be deleted** (need a
   reassign target, and entry requires a category).
2. **Unique category names** (case-insensitive, trimmed). Insights buckets spend **by
   category name**, so duplicates would silently merge — uniqueness avoids that.
3. **SF Symbols** icon grid (curated list); **swatches + `ColorPicker`** for color.
4. **NavigationStack + sheets** (the handoff "dialogs" map to iOS sheets).
5. **Settings shell shows only built rows** (just Manage categories now) — no dead
   placeholders.

## Behavioral requirements & edge cases

- Save disabled until the name is non-empty and unique (edit allows keeping its own name).
- Delete: empty → confirm + delete; in-use → reassign sheet (pick target) → move + delete.
- Only one category exists → its delete is blocked with a brief explanation.
- Entry "New category": opens the add sheet; on save, the created category becomes the
  selected category for the transaction being entered.
- All CRUD flows through `CategoryActions`; Manage Categories reads via `@Query` and
  updates live.

## Success criteria

- From Settings → Manage categories, the user can add, rename/recolor/re-icon, and delete
  categories; deleting an in-use category moves its transactions to a chosen category.
- Entry's "New category" creates and selects a category inline.
- Duplicate/empty names are rejected.
- `CategoryActions` + name validation are unit-tested (green in CI); screens verified via
  `#Preview` and the simulator.
