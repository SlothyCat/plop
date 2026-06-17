# Report a Bug — Requirements

Status: Approved (brainstorm complete) · Date: 2026-06-17

A Settings dialog that lets the user report a bug — a description plus an optional
screenshot — delivered via the native Mail composer (no server, no OAuth, no new
dependencies). The last item in the Settings cluster; also fulfils the "submit a
bug report" nudge in the export error fallback.

## User stories

- As a user, from Settings → Report a bug I can describe what went wrong.
- I can optionally attach a screenshot from my photo library.
- **Send** is disabled until I've written a description.
- Tapping Send opens a prefilled email (to the support address, with my
  description, device/app diagnostics, and the screenshot attached) that I send
  from my own Mail account.
- If I have no Mail account set up, I'm shown the support address and can copy my
  report to the clipboard.

## Delivery

- **Native Mail compose** (`MFMailComposeViewController`). Nothing leaves the
  device until the user taps Send inside Mail.
- **To:** `slothycatcoder@gmail.com`
- **Subject:** `plop bug report`
- **Body:** the description, then a diagnostics block (app version + build, iOS
  version, device model).
- **Attachment:** the optional screenshot as `image/jpeg`.

## In scope

- A **Report a bug** row in Settings (grouped with Export under a "Support" section).
- A bug-report sheet: description `TextEditor`, optional screenshot via
  `PhotosPicker` (library — not auto-capture), Send (disabled until description
  non-empty) + Cancel; content-hugging detent.
- The mail composer wrapper + result handling (sent/saved/cancelled/failed →
  dismiss).
- No-mail-account fallback: show the support address + a "Copy report" button.
- A pure, unit-tested email body/subject builder.

## Out of scope

- Server-side delivery, ticketing, or any backend / third-party service.
- Automatic screenshot capture (the user picks an image, per the handoff).
- Crash/log capture, breadcrumbs, or analytics.
- Attaching more than one image.
- In-app reply / status tracking.

## Key decisions (with rationale)

1. **Native Mail compose**, not a server or the Google OAuth path — fits the
   local-first, no-backend, no-new-deps ethos; `MessageUI`/`PhotosUI` are system
   frameworks. The user stays in control (sends from their own account).
2. **Auto-included diagnostics** (app/iOS/device) — makes reports actionable; the
   body builder is pure so it's unit-testable.
3. **Library screenshot picker**, not auto-capture — matches the handoff
   ("Not an auto-capture").
4. **Graceful no-Mail fallback** — `canSendMail()` false is common on the
   simulator and for users without Mail; show the address + copy-to-clipboard.
5. **One PR** — self-contained; no cross-feature dependency.
