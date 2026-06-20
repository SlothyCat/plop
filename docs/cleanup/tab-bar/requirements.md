# Tab Bar Fidelity (Cleanup D) — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-20

A visual pass on the custom bottom tab bar to match the handoff: a brighter blurred
material, the correct flush bottom layout (no floating gap), aligned glyphs, and the
center-button **halo pulse** on Home. Pure visual — no change to tabs, routing, or the
center button's behavior.

## User-visible outcome

The tab bar reads like the handoff: a bright near-white (light) / dark-translucent
(dark) blurred bar flush to the bottom edge, content sitting just above the home
indicator (no empty gap), and the center "+" on Home **occasionally radiates a soft
halo** (a pulse-then-pause loop).

## In scope

- **Material/color:** replace `.ultraThinMaterial` (renders gray on baby-blue) with a
  brighter blurred material that adapts light/dark, keeping the 1px top hairline.
- **Layout/safe-area:** the bar background fills flush to the screen bottom while the
  content row sits at a fixed height padded ~12 from the top — the home-indicator inset
  is natural bottom space, not extra empty height. Fixes the floating gap.
- **Glyphs:** Insights → solid bars; Settings stays a gear; active tab uses the
  filled/semibold variant.
- **Center-button halo:** when on Home (button = "+"), a soft accent ring pulses
  outward and fades on a ~2.8s loop with a quiet gap (the handoff `addhalo`). No halo
  when off Home (button = house). Respect Reduce Motion (no pulse when enabled).

## Out of scope

- Any behavior change (tab selection, routing, the center add/return-home action).
- The blurred-popup dialog work (Cleanup B) and other screens.
- The `iconpop` icon-swap animation (nice-to-have; not required here).

## The handoff halo (source of truth)

`addhalo` keyframes (from `Expense Tracker.html`), accent = `#8CC0EB` (Palette.accent):
```
0%   box-shadow 0 0 0 0   rgba(140,192,235,0.5)
70%  box-shadow 0 0 0 16px rgba(140,192,235,0)
100% box-shadow 0 0 0 0   rgba(140,192,235,0)
2.8s ease-out infinite
```
i.e. an expanding ring that fades over the first 70%, then holds invisible to 100% →
the "occasional" feel.

## Key decisions (with rationale)

1. **`.regularMaterial`** (not `.ultraThinMaterial`) — bright in light, dark in dark,
   matches the handoff far better; fallback to explicit translucent + blur if the sim
   shows it off.
2. **Keep the ZStack overlay** (don't switch to `safeAreaInset`) — preserves the raised
   center button that overflows the bar top; fix the height math instead of restructuring.
3. **Halo only on Home + Reduce-Motion aware** — it's the add affordance; off-Home it's
   a navigation button, no pulse. Honoring Reduce Motion is the right accessibility default.
4. **Visual only** — no behavior change keeps this low-risk; verified in the simulator
   against `home.jpg`/`settings.jpg` and the `.mov`.
