# Recurring Payments — SP2: Generation Engine + Catch-up

Status: Approved (brainstorm complete) · Date: 2026-06-18

The engine that turns rules into real transactions. Builds on SP1 (the `RecurringRule`
model + the pure `RecurringSchedule.dueOccurrences`). On app launch/foreground, it
materializes any missed occurrences for active rules, idempotently. No UI — that's
SP3 (create from Entry) and SP4 (manage/stop).

## User-visible outcome

If an active `RecurringRule` exists, opening the app creates the `Transaction`s that
are now due (a normal ledger entry per period). Because occurrences are real
transactions, they appear in Home, count in Insights/budgets, and export — all
existing features, unchanged.

(Note: no UI yet *creates* rules — that's SP3. SP2 is verified via tests + seeding a
rule manually. It's the engine that makes SP3/SP4 meaningful.)

## In scope

- `RecurringGenerator.generate(in:now:calendar:)`: for each **active** rule, insert a
  `Transaction` per due date (from `dueOccurrences`), advance `lastGeneratedDate`,
  save. Returns the inserted count.
- Each generated `Transaction` copies the rule's amount/type/note/category, dates to
  the due date (start-of-day), links via `tx.rule`, and sets `recurrence =
  rule.interval` (so the existing "Repeats" label shows — no UI change).
- A trigger on `scenePhase == .active` (launch + foreground) running on the main
  context. No server, no background daemon.
- Catch-up: generate **all** missed occurrences up to `now`.
- Unit tests with an in-memory container + injected `now`/calendar.

## Out of scope (later SPs)

- Any UI to create rules (Entry), the pre-save disclosure, the global default anchor
  day — **SP3**.
- Manage/stop surface, edit-one-vs-series — **SP4**.
- Background generation while the app is closed (not possible without a daemon; we
  catch up on next open instead).

## Key decisions (with rationale)

1. **Generate all missed (no cap)** — a faithful, complete ledger; only daily/weekly
   over long gaps produce many rows, and those rules are user-created.
2. **Trigger on `scenePhase == .active`** — covers launch and foreground in one place;
   local-first, no daemon. Naturally idempotent (see below).
3. **Idempotent via `lastGeneratedDate`** — each run advances it; `dueOccurrences`
   treats it as an exclusive lower bound, so repeated `.active` events in a session
   (or a same-day reopen) generate nothing new.
4. **Occurrences carry `recurrence = interval`** — the one light touch of the legacy
   field SP1 deferred; lets Home's existing "Repeats X" label work with no UI change.
5. **Runs on the main context / main actor** — generation is fast and synchronous;
   keeps SwiftData access on one context, avoiding cross-context complexity.
6. **Start-of-day occurrence date** — matches the pure schedule's normalized dates;
   deterministic and timezone-stable in tests.
