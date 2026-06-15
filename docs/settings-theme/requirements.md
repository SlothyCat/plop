# Theme — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-15

Lets the user choose the app's appearance — **Light**, **Dark**, or **Automatic**
(follow system) — from Settings. Dark tokens already exist in the design handoff.

## User stories

- As a user, I can open Settings → Theme and pick Light, Dark, or Automatic.
- Picking an option repaints the whole app immediately (live preview).
- **Automatic** follows my device's light/dark setting.
- My choice persists across launches.

## In scope

- An **Appearance** bottom sheet (per the provided mockup): title + subtitle,
  three selectable cards (icon, title, subtitle, checkmark on the active one,
  selected card filled with `accentSoft`), and a **Done** button.
- A Settings **Theme** row that opens the sheet and shows the current mode.
- Adaptive `Palette`: every scheme-dependent token resolves light/dark
  automatically, so all existing views adopt dark mode with no per-view changes.
- `ThemeMode` enum persisted in `@AppStorage("themeMode")`; applied once at the
  app root via `.preferredColorScheme`.
- Dark values for `bg`, `card`, `field`, `ink`, `ink60/40/12`, `hair` from the
  handoff; a brighter dark variant for `incomeGreen`.

## Out of scope

- Per-screen or per-element theme overrides.
- Custom user-defined palettes / accent color picking.
- Animated cross-fade on theme switch (the system handles the repaint).
- Theming the app icon.

## Key decisions (with rationale)

1. **Adaptive colors, not a live-mutated singleton.** Tokens become dynamic
   `UIColor`-backed `Color`s that resolve per `userInterfaceStyle`. This is the
   SwiftUI-native path and requires **zero changes to any view** — they already
   read `Palette.*`. (The handoff's JS used a mutated `T` object; that pattern
   doesn't fit SwiftUI and would need manual re-render plumbing.)
2. **Mode applied at the root** via `.preferredColorScheme`; `automatic → nil`
   (follow system). One injection point, whole-app effect.
3. **Bottom-sheet Appearance dialog**, per the user's mockup — friendlier than a
   pushed list for a 3-way choice; selection applies live, Done dismisses.
4. **`@AppStorage` persistence**, consistent with currency and budget.
5. **Brand accents stay identical** in both themes (the blue reads on light and
   dark); `tileInk` stays charcoal (it sits on fixed pastel tiles).
6. **One PR** — self-contained, no cross-feature dependency.
