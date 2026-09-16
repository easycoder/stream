# Conversation 12 — Keep the admin session alive so a long-idle tab keeps working

Date: 2026-09-16

---

## Summary

### The problem

Leaving the admin editor tab open for a long while made it stop working: the
next request to a PHP endpoint failed, and only a page refresh (plus a fresh
sign-in) put it right.

Cause: PHP deletes a session file once it has gone unwritten for
`session.gc_maxlifetime` (1440 seconds — 24 minutes — with the defaults at
DreamHost). An idle admin tab makes no requests at all, so the session is
collected while the tab sits open. `bookings-save.php` then answers
`401 {"status":"fail","error":"Not authenticated"}`, and the page — which
still *looks* signed in — can no longer save.

### The fix

Two new server-side pieces and a handful of changes in `admin-main.as`:

- **`heartbeat.php`** (new) — stamps `$_SESSION['heartbeat'] = time()` for a
  signed-in user, which forces PHP's lazy session writer to rewrite the file
  and restarts the garbage collector's clock. It also reports
  `authenticated: yes|no`, so it doubles as an auth probe. It deliberately
  does **not** stamp anonymous sessions, which would otherwise leave a live
  session file behind for every passing visitor.
- **`admin-main.as`** — a `Heartbeat` thread forked on page load pings the
  endpoint every 10 minutes, comfortably inside the 24-minute window.
- **`admin-main.as`** — the save path now diagnoses its own failures. The
  runtime reports any non-2xx reply as one undifferentiated failure and
  discards the body (confirmed in `allspeak.js`: `onFailure(\`${response.status}
  ${response.statusText}\`)`, no body delivered), so a 401 and an unreachable
  server are indistinguishable from the script's side. On a failed save the
  script now asks `heartbeat.php` whether the session is still valid. If it is
  not, `RecoverSession` re-signs-in from the credentials still held in the
  login fields and the save is retried — a long-idle tab quietly carries on
  working instead of silently failing.

Supporting refactors: `OnLogin` was split into `OnLogin` + `BuildLoginBody`
(so login and recovery share one body builder, writing to a separate
`LoginBody` variable so the record in `BodyText` survives the retry), and the
save POST was extracted into `PostSave` so it can be issued twice.

**Files changed:** `heartbeat.php` (new), `admin-main.as`, `deploy.sh`.

### The near-miss

`deploy.sh` carries an explicit file list (a deliberate choice — see the note
in the script: "These are excluded by listing only the production files
explicitly below"). `heartbeat.php` was not added to it, so the endpoint would
have 404'd in production, the heartbeat would have failed silently, the
session would still have expired, and the fix would have done nothing at all.
Added to the tar list. This is the **second** time this has bitten us — the
same thing happened to `allspeak.js` in conversation 09.

---

## Transcript

## User (2026-09-16)

When Reasonix crashed it was working on a fix to the problem where if I leave
the 'stream' tab open, after a while something times out, it can't access the
PHP script (?) and I have to refresh the page. Can you see how things stand
now?

## Assistant (2026-09-16)

Recovered the state. The fix was written on 2026-09-16 ~18:17 but left
uncommitted, and the crash happened before it was finished or verified.

What was already on disk and intact:

- `heartbeat.php` — new, untracked.
- `admin-main.as` — heartbeat thread, `CheckSession`, `RecoverSession`,
  `PostSave`, `BuildLoginBody`.

Verified statically (no live browser/PHP available in this environment):

- `python3 asdoc-check.py admin-main.as` — 43 sections, 0 errors, doc-block
  hashes in sync.
- All 45 labels defined; every `gosub` / `fork` target resolves; `begin`/`end`
  balanced 66/66; all 12 newly-used variables declared.
- `allspeak.js` confirms the design premise: non-2xx replies reach the script
  as a single undifferentiated failure with the body discarded, so the auth
  probe is a necessary workaround rather than belt-and-braces.
- `bookings-save.php` does return `401 Not authenticated` when the session is
  gone, matching the reported symptom.

What was **not** done, and why the fix would not have worked:

- `deploy.sh` did not ship `heartbeat.php`. Deploying as-is would 404 the
  endpoint, so the session would still expire.

Finished off:

- Added `heartbeat.php` to the `deploy.sh` tar list (and to the header
  comment's endpoint list). Verified: `bash -n deploy.sh` clean, all listed
  files exist, and the archive builds with `heartbeat.php` in it (23 files).
- Committed everything except `reasonix.toml`, which held an unrelated
  auto-added tool-permission blob — left in the working tree for Graham to
  decide on.
- Wrote this log.

## Assistant (2026-09-16) — open items, not fixed

- **`stream-main.as` has doc-block drift.** The opening block promises
  "then fire `gosub CheckAuth` to opportunistically reveal the back-to-editor
  link for a logged-in admin", and `AuthJson` / `AuthInfo` / `Authed` are
  still declared — but no `gosub CheckAuth` call and no `CheckAuth` label
  exist anywhere in the file. The viewer is effectively public-only.
  Separately, the file's four doc blocks have no `@hash` line, so
  `asdoc-check.py` cannot detect code drift there and reports them
  (informationally) on every run. Pre-existing; unrelated to this session's
  fix, so left alone.
- **The heartbeat assumes the tab's timers keep running.** A backgrounded tab
  is throttled by the browser, and a discarded/frozen tab (or one restored
  from the back/forward cache) will not ping at all. The 10-minute interval
  against a 24-minute lifetime gives roughly 2.4× margin, which covers normal
  throttling; it is not a guarantee. If the symptom recurs, the interval is
  the first thing to shorten, and re-testing should include a genuinely
  backgrounded tab left open for well over 24 minutes.
- **Not yet exercised end-to-end.** `heartbeat.php` was never run — there is
  no `php` binary in this environment — and the GUI script cannot be compiled
  statically here, because `div` needs the browser module. A local
  `allspeak server.as -t admin` session would settle both.
- The remote `session.gc_maxlifetime` was not checked. If DreamHost sets it
  below ~20 minutes, the 10-minute ping is the wrong number.
