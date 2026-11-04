# What changed

Reload the admin page; redeploy if you are checking the live site.

- Added a **Clients** lookup, opened by clicking any of the client fields in the **Contacts** tab. The window lists saved clients, sorted by **Client company** then **Client rep**; clicking a row fills Client company, Client rep, Client phone and Client email. New/Edit/Delete and Save/Cancel work as in the Locations window.
- The Clients window has a **No client** button: it clears the four client fields and closes the window, so a booking can be saved with only the family contact.
- Added **Client phone** to the booking record and the client record. The pair **Client company + Client rep** is the client key; renaming either updates the bookings that used the old pair. Phone and email are shared data on the client record, so editing them affects future picks, not historic bookings.
- `clients.php` builds `clients.json` from the existing booking files on first use, grouping by company + rep and normalising spelling. Deploy includes the new endpoint.

No data migration is needed.
