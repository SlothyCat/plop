# CLAUDE.md

Persistent context for Claude Code. Read this at the start of every session.

## Project

A local-first **iOS expense tracker**. Tracks expenses on-device and exports to
Google Sheets on demand. Target: **iOS 18+**. Intended for App Store release.
Solo project; this is also a portfolio piece demonstrating a disciplined,
plan-and-execute AI-assisted workflow.

> Product/scheme name is currently `plop` (placeholder). If renamed, update the
> scheme, the `ci.yml` env values, and the Bundle ID before submission.

## Tech stack

- **UI:** SwiftUI
- **Persistence:** SwiftData (local only — NOT CloudKit-backed)
- **Google Sheets export:** stateless OAuth via `ASWebAuthenticationSession` +
  `URLSession`. **No Google SDK.** Token is acquired, used once, discarded — no
  session persistence.
- **Tests:** XCTest

## Architecture decisions (do not silently change these)

- SwiftData over raw SQLite — chosen for SwiftUI integration and the iOS 18+ target.
- Stateless OAuth — no token storage, no refresh flow. Keep it simple.
- No third-party dependencies unless explicitly discussed first.
- Local data is the source of truth; Sheets export is one-way and on-demand.

## App structure

Three main tabs plus a dedicated entry screen:
- **Home** — transaction list
- **Insights** — pie/donut chart of spending by category
- **Settings** — Sheets export + category management
- **Entry** — full-screen add-expense page, opened via a center "+" tab bar button

Three modal dialogs: Google Sheets export, add category, bug reporting.

## Design constraints

- **Light theme.** ColorHunt palette:
  - `#FFF9D2`, `#FFEBCC`, `#BFDDF0`, `#8CC0EB`
  - Text: charcoal `~#2A2A2A` for contrast.
- **No emoji.** **No decorative SVG art.** **No filler/sample data** in shipped UI.
- Keep the visual language clean and restrained.

## Conventions

- **Linting:** SwiftLint, config at `.swiftlint.yml` (flexible profile). Follow it;
  don't introduce style that fights it.
- **Testing / TDD:** Write a failing test first, then minimal code to pass, then
  refactor. Business logic (category aggregation, OAuth token exchange, Sheets
  export formatting, SwiftData model logic) MUST be unit-tested. SwiftUI views are
  validated via `#Preview` and the simulator, not unit tests — don't force view tests.
- **Commits:** Small, focused, present-tense messages. One logical change per commit.

## Workflow (human-in-the-loop — important)

- Development follows a **brainstorm -> write plan -> get my approval -> implement**
  loop (Superpowers plugin). **Do not start implementing before I approve the plan.**
- One feature branch per feature; open a PR per feature so I can review the diff
  before merge. `main` must always build.
- **Do NOT use git worktrees** for subagent isolation — they break the open Xcode
  project. Run in the current session instead.
- CI runs build + tests on every PR; the merge is gated on tests passing.

## Documentation

Docs live under `docs/`:
- `docs/roadmap.md` — overall plan / sequencing
- `docs/architecture.md` — system design
- `docs/<feature>/` — per feature: `requirements.md`, `design.md`, `implementation.md`

Review sequencing for features: **Home + Entry first -> Insights + Settings ->
dialogs.**

## Secrets — never commit

- Google OAuth client config goes in a git-ignored `Secrets.xcconfig`.
- Commit `Secrets.example.xcconfig` with placeholder values so setup is visible.
- Never put credentials in source, Info.plist, or docs examples.
- Note: a native app can't truly hide a client secret in the binary — the OAuth
  design must not depend on a hidden secret (use PKCE, no client secret).

## Build & test commands

```bash
# Run tests. The .xcodeproj is in the plop/ subdirectory, so -project is required
# when running from the repo root. No OS is pinned so xcodebuild picks an installed
# iPhone 16 runtime (CI uses OS=latest for runner compatibility).
xcodebuild test -project plop/plop.xcodeproj -scheme plop \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Lint (reads .swiftlint.yml from the repo root)
swiftlint lint
```

## Things to avoid

- No CloudKit / iCloud sync.
- No emoji or decorative art in code or UI.
- No new dependencies without discussion.
- Don't push directly to `main`; go through a PR.
- Don't begin coding before the plan is approved.
