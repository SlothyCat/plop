# App Icon (PR1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render the handoff plop icon to a 1024 PNG and wire it into `AppIcon.appiconset` (universal only).

**Architecture:** Rasterize `logo/plop-icon.svg` (squircle clip removed, opaque background) with `rsvg-convert` after making Baloo 2 available; point AppIcon at a single universal 1024 image; verify by reading the PNG + building.

**Tech Stack:** rsvg-convert (librsvg), Xcode asset catalog. Asset only — no code, no tests.

Single PR on branch `feature/app-icon` (off `main`; spec committed there).

> EXECUTION NOTE: This task needs a **visual verification** of the rendered PNG (confirm the
> Baloo 2 wordmark resolved, not a fallback). Run it inline (the executor reads the image
> back), not via a fire-and-forget subagent.

---

## File structure

- **Create** `plop/plop/Assets.xcassets/AppIcon.appiconset/icon-1024.png` — rendered icon.
- **Modify** `plop/plop/Assets.xcassets/AppIcon.appiconset/Contents.json` — single universal entry.

---

## Task 1: Render the icon and wire AppIcon

**Files:**
- Create: `plop/plop/Assets.xcassets/AppIcon.appiconset/icon-1024.png`
- Modify: `plop/plop/Assets.xcassets/AppIcon.appiconset/Contents.json`

- [ ] **Step 1: Make Baloo 2 available to rsvg-convert**

```bash
brew install --cask font-baloo-2 2>&1 | tail -3
fc-list | grep -i baloo
```
Expected: `fc-list` lists a "Baloo 2" family. If the cask name differs or fails, download the
TTF from Google Fonts and copy it into `~/Library/Fonts/`, then re-run `fc-list | grep -i baloo`:
```bash
curl -fsSL -o /tmp/Baloo2.ttf \
  "https://github.com/google/fonts/raw/main/ofl/baloo2/Baloo2%5Bwght%5D.ttf"
cp /tmp/Baloo2.ttf ~/Library/Fonts/ && fc-list | grep -i baloo
```

- [ ] **Step 2: Render the 1024 PNG (squircle clip removed, opaque bg)**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
sed 's/ clip-path="url(#squircle)"//' \
  "design_handoff_plop/logo/plop-icon.svg" > /tmp/plop-icon-fullbleed.svg
rsvg-convert -w 1024 -h 1024 -b '#FFD98C' \
  /tmp/plop-icon-fullbleed.svg \
  -o plop/plop/Assets.xcassets/AppIcon.appiconset/icon-1024.png
file plop/plop/Assets.xcassets/AppIcon.appiconset/icon-1024.png
```
Expected: `PNG image data, 1024 x 1024`.

- [ ] **Step 3: Verify the render visually**

Read `plop/plop/Assets.xcassets/AppIcon.appiconset/icon-1024.png` and confirm: a cream
gradient fills the whole square (no transparent corners), the **"plop" wordmark is the
rounded Baloo 2** (not a plain/serif fallback), in blue, with the two ripple ellipses below.
If the text looks like a fallback sans, Baloo 2 didn't resolve — fix Step 1 and re-render.

- [ ] **Step 4: Point AppIcon at the single universal image**

Replace the entire contents of
`plop/plop/Assets.xcassets/AppIcon.appiconset/Contents.json` with:
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

- [ ] **Step 5: Build**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && xcodebuild build -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`, with no AppIcon "unassigned children" / missing-image
warning in the output.

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add plop/plop/Assets.xcassets/AppIcon.appiconset
git commit -m "Add app icon (rendered from the handoff plop logo)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Push + open PR

**Files:** none.

- [ ] **Step 1: Lint** (unchanged, sanity) — `swiftlint lint` → baseline 19/0.

- [ ] **Step 2: Simulator smoke check (manual — owner)** — the home screen / app switcher /
  Settings shows the plop icon (cream squircle, blue "plop", ripples); iOS's rounded mask
  looks right (no transparent corners).

- [ ] **Step 3: Push + PR**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git push -u origin feature/app-icon
```
`gh` not installed — open the PR via the printed URL, project format:

```markdown
## Summary
Add the app icon: rendered the handoff plop logo (cream squircle + blue "plop" wordmark +
ripples) to a 1024 PNG and wired AppIcon as a single universal image. Full-bleed/opaque so
iOS applies its own mask.

## Testing
Build succeeds (AppIcon resolves, no missing-image warning); icon verified on the simulator
home screen. Asset only — no unit tests.
```

---

## Self-review notes

- **Spec coverage:** render PNG with clip removed + opaque bg (Task 1 Step 2); universal-only
  Contents.json (Step 4); Baloo 2 dependency (Step 1); visual verify (Step 3); build (Step 5).
  All spec items map to a step.
- **Asset only:** no Swift/code/test changes; lint baseline unchanged.
- **Known follow-up (out of scope):** if App Store validation later flags an alpha channel,
  flatten the PNG then (roadmap "Before App Store"); opaque RGBA is fine for the app/Xcode now.
- **No placeholders;** font-install has a fallback path; PNG verified before commit.
