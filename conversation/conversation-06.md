# Conversation 06 — Merge account + streams onto filming subdomain

Date: 2026-06-06

---

## Summary

Began merging the account project (service log) with the streams project (live-stream management) into a single app on its own subdomain **filming.eclecity.net**.

## What was built

### Infrastructure (Phase 1)
- PHP endpoints: `bookings.php`, `bookings-save.php`, `bookings-delete.php`, `export.php`
- `.htaccess` routing `/` → admin, `/{slug}` → public viewer
- `deploy.sh` using tar+ssh
- `login.php`, `auth-check.php` copied from streams project

### Admin page (Phase 3 — skeleton)
- `admin.html` launcher
- `admin.json` Webson layout with login panel, service log table, and combined edit modal
- `admin-main.as` AllSpeak script (~1200 lines) with:
  - Login flow
  - Data loading from `bookings.php`
  - Table rendering with monthly subtotals and grand total
  - Conditional colouring (red for unpaid+invoiced, amber for unpaid+not-invoiced)
  - Combined edit modal with all service + stream + contact + financial fields
  - Save, delete, export

### Data migration (Phase 2)
- `migrate-data.py` Python script
- 12 stream records matched with account rows and merged
- 7 account-only records (expenses, slideshow)
- 19 total records deployed to server

## Bugs fixed
- `server.as`: `system` does not support `or` — removed the failure clause
- `admin-main.as`: added missing `variable FY` and `variable Mm` declarations
- `admin-main.as`: replaced all 6 `loop` instances with `if`/`else if` chain pattern

## Known AllSpeak pitfalls discovered
- `system` does NOT support `or` / `on failure` clauses
- `loop` does not exist — added to CLAUDE.md's common-mistakes list alongside `continue` and `break`
- Use `if`/`else if` chains or `gosub`/`return` to skip work inside a loop

## Pending
- admin-main.as hasn't been tested in a browser yet — may have further errors
- Colour highlighting and awaiting-info flags to refine
- User needs to test login and report console errors

## Key files
- `~/dev/filming/` — project root
- `https://filming.eclecity.net/` — live site
- `./deploy.sh` — deployment script
- `./admin-main.as` — main admin script
- `./migrate-data.py` — data migration script (one-off)
