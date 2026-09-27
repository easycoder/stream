# Conversation 13 — Rename the source extension `.as` → `.allspeak`

Date: 2026-09-27

---

## Summary

Every AllSpeak source file in the project moved from `.as` to `.allspeak`, and
every place that named one of those files was updated to match.

The change follows the upstream allspeak repository, whose `DIFF.md` records the
policy: 318 tracked `.as` files renamed to `.allspeak`, ~326 docs/config files
swept, and **both runtimes accept either extension** during the transition (the
Python CLI's globs and `--test`, the dev server's MIME map and `/list` filter,
the editor's save-as default, and both `asdoc-check` tools). So nothing here was
*broken* by the old spelling — the rename is about the name on disk, plus the
handful of places where the extension is written down and therefore has to
follow.

The one functional requirement in the request — "ensure asedit lists `.allspeak`
files" — is satisfied in `server.allspeak`: the editor has no extension filter of
its own, it renders whatever `/list` returns. The filter lives in the server's
`entries in … type …` argument, which was broadened from `as,ecs,…` to
`allspeak,as,ecs,md,txt,json,html,css,js,py` (matching upstream, which also added
`py` so the editor can open its own tooling). Legacy `as` is kept in the list and
in the MIME map so old files still open.

## User (2026-09-27)

Please change all .as extensions to .allspeak, in line with new AllSpeak policy.
Also ensure asedit lists .allspeak files.

## Assistant (2026-09-27)

**Files renamed** (`git mv`, so history follows): `account-main`, `admin-main`,
`asedit`, `build`, `index-main`, `seed`, `server`, `stream-main` — `.as` →
`.allspeak`.

**Files whose contents name a script:** `account.html`, `admin.html`,
`index.html`, `stream.html` (`rest get Script from …`), `edit.html`
(`fetch('asedit.allspeak')`), `deploy.sh` (upload list + comments),
`README.md`, `AGENTS.md`, `.htaccess` (comment), `reasonix.toml` (the recorded
tool-permission strings), `plugins/codemirror-ecs.js` (comment).

**In the scripts themselves:**

- `server.allspeak` — usage lines; the self-update downloads (`server.allspeak`,
  `asedit.allspeak`); the `/restart` re-exec line; the `/list` type filter and
  the MIME map as described above. The result is byte-identical to upstream's
  canonical `server.allspeak` apart from a missing trailing newline (which was
  already missing before this change).
- `asedit.allspeak` — banner; the four `StrSaveAs` prompts ("Save as (filename
  without .allspeak)" and its it/fr/de translations); the save-as default
  extension (`put File cat `.allspeak` into File`); the `server.allspeak` and
  `tools/asdoc-check.allspeak` cross-references.
- `build.allspeak` — banner/usage and the `cp account-main.allspeak` line.
- `seed.allspeak` — banner/usage and a cross-reference to `account-main.allspeak`.
- `account-main.allspeak` — banner, the `server.allspeak` loading note, and the
  `OnExport` prose that names `build.allspeak` and the server's `/build` route.
- `admin-main.allspeak`, `index-main.allspeak`, `stream-main.allspeak` — banners.
- `asdoc-check.py` — default extension is now `.allspeak,.as` (comma-separated,
  legacy still checked), matching upstream's tool exactly.

## Assistant (2026-09-27) — verification

- `asdoc-check.py` on all eight scripts: **0 errors**, and the only warnings are
  `verify-stale` in `asedit.allspeak` (see below). `--write` was run after the
  edits; it rewrote four `@hash` lines and touched nothing else (diffed before
  and after to confirm). One of those also cleared a `hash-stale` warning in
  `build.allspeak` that predated this change.
- Compile check via the Python runtime against copies of the same files from
  `HEAD`: the same files compile and the same files fail, with the same errors
  (`div Body` needs the browser module). No regression.
- Live server: `allspeak server.allspeak 8123` then `GET /list` returns
  `account-main.allspeak`, `asedit.allspeak`, … and `GET /read/admin-main.allspeak`
  returns the source. This is exactly the call `asedit` makes to build its file
  browser, so the editor now lists the renamed scripts.
- Nothing was downloaded by the dev server's self-update: local `.code-version`
  is `2` and `https://allspeak.ai/code/code-version` is also `2`, so the update
  block did not fire (the old `server.as` URL now 404s, so this route was
  effectively dead before and is correct after).

## Assistant (2026-09-27) — open items, not fixed

- **Two human verifications were invalidated.** The `StrSaveAs` block
  (`asedit.allspeak:272`) and the save-as block (`asedit.allspeak:409`) both
  carry `@verified` sign-offs, and this change edits code inside them. The tool
  never touches `@verified`, so they are now flagged `verify-stale` and want a
  human re-read. `asedit.allspeak` already had five stale verifications before
  this change; it now has seven. Upstream hit the same thing and recorded it as
  an open question rather than re-verifying.
- **`conversation/*.md` were deliberately not swept.** They are transcripts of
  work done when the files really were `.as`; rewriting them would falsify the
  record. Upstream's own rename commit left its conversation logs alone.
- **The deployed site still has the old names.** `deploy.sh` now uploads the
  `.allspeak` files and the updated HTML, but it does not delete the old `.as`
  files already on DreamHost — they will linger as dead weight until removed by
  hand.
- **`asedit.allspeak` here is an older fork** (38 KB) of the upstream editor
  (53 KB). That was already true. Worth knowing because the server's self-update
  now points at a URL that exists: a future `code-version` bump would overwrite
  this local copy with upstream's newer one. (It would also drop the trailing
  newline mismatch noted above.)
