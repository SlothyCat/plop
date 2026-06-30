# Export to Google Sheets — Design

Status: Approved (brainstorm complete) · Date: 2026-06-15

Companion to `requirements.md`. Architecture, the OAuth + Sheets flow, components,
error model, secrets, slicing, and testing.

## Architecture

```
plop/
  Logic/Export/
    ExportRange.swift     (PURE: This month | Date range → the set of month keys)
    SheetBuilder.swift    (PURE: [Transaction] + categories + currency → per-month value matrices)
    PKCE.swift            (PURE: code verifier/challenge + auth-URL building)
  Networking/
    GoogleOAuth.swift     (ASWebAuthenticationSession + token exchange)
    SheetsClient.swift    (Drive folder/file search+create, Sheets batchUpdate + values)
    HTTPError.swift       (maps URLResponse/JSON → ExportError)
  Services/
    ExportService.swift   (orchestrates: auth → build → upload; publishes state)
    ExportError.swift     (typed errors + user-facing messages)
  Views/Settings/
    ExportSheet.swift     (dialog: range, date pills, Export, progress/success/error)
    SettingsView.swift    (+ Export row)
  Config:
    Secrets.xcconfig          (git-ignored: GOOGLE_OAUTH_CLIENT_ID)
    Secrets.example.xcconfig  (committed placeholder)
    Info.plist                (CFBundleURLTypes = reversed client ID scheme)
```

Pure logic (`PKCE`, `SheetBuilder`, `ExportRange`, error mapping) is unit-tested;
networking is tested via request-building + response-parsing with a mocked
`URLProtocol`. Live OAuth + writes are simulator-only.

## Secrets & redirect

- `Secrets.xcconfig` (git-ignored) holds `GOOGLE_OAUTH_CLIENT_ID = ...apps.googleusercontent.com`.
  `Secrets.example.xcconfig` (committed) has a placeholder. The build setting maps to
  an Info.plist key the app reads at runtime (no secret in source).
- Info.plist `CFBundleURLTypes` registers the **reversed client ID** scheme
  (`com.googleusercontent.apps.<id>`) so the OAuth redirect returns to the app.
- No client secret anywhere (PKCE).

## OAuth + Sheets flow (stateless)

1. **PKCE** — random `verifier` (43–128 unreserved chars); `challenge =
   base64url(SHA256(verifier))`; `method = S256`.
2. **Authorize** — build `https://accounts.google.com/o/oauth2/v2/auth?...`
   (`client_id`, `redirect_uri` = reversed-ID scheme, `response_type=code`,
   `scope=https://www.googleapis.com/auth/drive.file`, `code_challenge`,
   `code_challenge_method=S256`). Present via `ASWebAuthenticationSession`
   (`prefersEphemeralWebBrowserSession = true`). Redirect returns `code`.
3. **Token** — POST `https://oauth2.googleapis.com/token` with
   `grant_type=authorization_code`, `code`, `code_verifier`, `client_id`,
   `redirect_uri`. Parse `access_token` (ignore/skip refresh). Nothing stored.
4. **Upload** (bearer token):
   - `GET drive/v3/files?q=name='plop-transactions' and mimeType='application/vnd.google-apps.folder' and trashed=false` → folder id, or `POST drive/v3/files` to create it.
   - `GET .../files?q=name='plop {year}' and '<folderId>' in parents and trashed=false` → spreadsheet id. If absent: `POST sheets/v4/spreadsheets` to create it, then `PATCH drive/v3/files/{id}?addParents=<folderId>&removeParents=root` to move it into the folder (Sheets `create` can't set a parent directly).
   - `GET sheets/v4/spreadsheets/{id}` → existing tab titles; `batchUpdate` `addSheet`
     for any missing in-range month tab.
   - For each in-range month tab: `values.clear` then `values.update`
     (`valueInputOption=RAW`) with the matrix from `SheetBuilder`.
5. Return the spreadsheet `spreadsheetUrl`; discard token.

> Token-once: we never request `access_type=offline`, so no refresh token is issued.

## SheetBuilder (pure, the heart of PR2)

```swift
/// A month's worth of rows ready for Sheets (a 2-D array of cell strings).
struct MonthSheet: Equatable {
    let tabTitle: String          // "2026-06"
    let values: [[String]]        // summary block + blank + header + tx rows
}

/// Groups in-range transactions by year then month and renders each month's matrix.
func buildMonthSheets(_ transactions: [Transaction],
                      categories: [ExpenseCategory],
                      currencyCode: String) -> [Int: [MonthSheet]]  // keyed by year
```

Each `MonthSheet.values` lays out: month totals (expense/income/net), the budget
line (`activeBudgetTotal` + spent + left), the **By category** table (spend desc;
budget/left where set), a blank row, the transactions header, then one row per
transaction. Amounts are RAW numbers (no symbol) so Sheets can SUM; the Amount
header carries the currency, e.g. `Amount (USD)`. Dates are `yyyy-MM-dd`.

Reuses existing logic where possible: `spendByCategory`, `categoryBudgetSum` /
`activeBudgetTotal`, `TransactionType`, and the currency helpers (numbers only —
not `formattedMoney`, which adds a symbol).

## ExportRange (pure)

```swift
enum ExportRange: Equatable { case thisMonth; case dateRange(ClosedRange<Date>) }
// → filters transactions and yields the affected (year, month) tab keys.
```

## ExportService (orchestration)

An `@MainActor` observable with state `idle | authorizing | uploading | success(URL)
| failure(ExportError)`. `func export(range:) async` runs auth → build → upload and
maps any thrown error through `ExportError`. The dialog observes this state.

## ExportError

```swift
enum ExportError: Error, Equatable {
    case cancelled              // silent
    case consentDenied, network, signInFailed
    case storageFull, rateLimited, serverError, unknown
    var message: String? { ... }   // nil for .cancelled
}
```
Mapping (in `HTTPError`): `URLError` → `.network`; 403 `storageQuotaExceeded` →
`.storageFull`; 429 / 403 `rateLimitExceeded` → `.rateLimited`; 5xx → `.serverError`;
`invalid_grant`/non-200 token → `.signInFailed`; else `.unknown`. `.unknown`
message: "Export failed. Please try again in a while, or submit a bug report."

## ExportSheet (UI)

Bottom sheet titled **Export to Google Sheets**: explainer text; a `WHAT GETS
EXPORTED` segmented control (This month / Date range) with From/To date pills when
Date range; an **Export** primary button and **Cancel**. While running it shows a
progress state; on success a checkmark + **Open in Google Sheets** (opens the URL);
on failure the mapped message + Retry. Presented from a Settings **Export** row
(icon `square.and.arrow.up`).

## Slicing (PRs — each builds; `main` stays green)

- **PR1 — Config + PKCE.** `Secrets.example.xcconfig`, git-ignore + Info.plist
  scheme wiring, `PKCE.swift` + tests. No UI, no live calls.
- **PR2 — SheetBuilder + ExportRange.** Pure transformation to month matrices +
  range filtering, fully unit-tested. No network.
- **PR3 — Networking + Service.** `GoogleOAuth`, `SheetsClient`, `HTTPError`,
  `ExportError`, `ExportService`; request-building/response-parsing tests via mocked
  `URLProtocol`.
- **PR4 — UI.** `ExportSheet` + Settings row, wired to `ExportService`; range,
  progress, success (open link), error states. Live verification in the simulator.

## Testing

- **PKCE** (PR1): verifier charset/length; `challenge == base64url(SHA256(verifier))`;
  auth-URL query params.
- **SheetBuilder / ExportRange** (PR2): grouping by year/month; tab titles; summary
  math (expense/income/net, budget/spent/left, per-category, blank budget cells);
  column order; RAW numeric amounts; ISO dates; empty range → no tabs; This month vs
  Date range selection.
- **Networking** (PR3): each request's URL/method/headers/body; response parsing
  (folder/file ids, spreadsheet URL); `ExportError` mapping for 403/429/5xx/URLError.
- **UI / live** (PR4): simulator + the test-user Google account — sign-in, create,
  re-export rewrite, open link, and an induced error (e.g. airplane mode → network).

:::voice[Reflection]
_Going stateless OAuth with PKCE and no Google SDK — why, and would you make the same call again?_
:::
