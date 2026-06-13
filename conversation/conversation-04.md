# Conversation 04 — Link Sent + Paid become boolean toggles

## User (2026-05-23)

1. I need a column added to the account. The title is "Link Sent". The data is boolean; it shows a checkbox or a tick when True and blank when False. On the data entry form it appears as a date when selected, blank otherwise, with a button to select/deselect. The column appears between "Client" and "Mileage".

2. The "Paid" column serves no useful purpose as is, so I want to move it to follow "Fees" and to set it to perform a similar function to "Link Sent". All saved records will need to be updated; they can be set to "False" and I'll edit them individually.

---

## Assistant (2026-05-23)

Implemented both changes together since they share UX, schema, and rendering paths.

**Schema** — added `linkSent`; redefined `paid`. Both fields are now either a falsy value (`false` or absent) when not set, or an ISO date string `YYYY-MM-DD` recording when the user toggled them on.

**Data migration** — walked `data/*/*.json` and `sample.json`, overwriting every row's `paid` (previously integer pence) with `false`. Ten data rows and seven sample rows migrated.

**Table column layout** — grid widened from 13 to 14 columns. New width string `50 100 1fr 60 1fr 90 80 100 120 70 110 90 90 70`. Header order is `Seq Date Name Time Location Postcode Distance Contact Client Link-sent Mileage/Item Expense Fees Paid`. Link Sent and Paid columns render a centred `✓` when truthy and a blank cell otherwise; both header cells are centre-aligned. Subtotal and grand-total rows now have only Mileage, Expense, and Fees figures — the Paid totals were dropped since Paid is no longer monetary. All three row emitters (`EmitDataRow`, `EmitSubtotal`, `EmitGrandTotal`) re-verified to emit exactly 14 cells.

**Modal form** — removed the old `paid-input` text field. Added matching toggle controls for both Link Sent and Paid: a single button whose label switches between `Set` (grey) and `Clear` (blue), plus a small date display next to it. Toggling Set captures today's date in `YYYY-MM-DD` form via `the year` / `the month` / `the day number` (the bare accessors return components of "now"); toggling Clear empties the value. Row order in the modal is unchanged through Fees and Link, then the two new toggle rows go at the bottom.

**New subroutines** — `ComputeTodayIso` (builds today's date string, zero-padding the month and day); `RefreshLinkSentDisplay` and `RefreshPaidDisplay` (the single point where state translates into DOM); `OnToggleLinkSent` and `OnTogglePaid` (the click handlers, wired in the boot section).

**Other touched files** — `account.json` (header grid + new modal rows for the two toggles); `seed.as` updated so a re-import would produce `paid: false` and `linkSent: false` rather than the old monetary `paid`. Doc blocks refreshed via `asdoc-check.py --write` for both `account-main.as` and `seed.as`.

**Verification** — launched `server.as`, fetched the rendered page with headless Chromium, and confirmed: layout matches the spec (Link Sent between Client and Mileage; Paid last); no console errors; clicking Add Booking opens the modal; clicking each toggle flips its button to `Clear` and shows today's date `2026-05-23`; the old `paid-input` element is no longer in the DOM.
