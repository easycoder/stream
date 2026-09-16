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

## Assistant (2026-09-16) — cleanup round

Graham: "Best to clean up now."

Checked the `stream-main.as` drift against history before touching it, which
changed the answer. The feature was **not** accidentally lost: conversation 08
records an explicit request — "Remove the '← Editor' button from the stream
viewer page" — and the assistant removed `$BackButton`, the variable, the
attach, the `CheckAuth` call and the `CheckAuth` subroutine. So the correct
cleanup was to correct the *docs*, not restore the feature.

- `stream-main.as` — corrected the opening doc block to state that the page is
  public and calls no auth endpoint, removed the three leftover variables
  (`AuthJson`, `AuthInfo`, `Authed`), and added the four missing `@hash` lines,
  which is why the drift had gone undetected.
- `admin-main.as` — removed three declaration-only variables of the same class
  (`DocumentUrlVal`, `BookingDacast`, `BookingRecordingUrl`), each read and
  written nowhere in the project.
- Committed as `4bed315` and `5f7b052`.

Verified: `asdoc-check.py` reports 0 error / 0 warning / 0 info on both files
(47 sections); no declaration-only variables remain in any of the four scripts;
zero dangling references to any of the seven removed names; label resolution
clean and `begin`/`end` balanced in all four (admin 66/66, stream 8/8,
account 73/73).

## Assistant (2026-09-16) — open items, not fixed

- **`admin-main.as` has an undocumented 228-line prelude.** Sections start at
  line 239; lines 1–238 (`script Admin`, every `div` handle and all ~127
  `variable` declarations) sit outside any `!! … !!!` doc block. The file does
  open with a `!` comment header explaining its purpose and the money/mileage
  conventions, so the intent is recorded — just in the older comment style.
  `account-main.as` (first block at 15), `stream-main.as` (3) and `asedit.as`
  (1) all have their preludes covered, so `admin-main.as` is the outlier.
  Left alone: wrapping it means choosing how to group the declarations and
  writing prose that asserts intent, which is Graham's call rather than a
  mechanical fix. Note this is also why removing those three dead variables
  raised no hash drift — that region isn't hashed.
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
- `reasonix.toml` still carries an unrelated auto-added tool-permission blob,
  left uncommitted.

