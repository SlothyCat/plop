# App Icon (PR1) — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-22

Ship the app icon from the handoff (`design_handoff_plop/logo/plop-icon.svg`): a
cream-gradient squircle with the blue "plop" wordmark + ripple rings. Wire it into the
(currently empty) `AppIcon.appiconset` as a single universal 1024 image.

Branch: `feature/app-icon`, off `main`. One PR.

> PR1 of the icon+launch work. PR2 (launch screen) is separate.

## User-visible outcome

The app shows the plop icon on the home screen / app switcher / Settings, instead of the
blank placeholder.

## In scope

1. **Render a 1024×1024 PNG** from `logo/plop-icon.svg`, with the squircle clip **removed**
   so the cream gradient fills the full square (app icons must be opaque; iOS applies its own
   rounded mask). Rendered with `rsvg-convert` at 1024.
2. **Wire `AppIcon.appiconset`** — replace the empty universal/dark/tinted slots with a
   single **universal** iOS 1024 entry pointing at the PNG.
3. **Verify** the rendered icon (read the PNG back) shows the cream squircle bg + blue "plop"
   wordmark + ripples before committing.

## Out of scope

- Dark / tinted icon variants (universal only, by decision).
- The launch screen (PR2).
- App Store icon-alpha flattening — if submission validation later flags an alpha channel,
  flatten then (tracked under roadmap "Before App Store"); an opaque PNG is fine for the app
  and Xcode now.

## Constraints / dependencies

- **Baloo 2 font** must be available to `rsvg-convert` (fontconfig) or the "plop" wordmark
  renders in a fallback sans. It is **not** installed locally; install it (Homebrew cask
  `font-baloo-2`, or download the Google Fonts TTF into `~/Library/Fonts`) before rendering.
  The font is only needed to rasterize the asset — it is **not** bundled in the app.

## Key decisions (with rationale)

1. **Remove the squircle clip** — iOS rounds icons itself; a full-bleed opaque square avoids
   transparent corners and matches how iOS expects the 1024 marketing icon.
2. **Universal only** — one icon for light/dark/tinted (iOS derives tinted); simplest and the
   cream icon reads on both modes.
3. **Verify the PNG visually** — the render depends on the Baloo 2 font resolving, so confirm
   the wordmark looks right (not a fallback font) before committing.
