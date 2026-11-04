# Conversation 15 — Locations lookup

Date: 2026-11-04

---

## Summary

Booking a venue meant retyping its name, postcode and distance every time, even
though the same handful of crematoria and churches come round again and again.
This change adds a **locations** list: one `locations.json` file on the server,
a picker opened from the now read-only Location field, and a small editor for
the four fields (`Name`, `Postcode`, `Distance`, `Notes`).

The list is created on first use by walking the existing booking files, so a
deployed site starts populated. Records sharing a postcode are treated as the
same venue, the most common spelling wins (ties go to the newest booking), and
the bookings that used another spelling are rewritten to match. Renaming a
location later sends an explicit `{from, to}` list with the save, and the server
applies it to every booking file — the global search/replace.

Three choices were put to the user before building:

- **Picking** — click the row; Edit and Delete are separate buttons beside it.
- **Notes** — the venue note stays with the venue and is never copied into a
  booking's own Notes.
- **First-run merge** — merge by postcode as well as by name, then update the
  bookings to the chosen spelling.

## User (2026-11-04)

I tend to visit the same locations more than once, so it would be helpful to
have a separate set of records for these, to avoid re-typing. Each record will
comprise the following fields: Name, Postcode, Distance, Notes. The data should
fit into a single JSON file, to be kept on the server. We can initialize it by
iterating all current records. If there are any inconsistencies, such as in the
names, then just pick one and adjust the others.

In the main edit page, the Location field will be non-editable and have an Edit
button at the end. When clicked, this will bring up a window with a scrolling
list of all saved locations, each with buttons New, Edit and Delete. The window
will have Save and Cancel at the bottom. Clicking New or Edit brings up another
popup with all the above fields, all editable. Where the name has changed, a
global search/replace will be needed. If the editor is opened with a blank
value, it will be treated as a New.

## Assistant (2026-11-04) — data and endpoint

`locations.php` (new, added to `deploy.sh`):

- `GET` returns `locations.json`. If it does not exist, it scans every
  `data/**/*.json` booking with a non-empty `location`, groups records by
  normalised postcode (records without one group by name and fold into a
  same-named postcode group when there is exactly one), chooses the most common
  name / postcode / distance, and writes the bookings that used another name
  spelling. Ties go to the most recent booking. Notes start empty — booking
  notes are event notes, not venue notes.
- `POST` requires the admin session, validates and writes the whole list, and
  applies each `{from, to}` rename across every booking file by normalised name
  match. It returns `{status, renamed}`.

`locations.json` lives at the site root, not under `data/`, so `bookings.php`
does not mistake it for a booking. It is server-generated and deliberately not
in the deploy tar.

## Assistant (2026-11-04) — UI

`admin.json`:

- The Location row is now a read-only input (`Choose a location`) with an
  **Edit** button at the end.
- Added a **Locations** window (`location-overlay`, z-index 1100): title,
  **New location**, a scrolling `location-list`, status line, and Cancel / Save.
- Added the smaller **New/Edit location** window (`location-edit-overlay`,
  z-index 1200) with Name, Postcode, Distance, Notes and Cancel / Save.
- Both overlays sit under `AdminPanel`, so they disappear with the signed-out
  page; they are siblings of the booking overlay.

`admin-main.allspeak`:

- Loads the list on first open (`locations.php?cb=…`), stages edits in five
  arrays (names, postcodes, distances, notes, original names), and renders one
  row per venue. The row's clickable area is a child of the row, so the
  New/Edit/Delete buttons do not also trigger a pick.
- Clicking the row applies Name, Postcode and Distance to the booking and
  closes the picker. The venue Notes stay in the list.
- New/Edit opens the detail popup. A blank or missing name opens it as New.
  Saving checks for a duplicate name (case- and space-insensitive) before
  changing the staging arrays. Delete asks for confirmation.
- The window's Save builds the whole `{locations, renames}` body, posts it with
  the same session-expiry recovery used by booking saves, re-baselines the
  original names, and refreshes the table when a rename happened. If the
  booking being edited used the old name, its Location field is updated too.
- Cancel discards the staging arrays and forces a fresh load next time.

## Assistant (2026-11-04) — verification and caveat

- `python3 asdoc-check.py admin-main.allspeak` — 45 sections, 0 errors,
  0 warnings.
- `python3 -m json.tool admin.json` — valid.
- `node /tmp/phpcheck/parse.js` — `locations.php` parses with php-parser.
- Browser test against a mock `locations.php`: three rows loaded; picking a row
  filled Location/Postcode/Distance; editing a name produced a POST body with
  the renamed record and a `{from,to}` rename; New added a row; Delete removed
  it after confirmation; outer Save persisted the list; Cancel discarded a
  staged rename and reopening showed the server names. Console showed no runtime
  errors.
- **PHP is not installed locally**, so `locations.php` has not been executed
  against real booking files. Syntax is parsed and the request/response shape is
  exercised by the mock; smoke-test the deployed endpoint (open the picker and
  confirm the first build) before relying on the one-time merge.

## User (2026-11-04)

I've updated AGENTS.md so please re-read.
The locations update works well, but shows that the Postcode and Distance
fields no longer needs to be shown in the main form.

## Assistant (2026-11-04) — hide the filled-in fields

- `admin.json`: `$PostcodeRow` and `$DistanceRow` are now `display: none`. They
  still render, so the script can attach and fill them, but they take no space
  in the form.
- `admin-main.allspeak`: removed the per-kind `display` toggles for those rows
  and their inputs. The location picker is now the only place the values are
  seen, in its own list.
- The values still travel: `PopulateForm` loads them from the record,
  `OnLocationPick` writes the venue's postcode/distance into the hidden inputs,
  and `OnSave` serialises them as before. Mileage auto-fill still reads the
  hidden Distance field.
- `DIFF.md` added with the action (reload, or redeploy for the live site).
- Verified in a browser: the General tab shows Date, Time, Name, Location +
  Edit, Mileage, Expense and Fees only. Picking St Mary's set the hidden
  `postcode-input` to `LS2 3CD` and `distance-input` to `14`; both rows computed
  `display: none`.

## User (2026-11-04)

On testing I notice that the Edit button on the Location line in the main form
isn't needed. The entire field can be the button.

## Assistant (2026-11-04) — make the field the button

- `admin.json`: removed `$LocationEditBtn` and gave the read-only Location input
  `cursor: pointer` plus a `Click to choose a location` tooltip.
- `admin-main.allspeak`: removed the button's declaration and attachment and
  moved the `OnOpenLocations` handler onto `LocationInput`. The location doc
  block now says the field itself opens the picker.
- Verified in a browser: clicking the field opened the Locations window; picking
  Our Lady of Sorrows set the field and the hidden postcode/distance to
  `LS3 4EF` / `8`; no `location-edit-btn` element remains and the field's
  computed cursor is `pointer`.

## User (2026-11-04)

In Edit booking, in the Data tab, there's an extra space in front of the Paid
checkbox that misaligns it with the other checkboxes.

## Assistant (2026-11-04) — align the Paid checkbox

- `admin.json`: `$PaidInput` was missing the `margin: 0.2em 0` and
  `flex-shrink: 0` that `$LinkSentToggle` and `$InvoicedToggle` carry, so the
  browser's default checkbox margin pushed it right.
- Verified in a browser: all three checkboxes now share the same left edge
  (155.2px) in the Data tab, and the screenshot shows them in line.



