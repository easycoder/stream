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

## User (2026-11-04)

The strategy we applied to Locations can also be applied in a similar way to
Clients. Here the combination of Client rep and Client company is unique.
Shared data are 1) a new 'Client phone' field and 2) the existing client email
address. In the listing, the sort order is Client company then Client rep.

## Assistant (2026-11-04) — Clients lookup

- `clients.php` (new, added to `deploy.sh`): `GET` builds `clients.json` from
  the booking files on first use, grouping by normalised company + rep,
  choosing the most common spelling of each (ties to the newest booking), and
  rewriting the booking keys that used another spelling. `POST` saves the list
  and applies each `{old_company, old_rep, company, rep}` rename to every
  booking with the old pair. Sort order is company, then rep.
- `bookings-save.php`: stores the new `client_phone` field.
- `admin.json`: added a **Client phone** row after Client email. All four client
  fields (rep, company, email, phone) are read-only and clicking any of them
  opens the Clients window. The window has a scrolling list sorted by company
  then rep, New/Edit/Delete on each row, a top-level New client, and
  Cancel/Save. The detail popup edits company, rep, phone and email.
- `admin-main.allspeak`: added the client staging arrays, list rendering,
  pick/New/Edit/Delete, duplicate-key check, save-and-rename body, and the same
  session-recovery retry as booking saves. `client_phone` is loaded in
  `PopulateForm`, cleared in `OnAdd` and serialised by `OnSave`. Phone and email
  edits update the client record and future picks only; the global replace is
  for the company + rep key, matching Locations.
- Verified in a browser against a mock endpoint: the list opened from the
  Client company field in the required company-then-rep order; picking
  Mason & Sons / Sarah Bell filled all four fields; renaming the company to
  Mason & Sons Ltd produced a POST body with the matching `old_company` /
  `old_rep` rename and updated the open booking; New and Delete worked; the
  booking save posted `client_phone: 07700 900111` alongside client, contact
  and client_email. `asdoc-check.py` reports 46 sections, 0 errors, 0 warnings;
  `clients.php` and `bookings-save.php` parse with php-parser.
- **PHP is still not installed locally**, so `clients.php` has not been executed
  against real booking files; smoke-test the first list build on deployment.

## User (2026-11-04)

I forgot to mention should be an option to have no client (I deal directly with
the contact)

## Assistant (2026-11-04) — No client option

- Added a **No client** button to the Clients window. It clears Client company,
  Client rep, Client phone and Client email and closes the window, so a booking
  can be saved with only the family contact.
- Verified in a browser: selecting a client then clicking No client left all
  four fields empty and closed the window.

## User (2026-11-05)

The new locations feature is a bit counter-intuitive, so I want to improve it.
In Edit booking, when Location is clicked it should open the editing form for
that location. This will be as it is now but with two new buttons: "Show all"
will bring up the list of locations. "Select" will set this location in the
main editor and close the location editor. The button order will be "Show all",
"Cancel", "Save, "Select". "Save" will save the data and will return the user
to where this was called from. "Select" will save the data then return to the
main form. Please also ensure that all fields are saved. I think the Notes
field isn't currently saved.

## User (2026-11-05)

In the locations list, clicking the name edits it. Buttons New and Edit are not
needed per row.

## Assistant (2026-11-05) — direct location editor

- Clicking the read-only Location field now opens the location editor for the
  current venue (matched case-insensitively against the saved list), or a new
  venue form carrying the current name and hidden postcode/distance when there
  is no match.
- The editor footer is **Show all / Cancel / Save / Select**. Save writes the
  whole list and returns to the origin (main form or locations list); Select
  writes, applies Name/Postcode/Distance to the booking and closes both windows;
  Show all opens the list.
- The locations list now evaluates a row click as **Edit**: it opens the
  editor for that record. Per-row New/Edit buttons were removed; each row has
  only Delete, and New location remains at the top.
- Shared save path: `BuildLocationsBody` + `SaveLocationData` are used by the
  list Save and by the editor's Save/Select, so every path posts the full
  record. `StageLocationRecord` validates and stages the edit, `RebaseLocation-
  Names` re-baselines for the next rename, and `ShowLocationSaveError` keeps
  failures visible in the editor.
- Notes: verified in a browser against the mock — changing Notes and pressing
  Select posted `"notes":"Access via the side door. Ring the bell."`, and
  reopening the editor showed it. Changing Notes and pressing Save (from the
  main form) posted `"Save path notes."`; Save from the list returned to the
  list and updated the row. The list row now shows only Delete.

## User (2026-11-05)

That all works fine, so now do the equivalent for Clients.

## Assistant (2026-11-05) — direct client editor

- Clicking any read-only client field now opens the client editor for the
  current company + rep pair, or a new client form carrying the current
  company, rep, phone and email when the pair is not saved. The editor footer
  is **Show all / Cancel / Save / Select**.
- Save writes the whole client list and returns to the origin (main form or
  clients list); Select writes, applies company/rep/phone/email to the booking
  and closes both windows; Show all opens the list.
- The clients list now treats a row click as **Edit**. Per-row New/Edit buttons
  were removed; each row has only Delete. New client and No client remain at
  the top. No client still clears all four fields.
- Shared save path: `BuildClientsBody` + `SaveClientData` are used by the list
  Save and the editor's Save/Select; `StageClientRecord` validates/stages,
  `RebaseClientKeys` re-baselines the key pair, and `ShowClientSaveError` keeps
  failures visible in the editor.
- Verified in a browser against the mock: the editor opened directly, Show all
  listed clients with only Delete per row, a row click opened the editor,
  changing the phone and pressing Select applied all four fields and posted the
  change, Save from the main form persisted and returned to the main form, Save
  from the list persisted and returned to the list, No client cleared the
  fields, and a company rename posted the old/new pair in `renames`.
