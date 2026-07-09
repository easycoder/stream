# Conversation 10 — Remember-me auto-login and Notes field

Date: 2026-07-08

---

## Summary

### Remember-me auto-login (admin-main.as + admin.json)

Added a "Remember me" checkbox to the login panel. When checked, the username
and password are saved to browser localStorage (`admin.credentials`). On
subsequent visits the credentials are pre-filled and login fires automatically.

**Race condition fix:** The auto-login's `gosub OnLogin` does an async
`rest post`. If the server responded quickly, the OnLogin continuation would
show AdminPanel — but the bootstrap's unconditional `set style 'display' of
AdminPanel to 'none'` immediately hid it again. Fixed by making the hide
conditional (only when no saved credentials exist) and hiding AdminPanel
up-front during auto-login so the user only sees the login panel with
pre-filled fields during the POST.

**Files changed:** `admin.json` (added `$RememberRow` to login panel),
`admin-main.as` (variable, attach, auto-login check, save/clear logic,
failure-path AdminPanel hiding).

### Notes field (admin-main.as + admin.json)

Added a `notes` textarea (7em, ~5 lines) to the booking modal form, always
visible regardless of kind (service/expense/slideshow). Stored as a `notes`
property in the booking JSON. Not rendered in the table — only visible when
editing a booking.

**Files changed:** `admin.json` (added `$NotesRow` at bottom of `$Fields`),
`admin-main.as` (11 touch points: declarations, attach, clear, populate,
3× kind toggles, save, JsonAddString).
