# Recurring Payments — SP4: Manage / Cancel

Status: Approved (brainstorm complete) · Date: 2026-06-19

The final recurring sub-project: a Settings surface to view active recurring rules
and cancel them. Cancelling stops future generation but keeps past occurrences. No
resume, no stopped state, no series-edit. Completes Feature 2.

## User stories

- As a user, from Settings → Recurring payments I can see my active recurring rules
  (what, how much, how often).
- I can **cancel** a recurrence; after cancelling, no new occurrences are generated.
- The transactions that recurrence already created **stay** in my ledger (history and
  totals are unchanged).

## In scope

- `RecurringActions.cancel(_:in:)` — deletes the `RecurringRule`; its past occurrences
  remain (the SP1 relationship is `.nullify`, so their `rule` link simply clears).
- A **"Recurring payments"** row in Settings → Preferences that presents a sheet.
- `RecurringRulesSheet`: lists active rules (note/category, amount, cadence via
  `recurringSummary`), each cancellable with a confirm; an empty state.

## Out of scope (decided)

- **Resume / a stopped state** — not useful; cancel removes the rule outright.
- **Deleting past occurrences on cancel** — kept (option A): they're real recorded
  spending; cancel stops the future, not the past.
- **In-place rule editor** on the manage screen.
- **Edit-one-vs-series prompt** — editing a generated transaction edits just that one
  occurrence (already the behavior since SP3); the rule is untouched. No change here.

## Key decisions (with rationale)

1. **Cancel = delete the rule (option A: keep past occurrences)** — the `.nullify`
   relationship already preserves the generated transactions; future generation stops
   because the rule is gone. Simplest, no tombstone, history intact.
2. **A sheet from a Settings row** (not a pushed screen) — matches the user's mental
   model ("a popup that lets us cancel a recurrence").
3. **List active rules only** — since cancel deletes, every stored rule is active;
   nothing stopped lingers.
4. **Reuse `recurringSummary`** (SP3) for the cadence text — consistent copy.
5. **No series-edit** — editing an occurrence editing only that occurrence is the
   accepted behavior; keeps SP4 to exactly manage/cancel.
