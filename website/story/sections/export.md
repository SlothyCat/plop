# Google Sheets export

One-way, on-demand export to Google Sheets using stateless **PKCE OAuth** — no Google SDK, no token storage.

:::voice[From the author]
This was not fully implemented by Claude as I needed to create the OAuth *by hand*. It is also my first time
doing an OAuth setup on my own. It was quite interesting, but I was genuinely scared of potentially exposing
keys. It did expose the `Client ID` which is okay, I still did a cleanup so that it is not reflected in
the planning files.
:::

Actual footage of me panicking:
<br>

![me panicking at exposed Client ID](/img/client_id_panic_prompt.png)

**In the Reference:** [Export design](/reference/settings-export/design)
