# Insights Budget Mode — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-15

Adds a second Insights view — **Budget mode** — alongside the existing
**Breakdown mode**. Breakdown answers "where did my money go?"; Budget answers
"how am I doing against my budget?". Consumes the budget persistence contract
shipped by the Set budget feature (`docs/settings-budget/`).

Depends on: **Settings → Set budget** (merged) for the budget values.

## User stories

- As a user, I can toggle Insights between **Breakdown** and **Budget**.
- In Budget mode the donut shows how much of my budget I've consumed; the center
  shows what's **LEFT** (or **OVER**) of the total budget.
- The legend shows each category's `spent / budget`, a progress bar, and
  `% used` (or `% · over`); categories with no budget read **"Set budget"**.
- I can tap a category row to set/edit that category's monthly budget inline,
  without leaving Insights.
- Switching the period to **This Year** scales monthly budgets ×12.

## Two budget flavours (from Settings)

- **General** (`budgetMode == general`): one total. All spend counts against it;
  every spend slice is drawn; rows show `% of budget`.
- **Category** (`budgetMode == category`): only categories with a budget count;
  total = sum of their budgets; only budgeted categories are drawn; non-budgeted
  categories appear as tappable "Set budget" rows.

## In scope

- A `Breakdown | Budget` segmented toggle, full-width below the Insights header.
- Budget-mode donut (consumption ring), center (LEFT/OVER + `of {total}`), and a
  `{spent} spent of {total} budget` subhead.
- Budget-mode legend rows: `spent / budget`, progress bar, `% used` / `% · over`,
  "Set budget" for unbudgeted.
- Tap-to-edit: a small sheet to set a single category's monthly budget
  (writes `ExpenseCategory.budget`).
- Year ×12 scaling (deferred from Set budget; lands here where it's consumed).
- Empty state when Budget mode is active but no budget is set.
- Pure, unit-tested aggregation Logic.

## Out of scope

- Changes to Breakdown mode (unchanged).
- Editing the **general** total from Insights (general has no per-row budget to
  tap; the empty-state prompt points to Settings). Per-category editing only.
- Week period (Insights stays month/year).
- Budget rollover / history / multi-month trends.

## Key decisions (with rationale)

1. **Two PRs: Logic then UI.** PR1 ships pure, fully-tested budget aggregation
   (no visible change); PR2 ships the UI. Mirrors the currency split; keeps each
   diff reviewable. This feature is ~2× Set budget in size.
2. **Tap-to-edit inline.** Matches the handoff's `onEditBudget`; lets users fix a
   budget right where they notice it's off, rather than leaving for Settings.
3. **Toggle below header.** Roomy and discoverable; doesn't crowd the existing
   This Month / This Year control.
4. **Consumption donut.** In Budget mode arcs represent spend as a fraction of
   the total budget (ring fills as budget is used), clamped to a full ring when
   over — distinct from Breakdown's share-of-spend arcs.
5. **Year scaling lives here.** It was deferred from Set budget because Insights
   is its only consumer.
