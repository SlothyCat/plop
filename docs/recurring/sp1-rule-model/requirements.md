# Recurring Payments — SP1: Rule Model + Schedule Math

Status: Approved (brainstorm complete) · Date: 2026-06-18

The foundation of Feature 2 (Recurring payments). Introduces the `RecurringRule`
model and a pure, fully-tested scheduling core that computes which occurrence dates
are due. No generation, no UI, no trigger — those are SP2–SP4.

Part of the decomposition: **SP1 (this)** → SP2 generation engine → SP3 create-from-
Entry → SP4 manage/stop + edit-one-vs-series.

## User-visible outcome

None directly. SP1 is infrastructure: after it, the app has a place to store
recurring rules and a correct answer to "given this rule, which dates are due as of
today?" Later sub-projects make it user-facing.

## In scope

- A `RecurringRule` SwiftData `@Model` (template + schedule state).
- A `Transaction.rule` optional relationship linking a generated occurrence to its
  rule (additive migration; deleting/stopping a rule nullifies the link, keeping the
  transaction).
- A pure schedule function: occurrence dates due in `(lastGenerated, asOf]` for a
  rule's interval + anchor, with month-end clamping and leap-year handling.
- Unit tests covering the schedule edge cases.

## Out of scope (later SPs)

- Generating/inserting occurrences and advancing `lastGeneratedDate` — **SP2**.
- The app-foreground/launch trigger — **SP2**.
- Creating a rule from Entry + the disclosure copy + the global default anchor day —
  **SP3**.
- Manage/stop surface and edit-one-vs-series semantics — **SP4**.
- Any change to how `Transaction.recurrence` (the legacy flat field) behaves — left
  untouched in SP1; reconciled/deprecated in SP3.

## Anchor semantics

- **monthly:** occurrences on `anchorDay` each month, **clamped** to month length
  (31 → Feb 28/29, Apr 30). First occurrence = first anchor-date ≥ `startDate`.
- **daily:** every day from `startDate`.
- **weekly:** `startDate`'s weekday, every 7 days.
- **yearly:** `startDate`'s month/day each year (Feb 29 → Feb 28 in non-leap years).
- `anchorDay` is meaningful only for `.monthly`; other intervals derive their anchor
  from `startDate`.

## Key decisions (with rationale)

1. **Separate `RecurringRule` entity (Option A)** — rule owns scheduling; occurrences
   are real `Transaction`s, so Home/Insights/budgets/export keep working untouched.
2. **Additive migration** — new model + one optional relationship; the lowest-risk
   SwiftData change. Relationship delete rule **nullify** (stopping/deleting a rule
   keeps its past occurrences).
3. **Legacy `recurrence` left alone in SP1** — avoids churning Entry/TxRow before
   SP3; keeps this PR small and the migration purely additive.
4. **Schedule core is pure + returns all due dates (no cap)** — correctness lives
   here and is unit-tested; SP2 decides any catch-up limits and does the inserting.
5. **`anchorDay` only for monthly** — keeps the model and math simple; the hybrid
   global-default-day (SP3) just seeds this field.
