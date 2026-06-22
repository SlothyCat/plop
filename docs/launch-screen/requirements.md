# Launch Screen (PR2) — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-22

Replicate the handoff launch experience (`design_handoff_plop/Launch Screen.html`): a smiling
coin drops into water with ripples, then the "plop" wordmark + "Designed for Simplicity" +
loading dots, on a sky gradient. iOS launch screens are static, so this is two layers — a
**static OS launch screen** + an **animated SwiftUI splash** shown on cold start, then a
crossfade to the app.

Branch: `feature/launch-screen`, off `main`. One PR. (PR2 of the icon+launch work.)

## User-visible outcome

On cold launch: a sky-blue screen (no flash of system white) → the coin drops in with
expanding ripples and settles, the "plop" wordmark (white, cream "o") + tagline rise in, then
three pulsing dots — then it crossfades into Home (~2.2s total). With **Reduce Motion** on:
the resting coin + wordmark + tagline appear (no drop/ripple/bob/pulse) briefly, then fade.

## In scope

1. **Static OS launch screen** — add a `UILaunchScreen` dict to the app's `plop/plop/Info.plist`
   with a solid sky **background color** (a new `LaunchBackground` color asset ≈ `#7EB7E8`).
   It's the instant pre-load frame; the animated splash paints its gradient over it.
2. **`SplashView`** (new SwiftUI view) replicating the HTML:
   - sky **gradient** bg (`#A8D3F2` → `#7EB7E8`), soft top glow;
   - a **coin** drawn with SwiftUI shapes (cream radial face, outer + inner rings, two ink
     eyes, a smile);
   - **coin drop** (fall + slight overshoot + fade-in) then a gentle settle; **ripple** rings
     expanding + fading; the **"plop"** wordmark (SF Rounded heavy, white with a cream "o")
     and **"Designed for Simplicity"** tagline rising/fading in; three pulsing **dots**;
   - auto-finishes after ~**2.2s** via an `onFinish` callback.
3. **Host in `ContentView`** — overlay `SplashView` over `RootView` on launch; on `onFinish`,
   crossfade it away (`withAnimation` opacity).
4. **Reduce Motion** — render the resting state (coin + wordmark + tagline, no motion), finish
   after ~**1.0s**.

## Out of scope

- Bundling Baloo 2 (use SF Rounded for the wordmark, by decision).
- Showing the splash on warm resume / every appearance — cold start only (one `@State`).
- Any change to Home/RootView behavior.

## Key decisions (with rationale)

1. **Static OS launch + animated SwiftUI splash** — iOS can't animate the launch screen, so
   the OS frame is a solid sky color and the real animation is a SwiftUI view over the app.
2. **Solid `LaunchBackground` color (no launch image)** — a gradient/coin can't be a literal
   launch screen; a solid sky blends into the splash's gradient that draws immediately.
3. **SF Rounded wordmark** — close to Baloo 2's rounded look, zero assets; matches the app's
   system-font approach (the icon already bakes in real Baloo 2).
4. **Reduce Motion → static, brief** — keeps the brand moment while honoring accessibility.
5. **~2.2s auto-finish, crossfade** — matches the HTML reveal timeline (coin ~1.1s, wordmark
   ~0.9s, tagline ~1.15s, dots ~1.5s) plus a beat, then fades to Home. Sim-tunable.
