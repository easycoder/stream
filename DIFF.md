# What changed

**Redeploy** (`./deploy.sh`) — the fix is in `index.html`, `manifest.json` and
`sw.js`. On the phone, reload the site, then install again.

The install failed because the install button was only offered from
`/admin.html`. The app's real address is the site root — `/` is `index.html`,
which boots `admin-main.allspeak` — and that page carried no manifest link and
registered no worker, so a phone opening the domain got "This app cannot be
installed".

- `index.html` now carries the manifest link, theme colour, Apple meta tags and
  the service-worker registration, exactly as `admin.html` does.
- The manifest's `start_url` is now `/`, so the installed app launches the root
  and there is one app identity whichever address it was installed from.
- The worker caches `/` as the shell, and serves `/`, `/index.html`, `/admin`
  (the old address) and `/admin.html` from that entry when the connection drops.
  Data requests are still never cached or queued.

To check after deploying: open `https://stream.eclecity.net/`, confirm the
install button appears, install, then DevTools → Network → Offline and reload —
the sign-in window should come up and signing in should fail with a network
error, not succeed on stale data.

If a previous shortcut is sitting on the home screen, remove it before
installing again.
