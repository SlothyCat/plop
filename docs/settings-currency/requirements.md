# Currency Picker — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-14 · Settings sub-feature.

## Purpose

Let the user choose the currency used to **display** money throughout the app. Amounts
are never converted — only the symbol and decimal precision change. Replaces the current
device-locale-only formatting with a user-selectable, persisted choice.

Design source: `design_handoff_plop/README.md` (Settings → Currency), `app/dialogs.jsx`
(CurrencyDialog), `app/store.jsx` (CURRENCIES).

## In scope

- `Currency.swift`: curated currency list + helpers (device default, display name, symbol).
- Switch `formattedMoney` / `currencyFractionDigits` from a `locale:` param to a
  `currencyCode:` param (symbol + decimals via `NumberFormatter.currencyCode`).
- Persist the choice in `@AppStorage("currencyCode")`, defaulting to the device currency.
- `CurrencyView` picker in Settings + a "Currency" row showing the current code.
- All money views read `@AppStorage("currencyCode")` and pass it to `formattedMoney`, so
  changing the currency **re-renders** Home, Insights, and Entry immediately.
- Entry's keypad decimal places follow the selected currency (JPY/KRW → 0 decimals).

## Out of scope

- **FX conversion** — values are stored/displayed as entered; switching currency only
  changes the symbol/precision, not the numbers.
- **Flag images** — rows show code · symbol · localized name (flag emoji is a later touch-up).
- Per-transaction currency.

## Key decisions (with rationale)

1. **`@AppStorage("currencyCode")`** (UserDefaults), default `deviceCurrencyCode()`
   (`Locale.current.currency?.identifier ?? "USD"`). Lightweight for a single pref; the
   default matches the user's country currency.
2. **Reactive via `@AppStorage` per view** + `formattedMoney(_:signed:currencyCode:)` —
   SwiftUI re-renders any view reading the value when it changes; the formatter stays
   unit-testable (explicit code). (A shared store would also work but adds plumbing; a
   global default inside the formatter would NOT re-render visible screens.)
3. **Curated currency list** (~12 common codes) rather than Foundation's full set —
   friendlier. Names via `Locale.localizedString(forCurrencyCode:)`; symbol + decimals via
   `NumberFormatter.currencyCode`.
4. **No flag images** — avoids a fuzzy currency→country mapping and stays offline.

## Behavioral requirements & edge cases

- Default = device currency; fall back to `"USD"` if the locale has none.
- 0-decimal currencies (JPY, KRW): no fraction digits shown and the keypad blocks the
  decimal point.
- Changing the currency updates every visible money figure without leaving the screen.
- Amounts are unchanged (no conversion) — only formatting differs.

## Success criteria

- Settings → Currency lists the curated currencies with the active one checked; picking
  one updates Home/Insights/Entry symbols + decimals instantly and persists across launches.
- Entry with JPY shows ¥, no decimal entry; with USD shows $ and 2 decimals.
- `Currency` helpers + `formattedMoney`/`currencyFractionDigits` are unit-tested (green in
  CI); the picker + reactive updates verified via `#Preview`/simulator.
