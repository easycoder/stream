# Conversation 09 — Local allspeak.js + deploy fix

Date: 2026-06-30

---

## Summary

Switched all HTML files from loading `allspeak.js` from the CDN (`https://allspeak.ai/dist/allspeak.js`) to a local copy, so upstream changes can't break this project. Fixed `deploy.sh` to include the new file.

---

## User (2026-06-30)

Console crashed — did I have a record of the last request? (No — compaction relay was empty, last conversation log was 08 from June 12.)

## User (2026-06-30)

The last request was to serve allspeak.js locally instead of from the allspeak website, to avoid a change for another project crashing this one.

## Assistant (2026-06-30)

- Downloaded `allspeak.js` (383 KB) from the CDN and saved it locally.
- Downloaded CodeMirror plugins (`plugins/codemirror.js`, `plugins/codemirror-ecs.js`, `plugins/codemirror/codemirror.js`, `plugins/codemirror/codemirror.css`) from the CDN for `edit.html`.
- Updated `account.html`, `admin.html`, `stream.html`, `index.html`: `s.src` changed from `https://allspeak.ai/dist/allspeak.js` to `allspeak.js`.
- Updated `edit.html`: all four allspeak.ai-hosted script/CSS URLs changed to local paths; CodeMirror Cloudflare CDN addons left as-is (version-pinned).
- Updated `AGENTS.md` GUI template to use local path for future projects.

## User (2026-06-30)

Ran deploy.sh but website doesn't load — console shows 404 for `allspeak.js`.

## Assistant (2026-06-30)

`deploy.sh` has an explicit file list and `allspeak.js` wasn't in it. Added `allspeak.js` to the deploy list.

## User (2026-06-30)

Re-ran deploy.sh — all working now. Closing session.
