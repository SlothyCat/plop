# Recurring Payments — SP3: Create a Rule from Entry

Status: Approved (brainstorm complete) · Date: 2026-06-18

Makes recurring payments user-creatable. When a new Entry has a repeat interval, it
now creates a `RecurringRule` (+ the first occurrence) instead of a flat one-off, and
discloses the behavior before saving. Builds on SP1 (model/schedule) and SP2 (engine).

## User stories

- As a user, when I add a transaction and set it to repeat (daily/weekly/monthly/
  yearly), the app creates a recurring rule so future occurrences are generated
  automatically (by the SP2 engine).
- The recurrence day is the **date I gave the transaction** (anchor = entry date's
  day-of-month for monthly).
- Before it's created, I'm told what will happen ("Repeats monthly on the 18th until
  you stop it") and can confirm or cancel.
- A one-off transaction (no repeat) behaves exactly as before.

## In scope

- `RecurringActions.create(from:in:calendar:)` — builds a `RecurringRule` from the
  draft (interval, `startDate` = entry date, `anchorDay` = entry date's day-of-month,
  amount/type/note/category), inserts the entered transaction as the first occurrence
  (linked, `recurrence = interval`), and sets `lastGeneratedDate = entry date` so SP2
  continues from the next occurrence (no double-create).
- `EntryView.confirm()` branch: a **new** entry with interval ≠ none routes through
  `RecurringActions.create` after a confirmation; otherwise the existing add/update.
- Disclosure: the under-amount chip shows the specifics ("Repeats monthly on the
  18th"); saving a new recurring entry shows a confirm dialog ("…until you stop it").
- A pure `recurringSummary(interval:date:calendar:)` string helper for the chip +
  dialog (unit-tested).

## Out of scope (later / dropped)

- Managing/stopping rules; editing an existing rule's start/anchor/amount; "edit this
  one vs the series" — **SP4**.
- Editing behavior in SP3 is unchanged: editing an existing transaction edits just
  that occurrence, not its rule.
- Global default billing day + per-rule day override — **dropped** (anchor = entry
  date, per the SP3 anchor decision).

## Key decisions (with rationale)

1. **Anchor = entry date's day-of-month** — most intuitive, zero extra UI; the user
   steers the recurrence day by choosing the transaction's date (via Entry's existing
   When picker), so start-date control is implicit.
2. **First occurrence = the entered transaction** — inserted + linked, with
   `lastGeneratedDate` set to its date so SP2 won't duplicate it; the sequence
   continues on the anchor.
3. **Create-only** — turning an existing transaction into a series, and series edits,
   are SP4. Keeps SP3 small and the edit path untouched.
4. **Disclose before saving** — a confirm dialog on save (new recurring only) +
   a specific chip; honest about "until you stop it" (SP2 honors `isActive`; the
   stop UI is SP4).
5. **Reconcile the legacy field minimally** — one-offs stay `.none`; recurring
   occurrences carry `recurrence = interval` as a display hint (matches SP2).
