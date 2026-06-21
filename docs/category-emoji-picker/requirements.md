# Category Emoji Picker (Emoji icons PR2) — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-21

Add the Icons/Emoji choice to the Add/Edit category form so a category's icon can be an SF
glyph **or** an emoji — a curated quick-pick grid **plus** a custom input that opens the iOS
emoji keyboard (any system emoji). Wire it through `CategoryActions` to set
`ExpenseCategory.emoji` (the field + the `CategoryIconView` renderer landed in PR1).

Branch: `feature/category-emoji-picker`, off `main`. One PR.

> PR2 of the emoji-icons feature; PR1 (model field + renderer at all surfaces) is merged.

## User-visible outcome

In **New category / Edit category**, the ICON section gains an **Icons / Emoji** toggle.
- **Icons** → the existing SF-glyph grid (unchanged).
- **Emoji** → a curated emoji grid (quick taps) **plus a custom field**: tapping it opens the
  iOS emoji keyboard so the user can pick **any** emoji; the chosen emoji becomes the icon.
Saving stores the emoji (or, in Icons mode, the glyph). The chosen icon then shows on every
category surface (Home, Insights, Budget, Manage, Reassign, Recurring, Entry) via PR1's
`CategoryIconView`. Editing a category prefills its current icon + mode.

## In scope

1. **Curated set** — `categoryEmojiChoices` in `Models/CategoryIcons.swift`: the handoff's 18
   (🎓 🍔 📺 🚗 🏠 ✈️ 🛒 💡 🐶 💪 🎁 💰 ☕ 🎮 👕 💊 🎵 🧾).
2. **`CategoryActions`** (TDD) — `add` gains `emoji: String = ""` (after `symbolName`);
   `update` gains a required `emoji: String`; both assign `category.emoji`.
3. **`CategoryFormView` ICON section** —
   - a header row: "ICON" label + a compact **Icons / Emoji** pill toggle;
   - **Icons mode:** the current eager SF-glyph grid (unchanged);
   - **Emoji mode:** an **eager** curated emoji grid (selected tile fills with the chosen
     color, like the glyph grid) + a **custom emoji field** that focuses the iOS emoji
     keyboard and keeps the last entered emoji (highlighted as selected when it's not one of
     the curated ones);
   - state: `@State emoji` + `iconType` (`.glyph` / `.emoji`); **save** writes
     `emoji = iconType == .emoji ? emoji : ""`; **prefill** sets
     `iconType = editing.emoji.isEmpty ? .glyph : .emoji`; toggling to Emoji with none chosen
     preselects the first curated emoji.
4. **CLAUDE.md** — extend the flag exception to cover **user-chosen category emoji**.

## Out of scope

- Default-category emoji (Seed/DefaultData stays SF glyphs).
- Changing any other category surface (PR1 already routes them through `CategoryIconView`).
- A bespoke in-app emoji browser — iOS has no API to present the emoji keyboard directly;
  the custom field + system emoji keyboard is the platform-standard mechanism.

## Key decisions (with rationale)

1. **Curated grid + custom field** — the grid covers common picks; the focusable field gives
   the user **any** iOS emoji (no public API to show the emoji keyboard otherwise). Matches
   the handoff and the user's "allow custom emoji" ask.
2. **Eager grids** — both the glyph and emoji grids render eagerly (no `LazyVGrid`); a lazy
   grid in the non-scrolling popup card snaps cells to final position on present (the bug we
   just fixed).
3. **`emoji` empty ⇒ glyph** — reuse PR1's presence-as-discriminator; Icons mode clears
   `emoji`, Emoji mode sets it. No new model field/migration.
4. **`CategoryActions` mirrors the budget pattern** — `add` defaulted, `update` required;
   only `CategoryFormView` + tests call them, so blast radius is contained.
