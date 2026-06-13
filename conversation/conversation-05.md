# Conversation 05 — Data export / accountant view explained

## User (2026-06-05)

First, I've created a folder for conversation logs. All new ones should be added there.
Next, I can't figure how the data export feature works (to send the table to my accountant). Can you explain it?

## Assistant (2026-06-05)

There is no "Export" button in the app — the accountant feature works differently: it's a **static read-only website** that you build from the terminal and host online. Here's the flow:

1. **Run `allspeak build.as`** from the project directory. This produces a self-contained `deploy/` folder containing the app files, a snapshot of all your `data/` JSON, and a `config.json` that sets the app to read-only mode (hiding Add/Save/Delete buttons).

2. **Host the `deploy/` folder** on any static web host (Cloudflare Pages, Netlify, GitHub Pages, etc.). This is already set up — the `deploy/` folder exists in the project already.

3. **Share the URL with your accountant.** They see the full table — all rows, monthly subtotals, grand total — but cannot edit, add, or delete anything.

The key detail: `build.as` takes a snapshot of the data at the moment you run it. So whenever you want to send your accountant an up-to-date view, you run `allspeak build.as` again, then redeploy (or commit and push if the deploy folder is linked to a hosting service that auto-deploys from git).


## User (2026-06-05)

Ah, I didn't think to look at build.as.
I think it would be preferable for there to be an 'Export' button next to 'Add booking', to perform the export function, avoiding the need to use the terminal. Since build.as is only 123 lines long perhaps it can be rolled into account-main.as?
Can I also have a deploy script that writes the contents of the deploy folder to my nominated server (for which I will supply the URL and username).

## Assistant (2026-06-05)

Explained why rolling build.as into account-main.as won't work cleanly: `rest post` JSON-serialises its payload, so posting HTML or .as files from the browser would corrupt them. JSON data files would survive, but the app files wouldn't.

Solution implemented: added a `/build` endpoint to server.as (one `system` call to `allspeak build.as`). The Export button in the GUI calls that endpoint via `rest get`. build.as stays as the actual build logic.

Changes made:
- account.json: added Export button and ExportStatus div to the header
- server.as: added `/build` endpoint that runs `allspeak build.as` as a subprocess
- account-main.as: added ExportBtn and ExportStatus variables, attach calls, click handler, OnExport subroutine, and hides ExportBtn in ReadOnly mode

build.as can be kept as a terminal fallback or retired — user's choice.

For the deploy script: asked the user for server hostname, username, and remote path.

## User (2026-06-05)

I'm going to add a subdomain to my own website for this. It may take me a couple of days to organise things so can we wrap up here and resume later?

## Assistant (2026-06-05)

Of course — when you're ready, just come back with the subdomain hostname, username, and remote path and we'll write the deploy script.
