# Conversation 07 — Admin page debugs + AllSpeak guidance overhaul

Date: 2026-06-07

---

## Summary

Intensive debugging session fixing the merged admin-main.as for filming.eclecity.net. The page now renders both the table and edit modal successfully. Along the way, numerous AllSpeak guidance gaps were identified and documented.

## Bugs fixed

- **DataRowDivs array never sized** — Added `set the elements of DataRowDivs to BookingCount` and `index DataRowDivs to I` before `create`
- **`put N into index of` wrong syntax** — Changed to `index DataRowDivs to I`
- **Garbled `on click` inside EmitRow** — Replaced with clean `on click DataRowDivs gosub OnRowClick` after the loop
- **FormatMoney used `left -2 of`** — Replaced with correct `from 0 to MoneyPos of` pattern
- **FormatMoney used `put 0 - MoneyVal`** — Changed to `negate MoneyVal giving TempStr`
- **FormatMileage used `left -1 of`** — Replaced with correct `from 0 to MilePos of` pattern
- **FyAndMmFromDate used `>=` C-style operator** — Changed to `is not less than`
- **FyAndMmFromDate `from 6` off-by-one** — Changed to `from 5` (month tens digit at position 5)
- **FyAndMmFromDate: `04` string comparison** — Changed to `the value of Mm is not less than 4`
- **FyAndMmFromDate: `put FY into NextYr` produces string** — Changed to `put the value of FY into NextYr` for arithmetic
- **FyAndMmFromDate: missing `begin...end` on multi-statement if/else** — Added blocks
- **`if Ch >= 'A'` C-style operators in slug code** — Changed to `Ch is not less than`
- **`set the location` not valid AllSpeak** — Changed Export button to `<a>` element in Webson
- **`the count of TempStr` should be `length of`** — Fixed string length reference
- **`index AllBookings to I` for JSON array** — Changed to `put element I of AllBookings into Row`
- **`modal-form` not found in DOM** — Restructured admin.json (sibling reference → physically nested, then reverted to sibling pattern after Webson fix)
- **`title-field` vs `title-input` mismatch** — Fixed attach target
- **Unused variable declarations removed** — ~30 removed, ~10 restored after detecting false positives
- **Missing variable declarations added** — MoneyLen, MoneyPos, Whole, CentsStr, MileLen, MilePos, FracStr, NextYr, Key
- **`gosub JsonAddString `slug`` → `gosub JsonAddString with `slug``** — Updated to new parameterized syntax

## AllSpeak guidance improvements

See session-2-status memory for full list. All changes in ~/dev/allspeak/learn/.

## New password set

Created make-credentials.php to generate bcrypt-hashed credentials file for login.

## Pending

- Colour highlighting refinement
- Awaiting-info flags
- Year filter (EditFyStart) mapping may be off when filter is active
- Modal form layout tweaks
