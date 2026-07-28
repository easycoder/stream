# Conversation 11 — Fix Notes field not saving

Date: 2025-07-11

---

## Summary

Investigated and fixed the "Notes" field not persisting. The front-end (`admin-main.as`) correctly included `"notes"` in the JSON save request body, but `bookings-save.php` was missing the `notes` key from its `$record` array — notes arrived at the server but were silently discarded. Added `'notes' => $body['notes'] ?? '',` to the record builder. User confirmed the fix works.
