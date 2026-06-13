# plop — Roadmap

Overall feature sequencing. Each feature runs the full loop: brainstorm → spec →
plan → PRs. `main` always builds; one branch + PR per slice.

## Status

- **Project init** — done (`.gitignore`, CI, SwiftLint, `CLAUDE.md`, design handoff).
- **Feature 1 (Home + Entry)** — spec approved (`docs/home-entry/`); planning PR1.

## Feature sequence

### Feature 1 — Home + Entry  *(in progress)*
Core foundation: SwiftData model, Home (list + period filter + net total), Entry
(add/edit/delete), and the app's routing skeleton with stubbed tabs.
**5 PRs:** `expense-model` → `home-ui` → `home-data` → `entry-ui` → `entry-data`.
Spec: `docs/home-entry/`.

### Feature 2 — Recurring payments (engine)
Auto-generate transactions on a schedule **until stopped**. Hybrid anchor (a global
default day, overridable per rule); disclose the behavior before saving; manage/stop
from a dedicated surface (likely Settings). Builds on the Feature 1 model. Hard parts:
catch-up generation when the app was closed, "edit this one vs. the series", and
stop/manage semantics. Placement is flexible — independent of Insights/Settings.

### Feature 3 — Insights tab
Animated donut (per handoff). **Breakdown** mode (spend split by category) ships
independent of budgets. **Budget** mode (spend vs. budget) depends on budgets from
Settings, so breakdown can come first.

### Feature 4 — Settings tab (a cluster of semi-independent pieces)
- **Category management** (add/edit/delete) — restores Entry's hidden "New category".
- **Currency picker** — refines Feature 1's device-locale default.
- **Theme** (Light / Dark / Automatic) — dark tokens already exist in the handoff.
- **Set budget** (total / by-category) — feeds Insights budget mode.
- **Export to Google Sheets** — stateless OAuth (PKCE, no client secret); the headline
  backend feature.
- **Report a bug.**

### Feature 5 — Dialogs polish
Export, add-category, and bug-report modals refined to the handoff fidelity.

## Dependency notes

- Insights **budget mode** ⟵ Settings **Set budget**.
- Entry **"New category"** ⟵ Settings **category management**.
- **Currency picker** refines Feature 1's device-locale default.
- **Theme** — Feature 1 builds light first; dark tokens are in the handoff.

## Conventions

- One feature branch per slice; PR per slice; review the diff before merge.
- No git worktrees (they break the open Xcode project) — sequential, current session.
- CLAUDE.md review sequencing: **Home + Entry → Insights + Settings → dialogs.**
