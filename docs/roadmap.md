# plop — Roadmap

Overall feature sequencing. Each feature ran the full loop: brainstorm → spec → plan →
PRs. `main` always builds; one branch + PR per slice.

## Status

**All planned features shipped** (on `main`), plus a fidelity cleanup pass and a batch of
field-note fixes. Remaining work is pre-submission setup, not features (see "Before App
Store").

- **Project init** — done (`.gitignore`, CI, SwiftLint, `CLAUDE.md`, design handoff).
- **Feature 1 — Home + Entry** — done (`docs/home-entry/`).
- **Feature 2 — Recurring payments (engine)** — done (`docs/recurring/`).
- **Feature 3 — Insights tab** — done (`docs/insights/`, `docs/insights-budget/`).
- **Feature 4 — Settings cluster** — done: categories (`docs/settings-categories/`),
  currency (`docs/settings-currency/`), theme (`docs/settings-theme/`), set budget
  (`docs/settings-budget/`), export (`docs/settings-export/`), report a bug
  (`docs/settings-bug-report/`), plus the Settings restyle (`docs/settings-restyle/`).
- **Feature 5 — Dialogs polish** — done.

## Cleanup & polish (post-feature)

The `design_handoff_plop` fidelity audit (`docs/cleanup/fidelity-audit.md`) and follow-ups,
all merged:

- **A — Settings restyle** ✅ (`docs/settings-restyle/`)
- **D — Tab bar fidelity** ✅ (`docs/cleanup/tab-bar/`)
- **B — Blurred bottom popups** ✅ — reusable `BlurPopup` + adoption across every Settings
  dialog (`docs/cleanup/dialog-popups{,-2,-3}/`).
- **C — Per-dialog restyle** ✅ — folded into B2a (currency flags + filled row + bottom done;
  budget tiles/$-fields/total card), B2b (category tiles, $X/mo, inline trash, Add button),
  and the emoji feature (add-category emoji + custom color + monthly-budget field).
- **E — Polish** ✅ (`docs/cleanup/insights-polish/`) — net-total gray "$" prefix; Insights
  Breakdown/Budget toggle kept (intentional); ring spacing; dark arc outlines.

**Extras beyond the original audit (merged):**
- **Emoji category icons** — `CategoryIconView` everywhere + Icons/Emoji picker with curated
  + custom emoji (`docs/category-icon-renderer/`, `docs/category-emoji-picker/`).
- **Settings popup polish** — standard top-right × on every popup, popups follow the theme
  live, full-row taps (currency + Settings rows), unified primary buttons
  (`docs/settings-popup-polish/`).
- **Donut minimum arc** — tiny categories keep a visible sliver (`docs/donut-min-arc/`).

## Versioning

- `MARKETING_VERSION` = **1.0.0** (the Settings version footer reads from
  `CFBundleShortVersionString`).

## Before App Store (not features — pre-submission setup)

- **Rename the `plop` placeholder** — scheme, Bundle ID, and the `ci.yml` env values
  (per CLAUDE.md) before submission.
- **OAuth client config** — real client ID in the git-ignored `Secrets.xcconfig` (PKCE, no
  client secret) for Google Sheets export.
- **App assets** — app icon, launch screen, App Store screenshots/metadata.

## Conventions

- One feature branch per slice; PR per slice; review the diff before merge.
- No git worktrees (they break the open Xcode project) — sequential, current session.
- Build to handoff fidelity: compare against `design_handoff_plop/screenshots/*` while
  building (see CLAUDE.md).
