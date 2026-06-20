# Settings Restyle (Cleanup A) — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-19

A visual-fidelity pass on the Settings screen to match the design handoff: colored
icon tiles, the handoff's grouping + custom section labels, consistent row alignment,
and a version footer. **Pure visual** — no change to what any row does (push vs sheet)
or to the presentation/blur (that's a separate Cleanup B).

## User-visible outcome

Settings looks like the handoff: each row has a colored icon tile, rows align cleanly
(tile · label · value · chevron), groups read DATA / PREFERENCES / RECURRING / SUPPORT,
and a centered "Version x.y.z" sits at the bottom.

## In scope

- A reusable `SettingsRow` (tile + label + optional value + chevron) used by every row
  so columns align identically (fixes the current alignment drift).
- Per-row colored tiles (30×30, radius 9, `tileInk` glyph) with the handoff palette.
- Grouping into **DATA**, **PREFERENCES**, **RECURRING**, **SUPPORT** with custom
  uppercase section labels (12.5, letter-spaced, ink40); Export moves to **DATA**.
- A centered version footer read dynamically from the bundle
  (`CFBundleShortVersionString`).
- A manual one-field Xcode step: set `MARKETING_VERSION = 1.0.0` so the dynamic footer
  reads "Version 1.0.0".

## Out of scope (Cleanup B / later)

- Converting pushed screens (Set budget, Manage categories, Currency) to popups.
- The blurred-scrim popup presentation.
- Any change to row tap behavior, the destination screens/sheets, or their internals.

## Grouping + per-row mapping

| Group | Row | Behavior (unchanged) | Tile | Icon |
|---|---|---|---|---|
| DATA | Export to Google Sheets | sheet | accent | square.and.arrow.up |
| PREFERENCES | Set budget | push | accent | chart.pie.fill |
| PREFERENCES | Manage categories | push | accentSoft | tag.fill |
| PREFERENCES | Currency | push | cream | dollarsign.circle.fill |
| PREFERENCES | Theme | sheet | yellow | circle.lefthalf.filled |
| RECURRING | Recurring payments | sheet | accentSoft | arrow.triangle.2.circlepath |
| SUPPORT | Report a bug | sheet | accentSoft | ladybug.fill |

(Values shown as today: Set budget → budget total, Currency → code, Theme → mode.)

## Key decisions (with rationale)

1. **Reusable `SettingsRow`** — one row layout = consistent alignment; the fixed-width
   tile is what makes labels/values line up.
2. **Tiles fixed in light & dark** (`tileInk` charcoal glyph on brand pastels) —
   matches the Theme decision; pastels read in both schemes.
3. **Recurring gets its own group** — it's payment automation, distinct from app
   preferences and support.
4. **Dynamic version + bump to 1.0.0** — footer stays accurate across releases with no
   code edits; one Xcode field change yields the handoff's "1.0.0".
5. **Visual only** — push-vs-popup and the blur are Cleanup B; this PR must not change
   any behavior, so it's low-risk.
