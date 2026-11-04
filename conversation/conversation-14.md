# Conversation 14 — Split the edit form into four tabs

Date: 2026-11-04

---

## Summary

The booking edit modal in `admin.json` had grown to 27 stacked field rows, long
enough that the Save/Cancel buttons sat below the fold. This change splits those
rows across four tabs — **General**, **Contacts**, **Data** and **Text** —
placed between the existing top row (kind buttons plus Stream / Email 1 /
Email 2) and the existing bottom row (Delete / Cancel / Save). Both button rows
stay fixed for every tab.

The rows were only rearranged, not renamed or rewired: every `@id` the script
attaches to is unchanged, so save/load continues to read the same inputs.
`admin-main.allspeak` gained the tab-switching code and one extra rule — a kind
that leaves a tab empty hides that tab, so an expense is never offered an empty
Contacts page and a slideshow is never offered an empty Data page.

## User (2026-11-04)

I would like to split the data editing form into 4 tabbed pages, as follows:

Tab title: General — Date, Time, Name, Location, Postcode, Distance, Mileage,
Expense, Fees.

Tab title: Contacts — Client Rep, Client company, Client email, then a space,
then Contact name, Contact relation, Contact phone, Contact email.

Tab title: Data — Stream URL, Dacast ID, Recording URL, Tribute video URL,
Document, Link sent, Invoiced, Paid.

Tab title: Text — Stream title, Recording description, Notes.

The buttons at the top and the bottom remain the same for all tabs (so the tabs
are in their own panel).

## Assistant (2026-11-04) — layout

`admin.json`, `$FormFields` (inside `$ModalForm`):

- Added `$TabBar` with four `button` elements: `general-tab-btn`,
  `contacts-tab-btn`, `data-tab-btn`, `text-tab-btn`.
- Added four panel containers: `general-panel` (visible by default),
  `contacts-panel`, `data-panel`, `text-panel` (all `display: none`).
- Moved the existing row components into the panels in the requested order.
  Contacts gets a `$ContactsSeparator` — a hairline `border-top` with vertical
  margin — between the client fields and the contact fields.
- `$KindButtons`, `$ModalStatus` and `$Buttons` stay where they were, outside the
  tab bar and panels, so top and bottom controls are common to every tab.

The row definitions remain inside `$FormFields` as symbols; the panels reference
them, and Webson's auto-build logic skips definitions already listed in a
sibling's `#`, so each row renders once inside its panel.

## Assistant (2026-11-04) — behaviour

`admin-main.allspeak`:

- Declared and attached the four buttons and four panels.
- `TabActiveStyle` / `TabInactiveStyle` style the bar; the JSON defaults match
  the script defaults (General active, others hidden).
- `ShowGeneralTab` / `ShowContactsTab` / `ShowDataTab` / `ShowTextTab` set
  `ActiveFormTab`, then `ShowActiveTab` hides all four panels, restyles the
  buttons, and reveals the chosen panel.
- `SyncTabsToKind` is called at the end of each `SelectKind…` handler. It moves
  the selection back to General if the active tab is about to become
  unavailable, and `ShowActiveTab` hides the empty tab:
  - Expense → Contacts hidden (General, Data, Text remain).
  - Slideshow → Data hidden (General, Contacts, Text remain).
  - Service → all four shown.
- `OnAdd` and `PopulateForm` reset `ActiveFormTab` to `general`, so the modal
  always opens on the first tab.
- Added a doc block for the tab section and extended the kind-selection doc
  block to explain the tab-hiding rule.

## Assistant (2026-11-04) — verification

- `python3 -m json.tool admin.json` — valid JSON.
- `python3 asdoc-check.py admin-main.allspeak` — 44 sections, 0 errors,
  0 warnings; `--write` refreshed the changed hashes and inserted one for the
  new section.
- `git diff --check` — clean.
- Browser check (static `python3 -m http.server 8090`): the runtime compiled
  `Admin` (2214 lines) without error. With the admin panel forced visible, **Add
  booking** opened on General; Contacts, Data and Text each showed exactly their
  requested fields and only one panel at a time; Cancel/Save and the kind/Stream
  /Email row stayed visible on every tab. Switching to Expense hid Contacts,
  Slideshow hid Data, and Service restored both. Reopening the modal after
  closing it on Contacts started on General.
- `allspeak server.allspeak 8090` returned HTTP 503 “Server handler not ready”
  in this environment: the startup update check stalls before the request
  handler is registered. The static Python server was used for the UI test
  instead; this is an environment/network limitation, not a project change.

## Assistant (2026-11-04) — deployment cache fix

After deploy, the live page showed the sign-in panel with the service log directly
below it and then aborted with:

```
Runtime error in 'Admin':
Line 318: No such element: 'general-tab-btn'
```

Cause: the deployed `admin-main.allspeak` was the new one, but the browser was
still using a cached **old** `admin.json`. DreamHost serves `.json` (and
`.allspeak`) with `Cache-Control: max-age=172800` — two days — so a returning
visit pairs the new script with the pre-tab layout. `attach GeneralTabBtn` then
fails, and because the startup aborts before the credentials check, the admin
panel is never hidden (hence sign-in + service log both visible).

Confirmed by fetching the live files (`admin.json` does contain
`general-tab-btn`) and by reproducing locally: the new script with
`git show HEAD:admin.json` produced the identical line-318 error and the same
two-panels-visible state.

Fixes:

- `admin.html` now cache-busts the bootstrap fetch:
  `admin-main.allspeak?cb=` cat a random number.
- `admin-main.allspeak` now cache-busts the layout fetch:
  `admin.json?cb=` cat `CacheBuster`, using the random already declared for the
  bookings request.
- `.htaccess` sends `Cache-Control: no-cache, must-revalidate` for `.json` and
  `.allspeak` (inside `<IfModule mod_headers.c>`), so future deploys do not
  inherit a two-day window.

Verified the new fetches hit the server (`admin-main.allspeak?cb=988728058`,
`admin.json?cb=60920505`, both 200) and the modal still opens on General with
all four tabs.

Note for the deployed site: a browser that already holds the old `admin.json`
must hard-reload once (Ctrl+F5) after this deploy, or wait for the 10-minute
`admin.html` cache to expire; the new launcher's cache-buster then bypasses the
stale layout.

## Assistant (2026-11-04) — notes

- The documented `@id="form-fields"` container remains as the tab wrapper; it is
  not referenced from the script.
- The modals still open with a `max-height: 85vh` scroll container. With one tab
  visible at a time, the General tab now fits without scrolling.
- Save-time auto-fill of Mileage and Expense still runs regardless of which tab
  is on screen, because it reads and writes the inputs directly.
