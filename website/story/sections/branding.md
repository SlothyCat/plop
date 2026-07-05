# UI Design

## App Icon and Splash Design

The app icon and the animated launch/splash screen, built from the design handoff.

:::voice[From the author]
I wanted a very short name that was easy to remember, and thought of coins dropping into a fountain with a `plop` sound.
This gave inspiration for the App Icon and the Launch screen which is a splash itself.
:::

**In the Reference:** [App icon design](/reference/app-icon/design), [Launch screen design](/reference/launch-screen/design)

## General UI design

:::voice[From the author]
As mentioned in the [Behind the Build](/story/behind-the-build), I had a discussion with Claude while ideating for the
UI and I prompted Claude to generate a prompt for me to hand off to **Claude Design**. I think this is a very good move as it
is *hard to capture that much detail as a human* when prompting. Having the AI generate the appropriate prompt after brainstorming
is a ***wonderful tactic*** that I will continue using.
:::

This is the prompt that we generated in the end:

```txt
<system-info comment="Only acknowledge these if relevant">
Project title is now "Finance Tracking App"
Project currently has 1 file(s)
Current date is now May 29, 2026
</system-info>

<default aesthetic_system_instructions>
The user has not attached a design system. If they have ALSO not attached references or art direction, and the project is empty, you must ASK the user what visual aesthetic they want. Use the questions_v2 tool to ask about preferred vibe, audience, colors, type, mood, etc. Do NOT just pick your own visual aesthetic without getting the user's aesthetic input -- this is how you get slop!

Once answered, use this guidance when creating designs:
- Choose a type pairing from web-safe set or Google Fonts. Helvetica is a good choice. Avoid hard-to-read or overly stylized fonts. Use 1-3 fonts only.
- Foreground and background: choose a color tone (warm, cool, neutral, something in-between). Use subtly-toned whites and blacks; avoid saturations above 0.02 for whites.
- Accents: choose 0-2 additional accent colors using oklch. All accents should share same chroma and lightness; vary hue.
- NEVER write out an SVG yourself that's more complicated than a square, circle, diamond, etc.
- For imagery, never hand-draw SVGs; use subtly-striped SVG placeholders instead with monospace explainers for what should be dropped there (e.g. “product shot”)

CRITICAL: ignore default aesthetic entirely if given other aesthetic instructions like reference images, design systems or guidance, or if there are files in the project already.
</default aesthetic_system_instructions>

<attached_files>
- uploads/pasted-1780064566393-0.png
- uploads/pasted-1780064579351-0.png
</attached_files>

<pasted_text name="Pasted text (81 lines)">
I'm designing the UI for an iOS expense tracker app (Swift/SwiftUI). 
Light theme only. Design at iPhone size (393×852pt), iOS conventions.
I've attached two reference screenshots: one for the Home list, one for 
the Entry page. Match those layouts but in the light theme below.

COLOR PALETTE (light theme):
- #FFF9D2 pale yellow
- #FFEBCC cream
- #BFDDF0 light blue
- #8CC0EB medium blue
Use a pale tone as the app background, white cards on top, and the 
medium blue (#8CC0EB) as the primary/accent color for buttons and 
highlights. The palette has no dark color, so use a neutral charcoal 
(~#2A2A2A) for all text and icons so everything stays readable. Calm, 
minimal feel.

HARD RULES:
- No emoji anywhere. All icons must be a single consistent set of 
  simple line icons (SF Symbols style).
- No decorative or illustrative SVG art — icons and the chart only.
- Minimal, realistic sample data (4–6 transactions max), not filler 
  rows.

NAVIGATION:
Bottom tab bar with three tabs — Home, Insights, Settings — plus a 
prominent raised center "+" button. The + opens the full-screen Entry 
page (it is not a tab).

—— TAB 1: HOME (view records) ——
- Top bar: search icon left, filter icon right.
- "Net total" label with a "this month" pill, then a large amount 
  below (e.g. -$1,153.05).
- Transactions grouped under date headers (e.g. YESTERDAY, TUE 26 MAY), 
  each header showing that day's subtotal on the right.
- Each row: rounded-square category line-icon, category name + 
  timestamp stacked, amount right-aligned. Categories: School, Food, 
  Subscriptions.
- Show enough rows that the list clearly overflows the screen, with the 
  last row partially cut off at the bottom edge to signal scrolling.

—— ENTRY PAGE (opens full-screen from the center +) ——
- Top: close (X) icon top-left in a circle; a segmented 
  "Expense | Income" toggle centered (Expense selected); a recurring/
  repeat line icon top-right in a circle.
- Center: large amount display, "$" prefix in a muted tone, number in 
  charcoal. A circular backspace button to its right.
- An "Add Note" pill below the amount, with a small line icon.
- A row above the keypad: left pill = date + time 
  ("Today, 29 May  21:12") with a small calendar icon; right pill = 
  "Category" with a small grid icon (opens the Add-category dialog if 
  none exists).
- A CUSTOM number pad (not the iOS system keyboard): 1–9 in a 3×3 grid, 
  then a bottom row of ".", "0", and a confirm button. Make the confirm 
  button #8CC0EB with a charcoal checkmark as the clear primary action. 
  Keys are white/off-white cards on the pale background.

—— TAB 2: INSIGHTS ——
- A donut/pie chart of total spent by category this month.
- A clean legend below: category dot + name + amount + percentage.
- A small period selector (This Month / This Year).

—— TAB 3: SETTINGS ——
Standard grouped iOS settings list:
- "Export to Google Sheets" as the main action (opens Export dialog).
- "Manage categories" (opens Add-category dialog).
- "Report a bug" (opens Bug-report dialog).
- Currency, theme.

—— DIALOGS / POP-UPS (light theme, visually consistent: same corner 
radius, button style, spacing) ——
1. Export to Google Sheets (from Settings): confirm dialog with title, 
   a line on what gets exported (month / date range), a primary 
   "Export" button in #8CC0EB, and "Cancel".
2. Add category (from Settings → Manage categories, AND from the Entry 
   page's Category pill): name field, line-icon picker (no emoji), an 
   optional color-swatch row drawn from the palette, "Save" button.
3. Report a bug (from Settings): short description text area, an 
   "include screenshot" toggle, "Send" button.

Start with TAB 1 (Home) and the ENTRY page. Show me those two first 
before designing the rest.
</pasted_text>

<!-- The user explicitly selected the following skills for this project, as attachments to their message. These are not optional context — they define how you work. Use them. -->
<attached-skill name="Hi-fi design">
Create a high-fidelity, polished design.

Follow this general design process (use the todo list to remember):
(1) ask questions, (2) find existing UI kits and collect design context — copy ALL relevant components and read ALL relevant examples; ask the user if you can't find them, (3) start your file with assumptions + context + design reasoning (as if you are a junior designer and the user is your manager), with placeholders for the designs, and show it to the user early, (4) build out the designs and show the user again ASAP; append some next steps, (5) use your tools to check, verify and iterate on the design.

Good hi-fi designs do not start from scratch — they are rooted in existing design context. Ask the user to Import their codebase, or find a suitable UI kit / design resources, or ask for screenshots of existing UI. You MUST spend time trying to acquire design context, including components. If you cannot find them, ask the user for them. In the Import menu, they can link a local codebase, provide screenshots or Figma links; they can also link another project. Mocking a full product from scratch is a LAST RESORT and will lead to poor design. If stuck, try listing design assets and ls'ing design system files — be proactive! Some designs may need multiple design systems — get them all. Use the starter components (device frames, design canvas) to get high-quality scaffolding for free.

When designing, asking many good questions is ESSENTIAL.

Give options: try to give 3+ variations across several dimensions. Mix by-the-book designs that match existing patterns with new and novel interactions, including interesting layouts, metaphors, and visual styles. Have some options that use color or advanced CSS; some with iconography and some without. Start your variations basic and get more advanced and creative as you go! Try remixing the brand assets and visual DNA in interesting ways — play with scale, fills, texture, visual rhythm, layering, novel layouts, type treatments. The goal is not the perfect option; it's exploring atomic variations the user can mix and match.

CSS, HTML, JS and SVG are amazing. Users often don't know what they can do. Surprise the user.

If you do not have an icon, asset or component, draw a placeholder: in hi-fi design, a placeholder is better than a bad attempt at the real thing.
</attached-skill>

<attached-skill name="Interactive prototype">
Create a fully interactive prototype with realistic state management and transitions. Use React useState/useEffect for dynamic behavior. Include hover states, click interactions, form validation, animated transitions, and multi-step navigation flows. It should feel like a real working app, not a static mockup.
</attached-skill>


<system-reminder>Auto-injected reminder (ignore if not relevant): do not recreate copyrighted or branded UI unless the user's email domain matches that company. Create original designs instead.</system-reminder>
```