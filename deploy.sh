#!/usr/bin/env bash
# Deploy the stream.eclecity.net site to DreamHost.
#
# Remote layout:
#   /                 <- AllSpeak triples (HTML, .json layouts, -main.allspeak scripts)
#   /*.php            <- backend endpoints (login, session heartbeat/auth probe,
#                        bookings list/save/delete)
#   /manifest.json    <- PWA manifest for the admin panel
#   /sw.js            <- service worker (installable shell, data stays live)
#   /icons/           <- PWA icons referenced by the manifest
#   /.htaccess        <- URL rewrites for /admin and /{slug}
#   /data/YYYY/MM/DD/ <- per-booking JSON files, written server-side. NEVER touched by deploy.
#
# Usage:  ./deploy.sh
#
# Local-only files that must NOT be uploaded:
#   .credentials              dev-only plaintext fallback for login (if present)
#   server.allspeak           AllSpeak dev server
#   edit.html, asedit.*       browser editor for local AllSpeak development
#   .code-version             tracks the dev server's self-update cycle
#   .allspeak-init            marker file for the AllSpeak project bootstrap
#   allspeak-en.zip           local AllSpeak distribution archive
#   AI.md, .gitignore, deploy.sh  repo metadata
#   conversation/             build transcripts
#   seed.allspeak, sample.json one-time helpers
#   build.allspeak            replaced by export.php
#   data/locations.json       server-generated venue list; locations.php creates it
#   data/clients.json         server-generated client list; clients.php creates it
# These are excluded by listing only the production files explicitly below.

set -euo pipefail

REMOTE="eclecity@eclecity.net:/home/eclecity/stream.eclecity.net"
LOCAL="$(cd "$(dirname "$0")" && pwd)"

# Optional: uncomment to refuse deploy with dirty working tree.
# if [[ -n "$(git -C "$LOCAL" status --porcelain 2>/dev/null)" ]]; then
#     echo "Working tree has uncommitted changes (or not a git repo):"
#     git -C "$LOCAL" status --short 2>/dev/null || true
#     echo
#     echo "Commit or stash before deploying."
#     exit 1
# fi

echo "Deploying stream.eclecity.net from ${LOCAL}..."

tar czf /tmp/stream-deploy.tar.gz \
    -C "$LOCAL" \
    admin.html admin-main.allspeak admin.json \
    manifest.json sw.js icons \
    index.html index-main.allspeak index.json \
    stream.html stream-main.allspeak stream.json \
    allspeak.js \
    email1.json email2.json \
    login.php auth-check.php upload.php heartbeat.php \
    bookings.php bookings-save.php bookings-delete.php \
    locations.php clients.php \
    export.php books.php background.jpg .htaccess

ssh -o StrictHostKeyChecking=accept-new eclecity@eclecity.net \
    "mkdir -p ~/stream.eclecity.net && cd ~/stream.eclecity.net && tar xzf -" < /tmp/stream-deploy.tar.gz

rm -f /tmp/stream-deploy.tar.gz

echo "Done."