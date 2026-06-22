# App Icon (PR1) — Design

Status: Approved (brainstorm complete) · Date: 2026-06-22

Companion to `requirements.md`. Rendering the icon PNG, wiring the asset catalog, testing.

## Architecture

```
plop/plop/Assets.xcassets/AppIcon.appiconset/
  Contents.json   (→ single universal 1024 entry)
  icon-1024.png   (new — rendered from the handoff SVG)
```
Source SVG stays in `design_handoff_plop/logo/plop-icon.svg`; the committed artifact is the
PNG.

## 1. Render the PNG

The handoff SVG clips its content to a squircle (transparent corners). For an app icon we
want a full opaque square, so render a copy with the `clip-path` removed:

```bash
# 1. Make Baloo 2 available to rsvg-convert (fontconfig), e.g.:
brew install --cask font-baloo-2   # or drop the Baloo 2 TTF into ~/Library/Fonts
fc-list | grep -i baloo            # confirm it's visible

# 2. Strip the squircle clip so the cream rect fills the whole square.
sed 's/ clip-path="url(#squircle)"//' \
  design_handoff_plop/logo/plop-icon.svg > /tmp/plop-icon-fullbleed.svg

# 3. Rasterize at 1024 with an opaque background.
rsvg-convert -w 1024 -h 1024 -b '#FFD98C' \
  /tmp/plop-icon-fullbleed.svg \
  -o plop/plop/Assets.xcassets/AppIcon.appiconset/icon-1024.png
```
`-b '#FFD98C'` (the gradient's bottom stop) guarantees opaque corners even though the rect
already covers the square. The gradient + wordmark + ripples render on top.

## 2. AppIcon Contents.json

Replace the current (image-less) universal/dark/tinted set with a single universal entry:
```json
{
  "images" : [
    {
      "filename" : "icon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

## 3. Verify + build

- **Read back** `icon-1024.png` to confirm it shows the cream squircle-fill gradient, the
  **blue "plop" wordmark in Baloo 2** (not a fallback sans), and the ripple rings. If the
  text looks like a plain sans, Baloo 2 didn't resolve — install it and re-render.
- **Build** the app → `** BUILD SUCCEEDED **` (asset compiles; no "unassigned children"
  warning for AppIcon).

## Testing

No unit tests (asset only). Verification = the PNG read-back + a build, and on the simulator
the home-screen / Settings icon shows the plop mark.

## Scope

The `icon-1024.png` render + `AppIcon.appiconset/Contents.json`. One PR on `feature/app-icon`.
Launch screen is PR2.
