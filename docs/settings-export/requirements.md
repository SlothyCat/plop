# Export to Google Sheets — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-15

The headline backend feature: a one-way, on-demand export of local transactions
to Google Sheets via stateless OAuth (PKCE, no client secret, no Google SDK). The
access token is acquired, used once, and discarded — nothing is persisted.

Depends on: a Google Cloud **iOS OAuth client ID** (provided by the owner; stored
in git-ignored `Secrets.xcconfig`). Scope: `drive.file`.

## User stories

- As a user, from Settings I can export my transactions to Google Sheets.
- I pick a range (This month, or a custom Date range) and tap Export.
- I sign in to Google in a secure web sheet and grant access once.
- My data lands in a tidy, useful spreadsheet I can open in Google Sheets.
- Re-exporting updates the same spreadsheet instead of making duplicates.
- If something goes wrong, I see a clear, friendly message.

## Output model

- A Drive folder **`plop-transactions`** holds everything (created if missing).
- **One spreadsheet per year**, named `plop {year}`, inside that folder.
- **One tab per month** that has in-range transactions, named `{year}-{MM}`.
- **Each month tab**, top to bottom:
  - **Month totals**: Total expense, Total income, Net.
  - **Budget line**: Total budget · Spent · Left (uses the app's active-budget total).
  - **By category**: Category · Spent · Budget · Left (largest spend first; Budget
    and Left blank where a category has no budget).
  - **Transactions**: `Date (ISO yyyy-MM-dd) · Category · Note · Type · Amount (CUR)`.
- On success: a link to **Open in Google Sheets** (the create/get returns the URL).

## Behavior

- **Re-export = find & rewrite.** Locate the app-created `plop-transactions`
  folder and `plop {year}` spreadsheet by name (create if absent), then **rewrite**
  each in-range month tab from current local data. Idempotent: no duplicate files
  or rows; the sheet always mirrors the app. Safe to retry after any failure.
- **Stateless.** No token, spreadsheet ID, or folder ID is stored; every export
  searches by name and discards the token when done.
- **Local is the source of truth**; export is one-way (app → Sheets only).

## Error handling (`ExportError`, friendly dialog messages)

| Failure | Message |
|---|---|
| User cancels sign-in | (silent — just close) |
| Consent denied (`access_denied`) | "Sign-in was declined." |
| Offline / network error | "No connection — check your network and try again." |
| Token exchange failed (`invalid_grant`/non-200) | "Couldn't sign in to Google. Try again." |
| Drive storage full (403 `storageQuotaExceeded`) | "Your Google Drive is full — free up space and retry." |
| Rate limited (429 / 403 `rateLimitExceeded`) | "Google is busy — try again in a moment." |
| Google server error (5xx) | "Google Sheets is unavailable right now." |
| Anything else | "Export failed. Please try again in a while, or submit a bug report." |

## In scope

- The Export dialog (range: This month / Date range with from/to pills; Export +
  Cancel; progress / success / error states).
- PKCE OAuth via `ASWebAuthenticationSession` + token exchange over `URLSession`.
- Drive folder + per-year spreadsheet + per-month tab creation and rewrite.
- The per-month summary (totals, budget, category breakdown) + transaction rows.
- `Secrets.xcconfig` (git-ignored) + `Secrets.example.xcconfig` + Info.plist
  redirect URL scheme.

## Out of scope

- Importing or two-way sync (export is one-way).
- Storing tokens / refresh flow / background or scheduled export.
- Choosing an existing spreadsheet or arbitrary Drive folder (we own
  `plop-transactions`).
- Recovering a user-**renamed** spreadsheet/folder (a rename causes a fresh file
  next export; no local data is lost). Documented limitation.
- Per-category budget editing or any Insights changes.

## Key decisions (with rationale)

1. **Stateless PKCE, no secret, no SDK** — per CLAUDE.md; a native app can't hide a
   secret, so the design must not need one.
2. **`drive.file` scope** — least-privilege: the app only sees files it created.
   Enough to create the folder + spreadsheets; keeps the consent screen in Testing
   without Google verification.
3. **Find & rewrite, by name** — idempotent and stateless; avoids duplicates
   without persisting IDs.
4. **Year spreadsheet / month tabs in a `plop-transactions` folder** — the
   structure the owner wants; tidy and scannable.
5. **Multi-PR** (config+PKCE → sheet builder → networking → UI) — large feature;
   each PR builds and is independently reviewable.
