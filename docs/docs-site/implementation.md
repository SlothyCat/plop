# Documentation Site (Docusaurus) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a Docusaurus 3 site in `website/` that serves the existing `docs/` specs as **Reference**, wraps them in a curated **Story** with scaffolded `:::voice` blanks (Standard density), and deploys to GitHub Pages. Per `docs/docs-site/design.md`.

**Architecture:** Two `@docusaurus/plugin-content-docs` instances — default `docs` → `../docs` (Reference), second `story` → `website/story` (curated). Custom `voice` admonition for personal-voice blanks. CommonMark mode so the raw specs build. Isolated from the Swift app; deployed via a dedicated Pages workflow.

**Tech Stack:** Docusaurus 3, Node 20, React, GitHub Pages (Actions). No Swift/`ci.yml` changes.

Single PR on `feature/docs-site` (the design spec is committed there).

---

## Context for the implementer

- Node `v20.14`, npm `10.7` are available. Run all `npm`/`npx` from `website/` unless noted.
- The gate is **`npm run build`** (from `website/`) succeeding — it catches MDX/link problems.
  Use `npm start` only for manual preview, not in this plan.
- `markdown.format: 'detect'` makes the `.md` specs parse as **CommonMark**, avoiding MDX errors
  from prose like `Binding<Color>`. Keep it.
- Do **not** touch the Swift app, `ci.yml`, or `.swiftlint.yml`. SwiftLint/xcodebuild are
  irrelevant here.
- The `:::voice` blocks are **intentional blanks** for the owner — leave the italic prompts in.

### Verify command (used throughout)

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop/website && npm run build 2>&1 | tail -15
```
Expected: `[SUCCESS] Generated static files in "build".`

---

## File structure

- **Create** `website/` (Docusaurus scaffold): `docusaurus.config.js`, `sidebars.js`,
  `sidebarsStory.js`, `src/css/custom.css`, `src/pages/index.mdx`, `story/**`.
- **Modify** root `.gitignore`.
- **Modify** 6 spec files under `docs/**` (append a `:::voice` Reflection).
- **Create** `.github/workflows/docs.yml`.

---

## Task 1: Scaffold + base config + gitignore

**Files:** create `website/` (scaffold), modify root `.gitignore`.

- [ ] **Step 1: Scaffold Docusaurus (classic, JS)**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
npx --yes create-docusaurus@latest website classic --javascript
```
This creates `website/` with `package.json` and installs dependencies. Confirm
`website/package.json` exists and lists `@docusaurus/core`.

- [ ] **Step 2: Remove the scaffold's sample content we won't use**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop/website
rm -rf docs blog src/components/HomepageFeatures src/pages/index.js src/pages/index.module.css src/pages/markdown-page.md
```
(The default tutorial `docs/` and blog are replaced; the homepage is rebuilt as MDX in Task 6.)

- [ ] **Step 3: Add a temporary placeholder homepage so the build passes until Task 6**

Create `website/src/pages/index.mdx`:
```mdx
# plop

A local-first iOS expense tracker. Documentation site scaffold.
```

- [ ] **Step 4: gitignore the build artifacts**

Append to the root `.gitignore` (`/Users/meowmeowmachine/Documents/GitHub/plop/.gitignore`):
```
# Docusaurus
website/node_modules
website/build
website/.docusaurus
```

- [ ] **Step 5: Build the bare scaffold** → run the verify command → `[SUCCESS] Generated static files`.

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add website .gitignore
git reset -q website/node_modules 2>/dev/null || true
git commit -m "Scaffold Docusaurus docs site in website/

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```
(`node_modules` is gitignored; the `reset` is a belt-and-suspenders no-op if already ignored.)

---

## Task 2: Reference instance (serve ../docs) + core config

**Files:** `website/docusaurus.config.js`, `website/sidebars.js`.

- [ ] **Step 1: Replace `docusaurus.config.js`**

Overwrite `website/docusaurus.config.js` with:
```js
// @ts-check
/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'plop',
  tagline: 'A local-first iOS expense tracker, built with a disciplined AI-assisted workflow.',
  favicon: 'img/favicon.ico',
  url: 'https://slothycat.github.io',
  baseUrl: '/plop/',
  organizationName: 'SlothyCat',
  projectName: 'plop',
  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',
  trailingSlash: false,
  markdown: { format: 'detect' },
  i18n: { defaultLocale: 'en', locales: ['en'] },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          path: '../docs',
          routeBasePath: 'reference',
          sidebarPath: require.resolve('./sidebars.js'),
          admonitions: { keywords: ['voice'], extendDefaults: true },
        },
        blog: false,
        theme: { customCss: require.resolve('./src/css/custom.css') },
      }),
    ],
  ],

  plugins: [
    [
      '@docusaurus/plugin-content-docs',
      {
        id: 'story',
        path: 'story',
        routeBasePath: 'story',
        sidebarPath: require.resolve('./sidebarsStory.js'),
        admonitions: { keywords: ['voice'], extendDefaults: true },
      },
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      navbar: {
        title: 'plop',
        items: [
          { to: '/story/overview', label: 'The Story', position: 'left' },
          { to: '/reference/roadmap', label: 'Reference', position: 'left' },
          { href: 'https://github.com/SlothyCat/plop', label: 'GitHub', position: 'right' },
        ],
      },
      footer: {
        style: 'light',
        copyright: `Built by SlothyCat. Docs powered by Docusaurus.`,
      },
    }),
};

module.exports = config;
```

- [ ] **Step 2: Reference sidebar (autogenerated)**

Overwrite `website/sidebars.js`:
```js
/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  referenceSidebar: [{ type: 'autogenerated', dirName: '.' }],
};
module.exports = sidebars;
```

- [ ] **Step 3: Story sidebar (autogenerated)**

Create `website/sidebarsStory.js`:
```js
/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  storySidebar: [{ type: 'autogenerated', dirName: '.' }],
};
module.exports = sidebars;
```

- [ ] **Step 4: Create a minimal `story/overview.md` placeholder** (fleshed out in Task 3) so the
  `story` plugin and the navbar link resolve:
```md
---
sidebar_position: 1
---

# The Story

Overview coming together in Task 3.
```

- [ ] **Step 5: Build** → verify command.
  - Expected: `[SUCCESS]`. The Reference specs are now served under `/reference/...`
    (e.g. `/reference/roadmap`, `/reference/haptics/design`).
  - **If the build errors that the docs `path` `'../docs'` is outside the site directory**, create
    a symlink and point `path` at it instead:
    ```bash
    cd /Users/meowmeowmachine/Documents/GitHub/plop/website && ln -s ../docs reference-docs
    ```
    then set `docs.path: 'reference-docs'` and add `website/reference-docs` is a symlink (commit
    the symlink). Re-run the build.
  - **If a specific spec file fails to compile** even in CommonMark mode, note the file and fix the
    offending line minimally (usually an unescaped construct); prefer a tiny edit over disabling.

- [ ] **Step 6: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add website
git commit -m "Serve the existing specs as the Reference docs instance

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Voice admonition + Story overview + Behind-the-Build essay (Tier 1)

**Files:** `website/src/css/custom.css`, `website/story/overview.md`, `website/story/behind-the-build.mdx`.

- [ ] **Step 1: Style the `voice` admonition**

Append to `website/src/css/custom.css`:
```css
/* "From the author" personal-voice callout */
.theme-admonition-voice {
  border-left: 4px solid #8CC0EB;
  background: rgba(140, 192, 235, 0.10);
}
.theme-admonition-voice .admonitionHeading_node_modules-\@docusaurus,
.theme-admonition-voice .admonition-heading {
  text-transform: uppercase;
  letter-spacing: 0.04em;
}
```

- [ ] **Step 2: Flesh out `website/story/overview.md`** (Tier-1 "Why I built this" blank + a
  short how-to-add-voice note):
```md
---
sidebar_position: 1
---

# The Story

This site documents how **plop** — a local-first iOS expense tracker — was designed and built,
using a deliberate *brainstorm → write a plan → get approval → implement* loop. The
[Reference](/reference/roadmap) holds the full engineering specs; this section narrates the
decisions behind them.

:::voice[From the author]
_Why did you build plop, and what did you want this project to prove? (Your motivation in a few
sentences.)_
:::

## How this is organised

- **[Behind the Build](./behind-the-build)** — the workflow and the lessons.
- **Section notes** — short framing for each area of the app.
- **[Reference](/reference/roadmap)** — the raw requirements / design / implementation specs.

> Throughout the site, the highlighted **"From the author"** boxes are my own notes. You can add
> more anywhere by writing a `:::voice[From the author] … :::` block.
```

- [ ] **Step 3: Create the essay `website/story/behind-the-build.mdx`** (Tier-1, 5 blanks):
```mdx
---
sidebar_position: 2
---

# Behind the Build

plop was built as a portfolio piece for a disciplined, AI-assisted workflow: every feature went
through a written spec and plan before any code, one branch and PR per slice, with tests and lint
gating `main`.

## The workflow

:::voice[From the author]
_How did the brainstorm → plan → approve → implement loop actually feel day to day? What made it
work?_
:::

## What worked

:::voice[From the author]
_Which parts of this approach paid off the most?_
:::

## What was hard

:::voice[From the author]
_Where did it get messy — a bug, a tooling fight, a decision you went back and forth on?_
:::

## What I'd change

:::voice[From the author]
_If you started over, what would you do differently?_
:::

## Advice to someone trying this

:::voice[From the author]
_Your one or two takeaways for working this way._
:::
```

- [ ] **Step 4: Build** → verify command → `[SUCCESS]`; the `voice` admonition renders (no
  "unknown admonition" warning).

- [ ] **Step 5: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add website
git commit -m "Add the Story overview and Behind-the-Build essay with voice blanks

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Section-intro pages (Tier 2, 8 blanks)

**Files:** `website/story/sections/_category_.json` + 8 markdown files.

- [ ] **Step 1: Category metadata** — create `website/story/sections/_category_.json`:
```json
{ "label": "Section notes", "position": 3 }
```

- [ ] **Step 2: Create the 8 section pages.** Each uses this template (replace `TITLE`,
  `ONE-LINE FRAMING`, the voice prompt, and the Reference links). Filenames and the spec links:

For each section below, create `website/story/sections/<file>.md`:
```md
# TITLE

ONE-LINE FRAMING of what this area of the app does.

:::voice[From the author]
_My take on TITLE — why it mattered, the key design tension, and what I learned._
:::

**In the Reference:** LINKS
```

| file | TITLE | LINKS (to `/reference/...`) |
|------|-------|------------------------------|
| `home-entry.md` | Home & Entry | `/reference/home-entry/design` |
| `insights.md` | Insights & Budget | `/reference/insights/design`, `/reference/insights-budget/design` |
| `recurring.md` | Recurring payments | `/reference/recurring/sp2-generation-engine/design` |
| `export.md` | Google Sheets export | `/reference/settings-export/design` |
| `prefs.md` | Categories, Currency & Theme | `/reference/settings-categories/design`, `/reference/settings-currency/design`, `/reference/settings-theme/design` |
| `cleanup.md` | Cleanup & Polish | `/reference/popup-consistency/design`, `/reference/cleanup/fidelity-audit` |
| `branding.md` | App icon & Launch screen | `/reference/app-icon/design`, `/reference/launch-screen/design` |
| `feedback.md` | Haptics & Invalid-action feedback | `/reference/haptics/design`, `/reference/invalid-feedback/design` |

Write a real one-line framing for each (factual, neutral — the *voice* block is the owner's). Use
Markdown links, e.g. `[Insights design](/reference/insights/design)`.

- [ ] **Step 3: Build** → verify command → `[SUCCESS]`. (Broken links warn, not fail — but the
  links above are valid; fix any that warn.)

- [ ] **Step 4: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add website
git commit -m "Add section-note pages with per-area voice blanks

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Milestone reflections (Tier 3, 6 spec appends)

**Files:** append a block to each of these 6 specs under `docs/`.

- [ ] **Step 1: Append the Reflection block** to the **end** of each file below. The block is the
  same shape; tailor the italic prompt to the file:
```md

:::voice[Reflection]
_PROMPT_
:::
```

| file | PROMPT |
|------|--------|
| `docs/settings-export/design.md` | _Going stateless OAuth with PKCE and no Google SDK — why, and would you make the same call again?_ |
| `docs/recurring/sp2-generation-engine/design.md` | _The generation engine was the trickiest logic in the app. What made it hard, and how did you get it right?_ |
| `docs/donut-min-arc/design.md` | _The donut's tiny-slice / clipped-ring saga — what did chasing those bugs teach you?_ |
| `docs/popup-consistency/design.md` | _Standardising every popup onto BlurPopup — was the consistency worth the churn?_ |
| `docs/home-entry/design.md` | _Choosing SwiftData over raw SQLite and modelling the data — what would you tell your past self?_ |
| `docs/haptics/design.md` | _Designing how the app should *feel* (success vs error haptics) — what surprised you?_ |

> These `:::voice` blocks only render inside the site (the `voice` keyword is registered there);
> in plain Markdown viewers they show as a labelled blockquote-like block, which is fine.

- [ ] **Step 2: Build** → verify command → `[SUCCESS]` (the specs are served under `/reference`,
  so the new blocks appear there).

- [ ] **Step 3: Commit**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add docs
git commit -m "Add author-reflection voice blanks to milestone specs

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 6: Homepage, Pages deploy workflow, verify + PR

**Files:** `website/src/pages/index.mdx`, `.github/workflows/docs.yml`.

- [ ] **Step 1: Real homepage** — overwrite `website/src/pages/index.mdx`:
```mdx
# plop

**A local-first iOS expense tracker** — tracks expenses on-device (SwiftUI + SwiftData, iOS 18+)
and exports to Google Sheets on demand. Built as a portfolio piece for a disciplined,
AI-assisted *brainstorm → plan → approve → implement* workflow.

- **[Read the Story →](/story/overview)** — the decisions and lessons behind the build.
- **[Browse the Reference →](/reference/roadmap)** — the full engineering specs.
- **[View the source on GitHub →](https://github.com/SlothyCat/plop)**
```

- [ ] **Step 2: GitHub Pages deploy workflow** — create `.github/workflows/docs.yml`:
```yaml
name: Deploy docs site

on:
  push:
    branches: [main]
    paths: ['website/**', 'docs/**', '.github/workflows/docs.yml']
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: website
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
          cache-dependency-path: website/package-lock.json
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-pages-artifact@v3
        with:
          path: website/build

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

- [ ] **Step 3: Final production build** → verify command → `[SUCCESS]`. Confirm `website/build`
  contains `index.html`, `story/`, and `reference/` output.

- [ ] **Step 4: Confirm `package-lock.json` is committed** (the workflow uses `npm ci`):
```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop && test -f website/package-lock.json && echo OK
```

- [ ] **Step 5: Commit + push**

```bash
cd /Users/meowmeowmachine/Documents/GitHub/plop
git add website/src/pages/index.mdx .github/workflows/docs.yml
git commit -m "Add homepage and GitHub Pages deploy workflow

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
git push -u origin feature/docs-site
```

- [ ] **Step 6: PR + owner enablement note.** Open the PR (project format) via the printed URL:
```markdown
## Summary
Add a Docusaurus docs site under website/ that serves the existing specs as Reference and wraps
them in a curated Story with "From the author" voice blanks (Standard density). Deploys to
GitHub Pages via a dedicated workflow. No Swift app or ci.yml changes.

## Testing
`npm run build` succeeds (production build of the full site). No app code touched; Swift CI
unaffected.
```
**Owner action required after merge:** repo **Settings → Pages → Source = "GitHub Actions"**, then
re-run the *Deploy docs site* workflow. Site publishes at `https://slothycat.github.io/plop/`.

---

## Self-review notes

- **Spec coverage:** scaffold + isolation + gitignore (T1); Reference `../docs` + CommonMark +
  broken-links warn + metadata (T2); `voice` admonition + Tier-1 overview/essay (T3); 8 Tier-2
  section intros (T4); 6 Tier-3 reflections (T5); homepage + Pages workflow (T6). All design
  items map to a task; ~20 voice blanks total (Standard).
- **Isolation:** nothing touches `plop/`, `ci.yml`, or `.swiftlint.yml`; `node_modules`/`build`
  gitignored; the deploy workflow is separate and path-filtered.
- **Risk fallbacks called out:** docs `path` outside siteDir → symlink (T2 S5); a spec that won't
  compile even as CommonMark → minimal per-file fix (T2 S5).
- **Voice blanks are intentional** — the italic prompts stay for the owner to replace.
- **No placeholders in the plan itself** (the `:::voice` prompts are deliverable content, not plan
  TODOs); every file's content or exact insertion is given.
- **`onBroken*: 'warn'`** so cross-spec links never fail the build; `markdown.format: 'detect'`
  keeps the specs building.
