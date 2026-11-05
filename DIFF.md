# What changed

Reload the admin page; redeploy if you are checking the live site.

- Clicking any client field now opens the editor for that client directly, or a new client form when the company + rep pair is not saved. The editor footer is **Show all / Cancel / Save / Select**.
  - **Save** writes the client and returns to the caller — the main form, or the clients list.
  - **Select** writes the client, applies company, rep, phone and email to the booking, and returns to the main form.
  - **Show all** opens the clients list.
- In the clients list, clicking a row opens its editor; each row now has only **Delete**. **New client** and **No client** remain at the top. A row click no longer selects straight away — use **Select** in the editor.
- **No client** still clears all four client fields.
- Every Save/Select writes the full client record; a change to company or rep still triggers the global rename.

No migration or other data change.
